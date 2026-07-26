local ADDON_NAME, ns = ...

ns.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
ns.Era = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
-- ns.Classic = not ns.Retail and not ns.Era

local L = ns.L

--------------------------------------------------------------------------------------------------------
-- Saved variables
--------------------------------------------------------------------------------------------------------

ns.defaults = {
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

	tipColor = { 0.090, 0.090, 0.188, 1.000 },
	tipBorderColor = { 1, 1, 1, 1 },

	targetColor = { 1.000, 0.824, 0.000, 1.000 },

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

--------------------------------------------------------------------------------------------------------
-- Tooltip lists
--------------------------------------------------------------------------------------------------------

ns.RetailTooltips = {
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

ns.EraTooltips = {
	GameTooltip,
	ShoppingTooltip1,
	ShoppingTooltip2,
	ItemRefTooltip,
	ItemRefShoppingTooltip1,
	ItemRefShoppingTooltip2,
}

if ns.Retail then
	ns.tooltips = ns.RetailTooltips
else
	ns.tooltips = ns.EraTooltips
end

--------------------------------------------------------------------------------------------------------
-- Shared colors
--------------------------------------------------------------------------------------------------------

ns.COLOR_WHITE = WHITE_FONT_COLOR_CODE
ns.COLOR_WARNING = WARNING_FONT_COLOR_CODE
ns.CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS

ns.ClassColorMarkup = {}
for classID, color in next, ns.CLASS_COLORS do
	ns.ClassColorMarkup[classID] = color:GenerateHexColorMarkup()
end

function ns.GenerateHexColor(color)
	return CreateColor(unpack(color)):GenerateHexColor()
end

function ns.GenerateHexColorMarkup(color)
	return CreateColor(unpack(color)):GenerateHexColorMarkup()
end

--------------------------------------------------------------------------------------------------------
-- Player level tracking
--------------------------------------------------------------------------------------------------------

local function GetQuestGreenRange()
	return ns.Retail and UnitQuestTrivialLevelRange("player") or _G.GetQuestGreenRange()
end

function ns.GetDifficultyLevelColor(level)
	local diff = level - ns.playerLevel
	if diff >= 5 then
		return IMPOSSIBLE_DIFFICULTY_COLOR_CODE
	elseif diff >= 3 then
		return DIFFICULT_DIFFICULTY_COLOR_CODE
	elseif diff >= -2 then
		return FAIR_DIFFICULTY_COLOR_CODE
	elseif -diff <= ns.questGreenRange then
		return EASY_DIFFICULTY_COLOR_CODE
	else
		return TRIVIAL_DIFFICULTY_COLOR_CODE
	end
end

local function RefreshPlayerLevel()
	ns.playerLevel = UnitLevel("player")
	ns.questGreenRange = GetQuestGreenRange()
end

--------------------------------------------------------------------------------------------------------
-- Currently-hovered unit
--------------------------------------------------------------------------------------------------------

ns.activeUnit = {}

local function StatusBar_OnValueChanged(self)
	if self ~= GameTooltipStatusBar or not ns.activeUnit.token then
		return
	end

	GameTooltipStatusBar:SetStatusBarColor(ns.activeUnit.color:GetRGBA())

	if ns.cfg.showBarValues then
		GameTooltipStatusBar.text:SetText(ns.GetHealthBarText(ns.activeUnit.token))
	end
end

local function OnTooltipCleared(tip)
	if tip.ItemTooltip and not tip.ItemTooltip:IsShown() then
		tip:SetPadding(0, 0)
	end

	GameTooltipStatusBar.text:SetText("")
	ns.SetDefaultNineSliceColor(tip)

	if ns.Retail then
		ns.activeUnit = {}
	end
end

--------------------------------------------------------------------------------------------------------
-- Shared tooltip visuals
--------------------------------------------------------------------------------------------------------

local TooltipLayout = {
	["TopRightCorner"] = { atlas = "Tooltip-NineSlice-CornerTopRight" },
	["TopLeftCorner"] = { atlas = "Tooltip-NineSlice-CornerTopLeft" },
	["BottomLeftCorner"] = { atlas = "Tooltip-NineSlice-CornerBottomLeft" },
	["BottomRightCorner"] = { atlas = "Tooltip-NineSlice-CornerBottomRight" },
	["TopEdge"] = { atlas = "_Tooltip-NineSlice-EdgeTop" },
	["BottomEdge"] = { atlas = "_Tooltip-NineSlice-EdgeBottom" },
	["LeftEdge"] = { atlas = "!Tooltip-NineSlice-EdgeLeft" },
	["RightEdge"] = { atlas = "!Tooltip-NineSlice-EdgeRight" },
	["Center"] = { layer = "BACKGROUND", atlas = "Tooltip-NineSlice-Center", x = -4, y = 4, x1 = 4, y1 = -4 },
}

function ns.SetDefaultNineSliceColor(tip)
	if not tip or tip.IsEmbedded then
		return
	end

	if tip.NineSlice then
		tip.NineSlice:SetCenterColor(unpack(ns.cfg.tipColor))
		tip.NineSlice:SetBorderColor(unpack(ns.cfg.tipBorderColor))
	end
end

local function STT_SetBackdropStyle(tip)
	if not tip or tip.IsEmbedded then
		return
	end

	if tip.NineSlice then
		NineSliceUtil.ApplyLayout(tip.NineSlice, TooltipLayout)
	end

	ns.SetDefaultNineSliceColor(tip)
end

local itemQualityCache = {}
function ns.SetNineSliceBorderColor(tip, itemLinkOrID)
	if tip.IsEmbedded then
		return
	end

	if itemQualityCache[itemLinkOrID] then
		local r, g, b = C_Item.GetItemQualityColor(itemQualityCache[itemLinkOrID])
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
	-- Also fires immediately if the item is already loaded.
	item:ContinueOnItemLoad(function()
		local rarity = item:GetItemQuality()
		local r, g, b = C_Item.GetItemQualityColor(rarity)
		tip.NineSlice:SetBorderColor(r, g, b, 1)
		itemQualityCache[itemLinkOrID] = rarity
	end)
end

function ns.AddIdLine(tip, id)
	if ns.cfg.showId and id ~= "" then
		tip:AddLine(" ")
		tip:AddLine(WrapTextInColorCode(L["id"], ns.GenerateHexColor(ns.cfg.infoColor1))..WrapTextInColorCode(id, ns.GenerateHexColor(ns.cfg.infoColor2)))
	end
end

-- Scans rendered lines for "Level NN" text
function ns.FindLevelLineByText(tip)
	for i = 2, tip:NumLines() do
		local leftText = _G[tip:GetName().."TextLeft"..i]:GetText()
		if leftText and strfind(leftText, "^"..LEVEL.." [%d%?]+") then
			return i
		end
	end

	return false
end

function ns.AddEmptyTrailingLine(tip)
	tip:AddLine(" ")
	return _G[tip:GetName().."TextLeft"..tip:NumLines()]
end

--------------------------------------------------------------------------------------------------------
-- Item/Spell/Toy/Macro tooltips
--------------------------------------------------------------------------------------------------------

local function OnTooltipSetItem(tip, data)
	if tip ~= GameTooltip and tip ~= ItemRefTooltip and tip ~= ItemRefShoppingTooltip1 and tip ~= ItemRefShoppingTooltip2 and tip ~= ShoppingTooltip1 and tip ~= ShoppingTooltip2 then
		return
	end

	if data and data.id then
		tip.NineSlice:SetBorderColor(data.lines[1].leftColor:GetRGBA())
		ns.AddIdLine(tip, data.id)
	end
end

local function OnTooltipSetSpell(tip, data)
	if tip ~= GameTooltip then
		return
	end

	local id = (data and data.id) or select(2, tip:GetSpell())
	if id then
		ns.AddIdLine(tip, id)
	end
end

local function OnTooltipSetUnitAura(tip, data)
	if tip ~= GameTooltip and tip ~= ItemRefTooltip then
		return
	end

	if data.id then
		ns.AddIdLine(tip, data.id)
	end
end

local function OnTooltipSetToy(tip, data)
	if tip ~= GameTooltip then
		return
	end

	if data.id then
		ns.SetNineSliceBorderColor(tip, data.id)
		ns.AddIdLine(tip, data.id)
	end
end

local function OnTooltipSetMacro(tip, data)
	if tip ~= GameTooltip then
		return
	end

	if data and data.lines[2] then
		if data.lines[1].tooltipType == 0 then
			tip.NineSlice:SetBorderColor(data.lines[2].leftColor:GetRGBA())
		end
		ns.AddIdLine(tip, data.lines[1].tooltipID)
	end
end

ns.OnTooltipSetItem = OnTooltipSetItem
ns.OnTooltipSetSpell = OnTooltipSetSpell
ns.OnTooltipSetUnitAura = OnTooltipSetUnitAura
ns.OnTooltipSetToy = OnTooltipSetToy
ns.OnTooltipSetMacro = OnTooltipSetMacro

--------------------------------------------------------------------------------------------------------
-- Anchor
--------------------------------------------------------------------------------------------------------

local function GTT_SetDefaultAnchor(tip, parent)
	if not parent then
		return
	end

	tip:SetOwner(parent, "ANCHOR_NONE")

	if ns.FlavorModule.SetCustomAnchorPoint then
		tip:ClearAllPoints()
		ns.FlavorModule.SetCustomAnchorPoint(tip)
	end
end

--------------------------------------------------------------------------------------------------------
-- Status bar (health bar) styling
--------------------------------------------------------------------------------------------------------

local function SetupGameTooltipStatusBar()
	GameTooltipStatusBar.bg = GameTooltipStatusBar:CreateTexture(nil, "BACKGROUND")
	GameTooltipStatusBar.bg:SetVertexColor(0.3, 0.3, 0.3, 0.6)
	GameTooltipStatusBar.bg:SetAllPoints()
	GameTooltipStatusBar.text = GameTooltipStatusBar:CreateFontString(ADDON_NAME.."StatusBarHealthText")
	GameTooltipStatusBar.text:SetPoint("CENTER", GameTooltipStatusBar, 1, 0)
	GameTooltipStatusBar.text:SetFont(LibStub("LibSharedMedia-3.0"):Fetch("font", ns.cfg.barFontFace), ns.cfg.barFontSize, ns.cfg.barFontFlags)
	GameTooltipStatusBar:HookScript("OnShow", function(self)
		if ns.cfg.showBar then
			self:Show()
		else
			self:Hide()
		end
	end)
end

function ns.UpdateTooltipScale()
	for _, tip in next, ns.tooltips do
		tip:SetScale(ns.cfg.tipScale)
	end
end

function ns.UpdateGameTooltipFont()
	local font = LibStub("LibSharedMedia-3.0"):Fetch("font", ns.cfg.textFontFace) or ns.cfg.textFontFace
	local size = ns.cfg.textFontSize
	local flag = ns.cfg.textFontFlags == "NONE" and "" or ns.cfg.textFontFlags
	GameTooltipText:SetFont(font, size, flag)
	GameTooltipHeaderText:SetFont(font, size + 2, flag)
	GameTooltipTextSmall:SetFont(font, size, flag)
end

function ns.UpdateGameTooltipStatusBarVisibility()
	if ns.cfg.showBar and ns.cfg.showBarValues then
		GameTooltipStatusBar.text:Show()
	else
		GameTooltipStatusBar.text:Hide()
	end
end

function ns.UpdateGameTooltipStatusBarTexture()
	GameTooltipStatusBar:SetStatusBarTexture(LibStub("LibSharedMedia-3.0"):Fetch("statusbar", ns.cfg.barTexture))
	GameTooltipStatusBar.bg:SetTexture(LibStub("LibSharedMedia-3.0"):Fetch("statusbar", ns.cfg.barTexture))
end

function ns.UpdateGameTooltipStatusBarText()
	GameTooltipStatusBar.text:SetFont(LibStub("LibSharedMedia-3.0"):Fetch("font", ns.cfg.barFontFace), ns.cfg.barFontSize, ns.cfg.barFontFlags)
end

--------------------------------------------------------------------------------------------------------
-- Pet battle border coloring
--------------------------------------------------------------------------------------------------------

local function PetBattleUnitTooltip_UpdateForUnit(tip, owner, index)
	if C_PetBattles.IsWildBattle() then
		local rarity = C_PetBattles.GetBreedQuality(owner, index)
		tip.NineSlice:SetBorderColor(ITEM_QUALITY_COLORS[rarity].r, ITEM_QUALITY_COLORS[rarity].g, ITEM_QUALITY_COLORS[rarity].b, 1)
	end
end

--------------------------------------------------------------------------------------------------------
-- Hook registration
--------------------------------------------------------------------------------------------------------

local function RegisterCommonHooks()
	for _, tip in next, ns.tooltips do
		ns.SetDefaultNineSliceColor(tip)
	end

	GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
	ItemRefTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
	hooksecurefunc("GameTooltip_SetDefaultAnchor", GTT_SetDefaultAnchor)
	hooksecurefunc("SharedTooltip_SetBackdropStyle", STT_SetBackdropStyle)
	hooksecurefunc("HealthBar_OnValueChanged", StatusBar_OnValueChanged)

	if ns.Retail then
		ns.FlavorModule = ns.RetailModule
	else
		ns.FlavorModule = ns.EraModule
	end

	ns.FlavorModule.Init()
	ns.GetHealthBarText = ns.FlavorModule.GetHealthBarText
end

--------------------------------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------------------------------

local mt = CreateFrame("Frame")

function mt:PLAYER_LOGIN()
	ns.UpdateGameTooltipStatusBarTexture()
	ns.UpdateGameTooltipStatusBarText()
	ns.UpdateGameTooltipFont()
	RefreshPlayerLevel()
end

mt:SetScript("OnEvent", function(self, event, ...)
	self[event](self, event, ...)
end)
mt.PLAYER_ENTERING_WORLD = RefreshPlayerLevel
mt.PLAYER_LEVEL_UP = RefreshPlayerLevel
mt.PLAYER_LEVEL_CHANGED = RefreshPlayerLevel
mt:RegisterEvent("PLAYER_LOGIN")
mt:RegisterEvent("PLAYER_LEVEL_UP")
mt:RegisterEvent("PLAYER_LEVEL_CHANGED")
mt:RegisterEvent("PLAYER_ENTERING_WORLD")

EventUtil.ContinueOnAddOnLoaded(ADDON_NAME, function()
	if not ManiaTipDB then
		ManiaTipDB = {}
	end

	ns.cfg = setmetatable(ManiaTipDB, { __index = ns.defaults })

	SetupGameTooltipStatusBar()
	RegisterCommonHooks()
	ns.UpdateTooltipScale()
end)

EventUtil.ContinueOnAddOnLoaded("Blizzard_Calendar", function()
	ns.SetDefaultNineSliceColor(CalendarContextMenu)
end)

EventUtil.ContinueOnAddOnLoaded("Blizzard_PetBattleUI", function()
	hooksecurefunc("PetBattleUnitTooltip_UpdateForUnit", PetBattleUnitTooltip_UpdateForUnit)
end)
