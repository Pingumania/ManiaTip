local ADDON_NAME, ns = ...

ns.Classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
ns.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local GetQuestGreenRange = ns.Retail and UnitQuestTrivialLevelRange("player") or GetQuestGreenRange()

local L = ns.L
local mt = CreateFrame("Frame")
mt.playerLevel = 0
local itemCache = {}
local u

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
	FloatingBattlePetTooltip,
}

-- Config data variables
local cfg
local defaults = {
	showPlayerTitle = true,
	showRealm = true,
	showPlayerRealm = true,
	showSameRealm = true,
	showTarget = true,
	showId = true,
	targetYouText = "<YOU>",
	tipScale = 1,

	hidePvpText = false,
	hideFactionText = false,
	hideSubFactionText = false,

	colGuild = { 0.77, 0.12, 0.23, 1 },
	colSameGuild = { 1, 0.23, 0.56, 1 },

	colReact1 = { 0.5,  0.5,  0.5,  1 },
	colReact2 = { 1,    0,    0,    1 },
	colReact3 = { 0.8,  0.3,  0.22, 1 },
	colReact4 = { 0.9,  0.7,  0,    1 },
	colReact5 = { 0,    0.6,  0.1,  1 },
	colReact6 = { 0,    0.75, 0.95, 1 },
	colReact7 = { 0.35, 0.35, 0.35, 1 },

	tipColor = { TOOLTIP_DEFAULT_BACKGROUND_COLOR:GetRGBA() },
	tipBorderColor = { 1, 1, 1, 1 },

	targetColor = { NORMAL_FONT_COLOR:GetRGBA() },

	textFontFace = "Arial Narrow",
	textFontSize = 12,
	textFontFlags = "",

	barFontFace = "Arial Narrow",
	barFontSize = 12,
	barFontFlags = "OUTLINE",
	barTexture = "Blizzard",

	showBar = true,
	showBarValues = true,
	barsCondenseValues = true,

	classification_minus = "-%s ",
	classification_trivial = "~%s ",
	classification_normal = "%s ",
	classification_elite = "+%s ",
	classification_worldboss = "%s|r (Boss) ",
	classification_rare = "%s|r (Rare) ",
	classification_rareelite = "+%s|r (Rare) ",

	infoColor1 = { 0.2, 0.6, 1, 1 },
	infoColor2 = { 1,   1,   1, 1 },
}
ns.defaults = defaults

-- Faction names
local FactionNames = {}
for factionID = 1, 9999 do
	local factionData = C_Reputation.GetFactionDataByID(factionID)
	if factionData and factionData.name then
		FactionNames[factionData.name] = true
	end
end

-- Colors
local COLOR_WHITE = WHITE_FONT_COLOR_CODE
local COLOR_LIGHTGRAY = LIGHTGRAY_FONT_COLOR_CODE
local COLOR_WARNING = WARNING_FONT_COLOR_CODE
local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local ClassColorMarkup = {}
for classID, color in next, CLASS_COLORS do
	ClassColorMarkup[classID] = color:GenerateHexColorMarkup()
end

--------------------------------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------------------------------

local function GetDifficultyLevelColor(level)
	level = level - mt.playerLevel
	if level > 4 then
		return IMPOSSIBLE_DIFFICULTY_COLOR_CODE
	elseif level > 2 then
		return DIFFICULT_DIFFICULTY_COLOR_CODE
	elseif level >= -2 then
		return FAIR_DIFFICULTY_COLOR_CODE
	elseif level >= -GetQuestGreenRange then
		return EASY_DIFFICULTY_COLOR_CODE
	else
		return TRIVIAL_DIFFICULTY_COLOR_CODE
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

local function SetFormattedBarValues(bar, val, max)
	if val > 0 then
		bar:SetFormattedText("%s / %s", FormatValue(val), FormatValue(max))
	elseif max then
		bar:SetText(DEAD)
	end
end

local function GetRGBAAsBytes(color)
	return Round(color[1] * 255), Round(color[2] * 255), Round(color[3] * 255), Round((color[4] or 1) * 255)
end

local function GenerateHexColor(color)
	return ("ff%.2x%.2x%.2x"):format(GetRGBAAsBytes(color))
end

local function GenerateHexColorMarkup(color)
	return "|c"..GenerateHexColor(color)
end

local function SafeUnpackColor(color, default)
    default = default or 1
    return color[1] or default,
           color[2] or default,
           color[3] or default,
           color[4] or default
end

--------------------------------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------------------------------

local function SetDefaultNineSliceColor(tip)
	if not tip or tip.IsEmbedded then
		return
	end

	if tip.NineSlice then
		tip.NineSlice:SetCenterColor(SafeUnpackColor(cfg.tipColor))
		tip.NineSlice:SetBorderColor(SafeUnpackColor(cfg.tipBorderColor))
	end
end

local function GetUnit(tip)
	local _, unit = tip:GetUnit()

	return unit
end

local function GetLevelLineIndex(tip)
	for i = 1, tip:NumLines() do
		local text = _G[tip:GetName().."TextLeft"..i]:GetText()
		if text and strfind(text, LEVEL) then
			return i
		end
	end

	return false
end

local function GetLevelLineIndexFromTooltipData(data)
	local offset = 0
	if data.lines[1].leftText == "" then
		offset = -1
	end
	for i = 2, 4 do
		local text = data.lines[i] and data.lines[i].leftText
		if text and strfind(text, LEVEL) then
			return i + offset
		end
	end

	return false
end

local function RemoveUnwantedLines(tip)
	local line, text
	for i = 2, tip:NumLines() do
		line = _G["GameTooltipTextLeft"..i]
		text = line:GetText()
		if (cfg.hideFactionText) and (text == FACTION_ALLIANCE or text == FACTION_HORDE) then
			line:SetText("")
		elseif (cfg.hidePvpText) and (text == PVP_ENABLED) then
			line:SetText("")
		elseif (cfg.hideSubFactionText) and FactionNames[text] then
			line:SetText("")
		end
	end
end

local function GetEmptyTrailingLines(tip)
	local frame
	local count = 0
	for i = 2, tip:NumLines() do
		frame = _G[tip:GetName().."TextLeft"..i]
		if frame and (frame:GetStringHeight() == 0 or not frame:GetText()) then
			count = count + 1
		else
			count = 0
		end
	end

	return count
end

local function GetEmptyTrailingLine(tip)
	local count = GetEmptyTrailingLines(tip)
	if count > 0 then
		return _G["GameTooltipTextLeft"..tip:NumLines() + 1 - count]
	else
		tip:AddLine(" ")
		return _G["GameTooltipTextLeft"..tip:NumLines()]
	end
end

local function AddIdLine(tip, id)
	if cfg.showId and id ~= "" then
		tip:AddLine(" ")
		tip:AddLine(WrapTextInColorCode(L["id"], GenerateHexColor(cfg.infoColor1))..WrapTextInColorCode(id, GenerateHexColor(cfg.infoColor2)))
	end
end

local function SetNineSliceBorderColor(tip, itemLinkOrID)
	if tip.IsEmbedded then
		return
	end

	if itemCache[itemLinkOrID] then
		local r, g, b = C_Item.GetItemQualityColor(itemCache[itemLinkOrID])
		tip.NineSlice:SetBorderColor(r, g, b, 1)
		return
	end

	local item
	if type(itemLinkOrID) == "number" then
		item = Item:CreateFromItemID(itemLinkOrID)
	elseif type(itemLinkOrID) == "string" then
		item = Item:CreateFromItemLink(itemLinkOrID)
	end
	if item:IsItemEmpty() then
		return
	end
	-- This function also executes when the item is already loaded
	item:ContinueOnItemLoad(function()
		local rarity = item:GetItemQuality()
		local r, g, b = C_Item.GetItemQualityColor(rarity)
		tip.NineSlice:SetBorderColor(r, g, b, 1)
		itemCache[itemLinkOrID] = rarity
	end)
end

local function GetTarget(unit)
	local target = unit.."target"
	local targetName = UnitName(target)
	return target, targetName
end

local function CalculateYOffset(tip)
	local yPadding = GetEmptyTrailingLines(tip) * -3
	return yPadding
end

local function OnTooltipShow(tip)
	if not u then
		return
	end

	tip:SetPadding(0, CalculateYOffset(tip))
end

local function OnTooltipSetUnit(tip, data)
	if tip ~= GameTooltip then
		return
	end

	local unit = GetUnit(tip)

	if not unit then
		tip:Hide()
		return
	end

	RemoveUnwantedLines(tip)

	u = unit
	local isPlayer = UnitIsPlayer(unit)
	local guild = GetGuildInfo(unit)
	local _, classID = UnitClass(unit)
	local reactionIndex = GetUnitReactionIndex(unit)
	local fullName = data.lines[1].leftText ~= "" and data.lines[1].leftText or data.lines[2].leftText
	local reactionColor = cfg["colReact"..reactionIndex]
	local reactionColorMarkup = GenerateHexColorMarkup(reactionColor)
	local isPetWild, isPetCompanion = UnitIsWildBattlePet(unit), UnitIsBattlePetCompanion(unit)

	-- UnitName
	local nameString = reactionColorMarkup..fullName
	local color = reactionColor
	if isPlayer then
		local name, realm = UnitName(unit)
		color = { CLASS_COLORS[classID]:GetRGBA() }
		nameString = ClassColorMarkup[classID]..name

		if cfg.showPlayerTitle then
			if realm then
				nameString = ClassColorMarkup[classID]..gsub(fullName, "-"..realm, "")
			else
				nameString = ClassColorMarkup[classID]..fullName
			end
		end
		if cfg.showRealm then
			if cfg.showSameRealm then
				if not realm then
					realm = GetRealmName()
				end
			end
			nameString = nameString..(realm and "-"..realm or "")
		end
		-- dc, afk or dnd
		local status = (not UnitIsConnected(unit) and " <DC>") or (UnitIsAFK(unit) and " <AFK>") or (UnitIsDND(unit) and " <DND>")
		if status then
			nameString = nameString..COLOR_WHITE..status
		end
	end
	GameTooltipTextLeft1:SetFormattedText("%s", nameString)
	tip.NineSlice:SetBorderColor(SafeUnpackColor(color))
	GameTooltipStatusBar:SetStatusBarColor(SafeUnpackColor(color))

	-- Guild
	if isPlayer and guild then
		local pGuild = GetGuildInfo("player")
		local guildColor = (guild == pGuild and GenerateHexColorMarkup(cfg.colSameGuild) or GenerateHexColorMarkup(cfg.colGuild))
		GameTooltipTextLeft2:SetFormattedText("%s<%s>", guildColor, guild)
	end

	-- Level + Classification
	local level = (isPetWild or isPetCompanion) and UnitBattlePetLevel(unit) or UnitLevel(unit) or -1
	local classification = UnitClassification(unit) or ""
	local unitClass = isPlayer and UnitRace(unit) or "" or (isPetWild or isPetCompanion) and _G["BATTLE_PET_NAME_"..UnitBattlePetType(unit)] or UnitCreatureFamily(unit) or UnitCreatureType(unit) or ""
	local levelColor = GetDifficultyLevelColor(level ~= -1 and level or 500)
	local levelText = (cfg["classification_"..classification] or "%s? "):format(level == -1 and "??" or level)
	local levelLine = GetLevelLineIndexFromTooltipData(data)
	if levelLine then
		_G["GameTooltipTextLeft"..levelLine]:SetFormattedText("%s %s%s", LEVEL, levelColor..levelText.."|r", unitClass)
	end

	-- Target
	if cfg.showTarget then
		local target, targetName = GetTarget(unit)
		if target then
			local text = ""
			if targetName and (targetName ~= UNKNOWNOBJECT and targetName ~= "" or UnitExists(target)) then
				text = GenerateHexColorMarkup(cfg["targetColor"])..BINDING_HEADER_TARGETING..": "
				if (UnitIsUnit("player", target)) then
					text = text..COLOR_WARNING..cfg.targetYouText
				else
					local targetReactionIndex = GetUnitReactionIndex(target)
					local targetReactionColor = cfg["colReact"..targetReactionIndex]
					local targetReactionColorMarkup = GenerateHexColorMarkup(targetReactionColor)
					text = text..targetReactionColorMarkup
					if (UnitIsPlayer(target)) then
						local _, targetClassID = UnitClass(target)
						text = text..(ClassColorMarkup[targetClassID] or COLOR_LIGHTGRAY)..targetName
					else
						text = text..targetName
					end
				end

				local line = GetEmptyTrailingLine(tip)
				line:SetText(text)
			end
		end
	end

	local textWidth = _G[ADDON_NAME.."StatusBarHealthText"]:GetStringWidth()
	if textWidth and GameTooltipStatusBar:IsShown() then
		tip:SetMinimumWidth(textWidth + 12)
	end

	for i = 1, tip:NumLines() do
		local line = _G[tip:GetName().."TextLeft"..i]
		line:SetSpacing(0)
	end

	tip:Show()
end

local function OnTooltipSetItem(tip)
	if tip ~= GameTooltip and tip ~= ItemRefTooltip and tip ~= ItemRefShoppingTooltip1 and tip ~= ItemRefShoppingTooltip2 and tip ~= ShoppingTooltip1 and tip ~= ShoppingTooltip2 then
		return
	end

	if not tip.GetItem then
		Mixin(tip, GameTooltipDataMixin)
	end

	local _, link = tip:GetItem()
	if not link then
		return
	end

	SetNineSliceBorderColor(tip, link)

	local id = strmatch(link, "item:(%d+)")
	if id then
		AddIdLine(tip, id)
	end
end

local function OnTooltipSetSpell(tip, data)
	if tip ~= GameTooltip then
		return
	end

	if data.id then
		AddIdLine(tip, data.id)
	end
end

local function OnTooltipSetUnitAura(tip, data)
	if tip ~= GameTooltip and tip ~= ItemRefTooltip then
		return
	end

	if data.id then
		AddIdLine(tip, data.id)
	end
end

local function OnTooltipSetToy(tip, data)
	if tip ~= GameTooltip then
		return
	end

	if data.id then
		SetNineSliceBorderColor(tip, data.id)
		AddIdLine(tip, data.id)
	end
end

local function OnTooltipSetMacro(tip, data)
	if tip ~= GameTooltip then
		return
	end

	if data and data.lines[1] and data.lines[1].tooltipID then
		if data.lines[1].tooltipType == 0 then
			SetNineSliceBorderColor(tip, data.lines[1].tooltipID)
		end
		AddIdLine(tip, data.lines[1].tooltipID)
	end
end

local function PetBattleUnitTooltip_UpdateForUnit(tip, owner, index)
	if C_PetBattles.IsWildBattle() then
		local rarity = C_PetBattles.GetBreedQuality(owner, index)
		tip.NineSlice:SetBorderColor(ITEM_QUALITY_COLORS[rarity].r, ITEM_QUALITY_COLORS[rarity].g, ITEM_QUALITY_COLORS[rarity].b, 1)
	end
end

local function OnTooltipCleared(tip)
	if tip.ItemTooltip and not tip.ItemTooltip:IsShown() then
		tip:SetPadding(0, 0)
	end

	GameTooltipStatusBar.text:SetText("")

	u = nil
end

local function SetupGameTooltipStatusBar()
	GameTooltipStatusBar.bg = GameTooltipStatusBar:CreateTexture(nil, "BACKGROUND")
	GameTooltipStatusBar.bg:SetVertexColor(0.3, 0.3, 0.3, 0.6)
	GameTooltipStatusBar.bg:SetAllPoints()
	GameTooltipStatusBar.text = GameTooltipStatusBar:CreateFontString(ADDON_NAME.."StatusBarHealthText")
	GameTooltipStatusBar.text:SetPoint("CENTER", GameTooltipStatusBar)
	GameTooltipStatusBar.text:SetFont(LibStub("LibSharedMedia-3.0"):Fetch("font", cfg.barFontFace), cfg.barFontSize, cfg.barFontFlags)
	GameTooltipStatusBar:HookScript("OnShow", function(self)
		if cfg.showBar then
			self:Show()
		else
			self:Hide()
		end
	end)
end

local function StatusBar_OnValueChanged(self, value)
	if not value then
		return
	end

	local unit = GetUnit(self:GetParent())
	if not unit then
		return
	end

	if cfg.showBarValues then
		local current = UnitHealth(unit)
		local max = UnitHealthMax(unit)

		if (current < 0) or (current > max) then
			return
		end
		SetFormattedBarValues(GameTooltipStatusBar.text, current, max)
	end
end

local function GTT_SetDefaultAnchor(tip, parent)
	if not parent then
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
	local level, race, classID
	if self.GetMemberInfo then
		local info = self:GetMemberInfo()
		if not info then
			return
		end
		classID = info.classID
		level = info.level
		race = info.race
	else
		return
	end

	if not classID then
		return
	end

	local text = GameTooltipTextLeft1:GetText()
	if not text then
		return
	end

	if cfg.showRealm and cfg.showSameRealm then
		if (not strmatch(text, "%a+%-.+")) then
			text = text.."-"..GetRealmName()
		end
	else
		text = gsub(text, "%-.+", "")
	end

	local classInfo = C_CreatureInfo.GetClassInfo(classID)
	local color = { CLASS_COLORS[classInfo.classFile]:GetRGBA() }
	GameTooltipTextLeft1:SetFormattedText("%s", ClassColorMarkup[classInfo.classFile]..text)

	local raceInfo = C_CreatureInfo.GetRaceInfo(race)
	local levelColor = GetDifficultyLevelColor(level ~= -1 and level or 500)
	local levelLine = GetLevelLineIndex(GameTooltip)
	if levelLine then
		_G["GameTooltipTextLeft"..levelLine]:SetFormattedText("%s %s %s", levelColor..level.."|r", raceInfo.raceName, ClassColorMarkup[classInfo.classFile]..classInfo.className)
	end

	GameTooltip.NineSlice:SetBorderColor(SafeUnpackColor(color))
	GameTooltip:Show()
end

local function MemberList_OnLeave()
	GameTooltip:Hide()
end

--------------------------------------------------------------------------------------------------------
-- Config update
--------------------------------------------------------------------------------------------------------

local function UpdateTooltipScale()
	for _, tip in next, tips do
		tip:SetScale(cfg.tipScale)
	end
end
ns.UpdateTooltipScale = UpdateTooltipScale

local function UpdateGameTooltipFont()
	local font = LibStub("LibSharedMedia-3.0"):Fetch("font", cfg.textFontFace)
	local size = cfg.textFontSize
	local flag = cfg.textFontFlags == "NONE" and "" or cfg.textFontFlags
	GameTooltipText:SetFont(font, size, flag)
	GameTooltipHeaderText:SetFont(font, size + 2, flag)
	GameTooltipTextSmall:SetFont(font, size, flag)
end
ns.UpdateGameTooltipFont = UpdateGameTooltipFont

local function UpdateGameTooltipStatusBarVisibility()
	if cfg.showBar then
		if cfg.showBarValues then
			GameTooltipStatusBar.text:Show()
		else
			GameTooltipStatusBar.text:Hide()
		end
	else
		GameTooltipStatusBar.text:Hide()
	end
end
ns.UpdateGameTooltipStatusBarVisibility = UpdateGameTooltipStatusBarVisibility

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

local function HookTips()
	for _, tip in next, tips do
		SetDefaultNineSliceColor(tip)
	end

	GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
	hooksecurefunc(GameTooltip, "Show", OnTooltipShow)
	GameTooltipStatusBar:SetScript("OnValueChanged", StatusBar_OnValueChanged)
	hooksecurefunc("GameTooltip_SetDefaultAnchor", GTT_SetDefaultAnchor)
	hooksecurefunc("SharedTooltip_SetBackdropStyle", STT_SetBackdropStyle)

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, OnTooltipSetSpell)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, OnTooltipSetUnitAura)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Toy, OnTooltipSetToy)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Macro, OnTooltipSetMacro)
end

--------------------------------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------------------------------

function mt:PLAYER_LOGIN(event)
	UpdateGameTooltipStatusBarTexture()
	UpdateGameTooltipStatusBarText()
	UpdateGameTooltipFont()

	self.playerLevel = UnitLevel("player")
	self:UnregisterEvent(event)
end

function mt:PLAYER_LEVEL_UP(event, newLevel)
	self.playerLevel = newLevel
end

EventUtil.ContinueOnAddOnLoaded(ADDON_NAME, function()
	if not ManiaTipDB then
		ManiaTipDB = {}
	end

	cfg = setmetatable(ManiaTipDB, { __index = defaults })
	ns.cfg = cfg

	SetupGameTooltipStatusBar()
	HookTips()
	UpdateTooltipScale()
end)

EventUtil.ContinueOnAddOnLoaded("Blizzard_Communities", function()
	local hooked = {}
	local function OnTokenButtonAcquired(_, frame)
		if not hooked[frame] then
		frame:HookScript("OnEnter", MemberList_OnEnter)
		frame:HookScript("OnLeave", MemberList_OnLeave)
			hooked[frame] = true
		end
	end

	local iterateExisting = true
	local owner = nil
	ScrollUtil.AddAcquiredFrameCallback(CommunitiesFrame.MemberList.ScrollBox, OnTokenButtonAcquired, owner, iterateExisting)
end)

EventUtil.ContinueOnAddOnLoaded("Blizzard_Calendar", function()
	SetDefaultNineSliceColor(CalendarContextMenu)
end)

EventUtil.ContinueOnAddOnLoaded("Blizzard_PetBattleUI", function()
	hooksecurefunc("PetBattleUnitTooltip_UpdateForUnit", PetBattleUnitTooltip_UpdateForUnit)
end)

mt:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
mt:RegisterEvent("PLAYER_LOGIN")
mt:RegisterEvent("PLAYER_LEVEL_UP")