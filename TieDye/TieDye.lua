-----------------------------------------------------------------------------------------------
-- Client Lua Script for TieDye
-----------------------------------------------------------------------------------------------

require "Apollo"
require "ChatSystemLib"
require "GameLib"
require "Window"

-----------------------------------------------------------------------------------------------
-- TieDye Module Definition
-----------------------------------------------------------------------------------------------
local TieDye = {}
TieDyeData = {}

local carbineCostumes, L
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local CodeEnumOrderBy = {
  NAME = 'NAME',
  RAMP = 'RAMP',
  COST = 'COST'
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function TieDye:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- Default option values
    self.SortOrder = CodeEnumOrderBy.NAME
    self.ShortList = true
    self.KnownOnly = true
    self.FilterText = ""
    self.ColorGradientVisible = false
    self.FilterHue = 180

    -- Internal only
    self.SortedDyes = {}
    self.KnownDyesById = {}
    self.KnownDyesByRamp = {}
    self.KnownDyes = 0
    self.MouseButtonPressed = false

    -- Track all seen dyes here
    self.tDyeInfo = {}

    return o
end

function TieDye:Init()
  local bHasConfigureFunction = false
  local strConfigureButtonText = ""
  local tDependencies = {
    "Costumes",
    "Gemini:Hook-1.0",
    "Gemini:Locale-1.0"
  }
  Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

-----------------------------------------------------------------------------------------------
-- TieDye OnLoad
-----------------------------------------------------------------------------------------------
function TieDye:OnLoad()
  Apollo.GetPackage("Gemini:Hook-1.0").tPackage:Embed(self)
  L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("TieDye", false)
  carbineCostumes = Apollo.GetAddon("Costumes")

  -- Load our form file
  self.xmlDoc = XmlDoc.CreateFromFile("TieDye.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
  Apollo.LoadSprites("TieDye_Sprites.xml")
  self:LoadDyes()
end

-----------------------------------------------------------------------------------------------
-- TieDye OnDocLoaded
-----------------------------------------------------------------------------------------------
function TieDye:OnDocLoaded()

  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
    Apollo.RegisterSlashCommand("tiedye", "OnTieDyeCommand", self)

    self:AddHooks()

    if Apollo.GetAddon("Rover") then
      SendVarToRover("TieDye", self)
    end
  end
end

-----------------------------------------------------------------------------------------------
-- Load / Save
-----------------------------------------------------------------------------------------------

function TieDye:SaveAccount()
  -- Account-level values (window state)
  local tSave = {}
  tSave.Version = 3
  tSave.SortOrder = self.SortOrder
  tSave.DetailView = not self.ShortList
  tSave.KnownOnly = self.KnownOnly
  tSave.FilterHue = self.FilterHue
  tSave.ColorGradientVisible = self.ColorGradientVisible

  return tSave
end

function TieDye:SaveGeneral()
  -- General values (all encountered dyes)
  local now = os.time()
  local max_age = now - (86400 * 14)
  local tSave = {
    Version = 1,
    Locale = { [L["Locale"]] = {} },
  }

  -- Copy over records (but not if too old)
  if self.tDyeInfo.Locale ~= nil then
    for locale, dyes in pairs(self.tDyeInfo.Locale) do
      local newDyes = {}
      for nId, tDyeInfo in pairs(dyes) do
        if tDyeInfo.lastSeen > max_age then
          newDyes[nId] = tDyeInfo
        end
      end
      tSave.Locale[locale] = newDyes
    end
  end

  for nId, tDyeInfo in pairs(self.KnownDyesById) do
    tDyeInfo.lastSeen = now
    tSave.Locale[L["Locale"]][nId] = tDyeInfo
  end

  return tSave
end

function TieDye:OnSave(eLevel)
  if eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
    return self:SaveAccount()
  elseif eLevel == GameLib.CodeEnumAddonSaveLevel.General then
    return self:SaveGeneral()
  end

  return nil
end

function TieDye:OnRestore(eLevel, tData)
  if eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
    self.ShortList = tData.DetailView == false
    self.KnownOnly = tData.KnownOnly == true
    self.ColorGradientVisible = tData.ColorGradientVisible == true

    if tData.Version > 1 and tData.FilterHue >= 0 and tData.FilterHue < 360 then
      self.FilterHue = tData.FilterHue
    end

    if tData.Version <= 2 then
      self.SortOrder = (tData.OrderByName == true) and CodeEnumOrderBy.NAME or CodeEnumOrderBy.RAMP
    else
      self.SortOrder = CodeEnumOrderBy[tData.SortOrder] or CodeEnumOrderBy.RAMP
    end
  elseif eLevel == GameLib.CodeEnumAddonSaveLevel.General then
    if tData.Version == 1 then
      self.tDyeInfo = tData
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Setup our hooks and windows
---------------------------------------------------------------------------------------------------
-- It might not really matter for how lua is being used, but order of operations is important to
-- ensure that the state is as expected. This means we don't enable our hook until our windows are
-- ready and we don't muck around in Costume's stuff until we've removed their hook, and vice-versa

function TieDye:AddHooks()
  if self.carbineWndDyeList then
    return
  end

  -- Hide Costume's Dye List window but keep it around so we can restore it if we remove our hook
  self.carbineWndDyeList = carbineCostumes.wndDyeList
  self.carbineWndDyeList:Show(false)

  -- Add our own container window
  local carbineDyeContainer = carbineCostumes.wndDyeList:GetParent()
  self.wndTieDyeContainer = Apollo.LoadForm(self.xmlDoc, "TieDyeContainer", carbineDyeContainer, self)
  self.wndControls = self.wndTieDyeContainer:FindChild("DyeControlBackground")
  self.wndGradient = self.wndControls:FindChild("Gradient")
  self.wndDyeList = self.wndTieDyeContainer:FindChild("DyeList")
  carbineCostumes.wndDyeList = self.wndDyeList

  -- Hook in our handlers
  self:RawHook(Apollo.GetAddon("Costumes"), "FillDyes")
  self:Hook(Apollo.GetAddon("Costumes"), "Reset")

  -- Clear the original dye list
  self.carbineWndDyeList:DestroyChildren()

  -- Set localized tooltips
  self.wndControls:FindChild("ListTypeGrid"):SetTooltip(L["VIEW_GRID"])
  self.wndControls:FindChild("ListTypeLong"):SetTooltip(L["VIEW_LIST"])
  self.wndControls:FindChild("OrderName"):SetTooltip(L["SORT_NAME"])
  self.wndControls:FindChild("OrderRamp"):SetTooltip(L["SORT_ID"])
  self.wndControls:FindChild("KnownOnly"):SetTooltip(L["SHOW_KNOWN_ONLY"])
  self.wndControls:FindChild("ColorChooserButton"):SetTooltip(L["SEARCH_COLOR"])

  self:ShowGradientWindow(self.ColorGradientVisible)

  -- Populate dyes
  carbineCostumes:Reset()

  ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, L['TIEDYE_ENABLED'])
end

function TieDye:RemoveHooks()
  if not self.carbineWndDyeList then
    return
  end

  -- Put Costume's Dye List window back where it expects it
  carbineCostumes.wndDyeList = self.carbineWndDyeList

  -- Remove our handler and destroy our window
  self:Unhook(Apollo.GetAddon("Costumes"), "FillDyes")
  self:Unhook(Apollo.GetAddon("Costumes"), "Reset")
  self.wndTieDyeContainer:Destroy()

  -- Unhide the Dye List window and then remove our reference
  self.carbineWndDyeList:Show(true)
  self.carbineWndDyeList = nil

  -- Populate dyes
  carbineCostumes:Reset()

  ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, L['TIEDYE_DISABLED'])
end

function TieDye:Reset()
  self.FilterText = ""
  self.wndControls:FindChild("SearchContainer:SearchInputBox"):SetText(self.FilterText)
  self.wndControls:FindChild("SearchContainer:SearchClearButton"):Show(self.FilterText ~= "")
  self.wndControls:FindChild("SearchContainer:SearchInputBox"):ClearFocus()
  self.MouseButtonPressed = false
end

function TieDye:FillDyes()
  self:SetButtons()
  self:GetKnownDyes()
  self:FillDyeList()
end

function TieDye:UpdateGradientMarker()
  local wndMarker = self.wndGradient:FindChild("HueMarker")
  local left, top, right, bottom = wndMarker:GetAnchorOffsets()
  local MarkerWidth = wndMarker:GetWidth()
  left = self.wndGradient:GetWidth() * self.FilterHue / 359
  left = math.floor(left - (MarkerWidth / 2))
  wndMarker:SetAnchorOffsets(left, top, left + MarkerWidth, bottom)
end

function TieDye:ShowGradientWindow(enable)
  -- Show/hide the gradient
  self.ColorGradientVisible = enable
  self.wndGradient:Show(enable)
  self.wndControls:FindChild("SearchContainer"):Show(not enable)
  self.wndControls:FindChild("ColorChooserButton"):SetCheck(enable)
  if enable then
    self:UpdateGradientMarker()
  end
end

---------------------------------------------------------------------------------------------------
-- Slash Commands
---------------------------------------------------------------------------------------------------
function TieDye:OnTieDyeCommand(command, args)
  if self:IsHooked(Apollo.GetAddon("Costumes"), "FillDyes") then
    self:RemoveHooks()
  else
    self:AddHooks()
  end
end

---------------------------------------------------------------------------------------------------
-- Load Dyes (Thanks to http://www.curse.com/ws-addons/wildstar/222537-dyepreview for the info)
---------------------------------------------------------------------------------------------------
function TieDye:LoadDyes()
  TieDyeData.nRampIndex_to_nId = {}
  TieDyeData.dyes = {}
  -- [1] = nId
  -- [2] = nRampIndex
  -- [3] = cost multiplier (normally not exposed via GetKnownDyes())
  -- [4] = strName
  local dyes = dofile(Apollo.GetAssetFolder() .. [[\libs\Dyes.lua]])
  for _, dye in ipairs(dyes) do
    if "(Unnamed)" ~= dye[4] then
      TieDyeData.nRampIndex_to_nId[dye[2]] = dye[1]
      TieDyeData.dyes[dye[1]] = {
        nId = dye[1],
        nRampIndex = dye[2],
        costMultiplier = dye[3],
        strName = dye[4]
      }
    end
  end
end

-----------------------------------------------------------------------------------------------
-- TieDye Filter Functions
-----------------------------------------------------------------------------------------------
function TieDye:MatchHue(nRampIndex, FilterHue)
  if not TieDyeData.ramps[nRampIndex] then
    return false
  end

  local RampHue = TieDyeData.ramps[nRampIndex].hsv.hue
  local Variance = math.abs(FilterHue - RampHue)
  return Variance < 30 or Variance > 329
end

-- Match hue against the hue of an entered color name
function TieDye:MatchColorName(nRampIndex)
  if TieDyeData.colors[self.FilterText] then
    return self:MatchHue(nRampIndex, TieDyeData.colors[self.FilterText].hsv.hue)
  else
    return false
  end
end

function TieDye:MatchDye(tDyeInfo)
  -- Unknown dye
  if self.KnownOnly then
    if not (tDyeInfo.nId and self.KnownDyesById[tDyeInfo.nId]) then
      return false
    end
  end

  -- Match hue against the filter hue
  if self.ColorGradientVisible then
    return self:MatchHue(tDyeInfo.nRampIndex, self.FilterHue)
  end

  if self.FilterText == "" then
    return true
  end

  -- Filter by color name
  if self:MatchColorName(tDyeInfo.nRampIndex) then
    return true
  end

  -- Match by substring
  return string.find(string.lower(tDyeInfo.strName), self.FilterText, 1, true) ~= nil
end

-----------------------------------------------------------------------------------------------
-- TieDye Functions
-----------------------------------------------------------------------------------------------
function TieDye:MakeTooltip(tDyeInfo)
  return tDyeInfo.strName
end

-- Define general functions here
function TieDye:MakeDyeWindow(tDyeInfo)
  if not self:MatchDye(tDyeInfo) then
    return
  end

  local strSprite = "CRB_DyeRampSprites:sprDyeRamp_" .. tDyeInfo.nRampIndex
  local strName = self:MakeTooltip(tDyeInfo)
  local wndNewDye = nil
  local tNewDyeInfo = {
    nRampIndex = tDyeInfo.nRampIndex,
    strName = tDyeInfo.strName,
    strSprite = strSprite,
    id = tDyeInfo.nId
  }

  if tDyeInfo.nId and self.KnownDyesById[tDyeInfo.nId] then
    if self.ShortList then
      wndNewDye = Apollo.LoadForm(self.xmlDoc, "DyeButton", self.wndDyeList, carbineCostumes)
    else
      wndNewDye = Apollo.LoadForm(self.xmlDoc, "DyeButtonLong", self.wndDyeList, carbineCostumes)
      wndNewDye:FindChild("DyeName"):SetText(self:MakeTooltip(tDyeInfo))
    end
  else
    if self.ShortList then
      wndNewDye = Apollo.LoadForm(self.xmlDoc, "DyeColor", self.wndDyeList, self)
      wndNewDye:SetOpacity(0.30, 1)
    else
      wndNewDye = Apollo.LoadForm(self.xmlDoc, "DyeColorLong", self.wndDyeList, self)
      wndNewDye:FindChild("DyeName"):SetText(self:MakeTooltip(tDyeInfo))
      wndNewDye:SetOpacity(0.50, 1)
    end
  end
  wndNewDye:SetData(tNewDyeInfo)

  wndNewDye:FindChild("DyeSwatchArtHack:DyeSwatch"):SetSprite(strSprite)
  wndNewDye:SetTooltip(strName)
end

function TieDye:SortDyes()
  local SortFunction
  if self.SortOrder == CodeEnumOrderBy.NAME then
    SortFunction = function(a, b) return a.strName < b.strName end
  else
    SortFunction = function(a, b)
      local RampDataA = TieDyeData.ramps[a.nRampIndex]
      local RampDataB = TieDyeData.ramps[b.nRampIndex]
      local OrderA = RampDataA and RampDataA.order or a.nRampIndex
      local OrderB = RampDataB and RampDataB.order or b.nRampIndex
      return OrderA < OrderB
    end
  end

  table.sort(self.SortedDyes, SortFunction)
end

function TieDye:GetKnownDyes()
  local dyesLoaded = (self.KnownDyes > 0)

  -- Build a table mapping ramp -> dye for known dyes
  local minRampIndex = 1  -- Is 0 valid? Best be safe, but assume it isn't by default
  local maxRampIndex = 169
  local newDyes = false
  for _, tDyeInfo in ipairs(GameLib.GetKnownDyes()) do
    if not self.KnownDyesById[tDyeInfo.nId] then
      newDyes = true
      self.KnownDyes = self.KnownDyes + 1
      self.KnownDyesById[tDyeInfo.nId] = tDyeInfo
      if dyesLoaded then
        ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System,
          string.format(L["DYE_LEARNED"], tDyeInfo.strName))
      end
    end
    self.KnownDyesByRamp[tDyeInfo.nRampIndex] = tDyeInfo

    if tDyeInfo.nRampIndex > maxRampIndex then
      maxRampIndex = tDyeInfo.nRampIndex
    elseif 0 == tDyeInfo.nRampIndex then
      minRampIndex = 0
    end
  end

  if not newDyes then
    return
  end

  if 1 == self.KnownDyes then
    ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Debug,
      string.format(L["ONE_DYE_KNOWN"]))
  else
    ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Debug,
      string.format(L["DYES_KNOWN"], self.KnownDyes))
  end

  -- Fill the table for sorting
  self.SortedDyes = {}
  local tDyeInfo, nId
  for nRampIndex = minRampIndex, maxRampIndex do
    tDyeInfo = self.KnownDyesByRamp[nRampIndex]
    if nil == tDyeInfo then
      nId = TieDyeData.nRampIndex_to_nId[nRampIndex]
      if nId and TieDyeData.dyes[nId] then
        -- Unknown dye we have data for
        tDyeInfo = TieDyeData.dyes[nId]
      else
        -- Unknown dye we have no data for, make a dummy record
        tDyeInfo = {
          nRampIndex = nRampIndex,
          strName = L["NO_INFO"]
        }
      end
    end
    table.insert(self.SortedDyes, tDyeInfo)
  end

  self:SortDyes()
end

function TieDye:FillDyeList()
  self.wndDyeList:DestroyChildren()

  for _, tDyeInfo in ipairs(self.SortedDyes) do
    self:MakeDyeWindow(tDyeInfo)
  end

  self.wndDyeList:ArrangeChildrenTiles()
end

-- Set the button state
function TieDye:SetButtons()
  self.wndControls:FindChild("ListTypeGrid"):SetCheck(self.ShortList)
  self.wndControls:FindChild("ListTypeLong"):SetCheck(not self.ShortList)
  self.wndControls:FindChild("OrderName"):SetCheck(self.SortOrder == CodeEnumOrderBy.NAME)
  self.wndControls:FindChild("OrderRamp"):SetCheck(self.SortOrder == CodeEnumOrderBy.RAMP)
  self.wndControls:FindChild("SearchContainer:SearchInputBox"):SetText(self.FilterText)
  self.wndControls:FindChild("SearchContainer:SearchClearButton"):Show(self.FilterText ~= "")
  self.wndControls:FindChild("KnownOnly"):SetCheck(self.KnownOnly)
end

---------------------------------------------------------------------------------------------------
-- TieDyeContainer Functions
---------------------------------------------------------------------------------------------------

function TieDye:OnClear( wndHandler, wndControl, eMouseButton )
  if self.FilterText then
    self.wndControls:FindChild("SearchContainer:SearchInputBox"):SetText("")
    self.wndControls:FindChild("SearchContainer:SearchInputBox"):ClearFocus()
    self:OnText(wndHandler, wndControl, "")
  end
end

function TieDye:OnText( wndHandler, wndControl, strText )
  self.FilterText = string.lower(strText)
  self.wndControls:FindChild("SearchContainer:SearchClearButton"):Show(strText ~= "")
  self:FillDyeList()
end

function TieDye:OnOrderByName( wndHandler, wndControl, eMouseButton )
  self.SortOrder = CodeEnumOrderBy.NAME
  self:SortDyes()
  self:FillDyeList()
end

function TieDye:OnOrderByRamp( wndHandler, wndControl, eMouseButton )
  self.SortOrder = CodeEnumOrderBy.RAMP
  self:SortDyes()
  self:FillDyeList()
end

function TieDye:OnListTypeGrid( wndHandler, wndControl, eMouseButton )
  self.ShortList = true
  self:FillDyeList()
end

function TieDye:OnListTypeLong( wndHandler, wndControl, eMouseButton )
  self.ShortList = false
  self:FillDyeList()
end

function TieDye:ButtonKnownOnly( wndHandler, wndControl, eMouseButton )
  self.KnownOnly = wndControl:IsChecked()
  self:FillDyeList()
end

function TieDye:OnColorFilterCheck( wndHandler, wndControl, eMouseButton )
  self:ShowGradientWindow(true)
  self:FillDyeList()
end

function TieDye:OnColorFilterUncheck( wndHandler, wndControl, eMouseButton )
  self:ShowGradientWindow(false)
  self:FillDyeList()
end

function TieDye:CalculateNewHue(width, nLastRelativeMouseX)
  nLastRelativeMouseX = math.min(nLastRelativeMouseX, width - 1)
  return math.floor(nLastRelativeMouseX * 359 / (width - 1))
end

function TieDye:OnGradientMouseButtonDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
  if wndHandler == wndControl and eMouseButton == GameLib.CodeEnumInputMouse.Left then
    self.MouseButtonPressed = true
    self.FilterHue = self:CalculateNewHue(self.wndGradient:GetWidth(), nLastRelativeMouseX)
    self:UpdateGradientMarker()
    self:FillDyeList()
  end
end

function TieDye:OnGradientMouseButtonUp( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
  if self.MouseButtonPressed and eMouseButton == GameLib.CodeEnumInputMouse.Left then
    self.MouseButtonPressed = false
  end
end

function TieDye:OnGradientMouseMove( wndHandler, wndControl, nLastRelativeMouseX, nLastRelativeMouseY )
  if wndHandler == wndControl and self.MouseButtonPressed then
    local FilterHue = self:CalculateNewHue(self.wndGradient:GetWidth(), nLastRelativeMouseX)
    if math.abs(self.FilterHue - FilterHue) > 10 then
      self.FilterHue = FilterHue
      self:UpdateGradientMarker()
      self:FillDyeList()
    end
  end
end

function TieDye:OnGradientMouseExit( wndHandler, wndControl, x, y )
  if wndHandler == wndControl then
    self.MouseButtonPressed = false
  end
end

-----------------------------------------------------------------------------------------------
-- TieDye Instance
-----------------------------------------------------------------------------------------------
local TieDyeInst = TieDye:new()
TieDyeInst:Init()
