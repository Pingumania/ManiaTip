local ADDON_NAME, ns = ...

local L = ns.L
local mt = CreateFrame("Frame")

local function ColorGetter(info)
	local color = ns.cfg[info[#info]]
	return color[1], color[2], color[3], color[4] or 1
end

local function ColorSetter(info, r, g, b, a)
	ns.cfg[info[#info]] = {r, g, b, a or 1}
end

local function ColorOption(order, name, width, hasAlpha)
	return {
		order = order,
		name = name,
		type = "color",
		width = width,
		hasAlpha = hasAlpha,
		get = ColorGetter,
		set = ColorSetter,
	}
end

local function CreateConfig()
	local fonts = LibStub("LibSharedMedia-3.0"):List("font")
	local statusbars = LibStub("LibSharedMedia-3.0"):List("statusbar")

	LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, {
		type = "group",
		name = ADDON_NAME,
		get = function(info)
			return ns.cfg[info[#info]]
		end,
		set = function(info, value)
			ns.cfg[info[#info]] = value
		end,
		args = {
			showPlayerTitle = {
				order = 10,
				name = L["showPlayerTitle"],
				type = "toggle",
				width = 1.75,
			},
			hidePvpText = {
				order = 11,
				name = L["hidePvpText"],
				type = "toggle",
				width = 1.75,
			},
			showRealm = {
				order = 12,
				name = L["showRealm"],
				type = "toggle",
				width = 1.75,
			},
			hideFactionText = {
				order = 13,
				name = L["hideFactionText"],
				type = "toggle",
				width = 1.75,
			},
			showTarget = {
				order = 14,
				name = L["showTarget"],
				type = "toggle",
				width = 1.75,
			},
			hideSubFactionText = {
				order = 15,
				name = L["hideSubFactionText"],
				type = "toggle",
				width = 1.75,
			},
			showId = {
				order = 16,
				name = L["showId"],
				type = "toggle",
				width = "full",
			},
			tipScale = {
				order = 17,
				name = L["tipScale"],
				type = "range",
				max = 2,
				min = 0.5,
				step = .05,
				set = function(info, value)
					ns.cfg[info[#info]] = value
					ns.UpdateTooltipScale()
				end,
			},
			header1 = {
				order = 20,
				type = "header",
				name = L["colorSettings"],
			},
			descTooltipColors = {
				order = 21,
				type = "description",
				name = NORMAL_FONT_COLOR:WrapTextInColorCode(L["descTooltipColors"]),
			},
			tipColor = ColorOption(22, L["tipColor"], 1.10, true),
			tipBorderColor = ColorOption(23, L["tipBorderColor"], 1.10, true),
			descReactionColors = {
				order = 24,
				type = "description",
				name = NORMAL_FONT_COLOR:WrapTextInColorCode(L["descReactionColors"]),
			},
			colReact1 = ColorOption(25, L["colReact1"], 1.10),
			colReact2 = ColorOption(26, L["colReact2"], 1.10),
			colReact3 = ColorOption(27, L["colReact3"], 1.10),
			colReact4 = ColorOption(28, L["colReact4"], 1.10),
			colReact5 = ColorOption(29, L["colReact5"], 1.10),
			colReact6 = ColorOption(30, L["colReact6"], 1.10),
			colReact7 = ColorOption(31, L["colReact7"], 1.10),
			descInfoColors = {
				order = 32,
				type = "description",
				name = NORMAL_FONT_COLOR:WrapTextInColorCode(L["descInfoColors"]),
			},
			infoColor1 = ColorOption(33, L["infoColor1"], 1.10),
			infoColor2 = ColorOption(34, L["infoColor2"], 1.10),
			infoColorSpacer = {
				order = 35,
				type = "description",
				name = "",
			},
			colGuild = ColorOption(36, L["colGuild"], 1.10),
			colSameGuild = ColorOption(37, L["colSameGuild"], 1.10),
			resetColors = {
				order = 38,
				name = L["resetColors"],
				type = "execute",
				func = function()
					for _, key in ipairs({
						"tipColor", "tipBorderColor",
						"colReact1", "colReact2", "colReact3", "colReact4", "colReact5", "colReact6", "colReact7",
						"infoColor1", "infoColor2",
						"colGuild", "colSameGuild",
					}) do
						ns.cfg[key] = ns.defaults[key]
					end
				end,
			},
			header2 = {
				order = 40,
				type = "header",
				name = L["fontSettings"],
			},
			textFontFace = {
				order = 41,
				name = L["textFontFace"],
				type = "select",
				width = 1.5,
				values = fonts,
				get = function()
					for i, v in next, fonts do
						if v == ns.cfg.textFontFace then return i end
					end
				end,
				set = function(_, value)
					ns.cfg.textFontFace = fonts[value]
					ns.UpdateGameTooltipFont()
				end,
				itemControl = "DDI-Font",
			},
			spacer1 = {
				order = 42,
				type = "description",
				name = "",
				width = 0.1,
			},
			textFontSize = {
				order = 43,
				name = L["textFontSize"],
				type = "range",
				max = 26,
				min = 1,
				step = 1,
				set = function(info, value)
					ns.cfg[info[#info]] = value
					ns.UpdateGameTooltipFont()
				end,
			},
			spacer2 = {
				order = 44,
				type = "description",
				name = "",
				width = 0.1,
			},
			textFontFlags = {
				order = 45,
				name = L["textFontFlags"],
				type = "select",
				width = 0.6,
				values = { NONE = L["none"], OUTLINE = L["thin"], THICKOUTLINE = L["thick"] },
				set = function(info, value)
					ns.cfg[info[#info]] = value
					ns.UpdateGameTooltipFont()
				end,
			},
			spacer3 = {
				order = 52,
				type = "description",
				name = "",
			},
			header3 = {
				order = 60,
				type = "header",
				name = L["healthBarSettings"],
			},
			showBar = {
				order = 61,
				name = L["showBar"],
				type = "toggle",
				width = "full",
				set = function(info, value)
					ns.cfg[info[#info]] = value
					ns.UpdateGameTooltipStatusBarVisibility()
				end,
			},
			barTexture = {
				order = 62,
				name = L["barTexture"],
				type = "select",
				width = 1.5,
				values = statusbars,
				disabled = function() return not ns.cfg.showBar end,
				get = function()
					for i, v in next, statusbars do
						if v == ns.cfg.barTexture then return i end
					end
				end,
				set = function(_, value)
					ns.cfg.barTexture = statusbars[value]
					ns.UpdateGameTooltipStatusBarTexture()
				end,
				itemControl = "DDI-Statusbar",
			},
			spacer4 = {
				order = 63,
				type = "description",
				name = " ",
				width = "full",
			},
			showBarValues = {
				order = 64,
				name = L["showBarValues"],
				type = "toggle",
				width = "full",
				disabled = function() return not ns.cfg.showBar end,
				set = function(info, value)
					ns.cfg[info[#info]] = value
					ns.UpdateGameTooltipStatusBarVisibility()
				end,
			},
			barFontFace = {
				order = 65,
				name = L["barFontFace"],
				type = "select",
				width = 1.5,
				values = fonts,
				disabled = function() return not ns.cfg.showBar end,
				get = function()
					for i, v in next, fonts do
						if v == ns.cfg.barFontFace then return i end
					end
				end,
				set = function(_, value)
					ns.cfg.barFontFace = fonts[value]
					ns.UpdateGameTooltipStatusBarText()
				end,
				itemControl = "DDI-Font",
			},
			spacer5 = {
				order = 66,
				type = "description",
				name = "",
				width = 0.1,
			},
			barFontSize = {
				order = 67,
				name = L["barFontSize"],
				type = "range",
				max = 26,
				min = 1,
				step = 1,
				disabled = function() return not ns.cfg.showBar end,
				set = function(info, value)
					ns.cfg[info[#info]] = value
					ns.UpdateGameTooltipStatusBarText()
				end,
			},
			barFontFlags = {
				order = 69,
				name = L["barFontFlags"],
				type = "select",
				width = 0.6,
				values = { NONE = L["none"], OUTLINE = L["thin"], THICKOUTLINE = L["thick"] },
				disabled = function() return not ns.cfg.showBar end,
				set = function(info, value)
					ns.cfg[info[#info]] = value
					ns.UpdateGameTooltipStatusBarText()
				end,
			},
		},
	})

	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME)
end

function mt:ADDON_LOADED(event, addon)
	if addon == ADDON_NAME then
		CreateConfig()
	end
end

mt:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
mt:RegisterEvent("ADDON_LOADED")
