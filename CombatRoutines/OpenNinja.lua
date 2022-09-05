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

local AOE = false
local currentMudra = nil
local lastFrameActive = false

local Buffs = {
  Mudra       = 496,
  TrickAttack = 3254,
  Mug         = 638,
  RaijuReady  = 0,
  Doton       = 501,
  Kassatsu    = 497,
  Suiton      = 507 
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
  Kassatsu        = 2264,
  ArmorCrush      = 3563,
  TenChiJin       = 7403,
  SecondWind      = 7541,

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

  DreamWithinADream = 3566,
    
  -- Basic Combo
  SpinningEdge    = 2240,
  GustSlash       = 2242,
  AeolianEdge     = 2255,

  -- Ninki
  Meisui          = 1648,
  Bunshin         = 1649,
  Bhavacakra      = 7402,
  Hellfrog        = 7401
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

local function IsNinjutsuReady()
  local offCd = not ActionList:Get(1, Skills.Ten).isoncd
    and not ActionList:Get(1, Skills.Chi).isoncd
    and not ActionList:Get(1, Skills.Jin).isoncd
  return PlayerHasBuff(Buffs.Kassatsu) or offCd
end

local function SetMudra(mudra)
  if currentMudra ~= nil then return false end
  currentMudra = table.deepcopy(mudra, true)
  lastFrameActive = false
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
  local useKassatsu = profile.SkillEnabled.Kassatsu
  local hasKassatsu = PlayerHasBuff(Buffs.Kassatsu)

  if not IsNinjutsuReady() and useKassatsu then
    local Kassatsu = ActionList:Get(1, Skills.Kassatsu);
    if Kassatsu:IsReady() then return Kassatsu:Cast() end
  end

  if hasKassatsu or IsNinjutsuReady() then
    if numNearby > 2 then
      if profile.SkillEnabled.Doton then
        if not PlayerHasBuff(Buffs.Doton) then
          return SetMudra(Mudras.Doton)
        end
      end

      if PlayerHasBuff(Buffs.Kassatsu)
        and profile.SkillEnabled.Goka then
        return SetMudra(Mudras.Goka);
      end
      
      return SetMudra(Mudras.Katon);
    else
      -- Use Suiton to set up Trick Attack when there is less than 20 seconds left on Trick Attack's cooldown.
      if profile.SkillEnabled.Suiton then
        local TrickAttack = ActionList:Get(1, Skills.TrickAttack)
        if TrickAttack.cdmax - TrickAttack.cd < 20 and not PlayerHasBuff(Buffs.Suiton) then
          return SetMudra(Mudras.Suiton)
        end
      end

      if profile.SkillEnabled.Doton then
        if numNearby > 1 and not PlayerHasBuff(Buffs.Doton) then
          return SetMudra(Mudras.Doton)
        end
      end

      local hasKassatsu = PlayerHasBuff(Buffs.Kassatsu)
      if numNearby > 1 and profile.SkillEnabled.Goka and hasKassatsu then
        return SetMudra(Mudras.Goka) -- Goka Mekkyaku for multi-target
      elseif profile.SkillEnabled.Goka and hasKassatsu then
        return SetMudra(Mudras.Hyosho) -- Hyosho Ranryu for single-target
      end

      if profile.SkillEnabled.Raiton then
        return SetMudra(Mudras.Raiton)
      end
    end
  end

  return false
end

local function CastIfReady(skillId, targetId)
  local action = ActionList:Get(1, skillId);
  if table.valid(action) then
    if targetId ~= nil then
      if action:IsReady(targetId) then
        if action:Cast(targetId) then
          return true
        end
      end
    else
      if action:IsReady() then
        if action:Cast() then
          return true
        end
      end
    end
  end

  return false
end

local function BasicCombo(numNearby, target)
  if not profile.ComboEnabled then return false end

  if numNearby > 2 then    
    if Player.lastcomboid == Skills.DeathBlossom then
      return CastIfReady(Skills.HakkeMujinsatsu)
    else
      return CastIfReady(Skills.DeathBlossom)
    end
  else
    if Player.lastcomboid == Skills.GustSlash then
      -- If you have more than 30 seconds left on your Huton buff, use Aeolian Edge as your combo ender instead.
      if Player.gauge[2] > 30000 then
        return CastIfReady(Skills.AeolianEdge, target.id)
      end
    elseif Player.lastcomboid == Skills.SpinningEdge then
      return CastIfReady(Skills.GustSlash, target.id)
    else
      return CastIfReady(Skills.SpinningEdge, target.id)
    end
  end

  return false
end

function UseRaiju(numNearby, target)
  if not profile.SkillEnabled.FleetingRaiju and not profile.SkillEnabled.ForkedRaiju then
    return false
  end

  if numNearby > 2 then return false end
  if not PlayerHasBuff(Buffs.RaijuReady) then
    return false
  end

  local FleetingRaiju = ActionList:Get(1, Skills.FleetingRaiju);
  local ForkedRaiju = ActionList:Get(1, Skills.ForkedRaiju);

  -- Should automatically calculate distance, so if not fleeting (standing)
  --  then we cast Forked (teleports to target)
  if FleetingRaiju:IsReady(target.id) then
    return FleetingRaiju:Cast(target.id)
  elseif ForkedRaiju:IsReady(target.id) then
    return ForkedRaiju:Cast(target.id)
  end

  return false
end

local function MaintainHuton(target)
  -- If player doesn't have Huton, must cast.
  local hutonTimeleft = Player.gauge[2]
  local hasHuton = hutonTimeleft > 0
  if not hasHuton then
    return SetMudra(Mudras.Huton)
  end

  if hutonTimeleft < 30000 and profile.SkillEnabled.ArmorCrush then
    local action = ActionList:Get(1, Skills.ArmorCrush);
    local isImmediate = Player.gauge[2] <= 3000
    if action:IsReady(target.id) then
      if isImmediate or Player.lastcomboid == Skills.GustSlash then
        if action:Cast(target.id) then
          return true
        else
          d("Failed to cast ArmorCrush")
        end
      end
    end
  end

  return false
end

local function HandleMudra(target)
  local isFinished = currentMudra[1] == nil

  if isFinished then
    local jutsu = ActionList:Get(1, Skills.Ninjutsu);
    local wasCast = jutsu:Cast(target.id) or jutsu:Cast(Player.id)
    if wasCast then currentMudra = nil end
    return wasCast
  else
    local action = ActionList:Get(1, currentMudra[1]);
    if action:Cast() then
      table.remove(currentMudra, 1)
      return true
    end
  end

  return false
end

local function ManageNinki(numNearby, target)
  if not profile.NinkiEnabled then return false end

  local ninkiPower = Player.gauge[1]

  -- Use Bunshin as soon as it is off cooldown.
  local Bunshin = ActionList:Get(1, Skills.Bunshin);
  if Bunshin:IsReady(Player.id) then
    if Bunshin:Cast(Player.id) then
      return true
    else
      d("Failed to cast Bunshin")
    end
  end

  -- Ninki Management
  -- The big thing is that you will never want to overcap it
  if numNearby <= 2 then
    -- If Trick Attack is up, use all your Ninki on Bhavacakra.
    -- If you are about to overcap Ninki and Trick Attack is not up, use Bhavacakra once.
    local Bhavacakra = ActionList:Get(1, Skills.Bhavacakra)
    if Bhavacakra:IsReady(target.id) then
      local TrickAttackDebuff = GetTargetDebuff(target, Buffs.TrickAttack)
      if TrickAttackDebuff ~= nil then
        if Bhavacakra:Cast(target.id) then return true end
      elseif ninkiPower >= 90 then
        if Bhavacakra:Cast(target.id) then return true end
      end
    end
  else
    -- Our ninki will now be used for AoE as well.
    -- This means using Hellfrog Medium instead of Bhavacakra
    local Hellfrog = ActionList:Get(1, Skills.Hellfrog)
    if Hellfrog:IsReady() then
      if Hellfrog:Cast() then
        return true
      else
        d("Failed to cast hellfrog")
      end
    end
  end

  return false
end

-- The Cast() function is where the magic happens.
-- Action code should be called and fired here.
function profile.Cast()
  if Player == nil then return false end

  local target = Player:GetTarget()
  if target == nil then return false end
  
  -- ensures we're getting newest state of any actions
  ClearCache()

  -- Don't do anything except activate the mudra combo when mudra is active...
  if currentMudra ~= nil then
    -- stuckproofing
    local isMudraActive = PlayerHasBuff(Buffs.Mudra);
    if lastFrameActive and not isMudraActive then
      currentMudra = nil
      return false
    end
    
    lastFrameActive = isMudraActive
    return HandleMudra(target)
  end

  local attackables = MEntityList("alive,attackable");
  if not table.valid(attackables) then
    return false
  end

  -- Gets targets within range of AOE attacks centered on player
  local nearby = FilterByProximity(attackables, Player.pos, 10);
  if not table.valid(nearby) then
    nearby = {}
  end

  if MaintainHuton(target) then return true end
  if UseRaiju(#nearby, target) then return true end
  if ManageNinki(#nearby, target) then return true end
  if Ninjutsu(#nearby) then return true end

  if profile.SkillEnabled.TrickAttack then
    if SkillIsActuallyReadyOnTarget(Skills.TrickAttack, target) then
      if CastOnTarget(Skills.TrickAttack, target) then return true end
    end
  end

  if profile.SkillEnabled.Assassinate then
    -- Only use DWD/Assassinate when TrickAttack is up
    local TrickAttackDebuff = GetTargetDebuff(target, Buffs.TrickAttack)
    if TrickAttackDebuff ~= nil and #nearby < 3 then
      local assassinate = ActionList:Get(1, Skills.Assassinate)
      local dwd = ActionList:Get(1, Skills.DreamWithinADream)
      if not assassinate.isoncd and not dwd.isoncd then
        -- Will cast both
        if assassinate:Cast(target.id) then
          return true
        end
      end
    end
  end

  if BasicCombo(#nearby, target) then return true end

  if SkillIsActuallyReadyOnTarget(Skills.ThrowingDagger, target) then
    if CastOnTarget(Skills.ThrowingDagger, target) then return true end
  end

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
    profile.SkillEnabled[skill] = GUI:Checkbox(k, profile.SkillEnabled[skill])
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

end

-- Return the profile to ACR, so it can be read.
return profile