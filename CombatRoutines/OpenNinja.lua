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
}

local AOE = false

local Buffs = {
  Mudra = { type = 0, id = 496 },
  TrickAttack = { type = 0, id = 3254 },
  Mug = { type = 0, id = 638 },
  RaijuReady = { type = 0, id = 0 },
  Doton = { type = 0, id = 501 },
  Kassatsu = { type = 0, id = 497 },
  Suiton = { type = 0, id = 507 }
}

local PvPSkills = {
  Bunshin         = { type = 1, id = 29511, enabled = true },
  FleetingRaiju   = { type = 1, id = 29707, enabled = true },
  Meisui          = { type = 1, id = 29508, enabled = true },
  ForkedRaiju     = { type = 1, id = 29510, enabled = true },
}

local Skills = {
  SpinningEdge    = { type = 1, id = 2240, enabled = true },
  ShadeShift      = { type = 1, id = 2241, enabled = true },
  GustSlash       = { type = 1, id = 2242, enabled = true },
  Hide            = { type = 1, id = 2245, enabled = true },
  Assassinate     = { type = 1, id = 2246, enabled = true },
  ThrowingDagger  = { type = 1, id = 2247, enabled = true },
  Mug             = { type = 1, id = 2248, enabled = true },
  DeathBlossom    = { type = 1, id = 2254, enabled = true }, -- FAN AOE
  AeolianEdge     = { type = 1, id = 2255, enabled = true },
  TrickAttack     = { type = 1, id = 2258, enabled = true },
  Ten             = { type = 1, id = 2259, enabled = true },
  Ninjutsu        = { type = 1, id = 2260, enabled = true },
  Chi             = { type = 1, id = 2261, enabled = true },
  Shukuchi        = { type = 1, id = 2262, enabled = true },
  Jin             = { type = 1, id = 2263, enabled = true },
  Kassatsu        = { type = 1, id = 2264, enabled = true },
  FumaShuriken    = { type = 1, id = 2265, enabled = true },
  Katon           = { type = 1, id = 2266, enabled = true },
  Raiton          = { type = 1, id = 2267, enabled = true },
  Huton           = { type = 1, id = 2269, enabled = true },
  Doton           = { type = 1, id = 2270, enabled = true },
  Suiton          = { type = 1, id = 2271, enabled = true },
  ArmorCrush      = { type = 1, id = 3563, enabled = true },
  Hellfrog        = { type = 1, id = 7401, enabled = true },
  Bhavacakra      = { type = 1, id = 7402, enabled = true },
  TenChiJin       = { type = 1, id = 7403, enabled = true },
  SecondWind      = { type = 1, id = 7541, enabled = true },

  ForkedRaiju     = { type = 1, id = 25777, enabled = true },
  FleetingRaiju   = { type = 1, id = 25778, enabled = true },
  Meisui          = { type = 1, id = 16489, enabled = true },
  Bunshin         = { type = 1, id = 16493, enabled = true }
}

local function IsCapable(skill)
  if not HasAction(skill.id, skill.type) then
    return false
  end

  local action = ActionList:Get(skill.type, skill.id)
  return action.level <= Player.level
end

local function GetTargetDebuff(target, buff)
  for i,_ in ipairs(target.buffs) do
    if target.buffs[i].id == buff.id then
      return target.buffs[i]
    end
  end

  return nil
end

local function PlayerHasBuff(buff)
  for i,_ in ipairs(Player.buffs) do
    if Player.buffs[i].id == buff.id then
      return true
    end
  end

  return false
end

local function GetSkill(skill) return ActionList:Get(skill.type, skill.id) end

local function GetMudra()
  local stacks = 0
  for i,v in ipairs(Player.buffs) do
    if Player.buffs[i].id == Buffs.Mudra.id then
      stacks = Player.buffs[i].stacks
      break
    end
  end

  if stacks == 0 or stacks > 16 then
    local allOrNone = stacks / 16 >= 1
    return allOrNone, allOrNone, allOrNone
  end

  -- from right to left...
  local first = stacks % 4 -- first 2 bits
  local second = math.floor(stacks / 4) % 4 -- second 2 bits

  local ten = first == 1 or second == 1
  local chi = first == 2 or second == 2
  local jin = first == 3 or second == 3

  return ten, chi, jin
end

-- second and third are optional
local function ComboForNinjutsu(first, second, third)
  local isTen, isChi, isJin = GetMudra()

  local isFirst = (first.id == Skills.Ten.id and isTen)
    or (first.id == Skills.Chi.id and isChi)
    or (first.id == Skills.Jin.id and isJin)

  local isSecond = true and second == nil -- lua ternary-ish
    or (second.id == Skills.Ten.id and isTen)
    or (second.id == Skills.Chi.id and isChi)
    or (second.id == Skills.Jin.id and isJin)

  local isThird = true and third == nil -- lua ternary-ish
    or (third.id == Skills.Ten.id and isTen)
    or (third.id == Skills.Chi.id and isChi)
    or (third.id == Skills.Jin.id and isJin)

  if not isFirst then
    local action = ActionList:Get(first.type, first.id)
    if action:IsReady(Player.id) then
      return action:Cast(Player.id)
    end

    return false
  end

  if not isSecond then
    local action = ActionList:Get(second.type, second.id)
    if action:IsReady(Player.id) then
      return action:Cast(Player.id)
    end

    return false
  end

  if not isThird then
    local action = ActionList:Get(third.type, third.id)
    if action:IsReady(Player.id) then
      return action:Cast(Player.id)
    end

    return false
  end

  local action = ActionList:Get(Skills.Ninjutsu.type, Skills.Ninjutsu.id)
  if action:IsReady(targetId) then
    return action:Cast(targetId)
  elseif action:IsReady(Player.id) then
    return action:Cast(Player.id)
  end

  return false
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

local function AOENinjutsu()
  d('Performing AOE Ninjutsu')
  local Kassatsu = ActionList:Get(Skills.Kassatsu.type, Skills.Kassatsu.id);

  if not PlayerHasBuff(Buffs.Doton) then
    d('Casting Doton')
    return ComboForNinjutsu(Skills.Ten, Skills.Jin, Skills.Chi)

  elseif Kassatsu:IsReady(Player.id) then
    d('Casting Kassatsu')
    return Kassatsu:Cast(Player.id)

  else
    d('Casting Goka/Katon')
    return ComboForNinjutsu(Skills.Chi, Skills.Ten) -- Goka/Katon
  end

  return false
end

local function Ninjutsu(useDoton)
  --[[
  Two Targets:
    You will still use Suiton to set up Trick Attack, but now as well as Raiton, you will also be using Doton.
    - Keep Doton up as much as possible, assuming the enemies will stay in it for at least 12 seconds of the duration.
    - Use Goka Mekkyaku with Kassatsu inside Trick Attack assuming Doton is down.
    - Use Raiton if enemies die before full usage of another Doton.

  Single Target:
    Because Ninjutsu has two charges, we are able to go into every burst window with one full charge ready, and another one that will become ready to use during the burst window.
    This is achieved by only ever using 1 Suiton outside of Trick Attack and holding the other charges for Trick Attack.
    This means that you will use one ninjutsu charge on Suiton outside of Trick Attack, and two charges inside of Trick Attack.
  ]]--
  local TrickAttack = ActionList:Get(Skills.TrickAttack.type, Skills.TrickAttack.id)

  -- Use Suiton to set up Trick Attack when there is less than 20 seconds left on Trick Attack's cooldown.
  if TrickAttack.cdmax - TrickAttack.cd < 20 and not PlayerHasBuff(Buffs.Suiton) then
    local wasCast = ComboForNinjutsu(Skills.Ten, Skills.Chi, Skills.Jin)

    -- Check if it is returning false
    if wasCast then d('Combo for Suiton...') else d('Stopped Combo for Suiton?') end
    return wasCast
  end

  if useDoton and not PlayerHasBuff(Buffs.Doton) then
    local wasCast = ComboForNinjutsu(Skills.Ten, Skills.Jin, Skills.Chi)
    if wasCast then d('Combo for Doton...') end
    return wasCast
  end

  if TrickAttackDebuff ~= nil then
    d('Finishing TrickAttack Combo with Kassatsu and Goka/Raiton')
    if Kassatsu:IsReady(Player.id) then
      return Kassatsu:Cast(Player.id)
    end

    -- Goka Mekkyaku for multi-target
    if useDoton and PlayerHasBuff(Buffs.Kassatsu) then
      return ComboForNinjutsu(Skills.Chi, Skills.Ten)
    end

    -- If Trick Attack is up, use both your charges on Raiton and your extra Kassatsu on Hyosho Ranryu.
    return ComboForNinjutsu(Skills.Ten, Skills.Chi)
  end

  return false
end

local function IsNinjutsuReady()
  local isTen = ActionList:Get(1, Skills.Ten.id):IsReady(Player.id)
  local isChi = ActionList:Get(1, Skills.Chi.id):IsReady(Player.id)
  local isJin = ActionList:Get(1, Skills.Jin.id):IsReady(Player.id)

  return isTen or isChi or isJin
end

local function Doton()
  -- Ten Jin Chi

  local targetId = Player:GetTarget().id
  local doton = ActionList:Get(Skills.Doton.type, Skills.Doton.id)
  if doton:IsReady(targetId) then
    return doton:Cast(targetId)
  end
end

local function Katon()
  -- Chi Ten

  local targetId = Player:GetTarget().id
  local katon = ActionList:Get(Skills.Katon.type, Skills.Katon.id)
  if katon:IsReady(targetId) then
    return katon:Cast(targetId)
  end
end

local function Raiton()
  -- Ten Chi
  local ten = ActionList:Get(Skills.Ten.type, Skills.Ten.id)
  local chi = ActionList:Get(Skills.Chi.type, Skills.Chi.id)

  local wasTen = false
  local wasChi = false



  local targetId = Player:GetTarget().id
  local raiton = ActionList:Get(Skills.Raiton.type, Skills.Raiton.id)
  if raiton:IsReady(targetId) then
    return raiton:Cast(targetId)
  end
end

local function Suiton()
  -- Ten Chi Jin

  local targetId = Player:GetTarget().id
  local suiton = ActionList:Get(Skills.Suiton.type, Skills.Suiton.id)
  if suiton:IsReady(targetId) then
    return suiton:Cast(targetId)
  end
end

local function Huton()
  -- Jin Chi Ten

  local huton = ActionList:Get(Skills.Huton.type, Skills.Huton.id)
  if huton:IsReady(Player.id) then
    return huton:Cast(Player.id)
  end
end

local function Goka()
  -- Check for Kassatsu
  return Katon()
end

local function Hyosho()
  -- Check for Kassatsu
  -- Ten Jin
end

local function BasicCombo(targetId)
  local SpinningEdge = ActionList:Get(Skills.SpinningEdge.type, Skills.SpinningEdge.id)
  local GustSlash = ActionList:Get(Skills.GustSlash.type, Skills.GustSlash.id)
  local AeolianEdge = ActionList:Get(Skills.AeolianEdge.type, Skills.AeolianEdge.id)

  if Player.lastcomboid == Skills.GustSlash.id then
    -- If you have more than 30 seconds left on your Huton buff, use Aeolian Edge as your combo ender instead.
    if Player.gauge[2] > 30000 and AeolianEdge:IsReady(targetId) then
      return AeolianEdge:Cast(targetId)
    end

  elseif Player.lastcomboid == Skills.SpinningEdge.id then
    if GustSlash:IsReady(targetId) then
      return GustSlash:Cast(targetId)
    end

  elseif SpinningEdge:IsReady(targetId) then
    return SpinningEdge:Cast(targetId)
  end

  return false
end


-- The Cast() function is where the magic happens.
-- Action code should be called and fired here.
function profile.Cast()
  if Player == nil then return false end

  local target = Player:GetTarget()
  if target == nil then return false end

  local attackables = MEntityList("alive,attackable");
  if not table.valid(attackables) then
    return false
  end

  -- Gets targets within range of AOE attacks centered on player
  local nearby = FilterByProximity(attackables, Player.pos, 10);
  if not table.valid(nearby) then
    nearby = {}
  end

  local TrickAttackDebuff = GetTargetDebuff(target, Buffs.TrickAttack)
  local ninkiPower = Player.gauge[1]

  local hasHuton = Player.gauge[2] > 0
  if not hasHuton then
    -- Cast Huton
    return ComboForNinjutsu(Skills.Jin, Skills.Chi, Skills.Ten)
  end

  local doesHutonNeedRefreshed = Player.gauge[2] < 30000 and Skills.ArmorCrush.enabled
  if doesHutonNeedRefreshed then
    local action = ActionList:Get(Skills.ArmorCrush.type, Skills.ArmorCrush.id);
    local isImmediate = Player.gauge[2] < 15000
    if action:IsReady(target.id) then
      if isImmediate or Player.lastcomboid == Skills.GustSlash.id then
        d('Refreshing Huton with Armor Crush')
        return action:Cast(target.id)
      end
    end
  end

  if #nearby <= 2 and (Skills.FleetingRaiju.enabled or Skills.ForkedRaiju.enabled) then
    if PlayerHasBuff(Buffs.RaijuReady) then
      local FleetingRaiju = ActionList:Get(Skills.FleetingRaiju.type, Skills.FleetingRaiju.id);
      local ForkedRaiju = ActionList:Get(Skills.ForkedRaiju.type, Skills.ForkedRaiju.id);

      -- Should automatically calculate distance, so if not fleeting (standing)
      --  then we cast Forked (teleports to target)
      if FleetingRaiju:IsReady(target.id) then
        return FleetingRaiju:Cast(target.id)
      elseif ForkedRaiju:IsReady(target.id) then
        return ForkedRaiju:Cast(target.id)
      end
    end
  end

  if IsCapable(Skills.Bunshin) then
    d('Bunshin Capable')
    -- Use Bunshin as soon as it is off cooldown.
    if CastWhenReady(Skills.Bunshin) then return true end

    -- Ninki Management
    -- the big thing is that you will never want to overcap it
    if #nearby <= 2 then      
      -- If Trick Attack is up, use all your Ninki on Bhavacakra.
      if TrickAttackDebuff ~= nil then
        return CastWhenReady(Skills.Bhavacakra)

      -- If you are about to overcap Ninki and Trick Attack is not up, use Bhavacakra once.
      elseif ninkiPower >= 90 then
        return CastWhenReady(Skills.Bhavacakra)
      end

    else
      -- Our ninki will now be used for AoE as well.
      -- This means using Hellfrog Medium instead of Bhavacakra
      return CastWhenReady(Skills.Hellfrog)
    end
  end

  if IsNinjutsuReady() then
    if #nearby > 2 then
      if AOENinjutsu() then return true end
    else
      if Ninjutsu(#nearby == 2) then return true end
    end
  end

  local TrickAttack = ActionList:Get(Skills.TrickAttack.type, Skills.TrickAttack.id)
  if TrickAttack:IsReady(target.id) then
    return TrickAttack:Cast(target.id)
  elseif NormalCombo(target.id) then
    return true
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
  
  for skill,_ in pairs(Skills) do
    Skills[skill].enabled = GUI:Checkbox(skill, Skills[skill].enabled)
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
  for skill,_ in pairs(Skills) do
    local isDefaultEnabled = ActionList:Get(1, Skills[skill].id).level < Player.level
    Skills[skill].enabled = ACR.GetSetting("OpenACR_Ninja_" .. skill .. "Enabled", isDefaultEnabled)
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