let containers = document.querySelectorAll('.it')

$('.container').hide()

window.addEventListener('message', (event) => {
    let eventData = event.data

    if (eventData.action === 'addItem') {
        eventData.data.forEach(item => {
            addTo(data, item)
        });
        reloadData()
        return
    }

    if (eventData.action === 'removeItem') {
        data = removeFrom(data, eventData.id)
        reloadData()
        return
    }

    if (eventData.action === 'clearItem') {
        data = clearDB()
        reloadData()
    }

    if (eventData.action === 'display') {

        if (eventData.is) {
            $('.container').show()
            reloadData()
        } else {
            $('.container').fadeOut()
        }

        return
    }
})

function getFirstFreeSlot(stack) {
    if (stack) {
        for (let i = 0; i < containers.length; i++) {
            const container = containers[i];
            if (container.innerHTML === '') {
                return container.id
            } else if (container.lastChild) {
                if (container.lastChild.getAttribute('name') === stack) {
                    return container.id
                }
            }
        }
    } else {
        for (let i = 0; i < containers.length; i++) {
            const container = containers[i];
            if (container.innerHTML === '') {
                return container.id
            }
        }
    }
}

function reloadData() {
    containers.forEach(container => {
        container.innerHTML = ''
    })

    data.forEach(obj => {
        let container = document.getElementById(obj.slot)
        if (container.innerHTML === '') {
            createItem(obj, container)
        } else {
            let amount = container.lastChild
            amount.innerText = Number(amount.innerText) + 1
        }
    })

    getFirstFreeSlot()
}

function createItem(obj, append) {
    let item = document.createElement('div')

    item.id = obj.id
    item.setAttribute('name', obj.name)
    item.innerText = 1
    item.style.backgroundImage = `url('img/${obj.name}.png')`
    item.classList.add('it-img')

    append.appendChild(item)

    $(`#${obj.id}`).draggable({
        helper: 'clone',
        appendTo: 'body',
        zIndex: 99999,
        revert: 'invalid',
        start: function () {
            item.classList.add('dragging')
        },
        stop: function () {
            item.classList.remove('dragging')
        }
    });

    $(`#${obj.id}`).hover(() => {
        $('#item-name').html(obj.label)
    })

    if (obj.usable) {
        $(`#${obj.id}`).click(function (event) {
            closeNUI()
            $.post(`https://${GetParentResourceName()}/useItem`, JSON.stringify({
                'id': event.currentTarget.id
            }));
            data = removeFrom(data, obj.id)
        });
    }

    if (obj.canRemove) {
        $(`#${obj.id}`).on('contextmenu', function (event) {
            closeNUI()
            if (event.shiftKey) {
                $.post(`https://${GetParentResourceName()}/dropItem`, JSON.stringify({
                    'id' : event.currentTarget.id,
                    'slot' : obj.slot,
                    'all' : true
                }));
                data.filter(i => obj.name != i.name && obj.slot === i.slot)
            } else {
                $.post(`https://${GetParentResourceName()}/dropItem`, JSON.stringify({
                    'id' : event.currentTarget.id,
                    'all' : false
                }));
                data = removeFrom(data, obj.id)
            }
            return false
        });
    }
}

$('.it').droppable({
    hoverClass: 'dragged-over',
    drop: function (event, ui) {
        updateData(event.target, ui.draggable[0], event.shiftKey)
    }
});

function updateData(container, draggable, shiftKey) {
    let draggableName = draggable.getAttribute('name')

    let index = data.findIndex(e => e.id === draggable.id)
    if (container.lastChild) {
        if (container.lastChild.getAttribute('name') !== draggable.getAttribute('name')) {
            let container1 = draggable.parentElement
            let draggable1 = container.firstChild

            data.forEach((item, i) => {

                if (item.name === draggableName && item.slot === draggable.parentElement.id) {
                    data[i].slot = container.id
                }

                if (item.name === draggable1.getAttribute('name') && item.slot === draggable1.parentElement.id) {
                    data[i].slot = container1.id
                }
            })

            $.post(`https://${GetParentResourceName()}/moveSlot`, JSON.stringify({
                'mode': 'trade',
                'nameFrom': draggableName,
                'nameTo': draggable1.getAttribute('name'),
                'slotFrom': container1.id,
                'slotTo': container.id
            }));
        } else {
            if (shiftKey) {
                data.forEach((item, i) => {
                    if (item.name === draggableName && item.slot === draggable.parentElement.id) {
                        data[i].slot = container.id
                    }
                })

                $.post(`https://${GetParentResourceName()}/moveSlot`, JSON.stringify({
                    'mode': 'move',
                    'all': true,
                    'id': data[index].id,
                    'name': draggableName,
                    'slotFrom': draggable.parentElement.id,
                    'slotTo': container.id
                }));
            } else {
                data[index].slot = container.id

                $.post(`https://${GetParentResourceName()}/moveSlot`, JSON.stringify({
                    'mode': 'move',
                    'all': false,
                    'id': data[index].id,
                    'slotTo': container.id
                }));
            }
        }
    } else {
        if (shiftKey) {
            data.forEach((item, i) => {
                if (item.name === draggableName && item.slot === draggable.parentElement.id) {
                    data[i].slot = container.id
                }
            })
            $.post(`https://${GetParentResourceName()}/moveSlot`, JSON.stringify({
                'mode': 'move',
                'all': true,
                'name': draggableName,
                'id': data[index].id,
                'slotFrom': draggable.parentElement.id,
                'slotTo': container.id
            }));
        } else {
            data[index].slot = container.id
            $.post(`https://${GetParentResourceName()}/moveSlot`, JSON.stringify({
                'mode': 'move',
                'all': false,
                'id': data[index].id,
                'slotTo': container.id
            }));
        }
    }

    reloadData()

    container.classList.remove('dragged-over')
}

function closeNUI(){
    $('.container').fadeOut()
    $.post(`https://${GetParentResourceName()}/close`, JSON.stringify({}));
}

$('body').on('keydown', function (key) {
    if ([113, 27, 90, 87, 83, 65, 68].includes(key.which)) {
        closeNUI()
    }
});