-- ╔══════════════════════════════════════════════════════════════╗
-- ║            GLADIUS COOKING — CLIENT MAIN                      ║
-- ╚══════════════════════════════════════════════════════════════╝

local QBCore   = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local menuOpen   = false
local isCooking  = false

---Refcount: Config.Shops key (job name) → how many kitchen points the ped is inside
local kitchenPresence = {}
local kitchenPoints = {}

-- ─────────────────────────────────────────────────────────────
-- PLAYER DATA
-- ─────────────────────────────────────────────────────────────

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)

CreateThread(function()
    while QBCore == nil do Wait(100) end
    while QBCore.Functions.GetPlayerData().citizenid == nil do Wait(250) end
    PlayerData = QBCore.Functions.GetPlayerData()
end)

-- ─────────────────────────────────────────────────────────────
-- KITCHEN PROXIMITY (ox_lib points — grid-based; no per-frame checks when away)
-- ─────────────────────────────────────────────────────────────

local function enterKitchen(shopJob)
    kitchenPresence[shopJob] = (kitchenPresence[shopJob] or 0) + 1
end

local function exitKitchen(shopJob)
    local n = (kitchenPresence[shopJob] or 1) - 1
    if n <= 0 then
        kitchenPresence[shopJob] = nil
    else
        kitchenPresence[shopJob] = n
    end
end

---Player is inside a kitchen sphere registered for this shop job key
---@param shopJob string Config.Shops key (= QB job name for that kitchen)
---@return boolean
local function IsAtKitchenForShopJob(shopJob)
    local n = kitchenPresence[shopJob]
    return n ~= nil and n > 0
end

---Job must have a shop entry; player must be within proximity of that job's kitchen coords
---@param job string PlayerData.job.name
---@return boolean
local function ClientAuthorizedAtKitchen(job)
    if not job then return false end
    if IsAtKitchenForShopJob(job) then return true end
    local ped = PlayerPedId()
    return Gladius.Utils.IsInShop(job, GetEntityCoords(ped))
end

-- ─────────────────────────────────────────────────────────────
-- PERMISSION CHECKS
-- ─────────────────────────────────────────────────────────────

---@return boolean
local function HasKitchenAccess()
    if not PlayerData or not PlayerData.job then return false end
    local job = PlayerData.job.name
    local shop = Config.Shops[job]
    if not shop then
        Gladius.Utils.Log('HasKitchenAccess: job has no shop config:', job)
        return false
    end
    if not ClientAuthorizedAtKitchen(job) then
        Gladius.Utils.Log('HasKitchenAccess: not at authorized kitchen for job', job)
        return false
    end
    return true
end

exports('HasKitchenAccess', HasKitchenAccess)

-- ─────────────────────────────────────────────────────────────
-- MENU OPEN / CLOSE
-- ─────────────────────────────────────────────────────────────

---Opens the cooking menu for the current job
function OpenCookingMenu()
    if menuOpen then return end
    if isCooking then
        GladiusCookingNotify(_('notify_already_cooking'), 'error')
        return
    end

    if not PlayerData or not PlayerData.job then
        GladiusCookingNotify(_('notify_no_job'), 'error')
        return
    end

    local job  = PlayerData.job.name
    local shop = Config.Shops[job]

    if not shop then
        GladiusCookingNotify(_('notify_no_job'), 'error')
        return
    end

    if not ClientAuthorizedAtKitchen(job) then
        GladiusCookingNotify(_('notify_wrong_location'), 'error')
        return
    end

    -- Envanter durumunu server'dan alalım
    QBCore.Functions.TriggerCallback('gladius_cooking:server:GetPlayerInventory', function(invItems)
        menuOpen = true
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)

        local payload = {
            action     = 'open',
            shop       = {
                id         = job,
                label      = shop.label,
                shortLabel = shop.shortLabel or shop.label,
                logo       = shop.logo,
            },
            recipes    = shop.recipes,
            appliances = Config.Appliances,
            inventory  = invItems,
            locale     = Locale,
            cookedExpiryHours = Config.CookedItemExpiryHours or 24,
        }

        SendNUIMessage(payload)
    end)
end

exports('OpenCookingMenu', OpenCookingMenu)

---Close the NUI
function CloseCookingMenu()
    menuOpen = false
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

exports('CloseCookingMenu', CloseCookingMenu)

---Push latest ox_inventory counts to NUI while menu is open (ingredient tiles / start button)
local function SyncInventoryToNui()
    if not menuOpen then return end
    QBCore.Functions.TriggerCallback('gladius_cooking:server:GetPlayerInventory', function(invItems)
        SendNUIMessage({ action = 'inventoryUpdate', inventory = invItems })
    end)
end

AddEventHandler('ox_inventory:updateInventory', function()
    SyncInventoryToNui()
end)

-- ─────────────────────────────────────────────────────────────
-- COMMAND / KEY
-- ─────────────────────────────────────────────────────────────

RegisterCommand(Config.OpenCommand, function()
    OpenCookingMenu()
end, false)

if Config.OpenKey then
    RegisterKeyMapping(Config.OpenCommand, 'Gladius Cooking Menüsünü Aç', 'keyboard', Config.OpenKey)
end

-- ─────────────────────────────────────────────────────────────
-- OX_LIB KITCHEN POINTS (distance via grid; nearby interval only when in range)
-- ─────────────────────────────────────────────────────────────

CreateThread(function()
    if not lib or not lib.points or not lib.points.new then
        Gladius.Utils.Log('ox_lib points unavailable; using coordinate fallback only')
        return
    end

    Wait(750)

    for shopJob, shop in pairs(Config.Shops) do
        if shop.locations then
            for _, loc in ipairs(shop.locations) do
                local radius = Gladius.Utils.GetShopProximityRadius(shop)
                local pt = lib.points.new({
                    coords = loc,
                    distance = radius,
                    onEnter = function()
                        enterKitchen(shopJob)
                    end,
                    onExit = function()
                        exitKitchen(shopJob)
                    end,
                })
                kitchenPoints[#kitchenPoints + 1] = pt
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- TARGET / INTERACTION
-- ─────────────────────────────────────────────────────────────

CreateThread(function()
    if not Config.UseTarget then return end
    Wait(1000)

    for jobName, shop in pairs(Config.Shops) do
        if shop.locations then
            local interactRadius = Gladius.Utils.GetShopProximityRadius(shop)
            for idx, loc in ipairs(shop.locations) do
                if Config.TargetResource == 'ox_target' then
                    exports.ox_target:addSphereZone({
                        coords   = loc,
                        radius   = interactRadius,
                        name     = ('gladius_kitchen_%s_%s'):format(jobName, idx),
                        options  = {
                            {
                                name     = ('gladius_kitchen_%s_%s_open'):format(jobName, idx),
                                label    = _('target_open_menu'),
                                icon     = 'fa-solid fa-utensils',
                                distance = interactRadius,
                                groups   = { [jobName] = 0 },
                                canInteract = function()
                                    if not PlayerData or not PlayerData.job then return false end
                                    if PlayerData.job.name ~= jobName then return false end
                                    return ClientAuthorizedAtKitchen(jobName)
                                end,
                                onSelect = function()
                                    OpenCookingMenu()
                                end,
                            },
                        },
                    })
                elseif Config.TargetResource == 'qb-target' then
                    exports.qtarget:AddCircleZone(
                        ('gladius_kitchen_%s_%s'):format(jobName, idx),
                        loc,
                        interactRadius,
                        { name = ('gladius_kitchen_%s_%s'):format(jobName, idx), useZ = true },
                        {
                            options = {
                                {
                                    type   = 'client',
                                    action = function()
                                        OpenCookingMenu()
                                    end,
                                    icon   = 'fa-solid fa-utensils',
                                    label  = _('target_open_menu'),
                                    job    = jobName,
                                },
                            },
                            distance = interactRadius,
                        }
                    )
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- BLIPS
-- ─────────────────────────────────────────────────────────────

CreateThread(function()
    for _, shop in pairs(Config.Shops) do
        if shop.blip and shop.blip.enabled and shop.locations then
            for _, loc in ipairs(shop.locations) do
                local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
                SetBlipSprite(blip, shop.blip.sprite or 106)
                SetBlipColour(blip, shop.blip.color or 5)
                SetBlipScale(blip, shop.blip.scale or 0.7)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(shop.label)
                EndTextCommandSetBlipName(blip)
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- STATE ACCESSORS
-- ─────────────────────────────────────────────────────────────

function Gladius_SetCooking(state)
    isCooking = state and true or false
end

function Gladius_IsCooking()
    return isCooking
end

function Gladius_SetMenuOpen(state)
    menuOpen = state and true or false
end

function Gladius_GetPlayerData()
    return PlayerData
end

---Used by client/nui.lua to block melee while the cooking NUI is open (SetNuiFocusKeepInput passes game input).
---@return boolean
function Gladius_IsMenuOpen()
    return menuOpen
end

-- ─────────────────────────────────────────────────────────────
-- CLEANUP ON STOP
-- ─────────────────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    menuOpen = false
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    for i = 1, #kitchenPoints do
        local pt = kitchenPoints[i]
        if pt and pt.remove then pt:remove() end
    end
    table.wipe(kitchenPoints)
    table.wipe(kitchenPresence)
end)
