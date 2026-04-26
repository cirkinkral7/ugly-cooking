-- ╔══════════════════════════════════════════════════════════════╗
-- ║            GLADIUS COOKING — SERVER: FINALIZE                 ║
-- ╚══════════════════════════════════════════════════════════════╝

local QBCore = exports['qb-core']:GetCoreObject()

-- ─────────────────────────────────────────────────────────────
-- ANTI-SPAM: Cooldown per player (prevents callback replays)
-- ─────────────────────────────────────────────────────────────

local cookingLock = {}

local function AcquireLock(src)
    if cookingLock[src] then return false end
    cookingLock[src] = os.time()
    return true
end

local function ReleaseLock(src)
    cookingLock[src] = nil
end

-- ─────────────────────────────────────────────────────────────
-- FINALIZE: Remove ingredients, grant result with metadata
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('gladius_cooking:server:FinalizeCooking', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not AcquireLock(src) then
        Gladius.Utils.Log('Cooking lock held for', src)
        return
    end

    local ok, err = pcall(function()
        local job      = data and data.job
        local recipeId = data and data.recipeId
        local quality  = tonumber(data and data.quality) or 0

        if not job or not recipeId then return end

        -- Re-validate job
        if Player.PlayerData.job.name ~= job then
            TriggerClientEvent('QBCore:Notify', src, _('notify_no_job'), 'error')
            return
        end

        local recipe = Gladius.Utils.GetRecipe(job, recipeId)
        if not recipe then
            TriggerClientEvent('QBCore:Notify', src, _('notify_no_job'), 'error')
            return
        end

        -- Re-check location (anti-cheat)
        local ped = GetPlayerPed(src)
        local pos = GetEntityCoords(ped)
        local shop = Config.Shops[job]
        if not shop then
            TriggerClientEvent('QBCore:Notify', src, _('notify_wrong_location'), 'error')
            return
        end
        local maxDist = Gladius.Utils.GetShopProximityRadius(shop) + 0.75
        local withinRadius = false
        for _, loc in ipairs(shop.locations or {}) do
            if #(pos - loc) <= maxDist then
                withinRadius = true
                break
            end
        end
        if not withinRadius then
            TriggerClientEvent('QBCore:Notify', src, _('notify_wrong_location'), 'error')
            return
        end

        -- Re-check ingredients
        for _, ing in ipairs(recipe.ingredients or {}) do
            local have = exports.ox_inventory:Search(src, 'count', ing.item) or 0
            if have < (ing.amount or 1) then
                TriggerClientEvent('QBCore:Notify', src, _('notify_no_ingredients'), 'error')
                return
            end
        end

        local removedStack = {}

        local function rollbackRemoved()
            for i = #removedStack, 1, -1 do
                local r = removedStack[i]
                exports.ox_inventory:AddItem(src, r.item, r.count)
            end
            table.wipe(removedStack)
        end

        for _, ing in ipairs(recipe.ingredients or {}) do
            local amount = ing.amount or 1
            local removed = exports.ox_inventory:RemoveItem(src, ing.item, amount)
            if not removed then
                rollbackRemoved()
                TriggerClientEvent('QBCore:Notify', src, _('notify_no_ingredients'), 'error')
                return
            end
            removedStack[#removedStack + 1] = { item = ing.item, count = amount }
        end

        -- Clamp quality (from client skillcheck; re-clamped server-side)
        if quality > Config.MaxQuality then quality = Config.MaxQuality end
        if quality < 0 then quality = 0 end

        local qLabel = Gladius.Utils.GetQualityLabel(quality)
        local createdAt = os.time()
        local cookedExpiryHours = Config.CookedItemExpiryHours or 24
        local expiresAt = createdAt + (cookedExpiryHours * 3600)

        local metadata = {
            quality          = quality,
            quality_percent  = quality,
            quality_label    = qLabel.label,
            quality_color    = qLabel.color,
            created_at       = createdAt,
            expires_at       = expiresAt,
            expiration_hours = cookedExpiryHours,
            cooked_by        = Player.PlayerData.citizenid,
            cooked_by_name   = ('%s %s'):format(Player.PlayerData.charinfo.firstname or '', Player.PlayerData.charinfo.lastname or ''),
            job              = job,
            recipe           = recipeId,
            recipe_label     = (recipe.label or recipeId),
            description      = ('Kalite: %%%d | Son tüketim: %s'):format(
                quality,
                os.date('%d/%m/%Y %H:%M', expiresAt)
            ),
        }

        local resultItem = recipe.result and recipe.result.item
        local resultAmount = (recipe.result and recipe.result.amount) or 1
        if not resultItem then
            rollbackRemoved()
            TriggerClientEvent('QBCore:Notify', src, _('notify_cook_failed'), 'error')
            return
        end

        local added = exports.ox_inventory:AddItem(src, resultItem, resultAmount, metadata)
        if not added then
            rollbackRemoved()
            TriggerClientEvent('QBCore:Notify', src, _('notify_inventory_full'), 'error')
            return
        end

        TriggerClientEvent('QBCore:Notify', src, _('notify_cook_success'), 'success')

        -- Log for audit
        Gladius.Utils.Log(('[FINALIZE] %s cooked %s (quality=%d) at %s'):format(
            Player.PlayerData.citizenid, recipeId, quality, job
        ))
    end)

    ReleaseLock(src)
    if not ok then
        print('[^1Gladius Cooking^7] Finalize error:', err)
    end
end)

-- ─────────────────────────────────────────────────────────────
-- CLEANUP LOCKS ON DISCONNECT
-- ─────────────────────────────────────────────────────────────

AddEventHandler('playerDropped', function()
    local src = source
    ReleaseLock(src)
end)

-- ─────────────────────────────────────────────────────────────
-- EXPORT: Check freshness of an item (for consume scripts)
-- ─────────────────────────────────────────────────────────────

exports('IsItemFresh', function(metadata)
    if not metadata then return true, nil end
    local now = os.time()
    if metadata.expires_at then
        local hoursLeft = (metadata.expires_at - now) / 3600
        return metadata.expires_at > now, hoursLeft
    end
    if not metadata.created_at then return true, nil end
    local recipe = Gladius.Utils.GetRecipe(metadata.job or '', metadata.recipe or '')
    local expirationHours = metadata.expiration_hours
        or (recipe and recipe.result and recipe.result.expiration)
        or Config.FreshnessHours
    return Gladius.Utils.IsFresh(metadata.created_at, expirationHours)
end)
