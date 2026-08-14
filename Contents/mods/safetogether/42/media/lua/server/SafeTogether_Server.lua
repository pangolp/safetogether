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

-- Set (or clear) the player's respawn safehouse.
--
-- The vanilla "respawn here" tickbox sends SafehouseChangeRespawnPacket, whose
-- server-side consistency/anti-cheat check requires the player to be in the
-- safehouse's players list OR be its owner. But SafeHouse.setOwner() drops the
-- owner from the players list, and in Build 42.20+ the "SafeHouseMember" anti-
-- cheat kicks anyone that check rejects -> the OWNER gets kicked when setting
-- respawn in their own safehouse (guests, who ARE in the players list, are fine).
--
-- We route the change through this server command instead, calling the
-- unrestricted SafeHouse method directly (server is authoritative), so the
-- vanilla packet and its anti-cheat are never involved. We also enforce the
-- mod's rule of a single respawn safehouse per player.
function SafeTogetherServer.setRespawn(playerObj, args)
    local username = playerObj:getUsername()
    local sh = SafeHouse.getSafeHouse(args.x, args.y, args.w, args.h)
    if not sh then return end
    -- Must own or be a member of THIS safehouse.
    if not sh:playerAllowed(username) then return end

    if args.set then
        -- Single respawn: clear the flag from every other safehouse first.
        local list = SafeHouse.getSafehouseList()
        for i = 0, list:size() - 1 do
            local other = list:get(i)
            if other:isRespawnInSafehouse(username) then
                other:setRespawnInSafehouse(false, username)
            end
        end
        sh:setRespawnInSafehouse(true, username)
    else
        sh:setRespawnInSafehouse(false, username)
    end

    -- Mirror to every client so open UIs and the respawn indicator update live.
    sendServerCommand(SafeTogether.MODULE, "respawnChanged", {
        x = args.x, y = args.y, w = args.w, h = args.h,
        member = username, set = args.set and true or false,
    })
end

-- Place a (re)spawning player at THE safehouse where they set respawn.
--
-- Fires server-side during character creation (OnNewGame, triggered inside
-- CreatePlayerPacket.processServer) BEFORE the player position is serialized to
-- the client, so server and client agree from the start and no movement anti-
-- cheat delta is produced.
--
-- Why we need it: vanilla already respawns at a safehouse, but it uses
-- SafeHouse.hasSafehouse(user), which returns the FIRST safehouse the player
-- belongs to. For a multi-safehouse player (owner of one, guest in others) that
-- is often NOT the one they chose, so they land at a map spawn instead. We scan
-- for the safehouse where the player actually has respawn set (single, enforced
-- by setRespawn) and override the position to it.
local function onServerNewGame(playerObj)
    if not playerObj then return end
    if not getServerOptions():getBoolean("SafehouseAllowRespawn") then return end
    local username = playerObj:getUsername()
    if not username then return end

    local list = SafeHouse.getSafehouseList()
    for i = 0, list:size() - 1 do
        local sh = list:get(i)
        if sh:playerAllowed(username) and sh:isRespawnInSafehouse(username) then
            -- Match vanilla's center calc (note: X uses H, Y uses W, as in
            -- CreatePlayerPacket / SafeHouse respawn).
            local x = sh:getX() + sh:getH() / 2
            local y = sh:getY() + sh:getW() / 2
            playerObj:setX(x + 0.5)
            playerObj:setY(y + 0.5)
            playerObj:setZ(0)
            playerObj:setLastX(x + 0.5)
            playerObj:setLastY(y + 0.5)
            print("[SafeTogether] respawn " .. username .. " -> '" .. sh:getTitle() .. "' @" .. x .. "," .. y)
            return
        end
    end
end
Events.OnNewGame.Add(onServerNewGame)

local function onClientCommand(module, command, playerObj, args)
    if module ~= SafeTogether.MODULE then return end
    if not playerObj or not args then return end
    local handler = SafeTogetherServer[command]
    if handler then
        handler(playerObj, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)
