local _, ns = ...

local L = ns.L

local FLAG_OPTIONS = {
	{ value = "NONE", label = L["none"] },
	{ value = "OUTLINE", label = L["thin"] },
	{ value = "THICKOUTLINE", label = L["thick"] },
}

local function CreateFontFaceRow(rowFrame)
	return ns:CreateMediaDropdown(rowFrame, "font", function()
		return ns.Config.textFontFace
	end, function(value)
		ns.Config.textFontFace = value
		ns.UpdateGameTooltipFont()
	end)
end

local function CreateBarPreviewRow(mediaType, key, updateFn)
	return function(rowFrame)
		return ns:CreateMediaDropdown(rowFrame, mediaType, function()
			return ns.Config[key]
		end, function(value)
			ns.Config[key] = value
			updateFn()
		end)
	end
end

local CreateBarTextureRow = CreateBarPreviewRow("statusbar", "barTexture", ns.UpdateGameTooltipStatusBarTexture)
local CreateBarFontFaceRow = CreateBarPreviewRow("font", "barFontFace", ns.UpdateGameTooltipStatusBarText)

local function CreateConfig()
	ns:RegisterOptionCallback("tipScale", function()
		ns.UpdateTooltipScale()
	end)
	ns:RegisterOptionCallback("textFontSize", ns.UpdateGameTooltipFont)
	ns:RegisterOptionCallback("textFontFlags", ns.UpdateGameTooltipFont)

	if not ns:IsRetail() then
		ns:RegisterOptionCallback("showBar", ns.UpdateGameTooltipStatusBarVisibility)
		ns:RegisterOptionCallback("showBarValues", ns.UpdateGameTooltipStatusBarVisibility)
		ns:RegisterOptionCallback("barFontSize", ns.UpdateGameTooltipStatusBarText)
		ns:RegisterOptionCallback("barFontFlags", ns.UpdateGameTooltipStatusBarText)
	end

	local settings = {
		{ key = "showPlayerTitle", type = "toggle", title = L["showPlayerTitle"], default = ns.defaults.showPlayerTitle },
		{ key = "hidePvpText", type = "toggle", title = L["hidePvpText"], default = ns.defaults.hidePvpText },
		{ key = "showRealm", type = "toggle", title = L["showRealm"], default = ns.defaults.showRealm },
		{ key = "hideFactionText", type = "toggle", title = L["hideFactionText"], default = ns.defaults.hideFactionText },
		{ key = "showTarget", type = "toggle", title = L["showTarget"], default = ns.defaults.showTarget },
		{ key = "hideSubFactionText", type = "toggle", title = L["hideSubFactionText"], default = ns.defaults.hideSubFactionText },
		{ key = "showId", type = "toggle", title = L["showId"], default = ns.defaults.showId },
		{ key = "tipScale", type = "slider", title = L["tipScale"], default = ns.defaults.tipScale, minValue = 0.5, maxValue = 2, valueStep = 0.05 },

		{ type = "header", title = L["fontSettings"] },
		{ type = "custom", title = L["textFontFace"], createControl = CreateFontFaceRow },
		{ key = "textFontSize", type = "slider", title = L["textFontSize"], default = ns.defaults.textFontSize, minValue = 1, maxValue = 26, valueStep = 1 },
		{ key = "textFontFlags", type = "menu", title = L["textFontFlags"], default = ns.defaults.textFontFlags, options = FLAG_OPTIONS },

		{ type = "header", title = L["healthBarSettings"] },
		{ key = "showBar", type = "toggle", title = L["showBar"], default = ns.defaults.showBar },
		{ type = "custom", title = L["barTexture"], requires = "showBar", createControl = CreateBarTextureRow },
	}

	-- retail hides a unit's health from addons, so there is nothing to put on the bar there
	if not ns:IsRetail() then
		tinsert(settings, { key = "showBarValues", type = "toggle", title = L["showBarValues"], default = ns.defaults.showBarValues, requires = "showBar" })
		tinsert(settings, { type = "custom", title = L["barFontFace"], requires = "showBar", createControl = CreateBarFontFaceRow })
		tinsert(settings, { key = "barFontSize", type = "slider", title = L["barFontSize"], default = ns.defaults.barFontSize, minValue = 1, maxValue = 26, valueStep = 1, requires = "showBar" })
		tinsert(settings, { key = "barFontFlags", type = "menu", title = L["barFontFlags"], default = ns.defaults.barFontFlags, requires = "showBar", options = FLAG_OPTIONS })
	end

	ns:RegisterSettings("ManiaTipDB", settings)

	ns:RegisterSubSettings("Colors", {
		{ type = "header", title = L["descTooltipColors"] },
		{ key = "tooltipColor", type = "color", title = L["tipColor"], default = ns.defaults.tooltipColor },
		{ key = "tooltipBorderColor", type = "color", title = L["tipBorderColor"], default = ns.defaults.tooltipBorderColor },

		{ type = "header", title = L["descReactionColors"] },
		{ key = "reactionColor1", type = "color", title = L["colReact1"], default = ns.defaults.reactionColor1 },
		{ key = "reactionColor2", type = "color", title = L["colReact2"], default = ns.defaults.reactionColor2 },
		{ key = "reactionColor3", type = "color", title = L["colReact3"], default = ns.defaults.reactionColor3 },
		{ key = "reactionColor4", type = "color", title = L["colReact4"], default = ns.defaults.reactionColor4 },
		{ key = "reactionColor5", type = "color", title = L["colReact5"], default = ns.defaults.reactionColor5 },
		{ key = "reactionColor6", type = "color", title = L["colReact6"], default = ns.defaults.reactionColor6 },
		{ key = "reactionColor7", type = "color", title = L["colReact7"], default = ns.defaults.reactionColor7 },

		{ type = "header", title = L["descInfoColors"] },
		{ key = "idLabelColor", type = "color", title = L["infoColor1"], default = ns.defaults.idLabelColor },
		{ key = "idColor", type = "color", title = L["infoColor2"], default = ns.defaults.idColor },

		{ key = "guildColor", type = "color", title = L["colGuild"], default = ns.defaults.guildColor },
		{ key = "sameGuildColor", type = "color", title = L["colSameGuild"], default = ns.defaults.sameGuildColor },
	})
end

CreateConfig()

ns:RegisterSettingsSlash("/maniatip")
