let containers
let display = false
let isLoading = false
let showMiddleMenu = false
let inventoryMaxWeight = 0
let contextElement = document.getElementById('context-menu')
let infoMenu = document.getElementById('info-menu')

const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)')
let reducedMotion = mediaQuery.matches
mediaQuery.addEventListener('change', () => {
    reducedMotion = mediaQuery.matches
})

fetch(`https://${GetParentResourceName()}/getConfig`, {
    method: 'GET',
    headers: {
        'Content-Type': 'application/json; charset=UTF-8',
    }
}).then(resp => resp.json()).then((resp) => {
    showMiddleMenu = resp.showMiddleMenu
    setupContainers(0, resp.playerInventorySlot)

    if (showMiddleMenu) {
        $('#middle-menu').droppable({
            hoverClass: 'mid-dragged-over',
            drop: function (event, ui) {
                event.preventDefault()
        
                useItem(ui.draggable[0].id)
            }
        })
    }
});

window.addEventListener('message', (event) => {
    let eventData = event.data

    if (eventData.action === 'addItem') {
        setLoading(0, false)

        inventoryMaxWeight = eventData.weights.maxWeight

        eventData.data.forEach(item => {
            addTo(data, item)
        })
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
            if (eventData.showLoading) {
                setLoading(0, true)
            }

            setDisplay(1)
            reloadData()
        } else {
            setDisplay(0)
        }

        return
    }
})

// Type is the inventory type
//  0 = Inventory / Player Items
function setLoading(type, is) {
    if (type === 0) {
        if (is) {
            isLoading = is
            containers.forEach(container => {
                container.style.animation = 'loading-animation 1000ms ease infinite'
            })
        } else {
            isLoading = is
            containers.forEach(container => {
                container.style.animation = 'none'
            })
        }
    }
}

// Type is the inventory type
//  0 = Inventory / Player Items
// Count multiple of 5 if possible
function setupContainers(type, count) {
    if (type === 0) {
        let itemContainer = document.getElementById('items')

        itemContainer.innerHTML = ''

        for (let i = 1; i <= count; i++) {
            let item = document.createElement('div')

            item.id = `it${i}-c`
            item.classList.add('it-c')

            itemContainer.appendChild(item)
        }

        $('.it-c').droppable({
            hoverClass: 'dragged-over',
            drop: function (event, ui) {
                updateData(event.target, ui.draggable[0], event.shiftKey)
            }
        })

        containers = document.querySelectorAll('.it-c')
    }
}

function useItem(id) {
    let value = getFrom(data, null, id)

    if (value.usable) {
        closeNUI()
        $.post(`https://${GetParentResourceName()}/useItem`, JSON.stringify({
            'name': value.name,
            'id': id
        }))
        data = removeFrom(data, id)
    } else {
        document.getElementById(id).parentElement.style.animation = 'shake-animation 500ms ease infinite'
        setTimeout(() => {
            document.getElementById(id).parentElement.style.animation = 'none'
        }, 500);
    }
}

function setDisplay(value) {
    let middleMenu = document.getElementById('middle-menu')
    let inventory = document.getElementById('inventory')
    let wrapper = document.querySelector('.wrapper')

    if (value === 0) {
        display = false
        
        if (!reducedMotion) {
            inventory.style.transition = 'transform 500ms cubic-bezier(0.74, 0.02, 0.07, 1), opacity 250ms ease 250ms'
            middleMenu.style.transition = 'transform 500ms cubic-bezier(0.74, 0.02, 0.07, 1), opacity 250ms ease 250ms'
        }
        inventory.style.transform = 'translateY(500px)'
        inventory.style.opacity = '0'

        middleMenu.style.transform = 'translateY(500px)'
        middleMenu.style.opacity = '0'

        wrapper.style.backgroundColor = 'rgb(0 0 0 / 0)'
    } else if (value === 1) {
        display = true

        if (!reducedMotion) {
            inventory.style.transition = 'transform 500ms cubic-bezier(0.74, 0.02, 0.07, 1), opacity 250ms ease'
            middleMenu.style.transition = 'transform 500ms cubic-bezier(0.74, 0.02, 0.07, 1), opacity 250ms ease'
        }

        inventory.style.transform = 'translateY(0)'
        inventory.style.opacity = '1'

        if (showMiddleMenu) {
            middleMenu.style.transform = 'translateY(0)'
            middleMenu.style.opacity = '.75'
        }

        wrapper.style.backgroundColor = 'rgb(0 0 0 / .30)'
    }
}

function setWeight(type, weight, maxWeight) {
    if (type === 0) {
        document.getElementById('bar').style.width = ((weight * 100) / maxWeight).toString() + '%'
        document.getElementById('weight').innerText = weight.toFixed(2) + 'Kg'
        document.getElementById('max-weight').innerText = maxWeight.toFixed(2) + 'Kg'
    }
}

function getFirstFreeSlot(stack) {
    if (stack) {
        for (let i = 0; i < containers.length; i++) {
            const container = containers[i]
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
            const container = containers[i]
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

    let weight = 0 
    data.forEach(obj => {
        let container = document.getElementById(obj.slot)
        weight += obj.weight

        if (container.innerHTML === '') {
            createItem(obj, container)
        } else {
            let amount = container.firstChild.firstChild

            container.innerHTML = ''
            createItem(obj, container, Number(amount.innerText) + 1)
        }
    })

    setWeight(0, weight, inventoryMaxWeight)
    contextElement.classList.remove('active')
}

function createItem(obj, append, count) {
    let item = document.createElement('div')

    item.id = obj.id
    item.setAttribute('name', obj.name)
    item.classList.add('it')

    let itemCount = document.createElement('p')
    itemCount.innerText = count || 1
    itemCount.classList.add('it-count')
    itemCount.style.pointerEvents = "none"
    item.appendChild(itemCount)

    let itemImage = document.createElement('div')
    itemImage.classList.add('it-img')
    itemImage.style.backgroundImage = `url('img/${obj.name}.png')`
    itemImage.style.pointerEvents = "none"
    item.appendChild(itemImage)

    let itemLabel = document.createElement('p')
    itemLabel.innerText = obj.label
    itemLabel.classList.add('it-label')
    itemLabel.style.pointerEvents = "none"
    item.appendChild(itemLabel)

    append.appendChild(item)

    $(`#${obj.id}`).draggable({
        helper: 'clone',
        appendTo: 'body',
        scroll: false,
        distance: 5,
        zIndex: 222,
        revert: 'invalid',
        start: function () {
            item.classList.add('dragging')
        },
        stop: function () {
            item.classList.remove('dragging')
        }
    })

    $(`#${obj.id}`).hover((event) => {
        if (event.type === "mouseenter" && event.target.id === obj.id) {

            infoMenu.style.left = event.pageX - event.offsetX + document.getElementById(obj.id).offsetWidth + 5 + 'px'
            infoMenu.style.top = event.pageY - event.offsetY + document.getElementById(obj.id).offsetHeight - infoMenu.offsetHeight + 'px'

            document.getElementById('info-menu-label').innerText = obj.label
            document.getElementById('info-menu-weight').innerText = (obj.weight).toFixed(2) + 'Kg'

            infoMenu.classList.add('active')
        } else {
            infoMenu.classList.remove('active')
        }
    })

    $(`#${obj.id}`).click(function (event) {
        event.preventDefault()

        useItem(obj.id)
    })

    $(`#${obj.id}`).on('contextmenu', function (event) {
        event.preventDefault()

        contextElement.style.left = event.pageX - event.offsetX + document.getElementById(obj.id).offsetWidth + 5 + 'px'
        contextElement.style.top = event.pageY - event.offsetY + document.getElementById(obj.id).offsetHeight - contextElement.offsetHeight + 'px'
        contextElement.classList.add('active')
        infoMenu.classList.remove('active')

        $('#cm-use').unbind().click(function (e) {
            e.preventDefault()

            useItem(obj.id)
        })

        if (obj.canRemove) {
            $('#cm-drop').unbind().click(function (e) {
                e.preventDefault()

                closeNUI()
                $.post(`https://${GetParentResourceName()}/dropItem`, JSON.stringify({
                    'id': obj.id,
                    'all': false
                }))
                data = removeFrom(data, obj.id)
            })

            $('#cm-dropAll').unbind().click(function (e) {
                e.preventDefault()

                closeNUI()
                $.post(`https://${GetParentResourceName()}/dropItem`, JSON.stringify({
                    'id': obj.id,
                    'slot': obj.slot,
                    'all': true
                }))
                data = data.filter(i => obj.name != i.name && obj.slot === i.slot)
            })
        } else {
            $('#cm-drop').unbind().click(function (e) {
                e.preventDefault()

                document.getElementById(obj.id).parentElement.style.animation = 'shake-animation 500ms ease infinite'
                setitemQuality(obj.id, 100)
                setTimeout(() => {
                    document.getElementById(obj.id).parentElement.style.animation = 'none'
                    setitemQuality(obj.id, 0)
                }, 500);
            })

            $('#cm-dropAll').unbind().click(function (e) {
                e.preventDefault()

                document.getElementById(obj.id).parentElement.style.animation = 'shake-animation 500ms ease infinite'
                setTimeout(() => {
                    document.getElementById(obj.id).parentElement.style.animation = 'none'
                }, 500);
            })
        }

        return false
    })
}

window.addEventListener('click', () => {
    contextElement.classList.remove('active')
})

function updateData(container, draggable, shiftKey) {
    if (isLoading) {
        document.getElementById('inventory').style.animation = 'shake-animation 500ms ease infinite'
        setTimeout(() => {
            document.getElementById('inventory').style.animation = 'none'
        }, 500);
    } else {
        let draggableName = draggable.getAttribute('name')

        let index = data.findIndex(e => e.id === draggable.id)
        if (container.lastChild) {
            if (container.lastChild.getAttribute('name') !== draggable.getAttribute('name')) {
                let container2 = draggable.parentElement
                let draggable2 = container.firstChild

                data.forEach((item, i) => {

                    if (item.name === draggableName && item.slot === draggable.parentElement.id) {
                        data[i].slot = container.id
                    }

                    if (item.name === draggable2.getAttribute('name') && item.slot === draggable2.parentElement.id) {
                        data[i].slot = container2.id
                    }
                })

                $.post(`https://${GetParentResourceName()}/moveSlot`, JSON.stringify({
                    'mode': 'trade',
                    'nameFrom': draggableName,
                    'nameTo': draggable2.getAttribute('name'),
                    'slotFrom': container2.id,
                    'slotTo': container.id
                }))
            } else {
                if (!shiftKey) {
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
                    }))

                } else {
                    data[index].slot = container.id

                    $.post(`https://${GetParentResourceName()}/moveSlot`, JSON.stringify({
                        'mode': 'move',
                        'all': false,
                        'id': data[index].id,
                        'slotTo': container.id
                    }))
                }
            }
        } else {
            if (!shiftKey) {
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
                }))
            } else {
                data[index].slot = container.id

                $.post(`https://${GetParentResourceName()}/moveSlot`, JSON.stringify({
                    'mode': 'move',
                    'all': false,
                    'id': data[index].id,
                    'slotTo': container.id
                }))
            }
        }
        reloadData()
    }
}

function closeNUI() {
    setDisplay(0)

    infoMenu.classList.remove('active')
    contextElement.classList.remove('active')

    $.post(`https://${GetParentResourceName()}/close`, JSON.stringify({}))

    data = clearDB()
    reloadData()
}

$('body').on('keydown', function (key) {
    if ([113, 27, 90, 87, 83, 65, 68].includes(key.which)) {
        closeNUI()
    }

    if ([16].includes(key.which)) {
        document.getElementById('shift').style.color = 'var(--clr-accent)'
    }
})

$('body').on('keyup', function (key) {
    if ([16].includes(key.which)) {
        document.getElementById('shift').style.color = 'var(--clr-txt)'
    }
})