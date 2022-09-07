-- From top to bottom, the order of operations of casting.
local profile = {
  GUI = {
    open = false,
    visible = true,
    name = "OpenACR Ninja"
  },

  classes = {
    [FFXIV.JOBS.NINJA] = true,
    [FFXIV.JOBS.ROGUE] = true,
  },

  ComboEnabled   = true,
  NinkiEnabled   = true,
  SkillEnabled   = {}
}

local AwaitDo = ml_global_information.AwaitDo

local AOE = false
local PerformingMudra = false

local activeTrickAttack = nil
local lastFrameActive = false

local Buffs = {
  Mudra       = 496,
  TrickAttack = 3254,
  Mug         = 638,
  RaijuReady  = 0,
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

-- TODO: Use non-GCD skills in same loop
local Skills = {
  ShadeShift      = 2241,
  Hide            = 2245,
  Assassinate     = 2246,
  ThrowingDagger  = 2247,
  Mug             = 2248,
  DeathBlossom    = 2254,
  TrickAttack     = 2258,
  Ninjutsu        = 2260,
  Ten             = 2259,
  Chi             = 2261,
  Jin             = 2263,
  Shukuchi        = 2262,
  Kassatsu        = 2264, -- No GCD
  ArmorCrush      = 3563,
  TenChiJin       = 7403,
  SecondWind      = 7541,
  Bloodbath       = 7542, -- No GCD

  -- Mudras
  Fuma   = 2265,
  Katon  = 2266,
  Raiton = 2267,
  Hyoton = 2268,
  Hyosho = 16492,
  Goka   = 16491,
  Doton  = 2270,
  Huton  = 2269,
  Suiton = 2271,

  ForkedRaiju     = 25777,
  FleetingRaiju   = 25778,
  HakkeMujinsatsu = 16488,
  Kamaitachi      = 16493,

  DreamWithinADream = 3566, -- No GCD
    
  -- Basic Combo
  SpinningEdge    = 2240,
  GustSlash       = 2242,
  AeolianEdge     = 2255,

  -- Ninki
  Meisui          = 16489,
  Bunshin         = 16493,
  Bhavacakra      = 7402, -- No GCD
  Hellfrog        = 7401  -- NO GCD
}

-- If it's not enabled it's not a part of the IcyVeins rotation...
-- devnote: elements without a key are stacked from 1 - inf
local Mudras = {
  Fuma   = { Skills.Ten, Skills.Ten },
  Katon  = { Skills.Chi, Skills.Ten },
  Raiton = { Skills.Ten, Skills.Chi },
  Hyoton = { Skills.Ten, Skills.Jin },
  Hyosho = { Skills.Ten, Skills.Jin },
  Goka   = { Skills.Chi, Skills.Ten },
  Doton  = { Skills.Ten, Skills.Jin, Skills.Chi },
  Huton  = { Skills.Jin, Skills.Chi, Skills.Ten },
  Suiton = { Skills.Ten, Skills.Chi, Skills.Jin },
}

-- TODO: Handle Mug the same
local function TrickAttackIsActive()
  return activeTrickAttack ~= nil
end

local function IsNinjutsuReady()
  local offCd = not ActionList:Get(1, Skills.Ten).isoncd
    and not ActionList:Get(1, Skills.Chi).isoncd
    and not ActionList:Get(1, Skills.Jin).isoncd
  return PlayerHasBuff(Buffs.Kassatsu) or offCd
end

local function ComboMudra(mudra)
  PerformingMudra = true;

  local first = ActionList:Get(1, mudra[1]);
  local second = ActionList:Get(1, mudra[2]);
  local third = nil
  
  if mudra[3] ~= nil then
    third = ActionList:Get(1, mudra[3]);
  end

  AwaitDo(0, 500, first:Cast(), nil, function()
    AwaitDo(0, 500, second:Cast(), nil, function()
      if third == nil then
        PerformingMudra = false
        d("Casted Mudra: " .. first.name .. ', ' .. second.name)
        return
      end

      AwaitDo(0, 500, third:Cast(), nil, function()
        d("Casted Mudra: " .. first.name .. ', ' .. second.name .. ', ' .. third.name)
        PerformingMudra = false
      end)
    end)
  end)

  return true
end

local function Opener()
  -- 11 seconds before pull JCT -> Huton
  -- Hide
  -- TCJ -> Suiton cast 1s before pull
  -- At 1 second on the countdown, use Suiton Icon Suiton then immediately use Kassatsu Icon Kassatsu
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
  if profile.SkillEnabled.Kassatsu and not IsNinjutsuReady() then
    local Kassatsu = ActionList:Get(1, Skills.Kassatsu);
    if Kassatsu:IsReady() then return Kassatsu:Cast() end
  end

  if IsNinjutsuReady() then
    if numNearby > 2 then
      if profile.SkillEnabled.Doton then
        if not PlayerHasBuff(Buffs.Doton) then
          return ComboMudra(Mudras.Doton)
        end
      end

      if PlayerHasBuff(Buffs.Kassatsu)
        and profile.SkillEnabled.Goka then
        return ComboMudra(Mudras.Goka);
      end
      
      return ComboMudra(Mudras.Katon);
    else
      -- Use Suiton to set up Trick Attack when there is less than 20 seconds left on Trick Attack's cooldown.
      if profile.SkillEnabled.Suiton and not PlayerHasBuff(Buffs.Suiton) then
        local TrickAttack = ActionList:Get(1, Skills.TrickAttack)
        if TrickAttack.cdmax - TrickAttack.cd < 20 then
          return ComboMudra(Mudras.Suiton)
        end
      end

      if profile.SkillEnabled.Doton then
        if numNearby > 1 and not PlayerHasBuff(Buffs.Doton) then
          return ComboMudra(Mudras.Doton)
        end
      end

      local hasKassatsu = PlayerHasBuff(Buffs.Kassatsu)
      if numNearby > 1 and profile.SkillEnabled.Goka and hasKassatsu and IsCapable(Skills.Goka) then
        return ComboMudra(Mudras.Goka) -- Goka Mekkyaku for multi-target
      elseif profile.SkillEnabled.Hyosho and hasKassatsu and IsCapable(Skills.Hyosho) then
        return ComboMudra(Mudras.Hyosho) -- Hyosho Ranryu for single-target
      end

      if profile.SkillEnabled.Raiton then
        return ComboMudra(Mudras.Raiton)
      end
    end
  end

  return false
end

local function BasicCombo(numNearby)
  if not profile.ComboEnabled then return false end

  if numNearby > 2 then    
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
  if not profile.SkillEnabled.FleetingRaiju and not profile.SkillEnabled.ForkedRaiju then
    return false
  end

  if numNearby > 2 then return false end
  if not PlayerHasBuff(Buffs.RaijuReady) then
    return false
  end

  return CastOnTargetIfPossible(Skills.FleetingRaiju)
    or CastOnTargetIfPossible(Skills.ForkedRaiju);
end

local function MaintainHuton()
  -- If player doesn't have Huton, must cast.
  local hutonTimeleft = Player.gauge[2]
  local hasHuton = hutonTimeleft > 0
  if not hasHuton and IsNinjutsuReady() then
    return ComboMudra(Mudras.Huton)
  end

  if hutonTimeleft < 30000 and profile.SkillEnabled.ArmorCrush then
    local isImmediate = Player.gauge[2] <= 3000
    if isImmediate or Player.lastcomboid == Skills.GustSlash then
      if CastOnTargetIfPossible(Skills.ArmorCrush) then return true end
    end
  end

  return false
end

local function ManageNinki(numNearby)
  if not profile.NinkiEnabled then return false end
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
  if numNearby <= 2 then
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

local function TCJ()
  if not profile.SkillEnabled.TenChiJin then return false end
  if not TrickAttackIsActive() then return false end

  -- We only ever want to do this if Meisui is up
  if IsOnCooldown(Skills.Meisui) then return false end

  return CastOnSelfIfPossible(Skills.TenChiJin)
end

local lasttime = 0

-- The Cast() function is where the magic happens.
-- Action code should be called and fired here.
function profile.Cast()
  -- Runs on a "separate" thread, so we "lock" until it's done
  if PerformingMudra then return false end

  -- Update 20x a second?
  if TimeSince(lasttime) < 50 then return false end
  lastTime = Now()

  if Player == nil then return false end
  if not ActionList:IsReady() then return false end
  
  -- ensures we're getting newest state of any actions
  ClearCache()

  -- TODO: Add Feint
  -- TODO: Add Shukuchi

  local target = GetACRTarget()
  if target == nil then return false end
  if not target.attackable then return false end

  activeTrickAttack = GetTargetDebuff(Buffs.TrickAttack)

  local playerHasTCJ        = PlayerHasBuff(Buffs.TenChiJin)
  local playerHasMudra      = PlayerHasBuff(Buffs.Mudra)
  local playerHasKamaitachi = PlayerHasBuff(Buffs.KamaitachiReady)

  if playerHasTCJ then
    if CastOnTarget(Skills.Ten) then return true end
    if CastOnTarget(Skills.Chi) then return true end
    if CastOnTarget(Skills.Jin) then return true end
    return false
  end

  -- FORCE CAST FOR MUDRA BEFORE ANYTHING
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

  if #nearby > 0 then
    d('Num Nearby: ' .. tostring(#nearby))
  end

  if MaintainHuton() then return true end

  if Player.hp.percent < 35 then
    if CastOnSelfIfPossible(Skills.Bloodbath) then return true end
  end

  if UseRaiju(#nearby) then return true end
  if ManageNinki(#nearby) then return true end
  if TCJ() then return true end

  -- TA becomes priority when Suiton is active
  if profile.SkillEnabled.TrickAttack then
    if CastOnTargetIfPossible(Skills.TrickAttack) then return true end
  end

  if profile.SkillEnabled.Meisui then
    if PlayerHasBuff(Buffs.Suiton) and IsOnCooldown(Skills.TrickAttack) then
      if CastOnSelfIfPossible(Skills.Meisui) then
        return true
      end
    end
  end

  if Ninjutsu(#nearby) then return true end

  if profile.SkillEnabled.Assassinate then
    if TrickAttackDebuff ~= nil and #nearby < 3 then
      if CastOnTargetIfPossible(Skills.Assassinate) then return true end
    end    
  end

  if BasicCombo(#nearby) then return true end
  if CastOnTargetIfPossible(Skills.ThrowingDagger) then return true end

  return false
end

-- The Draw() function provides a place where a developer can show custom options.
function profile.Draw()
  if not profile.GUI.open then
    return
  end

  profile.GUI.visible, profile.GUI.open = GUI:Begin(profile.GUI.name, profile.GUI.open)
  if not profile.GUI.visible then
    return
  end
  
  profile.ComboEnabled   = GUI:Checkbox("Combo Enabled", profile.ComboEnabled)
  profile.NinkiEnabled   = GUI:Checkbox("Ninki Enabled", profile.NinkiEnabled)

  for skill,_ in pairs(Skills) do
    profile.SkillEnabled[skill] = GUI:Checkbox(skill, profile.SkillEnabled[skill])
  end

  GUI:End()
end

-- Adds a customizable header to the top of the ffxivminion task window.
function profile.DrawHeader()

end

-- Adds a customizable footer to the top of the ffxivminion task window.
function profile.DrawFooter()

end

-- The OnOpen() function is fired when a user pressed "View Profile Options" on the main ACR window.
function profile.OnOpen()
  -- Set our GUI table //open// variable to true so that it will be drawn.
  profile.GUI.open = true
end

-- The OnLoad() function is fired when a profile is prepped and loaded by ACR.
function profile.OnLoad()
  profile.ComboEnabled   = ACR.GetSetting("OpenACR_Ninja_ComboEnabled", true)
  profile.NinkiEnabled   = ACR.GetSetting("OpenACR_Ninja_NinkiEnabled", true)

  for skill,_ in pairs(Skills) do
    profile.SkillEnabled[skill] = ACR.GetSetting("OpenACR_Ninja_" .. skill .. "Enabled", true)
  end
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
  local mudra = GetPlayerBuff(Buffs.Mudra)
  if mudra ~= nil then
    if mudra.stacks ~= lastMudraStacks then
      wasMudraUpdated = true
    end
  end
end

-- Return the profile to ACR, so it can be read.
return profile