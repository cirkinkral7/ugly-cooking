// ╔══════════════════════════════════════════════════════════════╗
// ║            GLADIUS COOKING — NUI SCRIPT                       ║
// ╚══════════════════════════════════════════════════════════════╝

(() => {
    'use strict';

    const RESOURCE = (typeof GetParentResourceName === 'function')
        ? GetParentResourceName()
        : 'gladius_cooking';

    const state = {
        shop:       null,
        recipes:    {},
        appliances: {},
        inventory:  {},
        currentRecipeId: null,
        locale:     {},
        cookedExpiryHours: 24,
    };

    /** NUI skill bar — driven by rAF; [E] commits; no CSS auto-animation */
    const skillState = {
        sessionActive: false,
        active:        false,
        posting:       false,
        raf:           null,
        token:         0,
        phaseStart:    0,
        periodSec:     2.2,
        zoneLeftPct:   55,
        zoneWidthPct:  22,
        lastXPct:      8,
    };

    const TIER_PARAMS = {
        easy:   { width: 32, period: 2.85 },
        medium: { width: 22, period: 2.15 },
        hard:   { width: 16, period: 1.55 },
        expert: { width: 11, period: 1.12 },
    };

    // ─── Helpers ────────────────────────────────────────────

    const $ = sel => document.querySelector(sel);
    const root = $('#gladius-root');

    function post(endpoint, payload) {
        return fetch(`https://${RESOURCE}/${endpoint}`, {
            method:  'POST',
            headers: { 'Content-Type': 'application/json;charset=UTF-8' },
            body:    JSON.stringify(payload || {}),
        }).then(r => r.json()).catch(() => ({ ok: false }));
    }

    function show() { root.classList.remove('hidden'); }
    function hide() { root.classList.add('hidden'); }

    function loc(key, fallback) {
        const L = state.locale || {};
        const v = L[key];
        return (v != null && String(v).trim() !== '') ? String(v) : fallback;
    }

    function applyLocaleLabels() {
        $('#minigame-title').textContent = loc('mini_game', 'MINI-GAME').toUpperCase();
        $('#skillcheck-subtitle').textContent = loc('skill_check', 'SKILL CHECK').toUpperCase();
        $('#minigame-hint').textContent = loc('skill_press_e', 'Press E when the marker is in the green zone.');
        const flash = $('#skill-perfect-flash');
        if (flash) flash.textContent = loc('skill_perfect', 'Perfect!');
    }

    function stopSkillRaf() {
        if (skillState.raf != null) {
            cancelAnimationFrame(skillState.raf);
            skillState.raf = null;
        }
        skillState.active = false;
        skillState.phaseStart = 0;
        const ind = $('#skill-indicator');
        if (ind) ind.classList.add('is-idle');
    }

    function layoutZone(zoneEl, leftPct, widthPct) {
        zoneEl.style.left = leftPct + '%';
        zoneEl.style.width = widthPct + '%';
    }

    function computeHitQuality(barEl, zoneEl, indEl) {
        const br = barEl.getBoundingClientRect();
        const zr = zoneEl.getBoundingClientRect();
        const ir = indEl.getBoundingClientRect();
        if (br.width <= 0) return { quality: 0, perfect: false, hit: false };

        const cx = ((ir.left + ir.width / 2) - br.left) / br.width * 100;
        const zl = ((zr.left) - br.left) / br.width * 100;
        const zrgt = zl + (zr.width / br.width) * 100;
        const zmid = (zl + zrgt) / 2;
        const half = Math.max(0.05, (zrgt - zl) / 2);

        if (cx >= zl && cx <= zrgt) {
            const d = Math.abs(cx - zmid) / half;
            const perfect = d < 0.12;
            const quality = Math.round(Math.max(0, Math.min(100, 100 - 42 * d)));
            return { quality, perfect, hit: true };
        }

        const distOut = cx < zl ? (zl - cx) : (cx - zrgt);
        const quality = Math.max(10, Math.round(48 - Math.min(48, distOut * 2.4)));
        return { quality, perfect: false, hit: false };
    }

    function showPerfectFlash() {
        const el = $('#skill-perfect-flash');
        if (!el) return;
        el.removeAttribute('hidden');
        el.style.animation = 'none';
        void el.offsetWidth;
        el.style.animation = '';
        window.setTimeout(() => {
            el.setAttribute('hidden', '');
        }, 900);
    }

    function skillTick(ts) {
        if (!skillState.active) return;
        if (!skillState.phaseStart) skillState.phaseStart = ts;
        const elapsed = (ts - skillState.phaseStart) / 1000;
        const period = skillState.periodSec;
        const u = (elapsed / period) % 2;
        const ping = u < 1 ? u : (2 - u);
        const xMin = 7;
        const xMax = 93;
        const xPct = xMin + ping * (xMax - xMin);
        skillState.lastXPct = xPct;
        const ind = $('#skill-indicator');
        if (ind) {
            ind.style.left = xPct + '%';
            ind.classList.remove('is-idle');
        }
        skillState.raf = requestAnimationFrame(skillTick);
    }

    function startSkillRound(data) {
        stopSkillRaf();
        skillState.posting = false;
        const tier = (data.tier || 'medium').toLowerCase();
        const tp = TIER_PARAMS[tier] || TIER_PARAMS.medium;
        skillState.token = Number(data.token) || 0;
        skillState.periodSec = tp.period;
        skillState.zoneWidthPct = tp.width;
        const margin = 6;
        const maxL = 100 - skillState.zoneWidthPct - margin;
        skillState.zoneLeftPct = margin + Math.random() * Math.max(0.1, (maxL - margin));
        layoutZone($('#skill-zone'), skillState.zoneLeftPct, skillState.zoneWidthPct);

        const rt = $('#skill-round-text');
        if (rt) rt.textContent = `ROUND ${data.round || 1} / ${data.total || 1}`;

        skillState.active = false;
        skillState.phaseStart = 0;
        // Sync bar motion with Lua round start + layout: start after two animation frames
        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                if (skillState.token !== (Number(data.token) || 0)) return;
                skillState.active = true;
                skillState.phaseStart = performance.now();
                skillState.raf = requestAnimationFrame(skillTick);
            });
        });
    }

    async function commitSkillRound() {
        if (!skillState.active || skillState.posting) return;

        stopSkillRaf();

        const bar = $('#skillcheck-bar');
        const zone = $('#skill-zone');
        const ind = $('#skill-indicator');
        const { quality, perfect, hit } = computeHitQuality(bar, zone, ind);

        if (perfect && hit) showPerfectFlash();

        skillState.posting = true;
        try {
            await post('cookingSkillResult', {
                token: skillState.token,
                quality,
                perfect: !!perfect,
                hit: !!hit,
                cancelled: false,
            });
        } finally {
            skillState.posting = false;
        }
    }

    async function cancelSkillSession() {
        if (skillState.posting) return;
        stopSkillRaf();
        const tok = skillState.token;
        skillState.posting = true;
        try {
            await post('cookingSkillResult', {
                token: tok,
                quality: 0,
                perfect: false,
                hit: false,
                cancelled: true,
            });
        } finally {
            skillState.posting = false;
        }
    }

    // Best-effort ingredient emoji fallback
    const INGREDIENT_EMOJI = {
        ground_beef: '🥩', lettuce: '🥬', tomato: '🍅', onion: '🧅', bun: '🍞',
        raw_steak: '🥩', potato: '🥔', butter: '🧈', salt: '🧂',
        lobster: '🦞', pasta: '🍝', cream: '🥛', garlic: '🧄',
        pizza_dough: '🍥', tomato_sauce: '🥫', mozzarella: '🧀', basil: '🌿',
        cheese: '🧀', egg: '🥚', milk: '🥛', chicken: '🍗', fish: '🐟',
    };

    const RECIPE_EMOJI_DEFAULT = '🍽️';

    function emojiFor(item) {
        return INGREDIENT_EMOJI[item] || '📦';
    }

    // ─── Rendering ──────────────────────────────────────────

    function getShopDisplayLabel() {
        const s = state.shop;
        if (!s) return '—';
        const raw = (s.label && String(s.label).trim())
            || (s.shortLabel && String(s.shortLabel).trim())
            || (s.id && String(s.id).trim())
            || '—';
        return raw.toUpperCase();
    }

    function renderShop() {
        const loc = $('#shop-name');
        const name = getShopDisplayLabel();
        loc.textContent = name;
        loc.title = state.shop
            ? ((state.shop.label || state.shop.shortLabel || state.shop.id || '') + '')
            : '';
        $('#breadcrumb-text').textContent = state.shop
            ? `GLADIUS COOKING: ${(state.currentRecipe?.label || '').toUpperCase()}`
            : 'GLADIUS COOKING';
    }

    function renderRecipeList() {
        const list = $('#recipe-list');
        list.innerHTML = '';
        const entries = Object.entries(state.recipes || {});
        entries.forEach(([id, recipe]) => {
            const btn = document.createElement('button');
            btn.className = 'recipe-btn' + (id === state.currentRecipeId ? ' active' : '');
            btn.innerHTML = `<span class="icon">${recipe.icon || RECIPE_EMOJI_DEFAULT}</span><span>${recipe.label || id}</span>`;
            btn.addEventListener('click', () => selectRecipe(id));
            list.appendChild(btn);
        });

        if (entries.length && !state.currentRecipeId) {
            selectRecipe(entries[0][0]);
        }
    }

    function selectRecipe(id) {
        state.currentRecipeId = id;
        state.currentRecipe   = state.recipes[id];
        renderRecipeDetail();
        renderRecipeList();
        renderShop();
    }

    function renderRecipeDetail() {
        const recipe = state.currentRecipe;
        if (!recipe) return;

        $('#recipe-icon').textContent  = recipe.icon || RECIPE_EMOJI_DEFAULT;
        $('#recipe-title').textContent = (recipe.label || '').toUpperCase();

        renderIngredients(recipe);
        renderAppliances(recipe);
        renderCookTime(recipe);
        renderFinal(recipe);
        updateStartButton(recipe);
    }

    function renderIngredients(recipe) {
        const grid = $('#ingredients-grid');
        grid.innerHTML = '';
        const ings = recipe.ingredients || [];
        ings.forEach(ing => {
            const have = state.inventory[ing.item] || 0;
            const need = ing.amount || 1;
            const ok   = have >= need;

            const tile = document.createElement('div');
            tile.className = 'ingredient-tile' + (ok ? ' ok' : ' missing');
            tile.innerHTML = `
                <div class="ing-count">${Math.min(have, need)}/${need}</div>
                <div class="ing-check">✓</div>
                <div class="ing-emoji">${emojiFor(ing.item)}</div>
                <div class="ing-name">${ing.label || ing.item}</div>
            `;
            grid.appendChild(tile);
        });
    }

    function renderAppliances(recipe) {
        const row   = $('#appliance-row');
        row.innerHTML = '';
        const active = recipe.cook && recipe.cook.appliance;

        const icons = {
            frying_pan: `<svg viewBox="0 0 24 24"><ellipse cx="10" cy="13" rx="7" ry="4"/><path d="M17 13h4"/></svg>`,
            oven:       `<svg viewBox="0 0 24 24"><rect x="4" y="4" width="16" height="16" rx="2"/><line x1="4" y1="10" x2="20" y2="10"/><circle cx="8" cy="7" r="0.8"/><circle cx="12" cy="7" r="0.8"/></svg>`,
            grill:      `<svg viewBox="0 0 24 24"><path d="M4 6h16l-2 12H6L4 6z"/><line x1="7" y1="9" x2="17" y2="9"/><line x1="7" y1="13" x2="17" y2="13"/></svg>`,
        };

        ['frying_pan', 'oven', 'grill'].forEach(app => {
            const btn = document.createElement('div');
            btn.className = 'appliance-btn' + (app === active ? ' active' : '');
            btn.innerHTML = icons[app] || icons.frying_pan;
            row.appendChild(btn);
        });

        const applianceLabel = (state.appliances[active] && state.appliances[active].label)
            || (active ? active.replace('_', ' ').toUpperCase() : '—');
        $('#cook-appliance-label').textContent = applianceLabel.toUpperCase();
    }

    function renderCookTime(recipe) {
        const durationMs = (recipe.cook && recipe.cook.duration) || 30000;
        const seconds = Math.round(durationMs / 1000);
        $('#cook-time-text').textContent = seconds + 's';

        const circumference = 2 * Math.PI * 17;
        const ratio = Math.min(1, Math.max(0.1, seconds / 90));
        const offset = circumference * (1 - ratio);
        const ring = $('#cook-time-ring-fg');
        ring.setAttribute('stroke-dasharray', circumference.toFixed(2));
        ring.setAttribute('stroke-dashoffset', offset.toFixed(2));
    }

    function renderFinal(recipe) {
        const name = recipe.label || '';
        $('#final-name').textContent = name.toUpperCase();

        const img = $('#final-image');
        const fallback = $('#final-image-fallback');
        if (recipe.image) {
            img.src = `img/${recipe.image}`;
            img.onload  = () => { img.classList.add('visible'); fallback.style.display = 'none'; };
            img.onerror = () => { img.classList.remove('visible'); fallback.style.display = 'block'; fallback.textContent = recipe.icon || RECIPE_EMOJI_DEFAULT; };
        } else {
            img.classList.remove('visible');
            fallback.style.display = 'block';
            fallback.textContent = recipe.icon || RECIPE_EMOJI_DEFAULT;
        }

        $('#final-quality').textContent = '%90+';

        const expH = state.cookedExpiryHours || 24;
        $('#final-expiration').textContent = expH + 'h';

        const effects = (recipe.result && recipe.result.effectsDisplay) || [];
        $('#final-effects').innerHTML = effects.length
            ? effects.map(e => `<span>${e}</span>`).join('')
            : '<span>—</span>';
    }

    function updateStartButton(recipe) {
        const btn = $('#btn-start');
        const ings = recipe.ingredients || [];
        const allOk = ings.every(ing => (state.inventory[ing.item] || 0) >= (ing.amount || 1));
        btn.disabled = !allOk;
    }

    // ─── Event Listeners ────────────────────────────────────

    $('#btn-cancel').addEventListener('click', () => post('close'));
    $('#btn-back').addEventListener('click', () => post('close'));

    $('#btn-start').addEventListener('click', async () => {
        if (!state.currentRecipeId) return;
        const btn = $('#btn-start');
        btn.disabled = true;
        btn.querySelector('span').textContent = 'STARTING...';

        const res = await post('startPrep', { recipeId: state.currentRecipeId });
        if (!res || !res.ok) {
            btn.disabled = false;
            btn.querySelector('span').textContent = 'START PREP';
            const invRes = await post('refreshInventory', {});
            if (invRes && invRes.inventory) {
                state.inventory = invRes.inventory;
                if (state.currentRecipe) {
                    renderIngredients(state.currentRecipe);
                    updateStartButton(state.currentRecipe);
                }
            }
        }
    });

    document.addEventListener('keydown', e => {
        if (skillState.active && (e.key === 'e' || e.key === 'E')) {
            e.preventDefault();
            e.stopPropagation();
            commitSkillRound();
            return;
        }
        if (skillState.active && e.key === 'Escape') {
            e.preventDefault();
            e.stopPropagation();
            cancelSkillSession();
            return;
        }
    }, true);

    document.addEventListener('keyup', e => {
        if (skillState.sessionActive) return;
        if (e.key === 'Escape') post('close');
    });

    // ─── NUI Message Handler ────────────────────────────────

    window.addEventListener('message', event => {
        const data = event.data || {};

        switch (data.action) {
            case 'open': {
                state.shop       = data.shop || null;
                state.recipes    = data.recipes || {};
                state.appliances = data.appliances || {};
                state.inventory  = data.inventory || {};
                state.locale     = data.locale || {};
                state.cookedExpiryHours = data.cookedExpiryHours || 24;
                state.currentRecipeId = null;
                state.currentRecipe   = null;
                applyLocaleLabels();
                renderShop();
                renderRecipeList();
                show();
                break;
            }

            case 'close':
                stopSkillRaf();
                skillState.sessionActive = false;
                hide();
                break;

            case 'inventoryUpdate': {
                state.inventory = data.inventory || {};
                const cur = state.currentRecipe;
                if (cur) {
                    renderIngredients(cur);
                    updateStartButton(cur);
                }
                break;
            }

            case 'skillcheckSessionStart':
                skillState.sessionActive = true;
                stopSkillRaf();
                $('#skill-round-text').textContent = '';
                break;

            case 'skillcheckSessionEnd':
                skillState.sessionActive = false;
                stopSkillRaf();
                $('#skill-round-text').textContent = '';
                break;

            case 'skillcheckRoundStart':
                startSkillRound(data);
                break;

            case 'skillcheckDone': {
                const q = typeof data.quality === 'number' ? Math.round(data.quality) : null;
                if (q != null) {
                    $('#final-quality').textContent = '%' + q;
                }
                if (data.perfect) {
                    $('#final-quality').textContent = '%' + (q != null ? q : 95) + '+';
                }
                break;
            }

            default:
                break;
        }
    });

    hide();
})();
