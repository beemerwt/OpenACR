-- From top to bottom, the order of operations of casting.
local profile = {
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

local activeTrickAttack = nil

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
  Bunshin       = 29511,
  FleetingRaiju = 29707,
  Meisui        = 29508,
  ForkedRaiju   = 29510,
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
  SecondWind      = 7541,
  Bloodbath       = 7542, -- No GCD
  Kamaitachi      = 16493,
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
  Fuma   = { 'ten', 'ten' },
  Katon  = { 'chi', 'ten' },
  Raiton = { 'ten', 'chi' },
  Hyoton = { 'ten', 'jin' },
  Hyosho = { 'ten', 'jin' },
  Goka   = { 'jin', 'ten' },
  Doton  = { 'ten', 'jin', 'chi' },
  Huton  = { 'jin', 'chi', 'ten' },
  Suiton = { 'ten', 'chi', 'jin' },
}

local function TrickAttackIsActive()
  return activeTrickAttack ~= nil
end

local function IsNinjutsuReady()
  return PlayerHasBuff(Buffs.Kassatsu) or not IsOnCooldown(Skills.Ten)
end

local StartMudra = 0
local MudraQueue = {}
local function ComboMudra()
  if #MudraQueue == 0 then return false end
  if TimeSince(StartMudra) >= 6000 then return false end

  local wasCast = false
  if MudraQueue[1] == 'ten' then
    wasCast = ReadyCast(Player.id, Skills.Ten, Skills.MudraTen)
  elseif MudraQueue[1] == 'chi' then
    wasCast = ReadyCast(Player.id, Skills.Chi, Skills.MudraChi)
  elseif MudraQueue[1] == 'jin' then
    wasCast = ReadyCast(Player.id, Skills.Jin, Skills.MudraJin)
  end

  if wasCast then table.remove(MudraQueue, 1) end
  return true
end

local function QueueMudra(mudra)
  MudraQueue = table.shallowcopy(mudra)
  StartMudra = Now()
  return true
end

local function Opener()
  -- 11 seconds before pull JCT -> Huton
  -- Hide
  -- TCJ -> Suiton cast 1s before pull
  -- At 1 second on the countdown, use Suiton Icon Suiton then immediately use Kassatsu
  -- Spinning Edge -> Grade 6 Tincture of Dexterity
  -- Gust Slash -> Mug -> Bunshin
  -- Phantom Kamaitachi -> late weave Trick Attack Icon Trick Attack
  -- Aeolian Edge -> Dream Within a Dream
  -- Hyosho Ranryu
  -- Raiton -> Ten Chi Jin
  -- Fuma Shuriken -> Raiton -> Suiton -> Meisui
  -- Fleeting Raiju ->Bhavacakra Icon Bhavacakra
  -- Fleeting Raiju ->Bhavacakra Icon Bhavacakra
  -- Raiton
  -- Fleeting Raiju
end

local function Ninjutsu(numNearby)
  if not IsCapable(Skills.Ninjutsu) then return false end
  if not IsNinjutsuReady() then return false end

  if numNearby > 2 and profile.AOEEnabled then
    if not PlayerHasBuff(Buffs.Doton) and IsCapable(Skills.Doton) then
      return QueueMudra(Mudras.Doton)
    end

    if PlayerHasBuff(Buffs.Kassatsu) and IsCapable(Skills.Goka) then
      return QueueMudra(Mudras.Goka);
    end

    return QueueMudra(Mudras.Katon);
  end

  -- Use Suiton to set up Trick Attack when there is less than 20 seconds left on Trick Attack's cooldown.
  if not PlayerHasBuff(Buffs.Suiton) then
    local TrickAttack = ActionList:Get(1, Skills.TrickAttack)
    if TrickAttack.cdmax - TrickAttack.cd < 20 then
      return QueueMudra(Mudras.Suiton)
    end
  end

  if numNearby > 1 and profile.AOEEnabled then
    if not PlayerHasBuff(Buffs.Doton) and IsCapable(Skills.Doton) then
      return QueueMudra(Mudras.Doton)
    end

    if PlayerHasBuff(Buffs.Kassatsu) and IsCapable(Skills.Goka) then
      return QueueMudra(Mudras.Goka) -- Goka Mekkyaku for multi-target
    end
  end

  if PlayerHasBuff(Buffs.Kassatsu) and IsCapable(Skills.Hyosho) then
    return QueueMudra(Mudras.Hyosho) -- Hyosho Ranryu for single-target
  end

  if IsCapable(Skills.Raiton) then
    return QueueMudra(Mudras.Raiton)
  end

  return QueueMudra(Mudras.Fuma)
end

local function BasicCombo(numNearby)
  if numNearby > 2 and profile.AOEEnabled then
    if Player.lastcomboid == Skills.DeathBlossom then
      return CastOnSelfIfPossible(Skills.HakkeMujinsatsu)
    else
      return CastOnSelfIfPossible(Skills.DeathBlossom)
    end
  else
    -- If you have more than 30 seconds left on your Huton buff
    --  use Aeolian Edge as your combo ender instead.
    if Player.lastcomboid == Skills.GustSlash and Player.gauge[2] > 30000 then
      return CastOnTargetIfPossible(Skills.AeolianEdge)
    elseif Player.lastcomboid == Skills.SpinningEdge then
      return CastOnTargetIfPossible(Skills.GustSlash)
    else
      return CastOnTargetIfPossible(Skills.SpinningEdge)
    end
  end

  return false
end

function UseRaiju(numNearby)
  if numNearby > 2 then return false end
  if not PlayerHasBuff(Buffs.RaijuReady) then return false end

  return CastOnTargetIfPossible(Skills.FleetingRaiju)
    or CastOnTargetIfPossible(Skills.ForkedRaiju);
end

local function MaintainHuton()
  -- If player doesn't have Huton, must cast.
  local hutonTimeleft = Player.gauge[2]
  local hasHuton = hutonTimeleft > 0
  if not hasHuton and IsNinjutsuReady() then
    return QueueMudra(Mudras.Huton)
  end

  if hutonTimeleft < 30000 and profile.ACEnabled then
    local isImmediate = Player.gauge[2] <= 3000
    if isImmediate or Player.lastcomboid == Skills.GustSlash then
      if CastOnTargetIfPossible(Skills.ArmorCrush) then return true end
    end
  end

  return false
end

local function ManageNinki(numNearby)
  local ninkiPower = Player.gauge[1]

  if CastOnTargetIfPossible(Skills.Bunshin) then
    return true
  end

  -- Use Bunshin as soon as it is off cooldown.
  if CastOnSelfIfPossible(Skills.Bunshin) then
    return true
  end

  -- Ninki Management
  -- The big thing is that you will never want to overcap it
  if numNearby < 3 then
    -- If Trick Attack is up, use all your Ninki on Bhavacakra.
    -- If you are about to overcap Ninki and Trick Attack is not up, use Bhavacakra once.
    if TrickAttackIsActive() or ninkiPower >= 85 then
      if CastOnTargetIfPossible(Skills.Bhavacakra) then
        return true
      end
    end
  else
    -- Our ninki will now be used for AoE as well.
    -- This means using Hellfrog Medium instead of Bhavacakra
    if CastOnTargetIfPossible(Skills.Hellfrog) then
      return true
    end
  end

  return false
end

local function MugIsActive()
  local mug = GetTargetDebuff(Buffs.Mug)
  return mug ~= nil
end

local usedFuma = false
local usedRaiton = false
local usedSuiton = false
local function TCJ()
  if not TrickAttackIsActive() and not MugIsActive() then return false end

    -- We only ever want to do this if Meisui is up
  if profile.MeisuiEnabled and IsOnCooldown(Skills.Meisui) then return false end

  if CastOnSelfIfPossible(Skills.TenChiJin) then
    usedFuma = false
    usedRaiton = false
    usedSuiton = false
    return true
  end

  return false
end

-- The Cast() function is where the magic happens.
-- Action code should be called and fired here.
function profile.Cast()
  if not OpenACR_IsReady then return false end
  if Player == nil then return false end
  if not ActionList:IsReady() then return false end

  if ComboMudra() then return true end

  -- ensures we're getting newest state of any actions
  ClearCache()

  local target = GetACRTarget()
  if target == nil then return false end
  if not target.attackable then return false end

  activeTrickAttack = GetTargetDebuff(Buffs.TrickAttack)

  local playerHasTCJ        = PlayerHasBuff(Buffs.TenChiJin)
  local playerHasMudra      = PlayerHasBuff(Buffs.Mudra)
  local playerHasKamaitachi = PlayerHasBuff(Buffs.KamaitachiReady)

  if playerHasTCJ then
    if not usedFuma then
      if CastOnTargetIfPossible(Skills.TCJFuma) then
        usedFuma = true
        return true
      end
    end

    if not usedRaiton then
      if CastOnTargetIfPossible(Skills.TCJRaiton) then
        usedRaiton = true
        return true
      end
    end

    if not usedSuiton then
      if CastOnTargetIfPossible(Skills.TCJSuiton) then
        usedSuiton = true
        return true
      end
    end

    return false
  end

  if playerHasMudra then
    if CastOnSelf(Skills.Ninjutsu) then return true end
    if CastOnTarget(Skills.Ninjutsu) then return true end
    return false
  end

  if playerHasKamaitachi then
    if CastOnTarget(Skills.Kamaitachi) then return true end
    if CastOnTarget(Skills.Bunshin) then return true end
    return false
  end

  local nearby = GetNearbyEnemies(10)

  if MaintainHuton() then return true end

  if Player.hp.percent < 35 then
    if CastOnSelfIfPossible(Skills.Bloodbath) then return true end
  end

  if profile.RaijuEnabled then
    if UseRaiju(#nearby) then
      return true
    end
  end

  if profile.NinkiEnabled then
    if ManageNinki(#nearby) then
      return true
    end
  end

  if profile.TCJEnabled then
    if TCJ() then
      return true
    end
  end

  -- TA becomes priority when Suiton is active
  if profile.TAEnabled then
    if CastOnTargetIfPossible(Skills.TrickAttack) then return true end
  end

  if profile.AssassinateEnabled then
    if TrickAttackIsActive() and #nearby < 3 then
      if ReadyCast(target.id, Skills.Assassinate, Skills.DreamWithinADream) then return true end
    end
  end

  if profile.MeisuiEnabled then
    if PlayerHasBuff(Buffs.Suiton) and IsOnCooldown(Skills.TrickAttack) then
      if CastOnSelfIfPossible(Skills.Meisui) then
        return true
      end
    end
  end

  if profile.NinjutsuEnabled then
    if Ninjutsu(#nearby) then
      return true
    end

    -- Priority of Kassatsu is not very high
    -- We just need to throw it into our rotation on CD
    if not IsNinjutsuReady() and not PlayerHasBuff(Buffs.Mudra) then
      if CastOnSelfIfPossible(Skills.Kassatsu) then return true end
    end
  end

  if profile.ComboEnabled then
    if BasicCombo(#nearby) then
      return true
    end
  end

  if profile.ThrowingEnabled then
    if CastOnTargetIfPossible(Skills.ThrowingDagger) then
      return true
    end
  end

  return false
end

-- The Draw() function provides a place where a developer can show custom options.
function profile.Draw()
  profile.AOEEnabled = GUI:Checkbox("AOE Enabled", profile.AOEEnabled)
  profile.ComboEnabled = GUI:Checkbox("Combo Enabled", profile.ComboEnabled)
  profile.NinkiEnabled = GUI:Checkbox("Ninki Enabled", profile.NinkiEnabled)
  profile.NinjutsuEnabled = GUI:Checkbox("Ninjutsu Enabled", profile.NinjutsuEnabled)
  profile.RaijuEnabled = GUI:Checkbox("Raiju Enabled", profile.RaijuEnabled)
  profile.TCJEnabled = GUI:Checkbox("Ten Chi Jin", profile.TCJEnabled)
  profile.ACEnabled = GUI:Checkbox("Armor Crush", profile.ACEnabled)
  profile.ThrowingEnabled = GUI:Checkbox("Throwing Dagger", profile.ThrowingEnabled)
  profile.AssassinateEnabled = GUI:Checkbox("Assassinate", profile.AssassinateEnabled)
  profile.MeisuiEnabled = GUI:Checkbox("Meisui", profile.MeisuiEnabled)
  profile.TAEnabled = GUI:Checkbox("Trick Attack", profile.TAEnabled)
end

-- The OnLoad() function is fired when a profile is prepped and loaded by ACR.
function profile.OnLoad()
  profile.ComboEnabled = ACR.GetSetting("OpenACR_Ninja_ComboEnabled", true)
  profile.NinkiEnabled = ACR.GetSetting("OpenACR_Ninja_NinkiEnabled", true)
  profile.AOEEnabled = ACR.GetSetting("OpenACR_Ninja_AOEEnabled", true)
  profile.NinjutsuEnabled = ACR.GetSetting("OpenACR_Ninja_NinjutsuEnabled", true)
  profile.RaijuEnabled = ACR.GetSetting("OpenACR_Ninja_RaijuEnabled", true)
  profile.TCJEnabled = ACR.GetSetting("OpenACR_Ninja_TenChiJinEnabled", true)
  profile.ACEnabled = ACR.GetSetting("OpenACR_Ninja_ArmorCrushEnabled", true)
  profile.ThrowingEnabled = ACR.GetSetting("OpenACR_Ninja_ThrowingDaggerEnabled", true)
  profile.AssassinateEnabled = ACR.GetSetting("OpenACR_Ninja_AssassinateEnabled", true)
  profile.MeisuiEnabled = ACR.GetSetting("OpenACR_Ninja_MeisuiEnabled", true)
  profile.TAEnabled = ACR.GetSetting("OpenACR_Ninja_TrickAttackEnabled", true)
end

-- The OnClick function is fired when a user clicks on the ACR party interface.
-- It accepts 5 parameters:
-- mouse /int/ - Possible values are 0 (Left-click), 1 (Right-click), 2 (Middle-click)
-- shiftState /bool/ - Is shift currently pressed?
-- controlState /bool/ - Is control currently pressed?
-- altState /bool/ - Is alt currently pressed?
-- entity /table/ - The entity information for the party member that was clicked on.
function profile.OnClick(mouse,shiftState,controlState,altState,entity)

end

-- The OnUpdate() function is fired on the gameloop, like any other OnUpdate function found in FFXIVMinion code.
function profile.OnUpdate(event, tickcount)
end

-- Return the profile to ACR, so it can be read.
return profile