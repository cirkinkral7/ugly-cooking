-- ╔══════════════════════════════════════════════════════════════╗
-- ║            GLADIUS COOKING — CONFIGURATION                    ║
-- ║            Premium Multi-Step Cooking System                  ║
-- ╚══════════════════════════════════════════════════════════════╝

Config = {}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  GENEL AYARLAR                                                ║
-- ╚══════════════════════════════════════════════════════════════╝

Config.Debug            = true                 -- Debug logları aç/kapa
Config.Framework        = 'qb-core'             -- qb-core
Config.Inventory        = 'ox_inventory'        -- ox_inventory
Config.UseTarget        = true                  -- ox_target entegrasyonu
Config.TargetResource   = 'ox_target'           -- ox_target | qb-target

Config.OpenCommand      = 'cook'                -- /cook komutu ile menü açma
Config.OpenKey          = 'nil'                   -- nil = kapalı, örn: 'E'

Config.MaxQuality       = 100                   -- Maksimum kalite yüzdesi
Config.MinQuality       = 20                    -- Başarısız skillcheck sonrası minimum kalite
Config.FreshnessHours   = 24                    -- Varsayılan tazelik süresi (saat)
-- Pişmiş ürün: ox_inventory metadata `expires_at` = created_at + (saat * 3600)
Config.CookedItemExpiryHours = 24

-- Mutfağa yakınlık (metre). ox_lib points + menü/sunucu doğrulaması bu değeri kullanır.
-- Config.Shops anahtarı (ör. 'burgershot') ile PlayerData.job.name birebir eşleşmeli.
Config.KitchenProximity = 2.0

Config.QualityMessages = {
    [90] = { label = 'Mükemmel', color = '#22c55e' },
    [70] = { label = 'İyi',      color = '#84cc16' },
    [50] = { label = 'Orta',     color = '#eab308' },
    [0]  = { label = 'Kötü',     color = '#ef4444' },
}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SKILLCHECK ZORLUK HARİTASI                                   ║
-- ╚══════════════════════════════════════════════════════════════╝

Config.Skillchecks = {
    easy   = { 'easy' },
    medium = { 'easy', 'medium' },
    hard   = { 'easy', 'medium', 'hard' },
    expert = { 'medium', 'hard', 'hard' },
}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  GÖRSEL / SES / PTFX (client cooking.lua)                     ║
-- ║  interact-sound: client/html/sounds/<dosya>.ogg ekleyin       ║
-- ╚══════════════════════════════════════════════════════════════╝

Config.CookingEffects = {
    --- Mutfak dumanı (ox progress “cook” aşaması). Asset: core
    ptfx = {
        asset   = 'core',
        name    = 'exp_grd_gas_smoke',
        scale   = 0.45,
        zOffset = 0.18,
    },
    --- interact-sound (TriggerEvent InteractSound_CL:PlayOnOne)
    interactSound = {
        enabled          = true,
        resource         = 'interact-sound',
        chopFile         = 'chopping',  -- chopping.ogg
        fryFile          = 'frying',    -- frying.ogg
        chopVolume       = 0.42,
        fryVolume        = 0.38,
        repeatIntervalMs = 2000,
    },
    props = {
        knife = 'prop_cleaver',
        pan   = 'prop_fry_pan_02',
    },
    --- Bıçak: sağ el (57005), tava: sol el (60309) — BBQ anim ile uyumlu
    knifeAttach = { bone = 57005, pos = { x = 0.11, y = 0.02, z = -0.02 }, rot = { x = 65.0, y = 115.0, z = 8.0 } },
    panAttach   = { bone = 60309, pos = { x = 0.14, y = 0.02, z = 0.02 }, rot = { x = -90.0, y = 25.0, z = 0.0 } },
    --- Hazırlık: doğrama; recipe.prep.anim varsa o kullanılır
    prepAnimDefault = {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        anim = 'machinic_loop_mechandplayer',
    },
    --- Pişirme: recipe.cook.anim yoksa cihaza göre (hepsi BBQ tabanı)
    cookAnimByAppliance = {
        frying_pan = { dict = 'amb@prop_human_bbq@male@base', anim = 'base' },
        grill      = { dict = 'amb@prop_human_bbq@male@base', anim = 'base' },
        oven       = { dict = 'amb@prop_human_bbq@male@base', anim = 'base' },
    },
}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  DÜKKAN / İŞLETME TANIMLARI                                   ║
-- ║  Tablo anahtarı = QB job adı (PlayerData.job.name).           ║
-- ║  locations = mutfak etkileşim noktası (vector3).             ║
-- ║  radius = isteğe bağlı; yoksa Config.KitchenProximity kullanılır. ║
-- ╚══════════════════════════════════════════════════════════════╝

Config.Shops = {

    -- ───────────────────────────────────────────────
    -- BURGERSHOT
    -- ───────────────────────────────────────────────
    ['police'] = {
        label      = 'LSPD Kitchen',
        shortLabel = 'LSPD',
        logo       = 'burgershot.png',
        blip = {
            enabled = false,
            sprite  = 106,
            color   = 5,
            scale   = 0.7,
        },
        locations = {
            vector3(460.08, -977.0, 42.25),
        },
        recipes = {

                ['gourmet_burger'] = {
                    label       = 'Gourmet Burger',
                    icon        = '🍔',
                    image       = 'gourmet_burger.png',
                    description = 'Özel soslu, taze malzemelerle hazırlanan gurme hamburger.',
                    ingredients = {
                        { item = 'ground_beef', amount = 1, label = 'Ground Beef' },
                        { item = 'lettuce',     amount = 1, label = 'Lettuce'     },
                        { item = 'tomato',      amount = 1, label = 'Tomato'      },
                        { item = 'onion',       amount = 1, label = 'Onion'       },
                        { item = 'bun',         amount = 1, label = 'Bun'         },
                    },
                    prep = {
                        difficulty = 'medium',
                        duration   = 5000,
                        -- anim yoksa Config.CookingEffects.prepAnimDefault (bıçak ile uyumlu)
                    },
                    cook = {
                        appliance = 'frying_pan',       -- frying_pan | oven | grill
                        duration  = 30000,              -- ms
                        anim      = { dict = 'amb@prop_human_bbq@male@base', anim = 'base' },
                    },
                    result = {
                        item       = 'gourmet_burger',
                        amount     = 1,
                        expiration = 24,
                        effects    = {
                            hunger = 100,
                            stress = -50,
                        },
                        effectsDisplay = {
                            '+100 Hunger',
                            '-50 Stress',
                        },
                    },
                },

                ['steak_fries'] = {
                    label       = 'Steak & Fries',
                    icon        = '🥩',
                    image       = 'steak_fries.png',
                    description = 'Izgara biftek ve çıtır patates kızartması ikilisi.',
                    ingredients = {
                        { item = 'raw_steak',   amount = 1, label = 'Raw Steak' },
                        { item = 'potato',      amount = 2, label = 'Potato'    },
                        { item = 'butter',      amount = 1, label = 'Butter'    },
                        { item = 'salt',        amount = 1, label = 'Salt'      },
                    },
                    prep = {
                        difficulty = 'hard',
                        duration   = 6000,
                    },
                    cook = {
                        appliance = 'grill',
                        duration  = 45000,
                    },
                    result = {
                        item       = 'steak_fries',
                        amount     = 1,
                        expiration = 18,
                        effects    = {
                            hunger = 120,
                            thirst = -10,
                            stress = -40,
                        },
                        effectsDisplay = {
                            '+120 Hunger',
                            '-40 Stress',
                        },
                    },
                },

                ['lobster_pasta'] = {
                    label       = 'Lobster Pasta',
                    icon        = '🦞',
                    image       = 'lobster_pasta.png',
                    description = 'İstakoz soslu premium makarna tabağı.',
                    ingredients = {
                        { item = 'lobster', amount = 1, label = 'Lobster' },
                        { item = 'pasta',   amount = 1, label = 'Pasta'   },
                        { item = 'cream',   amount = 1, label = 'Cream'   },
                        { item = 'garlic',  amount = 1, label = 'Garlic'  },
                    },
                    prep = {
                        difficulty = 'expert',
                        duration   = 8000,
                    },
                    cook = {
                        appliance = 'oven',
                        duration  = 60000,
                    },
                    result = {
                        item       = 'lobster_pasta',
                        amount     = 1,
                        expiration = 12,
                        effects    = {
                            hunger = 150,
                            stress = -80,
                        },
                        effectsDisplay = {
                            '+150 Hunger',
                            '-80 Stress',
                        },
                    },
                },

        },
    },

    -- ───────────────────────────────────────────────
    -- ÖRNEK: PIZZA THIS
    -- ───────────────────────────────────────────────
    ['pizzaria'] = {
        label      = 'Pizza This Kitchen',
        shortLabel = 'Pizza This',
        logo       = 'pizza.png',
        blip = {
            enabled = false,
            sprite  = 267,
            color   = 1,
            scale   = 0.7,
        },
        locations = {
            vector3(288.4, -966.9, 29.41),
        },
        recipes = {
            ['margherita'] = {
                label       = 'Margherita Pizza',
                icon        = '🍕',
                image       = 'pizza.png',
                description = 'Klasik İtalyan margarita pizzası.',
                ingredients = {
                    { item = 'pizza_dough',    amount = 1, label = 'Pizza Dough'    },
                    { item = 'tomato_sauce',   amount = 1, label = 'Tomato Sauce'   },
                    { item = 'mozzarella',     amount = 1, label = 'Mozzarella'     },
                    { item = 'basil',          amount = 1, label = 'Basil'          },
                },
                prep = {
                    difficulty = 'medium',
                    duration   = 5000,
                },
                cook = {
                    appliance = 'oven',
                    duration  = 50000,
                },
                result = {
                    item       = 'margherita_pizza',
                    amount     = 1,
                    expiration = 20,
                    effects    = {
                        hunger = 110,
                        stress = -30,
                    },
                    effectsDisplay = {
                        '+110 Hunger',
                        '-30 Stress',
                    },
                },
            },
        },
    },

}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  APPLIANCE GÖRSELLERİ                                         ║
-- ╚══════════════════════════════════════════════════════════════╝

Config.Appliances = {
    frying_pan = { label = 'Frying Pan', icon = 'pan.svg'   },
    oven       = { label = 'Oven',       icon = 'oven.svg'  },
    grill      = { label = 'Grill',      icon = 'grill.svg' },
}
