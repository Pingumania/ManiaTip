local _, ns = ...

--------------------------------------------------------------------------------------------------------
-- Reaction color lookup
--------------------------------------------------------------------------------------------------------

local function Plain(value, fallback)
	if issecretvalue(value) then
		return fallback
	end

	return value
end

local Transliterate = C_Intl and C_Intl.Transliterate
local latinNames = {}

local function Latin(text)
	if not (Transliterate and ns.Config.transliterateNames) then
		return text
	end

	if issecretvalue(text) then
		return Transliterate(text, "Any-Latin; Latin-ASCII")
	end

	if not latinNames[text] then
		latinNames[text] = Transliterate(text, "Any-Latin; Latin-ASCII")
	end

	return latinNames[text]
end

local function ReactionColor(index)
	return CreateColorFromHexString(ns.Config["reactionColor"..index])
end

local function GetUnitReactionColor(unit)
	if issecretvalue(UnitIsDead(unit)) then
		return ReactionColor(3)
	end

	if UnitIsDead(unit) then
		return ReactionColor(7)
	end

	if UnitIsTapDenied(unit) and not UnitPlayerControlled(unit) then
		return ReactionColor(1)
	end

	if not (UnitIsPlayer(unit) or UnitPlayerControlled(unit)) then
		local reaction = UnitReaction(unit, "player") or 3
		return ReactionColor((reaction > 5 and 5) or (reaction < 2 and 2) or reaction)
	end

	if UnitCanAttack(unit, "player") then
		return ReactionColor(UnitCanAttack("player", unit) and 2 or 3)
	end

	if UnitCanAttack("player", unit) then
		return ReactionColor(4)
	end

	if UnitIsPVPSanctuary(unit) or UnitIsPVPSanctuary("player") then
		return ReactionColor(6)
	end

	return C_CurveUtil.EvaluateColorFromBoolean(UnitIsPVP(unit), ReactionColor(5), ReactionColor(6))
end

--------------------------------------------------------------------------------------------------------
-- Status tags
--------------------------------------------------------------------------------------------------------

local STATUS_ICONS = {
	"Interface\\FriendsFrame\\StatusIcon-Offline",
	"Interface\\FriendsFrame\\StatusIcon-Away",
	"Interface\\FriendsFrame\\StatusIcon-DnD",
}
local STATUS_TEXTS = { "DC", "AFK", "DND" }
local STATUS_COLOR_KEYS = { "statusColorOffline", "statusColorAFK", "statusColorDND" }
local INLINE_SPACER = "|TInterface\\Common\\spacer:1:"

local function BuildInlineTags(before, labels)
	local tags = { before = before }
	for i, label in ipairs(labels) do
		if before then
			tags[i] = { label..INLINE_SPACER, "|t " }
		else
			tags[i] = { " "..INLINE_SPACER, "|t"..label }
		end
	end
	return tags
end

local STATUS_ICON_LABELS = {}
for i, path in ipairs(STATUS_ICONS) do
	STATUS_ICON_LABELS[i] = "|T"..path..":0|t"
end

local INLINE_TAGS = {
	icon = BuildInlineTags(false, STATUS_ICON_LABELS),
	iconBefore = BuildInlineTags(true, STATUS_ICON_LABELS),
}

ns.STATUS_TEXT_TOGGLES = {
	statusTextPrefix = "useStatusTextPrefix",
	statusTextSuffix = "useStatusTextSuffix",
}

local function GetStatusText(key)
	if ns.Config[ns.STATUS_TEXT_TOGGLES[key]] then
		return ns.Config[key]
	end

	return ns.defaults[key]
end

function ns.UpdateStatusTexts()
	local prefix, suffix = GetStatusText("statusTextPrefix"), GetStatusText("statusTextSuffix")
	local labels = {}
	local color
	for i, text in ipairs(STATUS_TEXTS) do
		color = ns.Config.statusColors and ns.Config[STATUS_COLOR_KEYS[i]] or "ffffffff"
		labels[i] = "|c"..color..prefix..text..suffix.."|r"
	end

	INLINE_TAGS.text = BuildInlineTags(false, labels)
	INLINE_TAGS.textBefore = BuildInlineTags(true, labels)
end

function ns.UpdateStatusColors()
	ns.UpdateStatusTabColors()
	ns.UpdateStatusTexts()
end

local TAB_MARGIN = 4
local TAB_PADDING = 12
local TAB_INSET = 4
local TAB_OVERLAP = 10
local TAB_SINK = 2
local TAB_ICON_OFFSET = 2.5
local TAB_POSITIONS = {
	TOPLEFT = { "TOP", "LEFT" },
	TOPRIGHT = { "TOP", "RIGHT" },
	RIGHTTOP = { "RIGHT", "TOP" },
	RIGHTBOTTOM = { "RIGHT", "BOTTOM" },
	LEFTTOP = { "LEFT", "TOP" },
	LEFTBOTTOM = { "LEFT", "BOTTOM" },
}

local tabs

local function SetAlphaFromStatus(regions, unit)
	regions[1]:SetAlphaFromBoolean(UnitIsConnected(unit), 0, 1)
	regions[2]:SetAlphaFromBoolean(UnitIsAFK(unit), 1, 0)
	regions[3]:SetAlphaFromBoolean(UnitIsDND(unit), 1, 0)
end

local function HideTabs()
	for _, tab in ipairs(tabs) do
		tab:SetAlpha(0)
	end
end

function ns.AnchorStatusTabs()
	if not tabs then
		return
	end

	local side, align = unpack(TAB_POSITIONS[ns.Config.statusTabPosition] or TAB_POSITIONS.TOPRIGHT)
	local offset = (align == "LEFT" or align == "BOTTOM") and TAB_INSET or -TAB_INSET
	local opposite = side == "LEFT" and "RIGHT" or "LEFT"
	local inward = side == "LEFT" and 1 or -1
	local _, size = GameTooltipHeaderText:GetFont()
	size = math.ceil(size)
	local length, thickness = size + TAB_PADDING, size + TAB_MARGIN

	for _, clip in ipairs(tabs) do
		clip:ClearAllPoints()
		clip.tab:ClearAllPoints()
		clip.icon:ClearAllPoints()
		clip.icon:SetSize(size, size)

		if side == "TOP" then
			clip:SetSize(length, thickness)
			clip:SetPoint("BOTTOM"..align, GameTooltip, "TOP"..align, offset, -TAB_SINK)
			clip.icon:SetPoint("CENTER", clip, 0, -TAB_ICON_OFFSET)
			clip.tab:SetPoint("TOPLEFT")
			clip.tab:SetPoint("TOPRIGHT")
			clip.tab:SetHeight(thickness + TAB_OVERLAP)
		else
			clip:SetSize(thickness, length)
			clip:SetPoint(align..opposite, GameTooltip, align..side, inward * TAB_SINK, offset)
			clip.icon:SetPoint("CENTER", clip, inward * TAB_ICON_OFFSET, 0)
			clip.tab:SetPoint("TOP"..side)
			clip.tab:SetPoint("BOTTOM"..side)
			clip.tab:SetWidth(thickness + TAB_OVERLAP)
		end
	end
end

function ns.UpdateStatusTabColors()
	if not tabs then
		return
	end

	for i, clip in ipairs(tabs) do
		if ns.Config.statusColors then
			clip.tab:SetBorderColor(CreateColorFromHexString(ns.Config[STATUS_COLOR_KEYS[i]]):GetRGBA())
		else
			clip.tab:SetBorderColor(GameTooltip.NineSlice:GetBorderColor())
		end
	end
end

function ns.UpdateStatusTabBorders()
	if not tabs then
		return
	end

	for _, clip in ipairs(tabs) do
		NineSliceUtil.ApplyLayout(clip.tab, ns.GetTooltipLayout())
		clip.tab:SetCenterColor(GameTooltip.NineSlice:GetCenterColor())
	end

	ns.UpdateStatusTabColors()
end

local function CreateTabs()
	local clip, tab

	tabs = {}
	for i = 1, #STATUS_ICONS do
		clip = CreateFrame("Frame", nil, GameTooltip)
		clip:SetFrameLevel(math.max(GameTooltip:GetFrameLevel() - 1, 0))
		clip:SetClipsChildren(true)
		clip:SetAlpha(0)

		tab = CreateFrame("Frame", nil, clip, "NineSlicePanelTemplate")
		tab:SetUsingParentLevel(true)
		NineSliceUtil.ApplyLayout(tab, ns.GetTooltipLayout())
		tab:SetCenterColor(GameTooltip.NineSlice:GetCenterColor())

		clip.tab = tab
		clip.icon = tab:CreateTexture(nil, "OVERLAY")
		clip.icon:SetTexture(STATUS_ICONS[i])
		tabs[i] = clip
	end

	ns.AnchorStatusTabs()
	ns.UpdateStatusTabColors()

	GameTooltip:HookScript("OnTooltipCleared", HideTabs)

	hooksecurefunc(GameTooltip.NineSlice, "SetCenterColor", function(_, ...)
		for _, statusTab in ipairs(tabs) do
			statusTab.tab:SetCenterColor(...)
		end
	end)
	hooksecurefunc(GameTooltip.NineSlice, "SetBorderColor", function(_, ...)
		if ns.Config.statusColors then
			return
		end

		for _, statusTab in ipairs(tabs) do
			statusTab.tab:SetBorderColor(...)
		end
	end)
end

local function InlineTag(value, ifTrue, ifFalse, tag)
	local flag = C_StringUtil.TruncateWhenZero(C_CurveUtil.EvaluateColorValueFromBoolean(value, ifTrue, ifFalse))
	return C_StringUtil.WrapString(flag, tag[1], tag[2])
end

local function ShowStatusTags(unit)
	local style = ns.Config.statusTagStyle

	if style == "tab" then
		if not tabs then
			CreateTabs()
		end

		SetAlphaFromStatus(tabs, unit)
		return "", ""
	end

	local tags = INLINE_TAGS[style..(ns.Config.statusTagPosition == "before" and "Before" or "")] or INLINE_TAGS.icon
	local text = InlineTag(UnitIsConnected(unit), 0, 1, tags[1])..InlineTag(UnitIsAFK(unit), 1, 0, tags[2])..InlineTag(UnitIsDND(unit), 1, 0, tags[3])
	if tags.before then
		return text, ""
	end

	return "", text
end

--------------------------------------------------------------------------------------------------------
-- Display builders
--------------------------------------------------------------------------------------------------------

local function BuildNameDisplay(unit, isPlayer, classID, fullName)
	if not isPlayer then
		local reactionColor = GetUnitReactionColor(unit)
		return reactionColor, reactionColor:GenerateHexColorMarkup()..fullName
	end

	local color = C_ClassColor.GetClassColor(classID)
	local classMarkup = color:GenerateHexColorMarkup()
	local name, realm = UnitName(unit)
	local nameString = classMarkup..Latin(name)

	if ns.Config.showPlayerTitle then
		local titleName = fullName
		if realm and not (issecretvalue(fullName) or issecretvalue(realm)) then
			titleName = gsub(fullName, "-"..realm, "")
		end
		nameString = classMarkup..Latin(titleName)
	end

	if ns.Config.showRealm and not ns:IsForever() then
		if ns.Config.showSameRealm and not realm then
			realm = GetRealmName()
		end
		nameString = nameString..(realm and "-"..Latin(realm) or "")
	end

	local before, after = ShowStatusTags(unit)
	return color, before..nameString..after
end

-- Returns the formatted guild line text, or nil if the unit has none / is not a player.
local function BuildGuildDisplay(unit, isPlayer)
	if not isPlayer then
		return nil
	end

	local guild = Plain(GetGuildInfo(unit))
	if not guild then
		return nil
	end

	local sameGuild = guild == GetGuildInfo("player")
	local guildColorMarkup = '|cff' .. (sameGuild and ns.Config.sameGuildColor or ns.Config.guildColor):sub(3)
	return ("%s<%s>|r"):format(guildColorMarkup, Latin(guild))
end

-- Returns the formatted "Level NN Classification" line text.
local function BuildLevelDisplay(unit, isPlayer, classID)
	local isPet = (UnitIsWildBattlePet and Plain(UnitIsWildBattlePet(unit), false))
		or (UnitIsBattlePetCompanion and Plain(UnitIsBattlePetCompanion(unit), false))

	local level
	if isPet then
		level = UnitBattlePetLevel(unit)
	else
		level = UnitLevel(unit)
	end
	level = Plain(level) or -1

	-- level -1 is a boss regardless of what classification actually says.
	local classification = level == -1 and "worldboss" or (Plain(UnitClassification(unit)) or "")

	local unitInfo
	if isPlayer then
		unitInfo = UnitRace(unit).." "
	else
		unitInfo = ""
	end

	local levelColor = ns.GetDifficultyLevelColor(level ~= -1 and level or 500)
	local levelText = (ns.Config["classification_"..classification] or "%s? "):format(level == -1 and "??" or level)
	return ("%s %s|r%s"):format(LEVEL, levelColor..levelText, unitInfo)
end

-- Returns the formatted "Target: ..." line text, or nil if the unit has no target or the feature is disabled.
local function BuildTargetDisplay(unit)
	if not ns.Config.showTarget then
		return nil
	end

	local target = unit.."target"
	if not UnitExists(target) then
		return nil
	end

	local text = ns.GenerateHexColorMarkup(ns.Config.targetColor)..BINDING_HEADER_TARGETING..": "
	if Plain(UnitIsUnit("player", target), false) then
		text = text..ns.COLOR_WARNING..ns.Config.targetYouText.." |r"
	end

	local targetClassID = select(2, UnitClass(target))
	if Plain(UnitIsPlayer(target), false) and targetClassID then
		return text..C_ClassColor.GetClassColor(targetClassID):GenerateHexColorMarkup()..Latin(UnitName(target))
	end

	return text..GetUnitReactionColor(target):GenerateHexColorMarkup()..UnitName(target)
end

-- Returns: color (for the health bar hook), isPlayer, formatted level line text.
function ns.ApplyUnitTooltip(tip, unit, classID, fullName)
	local isPlayer = Plain(UnitIsPlayer(unit), classID ~= nil)

	local color, nameString = BuildNameDisplay(unit, isPlayer, classID, fullName)
	tip.NineSlice:SetBorderColor(color:GetRGBA())
	GameTooltipStatusBar:SetStatusBarColor(color:GetRGBA())
	_G["GameTooltipTextLeft1"]:SetFormattedText("%s|r", nameString)

	local guildText = BuildGuildDisplay(unit, isPlayer)
	if guildText then
		GameTooltipTextLeft2:SetFormattedText("%s", guildText)
	end

	local targetText = BuildTargetDisplay(unit)
	if targetText then
		ns.AddEmptyTrailingLine(tip):SetText(targetText)
	end

	ns.activeUnit.color = color

	return color, isPlayer, BuildLevelDisplay(unit, isPlayer, classID)
end
