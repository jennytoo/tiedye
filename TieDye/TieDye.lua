-----------------------------------------------------------------------------------------------
-- Client Lua Script for TieDye
-----------------------------------------------------------------------------------------------

require "Apollo"
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



-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function TieDye:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- default display state
    self.OrderByName = false
    self.ShortList = true
    self.KnownOnly = true
    self.FilterText = ""

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

  -- load our form file
  self.xmlDoc = XmlDoc.CreateFromFile("TieDye.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
  Apollo.LoadSprites("TieDye_Sprites.xml")

  -- Add a slash command
  Apollo.RegisterSlashCommand("tiedye", "OnTieDyeCommand", self)
end

-----------------------------------------------------------------------------------------------
-- TieDye OnDocLoaded
-----------------------------------------------------------------------------------------------
function TieDye:OnDocLoaded()

  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
    -- Register handlers for events, slash commands and timer, etc.
    self:AddHooks()

    -- Do additional Addon initialization here
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
  tSave.Version = 1
  tSave.OrderByName = self.OrderByName
  tSave.DetailView = not self.ShortList
  tSave.KnownOnly = self.KnownOnly

  return tSave
end

function TieDye:SaveGeneral()
  -- General values (all encountered dyes)
  local tSave = {}
  for idx, tDyeInfo in ipairs(self.tDyeInfo) do
    tSave[tDyeInfo.nId] = tDyeInfo
  end

  for idx, tDyeInfo in ipairs(GameLib.GetKnownDyes()) do
    tSave[tDyeInfo.nId] = tDyeInfo
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
    self.OrderByName = tData.OrderByName == true
    self.ShortList = tData.DetailView == false
    self.KnownOnly = tData.KnownOnly == true
  elseif eLevel == GameLib.CodeEnumAddonSaveLevel.General then
    self.tDyeInfo = tData
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
  self.wndDyeContainer = Apollo.LoadForm(self.xmlDoc, "DyeContainer", carbineDyeContainer, self)
  self.wndControls = self.wndDyeContainer:FindChild("ButtonBackground")
  self.wndDyeList = self.wndDyeContainer:FindChild("DyeList")
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

  -- Populate dyes
  carbineCostumes:FillDyes()
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
  self.wndDyeContainer:Destroy()

  -- Unhide the Dye List window and then remove our reference
  self.carbineWndDyeList:Show(true)
  self.carbineWndDyeList = nil

  -- Populate dyes
  carbineCostumes:FillDyes()
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

-----------------------------------------------------------------------------------------------
-- TieDye Functions
-----------------------------------------------------------------------------------------------
function TieDye:FilterDye(tDyeInfo)
  -- Unknown dye
  if not tDyeInfo then
    return not (self.KnownOnly or self.FilterText ~= "")
  end

  -- No filter
  if self.FilterText == "" then
    return true
  end

  -- Match hue against the hue of an entered color name
  local hue, rampHue
  if TieDyeData.colors[self.FilterText] ~= nil then
    hue = TieDyeData.colors[self.FilterText].hsv.hue
    if TieDyeData.ramps[tDyeInfo.nRampIndex] ~= nil then
      rampHue = TieDyeData.ramps[tDyeInfo.nRampIndex].hue
      if math.abs(hue - rampHue) < 30 or math.abs(hue - rampHue) > 329 then
        return true
      end
    end
  end

  -- Match by substring
  return string.find(string.lower(tDyeInfo.strName), self.FilterText, 1, true) ~= nil
end

function TieDye:MakeTooltip(tDyeInfo)
  if tDyeInfo then
    return tDyeInfo.strName
  else
    return L["LOCKED"]
  end
end

-- Define general functions here
function TieDye:MakeDyeWindow(tDyeInfo, idx)
  local strSprite = "CRB_DyeRampSprites:sprDyeRamp_" .. idx

  if not self:FilterDye(tDyeInfo) then
    return
  end

  local strName = self:MakeTooltip(tDyeInfo)
  local wndNewDye = nil
  local tNewDyeInfo = {}

  if tDyeInfo then
    tNewDyeInfo.id = tDyeInfo.nId

    if self.ShortList then
      wndNewDye = Apollo.LoadForm(carbineCostumes.xmlDoc, "DyeColor", self.wndDyeList, carbineCostumes)
    else
      wndNewDye = Apollo.LoadForm(self.xmlDoc, "DyeButtonLong", self.wndDyeList, carbineCostumes)
      wndNewDye:FindChild("DyeName"):SetText(strName)
    end
  else
    if self.ShortList then
      wndNewDye = Apollo.LoadForm(self.xmlDoc, "UnknownDyeColor", self.wndDyeList, self)
    else
      wndNewDye = Apollo.LoadForm(self.xmlDoc, "DyeColorLong", self.wndDyeList, self)
      wndNewDye:FindChild("DyeName"):SetText(strName)
    end
    wndNewDye:SetOpacity(0.25, 1)
  end
  tNewDyeInfo.strName = strName
  tNewDyeInfo.strSprite = strSprite
  tNewDyeInfo.nRampIndex = idx
  wndNewDye:SetData(tNewDyeInfo)

  wndNewDye:FindChild("DyeSwatchArtHack:DyeSwatch"):SetSprite(strSprite)
  wndNewDye:SetTooltip(strName)
end

function TieDye:FillDyesByRamp()
  local knownDyes = {}
  local minRampIndex = 1 -- Is 0 valid? Best be safe, but assume it isn't by default
  local maxRampIndex = 169
  for idx, tDyeInfo in ipairs(GameLib.GetKnownDyes()) do
    knownDyes[tDyeInfo.nRampIndex] = tDyeInfo
    if tDyeInfo.nRampIndex > maxRampIndex then
      maxRampIndex = tDyeInfo.nRampIndex
    elseif 0 == tDyeInfo.nRampIndex then
      minRampIndex = 0
    end
  end

  for idx = minRampIndex, maxRampIndex do
    self:MakeDyeWindow(knownDyes[idx], idx)
  end
end

function TieDye:FillDyesByName()
  local tDyeSort = GameLib.GetKnownDyes()
  table.sort(tDyeSort, function (a,b) return a.strName < b.strName end)
  for idx, tDyeInfo in ipairs(tDyeSort) do
    self:MakeDyeWindow(tDyeInfo, tDyeInfo.nRampIndex)
  end
end

function TieDye:FillDyeList()
  self.wndDyeList:DestroyChildren()

  if self.OrderByName then
    self:FillDyesByName()
  else
    self:FillDyesByRamp()
  end

  self.wndDyeList:ArrangeChildrenTiles()
end

function TieDye:SetButtons()
  self.wndControls:FindChild("ListTypeGrid"):SetCheck(self.ShortList)
  self.wndControls:FindChild("ListTypeLong"):SetCheck(not self.ShortList)
  self.wndControls:FindChild("OrderName"):SetCheck(self.OrderByName == true)
  self.wndControls:FindChild("OrderRamp"):SetCheck(not self.OrderByName)
  self.wndControls:FindChild("EditBox"):SetText(self.FilterText)
  local KnownOnlyButton = self.wndControls:FindChild("KnownOnly")
  KnownOnlyButton:SetCheck(self.KnownOnly)
  KnownOnlyButton:Enable(not self.OrderByName)
  if self.OrderByName then
    KnownOnlyButton:SetOpacity(0.5, 1)
  else
    KnownOnlyButton:SetOpacity(1, 1)
  end
end

function TieDye:Reset()
  self.FilterText = ""
  self.wndControls:FindChild("EditBox"):SetText(self.FilterText)
end

function TieDye:FillDyes()
  self:SetButtons()
  self:FillDyeList()
end

---------------------------------------------------------------------------------------------------
-- DyeContainer Functions
---------------------------------------------------------------------------------------------------

function TieDye:OnClear( wndHandler, wndControl, eMouseButton )
  if self.FilterText then
    self.wndControls:FindChild("EditBox"):SetText("")
    self:OnText(wndHandler, wndControl, "")
  end
end

function TieDye:OnText( wndHandler, wndControl, strText )
  self.FilterText = string.lower(strText)
  self:FillDyeList()
end

function TieDye:OnOrderByName( wndHandler, wndControl, eMouseButton )
  self.OrderByName = true
  local KnownOnlyButton = self.wndControls:FindChild("KnownOnly")
  KnownOnlyButton:Enable(false)
  KnownOnlyButton:SetOpacity(0.5, 1)
  self:FillDyeList()
end

function TieDye:OnOrderByRamp( wndHandler, wndControl, eMouseButton )
  self.OrderByName = false
  local KnownOnlyButton = self.wndControls:FindChild("KnownOnly")
  KnownOnlyButton:Enable(true)
  KnownOnlyButton:SetOpacity(1, 1)
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

-----------------------------------------------------------------------------------------------
-- TieDye Instance
-----------------------------------------------------------------------------------------------
local TieDyeInst = TieDye:new()
TieDyeInst:Init()
