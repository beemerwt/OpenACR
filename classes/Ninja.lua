local Ninja = {
  PvPCapable = true,

  ComboEnabled       = true,
  NinkiEnabled       = true,
  NinjutsuEnabled    = true,
  AOEEnabled         = true,
  RaijuEnabled       = true,
  TCJEnabled         = true,
  MeisuiEnabled      = true,
  AssassinateEnabled = true,
  TAEnabled          = true,
  ThrowingEnabled    = true,
  ACEnabled          = true
}

local TargetHasTrickAttack = false
local TargetHasMug = false

local Buffs = {
  Mudra       = 496,
  TrickAttack = 3254,
  Mug         = 638,
  RaijuReady  = 2690,
  Doton       = 501,
  Kassatsu    = 497,
  Suiton      = 507,
  TenChiJin   = 1186,
  KamaitachiReady = 2723
}

local PvPSkills = {
  Combo1 = 29500, -- 3k
  Combo2 = 29501, -- 4k
  Combo3 = 29502, -- 5k

  Shukuchi = 29513, -- Movement + Stealth
  Assassinate = 29503, -- Can only be used while stealthed

  Fuma = 29505, -- Changes to Hyosho while Mudra'ed (6k)
  Hyosho = 29506, -- 16k

  -- Changes to Meisui, 10s duration, 2 charges, 15s cd, off GCD, can't use same mudra ability afterwards
  ThreeMudra = 29507,

  Meisui = 29508, -- Heals self (8k, 4k HOT/15s)
  Huton = 29512, -- Nullifies damage
  ForkedRaiju = 29510, -- 4k, Stuns 2s, Readies Fleeting Raiju
  FleetingRaiju = 29707, -- 4k, Also Stuns (2s, halved because DR)
  Goka = 29504, -- AOE, instant 4k, DOT for 12s dealing 4k damage
  Bunshin = 29511, -- Shadow Clone attacks (does not apply to limbreak)

  Sprint = 29057,
  Recuperate = 29711, -- 2.5k MP, Instant, 1s, heals 15k
  Elixir = 29055, -- Restores all HP and MP, 4.5s cast
  LimitBreak = 29515, -- Instantly kills target under 50% or deals 10k, if kills then it can be used again
  Guard = 29054, -- Reduces damage by 90%, immune to CC, 5s duration, can be reused to end early, movement speed halved
  Purify = 29056, -- Removes current CC--lasts 5s
  Mug = 29509, -- 2k, increases damage taken by 10%, lasts 10s, grants 1 charge of Fuma, changes to Goka
  Doton = 29514, -- AOE ground DOT (2k), when use Goka or Hyosho deals additional 2k damage and slows by 75% for 3s
}

local Skills = {
  ShadeShift      = 2241,
  Hide            = 2245,
  ThrowingDagger  = 2247,
  Mug             = 2248,
  TrickAttack     = 2258,
  Shukuchi        = 2262,
  ArmorCrush      = 3563,
  TenChiJin       = 7403,
  Kamaitachi      = 25774,
  DreamWithinADream = 3566, -- No GCD
  Assassinate     = 2246,

  -- Mudras/Ninjutsu
  Ninjutsu = 2260,
  Ten      = 2259,
  MudraTen = 18805,
  Chi      = 2261,
  MudraChi = 18806,
  Jin      = 2263,
  MudraJin = 18807,

  Fuma        = 2265,
  TCJFuma     = 18873,

  Katon       = 2266,
  MudraKaton  = 18876,

  Raiton      = 2267,
  TCJRaiton   = 18877,

  Suiton      = 2271,
  TCJSuiton   = 18881,

  Hyosho      = 16492,
  Goka        = 16491,
  Hyoton      = 2268,
  MudraHyoton = 18878,
  Doton       = 2270,
  MudraDoton  = 18880,
  Huton       = 2269,
  MudraHuton  = 18879,

  Kassatsu    = 2264,

  -- Raijus
  ForkedRaiju     = 25777,
  FleetingRaiju   = 25778,

  -- Basic Combo
  SpinningEdge    = 2240,
  GustSlash       = 2242,
  AeolianEdge     = 2255,
  -- Basic Combo AOE
  HakkeMujinsatsu = 16488,
  DeathBlossom    = 2254,

  -- Ninki
  Meisui          = 16489,
  Bunshin         = 16493,
  Bhavacakra      = 7402, -- No GCD
  Hellfrog        = 7401  -- NO GCD
}

local Mudras = {
  Fuma   = { 'ten' },

  Raiton = { 'ten', 'chi' }, -- 9
  Katon  = { 'chi', 'ten' }, -- 6

  Hyosho = { 'ten', 'jin' }, -- 13
  Goka   = { 'jin', 'ten' }, -- 7

  Huton  = { 'jin', 'chi', 'ten' }, -- 27
  Doton  = { 'ten', 'jin', 'chi' }, -- 45, 39 (Jin Ten Chi)
  Suiton = { 'ten', 'chi', 'jin' }, -- 57
}

local MudraActions = {
  [1] = Skills.Fuma,
  [6] = Skills.Katon,
  [7] = Skills.Goka,
  [9] = Skills.Raiton,
  [13] = Skills.Hyosho,
  [27] = Skills.Huton,
  [45] = Skills.Doton,
  [57] = Skills.Suiton
}

local function IsNinjutsuReady()
  return HasBuff(Player.id, Buffs.Kassatsu) or not IsOnCooldown(Skills.Ten)
end

local StartMudra = 0
local MudraQueue = {}
local function QueueMudra(mudra)
  MudraQueue = table.shallowcopy(mudra)
  StartMudra = Now()
  return true
end

local function Ninjutsu(numNearby)
  if not IsCapable(Skills.Ninjutsu) then return false end
  if not IsNinjutsuReady() then return false end

  if numNearby > 2 and Ninja.AOEEnabled then
    if not HasBuff(Player.id, Buffs.Doton) and IsCapable(Skills.Doton) then
      return QueueMudra(Mudras.Doton)
    end

    if HasBuff(Player.id, Buffs.Kassatsu) and IsCapable(Skills.Goka) then
      return QueueMudra(Mudras.Goka);
    end

    if IsCapable(Skills.Katon) then
      return QueueMudra(Mudras.Katon);
    end
  end

  local isMudraTransitioning = HasBuff(Player.id, Buffs.Mudra, 57)
  -- Use Suiton to set up Trick Attack when there is less than 20 seconds left on Trick Attack's cooldown.
  if not HasBuff(Player.id, Buffs.Suiton) and not isMudraTransitioning and IsCapable(Skills.Suiton) then
    local TrickAttack = ActionList:Get(1, Skills.TrickAttack)
    if TrickAttack.cdmax - TrickAttack.cd < 20 then
      return QueueMudra(Mudras.Suiton)
    end
  end

  if numNearby > 1 and Ninja.AOEEnabled then
    if not HasBuff(Player.id, Buffs.Doton) and IsCapable(Skills.Doton) then
      return QueueMudra(Mudras.Doton)
    end

    if HasBuff(Player.id, Buffs.Kassatsu) and IsCapable(Skills.Goka) then
      return QueueMudra(Mudras.Goka) -- Goka Mekkyaku for multi-target
    end
  end

  if HasBuff(Player.id, Buffs.Kassatsu) and IsCapable(Skills.Hyosho) then
    return QueueMudra(Mudras.Hyosho) -- Hyosho Ranryu for single-target
  end

  if IsCapable(Skills.Raiton) then
    return QueueMudra(Mudras.Raiton)
  end

  if IsCapable(Skills.Fuma) then
    return QueueMudra(Mudras.Fuma)
  end

  return false
end

local function CastMudra(name)
  if name == 'ten' then
    local ten = ActionList:Get(1, Skills.Ten)
    local mudraTen = ActionList:Get(1, Skills.MudraTen)
    if ten:IsReady() or mudraTen:IsReady() then
      return ten:Cast()
    end
    -- return ReadyCast(Player.id, Skills.Ten, Skills.MudraTen)
  elseif name == 'chi' then
    local chi = ActionList:Get(1, Skills.Chi)
    local mudraChi = ActionList:Get(1, Skills.MudraChi)
    if chi:IsReady() or mudraChi:IsReady() then
      return chi:Cast()
    end
    -- return ReadyCast(Player.id, Skills.Chi, Skills.MudraChi)
  elseif name == 'jin' then
    local jin = ActionList:Get(1, Skills.Jin)
    local mudraJin = ActionList:Get(1, Skills.MudraJin)
    if jin:IsReady() or mudraJin:IsReady() then
      return jin:Cast()
    end
    --return ReadyCast(Player.id, Skills.Jin, Skills.MudraJin)
  end

  return false
end

local function BasicCombo(target)
  if Player.lastcomboid == Skills.DeathBlossom then
    return ReadyCast(Player.id, Skills.HakkeMujinsatsu)
  elseif Player.lastcomboid == Skills.GustSlash and Player.gauge[2] > 30000 then
    return ReadyCast(target.id, Skills.AeolianEdge)
  elseif Player.lastcomboid == Skills.SpinningEdge then
    return ReadyCast(target.id, Skills.GustSlash)
  end

  return false
end

local function GetBuff(id)
  for i,_ in ipairs(Player.buffs) do
    if Player.buffs[i].id == id then
      return Player.buffs[i]
    end
  end

  return nil
end

local function DidNotCastMudraLast()
  return not In(Player.lastcastid,
    Skills.Ten,
    Skills.Chi,
    Skills.Jin,
    Skills.MudraTen,
    Skills.MudraChi,
    Skills.MudraJin)
end

local usedFuma = false
local usedRaiton = false
local usedSuiton = false

-- The Cast() function is where the magic happens.
-- Action code should be called and fired here.
function Ninja:Cast(target)
  TargetHasTrickAttack  = HasBuff(target.id, Buffs.TrickAttack)
  TargetHasMug          = HasBuff(target.id, Buffs.Mug)
  local playerTCJ       = GetBuff(Buffs.TenChiJin)
  local playerMudra     = GetBuff(Buffs.Mudra)

  -- TimeSince Failsafe
  if #MudraQueue > 0 and TimeSince(StartMudra) < 6000 then
    if CastMudra(MudraQueue[1]) then
      table.remove(MudraQueue, 1)
      return true
    end

    return false
  end

  if playerTCJ ~= nil then
    if playerTCJ.stacks == 0 then
      if ReadyCast(target.id, Skills.TCJFuma) then
        return true
      end
    end

    if playerTCJ.stacks == 1 then
      if ReadyCast(target.id, Skills.TCJRaiton) then
        return true
      end
    end

    if playerTCJ.stacks == 9 then
      if ReadyCast(target.id, Skills.TCJSuiton) then
        return true
      end
    end

    return false
  end

  if playerMudra ~= nil then
    local id = MudraActions[playerMudra.stacks]
    if id == Skills.Huton or id == Skills.Doton then
      if ReadyCast(Player.id, id) then return true end
    else
      if ReadyCast(target.id, id) then return true end
    end

    return false
  end

  local nearby = GetNearbyEnemies(5)

  -- Cast Huton if player doesn't have it.
  if Player.gauge[2] == 0 and IsNinjutsuReady() and IsCapable(Skills.Huton) then
    return QueueMudra(Mudras.Huton)
  end

  if self.ACEnabled and Player.gauge[2] < 30000 then
    local isImmediate = Player.gauge[2] <= 3000 and Player.gauge[2] > 0
    if isImmediate or Player.lastcomboid == Skills.GustSlash then
      if ReadyCast(target.id, Skills.ArmorCrush) then return true end
    end
  end

  if self.RaijuEnabled and #nearby < 2 then
    if HasBuff(Player.id, Buffs.RaijuReady) then
      if ReadyCast(target.id, Skills.FleetingRaiju, Skills.ForkedRaiju) then
        return true
      end
    end
  end

  if self.NinkiEnabled then
    local ninkiPower = Player.gauge[1]

    -- Bunshin = Kamaitachi | Cast both on cooldown
    if ReadyCast(target.id, Skills.Kamaitachi) then return true end
    if ReadyCast(Player.id, Skills.Bunshin) then return true end

    -- Ninki Management, The big thing is that you will never want to overcap it
    if #nearby > 2 then
      if ReadyCast(target.id, Skills.Hellfrog) then return true end
    elseif TargetHasTrickAttack or ninkiPower >= 85 then
      if ReadyCast(target.id, Skills.Bhavacakra) then return true end
    end
  end

  if self.TCJEnabled then
    if TargetHasTrickAttack or TargetHasMug then
      if (self.MeisuiEnabled and not IsOnCooldown(Skills.Meisui)) or not self.MeisuiEnabled then
        if ReadyCast(Player.id, Skills.TenChiJin) then return true end
      end
    end
  end

  if self.TAEnabled then
    if ReadyCast(target.id, Skills.TrickAttack) then return true end
  end

  if self.AssassinateEnabled then
    if (TargetHasTrickAttack or TargetHasMug) and #nearby < 3 then
      if ReadyCast(target.id, Skills.Assassinate, Skills.DreamWithinADream) then return true end
    end
  end

  if self.MeisuiEnabled and IsOnCooldown(Skills.TrickAttack) then
    if ReadyCast(Player.id, Skills.Meisui) then return true end
  end

  if self.NinjutsuEnabled then
    if Ninjutsu(#nearby) then
      return true
    end

    -- BUG: There is a frame inbetween where this is false and causes it to be cast before all charges are expended
    if not IsNinjutsuReady() and playerMudra ~= nil and DidNotCastMudraLast() then
      if ReadyCast(Player.id, Skills.Kassatsu) then return true end
    end
  end

  if self.ComboEnabled then
    if BasicCombo(target) then return true end
    if self.AOEEnabled and #nearby > 2 and IsCapable(Skills.DeathBlossom) then
      if ReadyCast(Player.id, Skills.DeathBlossom) then return true end
    else
      if ReadyCast(target.id, Skills.SpinningEdge) then return true end
    end
  end

  if self.ThrowingEnabled then
    if ReadyCast(target.id, Skills.ThrowingDagger) then return true end
  end

  return false
end

function Ninja:CastPvP(target)

end

-- The Draw() function provides a place where a developer can show custom options.
function Ninja:Draw()
  GUI:BeginChild("Class##SkillWindow", 0.0, 0.0, true)
  self.AOEEnabled = OpenACR.ListCheckboxItem("AOE Enabled", self.AOEEnabled, 145)
  self.ComboEnabled = OpenACR.ListCheckboxItem("Combo Enabled", self.ComboEnabled, 145)
  self.NinkiEnabled = OpenACR.ListCheckboxItem("Ninki Enabled", self.NinkiEnabled, 145)
  self.NinjutsuEnabled = OpenACR.ListCheckboxItem("Ninjutsu Enabled", self.NinjutsuEnabled, 145)
  self.RaijuEnabled = OpenACR.ListCheckboxItem("Raiju Enabled", self.RaijuEnabled, 145)
  self.TCJEnabled = OpenACR.ListCheckboxItem("Ten Chi Jin", self.TCJEnabled, 145)
  self.ACEnabled = OpenACR.ListCheckboxItem("Armor Crush", self.ACEnabled, 145)
  self.ThrowingEnabled = OpenACR.ListCheckboxItem("Throwing Dagger", self.ThrowingEnabled, 145)
  self.AssassinateEnabled = OpenACR.ListCheckboxItem("Assassinate", self.AssassinateEnabled, 145)
  self.MeisuiEnabled = OpenACR.ListCheckboxItem("Meisui", self.MeisuiEnabled, 145)
  self.TAEnabled = OpenACR.ListCheckboxItem("Trick Attack", self.TAEnabled, 145)
  GUI:EndChild()
end

function Ninja:DrawPvP()

end

-- The OnLoad() function is fired when a profile is prepped and loaded by ACR.
function Ninja:OnLoad()
  self.ComboEnabled = ACR.GetSetting("OpenACR_Ninja_ComboEnabled", true)
  self.NinkiEnabled = ACR.GetSetting("OpenACR_Ninja_NinkiEnabled", true)
  self.AOEEnabled = ACR.GetSetting("OpenACR_Ninja_AOEEnabled", true)
  self.NinjutsuEnabled = ACR.GetSetting("OpenACR_Ninja_NinjutsuEnabled", true)
  self.RaijuEnabled = ACR.GetSetting("OpenACR_Ninja_RaijuEnabled", true)
  self.TCJEnabled = ACR.GetSetting("OpenACR_Ninja_TenChiJinEnabled", true)
  self.ACEnabled = ACR.GetSetting("OpenACR_Ninja_ArmorCrushEnabled", true)
  self.ThrowingEnabled = ACR.GetSetting("OpenACR_Ninja_ThrowingDaggerEnabled", true)
  self.AssassinateEnabled = ACR.GetSetting("OpenACR_Ninja_AssassinateEnabled", true)
  self.MeisuiEnabled = ACR.GetSetting("OpenACR_Ninja_MeisuiEnabled", true)
  self.TAEnabled = ACR.GetSetting("OpenACR_Ninja_TrickAttackEnabled", true)
end

-- The OnClick function is fired when a user clicks on the ACR party interface.
-- It accepts 5 parameters:
-- mouse /int/ - Possible values are 0 (Left-click), 1 (Right-click), 2 (Middle-click)
-- shiftState /bool/ - Is shift currently pressed?
-- controlState /bool/ - Is control currently pressed?
-- altState /bool/ - Is alt currently pressed?
-- entity /table/ - The entity information for the party member that was clicked on.
function Ninja:OnClick(mouse,shiftState,controlState,altState,entity)

end

-- The OnUpdate() function is fired on the gameloop, like any other OnUpdate function found in FFXIVMinion code.
function Ninja:OnUpdate(event, tickcount)
end

-- Return the profile to ACR, so it can be read.
return Ninja