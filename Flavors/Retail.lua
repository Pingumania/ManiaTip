local _, ns = ...

ns.RetailModule = {}
local Retail = ns.RetailModule

--------------------------------------------------------------------------------------------------------
-- Health bar text
--------------------------------------------------------------------------------------------------------

function Retail.GetHealthBarText(unit)
	return ("%d%%"):format(UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
end

--------------------------------------------------------------------------------------------------------
-- Faction/PvP text hiding
--------------------------------------------------------------------------------------------------------

local FactionNames = {}
local function BuildFactionNames()
	for factionID = 1, 9999 do
		local factionData = C_Reputation.GetFactionDataByID(factionID)
		if factionData and factionData.name then
			FactionNames[factionData.name] = true
		end
	end
end

local function PlainText(value)
	if issecretvalue(value) then
		return nil
	end

	return value
end

local function RemoveUnwantedLines(data, unit)
	-- hideSubFactionText ("Hide the faction of an NPC") matches against every registered faction
	-- name, which includes Alliance/Horde themselves - only apply it to NPCs, not players
	local isNPC = not UnitIsPlayer(unit)
	for i, lineData in ipairs(data.lines) do
		local text = PlainText(lineData.leftText)
		local lineIndex = lineData.lineIndex or i
		if text then
			if ns.Config.hideFactionText and (text == FACTION_ALLIANCE or text == FACTION_HORDE) then
				_G["GameTooltipTextLeft"..lineIndex]:SetText("")
			elseif ns.Config.hidePvpText and text == PVP_ENABLED then
				_G["GameTooltipTextLeft"..lineIndex]:SetText("")
			elseif isNPC and ns.Config.hideSubFactionText and FactionNames[text] then
				_G["GameTooltipTextLeft"..lineIndex]:SetText("")
			end
		end
	end
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

local levelLineType = Enum.TooltipDataLineType.UnitLevel

local function FindLevelLineFromData(data)
	for i, lineData in ipairs(data.lines) do
		if levelLineType and lineData.type == levelLineType then
			return lineData.lineIndex or i
		end

		local text = PlainText(lineData.leftText)
		if text and strfind(text, "^"..LEVEL.." [%d%?]+") then
			return lineData.lineIndex or i
		end
	end

	return false
end

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

local function OnTooltipSetUnit(tip, data)
	if tip ~= GameTooltip or not data then
		return
	end

	ns.activeUnit = {}

	local unit = GetTooltipUnit(tip)
	if not unit then
		tip:Hide()
		return
	end

	RemoveUnwantedLines(data, unit)

	local _, classID = UnitClassFromGUID(data.guid)
	local fullName = FindNameFromData(data) or UnitName(unit)

	local _, isPlayer, levelText = ns.ApplyUnitTooltip(tip, unit, classID, fullName)

	local levelLine = FindLevelLineFromData(data)
	if levelLine then
		_G["GameTooltipTextLeft"..levelLine]:SetText(levelText)

		if isPlayer then
			local specLine = _G["GameTooltipTextLeft"..(levelLine + 1)]
			local text = specLine and specLine:GetText()
			if text then
				specLine:SetFormattedText("%s%s|r", C_ClassColor.GetClassColor(classID):GenerateHexColorMarkup(), text)
			end
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
		for i = 2, GameTooltip:NumLines() do
			local line = _G["GameTooltipTextLeft"..i]
			if line:GetText() == plainText then
				line:SetFormattedText("%s %s %s", levelColor..info.level.."|r", raceInfo.raceName, ns.ClassColorMarkup[classInfo.classFile]..classInfo.className)
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
	ScrollUtil.AddAcquiredFrameCallback(CommunitiesFrame.MemberList.ScrollBox, function(_, frame)
		if not hooked[frame] then
			frame:HookScript("OnEnter", MemberList_OnEnter)
			frame:HookScript("OnLeave", MemberList_OnLeave)
			hooked[frame] = true
		end
	end, nil, true)
end

--------------------------------------------------------------------------------------------------------
-- Entry point
--------------------------------------------------------------------------------------------------------

function Retail.Init()
	BuildFactionNames()

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ns.OnTooltipSetItem)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, ns.OnTooltipSetSpell)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, ns.OnTooltipSetUnitAura)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Toy, ns.OnTooltipSetToy)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Macro, ns.OnTooltipSetMacro)

	ns:ContinueOnAddOnLoaded("Blizzard_Communities", InitCommunitiesHook)
end
