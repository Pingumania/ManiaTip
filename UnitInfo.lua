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
local INLINE_FLAG_TEXTURE = "|TInterface\\Common\\spacer:1:"

local function BuildInlineTags(before, labels)
	local tags = { before = before }
	for i, label in ipairs(labels) do
		if before then
			tags[i] = { label..INLINE_FLAG_TEXTURE, "|t " }
		else
			tags[i] = { " "..INLINE_FLAG_TEXTURE, "|t"..label }
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
local function BuildGuildDisplay(unit, guild)
	if not guild then
		return nil
	end

	local sameGuild = Plain(UnitIsInMyGuild(unit), false)
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

local function ApplyUnitTooltip(tip, unit, classID, isPlayer, fullName, guild)
	local color, nameString = BuildNameDisplay(unit, isPlayer, classID, fullName)
	tip.NineSlice:SetBorderColor(color:GetRGBA())
	GameTooltipStatusBar:SetStatusBarColor(color:GetRGBA())
	_G["GameTooltipTextLeft1"]:SetFormattedText("%s|r", nameString)

	local guildText = BuildGuildDisplay(unit, guild)
	if guildText then
		GameTooltipTextLeft2:SetFormattedText("%s", guildText)
	end

	local targetText = BuildTargetDisplay(unit)
	if targetText then
		tip:AddLine(" ")
		tip:GetLeftLine(tip:NumLines()):SetText(targetText)
	end

	ns.activeUnit.color = color

	return BuildLevelDisplay(unit, isPlayer, classID)
end

--------------------------------------------------------------------------------------------------------
-- Faction/PvP text hiding
--------------------------------------------------------------------------------------------------------

local function GetTooltipUnit(tip)
	local info = tip.processingInfo
	local unit = info and info.getterArgs and info.getterArgs[1]
	if type(unit) == "string" and UnitExists(unit) then
		return unit
	end

	if UnitExists("mouseover") then
		return "mouseover"
	end
end

local function FindLevelLineFromData(data)
	for i, lineData in ipairs(data.lines) do
		local text = Plain(lineData.leftText)
		if text and strfind(text, "^"..LEVEL.." [%d%?]+") then
			return i
		end
	end
end

-- PvP and faction lines come as TooltipDataLineType.None, so they are found by text or position,
-- which fails once the text is secret. Proper filtering needs Blizzard to give them their own line type.
local droppedLines = {}
local current = {}

local function PrepareUnitLines(tip, data)
	wipe(droppedLines)
	wipe(current)
	if tip ~= GameTooltip then
		return
	end

	local unit = GetTooltipUnit(tip)
	if not unit then
		return
	end

	local _, classID = UnitClassFromGUID(data.guid)
	local isPlayer = Plain(UnitIsPlayer(unit), classID ~= nil)
	current.unit, current.classID, current.isPlayer = unit, classID, isPlayer
	if isPlayer then
		local guild = GetGuildInfo(unit)
		if not issecretvalue(guild) then
			current.guild = guild
			current.levelLine = guild and 3 or 2
		end
	else
		current.levelLine = FindLevelLineFromData(data)
	end

	if not (ns.Config.hideFactionText or ns.Config.hidePvpText) then
		return
	end

	local levelLine = current.levelLine
	local factionLine = levelLine and data.lines[levelLine + (isPlayer and 2 or 1)]
	local text
	for _, line in ipairs(data.lines) do
		text = Plain(line.leftText)
		if text == PVP_ENABLED then
			droppedLines[line] = ns.Config.hidePvpText
		elseif line == factionLine or text == FACTION_ALLIANCE or text == FACTION_HORDE then
			droppedLines[line] = ns.Config.hideFactionText
		end
	end
end

local function IsUnwantedLine(_, lineData)
	return droppedLines[lineData]
end

local function HideRightClickText(frame)
	if not ns.Config.hideRightClickText or not frame.UpdateTooltip or GameTooltip:IsForbidden() then
		return
	end

	GameTooltip:SetUnit(frame.unit, frame.hideStatusOnTooltip)
	GameTooltip:Show()
end

--------------------------------------------------------------------------------------------------------
-- Unit tooltip
--------------------------------------------------------------------------------------------------------

local function FindNameFromData(data)
	for _, lineData in ipairs(data.lines) do
		if lineData.type == Enum.TooltipDataLineType.UnitName then
			return lineData.leftText
		end
	end
end

local function OnTooltipSetUnit(tip, data)
	if tip ~= GameTooltip or not data then
		return
	end

	ns.activeUnit = {}

	local unit, levelLine = current.unit, current.levelLine
	if not unit then
		tip:Hide()
		return
	end

	local fullName = FindNameFromData(data) or UnitName(unit)
	local levelText = ApplyUnitTooltip(tip, unit, current.classID, current.isPlayer, fullName, current.guild)

	if levelLine then
		_G["GameTooltipTextLeft"..levelLine]:SetText(levelText)
	end

	if current.isPlayer and levelLine then
		local specLine = _G["GameTooltipTextLeft"..(levelLine + 1)]
		local text = specLine and specLine:GetText()
		local hasText = issecretvalue(text) or text
		if hasText and ns.Config.classColorText then
			specLine:SetFormattedText("%s%s|r", C_ClassColor.GetClassColor(current.classID):GenerateHexColorMarkup(), text)
		elseif hasText then
			specLine:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
		end
	end

	tip:Show()
end

--------------------------------------------------------------------------------------------------------
-- Guild roster hover tooltip
--------------------------------------------------------------------------------------------------------

local function MemberList_OnEnter(self)
	if not self.GetMemberInfo then
		return
	end

	local info = self:GetMemberInfo()
	if not info or not info.classID then
		return
	end

	local classInfo = C_CreatureInfo.GetClassInfo(info.classID)

	local name = info.name
	if ns.Config.showRealm and ns.Config.showSameRealm then
		if not strmatch(name, "%a+%-.+") then
			name = name.."-"..GetRealmName()
		end
	elseif not ns.Config.showRealm then
		name = gsub(name, "%-.+", "")
	end
	GameTooltipTextLeft1:SetFormattedText("%s", ns.ClassColorMarkup[classInfo.classFile]..name)

	local raceInfo = info.race and C_CreatureInfo.GetRaceInfo(info.race)
	if raceInfo and info.level then
		local levelColor = ns.GetDifficultyLevelColor(info.level ~= -1 and info.level or 500)
		local plainText = COMMUNITY_MEMBER_CHARACTER_INFO_FORMAT:format(info.level, raceInfo.raceName, classInfo.className)
		local classText = classInfo.className
		if ns.Config.classColorText then
			classText = ns.ClassColorMarkup[classInfo.classFile]..classText.."|r"
		end
		for i = 2, GameTooltip:NumLines() do
			local line = _G["GameTooltipTextLeft"..i]
			if line:GetText() == plainText then
				line:SetFormattedText("%s %s %s", levelColor..info.level.."|r", raceInfo.raceName, classText)
				break
			end
		end
	end

	GameTooltip.NineSlice:SetBorderColor(ns.CLASS_COLORS[classInfo.classFile]:GetRGBA())
	GameTooltip:Show()
end

local function MemberList_OnLeave()
	GameTooltip:Hide()
end

local function InitCommunitiesHook()
	local hooked = {}
	local function HookMember(frame)
		if not hooked[frame] then
			frame:HookScript("OnEnter", MemberList_OnEnter)
			frame:HookScript("OnLeave", MemberList_OnLeave)
			hooked[frame] = true
		end
	end

	CommunitiesFrame.MemberList.ScrollBox:ForEachFrame(HookMember)
	ScrollUtil.AddAcquiredFrameCallback(CommunitiesFrame.MemberList.ScrollBox, function(_, frame)
		HookMember(frame)
	end)
end

--------------------------------------------------------------------------------------------------------
-- Entry point
--------------------------------------------------------------------------------------------------------

function ns.InitUnitTooltip()
	TooltipDataProcessor.AddTooltipPreCall(Enum.TooltipDataType.Unit, PrepareUnitLines)
	TooltipDataProcessor.AddLinePreCall(Enum.TooltipDataLineType.None, IsUnwantedLine)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)

	hooksecurefunc("UnitFrame_UpdateTooltip", HideRightClickText)

	ns:ContinueOnAddOnLoaded("Blizzard_Communities", InitCommunitiesHook)
end
