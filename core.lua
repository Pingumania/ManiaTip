local ADDON_NAME, ns = ...

ns.Classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
ns.BCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
ns.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local GetQuestGreenRange = ns.Retail and UnitQuestTrivialLevelRange("player") or GetQuestGreenRange()

local L = ns.L
local mt = CreateFrame("Frame")
local itemCache = {}
local u = {}

-- Config data variables
local cfg
local defaults = {
	showPlayerTitle = true,
	showRealm = true,
	showPlayerRealm = true,
	showSameRealm = true,

	hidePvpText = true,
	hideFactionText = true,

	colorGuildByReaction = true,
	colGuild = "|cff0080cc",
	colSameGuild = "|cffff32ff",
	colLevel = "|cffc0c0c0",

	reactText = false,
	colReactText1 = "|cffc0c0c0",
	colReactText2 = "|cffff0000",
	colReactText3 = "|cffff7f00",
	colReactText4 = "|cffffff00",
	colReactText5 = "|cff00ff00",
	colReactText6 = "|cff25c1eb",
	colReactText7 = "|cff808080",

	colReactBack1 = { r = 0.5, g = 0.5, b = 0.5 },
	colReactBack2 = { r = 1, g = 0, b = 0 },
	colReactBack3 = { r = 0.8, g = 0.3, b = 0.22 },
	colReactBack4 = { r = 0.9, g = 0.7, b = 0 },
	colReactBack5 = { r = 0, g = 0.6, b = 0.1 },
	colReactBack6 = { r = 0.13, g = 0.31, b = 0.51 },
	colReactBack7 = { r = 0.35, g = 0.35, b = 0.35 },

	tipColor = {}, -- Set during VARIABLES_LOADED
	tipBorderColor = { 1, 1, 1, 1 },

	barFontFace = "Arial Narrow", -- Set during VARIABLES_LOADED
	barFontSize = 13,
	barFontFlags = "OUTLINE",
	barTexture = "Blizzard",

	barsCondenseValues = true,

	classification_minus = "-%s ",
	classification_trivial = "~%s ",
	classification_normal = "%s ",
	classification_elite = "+%s ",
	classification_worldboss = "%s|r (Boss) ",
	classification_rare = "%s|r (Rare) ",
	classification_rareelite = "+%s|r (Rare) ",

	infoColor = { 0.2, 0.6, 1 },
	itemQualityBorder = true
}
local orig = {}

-- Faction names
local FactionNames = {}
for i = 1, 3000 do
	local name = GetFactionInfoByID(i)
	if name then
		FactionNames[name] = true
	end
end

-- Colors
local COLOR_WHITE = "|cffffffff"
local COLOR_LIGHTGRAY = "|cffc0c0c0"
local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local ClassColorMarkup = {}
for classID, color in next, CLASS_COLORS do
	ClassColorMarkup[classID] = ("|cff%.2x%.2x%.2x"):format(color.r*255, color.g*255, color.b*255)
end

--------------------------------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------------------------------

local function GetDifficultyLevelColor(level)
	level = level - mt.playerLevel
	if level > 4 then
		return "|cffff2020"
	elseif level > 2 then
		return "|cffff8040"
	elseif level >= -2 then
		return "|cffffff00"
	elseif level >= -GetQuestGreenRange then
		return "|cff40c040"
	else
		return "|cff808080"
	end
end

local function GetUnitReactionIndex(unit)
	if (UnitIsDead(unit)) then
		return 7
	elseif (UnitIsPlayer(unit) or UnitPlayerControlled(unit)) then
		if (UnitCanAttack(unit, "player")) then
			return (UnitCanAttack("player", unit) and 2 or 3)
		elseif (UnitCanAttack("player", unit)) then
			return 4
		elseif (UnitIsPVP(unit) and not UnitIsPVPSanctuary(unit) and not UnitIsPVPSanctuary("player")) then
			return 5
		else
			return 6
		end
	elseif (UnitIsTapDenied(unit)) and not (UnitPlayerControlled(unit)) then
		return 1
	else
		local reaction = (UnitReaction(unit,"player") or 3)
		return (reaction > 5 and 5) or (reaction < 2 and 2) or (reaction)
	end
end

local function FormatValue(val)
	if (not cfg.barsCondenseValues) or (val < 1000) then
		return tostring(floor(val))
	elseif (val < 1000000) then
		return ("%.1fk"):format(val / 1000)
	elseif (val < 1000000000) then
		return ("%.2fm"):format(val / 1000000)
	else
		return ("%.2fg"):format(val / 1000000000)
	end
end

local function SetFormattedBarValues(val, max)
	local string = _G[ADDON_NAME.."StatusBarHealthText"]
	if val > 0 then
		string:SetFormattedText("%s / %s", FormatValue(val), FormatValue(max))
	elseif max then
		string:SetText(DEAD)
	end
end

--------------------------------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------------------------------

local function SetDefaultNineSliceColor(tip)
	if not tip or tip.IsEmbedded or tip:IsForbidden() then return end

	if tip.NineSlice then
		tip.NineSlice:SetCenterColor(unpack(cfg.tipColor))
		tip.NineSlice:SetBorderColor(unpack(cfg.tipBorderColor))
	end
end

local function GetUnit(tip)
	local _, unit = tip:GetUnit()

	if not unit then
		local mouseFocus = GetMouseFocus()
		unit = mouseFocus and (mouseFocus.unit or (mouseFocus.GetAttribute and mouseFocus:GetAttribute("unit")))
	end

	return unit
end

local function GetLevelLine(data)
	for i = 2, 3 do
		local text = data.lines[i] and data.lines[i].leftText
		if text and strfind(text, LEVEL) then
			return i
		end
	end

	return false
end

local function RemoveUnwantedLines(tip)
	local line, text
	for i = 2, tip:NumLines() do
		line = _G["GameTooltipTextLeft"..i]
		text = line:GetText()
		if (cfg.hidePvpText) and (text == PVP_ENABLED) or (cfg.hideFactionText and (text == FACTION_ALLIANCE or text == FACTION_HORDE)) or FactionNames[text] then
			line:SetText("")
		end
	end
end

local function SetNineSliceBorderColor(tip, itemLinkOrID)
	if tip.IsEmbedded then return end

	if itemCache[itemLinkOrID] then
		local r, g, b = GetItemQualityColor(itemCache[itemLinkOrID])
		tip.NineSlice:SetBorderColor(r, g, b)
		return
	end

	local item
	if type(itemLinkOrID) == "number" then
		item = Item:CreateFromItemID(itemLinkOrID)
	elseif type(itemLinkOrID) == "string" then
		item = Item:CreateFromItemLink(itemLinkOrID)
	end
	if item:IsItemEmpty() then return end
	-- This function also executes when the item is already loaded
	item:ContinueOnItemLoad(function()
		local rarity = item:GetItemQuality()
		local r, g, b = GetItemQualityColor(rarity)
		tip.NineSlice:SetBorderColor(r, g, b)
		itemCache[itemLinkOrID] = rarity
	end)
end

local function GetTarget(unit)
	local target = unit.."target"
	local targetName = UnitName(target)
	return target, targetName
end

local function GetEmptyTralingLines(tip)
	local frame
	local count = 0
	for i = 2, tip:NumLines() do
		frame = _G["GameTooltipTextLeft"..i]
		if frame and (frame:GetStringHeight() == 0 or not frame:GetText()) then
			count = count + 1
		else
			count = 0
		end
	end

	return count
end

local function CalculateYOffset(tip)
	local yPadding = GetEmptyTralingLines(tip) * -3
	return yPadding
end

local function OnTooltipShow(tip)
	if tip:IsForbidden() or not u.unit then return end
	tip:SetPadding(0, CalculateYOffset(tip))
end

local function OnTooltipSetUnit(tip, data)
	if tip ~= GameTooltip then return end
	if tip:IsForbidden() then return end

	local unit = GetUnit(tip)

	if not unit then
		tip:Hide()
		return
	end

	RemoveUnwantedLines(tip)

	u.unit = unit
	local isPlayer = UnitIsPlayer(unit)
	local guild = GetGuildInfo(unit)
	local class, classID = UnitClass(unit)
	local reactionIndex = GetUnitReactionIndex(unit)
	local fullName = data.lines[1].leftText
	local reactionColor = cfg["colReactText"..reactionIndex]
	local isPetWild, isPetCompanion = UnitIsWildBattlePet(unit), UnitIsBattlePetCompanion(unit)

	-- UnitName
	local nameString = reactionColor..fullName
	local color = cfg["colReactBack"..reactionIndex]
	if isPlayer then
		local name, realm = UnitName(unit)

		color = CLASS_COLORS[classID] or CLASS_COLORS["PRIEST"]
		nameString = ClassColorMarkup[classID]..name

		-- Name
		if cfg.showPlayerTitle then
			if realm then
				nameString = ClassColorMarkup[classID]..gsub(fullName, "-"..realm, "")
			else
				nameString = ClassColorMarkup[classID]..fullName
			end
		end
		if cfg.showRealm then
			if cfg.showSameRealm then
				if not realm then realm = GetRealmName() end
			end
			nameString = nameString..(realm and "-"..realm or "")
		end
		-- dc, afk or dnd
		local status = (not UnitIsConnected(unit) and " <DC>") or (UnitIsAFK(unit) and " <AFK>") or (UnitIsDND(unit) and " <DND>")
		if status then
			nameString = nameString..COLOR_WHITE..(status or "")
		end
		GameTooltipTextLeft1:SetFormattedText("%s", nameString)
	end
	GameTooltipTextLeft1:SetFormattedText("%s", nameString)
	tip.NineSlice:SetBorderColor(color.r, color.g, color.b)

	-- Guild
	if isPlayer and guild then
		local pGuild = GetGuildInfo("player")
		local guildColor = (guild == pGuild and cfg.colSameGuild or cfg.colorGuildByReaction and reactionColor or cfg.colGuild)
		GameTooltipTextLeft2:SetFormattedText("%s<%s>", guildColor, guild)
	end

	-- Level + Classification
	local level = (isPetWild or isPetCompanion) and UnitBattlePetLevel(unit) or UnitLevel(unit) or -1
	local classification = UnitClassification(unit) or ""
	local unitClass = isPlayer and format("%s %s", UnitRace(unit) or "", ClassColorMarkup[classID]..(UnitClass(unit) or "")) or (isPetWild or isPetCompanion) and _G["BATTLE_PET_NAME_"..UnitBattlePetType(unit)] or UnitCreatureFamily(unit) or UnitCreatureType(unit) or ""
	local levelColor = (UnitCanAttack(unit, "player") or UnitCanAttack("player", unit)) and GetDifficultyLevelColor(level ~= -1 and level or 500) or cfg.colLevel
	local levelText = (cfg["classification_"..classification] or "%s? "):format(level == -1 and "??" or level)
	local levelLine = GetLevelLine(data)
	if levelLine then
		_G["GameTooltipTextLeft"..levelLine]:SetFormattedText("%s %s", levelColor..levelText.."|r", unitClass)
	end

	local textWidth = _G[ADDON_NAME.."StatusBarHealthText"]:GetStringWidth()
	if textWidth and GameTooltipStatusBar:IsShown() then
		tip:SetMinimumWidth(textWidth + 12)
	end

	tip:Show()
end

local function OnTooltipSetItem(tip, data)
	if tip ~= GameTooltip and tip ~= ItemRefTooltip and tip and ItemRefShoppingTooltip1 and tip ~= ItemRefShoppingTooltip2 and tip ~= ShoppingTooltip1 and tip ~= ShoppingTooltip1 then return end
	if tip:IsForbidden() then return end

	if not tip.GetItem then
		Mixin(tip, GameTooltipDataMixin)
	end

	local _, link = tip:GetItem()
	if not link then return end

	SetNineSliceBorderColor(tip, link)

	local id = strmatch(link, "item:(%d+)")
	if id and id ~= "" then
		tip:AddLine(L["ItemID"]..id, unpack(cfg.infoColor))
		tip:Show()
	end
end

local function SetRecipeReagentItem(tip, recipeID, reagentIndex)
	if tip:IsForbidden() then return end
	local link = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, reagentIndex)
	if not link then return end

	SetNineSliceBorderColor(tip, link)

	local id = strmatch(link, "item:(%d+)")
	if id and id ~= "" then
		tip:AddLine(L["ItemID"]..id, unpack(cfg.infoColor))
		tip:Show()
	end
end

local function OnTooltipSetSpell(tip, data)
	if tip ~= GameTooltip then return end
	if tip:IsForbidden() then return end

	if data.id then
		tip:AddLine(L["SpellID"]..data.id, unpack(cfg.infoColor))
		tip:Show()
	end
end

local function OnTooltipSetUnitAura(tip, data)
	if tip ~= GameTooltip and tip ~= ItemRefTooltip then return end
	if tip:IsForbidden() then return end

	if data.id then
		tip:AddLine(L["AuraID"]..data.id, unpack(cfg.infoColor))
		tip:Show()
	end
end

local function OnTooltipSetToy(tip, data)
	if tip ~= GameTooltip then return end
	if tip:IsForbidden() then return end

	if data.id then
		SetNineSliceBorderColor(tip, data.id)
		tip:AddLine(L["ItemID"]..data.id, unpack(cfg.infoColor))
		tip:Show()
	end
end

local function PetBattleUnitTooltip_UpdateForUnit(tip, owner, index)
	if C_PetBattles.IsWildBattle() then
		local rarity = C_PetBattles.GetBreedQuality(owner, index)
		tip.NineSlice:SetBorderColor(ITEM_QUALITY_COLORS[rarity-1].r, ITEM_QUALITY_COLORS[rarity-1].g, ITEM_QUALITY_COLORS[rarity-1].b)
	end
end

local function OnTooltipCleared(tip)
	if tip:IsForbidden() then return end

	if tip.ItemTooltip and not tip.ItemTooltip:IsShown() then
		tip:SetPadding(0, 0)
	end

	-- wipe the vars
	wipe(u)
end

local function StatusBar_OnValueChanged(self, value)
	if self:IsForbidden() or not value then return end

	local unit = GetUnit(self:GetParent())
	if not unit then
		return
	end

	local value = UnitHealth(unit)
	local max = UnitHealthMax(unit)

	if (value < 0) or (value > max) then
		return
	end
	SetFormattedBarValues(value, max)

	local _, classID = UnitClass(unit)
	if UnitIsPlayer(unit) then
		local color = CLASS_COLORS[classID] or CLASS_COLORS["PRIEST"]
		self:SetStatusBarColor(color.r, color.g, color.b)
	end
end

local function GTT_SetDefaultAnchor(tip, parent)
	if tip:IsForbidden() or not parent then
		return
	end

	local owner = select(2, tip:GetPoint())
	tip:SetOwner(owner, "ANCHOR_NONE")
	tip:ClearAllPoints()
	tip:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT")
end

local function STT_SetBackdropStyle(tip)
	SetDefaultNineSliceColor(tip)
end

local function MemberList_OnEnter(self)
	local classID
	if type(self.GetMemberInfo) == "function" then
		local info = self:GetMemberInfo()
		if not info then return end
		classID = info.classID
	else
		return
	end

	if not classID then return end

	local text = GameTooltipTextLeft1:GetText()
	if not text then return end

	if cfg.showRealm and cfg.showSameRealm then
		if (not strmatch(text, "%a+%-.+")) then
			text = text.."-"..GetRealmName()
		end
	else
		text = gsub(text, "%-.+", "")
	end

	local classInfo = C_CreatureInfo.GetClassInfo(classID)
	local color = CLASS_COLORS[classInfo.classFile] or CLASS_COLORS["PRIEST"]
	GameTooltipTextLeft1:SetFormattedText("%s", ClassColorMarkup[classInfo.classFile]..text)
	GameTooltip:Show()
end

local function MemberList_OnLeave()
	GameTooltip:Hide()
end

--------------------------------------------------------------------------------------------------------
-- Config update
--------------------------------------------------------------------------------------------------------

local function UpdateGameTooltipStatusBarTexture()
	GameTooltipStatusBar:SetStatusBarTexture(LibStub("LibSharedMedia-3.0"):Fetch("statusbar", cfg.barTexture))
	GameTooltipStatusBar.bg:SetTexture(LibStub("LibSharedMedia-3.0"):Fetch("statusbar", cfg.barTexture))
end
ns.UpdateGameTooltipStatusBarTexture = UpdateGameTooltipStatusBarTexture

local function UpdateGameTooltipStatusBarText()
	GameTooltipStatusBar.text:SetFont(LibStub("LibSharedMedia-3.0"):Fetch("font", cfg.barFontFace), cfg.barFontSize, cfg.barFontFlags)
end
ns.UpdateGameTooltipStatusBarText = UpdateGameTooltipStatusBarText

--------------------------------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------------------------------

local function HookDropdowns()
	local dropdowns = {
		"DropDownList",
		"L_DropDownList",
		"Lib_DropDownList",
		"ADD_DropDownList"
	}
	for _, name in pairs(dropdowns) do
		for i = 1, UIDROPDOWNMENU_MAXLEVELS do
			local menu = _G[name..i.."MenuBackdrop"]
			if menu then
				SetDefaultNineSliceColor(menu)
			end
		end
	end
end

local function HookTips()
	local tips = {
		GameTooltip,
		ShoppingTooltip1,
		ShoppingTooltip2,
		ItemRefTooltip,
		ItemRefShoppingTooltip1,
		ItemRefShoppingTooltip2,
		FriendsTooltip,
		EmbeddedItemTooltip,
		QuickKeybindTooltip,
		GameNoHeaderTooltip,
		GameSmallHeaderTooltip,
		-- Blizzard addon tooltips
		FrameStackTooltip,
		EventTraceTooltip,
		RuneforgeFrameResultTooltip,
		CharCustomizeTooltip,
		CharCustomizeNoHeaderTooltip,
		NamePlateTooltip,
		ItemSocketingDescription,
		GarrisonMissionMechanicTooltip,
		GarrisonMissionMechanicFollowerCounterTooltip,
		BattlePetTooltip,
		PetBattlePrimaryUnitTooltip,
		PetBattlePrimaryAbilityTooltip,
		-- 3rd party addon tooltips
		AtlasLootTooltip,
		LibDBIconTooltip,
		-- Frames
		QueueStatusFrame,
		QuestScrollFrame and QuestScrollFrame.CampaignTooltip,
		QuestScrollFrame and QuestScrollFrame.StoryTooltip,
		ChatMenu,
		VoiceMacroMenu,
		LanguageMenu,
		EmoteMenu,
		AutoCompleteBox,
	}

	for _, tip in next, tips do
		SetDefaultNineSliceColor(tip)
	end

	GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
	GameTooltip:HookScript("OnShow", OnTooltipShow)
	GameTooltipStatusBar:HookScript("OnValueChanged", StatusBar_OnValueChanged)
	hooksecurefunc("GameTooltip_SetDefaultAnchor", GTT_SetDefaultAnchor)
	hooksecurefunc("SharedTooltip_SetBackdropStyle", STT_SetBackdropStyle)

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, OnTooltipSetSpell)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, OnTooltipSetUnitAura)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Toy, OnTooltipSetToy)

	-- TooltipDataProcessor.AddLinePostCall(Enum.TooltipDataLineType.UnitName, OnLineSetUnitName)
end

--------------------------------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------------------------------

function mt:PLAYER_LOGIN(event)
	self.playerLevel = UnitLevel("player")
	self:UnregisterEvent(event)
end

function mt:PLAYER_LEVEL_UP(event, newLevel)
	self.playerLevel = newLevel
end

function mt:ADDON_LOADED(event, addon)
	if addon == "ManiaTip" then
		if not ManiaTipDB then
			ManiaTipDB = {}
		end
		cfg = setmetatable(ManiaTipDB, { __index = defaults })
		ns.cfg = cfg
	end
	if addon == "Blizzard_Communities" then
		local function OnTokenButtonAcquired(_, frame)
			frame:HookScript("OnEnter", MemberList_OnEnter)
			frame:HookScript("OnLeave", MemberList_OnLeave)
			if type(frame.OnEnter) == "function" then hooksecurefunc(frame, "OnEnter", MemberList_OnEnter) end
			if type(frame.OnLeave) == "function" then hooksecurefunc(frame, "OnLeave", MemberList_OnLeave) end
		end

		local iterateExisting = true
		local owner = nil
		ScrollUtil.AddAcquiredFrameCallback(CommunitiesFrame.MemberList.ScrollBox, OnTokenButtonAcquired, owner, iterateExisting)
	end
	if CalendarContextMenu then
		SetDefaultNineSliceColor(CalendarContextMenu)
	end
	if FloatingBattlePetTooltip then
		SetDefaultNineSliceColor(FloatingBattlePetTooltip)
		for _, name in pairs({"BW_DropDownList"}) do
			for i = 1, UIDROPDOWNMENU_MAXLEVELS do
				local menu = _G[name..i.."MenuBackdrop"]
				if menu then
					SetDefaultNineSliceColor(menu)
				end
			end
		end
	end
	if ns.Retail and PetBattleUnitTooltip_UpdateForUnit then
		hooksecurefunc("PetBattleUnitTooltip_UpdateForUnit", PetBattleUnitTooltip_UpdateForUnit)
	end
end

function mt:VARIABLES_LOADED()
	GameTooltipStatusBar.bg = GameTooltipStatusBar:CreateTexture(nil, "BACKGROUND")
	GameTooltipStatusBar.bg:SetVertexColor(0.3, 0.3, 0.3, 0.6)
	GameTooltipStatusBar.bg:SetAllPoints()
	GameTooltipStatusBar.text = GameTooltipStatusBar:CreateFontString(ADDON_NAME.."StatusBarHealthText")
	GameTooltipStatusBar.text:SetPoint("CENTER", GameTooltipStatusBar)

	UpdateGameTooltipStatusBarTexture()
	UpdateGameTooltipStatusBarText()

	local r, g, b = TOOLTIP_DEFAULT_BACKGROUND_COLOR:GetRGB()
	ns.cfg.tipColor = { r, g, b, 1}

	-- Hook Tips & Dropdowns
	HookTips()
	HookDropdowns()
end

mt:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
mt:RegisterEvent("PLAYER_LOGIN")
mt:RegisterEvent("PLAYER_LEVEL_UP")
mt:RegisterEvent("VARIABLES_LOADED")
mt:RegisterEvent("ADDON_LOADED")