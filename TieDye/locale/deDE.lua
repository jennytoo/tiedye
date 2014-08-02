--Localization.deDE.lua
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("TieDye", "deDE")
if not L then return end
L["Locale"] = "deDE"

-- Thank you to my coworker TB for the translations
L["SORT_ID"] = "Nach ID sortieren"
L["SORT_NAME"] = "Nach Name sortieren"
L["SORT_QUALITY"] = "Nach Qualit�t sortieren"
L["SHOW_KNOWN_ONLY"] = "Nur bekannte F�rbungen zeigen"
L["GROUP_BY_COLLECTION"] = "F�rbungen nach Sammlung gruppieren"
L["VIEW_GRID"] = "Gitteransicht"
L["VIEW_LIST"] = "Listenansicht"
L["SEARCH_COLOR"] = "Anhand Farbton suchen"
L["SEARCH_QUALITY"] = "Qualit�t suchen"
L["NO_INFO"] = "Keine Angaben vorhanden"
L["LOCKED"] = "Noch unbekannt" -- Still Unknown
L["DYE_LEARNED"] = "Benutzung von %s erlernt"
