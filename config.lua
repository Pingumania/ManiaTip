
local ADDON_NAME, ns = ...

local L = ns.L
local mt = CreateFrame("Frame")

local function CreateConfig()
	local fonts = LibStub("LibSharedMedia-3.0"):List("font")
	local statusbars = LibStub("LibSharedMedia-3.0"):List("statusbar")

	local function ColorGetter(info)
		return ns.cfg[info][1], ns.cfg[info][2], ns.cfg[info][3], ns.cfg[info][4] or 1
	end

	local function ColorSetter(info, r, g, b, a)
		ns.cfg[info] = {r, g, b, a or 1}
	end

	LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, {
		type = "group",
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
			tipColor = {
				order = 22,
				name = L["tipColor"],
				type = "color",
				get = function(info) return ColorGetter(info[#info]) end,
				set = function(info, r,g,b,a) ColorSetter(info[#info], r, g, b, a) end,
				width = 1.10,
			},
			tipBorderColor = {
				order = 23,
				name = L["tipBorderColor"],
				type = "color",
				get = function(info) return ColorGetter(info[#info]) end,
				set = function(info, r,g,b,a) ColorSetter(info[#info], r, g, b, a) end,
				width = 1.10,
			},
			descReactionColors = {
				order = 24,
				type = "description",
				name = NORMAL_FONT_COLOR:WrapTextInColorCode(L["descReactionColors"]),
			},
			colReact1 = {
				order = 25,
				name = L["colReact1"],
				type = "color",
				get = function(info) return ColorGetter(info[#info]) end,
				set = function(info, r,g,b,a) ColorSetter(info[#info], r, g, b, a) end,
				width = 1.10,
			},
			colReact2 = {
				order = 26,
				name = L["colReact2"],
				type = "color",
				get = function(info) return ColorGetter(info[#info]) end,
				set = function(info, r,g,b,a) ColorSetter(info[#info], r, g, b, a) end,
				width = 1.10,
			},
			colReact3 = {
				order = 27,
				name = L["colReact3"],
				type = "color",
				get = function(info) return ColorGetter(info[#info]) end,
				set = function(info, r,g,b,a) ColorSetter(info[#info], r, g, b, a) end,
				width = 1.10,
			},
			colReact4 = {
				order = 28,
				name = L["colReact4"],
				type = "color",
				get = function(info) return ColorGetter(info[#info]) end,
				set = function(info, r,g,b,a) ColorSetter(info[#info], r, g, b, a) end,
				width = 1.10,
			},
			colReact5 = {
				order = 29,
				name = L["colReact5"],
				type = "color",
				get = function(info) return ColorGetter(info[#info]) end,
				set = function(info, r,g,b,a) ColorSetter(info[#info], r, g, b, a) end,
				width = 1.10,
			},
			colReact6 = {
				order = 30,
				name = L["colReact6"],
				type = "color",
				get = function(info) return ColorGetter(info[#info]) end,
				set = function(info, r,g,b,a) ColorSetter(info[#info], r, g, b, a) end,
				width = 1.10,
			},
			colReact7 = {
				order = 31,
				name = L["colReact7"],
				type = "color",
				get = function(info) return ColorGetter(info[#info]) end,
				set = function(info, r,g,b,a) ColorSetter(info[#info], r, g, b, a) end,
				width = 1.10,
			},
			descInfoColors = {
				order = 32,
				type = "description",
				name = NORMAL_FONT_COLOR:WrapTextInColorCode(L["descInfoColors"]),
			},
			infoColor1 = {
				order = 33,
				name = L["infoColor1"],
				type = "color",
				get = function(info) return ColorGetter(info[#info]) end,
				set = function(info, r,g,b,a) ColorSetter(info[#info], r, g, b, a) end,
				width = 1.10,
			},
			infoColor2 = {
				order = 34,
				name = L["infoColor2"],
				type = "color",
				get = function(info) return ColorGetter(info[#info]) end,
				set = function(info, r,g,b,a) ColorSetter(info[#info], r, g, b, a) end,
				width = 1.10,
			},
			infoColorSpacer = {
				order = 35,
				type = "description",
				name = "",
			},
			colGuild = {
				order = 36,
				name = L["colGuild"],
				type = "color",
				get = function(info) return ColorGetter(info[#info]) end,
				set = function(info, r,g,b,a) ColorSetter(info[#info], r, g, b, a) end,
				width = 1.10,
			},
			colSameGuild = {
				order = 37,
				name = L["colSameGuild"],
				type = "color",
				get = function(info) return ColorGetter(info[#info]) end,
				set = function(info, r,g,b,a) ColorSetter(info[#info], r, g, b, a) end,
				width = 1.10,
			},
			resetColors = {
				order = 38,
				name = L["resetColors"],
				type = "execute",
				func = function()
					ns.cfg.tipColor = ns.defaults.tipColor
					ns.cfg.tipBorderColor = ns.defaults.tipBorderColor
					ns.cfg.colReact1 = ns.defaults.colReact1
					ns.cfg.colReact2 = ns.defaults.colReact2
					ns.cfg.colReact3 = ns.defaults.colReact3
					ns.cfg.colReact4 = ns.defaults.colReact4
					ns.cfg.colReact5 = ns.defaults.colReact5
					ns.cfg.colReact6 = ns.defaults.colReact6
					ns.cfg.colReact7 = ns.defaults.colReact7
					ns.cfg.infoColor1 = ns.defaults.infoColor1
					ns.cfg.infoColor2 = ns.defaults.infoColor2
					ns.cfg.colGuild = ns.defaults.colGuild
					ns.cfg.colSameGuild = ns.defaults.colSameGuild
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
			showBarValues = {
				order = 61,
				name = L["showBarValues"],
				type = "toggle",
				width = "full",
				set = function(info, value)
					ns.cfg[info[#info]] = value
					ns.UpdateGameTooltipStatusBarValueVisibility()
				end,
			},
			barFontFace = {
				order = 62,
				name = L["barFontFace"],
				type = "select",
				width = 1.5,
				values = fonts,
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
			spacer4 = {
				order = 63,
				type = "description",
				name = "",
				width = 0.1,
			},
			barFontSize = {
				order = 64,
				name = L["barFontSize"],
				type = "range",
				max = 26,
				min = 1,
				step = 1,
				set = function(info, value)
					ns.cfg[info[#info]] = value
					ns.UpdateGameTooltipStatusBarText()
				end,
			},
			spacer5 = {
				order = 65,
				type = "description",
				name = "",
				width = 0.1,
			},
			barFontFlags = {
				order = 66,
				name = L["barFontFlags"],
				type = "select",
				width = 0.6,
				values = { NONE = L["none"], OUTLINE = L["thin"], THICKOUTLINE = L["thick"] },
				set = function(info, value)
					ns.cfg[info[#info]] = value
					ns.UpdateGameTooltipStatusBarText()
				end,
			},
			barTexture = {
				order = 67,
				name = L["barTexture"],
				type = "select",
				width = 1.5,
				values = statusbars,
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