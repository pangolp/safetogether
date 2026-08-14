--[[
    Safe Together - patches for the vanilla "add player to safehouse" panel.

    Two changes, applied on top of the base game's ISSafehouseAddPlayerUI:
      1. populateList: a player may be invited unless they are already a member
         of THIS safehouse (vanilla also blocks players who belong to ANY other
         safehouse, which is exactly the restriction this mod removes).
      2. onClick: the invitation is sent through the mod's own client command
         instead of vanilla sendSafehouseInvite (which the server would reject
         for anyone who already has a safehouse).
]]

require "SafeTogether_Shared"
require "ISUI/UserPanel/ISSafehouseAddPlayerUI"

function ISSafehouseAddPlayerUI:populateList()
    self.playerList:clear()
    if not self.scoreboard then return end

    for i = 1, self.scoreboard.usernames:size() do
        local username = self.scoreboard.usernames:get(i - 1)
        local displayName = self.scoreboard.displayNames:get(i - 1)

        if self.safehouse:getOwner() ~= username then
            local newPlayer = { username = username }
            -- Block only if already a member/owner of THIS safehouse.
            if self.safehouse:playerAllowed(username) then
                newPlayer.tooltip = getText("IGUI_SafehouseTogether_AlreadyInvited")
            end

            local item = self.playerList:addItem(displayName, newPlayer)
            if newPlayer.tooltip then
                item.tooltip = newPlayer.tooltip
            end
        end
    end
end

function ISSafehouseAddPlayerUI:onClick(button)
    if button.internal == "CANCEL" then
        self:setVisible(false)
        self:removeFromUIManager()
        ISSafehouseAddPlayerUI.instance = nil
    end
    if button.internal == "ADDPLAYER" then
        if not self.changeOwnership then
            local modal = ISModalDialog:new(0, 0, 350, 150, getText("IGUI_FactionUI_InvitationSent", self.selectedPlayer), false, nil, nil)
            modal:initialise()
            modal:addToUIManager()
            sendClientCommand(self.player, SafeTogether.MODULE, "invite", {
                x = self.safehouse:getX(), y = self.safehouse:getY(),
                w = self.safehouse:getW(), h = self.safehouse:getH(),
                invited = self.selectedPlayer,
            })
        else
            -- Ownership transfer keeps using the vanilla path.
            sendSafehouseChangeOwner(self.safehouse, self.selectedPlayer)
            self.safehouseUI:populateList()
        end
        self:setVisible(false)
        self:removeFromUIManager()
        ISSafehouseAddPlayerUI.instance = nil
    end
end
