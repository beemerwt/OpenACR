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
}

local AOE = false
local currentMudra = nil
local lastFrameActive = false

local Buffs = {
  Mudra       = { id = 496  },
  TrickAttack = { id = 3254 },
  Mug         = { id = 638  },
  RaijuReady  = { id = 0    },
  Doton       = { id = 501  },
  Kassatsu    = { id = 497  },
  Suiton      = { id = 507  }
}

local PvPSkills = {
  Bunshin         = { id = 29511, enabled = true },
  FleetingRaiju   = { id = 29707, enabled = true },
  Meisui          = { id = 29508, enabled = true },
  ForkedRaiju     = { id = 29510, enabled = true },
}

local Skills = {
  ShadeShift      = { id = 2241, enabled = true, buff = false },
  Hide            = { id = 2245, enabled = true, buff = true  },
  Assassinate     = { id = 2246, enabled = true, buff = false },
  ThrowingDagger  = { id = 2247, enabled = true, buff = false },
  Mug             = { id = 2248, enabled = true, buff = false },
  DeathBlossom    = { id = 2254, enabled = true, buff = false },
  TrickAttack     = { id = 2258, enabled = true, buff = false },
  Ninjutsu        = { id = 2260, enabled = true, buff = false },
  Ten             = { id = 2259, enabled = true, buff = true  },
  Chi             = { id = 2261, enabled = true, buff = true  },
  Jin             = { id = 2263, enabled = true, buff = true  },
  Shukuchi        = { id = 2262, enabled = true, buff = false },
  Kassatsu        = { id = 2264, enabled = true, buff = true  },
  ArmorCrush      = { id = 3563, enabled = true, buff = false },
  TenChiJin       = { id = 7403, enabled = true, buff = true  },
  SecondWind      = { id = 7541, enabled = true, buff = true  },

  ForkedRaiju     = { id = 25777, enabled = true, buff = false },
  FleetingRaiju   = { id = 25778, enabled = true, buff = false },
  HakkeMujinsatsu = { id = 16488, enabled = true, buff = true  },

  DreamWithinADream = { id = 3566, enabled = true, buff = false },
    
  -- Basic Combo
  SpinningEdge    = { id = 2240, enabled = true, buff = false },
  GustSlash       = { id = 2242, enabled = true, buff = false },
  AeolianEdge     = { id = 2255, enabled = true, buff = false },

  -- Ninki
  Meisui          = { id = 16489, enabled = true, buff = true  },
  Bunshin         = { id = 16493, enabled = true, buff = true  },
  Bhavacakra      = { id = 7402,  enabled = true, buff = false },
  Hellfrog        = { id = 7401,  enabled = true, buff = false },
}

-- If it's not enabled it's not a part of the IcyVeins rotation...
-- devnote: elements without a key are stacked from 1 - inf
Skills.Mudra = {
  Fuma   = { id = 2265,  enabled = false, buff = false, Skills.Ten, Skills.Ten },
  Katon  = { id = 2266,  enabled = true,  buff = false, Skills.Chi, Skills.Ten },
  Raiton = { id = 2267,  enabled = true,  buff = false, Skills.Ten, Skills.Chi },
  Hyoton = { id = 2268,  enabled = false, buff = false, Skills.Ten, Skills.Jin },
  Hyosho = { id = 16492, enabled = true,  buff = false, Skills.Ten, Skills.Jin },
  Goka   = { id = 16491, enabled = true,  buff = false, Skills.Chi, Skills.Ten },
  Doton  = { id = 2270,  enabled = true,  buff = false, Skills.Ten, Skills.Jin, Skills.Chi },
  Huton  = { id = 2269,  enabled = true,  buff = true,  Skills.Jin, Skills.Chi, Skills.Ten },
  Suiton = { id = 2271,  enabled = true,  buff = false, Skills.Ten, Skills.Chi, Skills.Jin }
}

local function IsNinjutsuReady()
  local offCd = not ActionList:Get(1, Skills.Ten.id).isoncd
    and not ActionList:Get(1, Skills.Chi.id).isoncd
    and not ActionList:Get(1, Skills.Jin.id).isoncd
  return PlayerHasBuff(Buffs.Kassatsu) or offCd
end

local function SetMudra(skill)
  if currentMudra ~= nil then return false end
  currentMudra = table.deepcopy(skill, true)
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
  if numNearby > 2 then
    if Skills.Mudra.Doton.enabled then
      if not PlayerHasBuff(Buffs.Doton) then
        return SetMudra(Skills.Mudra.Doton)
      end
    end

    if PlayerHasBuff(Buffs.Kassatsu)
      and Skills.Mudra.Goka.enabled then
      return SetMudra(Skills.Mudra.Goka);
    end
    
    return SetMudra(Skills.Mudra.Katon);
  else
    -- Use Suiton to set up Trick Attack when there is less than 20 seconds left on Trick Attack's cooldown.
    if Skills.Mudra.Suiton.enabled then
      local TrickAttack = ActionList:Get(1, Skills.TrickAttack.id)
      if TrickAttack.cdmax - TrickAttack.cd < 20 and not PlayerHasBuff(Buffs.Suiton) then
        return SetMudra(Skills.Mudra.Suiton)
      end
    end

    if Skills.Mudra.Doton.enabled then
      if numNearby > 1 and not PlayerHasBuff(Buffs.Doton) then
        return SetMudra(Skills.Mudra.Doton)
      end
    end

    if Skills.Kassatsu.enabled and TrickAttackDebuff ~= nil then
      if Kassatsu:IsReady(Player.id) then
        if Kassatsu:Cast(Player.id) then
          return true
        end
      end
    end

    if PlayerHasBuff(Buffs.Kassatsu) then
      -- Goka Mekkyaku for multi-target
      if numNearby > 1 and Skills.Mudra.Goka.enabled then
        return SetMudra(Skills.Mudra.Goka)

      -- Hyosho Ranryu for single-target
      elseif Skills.Mudra.Hyosho.enabled then
        return SetMudra(Skills.Mudra.Hyosho)
      end
    end

    if Skills.Mudra.Raiton.enabled then
      return SetMudra(Skills.Mudra.Raiton)
    end
  end

  return false
end

local function CastIfReady(skill, targetId)
  local action = ActionList:Get(1, skill.id);
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
    if Player.lastcomboid == Skills.DeathBlossom.id then
      return CastIfReady(Skills.HakkeMujinsatsu)
    else
      return CastIfReady(Skills.DeathBlossom)
    end
  else
    if Player.lastcomboid == Skills.GustSlash.id then
      -- If you have more than 30 seconds left on your Huton buff, use Aeolian Edge as your combo ender instead.
      if Player.gauge[2] > 30000 then
        return CastIfReady(Skills.AeolianEdge, target.id)
      end
    elseif Player.lastcomboid == Skills.SpinningEdge.id then
      return CastIfReady(Skills.GustSlash, target.id)
    else
      return CastIfReady(Skills.SpinningEdge, target.id)
    end
  end

  return false
end

function UseRaiju(numNearby, target)
  if not Skills.FleetingRaiju.enabled and not Skills.ForkedRaiju.enabled then
    return false
  end

  if numNearby > 2 then return false end
  if not PlayerHasBuff(Buffs.RaijuReady) then
    return false
  end

  local FleetingRaiju = ActionList:Get(1, Skills.FleetingRaiju.id);
  local ForkedRaiju = ActionList:Get(1, Skills.ForkedRaiju.id);

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
  local hutonTimeleft = Player.gauge[2]

  local hasHuton = hutonTimeleft > 0
  if not hasHuton then
    return SetMudra(Skills.Mudra.Huton)
  end

  if hutonTimeleft < 30000 and Skills.ArmorCrush.enabled then
    local action = ActionList:Get(1, Skills.ArmorCrush.id);
    local isImmediate = Player.gauge[2] < 15000
    if action:IsReady(target.id) then
      if isImmediate or Player.lastcomboid == Skills.GustSlash.id then
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
  local targetId = currentMudra.buff and Player.id or target.id

  if isFinished then
    local jutsu = ActionList:Get(1, Skills.Ninjutsu.id);    
    if jutsu:Cast(target.id) then
      currentMudra = nil
      return true
    elseif jutsu:Cast(Player.id) then
      currentMudra = nil
      return true
    else
      d("Failed to cast: " .. tostring(currentMudra.id))
    end
  else
    local action = ActionList:Get(1, currentMudra[1].id);
    if action:Cast() then
      table.remove(currentMudra, 1)
      return true
    else
      d('Failed to cast ' .. tostring(currentMudra[1].id) .. ' in mudra')
    end
  end

  return false
end

local function ManageNinki(numNearby, target)
  if not profile.NinkiEnabled then return false end

  local ninkiPower = Player.gauge[1]

  -- Use Bunshin as soon as it is off cooldown.
  local Bunshin = ActionList:Get(1, Skills.Bunshin.id);
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
    local Bhavacakra = ActionList:Get(1, Skills.Bhavacakra.id)
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
    local Hellfrog = ActionList:Get(1, Skills.Hellfrog.id)
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

  if not IsInCombat(true, true) then return false end

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

  local Kassatsu = ActionList:Get(1, Skills.Kassatsu.id);
  if IsNinjutsuReady() then
    if Ninjutsu(#nearby) then return true end
  elseif Kassatsu:IsReady() and Skills.Kassatsu.enabled then
    -- Force use Kassatsu on CD and only when we've exhausted both of mudra charges
    -- Ninjutsu will be ready upon next loop
    if Kassatsu:Cast() then
      return true
    end
  end

  if Skills.TrickAttack.enabled then
    local TrickAttack = ActionList:Get(1, Skills.TrickAttack.id)
    if TrickAttack:IsReady(target.id) then
      if TrickAttack:Cast(target.id) then return true
      else d("Failed to cast TrickAttack") end
    end
  end

  if Skills.Assassinate.enabled then
    local TrickAttackDebuff = GetTargetDebuff(target, Buffs.TrickAttack)
    if TrickAttackDebuff ~= nil and #nearby < 3 then
      local assassinate = ActionList:Get(1, Skills.Assassinate.id)
      local dwd = ActionList:Get(1, Skills.DreamWithinADream.id)
      if not assassinate.isoncd and not dwd.isoncd then
        -- Will cast both
        if assassinate:Cast(target.id) then
          return true
        end
      end
    end
  end

  if BasicCombo(#nearby, target) then return true end
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

  Skills.Mudra.Katon.enabled   = GUI:Checkbox("Katon", Skills.Mudra.Katon.enabled)
  Skills.Mudra.Raiton.enabled  = GUI:Checkbox("Raiton", Skills.Mudra.Raiton.enabled)
  Skills.Mudra.Goka.enabled    = GUI:Checkbox("Goka Mekkyaku", Skills.Mudra.Goka.enabled)
  Skills.Mudra.Hyosho.enabled  = GUI:Checkbox("Hyosho Ranryu", Skills.Mudra.Hyosho.enabled)
  Skills.ForkedRaiju.enabled   = GUI:Checkbox("Forked Raiju", Skills.ForkedRaiju.enabled)
  Skills.FleetingRaiju.enabled = GUI:Checkbox("Fleeting Raiju", Skills.FleetingRaiju.enabled)
  Skills.Bhavacakra.enabled    = GUI:Checkbox("Bhavacakra", Skills.Bhavacakra.enabled)
  Skills.TenChiJin.enabled     = GUI:Checkbox("Ten Chi Jin", Skills.TenChiJin.enabled)
  Skills.Kassatsu.enabled      = GUI:Checkbox("Kassatsu", Skills.Kassatsu.enabled)
  Skills.Assassinate.enabled   = GUI:Checkbox("Assassinate", Skills.Assassinate.enabled)
  Skills.ArmorCrush.enabled    = GUI:Checkbox("Armor Crush", Skills.ArmorCrush.enabled)

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

  Skills.Mudra.Katon.enabled   = ACR.GetSetting("OpenACR_Ninja_KatonEnabled", true)
  Skills.Mudra.Raiton.enabled  = ACR.GetSetting("OpenACR_Ninja_RaitonEnabled", true)
  Skills.Mudra.Goka.enabled    = ACR.GetSetting("OpenACR_Ninja_GokaEnabled", true)
  Skills.Mudra.Hyosho.enabled  = ACR.GetSetting("OpenACR_Ninja_HyoshoEnabled", true)
  Skills.ForkedRaiju.enabled   = ACR.GetSetting("OpenACR_Ninja_ForkedRaijuEnabled", true)
  Skills.FleetingRaiju.enabled = ACR.GetSetting("OpenACR_Ninja_FleetingRaijuEnabled", true)
  Skills.Bhavacakra.enabled    = ACR.GetSetting("OpenACR_Ninja_BhavaEnabled", true)
  Skills.TenChiJin.enabled     = ACR.GetSetting("OpenACR_Ninja_TCJEnabled", true)
  Skills.Kassatsu.enabled      = ACR.GetSetting("OpenACR_Ninja_KassatsuEnabled", true)
  Skills.Assassinate.enabled   = ACR.GetSetting("OpenACR_Ninja_AssassinateEnabled", true)
  Skills.ArmorCrush.enabled    = ACR.GetSetting("OpenACR_Ninja_ArmorCrushEnabled", true)
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