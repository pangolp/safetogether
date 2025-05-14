function removeItem(item, amount, player)
    if player then
        local _inventory = player:getInventory()
        if _inventory then
            local _items = _inventory:getItems()
            local _removedCount = 0

            for i = 0, _items:size() - 1 do
                local _item = _items:get(i)
                if _item:getFullType() == item then
                    local _itemCount = _item:getCount()
                    local _canRemove = math.min(amount - _removedCount, _itemCount)

                    _item:setCount(_itemCount - _canRemove)
                    _removedCount = _removedCount + _canRemove

                    if _removedCount >= amount then
                        break
                    end
                end
            end

            local _itemsToRemove = {}
            for i = 0, _items:size() - 1 do
                local _item = _items:get(i)
                if _item:getFullType() == item and _item:getCount() <= 0 then
                    table.insert(_itemsToRemove, _item)
                end
            end

            for _, _itemToRemove in ipairs(_itemsToRemove) do
                _inventory:Remove(_itemToRemove)
            end
        end
    end
end

function getItems(player, item)
    local _count = 0

    if player then
        local _inventory = player:getInventory()
        if _inventory then
            local _items = _inventory:getItems()
            if _items then
                for i = 0, _items:size() - 1 do
                    local _item = _items:get(i)
                    if _item:getFullType() == item then
                        _count = _count + _item:getCount()
                    end
                end
            end
        end
    end

    return _count
end

function getCountSafePerPlayer(player)
    local _count = 0

    for i = 0, SafeHouse.getSafehouseList():size() - 1 do
        local _safehouse = SafeHouse.getSafehouseList():get(i)
        if _safehouse:isOwner(player) then
            _count = _count + 1
        end
    end

    return _count
end
