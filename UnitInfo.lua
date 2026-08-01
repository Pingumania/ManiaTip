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
	local nameString = classMarkup..name

	if ns.Config.showPlayerTitle then
		local titleName = fullName
		if realm and not (issecretvalue(fullName) or issecretvalue(realm)) then
			titleName = gsub(fullName, "-"..realm, "")
		end
		nameString = classMarkup..titleName
	end

	if ns.Config.showRealm then
		if ns.Config.showSameRealm and not realm then
			realm = GetRealmName()
		end
		nameString = nameString..(realm and "-"..realm or "")
	end

	local status = (not UnitIsConnected(unit) and " <DC>") or (UnitIsAFK(unit) and " <AFK>") or (UnitIsDND(unit) and " <DND>")
	if status then
		nameString = nameString..ns.COLOR_WHITE..status
	end

	return color, nameString
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
	return ("%s<%s>|r"):format(guildColorMarkup, guild)
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
		if ns:IsClassicEra() then
			unitInfo = unitInfo..C_ClassColor.GetClassColor(classID):GenerateHexColorMarkup()..UnitClass(unit).."|r"
		end
	elseif ns:IsClassicEra() then
		unitInfo = (isPet and _G["BATTLE_PET_NAME_"..UnitBattlePetType(unit)]) or UnitCreatureFamily(unit) or UnitCreatureType(unit) or ""
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
		text = text..C_ClassColor.GetClassColor(targetClassID):GenerateHexColorMarkup()
	else
		text = text..GetUnitReactionColor(target):GenerateHexColorMarkup()
	end

	return text..UnitName(target)
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
		if ns:IsClassicEra() then
			tip:AddLine(GameTooltipTextLeft2:GetText(), 1, 1, 1)
		end
		GameTooltipTextLeft2:SetFormattedText("%s", guildText)
	end

	local targetText = BuildTargetDisplay(unit)
	if targetText then
		ns.AddEmptyTrailingLine(tip):SetText(targetText)
	end

	ns.activeUnit.token = unit
	ns.activeUnit.color = color

	return color, isPlayer, BuildLevelDisplay(unit, isPlayer, classID)
end
