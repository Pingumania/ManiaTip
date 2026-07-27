local _, ns = ...

local locale = GetLocale()
local localizations = {}

ns.L = setmetatable({}, {
	__index = function(_, key)
		local value = localizations[locale] and localizations[locale][key]
		if value then return value end
		return localizations.enUS and localizations.enUS[key] or key
	end,
	__call = function(_, forLocale)
		localizations[forLocale] = localizations[forLocale] or {}
		return localizations[forLocale]
	end,
})
