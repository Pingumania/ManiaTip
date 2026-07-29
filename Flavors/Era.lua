local ADDON_NAME, ns = ...

ns.EraModule = {}
local Era = ns.EraModule

--------------------------------------------------------------------------------------------------------
-- Health bar text
--------------------------------------------------------------------------------------------------------

function Era.GetHealthBarText(unit)
	return ("%s / %s"):format(BreakUpLargeNumbers(UnitHealth(unit)), BreakUpLargeNumbers(UnitHealthMax(unit)))
end

--------------------------------------------------------------------------------------------------------
-- Faction/PvP text hiding
--------------------------------------------------------------------------------------------------------

local FactionNames = {}
local function BuildFactionNames()
	for factionID = 1, 9999 do
		local name = GetFactionInfoByID(factionID)
		if name then
			FactionNames[name] = true
		end
	end
end

local function RemoveUnwantedLines(tip, unit)
	-- hideSubFactionText ("Hide the faction of an NPC") matches against every registered faction
	-- name, which includes Alliance/Horde themselves - only apply it to NPCs, not players
	local isNPC = not UnitIsPlayer(unit)
	for i = 2, tip:NumLines() do
		local line = _G["GameTooltipTextLeft"..i]
		local text = line:GetText()
		if ns.Config.hideFactionText and (text == FACTION_ALLIANCE or text == FACTION_HORDE) then
			line:SetText("")
		elseif ns.Config.hidePvpText and text == PVP_ENABLED then
			line:SetText("")
		elseif isNPC and ns.Config.hideSubFactionText and FactionNames[text] then
			line:SetText("")
		end
	end
end

--------------------------------------------------------------------------------------------------------
-- Draggable anchor frame
--------------------------------------------------------------------------------------------------------

local function CreateAnchor()
	local anchor = CreateFrame("Frame", ADDON_NAME.."Anchor", nil, "BackdropTemplate")
	anchor:SetSize(100, 20)
	anchor:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -300, 180)
	anchor:EnableMouse(true)
	ns:SetFrameMoveable(anchor)
	ns:CreateBackdrop(anchor)
	anchor:Hide()
end

function Era.SetCustomAnchorPoint(tip)
	local point = "BOTTOMLEFT"
	tip:SetPoint(point, ADDON_NAME.."Anchor", point)
end

--------------------------------------------------------------------------------------------------------
-- Unit tooltip
--------------------------------------------------------------------------------------------------------

local function GetUnitFromTooltip(tip)
	local _, unit = tip:GetUnit()
	return unit or "mouseover"
end

local function OnTooltipSetUnit(tip)
	if tip ~= GameTooltip then
		return
	end

	ns.activeUnit = {}

	local unit = GetUnitFromTooltip(tip)
	if not unit then
		tip:Hide()
		return
	end

	RemoveUnwantedLines(tip, unit)

	local _, classID = UnitClass(unit)
	local fullName = GameTooltipTextLeft1:GetText() or UnitName(unit)

	local _, _, levelText = ns.ApplyUnitTooltip(tip, unit, classID, fullName)

	local levelLine = ns.FindLevelLineByText(tip)
	if levelLine then
		_G["GameTooltipTextLeft"..levelLine]:SetText(levelText)
	end

	tip:Show()
end

--------------------------------------------------------------------------------------------------------
-- Aura tooltips
--------------------------------------------------------------------------------------------------------

local function SetUnitAura_Hook(tip, unit, index, filter)
	local spellId = select(10, UnitAura(unit, index, filter))
	if spellId then
		ns.AddIdLine(tip, spellId)
		tip:Show()
	end
end

--------------------------------------------------------------------------------------------------------
-- Entry point
--------------------------------------------------------------------------------------------------------

function Era.Init()
	BuildFactionNames()
	CreateAnchor()

	for _, tip in ipairs(ns.tooltips) do
		hooksecurefunc(tip, "SetUnitAura", SetUnitAura_Hook)
		hooksecurefunc(tip, "SetUnitBuff", SetUnitAura_Hook)
		hooksecurefunc(tip, "SetUnitDebuff", SetUnitAura_Hook)
		tip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
		tip:HookScript("OnTooltipSetItem", ns.OnTooltipSetItem)
		tip:HookScript("OnTooltipSetSpell", ns.OnTooltipSetSpell)
	end
end
