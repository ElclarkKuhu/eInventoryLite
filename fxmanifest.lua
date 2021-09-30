fx_version 'cerulean'

author 'Elclark'
version '1.0.1'
description 'Elclark Inventory Lite. Is an simple ESX Inventory with drag and drop and splittable items to organize your items and weapons'

game 'gta5'

ui_page 'NUI/index.html'

shared_script {
	'@es_extended/imports.lua',
}

files {
    'NUI/index.html',
    'NUI/style.css',
    'NUI/script.js',
    'NUI/eDB.js',
    'NUI/img/*.png',

    'NUI/jquery/jquery.js',
    'NUI/jquery/jquery-ui.js',
    'NUI/jquery/jquery-ui.css',
    'NUI/jquery/jquery-ui.min.css',
    'NUI/jquery/jquery-ui.min.js',
    'NUI/jquery/jquery-ui.structure.css',
    'NUI/jquery/jquery-ui.structure.min.css',
    'NUI/jquery/jquery-ui.theme.css',
    'NUI/jquery/jquery-ui.theme.min.css',

    'client/main.lua',
    'server/main.lua',
}

client_script {
    'client/main.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'es_extended',
	'mysql-async'
}
