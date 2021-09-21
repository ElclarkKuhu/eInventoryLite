let data = []

function addTo(db, item) {
    db[db.length] = {
        'id': item.id,
        'name': item.name,
        'label': item.label,
        'slot': item.slot,
        'type': item.type,
        'usable': item.usable,
        'canRemove': item.canRemove
    }
}

function getFrom(db, name) {
    return db.find(e => e.name === name);
}

function removeFrom(db, id) {
    return db.filter(i => id != i.id)
}

function clearDB() {
    return []
}