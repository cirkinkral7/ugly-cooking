-- ╔══════════════════════════════════════════════════════════════╗
-- ║    GLADIUS COOKING — ox_inventory için ITEM TANIMLARI        ║
-- ║    Bu dosyanın içeriğini ox_inventory/data/items.lua          ║
-- ║    dosyasına ekleyin. Kendi görsellerinizi ox_inventory/web/  ║
-- ║    images/ klasörüne atın.                                    ║
-- ╚══════════════════════════════════════════════════════════════╝

return {

    -- ─── HAM MALZEMELER ─────────────────────────────────────
    ['ground_beef'] = {
        label  = 'Ground Beef',
        weight = 200,
        stack  = true,
        close  = true,
    },
    ['lettuce'] = {
        label  = 'Lettuce',
        weight = 80,
        stack  = true,
        close  = true,
    },
    ['tomato'] = {
        label  = 'Tomato',
        weight = 50,
        stack  = true,
        close  = true,
    },
    ['onion'] = {
        label  = 'Onion',
        weight = 50,
        stack  = true,
        close  = true,
    },
    ['bun'] = {
        label  = 'Bun',
        weight = 80,
        stack  = true,
        close  = true,
    },
    ['raw_steak'] = {
        label  = 'Raw Steak',
        weight = 250,
        stack  = true,
        close  = true,
    },
    ['potato'] = {
        label  = 'Potato',
        weight = 60,
        stack  = true,
        close  = true,
    },
    ['butter'] = {
        label  = 'Butter',
        weight = 50,
        stack  = true,
        close  = true,
    },
    ['salt'] = {
        label  = 'Salt',
        weight = 10,
        stack  = true,
        close  = true,
    },
    ['lobster'] = {
        label  = 'Lobster',
        weight = 400,
        stack  = true,
        close  = true,
    },
    ['pasta'] = {
        label  = 'Pasta',
        weight = 150,
        stack  = true,
        close  = true,
    },
    ['cream'] = {
        label  = 'Cream',
        weight = 100,
        stack  = true,
        close  = true,
    },
    ['garlic'] = {
        label  = 'Garlic',
        weight = 20,
        stack  = true,
        close  = true,
    },
    ['pizza_dough'] = {
        label  = 'Pizza Dough',
        weight = 200,
        stack  = true,
        close  = true,
    },
    ['tomato_sauce'] = {
        label  = 'Tomato Sauce',
        weight = 100,
        stack  = true,
        close  = true,
    },
    ['mozzarella'] = {
        label  = 'Mozzarella',
        weight = 100,
        stack  = true,
        close  = true,
    },
    ['basil'] = {
        label  = 'Basil',
        weight = 10,
        stack  = true,
        close  = true,
    },

    -- ─── NİHAİ YEMEKLER (quality / created_at metadata ile) ─
    ['gourmet_burger'] = {
        label  = 'Gourmet Burger',
        weight = 350,
        stack  = false,  -- Metadata farklı olduğu için stack kapalı
        close  = true,
        description = 'Taze malzemelerle hazırlanmış gurme hamburger.',
        client = {
            status = { hunger = 100, stress = -50 },
            anim   = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
            usetime = 2500,
        },
    },
    ['steak_fries'] = {
        label  = 'Steak & Fries',
        weight = 450,
        stack  = false,
        close  = true,
        description = 'Izgara biftek ve patates kızartması.',
        client = {
            status = { hunger = 120, stress = -40 },
            usetime = 2500,
        },
    },
    ['lobster_pasta'] = {
        label  = 'Lobster Pasta',
        weight = 500,
        stack  = false,
        close  = true,
        description = 'Premium istakoz soslu makarna.',
        client = {
            status = { hunger = 150, stress = -80 },
            usetime = 3000,
        },
    },
    ['margherita_pizza'] = {
        label  = 'Margherita Pizza',
        weight = 400,
        stack  = false,
        close  = true,
        description = 'Klasik İtalyan pizzası.',
        client = {
            status = { hunger = 110, stress = -30 },
            usetime = 2500,
        },
    },
}
