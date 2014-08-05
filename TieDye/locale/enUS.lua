--Localization.enUS.lua
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("TieDye", "enUS", true)
if not L then return end
L["Locale"] = "enUS"

L["SORT_ID"] = "Sort by ID"
L["SORT_NAME"] = "Sort by name"
L["SORT_QUALITY"] = "Sort by quality"
L["SHOW_KNOWN_ONLY"] = "Show known dyes only"
L["GROUP_BY_COLLECTION"] = "Group dyes by collection"
L["VIEW_GRID"] = "Grid view"
L["VIEW_LIST"] = "List view"
L["SEARCH_COLOR"] = "Search by color"
L["SEARCH_QUALITY"] = "Search by quality"
L["NO_INFO"] = "No information available"
L["LOCKED"] = "Dye not learned yet"
L["DYE_LEARNED"] = "TieDye: Learned how to use %s"
L["TIEDYE_ENABLED"] = "TieDye enabled. Use /tiedye to disable."
L["TIEDYE_DISABLED"] = "TieDye disabled. Use /tiedye to enable."
L["ONE_DYE_KNOWN"] = "TieDye: 1 dye known"
L["DYES_KNOWN"] = "TieDye: %d dyes known"
L["DYE_DATA_FILE"] = "Dyes.lua"
