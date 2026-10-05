local _, ns = ...

local L = ns.L

local FLAG_OPTIONS = {
	{ value = "NONE", label = L["none"] },
	{ value = "OUTLINE", label = L["thin"] },
	{ value = "THICKOUTLINE", label = L["thick"] },
}

local BORDER_OPTIONS = {
	{ value = "blizzard", label = L["border_blizzard"] },
	{ value = "chatBubble", label = L["border_chatBubble"] },
}

local STATUS_STYLE_OPTIONS = {
	{ value = "icon", label = L["statusTagIcon"] },
	{ value = "text", label = L["statusTagText"] },
	{ value = "tab", label = L["statusTagTab"] },
}

local STATUS_POSITION_OPTIONS = {
	{ value = "before", label = L["statusTagBefore"] },
	{ value = "after", label = L["statusTagAfter"] },
}

local TAB_POSITION_OPTIONS = {
	{ value = "TOPLEFT", label = L["tabTopLeft"] },
	{ value = "TOPRIGHT", label = L["tabTopRight"] },
	{ value = "RIGHTTOP", label = L["tabRightTop"] },
	{ value = "RIGHTBOTTOM", label = L["tabRightBottom"] },
	{ value = "LEFTTOP", label = L["tabLeftTop"] },
	{ value = "LEFTBOTTOM", label = L["tabLeftBottom"] },
}

local function StatusTextRow(key)
	local toggleKey = ns.STATUS_TEXT_TOGGLES[key]
	return { key = key, type = "input", title = L[key], default = ns.defaults[key], toggleKey = toggleKey, toggleDefault = ns.defaults[toggleKey], gatedBy = "statusTagStyle", requiresValue = "text" }
end

local function ColorEntry(key, title, hasOpacity)
	return { key = key, title = title, default = ns.defaults[key], hasOpacity = hasOpacity }
end

local function CreateConfig()
	ns:RegisterOptionCallback("tipScale", ns.UpdateTooltipScale)
	ns:RegisterOptionCallback("textFontFace", ns.UpdateGameTooltipFont)
	ns:RegisterOptionCallback("textFontSize", ns.UpdateGameTooltipFont)
	ns:RegisterOptionCallback("textFontFlags", ns.UpdateGameTooltipFont)
	ns:RegisterOptionCallback("textFontSmooth", ns.UpdateGameTooltipFont)
	ns:RegisterOptionCallback("textFontShadow", ns.UpdateGameTooltipFont)
	ns:RegisterOptionCallback("barTexture", ns.UpdateGameTooltipStatusBarTexture)
	ns:RegisterOptionCallback("tooltipBorder", ns.UpdateTooltipBorders)
	ns:RegisterOptionCallback("statusTabPosition", ns.AnchorStatusTabs)
	for _, key in ipairs({ "statusColors", "statusColorOffline", "statusColorAFK", "statusColorDND" }) do
		ns:RegisterOptionCallback(key, ns.UpdateStatusColors)
	end
	for key, toggleKey in next, ns.STATUS_TEXT_TOGGLES do
		ns:RegisterOptionCallback(key, ns.UpdateStatusTexts)
		ns:RegisterOptionCallback(toggleKey, ns.UpdateStatusTexts)
	end

	ns:RegisterSettings("ManiaTipDB", {
		{ type = "header", title = L["headerName"] },
		{ key = "showPlayerTitle", type = "toggle", title = L["showPlayerTitle"], default = ns.defaults.showPlayerTitle },
		{ key = "showRealm", type = "toggle", title = L["showRealm"], default = ns.defaults.showRealm, hidden = ns:IsForever() },
		{ key = "showSameRealm", type = "toggle", title = L["showSameRealm"], default = ns.defaults.showSameRealm, requires = "showRealm", hidden = ns:IsForever() },
		{ key = "transliterateNames", type = "toggle", title = L["transliterateNames"], default = ns.defaults.transliterateNames, hidden = not (C_Intl and C_Intl.Transliterate) },

		{ type = "header", title = L["headerLines"] },
		{ key = "showTarget", type = "toggle", title = L["showTarget"], default = ns.defaults.showTarget },
		{ key = "classColorText", type = "toggle", title = L["classColorText"], default = ns.defaults.classColorText },
		{ key = "hidePvpText", type = "toggle", title = L["hidePvpText"], default = ns.defaults.hidePvpText },
		{ key = "hideFactionText", type = "toggle", title = L["hideFactionText"], default = ns.defaults.hideFactionText },
		{ key = "hideRightClickText", type = "toggle", title = L["hideRightClickText"], default = ns.defaults.hideRightClickText },

		{ type = "header", title = L["headerStatusTags"], tooltip = L["statusTagsDesc"] },
		{ key = "statusTagStyle", type = "menu", title = L["statusTagStyle"], default = ns.defaults.statusTagStyle, options = STATUS_STYLE_OPTIONS },
		{ key = "statusTagPosition", type = "menu", title = L["statusTagPosition"], default = ns.defaults.statusTagPosition, options = STATUS_POSITION_OPTIONS, gatedBy = "statusTagStyle", requiresValue = { "icon", "text" } },
		{ key = "statusTabPosition", type = "menu", title = L["statusTabPosition"], default = ns.defaults.statusTabPosition, options = TAB_POSITION_OPTIONS, gatedBy = "statusTagStyle", requiresValue = "tab" },
		{ key = "statusColors", type = "toggle", title = L["statusColors"], default = ns.defaults.statusColors, gatedBy = "statusTagStyle", requiresValue = { "text", "tab" } },
		{ type = "colors", title = L["rowColors"], requires = "statusColors", settings = {
			ColorEntry("statusColorOffline", L["statusOffline"]),
			ColorEntry("statusColorAFK", L["statusAFK"]),
			ColorEntry("statusColorDND", L["statusDND"]),
		} },
		StatusTextRow("statusTextPrefix"),
		StatusTextRow("statusTextSuffix"),

		{ type = "header", title = L["headerIds"] },
		{ key = "showId", type = "toggle", title = L["showId"], default = ns.defaults.showId },
		{ type = "colors", title = L["rowColors"], requires = "showId", settings = {
			ColorEntry("idLabelColor", L["idLabelColor"]),
			ColorEntry("idColor", L["idColor"]),
		} },

		{ type = "header", title = L["headerFrame"] },
		{ key = "tooltipBorder", type = "menu", title = L["tooltipBorder"], default = ns.defaults.tooltipBorder, options = BORDER_OPTIONS },
		{ key = "tipScale", type = "slider", title = L["tipScale"], default = ns.defaults.tipScale, minValue = 0.5, maxValue = 2, valueStep = 0.05, valueFormat = "%.2f" },
		{ type = "colors", title = L["rowColors"], settings = {
			ColorEntry("tooltipColor", L["tipColor"], true),
			ColorEntry("tooltipBorderColor", L["tipBorderColor"]),
		} },

		{ type = "header", title = L["fontSettings"] },
		{ key = "textFontFace", type = "media", mediaType = "font", title = L["textFontFace"], default = ns.defaults.textFontFace },
		{ key = "textFontSize", type = "slider", title = L["textFontSize"], default = ns.defaults.textFontSize, minValue = 1, maxValue = 26, valueStep = 1 },
		{ key = "textFontFlags", type = "menu", title = L["textFontFlags"], default = ns.defaults.textFontFlags, options = FLAG_OPTIONS },
		{ key = "textFontShadow", type = "toggle", title = L["textFontShadow"], default = ns.defaults.textFontShadow },
		{ key = "textFontSmooth", type = "toggle", title = L["textFontSmooth"], default = ns.defaults.textFontSmooth },

		{ type = "header", title = L["healthBarSettings"] },
		{ key = "showBar", type = "toggle", title = L["showBar"], default = ns.defaults.showBar },
		{ key = "barTexture", type = "media", mediaType = "statusbar", title = L["barTexture"], default = ns.defaults.barTexture, requires = "showBar" },

		{ type = "header", title = L["headerUnitColors"], tooltip = L["unitColorsDesc"] },
		{ type = "colors", title = L["rowReaction"], settings = {
			ColorEntry("reactionColor2", L["colReact2"]),
			ColorEntry("reactionColor3", L["colReact3"]),
			ColorEntry("reactionColor4", L["colReact4"]),
		} },
		{ type = "colors", title = L["rowAllies"], settings = {
			ColorEntry("reactionColor5", L["colReact5"]),
			ColorEntry("reactionColor6", L["colReact6"]),
		} },
		{ type = "colors", title = L["rowOther"], settings = {
			ColorEntry("reactionColor1", L["colReact1"]),
			ColorEntry("reactionColor7", L["colReact7"]),
		} },
		{ type = "colors", title = L["rowGuild"], settings = {
			ColorEntry("guildColor", L["colGuild"]),
			ColorEntry("sameGuildColor", L["colSameGuild"]),
		} },
	})
end

CreateConfig()

ns:RegisterSettingsSlash("/maniatip")
