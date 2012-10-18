
------------------------------------------
--  This addon was heavily inspired by  --
--    HandyNotes_Lorewalkers            --
--    HandyNotes_LostAndFound           --
--  by Kemayo                           --
------------------------------------------


-- declaration
local ID, HallowsEnd = ...

HallowsEnd.points = {}

-- our db upvalue and db defaults
local db
local defaults = { profile = { completed = false, icon_scale = 1.4, icon_alpha = 0.8 } }


-- localize some globals
local next = next
local HandyNotes = HandyNotes
local GameTooltip = GameTooltip
local WorldMapTooltip = WorldMapTooltip
local IsQuestFlaggedCompleted = IsQuestFlaggedCompleted


-- plugin handler for HandyNotes
function HallowsEnd:OnEnter(mapFile, coord)
	local tooltip = self:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
	
	if self:GetCenter() > UIParent:GetCenter() then -- compare X coordinate
		tooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		tooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	
	tooltip:SetText("Candy Bucket")
	tooltip:Show()
end

function HallowsEnd:OnLeave()
	if self:GetParent() == WorldMapButton then
		WorldMapTooltip:Hide()
	else
		GameTooltip:Hide()
	end
end

local function createWaypoint(button, mapFile, coord)
	local c, z = HandyNotes:GetCZ(mapFile)
	local x, y = HandyNotes:getXY(coord)
	
	if TomTom then
		TomTom:AddZWaypoint(c, z, x * 100, y * 100, "Candy Bucket")
	elseif Cartographer_Waypoints then
		Cartographer_Waypoints:AddWaypoint( NotePoint:new(HandyNotes:GetCZToZone(c, z), x, y, "Candy Bucket") )
	end
end

do
	-- context menu generator
	local info = {}
	local currentZone, currentCoord
	
	local function generateMenu(button, level)
		if not level then return end
		
		for k in pairs(info) do info[k] = nil end
		
		if level == 1 then
			-- create the title of the menu
			info.isTitle = 1
			info.text = "HandyNotes - Hallow's End"
			info.notCheckable = 1
			
			UIDropDownMenu_AddButton(info, level)

			if TomTom or Cartographer_Waypoints then
				-- waypoint menu item
				info.disabled = nil
				info.isTitle = nil
				info.notCheckable = nil
				info.text = "Create waypoint"
				info.icon = nil
				info.func = createWaypoint
				info.arg1 = currentZone
				info.arg2 = currentCoord
				
				UIDropDownMenu_AddButton(info, level)
			end

			-- close menu item
			info.text = "Close"
			info.icon = nil
			info.func = function() CloseDropDownMenus() end
			info.arg1 = nil
			info.notCheckable = 1
			
			UIDropDownMenu_AddButton(info, level)
		end
	end

	local dropdown = CreateFrame("Frame", "HandyNotes_HallowsEndDropdownMenu")
	dropdown.displayMode = "MENU"
	dropdown.initialize = generateMenu

	function HallowsEnd:OnClick(button, down, mapFile, coord)
		if button == "RightButton" and not down then
			currentZone = mapFile
			currentCoord = coord
			
			ToggleDropDownMenu(1, nil, dropdown, self, 0, 0)
		end
	end
end

do
	-- custom iterator we use to iterate over every node in a given zone
	local function iter(t, prestate)
		if not t then return nil end
		
		local state, value = next(t, prestate)
		
		while state do -- have we reached the end of this zone?
			if value and (db.completed or not IsQuestFlaggedCompleted(value)) then
				return state, nil, "interface\\icons\\achievement_halloween_candy_01", db.icon_scale, db.icon_alpha
			end
			
			state, value = next(t, state) -- get next data
		end
		
		return nil, nil, nil, nil
	end
	
	function HallowsEnd:GetNodes(mapFile)
		return iter, self.points[mapFile], nil
	end
end


-- config
local options = {
	type = "group",
	name = "Hallow's End",
	desc = "Hallow's End",
	get = function(info) return db[info[#info]] end,
	set = function(info, v)
		db[info[#info]] = v
		HallowsEnd:Refresh()
	end,
	args = {
		desc = {
			name = "These settings control the look and feel of the icon.",
			type = "description",
			order = 0,
		},
		completed = {
			name = "Show completed",
			desc = "Show waypoints for lore you've already found?",
			type = "toggle",
			arg = "completed",
			order = 10,
		},
		icon_scale = {
			type = "range",
			name = "Icon Scale",
			desc = "The scale of the icons.",
			min = 0.25, max = 2, step = 0.01,
			arg = "icon_scale",
			order = 20,
		},
		icon_alpha = {
			type = "range",
			name = "Icon Alpha",
			desc = "The alpha transparency of the icons.",
			min = 0, max = 1, step = 0.01,
			arg = "icon_alpha",
			order = 30,
		},
	},
}


-- initialise
function HallowsEnd:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("HandyNotes_HallowsEndDB", defaults)
	db = self.db.profile
	
	HandyNotes:RegisterPluginDB("HallowsEnd", self, options)
end

function HallowsEnd:OnEnable()
	self:RegisterEvent("QUEST_FINISHED", "Refresh")
end

function HallowsEnd:Refresh()
	self:SendMessage("HandyNotes_NotifyUpdate", "HallowsEnd")
end


-- activate
HallowsEnd = LibStub("AceAddon-3.0"):NewAddon(HallowsEnd, ID, "AceEvent-3.0")
