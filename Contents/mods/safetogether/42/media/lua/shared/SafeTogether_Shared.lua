--[[
    Safe Together - shared code (runs on both client and server).

    Build 42 made safehouses server-authoritative: a player may only ever be
    the owner OR a member of ONE safehouse, and that rule is enforced in Java
    packet handlers (SafehouseInvitePacket / SafehouseAcceptPacket) that a Lua
    mod cannot override. This mod works around it by driving membership changes
    through its own client<->server command protocol, where the SERVER-side Lua
    calls the (unrestricted, Lua-exposed) SafeHouse methods directly.

    Design goal: each player owns at most one safehouse (optional), and can be a
    guest in any number of friends' safehouses, but only when the owner invites
    them.
]]

SafeTogether = SafeTogether or {}

-- Command channel shared by sendClientCommand / sendServerCommand.
SafeTogether.MODULE = "SafeTogether"

--- Returns the safehouse a player OWNS, or nil. Guest memberships are ignored.
--- @param username string
--- @return SafeHouse|nil
function SafeTogether.getOwnedSafehouse(username)
    local list = SafeHouse.getSafehouseList()
    for i = 0, list:size() - 1 do
        local sh = list:get(i)
        if sh:getOwner() == username then
            return sh
        end
    end
    return nil
end

--- Locate a safehouse by its rectangle. The (x,y,w,h) tuple is a stable
--- identity that is valid on both the client and the server, unlike the Lua
--- object reference which differs per machine.
--- @return SafeHouse|nil
function SafeTogether.findSafehouse(x, y, w, h)
    return SafeHouse.getSafeHouse(x, y, w, h)
end
