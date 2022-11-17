
local ADDON_NAME, ns = ...

local L = ns.L
local mt = CreateFrame("Frame")

local function CreateConfig()
	local fonts = LibStub("LibSharedMedia-3.0"):List("font")
	local statusbars = LibStub("LibSharedMedia-3.0"):List("statusbar")

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
				width = "full",
			},
			showRealm = {
				order = 11,
				name = L["showRealm"],
				type = "toggle",
				width = "full",
			},
			targetYouText = {
				order = 12,
				name = L["targetYouText"],
				type = "input",
				width = 1.5
			},
			header1 = {
				order = 20,
				type = "header",
				name = L["colorSettings"],
			},
			tipColor = {
				order = 21,
				name = L["tipColor"],
				type = "color",
				get = function() return unpack(ns.cfg.tipColor) end,
				set = function(_, r, g, b)
					ns.cfg.tipColor = {r,g,b,1}
				end,
			},
			tipBorderColor = {
				order = 22,
				name = L["tipBorderColor"],
				type = "color",
				get = function() return unpack(ns.cfg.tipBorderColor) end,
				set = function(_, r, g, b)
					ns.cfg.tipBorderColor = {r,g,b,1}
				end,
			},
			header2 = {
				order = 30,
				type = "header",
				name = L["healthBarSettings"],
			},
			barTexture = {
				order = 31,
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
			spacer1 = {
				order = 32,
				type = "description",
				name = "",
			},
			barFontFace = {
				order = 33,
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
			spacer2 = {
				order = 34,
				type = "description",
				name = "",
				width = 0.1,
			},
			barFontSize = {
				order = 35,
				name = L["barFontSize"],
				type = "range",
				-- width = "half",
				max = 26,
				min = 1,
				step = 1,
				set = function(info, value)
					ns.cfg[info[#info]] = value
					ns.UpdateGameTooltipStatusBarText()
				end,
			},
			spacer3 = {
				order = 36,
				type = "description",
				name = "",
				width = 0.1,
			},
			barFontFlags = {
				order = 37,
				name = L["barFontFlags"],
				type = "select",
				width = 0.6,
				values = { NONE = L["None"], OUTLINE = L["Thin"], THICKOUTLINE = L["Thick"] },
				set = function(info, value)
					ns.cfg[info[#info]] = value
					ns.UpdateGameTooltipStatusBarText()
				end,
			},
		},
	})

	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME)
end

function mt:VARIABLES_LOADED()
	CreateConfig()
end

mt:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
mt:RegisterEvent("VARIABLES_LOADED")