local ADDON_NAME, ns = ...

ns.Classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
ns.BCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
ns.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local GetQuestGreenRange = ns.Retail and UnitQuestTrivialLevelRange("player") or GetQuestGreenRange()
local gsub = gsub
local format = format
local strmatch = strmatch
local strfind = strfind

local L = ns.L
local mt = CreateFrame("Frame")
local itemCache = {}
local u = {}

-- Config data variables
local cfg
local defaults = {
	targetYouText = "<<YOU>>",
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

	colReactBack1 = { 0.5, 0.5, 0.5 },
	colReactBack2 = { 1, 0, 0 },
	colReactBack3 = { 0.8, 0.3, 0.22 },
	colReactBack4 = { 0.9, 0.7, 0 },
	colReactBack5 = { 0, 0.6, 0.1 },
	colReactBack6 = { 0.13, 0.31, 0.51 },
	colReactBack7 = { 0.35, 0.35, 0.35 },

	tipBackdropBG = "Interface\\Tooltips\\UI-Tooltip-Background",
	tipBackdropEdge = "Interface\\Tooltips\\UI-Tooltip-Border",
	backdropEdgeSize = 14,
	backdropInsets = 3,

	tipColor = { 0.06, 0.06, 0.06, 1 },
	tipBorderColor = { 0.3, 0.3, 0.3, 1 },

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

-- Strip textures form object
local function StripTextures(obj)
	local nineSlicePieces = {
		"TopLeftCorner",
		"TopRightCorner",
		"BottomLeftCorner",
		"BottomRightCorner",
		"TopEdge",
		"BottomEdge",
		"LeftEdge",
		"RightEdge",
		"Center"
	}

	for index, pieceName in ipairs(nineSlicePieces) do
		local region = obj[pieceName]
		if region then
			region:SetTexture(nil)
		end
	end
end

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

-- Get reaction index
--[[
	1 = Tapped
	2 = Hostile
	3 = Caution
	4 = Neutral
	5 = Friendly NPC or PvP Player
	6 = Friendly Player
	7 = Dead
--]]
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

local function ApplyTipBackdrop(tip)
	if not tip or tip.IsEmbedded or tip:IsForbidden() then return end
	if not tip.SetBackdrop then
		Mixin(tip, BackdropTemplateMixin)
	end
	if tip.NineSlice then
		StripTextures(tip.NineSlice)
	end
	tip:SetBackdrop({
		bgFile = cfg.tipBackdropBG,
		edgeFile = cfg.tipBackdropEdge,
		tile = false,
		tileEdge = false,
		edgeSize = cfg.backdropEdgeSize,
		insets = { left = cfg.backdropInsets, right = cfg.backdropInsets, top = cfg.backdropInsets, bottom = cfg.backdropInsets },
	})
	tip:SetBackdropColor(unpack(cfg.tipColor))
	tip:SetBackdropBorderColor(unpack(cfg.tipBorderColor))
end

local function GetUnit(self)
	local _, unit = self:GetUnit()

	if not unit then
		local mouseFocus = GetMouseFocus()
		unit = mouseFocus and (mouseFocus.unit or (mouseFocus.GetAttribute and mouseFocus:GetAttribute("unit")))
	end

	return unit
end

local function GetLevelLine(self)
	local frame, text
	for i = 2, self:NumLines() do
		frame = _G["GameTooltipTextLeft"..i]
		if frame then text = frame:GetText() end
		if text and strfind(text, LEVEL) then
			return frame
		end
	end

	return false
end

local function RemoveUnwantedLines(tip)
	local frame, text
	for i = 2, tip:NumLines() do
		frame = _G["GameTooltipTextLeft"..i]
		text = frame:GetText()
		if (cfg.hidePvpText) and (text == PVP_ENABLED) or (cfg.hideFactionText and (text == FACTION_ALLIANCE or text == FACTION_HORDE)) or FactionNames[text] then
			frame:SetText(nil)
		end
	end
end

local function SetRarityBorderColor(self, itemLinkOrID)
	if self.IsEmbedded then return end

	if itemCache[itemLinkOrID] then
		self:SetBackdropBorderColor(ITEM_QUALITY_COLORS[itemCache[itemLinkOrID]].r, ITEM_QUALITY_COLORS[itemCache[itemLinkOrID]].g, ITEM_QUALITY_COLORS[itemCache[itemLinkOrID]].b)
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
		self:SetBackdropBorderColor(ITEM_QUALITY_COLORS[rarity].r, ITEM_QUALITY_COLORS[rarity].g, ITEM_QUALITY_COLORS[rarity].b)
		itemCache[itemLinkOrID] = rarity
	end)
end

local function GetTarget(unit)
	local target = unit.."target"
	local targetName = UnitName(target)
	return target, targetName
end

local function GetEmptyLineIndex(tip)
	local frame
	for i = 2, 15  do
		local frame = _G["GameTooltipTextLeft"..i]
		if frame and frame:GetStringHeight() == 0 then
			return i
		end
	end
end

local function GetEmptyLines(tip)
	local frame
	local count = 0
	for i = 2, tip:NumLines() do
		frame = _G["GameTooltipTextLeft"..i]
		if frame and (frame:GetStringHeight() == 0 or not frame:GetText()) then
			count = count + 1
		end
	end

	return count
end

local function CalculatePadding(tip)
	local yPadding
	if tip:NumLines() > 5 then
		yPadding = 0
	else
		yPadding = GetEmptyLines(tip) * -3
	end

	return 0, yPadding
end

local function GameTooltip_SetWidth(self, width)
	self:Show()
end

local function GameTooltip_Show(self)
	if self:IsForbidden() or not u.unit then return end
	self:SetPadding(CalculatePadding(self))
end

local function OnTooltipSetUnit(self)
	if self:IsForbidden() then return end
	local unit = GetUnit(self)

	if not unit then
		self:Hide()
		return
	end

	u.unit = unit
	u.isPlayer = UnitIsPlayer(unit)
	u.class, u.classID = UnitClass(unit)
	u.reactionIndex = GetUnitReactionIndex(unit)
	u.guild = GetGuildInfo(unit)

	RemoveUnwantedLines(self)

	-- Obtain unit properties
	u.name, u.realm = UnitName(unit)
	u.playerTitle = ""
	u.reactionColor = cfg["colReactText"..u.reactionIndex]
	u.isPetWild, u.isPetCompanion = UnitIsWildBattlePet(unit), UnitIsBattlePetCompanion(unit)

	-- Level + Classification
	local level = (u.isPetWild or u.isPetCompanion) and UnitBattlePetLevel(unit) or UnitLevel(unit) or -1
	local classification = UnitClassification(unit) or ""
	local unitClass = u.isPlayer and format("%s %s", UnitRace(unit) or "", ClassColorMarkup[u.classID]..(UnitClass(unit) or "")) or (u.isPetWild or u.isPetCompanion) and _G["BATTLE_PET_NAME_"..UnitBattlePetType(unit)] or UnitCreatureFamily(unit) or UnitCreatureType(unit) or ""
	local levelColor = (UnitCanAttack(unit, "player") or UnitCanAttack("player", unit)) and GetDifficultyLevelColor(level ~= -1 and level or 500) or cfg.colLevel
	local levelText = (cfg["classification_"..classification] or "%s? "):format(level == -1 and "??" or level)
	local levelLine = GetLevelLine(self)
	if levelLine then
		levelLine:SetFormattedText("%s %s", levelColor..levelText.."|r", unitClass)
	end

	-- Generate Line Modification
	if u.isPlayer then
		local nameString = ClassColorMarkup[u.classID]..u.name
		-- Name
		if cfg.showPlayerTitle then
			if u.realm then
				nameString = ClassColorMarkup[u.classID]..gsub(GameTooltipTextLeft1:GetText(), "-"..u.realm, "")
			else
				nameString = ClassColorMarkup[u.classID]..GameTooltipTextLeft1:GetText()
			end
		end
		if cfg.showRealm then
			if cfg.showSameRealm then
				if not u.realm then u.realm = GetRealmName() end
			end
			nameString = nameString..(u.realm and " ("..u.realm..")" or "")
		end
		-- dc, afk or dnd
		local status = (not UnitIsConnected(unit) and " <DC>") or (UnitIsAFK(unit) and " <AFK>") or (UnitIsDND(unit) and " <DND>")
		if status then
			nameString = nameString..COLOR_WHITE..(status or "")
		end
		GameTooltipTextLeft1:SetFormattedText("%s", nameString)
		-- Guild
		if u.guild then
			local pGuild = GetGuildInfo("player")
			local guildColor = (u.guild == pGuild and cfg.colSameGuild or cfg.colorGuildByReaction and u.reactionColor or cfg.colGuild)
			GameTooltipTextLeft2:SetFormattedText("%s<%s>", guildColor, u.guild)
		end

		local color = CLASS_COLORS[u.classID] or CLASS_COLORS["PRIEST"]
		self:SetBackdropBorderColor(color.r, color.g, color.b)
	else
		if u.title and (u.title ~= " ") then
			GameTooltipTextLeft2:SetFormattedText("%s<%s>", u.reactionColor, u.title)
		end
		GameTooltipTextLeft1:SetFormattedText("%s", u.reactionColor..u.name)
		self:SetBackdropBorderColor(unpack(cfg["colReactBack"..u.reactionIndex]))
	end

	-- Target
	local target, targetName = GetTarget(unit)
	if target and targetName then
		local targetLine = ""
		if targetName and (targetName ~= UNKNOWNOBJECT and targetName ~= "" or UnitExists(target)) then
			targetLine = "|cffffd100"..BINDING_HEADER_TARGETING..": "
			if (UnitIsUnit("player", target)) then
				targetLine = targetLine..COLOR_WHITE..cfg.targetYouText
			else
				local targetReaction = cfg["colReactText"..GetUnitReactionIndex(target)]
				targetLine = targetLine..targetReaction
				if (UnitIsPlayer(target)) then
					local _, targetClassID = UnitClass(target)
					targetLine = targetLine..(ClassColorMarkup[targetClassID] or COLOR_LIGHTGRAY)..targetName..targetReaction
				else
					targetLine = targetLine..targetName
				end
			end
		end

		local frame
		if GetEmptyLineIndex(self) then
			frame = _G["GameTooltipTextLeft"..GetEmptyLineIndex(self)]
		else
			self:AddLine(" ", nil, nil, nil, 1)
			frame = _G["GameTooltipTextLeft"..self:NumLines()]
		end
		frame:SetText(targetLine, unpack(cfg.infoColor))
	end

	local textWidth = _G[ADDON_NAME.."StatusBarHealthText"]:GetStringWidth()
	if textWidth and GameTooltipStatusBar:IsShown() then
		self:SetMinimumWidth(textWidth + 12)
	end

	self:Show()
end

local function OnTooltipSetItem(self)
	if self:IsForbidden() then return end
	local _, link = self:GetItem()
	if not link then return end

	SetRarityBorderColor(self, link)

	local id = strmatch(link, "item:(%d+)")
	if id and id ~= "" then
		self:AddLine(L["ItemID"]..id, unpack(cfg.infoColor))
		self:Show()
	end
end

local function SetRecipeReagentItem(self, recipeID, reagentIndex)
	if self:IsForbidden() then return end
	local link = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, reagentIndex)
	if not link then return end

	SetRarityBorderColor(self, link)

	local id = strmatch(link, "item:(%d+)")
	if id and id ~= "" then
		self:AddLine(L["ItemID"]..id, unpack(cfg.infoColor))
		self:Show()
	end
end

local function OnTooltipSetSpell(self)
	if self:IsForbidden() then return end
	-- Workaround for TalentsFrame constantly firing OnTooltipSetSpell
	if self:GetOwner():GetParent():GetParent() == PlayerTalentFrameTalents then
		-- Skip first
		if not u.skip then
			u.skip = true
			return
		end
	end
	local _, spellId = self:GetSpell()
	if spellId then
		self:AddLine(L["SpellID"]..spellId, unpack(cfg.infoColor))
		self:Show()
	end
end

local function SetUnitAura(self, unit, index, filter)
	if self:IsForbidden() then return end
	local _, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, index, filter)
	if spellId and spellId ~= 0 then
		self:AddLine(L["SpellID"]..spellId, unpack(cfg.infoColor))
		self:Show()
	end
end

local function SetHyperlink(self, link)
	if self:IsForbidden() then return end
	if cfg.itemQualityBorder then
		if self:NumLines() > 0 then
			SetRarityBorderColor(self, link)
		end
	end
end

local function SetToyByItemID(self, id)
	if self:IsForbidden() then return end
	if not id then return end

	SetRarityBorderColor(self, id)
	u.doNotReset = true
end

local function SetLFGDungeonReward(self, dungeonID, rewardID)
	if self:IsForbidden() then return end
	local link = GetLFGDungeonRewardLink(dungeonID, rewardID)
	if not link then return end

	SetRarityBorderColor(self, link)
end

local function SetLFGDungeonShortageReward(self, dungeonID, rewardArg, rewardID)
	if self:IsForbidden() then return end
	local link = GetLFGDungeonShortageRewardLink(dungeonID, rewardArg, rewardID)
	if not link then return end

	SetRarityBorderColor(self, link)
end

local function PetBattleUnitTooltip_UpdateForUnit(tip, owner, index)
	if C_PetBattles.IsWildBattle() then
		local rarity = C_PetBattles.GetBreedQuality(owner, index)
		tip:SetBackdropBorderColor(ITEM_QUALITY_COLORS[rarity-1].r, ITEM_QUALITY_COLORS[rarity-1].g, ITEM_QUALITY_COLORS[rarity-1].b)
	end
end

local function OnTooltipCleared(self)
	if self:IsForbidden() then return end
	-- reset padding and color
	if not u.doNotReset then
		self:SetBackdropBorderColor(unpack(cfg.tipBorderColor))
	end
	if self.ItemTooltip and not self.ItemTooltip:IsShown() then
		self:SetPadding(0, 0)
	end

	-- wipe the vars
	wipe(u)
end

local function StatusBar_OnValueChanged(self, value)
	if self:IsForbidden() or not value then return end

	local min, max = self:GetMinMaxValues()
	if (value < min) or (value > max) then
		return
	end
	SetFormattedBarValues(value, max)

	local unit = GetUnit(self:GetParent())
	if not unit then
		return
	end

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

	tip:SetOwner(parent, "ANCHOR_NONE")
	tip:ClearAllPoints()
	tip:SetPoint("BOTTOMRIGHT", ADDON_NAME.."Anchor")
end

local function STT_SetBackdropStyle(tip)
	ApplyTipBackdrop(tip)
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
	GameTooltip:SetBackdropBorderColor(color.r, color.g, color.b)
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
				ApplyTipBackdrop(menu)
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
		GlueTooltip,
		QuickKeybindTooltip,
		GlueNoHeaderTooltip,
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
		QuestScrollFrame.CampaignTooltip,
		ChatMenu,
		VoiceMacroMenu,
		LanguageMenu,
		EmoteMenu,
		AutoCompleteBox,
	}

	for _, tip in next, tips do
		ApplyTipBackdrop(tip)
	end

	GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
	GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
	GameTooltip:HookScript("OnTooltipSetSpell", OnTooltipSetSpell)
	GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
	ShoppingTooltip1:HookScript("OnTooltipSetItem", OnTooltipSetItem)
	ShoppingTooltip2:HookScript("OnTooltipSetItem", OnTooltipSetItem)
	ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", OnTooltipSetItem)
	ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", OnTooltipSetItem)
	GameTooltipStatusBar:HookScript("OnValueChanged", StatusBar_OnValueChanged)
	hooksecurefunc(GameTooltip, "SetUnitAura", SetUnitAura)
	hooksecurefunc(GameTooltip, "SetUnitBuff", SetUnitAura)
	hooksecurefunc(GameTooltip, "SetUnitDebuff", SetUnitAura)
	hooksecurefunc(GameTooltip, "SetRecipeReagentItem", SetRecipeReagentItem)
	hooksecurefunc(GameTooltip, "SetToyByItemID", SetToyByItemID)
	hooksecurefunc(GameTooltip, "SetLFGDungeonReward", SetLFGDungeonReward)
	hooksecurefunc(GameTooltip, "SetLFGDungeonShortageReward", SetLFGDungeonShortageReward)
	hooksecurefunc(GameTooltip, "Show", GameTooltip_Show)
	hooksecurefunc(GameTooltip, "SetWidth", GameTooltip_SetWidth)
	hooksecurefunc(ItemRefTooltip, "ItemRefSetHyperlink", SetHyperlink)
	hooksecurefunc(ItemRefTooltip, "SetUnitAura", SetUnitAura)
	hooksecurefunc(ItemRefTooltip, "SetUnitBuff", SetUnitAura)
	hooksecurefunc(ItemRefTooltip, "SetUnitDebuff", SetUnitAura)
	hooksecurefunc("GameTooltip_SetDefaultAnchor", GTT_SetDefaultAnchor)
	hooksecurefunc("SharedTooltip_SetBackdropStyle", STT_SetBackdropStyle)

	-- hooksecurefunc(ItemRefTooltip, "SetAchievementByID", SetAchievementByID)
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
		-- Init config
		if not ManiaTipDB then
			ManiaTipDB = {}
		end
		cfg = setmetatable(ManiaTipDB, { __index = defaults })
		ns.cfg = cfg
	end
	if addon == "Blizzard_Communities" then
		for _, button in pairs(_G.CommunitiesFrame.MemberList.ListScrollFrame.buttons) do
			button:HookScript("OnEnter", MemberList_OnEnter)
			button:HookScript("OnLeave", MemberList_OnLeave)
			if type(button.OnEnter) == "function" then hooksecurefunc(button, "OnEnter", MemberList_OnEnter) end
			if type(button.OnLeave) == "function" then hooksecurefunc(button, "OnLeave", MemberList_OnLeave) end
		end
	end
	if addon == "Blizzard_Calendar" then
		-- We have to force the Mixin here
		Mixin(CalendarContextMenu, BackdropTemplateMixin)
		ApplyTipBackdrop(CalendarContextMenu)
	end
	if FloatingBattlePetTooltip then
		Mixin(FloatingBattlePetTooltip, BackdropTemplateMixin)
		ApplyTipBackdrop(FloatingBattlePetTooltip)
		for _, name in pairs({"BW_DropDownList"}) do
			for i = 1, UIDROPDOWNMENU_MAXLEVELS do
				local menu = _G[name..i.."MenuBackdrop"]
				if menu then
					Mixin(menu, BackdropTemplateMixin)
					ApplyTipBackdrop(menu)
				end
			end
		end
	end
	if ns.Retail and PetBattleUnitTooltip_UpdateForUnit then
		hooksecurefunc("PetBattleUnitTooltip_UpdateForUnit", PetBattleUnitTooltip_UpdateForUnit)
	end
end

function mt:VARIABLES_LOADED(event)
	GameTooltipStatusBar.bg = GameTooltipStatusBar:CreateTexture(nil, "BACKGROUND")
	GameTooltipStatusBar.bg:SetVertexColor(0.3, 0.3, 0.3, 0.6)
	GameTooltipStatusBar.bg:SetAllPoints()
	GameTooltipStatusBar.text = GameTooltipStatusBar:CreateFontString(ADDON_NAME.."StatusBarHealthText")
	GameTooltipStatusBar.text:SetPoint("CENTER", GameTooltipStatusBar)

	UpdateGameTooltipStatusBarTexture()
	UpdateGameTooltipStatusBarText()

	-- Create Tooltip Anchor
	local anchor = CreateFrame("Frame", ADDON_NAME.."Anchor", UIParent)
	anchor:SetSize(64, 64)
	anchor:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -150, 150)

	-- Hook Tips & Dropdowns
	HookTips()
	HookDropdowns()
end

mt:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
mt:RegisterEvent("PLAYER_LOGIN")
mt:RegisterEvent("PLAYER_LEVEL_UP")
mt:RegisterEvent("VARIABLES_LOADED")
mt:RegisterEvent("ADDON_LOADED")
-- mt:RegisterEvent("UNIT_TARGET") -- Implement dynamic update of target in tooltip?