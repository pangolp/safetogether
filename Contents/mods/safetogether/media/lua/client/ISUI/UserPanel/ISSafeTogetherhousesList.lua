ISSafeTogetherhousesList = ISPanel:derive("ISSafeTogetherhousesList")
ISSafeTogetherhousesList.messages = {}

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

function ISSafeTogetherhousesList:initialise()
    ISPanel.initialise(self)
    local btnWid = 100
    local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
    local padBottom = 10

    self.no = ISButton:new(10, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, getText("IGUI_CraftUI_Close"), self, ISSafeTogetherhousesList.onClick)
    self.no.internal = "CANCEL"
    self.no.anchorTop = false
    self.no.anchorBottom = true
    self.no:initialise()
    self.no:instantiate()
    self.no.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(self.no)

    local listY = 20 + FONT_HGT_MEDIUM + 20
    self.datas = ISScrollingListBox:new(10, listY, self.width - 20, self.height - padBottom - btnHgt - padBottom - listY)
    self.datas:initialise()
    self.datas:instantiate()
    self.datas.itemheight = FONT_HGT_SMALL + 2 * 2
    self.datas.selected = 0
    self.datas.joypadParent = self
    self.datas.font = UIFont.NewSmall
    self.datas.doDrawItem = self.drawDatas
    self.datas.drawBorder = true
    self:addChild(self.datas)

    self.viewBtn = ISButton:new(self.no.x + 150,  self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, getText("IGUI_PlayerStats_View"), self, ISSafeTogetherhousesList.onClick)
    self.viewBtn.internal = "VIEW"
    self.viewBtn.anchorTop = false
    self.viewBtn.anchorBottom = true
    self.viewBtn:initialise()
    self.viewBtn:instantiate()
    self.viewBtn.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(self.viewBtn)
    self.viewBtn.enable = false

    self:populateList()

end

function ISSafeTogetherhousesList:populateList()
    self.datas:clear()
    for i=0, SafeHouse.getSafehouseList():size() - 1 do
        local safe = SafeHouse.getSafehouseList():get(i)
        if ((safe:getOwner() == self.player) or (safe:playerAllowed(self.player:getUsername()))) then
            self.datas:addItem(safe:getTitle(), safe)
        end
    end
end

function ISSafeTogetherhousesList:drawDatas(y, item, alt)
    local a = 0.9

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight - 1, a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight - 1, 0.3, 0.7, 0.35, 0.15)
        if not ISSafehouseUI.instance then
            self.parent.viewBtn.enable = true
        else
            self.parent.viewBtn.tooltip = "Solo puedes ver 1 refugio por vez"
        end
        self.parent.selectedSafehouse = item.item
    end

    local playersInSafehouse = item.item:getPlayers():size()
    local respawnInSafehouseActive = ""
    if playersInSafehouse == 0 then playersInSafehouse = playersInSafehouse + 1 end
    if item.item:isRespawnInSafehouse(getPlayer():getUsername()) then respawnInSafehouseActive = getText("IGUI_SafehouseTogether_Respawn") else respawnInSafehouseActive = "" end

    self:drawText((string.format(getText("IGUI_SafehouseTogether_Safehouse"), item.item:getTitle(), item.item:getOwner(), playersInSafehouse, respawnInSafehouseActive)), 10, y + 2, 1, 1, 1, a, self.font)

    return y + self.itemheight
end

function ISSafeTogetherhousesList:prerender()
    local z = 20
    local splitPoint = 100
    local x = 10
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    self:drawText(string.format(getText("IGUI_SafehouseTogether_Safehouse_Owner"), self.player:getUsername()), self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, string.format(getText("IGUI_SafehouseTogether_Safehouse_Owner"), self.player:getUsername())) / 2), z, 1,1,1,1, UIFont.Medium)
    z = z + 30
end

function ISSafeTogetherhousesList:onClick(button)
    if button.internal == "CANCEL" then
        self:close()
    end
    if button.internal == "VIEW" then
        if not ISSafehouseUI.instance then
            local safehouseUI = ISSafehouseUI:new(getCore():getScreenWidth() / 2 - 250,getCore():getScreenHeight() / 2 - 225, 500, 450, self.selectedSafehouse, self.player)
            safehouseUI:initialise()
            safehouseUI:addToUIManager()
            self:close()
        end
    end
end

function ISSafeTogetherhousesList:close()
    self:setVisible(false)
    self:removeFromUIManager()
    ISSafeTogetherhousesList.instance = nil
end

function ISSafeTogetherhousesList:new(x, y, width, height, player)
    local o = {}
    x = getCore():getScreenWidth() / 2 - (width / 2)
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.width = width
    o.height = height
    o.player = player
    o.selectedFaction = nil
    o.moveWithMouse = true
    ISSafeTogetherhousesList.instance = o
    return o
end

function ISSafeTogetherhousesList.OnSafehousesChanged()
    if ISSafeTogetherhousesList.instance then
        ISSafeTogetherhousesList.instance:populateList()
    end
end

Events.OnSafehousesChanged.Add(ISSafeTogetherhousesList.OnSafehousesChanged)
