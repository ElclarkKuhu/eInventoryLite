let data = []

function addTo(db, item) {
    db[db.length] = {
        'id': item.id,
        'name': item.name,
        'label': item.label,
        'slot': item.slot,
        'type': item.type,
        'weight': item.weight,
        'usable': item.usable,
        'canRemove': item.canRemove
    }
}

function getFrom(db, name, id) {
    if (id) {
        return db.find(e => e.id === id);
    }
    return db.find(e => e.name === name);
}

function removeFrom(db, id) {
    return db.filter(i => id != i.id)
}

function clearDB() {
    return []
}

// data[data.length] = {
//     'id': 'bread-1',
//     'name': 'bread',
//     'label': 'Bread',
//     'slot': 'it1-c',
//     'type': 'item_standard',
//     'weight': 1.00,
//     'usable': true,
//     'canRemove': true
// }

// data[data.length] = {
//     'id': 'bread-2',
//     'name': 'bread',
//     'label': 'Bread',
//     'slot': 'it1-c',
//     'type': 'item_standard',
//     'weight': 1.00,
//     'usable': true,
//     'canRemove': true
// }

// data[data.length] = {
//     'id': 'bread-3',
//     'name': 'bread',
//     'label': 'Bread',
//     'slot': 'it1-c',
//     'type': 'item_standard',
//     'weight': 1.00,
//     'usable': true,
//     'canRemove': true
// }

// data[data.length] = {
//     'id': 'water-1',
//     'name': 'water',
//     'label': 'Water',
//     'slot': 'it2-c',
//     'type': 'item_standard',
//     'weight': 1.00,
//     'usable': true,
//     'canRemove': true
// }

// data[data.length] = {
//     'id': 'water-2',
//     'name': 'water',
//     'label': 'Water',
//     'slot': 'it2-c',
//     'type': 'item_standard',
//     'weight': 1.00,
//     'usable': true,
//     'canRemove': true
// }