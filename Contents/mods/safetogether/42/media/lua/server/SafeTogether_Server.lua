--[[
    Safe Together - server-authoritative logic.

    Handles the mod's own client commands. Because this runs on the server it may
    call SafeHouse methods (addPlayer / addSafeHouse) directly, bypassing the
    Build 42 "one safehouse per player" limit that the vanilla Java packet
    handlers enforce. All validation the vanilla handlers would normally do is
    re-implemented here so players cannot abuse the commands.
]]

require "SafeTogether_Shared"

local SafeTogetherServer = {}

-- Pending invites keyed by the invited player's username -> { x, y, w, h, host }.
local pendingInvites = {}

local function getOnlinePlayerByName(username)
    local players = getOnlinePlayers()
    if not players then return nil end
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p and p:getUsername() == username then
            return p
        end
    end
    return nil
end

local function canManage(playerObj, safehouse)
    return safehouse:getOwner() == playerObj:getUsername()
        or playerObj:getRole():hasCapability(Capability.CanSetupSafehouses)
end

-- The owner (or a privileged role) invites a player to a safehouse they own.
function SafeTogetherServer.invite(playerObj, args)
    local sh = SafeHouse.getSafeHouse(args.x, args.y, args.w, args.h)
    if not sh then return end
    if not canManage(playerObj, sh) then return end
    -- Already a member/owner of THIS safehouse -> nothing to do.
    if sh:playerAllowed(args.invited) then return end

    local target = getOnlinePlayerByName(args.invited)
    if not target then return end

    pendingInvites[args.invited] = { x = args.x, y = args.y, w = args.w, h = args.h, host = playerObj:getUsername() }
    sendServerCommand(target, SafeTogether.MODULE, "receiveInvite", {
        x = args.x, y = args.y, w = args.w, h = args.h,
        host = playerObj:getUsername(),
        title = sh:getTitle(),
    })
end

-- The invited player answers the invitation.
function SafeTogetherServer.acceptInvite(playerObj, args)
    local invited = playerObj:getUsername()
    local pending = pendingInvites[invited]
    if not pending then return end
    pendingInvites[invited] = nil

    if not args.accepted then return end
    -- The invite must still refer to the same safehouse.
    if pending.x ~= args.x or pending.y ~= args.y or pending.w ~= args.w or pending.h ~= args.h then return end

    local sh = SafeHouse.getSafeHouse(args.x, args.y, args.w, args.h)
    if not sh then return end
    if sh:playerAllowed(invited) then return end

    -- Direct, unrestricted membership change (server is authoritative). This is
    -- persisted by SafeHouse.save and re-sent to every client on next login via
    -- MetaDataPacket, so it survives restarts and reconnects.
    sh:addPlayer(invited)

    -- Mirror the change on every connected client immediately so open UIs and
    -- access checks update without needing a relog.
    sendServerCommand(SafeTogether.MODULE, "memberAdded", {
        x = args.x, y = args.y, w = args.w, h = args.h, member = invited,
    })
end

-- A player who owns nothing yet claims their own safehouse. Needed because the
-- vanilla "Claim Safehouse" option is greyed out by the base game for anyone who
-- is already a guest in another safehouse.
function SafeTogetherServer.claimOwn(playerObj, args)
    local username = playerObj:getUsername()
    if SafeTogether.getOwnedSafehouse(username) ~= nil then return end -- max 1 owned
    -- Reject overlap with an existing safehouse.
    if SafeHouse.getSafehouseOverlapping(args.x, args.y, args.x + args.w, args.y + args.h) ~= nil then return end

    local sh = SafeHouse.addSafeHouse(args.x, args.y, args.w, args.h, username)
    if not sh then return end
    if args.title and args.title ~= "" then
        sh:setTitle(args.title)
    end

    sendServerCommand(SafeTogether.MODULE, "safehouseAdded", {
        x = args.x, y = args.y, w = args.w, h = args.h,
        owner = username, title = sh:getTitle(),
    })
end

local function onClientCommand(module, command, playerObj, args)
    if module ~= SafeTogether.MODULE then return end
    if not playerObj or not args then return end
    local handler = SafeTogetherServer[command]
    if handler then
        handler(playerObj, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)
