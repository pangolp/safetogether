local Safetogether = {}
Safetogether.money = 0
Safetogether.canClaimLand = true

local function setSafehouseData(_title, _owner, _x, _y, _w, _h)
    local playerObj = getSpecificPlayer(0)
    local safeObj = SafeHouse.addSafeHouse(_x, _y, _w, _h, _owner, false)
    safeObj:setTitle(_title)
    safeObj:setOwner(_owner)
    safeObj:updateSafehouse(playerObj)
    safeObj:syncSafehouse()
end

Safetogether.ClaimLand = function()
    local _player = getPlayer()
    if _player then
        if (Safetogether.canClaimLand == false) then
            _player:Say("Ya perteneces un refugio.")
            _player:Say("Para poder reclamar uno.")
            _player:Say("Primero debes abandonar el actual.")
        elseif getCountSafePerPlayer(_player) < SandboxVars.safetogether.NumberOfClaimsPerPlayer then
            local _x1 = _player:getX() - 15
            local _x2 = _player:getX() + 15
            local _y1 = _player:getY() - 15
            local _y2 = _player:getY() + 15

            local setX = math.floor(math.min(_x1, _x2))
            local setY = math.floor(math.min(_y1, _y2))
            local setW = math.floor(math.abs(_x1 - _x2) + 1)
            local setH = math.floor(math.abs(_y1 - _y2) + 1)

            removeItem(SandboxVars.safetogether.ItemNeededToClaim, SandboxVars.safetogether.QuantityOfItemToClaim, _player)
            setSafehouseData("Safezone #" .. SafeHouse.getSafehouseList():size() + 1, _player:getUsername(), setX, setY, setW, setH)
        else
            _player:Say("Superaste el limite de safehouse a tu nombre que podes tener.")
        end
    end
end

Safetogether.OnFillWorldObjectContextMenu = function(player, context, worldobjects, test)

    if getCore():getGameMode() == 'LastStand' then return end

    local _player = getSpecificPlayer(player)
    local canClaim = false

    if _player:getVehicle() then return end

    Safetogether.money = getItems(_player, SandboxVars.safetogether.ItemNeededToClaim)
    Safetogether.canClaimLand = true

    for i = 0, SafeHouse.getSafehouseList():size() - 1 do
        local _safehouse = SafeHouse.getSafehouseList():get(i)
        if _safehouse:isOwner(_player) and SandboxVars.safetogether.NotClaimEvenIfYouHaveHouse then
            Safetogether.canClaimLand = false
            break
        else
            for j=0, _safehouse:getPlayers():size() - 1 do
                if (_safehouse:getPlayers():get(j) == _player:getUsername() and SandboxVars.safetogether.NotClaimIfYouAreGuest) then
                    Safetogether.canClaimLand = false
                    break
                end
            end
        end
    end

    local restrictedLand = {
        -- chunck 41, 27
        { posX = 12340, posY = 8134 }, { posX = 12340, posY = 8209 }, { posX = 12340, posY = 8290 }, { posX = 12340, posY = 8365 },
        { posX = 12415, posY = 8134 }, { posX = 12415, posY = 8209 }, { posX = 12415, posY = 8290 }, { posX = 12415, posY = 8365 },
        { posX = 12490, posY = 8134 }, { posX = 12490, posY = 8209 }, { posX = 12490, posY = 8290 }, { posX = 12490, posY = 8365 },
        { posX = 12565, posY = 8134 }, { posX = 12565, posY = 8209 }, { posX = 12565, posY = 8290 }, { posX = 12565, posY = 8365 },
        -- chunck 41, 28
        { posX = 12340, posY = 8434 }, { posX = 12340, posY = 8509 }, { posX = 12340, posY = 8590 }, { posX = 12340, posY = 8665 },
        { posX = 12415, posY = 8434 }, { posX = 12415, posY = 8509 }, { posX = 12415, posY = 8590 }, { posX = 12415, posY = 8665 },
        { posX = 12490, posY = 8434 }, { posX = 12490, posY = 8509 }, { posX = 12490, posY = 8590 }, { posX = 12490, posY = 8665 },
        { posX = 12565, posY = 8434 }, { posX = 12565, posY = 8509 }, { posX = 12565, posY = 8590 }, { posX = 12565, posY = 8665 },
        -- chunck 41, 29
        { posX = 12340, posY = 8734 }, { posX = 12340, posY = 8809 }, { posX = 12340, posY = 8890 }, { posX = 12340, posY = 8965 },
        { posX = 12415, posY = 8734 }, { posX = 12415, posY = 8809 }, { posX = 12415, posY = 8890 }, { posX = 12415, posY = 8965 },
        { posX = 12490, posY = 8734 }, { posX = 12490, posY = 8809 }, { posX = 12490, posY = 8890 }, { posX = 12490, posY = 8965 },
        { posX = 12565, posY = 8734 }, { posX = 12565, posY = 8809 }, { posX = 12565, posY = 8890 }, { posX = 12565, posY = 8965 },
        -- chunck 41, 30
        { posX = 12340, posY = 9034 }, { posX = 12340, posY = 9109 }, { posX = 12340, posY = 9190 }, { posX = 12340, posY = 9265 },
        { posX = 12415, posY = 9034 }, { posX = 12415, posY = 9109 }, { posX = 12415, posY = 9190 }, { posX = 12415, posY = 9265 },
        { posX = 12490, posY = 9034 }, { posX = 12490, posY = 9109 }, { posX = 12490, posY = 9190 }, { posX = 12490, posY = 9265 },
        { posX = 12565, posY = 9034 }, { posX = 12565, posY = 9109 }, { posX = 12565, posY = 9190 }, { posX = 12565, posY = 9265 },
        -- chunck 41, 31
        { posX = 12340, posY = 9334 }, { posX = 12340, posY = 9409 }, { posX = 12340, posY = 9490 }, { posX = 12340, posY = 9565 },
        { posX = 12415, posY = 9334 }, { posX = 12415, posY = 9409 }, { posX = 12415, posY = 9490 }, { posX = 12415, posY = 9565 },
        { posX = 12490, posY = 9334 }, { posX = 12490, posY = 9409 }, { posX = 12490, posY = 9490 }, { posX = 12490, posY = 9565 },
        { posX = 12565, posY = 9334 }, { posX = 12565, posY = 9409 }, { posX = 12565, posY = 9490 }, { posX = 12565, posY = 9565 },
        -- chunck 42, 27
        { posX = 12640, posY = 8134 }, { posX = 12640, posY = 8209 }, { posX = 12640, posY = 8290 }, { posX = 12640, posY = 8365 },
        { posX = 12715, posY = 8134 }, { posX = 12715, posY = 8209 }, { posX = 12715, posY = 8290 }, { posX = 12715, posY = 8365 },
        { posX = 12790, posY = 8134 }, { posX = 12790, posY = 8209 }, { posX = 12790, posY = 8290 }, { posX = 12790, posY = 8365 },
        { posX = 12865, posY = 8134 }, { posX = 12865, posY = 8209 }, { posX = 12865, posY = 8290 }, { posX = 12865, posY = 8365 },
        -- chunck 42, 28
        { posX = 12640, posY = 8434 }, { posX = 12640, posY = 8509 }, { posX = 12640, posY = 8590 }, { posX = 12640, posY = 8665 },
        { posX = 12715, posY = 8434 }, { posX = 12715, posY = 8509 }, { posX = 12715, posY = 8590 }, { posX = 12715, posY = 8665 },
        { posX = 12790, posY = 8434 }, { posX = 12790, posY = 8509 }, { posX = 12790, posY = 8590 }, { posX = 12790, posY = 8665 },
        { posX = 12865, posY = 8434 }, { posX = 12865, posY = 8509 }, { posX = 12865, posY = 8590 }, { posX = 12865, posY = 8665 },
        -- chunck 42, 29
        { posX = 12640, posY = 8734 }, { posX = 12640, posY = 8809 }, { posX = 12640, posY = 8890 }, { posX = 12640, posY = 8965 },
        { posX = 12715, posY = 8734 }, { posX = 12715, posY = 8809 }, { posX = 12715, posY = 8890 }, { posX = 12715, posY = 8965 },
        { posX = 12790, posY = 8734 }, { posX = 12790, posY = 8809 }, { posX = 12790, posY = 8890 }, { posX = 12790, posY = 8965 },
        { posX = 12865, posY = 8734 }, { posX = 12865, posY = 8809 }, { posX = 12865, posY = 8890 }, { posX = 12865, posY = 8965 },
        -- chunck 42, 30
        { posX = 12640, posY = 9034 }, { posX = 12640, posY = 9109 }, { posX = 12640, posY = 9190 }, { posX = 12640, posY = 9265 },
        { posX = 12715, posY = 9034 }, { posX = 12715, posY = 9109 }, { posX = 12715, posY = 9190 }, { posX = 12715, posY = 9265 },
        { posX = 12790, posY = 9034 }, { posX = 12790, posY = 9109 }, { posX = 12790, posY = 9190 }, { posX = 12790, posY = 9265 },
        { posX = 12865, posY = 9034 }, { posX = 12865, posY = 9109 }, { posX = 12865, posY = 9190 }, { posX = 12865, posY = 9265 },
        -- chunck 42, 31
        { posX = 12640, posY = 9334 }, { posX = 12640, posY = 9409 }, { posX = 12640, posY = 9490 }, { posX = 12640, posY = 9565 },
        { posX = 12715, posY = 9334 }, { posX = 12715, posY = 9409 }, { posX = 12715, posY = 9490 }, { posX = 12715, posY = 9565 },
        { posX = 12790, posY = 9334 }, { posX = 12790, posY = 9409 }, { posX = 12790, posY = 9490 }, { posX = 12790, posY = 9565 },
        { posX = 12865, posY = 9334 }, { posX = 12865, posY = 9409 }, { posX = 12865, posY = 9490 }, { posX = 12865, posY = 9565 },
        -- chunck 44, 27
        { posX = 13240, posY = 8134 }, { posX = 13240, posY = 8209 }, { posX = 13240, posY = 8290 }, { posX = 13240, posY = 8365 },
        { posX = 13315, posY = 8134 }, { posX = 13315, posY = 8209 }, { posX = 13315, posY = 8290 }, { posX = 13315, posY = 8365 },
        { posX = 13390, posY = 8134 }, { posX = 13390, posY = 8209 }, { posX = 13390, posY = 8290 }, { posX = 13390, posY = 8365 },
        { posX = 13465, posY = 8134 }, { posX = 13465, posY = 8209 }, { posX = 13465, posY = 8290 }, { posX = 13465, posY = 8365 },

    }

    for _, coord in ipairs(restrictedLand) do
        if (math.floor(_player:getX()) == coord.posX and math.floor(_player:getY()) == coord.posY) then
            canClaim = true
        end
    end

    local _playerGridSquare = getCell():getOrCreateGridSquare(_player:getX(), _player:getY(), 0)
    if _playerGridSquare then
        if SafeHouse.getSafeHouse(_playerGridSquare) then
            canClaim = false
        end
    end

    if Safetogether.money >= SandboxVars.safetogether.QuantityOfItemToClaim and canClaim then
        context:addOption("Reclamar terreno", _player, Safetogether.ClaimLand)
    end
end

Events.OnFillWorldObjectContextMenu.Add(Safetogether.OnFillWorldObjectContextMenu)
