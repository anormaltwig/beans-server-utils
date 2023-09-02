surface.CreateFont("BSU_MenuTitle", {
	font = "Arial",
	extended = true,
	size = 30,
	weight = 600,
	antialias = true,
})

surface.CreateFont("BSU_MenuDesc", {
	font = "Arial",
	extended = true,
	size = 20,
	weight = 500,
	antialias = true,
})

local bsuMenu = {}

function bsuMenu:Init()
	self:SetSize(ScrW() * 0.6, ScrH() * 0.6)
	self:Center()
	self:SetTitle("BeanBox Server Utilities Menu")
	self:SetVisible(false)
	self:SetDraggable(true)
	self:ShowCloseButton(true)
	self:SetDeleteOnClose(false)
	self:SetSizable(true)
	self:SetScreenLock(true)
	
	local tabBar = vgui.Create("DPropertySheet", self)
	tabBar:Dock(FILL)
	self.tabBar = tabBar
	self.tabs = {}
end

function bsuMenu:AddTab(name, pos, panel, icon)
	table.insert(self.tabs, {
		name = name,
		pos = pos,
		panel = panel,
		icon = icon,
	})
end

function bsuMenu:InitializeTabs()
	table.sort(self.tabs, function(a, b)
		return a.pos < b.pos
	end)

	for _, data in ipairs(self.tabs) do
		self.tabBar:AddSheet(data.name, data.panel, data.icon)
	end
end

vgui.Register("BSUMenu", bsuMenu, "DFrame")

local function createBSUMenu()
	if BSU.BSUMenu then BSU.BSUMenu:Remove() end
	
	local bsuMenu = vgui.Create("BSUMenu")
	BSU.BSUMenu = bsuMenu
	hook.Run("BSU_BSUMenuInit", bsuMenu)
	bsuMenu:InitializeTabs()
	hook.Run("BSU_BSUMenuPostInit", bsuMenu)
end

local function openBSUMenu()
	BSU.BSUMenu:Center()
	BSU.BSUMenu:Show()
	BSU.BSUMenu:MakePopup()
end

net.Receive("bsu_menu_open", function()
	if not BSU.BSUMenu then createBSUMenu() end
	openBSUMenu()
end)

net.Receive("bsu_menu_regen", function()
	if BSU.BSUMenu then BSU.BSUMenu:Remove() end
	createBSUMenu()
	openBSUMenu()
end)