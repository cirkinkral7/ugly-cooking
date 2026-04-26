-- ╔══════════════════════════════════════════════════════════════╗
-- ║            GLADIUS COOKING — NUI CALLBACKS                    ║
-- ╚══════════════════════════════════════════════════════════════╝
-- Venice is never called from here directly: use GladiusCookingNotify in client/cooking.lua
-- (GetResourceState + pcall Create + QBCore:Notify fallback).
--
-- NUI: this file only drives gladius-cooking's own ui_page via SendNUIMessage in main/cooking.
-- No DoScreenFade*, Transition*, or exports to generic "screen fader" resources are invoked here.

local QBCore = exports['qb-core']:GetCoreObject()

-- ─────────────────────────────────────────────────────────────
-- CLOSE
-- ─────────────────────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    CloseCookingMenu()
    cb({ ok = true })
end)

-- ─────────────────────────────────────────────────────────────
-- REFRESH INVENTORY
-- ─────────────────────────────────────────────────────────────

RegisterNUICallback('refreshInventory', function(_, cb)
    QBCore.Functions.TriggerCallback('gladius_cooking:server:GetPlayerInventory', function(invItems)
        cb({ ok = true, inventory = invItems })
    end)
end)

-- ─────────────────────────────────────────────────────────────
-- START PREP — Server validates first, then we run skillcheck
-- ─────────────────────────────────────────────────────────────

RegisterNUICallback('startPrep', function(data, cb)
    local recipeId = data and data.recipeId
    if not recipeId then
        cb({ ok = false, error = 'no_recipe' })
        return
    end

    local pd = Gladius_GetPlayerData()
    if not pd or not pd.job then
        cb({ ok = false, error = 'no_job' })
        return
    end

    local job    = pd.job.name
    local recipe = Gladius.Utils.GetRecipe(job, recipeId)
    if not recipe then
        cb({ ok = false, error = 'no_recipe' })
        return
    end

    -- 1) Server ingredient validation
    QBCore.Functions.TriggerCallback('gladius_cooking:server:ValidateIngredients', function(ok, reason)
        if not ok then
            GladiusCookingNotify(_(reason or 'notify_no_ingredients'), 'error')
            cb({ ok = false, error = reason })
            return
        end

        -- 2) Full NUI focus; keep-input still routes some game controls — punch block thread runs while menu is open (see below)
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        Gladius_SetCooking(true)

        -- 3) Run the prep sequence (skillcheck + anim + cook)
        CreateThread(function()
            local quality = RunCookingFlow(job, recipeId, recipe)
            Gladius_SetCooking(false)

            -- Server finalizes: removes ingredients, grants final item with metadata
            TriggerServerEvent('gladius_cooking:server:FinalizeCooking', {
                job      = job,
                recipeId = recipeId,
                quality  = quality,
            })

            -- Re-open menu (optional): just close it for now
            CloseCookingMenu()
        end)

        cb({ ok = true })
    end, { job = job, recipeId = recipeId })
end)

-- ─────────────────────────────────────────────────────────────
-- PLAY HOVER / CLICK SOUNDS (optional)
-- ─────────────────────────────────────────────────────────────

RegisterNUICallback('playSound', function(data, cb)
    -- Optional: PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    cb({ ok = true })
end)

-- ─────────────────────────────────────────────────────────────
-- BLOCK MELEE WHILE MENU OPEN (SetNuiFocusKeepInput lets clicks reach game)
-- Stops when CloseCookingMenu() clears menuOpen in client/main.lua
-- ─────────────────────────────────────────────────────────────

CreateThread(function()
    while true do
        if Gladius_IsMenuOpen and Gladius_IsMenuOpen() then
            DisableControlAction(0, 24, true)  -- INPUT_ATTACK (LMB / punch)
            DisableControlAction(0, 140, true) -- INPUT_MELEE_ATTACK_LIGHT
            Wait(0)
        else
            Wait(100)
        end
    end
end)
