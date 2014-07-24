-----------------------------------------------------------------------------------------------
-- Client Lua Script for TieDye
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Apollo"
require "GameLib"
require "Window"
 
-----------------------------------------------------------------------------------------------
-- TieDye Module Definition
-----------------------------------------------------------------------------------------------
local TieDye = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local carbineCostumes = Apollo.GetAddon("Costumes")

-- dyeRampColors[tDyeInfo.nRampIndex]
local dyeRampColors = {
    [1] = {["hue"] = 358, ["saturation"] =  49, ["value"] =  94},
    [2] = {["hue"] =   1, ["saturation"] =  64, ["value"] =  81},
    [3] = {["hue"] = 359, ["saturation"] =  80, ["value"] =  65},
    [4] = {["hue"] = 357, ["saturation"] =  89, ["value"] =  45},
    [5] = {["hue"] =   0, ["saturation"] =  90, ["value"] =  32},
    [6] = {["hue"] =   1, ["saturation"] =  40, ["value"] =  81},
    [7] = {["hue"] = 358, ["saturation"] =  42, ["value"] =  71},
    [8] = {["hue"] = 359, ["saturation"] =  48, ["value"] =  55},
    [9] = {["hue"] = 354, ["saturation"] =  55, ["value"] =  38},
   [10] = {["hue"] =   0, ["saturation"] =  51, ["value"] =  19},
   [11] = {["hue"] = 319, ["saturation"] =  44, ["value"] =  68},
   [12] = {["hue"] = 320, ["saturation"] =  51, ["value"] =  58},
   [13] = {["hue"] = 321, ["saturation"] =  69, ["value"] =  51},
   [14] = {["hue"] = 323, ["saturation"] =  68, ["value"] =  35},
   [15] = {["hue"] = 314, ["saturation"] =  57, ["value"] =  22},
   [16] = {["hue"] = 313, ["saturation"] =  41, ["value"] =  68},
   [17] = {["hue"] = 315, ["saturation"] =  45, ["value"] =  58},
   [18] = {["hue"] = 315, ["saturation"] =  54, ["value"] =  45},
   [19] = {["hue"] = 320, ["saturation"] =  56, ["value"] =  32},
   [20] = {["hue"] = 314, ["saturation"] =  57, ["value"] =  22},
   [21] = {["hue"] = 284, ["saturation"] =  37, ["value"] =  68},
   [22] = {["hue"] = 285, ["saturation"] =  48, ["value"] =  58},
   [23] = {["hue"] = 293, ["saturation"] =  60, ["value"] =  48},
   [24] = {["hue"] = 300, ["saturation"] =  60, ["value"] =  32},
   [25] = {["hue"] = 300, ["saturation"] =  57, ["value"] =  22},
   [26] = {["hue"] = 276, ["saturation"] =  29, ["value"] =  58},
   [27] = {["hue"] = 287, ["saturation"] =  33, ["value"] =  45},
   [28] = {["hue"] = 288, ["saturation"] =  46, ["value"] =  35},
   [29] = {["hue"] = 284, ["saturation"] =  51, ["value"] =  25},
   [30] = {["hue"] = 300, ["saturation"] =  41, ["value"] =  16},
   [31] = {["hue"] = 244, ["saturation"] =  41, ["value"] =  78},
   [32] = {["hue"] = 252, ["saturation"] =  51, ["value"] =  65},
   [33] = {["hue"] = 257, ["saturation"] =  70, ["value"] =  58},
   [34] = {["hue"] = 253, ["saturation"] =  70, ["value"] =  41},
   [35] = {["hue"] = 247, ["saturation"] =  57, ["value"] =  25},
   [36] = {["hue"] = 242, ["saturation"] =  27, ["value"] =  65},
   [37] = {["hue"] = 253, ["saturation"] =  32, ["value"] =  51},
   [38] = {["hue"] = 252, ["saturation"] =  39, ["value"] =  41},
   [39] = {["hue"] = 247, ["saturation"] =  46, ["value"] =  32},
   [40] = {["hue"] = 242, ["saturation"] =  43, ["value"] =  22},
   [41] = {["hue"] = 208, ["saturation"] =  58, ["value"] =  84},
   [42] = {["hue"] = 216, ["saturation"] =  66, ["value"] =  78},
   [43] = {["hue"] = 224, ["saturation"] =  75, ["value"] =  65},
   [44] = {["hue"] = 223, ["saturation"] =  80, ["value"] =  48},
   [45] = {["hue"] = 221, ["saturation"] =  80, ["value"] =  32},
   [46] = {["hue"] = 223, ["saturation"] =  38, ["value"] =  68},
   [47] = {["hue"] = 224, ["saturation"] =  47, ["value"] =  61},
   [48] = {["hue"] = 227, ["saturation"] =  56, ["value"] =  51},
   [49] = {["hue"] = 228, ["saturation"] =  58, ["value"] =  38},
   [50] = {["hue"] = 232, ["saturation"] =  42, ["value"] =  22},
   [51] = {["hue"] = 199, ["saturation"] =  55, ["value"] =  87},
   [52] = {["hue"] = 199, ["saturation"] =  72, ["value"] =  81},
   [53] = {["hue"] = 202, ["saturation"] =  87, ["value"] =  78},
   [54] = {["hue"] = 194, ["saturation"] =  79, ["value"] =  45},
   [55] = {["hue"] = 194, ["saturation"] =  78, ["value"] =  29},
   [56] = {["hue"] = 195, ["saturation"] =  25, ["value"] =  65},
   [57] = {["hue"] = 202, ["saturation"] =  33, ["value"] =  58},
   [58] = {["hue"] = 200, ["saturation"] =  50, ["value"] =  51},
   [59] = {["hue"] = 196, ["saturation"] =  40, ["value"] =  32},
   [60] = {["hue"] = 202, ["saturation"] =  42, ["value"] =  22},
   [61] = {["hue"] = 138, ["saturation"] =  94, ["value"] =  56},
   [62] = {["hue"] = 135, ["saturation"] =  92, ["value"] =  41},
   [63] = {["hue"] = 133, ["saturation"] =  89, ["value"] =  30},
   [64] = {["hue"] = 130, ["saturation"] =  85, ["value"] =  21},
   [65] = {["hue"] = 144, ["saturation"] = 100, ["value"] =  15},
   [66] = {["hue"] = 143, ["saturation"] =  60, ["value"] =  41},
   [67] = {["hue"] = 140, ["saturation"] =  59, ["value"] =  31},
   [68] = {["hue"] = 135, ["saturation"] =  60, ["value"] =  23},
   [69] = {["hue"] = 137, ["saturation"] =  63, ["value"] =  17},
   [70] = {["hue"] = 120, ["saturation"] =  50, ["value"] =  12},
   [71] = {["hue"] =  90, ["saturation"] =  38, ["value"] =  68},
   [72] = {["hue"] =  93, ["saturation"] =  58, ["value"] =  62},
   [73] = {["hue"] =  90, ["saturation"] =  83, ["value"] =  56},
   [74] = {["hue"] =  91, ["saturation"] =  84, ["value"] =  39},
   [75] = {["hue"] =  96, ["saturation"] =  73, ["value"] =  23},
   [76] = {["hue"] =  86, ["saturation"] =  20, ["value"] =  60},
   [77] = {["hue"] =  94, ["saturation"] =  30, ["value"] =  50},
   [78] = {["hue"] =  88, ["saturation"] =  45, ["value"] =  41},
   [79] = {["hue"] =  93, ["saturation"] =  46, ["value"] =  30},
   [80] = {["hue"] =  92, ["saturation"] =  45, ["value"] =  17},
   [81] = {["hue"] =  53, ["saturation"] =  61, ["value"] =  84},
   [82] = {["hue"] =  51, ["saturation"] =  75, ["value"] =  78},
   [83] = {["hue"] =  55, ["saturation"] =  90, ["value"] =  65},
   [84] = {["hue"] =  52, ["saturation"] =  93, ["value"] =  48},
   [85] = {["hue"] =  49, ["saturation"] =  90, ["value"] =  32},
   [86] = {["hue"] =  50, ["saturation"] =  36, ["value"] =  71},
   [87] = {["hue"] =  54, ["saturation"] =  42, ["value"] =  61},
   [88] = {["hue"] =  58, ["saturation"] =  53, ["value"] =  48},
   [89] = {["hue"] =  53, ["saturation"] =  54, ["value"] =  35},
   [90] = {["hue"] =  58, ["saturation"] =  57, ["value"] =  22},
   [91] = {["hue"] =  39, ["saturation"] =  63, ["value"] =  87},
   [92] = {["hue"] =  37, ["saturation"] =  75, ["value"] =  78},
   [93] = {["hue"] =  38, ["saturation"] =  90, ["value"] =  68},
   [94] = {["hue"] =  40, ["saturation"] =  93, ["value"] =  45},
   [95] = {["hue"] =  36, ["saturation"] =  89, ["value"] =  29},
   [96] = {["hue"] =  42, ["saturation"] =  36, ["value"] =  71},
   [97] = {["hue"] =  39, ["saturation"] =  42, ["value"] =  61},
   [98] = {["hue"] =  38, ["saturation"] =  56, ["value"] =  51},
   [99] = {["hue"] =  39, ["saturation"] =  54, ["value"] =  35},
  [100] = {["hue"] =  36, ["saturation"] =  57, ["value"] =  22},
  [101] = {["hue"] =  21, ["saturation"] =  53, ["value"] =  90},
  [102] = {["hue"] =  21, ["saturation"] =  64, ["value"] =  81},
  [103] = {["hue"] =  23, ["saturation"] =  81, ["value"] =  68},
  [104] = {["hue"] =  21, ["saturation"] =  80, ["value"] =  48},
  [105] = {["hue"] =  21, ["saturation"] =  80, ["value"] =  32},
  [106] = {["hue"] =  22, ["saturation"] =  29, ["value"] =  78},
  [107] = {["hue"] =  20, ["saturation"] =  38, ["value"] =  68},
  [108] = {["hue"] =  24, ["saturation"] =  53, ["value"] =  55},
  [109] = {["hue"] =  23, ["saturation"] =  50, ["value"] =  38},
  [110] = {["hue"] =  19, ["saturation"] =  50, ["value"] =  25},
  [111] = {["hue"] =   9, ["saturation"] =  52, ["value"] =  81},
  [112] = {["hue"] =   9, ["saturation"] =  63, ["value"] =  71},
  [113] = {["hue"] =  14, ["saturation"] =  84, ["value"] =  61},
  [114] = {["hue"] =  14, ["saturation"] =  86, ["value"] =  45},
  [115] = {["hue"] =  12, ["saturation"] =  78, ["value"] =  29},
  [116] = {["hue"] =   9, ["saturation"] =  24, ["value"] =  68},
  [117] = {["hue"] =  15, ["saturation"] =  39, ["value"] =  58},
  [118] = {["hue"] =  18, ["saturation"] =  53, ["value"] =  48},
  [119] = {["hue"] =  13, ["saturation"] =  54, ["value"] =  35},
  [120] = {["hue"] =   7, ["saturation"] =  42, ["value"] =  22},
  [121] = {["hue"] = 217, ["saturation"] =  10, ["value"] =  61},
  [122] = {["hue"] = 225, ["saturation"] =   6, ["value"] =  48},
  [123] = {["hue"] = 215, ["saturation"] =  17, ["value"] =  38},
  [124] = {["hue"] = 186, ["saturation"] =  13, ["value"] =  25},
  [125] = {["hue"] = 217, ["saturation"] =  16, ["value"] =  19},
  [126] = {["hue"] =  35, ["saturation"] =  12, ["value"] =  51},
  [127] = {["hue"] =  22, ["saturation"] =  13, ["value"] =  45},
  [128] = {["hue"] =  22, ["saturation"] =   8, ["value"] =  35},
  [129] = {["hue"] =  53, ["saturation"] =  13, ["value"] =  25},
  [130] = {["hue"] =  52, ["saturation"] =  16, ["value"] =  19},
  [131] = {["hue"] = 200, ["saturation"] =  18, ["value"] =  68},
  [132] = {["hue"] = 208, ["saturation"] =  24, ["value"] =  55},
  [133] = {["hue"] = 194, ["saturation"] =  23, ["value"] =  41},
  [134] = {["hue"] = 183, ["saturation"] =  22, ["value"] =  29},
  [135] = {["hue"] = 198, ["saturation"] =  28, ["value"] =  22},
  [136] = {["hue"] =  40, ["saturation"] =  73, ["value"] =  35},
  [137] = {["hue"] =  37, ["saturation"] =  78, ["value"] =  29},
  [138] = {["hue"] =  40, ["saturation"] =  71, ["value"] =  22},
  [139] = {["hue"] =  36, ["saturation"] =  67, ["value"] =  19},
  [140] = {["hue"] =  43, ["saturation"] =  80, ["value"] =  16},
  [141] = {["hue"] = 348, ["saturation"] =  65, ["value"] =  74},
  [142] = {["hue"] = 349, ["saturation"] =  67, ["value"] =  58},
  [143] = {["hue"] = 346, ["saturation"] =  65, ["value"] =  45},
  [144] = {["hue"] = 345, ["saturation"] =  65, ["value"] =  32},
  [145] = {["hue"] = 348, ["saturation"] =  71, ["value"] =  22},
  [146] = {["hue"] =  36, ["saturation"] =  57, ["value"] =  45},
  [147] = {["hue"] =  39, ["saturation"] =  54, ["value"] =  35},
  [148] = {["hue"] =  39, ["saturation"] =  55, ["value"] =  29},
  [149] = {["hue"] =  43, ["saturation"] =  57, ["value"] =  22},
  [150] = {["hue"] =  43, ["saturation"] =  67, ["value"] =  19},
  [151] = {["hue"] =  13, ["saturation"] =  39, ["value"] =  48},
  [152] = {["hue"] =  17, ["saturation"] =  42, ["value"] =  38},
  [153] = {["hue"] =  19, ["saturation"] =  44, ["value"] =  29},
  [154] = {["hue"] =  17, ["saturation"] =  42, ["value"] =  22},
  [155] = {["hue"] =  19, ["saturation"] =  51, ["value"] =  19},
  [156] = {["hue"] = 186, ["saturation"] =  27, ["value"] =  12},
  [157] = {["hue"] =  37, ["saturation"] =   3, ["value"] =  87},
  [158] = {["hue"] = 300, ["saturation"] =   1, ["value"] =  41},
  [159] = {["hue"] =   0, ["saturation"] =   0, ["value"] = 100},
  [160] = {["hue"] =   0, ["saturation"] =   0, ["value"] = 100},
  [161] = {["hue"] =  99, ["saturation"] =  85, ["value"] =  87},
  [162] = {["hue"] = 191, ["saturation"] =  88, ["value"] =  81},
  [163] = {["hue"] = 295, ["saturation"] =  63, ["value"] =  78},
  [164] = {["hue"] =  46, ["saturation"] =  73, ["value"] =  84},
  [165] = {["hue"] = 213, ["saturation"] =  32, ["value"] =  19},
  [166] = {["hue"] =  23, ["saturation"] =  87, ["value"] =  78},
  [167] = {["hue"] = 285, ["saturation"] =  45, ["value"] =  29},
  [168] = {["hue"] =  40, ["saturation"] = 100, ["value"] =  65},
  [169] = {["hue"] = 213, ["saturation"] =  32, ["value"] =  19},
}

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
    "Gemini:Hook-1.0"
  }
  Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

-----------------------------------------------------------------------------------------------
-- TieDye OnLoad
-----------------------------------------------------------------------------------------------
function TieDye:OnLoad()
  Apollo.GetPackage("Gemini:Hook-1.0").tPackage:Embed(self)

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
-- Define general functions here
function TieDye:MakeDyeWindow(tDyeInfo, idx)
  local strSprite = "CRB_DyeRampSprites:sprDyeRamp_" .. idx

  local strName = ""
  local wndNewDye = nil
  local tNewDyeInfo = {}

  if tDyeInfo then
    if self.FilterText ~= "" and string.find(string.lower(tDyeInfo.strName), self.FilterText, 1, true) == nil then
      return
    end
    strName = tDyeInfo.strName
    tNewDyeInfo.id = tDyeInfo.nId

    if self.ShortList then
      wndNewDye = Apollo.LoadForm(carbineCostumes.xmlDoc, "DyeColor", self.wndDyeList, carbineCostumes)
    else
      wndNewDye = Apollo.LoadForm(self.xmlDoc, "DyeButtonLong", self.wndDyeList, carbineCostumes)
      wndNewDye:FindChild("DyeName"):SetText(strName)
    end
  elseif self.FilterText == "" and not self.KnownOnly then
    strName = "Dye not learned"

    if self.ShortList then
      wndNewDye = Apollo.LoadForm(self.xmlDoc, "UnknownDyeColor", self.wndDyeList, self)
    else
      wndNewDye = Apollo.LoadForm(self.xmlDoc, "DyeColorLong", self.wndDyeList, self)
      wndNewDye:FindChild("DyeName"):SetText(strName)
    end
    wndNewDye:SetOpacity(0.25, 1)
  else
    return
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
