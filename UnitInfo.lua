local _, ns = ...

--------------------------------------------------------------------------------------------------------
-- Reaction color lookup
--------------------------------------------------------------------------------------------------------

local function ReactionColor(index)
	return CreateColor(unpack(ns.cfg["colReact"..index]))
end

local function GetUnitReactionColor(unit)
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

	if ns.cfg.showPlayerTitle then
		nameString = classMarkup..(realm and gsub(fullName, "-"..realm, "") or fullName)
	end

	if ns.cfg.showRealm then
		if ns.cfg.showSameRealm and not realm then
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

	local guild = GetGuildInfo(unit)
	if not guild then
		return nil
	end

	local sameGuild = guild == GetGuildInfo("player")
	local guildColor = ns.GenerateHexColorMarkup(sameGuild and ns.cfg.colSameGuild or ns.cfg.colGuild)
	return ("%s<%s>|r"):format(guildColor, guild)
end

-- Returns the formatted "Level NN Classification" line text.
local function BuildLevelDisplay(unit, isPlayer, classID)
	local isPet = (UnitIsWildBattlePet and UnitIsWildBattlePet(unit)) or (UnitIsBattlePetCompanion and UnitIsBattlePetCompanion(unit))
	local level = (isPet and UnitBattlePetLevel(unit)) or UnitLevel(unit) or -1
	-- level -1 is a boss regardless of what classification actually says.
	local classification = level == -1 and "worldboss" or (UnitClassification(unit) or "")

	local unitInfo
	if isPlayer then
		unitInfo = UnitRace(unit).." "
		if ns.Era then
			unitInfo = unitInfo..C_ClassColor.GetClassColor(classID):GenerateHexColorMarkup()..UnitClass(unit).."|r"
		end
	elseif ns.Era then
		unitInfo = (isPet and _G["BATTLE_PET_NAME_"..UnitBattlePetType(unit)]) or UnitCreatureFamily(unit) or UnitCreatureType(unit) or ""
	else
		unitInfo = ""
	end

	local levelColor = ns.GetDifficultyLevelColor(level ~= -1 and level or 500)
	local levelText = (ns.cfg["classification_"..classification] or "%s? "):format(level == -1 and "??" or level)
	return ("%s %s|r%s"):format(LEVEL, levelColor..levelText, unitInfo)
end

-- Returns the formatted "Target: ..." line text, or nil if the unit has no target or the feature is disabled.
local function BuildTargetDisplay(unit)
	if not ns.cfg.showTarget then
		return nil
	end

	local target = unit.."target"
	if not UnitExists(target) then
		return nil
	end

	local text = ns.GenerateHexColorMarkup(ns.cfg.targetColor)..BINDING_HEADER_TARGETING..": "
	if UnitIsUnit("player", target) then
		text = text..ns.COLOR_WARNING..ns.cfg.targetYouText.." |r"
	end

	if UnitIsPlayer(target) then
		local _, targetClassID = UnitClass(target)
		text = text..C_ClassColor.GetClassColor(targetClassID):GenerateHexColorMarkup()
	else
		text = text..GetUnitReactionColor(target):GenerateHexColorMarkup()
	end

	return text..UnitName(target)
end

-- Returns: color (for the health bar hook), isPlayer, formatted level line text.
function ns.ApplyUnitTooltip(tip, unit, classID, fullName)
	local isPlayer = UnitIsPlayer(unit)

	local color, nameString = BuildNameDisplay(unit, isPlayer, classID, fullName)
	tip.NineSlice:SetBorderColor(color:GetRGBA())
	GameTooltipStatusBar:SetStatusBarColor(color:GetRGBA())
	_G["GameTooltipTextLeft1"]:SetFormattedText("%s|r", nameString)

	local guildText = BuildGuildDisplay(unit, isPlayer)
	if guildText then
		if ns.Era then
			-- Era's line 2 isn't guaranteed to be blank/guild already;
			-- preserve whatever was there by pushing it down first.
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
