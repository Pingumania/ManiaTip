
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
			header1 = {
				order = 20,
				type = "header",
				name = L["colorSettings"],
			},
			tipColor = {
				order = 21,
				name = L["tipColor"],
				type = "color",
				get = function() return ns.cfg.tipColor:GetRGBA() end,
				set = function(_, r, g, b)
					ns.cfg.tipColor = ns.cfg.tipColor:SetRGBA(r, g, b, 1)
				end,
			},
			tipBorderColor = {
				order = 22,
				name = L["tipBorderColor"],
				type = "color",
				get = function() return ns.cfg.tipBorderColor:GetRGBA() end,
				set = function(_, r, g, b)
					ns.cfg.tipBorderColor = ns.cfg.tipBorderColor:SetRGBA(r, g, b, 1)
				end,
			},
			spacer1 = {
				order = 23,
				type = "description",
				name = "",
			},
			colReactBack1 = {
				order = 24,
				name = L["colReactBack1"],
				type = "color",
				get = function() return ns.cfg.colReactBack1:GetRGBA() end,
				set = function(_, r, g, b)
					ns.cfg.colReactBack1 = ns.cfg.colReactBack1:SetRGBA(r, g, b, 1)
				end,
				width = "full",
			},
			colReactBack2 = {
				order = 25,
				name = L["colReactBack2"],
				type = "color",
				get = function() return ns.cfg.colReactBack2:GetRGBA() end,
				set = function(_, r, g, b)
					ns.cfg.colReactBack2 = ns.cfg.colReactBack2:SetRGBA(r, g, b, 1)
				end,
				width = "full",
			},
			colReactBack3 = {
				order = 26,
				name = L["colReactBack3"],
				type = "color",
				get = function() return ns.cfg.colReactBack3:GetRGBA() end,
				set = function(_, r, g, b)
					ns.cfg.colReactBack3 = ns.cfg.colReactBack3:SetRGBA(r, g, b, 1)
				end,
				width = "full",
			},
			colReactBack4 = {
				order = 27,
				name = L["colReactBack4"],
				type = "color",
				get = function() return ns.cfg.colReactBack4:GetRGBA() end,
				set = function(_, r, g, b)
					ns.cfg.colReactBack4 = ns.cfg.colReactBack4:SetRGBA(r, g, b, 1)
				end,
				width = "full",
			},
			colReactBack5 = {
				order = 28,
				name = L["colReactBack5"],
				type = "color",
				get = function() return ns.cfg.colReactBack5:GetRGBA() end,
				set = function(_, r, g, b)
					ns.cfg.colReactBack5 = ns.cfg.colReactBack5:SetRGBA(r, g, b, 1)
				end,
				width = "full",
			},
			colReactBack6 = {
				order = 29,
				name = L["colReactBack6"],
				type = "color",
				get = function() return ns.cfg.colReactBack6:GetRGBA() end,
				set = function(_, r, g, b)
					ns.cfg.colReactBack6 = ns.cfg.colReactBack6:SetRGBA(r, g, b, 1)
				end,
				width = "full",
			},
			colReactBack7 = {
				order = 30,
				name = L["colReactBack7"],
				type = "color",
				get = function() return ns.cfg.colReactBack7:GetRGBA() end,
				set = function(_, r, g, b)
					ns.cfg.colReactBack7 = ns.cfg.colReactBack7:SetRGBA(r, g, b, 1)
				end,
				width = "full",
			},
			header2 = {
				order = 40,
				type = "header",
				name = L["healthBarSettings"],
			},
			barTexture = {
				order = 41,
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
			spacer2 = {
				order = 42,
				type = "description",
				name = "",
			},
			barFontFace = {
				order = 43,
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
			spacer3 = {
				order = 44,
				type = "description",
				name = "",
				width = 0.1,
			},
			barFontSize = {
				order = 45,
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
			spacer4 = {
				order = 46,
				type = "description",
				name = "",
				width = 0.1,
			},
			barFontFlags = {
				order = 47,
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

function mt:ADDON_LOADED(event, addon)
	if addon == ADDON_NAME then
		CreateConfig()
	end
end

mt:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
mt:RegisterEvent("ADDON_LOADED")