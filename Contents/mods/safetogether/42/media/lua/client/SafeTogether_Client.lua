--[[
    Safe Together - client side.

    * Receives the mod's server commands (invitation dialog + membership mirror).
    * Redirects the "Safehouse" user-panel button to the multi-safehouse list.
    * Adds a "claim your own safehouse" context option for players who are guests
      elsewhere (the vanilla claim option is disabled for them by the base game).
]]

require "SafeTogether_Shared"
require "ISUI/UserPanel/ISUserPanelUI"
require "ISUI/UserPanel/ISSafehouseUI"

SafeTogether.Client = SafeTogether.Client or {}
SafeTogether.inviteDialogs = SafeTogether.inviteDialogs or {}

--=========================================================================--
--  Invitation dialog
--=========================================================================--

local function onAnswerInvite(button)
    local data = button.parent.stData
    SafeTogether.inviteDialogs[data.host] = nil
    sendClientCommand(getPlayer(), SafeTogether.MODULE, "acceptInvite", {
        x = data.x, y = data.y, w = data.w, h = data.h,
        accepted = (button.internal == "YES"),
    })
end

local function onReceiveInvite(args)
    local existing = SafeTogether.inviteDialogs[args.host]
    if existing and existing:isReallyVisible() then return end

    local modal = ISModalDialog:new(
        getCore():getScreenWidth() / 2 - 175, getCore():getScreenHeight() / 2 - 75,
        350, 150, getText("IGUI_SafehouseUI_Invitation", args.host), true, nil, onAnswerInvite)
    modal:initialise()
    modal:addToUIManager()
    modal.stData = args
    modal.moveWithMouse = true
    SafeTogether.inviteDialogs[args.host] = modal
end

--=========================================================================--
--  Membership mirror (keep local SafeHouse objects in sync live)
--=========================================================================--

local function onMemberAdded(args)
    local sh = SafeHouse.getSafeHouse(args.x, args.y, args.w, args.h)
    if sh then
        sh:addPlayer(args.member) -- idempotent
        triggerEvent("OnSafehousesChanged")
    end
end

local function onSafehouseAdded(args)
    local sh = SafeHouse.getSafeHouse(args.x, args.y, args.w, args.h)
    if not sh then
        sh = SafeHouse.addSafeHouse(args.x, args.y, args.w, args.h, args.owner)
    end
    if sh then
        sh:setOwner(args.owner)
        if args.title and args.title ~= "" then
            sh:setTitle(args.title)
        end
        triggerEvent("OnSafehousesChanged")
    end
end

-- Mirror a respawn change pushed by the server (see SafeTogether_Server.setRespawn).
-- Keeps every client's local SafeHouse objects in sync so the tickbox and the
-- respawn indicator in the safehouse list reflect the single-respawn rule.
local function onRespawnChanged(args)
    local username = args.member
    if args.set then
        -- Single respawn: clear the flag everywhere for this player first.
        local list = SafeHouse.getSafehouseList()
        for i = 0, list:size() - 1 do
            list:get(i):setRespawnInSafehouse(false, username)
        end
    end
    local sh = SafeHouse.getSafeHouse(args.x, args.y, args.w, args.h)
    if sh then
        sh:setRespawnInSafehouse(args.set and true or false, username)
    end

    -- Refresh an open safehouse UI tickbox belonging to the local player.
    local localPlayer = getPlayer()
    if localPlayer and localPlayer:getUsername() == username
        and ISSafehouseUI.instance and ISSafehouseUI.instance.respawn
        and ISSafehouseUI.instance.safehouse then
        ISSafehouseUI.instance.respawn.selected[1] =
            ISSafehouseUI.instance.safehouse:isRespawnInSafehouse(username)
    end

    triggerEvent("OnSafehousesChanged")
end

local ServerHandlers = {
    receiveInvite = onReceiveInvite,
    memberAdded = onMemberAdded,
    safehouseAdded = onSafehouseAdded,
    respawnChanged = onRespawnChanged,
}

local function onServerCommand(module, command, args)
    if module ~= SafeTogether.MODULE then return end
    local handler = ServerHandlers[command]
    if handler and args then
        handler(args)
    end
end

Events.OnServerCommand.Add(onServerCommand)

--=========================================================================--
--  User panel: open the multi-safehouse list instead of the single safehouse
--=========================================================================--

-- Relabel the panel button to the plural, since it now opens a LIST of every
-- safehouse the player owns or is a guest in (not a single one).
SafeTogether.Client.oldCreate = ISUserPanelUI.create

function ISUserPanelUI:create()
    SafeTogether.Client.oldCreate(self)
    if self.safehouseBtn then
        self.safehouseBtn.title = getText("IGUI_SafeTogether_SafehousesBtn")
    end
end

SafeTogether.Client.oldOnOptionMouseDown = ISUserPanelUI.onOptionMouseDown

function ISUserPanelUI:onOptionMouseDown(button, x, y)
    if button.internal == "SAFEHOUSEPANEL" then
        if SafeHouse.hasSafehouse(self.player) then
            if ISSafeTogetherhousesList.instance then
                ISSafeTogetherhousesList.instance:close()
            end
            local ui = ISSafeTogetherhousesList:new(50, 50, 600, 600, self.player)
            ui:initialise()
            ui:addToUIManager()
        end
        return
    end
    SafeTogether.Client.oldOnOptionMouseDown(self, button, x, y)
end

--=========================================================================--
--  Respawn: route the vanilla tickbox through the mod's server command
--=========================================================================--

-- The vanilla ISSafehouseUi respawn tickbox calls sendSafehouseChangeRespawn,
-- which triggers the "SafeHouseMember" anti-cheat and kicks safehouse OWNERS
-- (they are not in the players list). Send the mod command instead so the
-- change is applied server-side without the vanilla packet / anti-cheat, and
-- so the single-respawn rule is enforced. See SafeTogether_Server.setRespawn.
function ISSafehouseUI:onClickRespawn(clickedOption, enabled)
    local sh = self.safehouse
    if not sh then return end
    sendClientCommand(self.player, SafeTogether.MODULE, "setRespawn", {
        x = sh:getX(), y = sh:getY(), w = sh:getW(), h = sh:getH(),
        set = enabled and true or false,
    })
end

--=========================================================================--
--  Context menu: let a guest claim their own (first) safehouse
--=========================================================================--

local function onClaimOwn(worldobjects, square, playerObj, x, y, w, h, title)
    sendClientCommand(getPlayer(), SafeTogether.MODULE, "claimOwn", {
        x = x, y = y, w = w, h = h, title = title,
    })
end

local function onFillWorldObjectContextMenu(playerIndex, context, worldobjects, test)
    if test then return end
    local playerObj = getSpecificPlayer(playerIndex)
    if not playerObj then return end
    if playerObj:getVehicle() then return end

    local username = playerObj:getUsername()
    -- Only relevant when the player owns nothing yet but IS a guest somewhere:
    -- in that case the base game greys out its own "Claim Safehouse" option.
    if SafeTogether.getOwnedSafehouse(username) ~= nil then return end
    if SafeHouse.hasSafehouse(playerObj) == nil then return end

    local square
    for _, o in ipairs(worldobjects) do
        local sq = o:getSquare()
        if sq then square = sq break end
    end
    if not square or not square:getBuilding() then return end
    if SafeHouse.getSafeHouse(square) ~= nil then return end

    local def = square:getBuilding():getDef()
    if not def then return end
    local x = def:getX() - 2
    local y = def:getY() - 2
    local w = def:getW() + 4
    local h = def:getH() + 4

    context:addOption(getText("ContextMenu_SafeTogether_ClaimOwn"), worldobjects, onClaimOwn,
        square, playerObj, x, y, w, h, "Safehouse")
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
