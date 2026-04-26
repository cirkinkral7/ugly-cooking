fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Gladius Development'
description 'Gladius Cooking — Premium Multi-Step Cooking System (QB-Core + ox_inventory)'
version '1.0.0'

shared_scripts {
    'middleware/v2_settings.js',
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
    'locales/tr.lua',
}

client_scripts {
    'client/cooking.lua',
    'client/main.lua',
    'client/nui.lua',
}

server_scripts {
    'server/main.lua',
    'server/cooking.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png',
    'html/img/*.svg',
}

dependencies {
    'qb-core',
    'ox_inventory',
    'ox_lib',
}
