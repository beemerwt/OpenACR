local profile = {

}

local Buffs = {
  SoulReaver = 2587,
  DeathsDesign = 2586,

  EnhancedGibbet = 2588,
  EnhancedGallows = 2589,

  ImmortalSacrifice = -1,
  SoulSow = -1
}

local Skills = {
  Harpe = 24386,
  Slice = 24373,
  WaxingSlice = 24374,
  InfernalSlice = 24375,
  WhorlOfDeath = 24379,
  ShadowOfDeath = 24378,
  Gibbet = 24382,
  Gallows = 24383,
  Guillotine = 24384,
  Enshroud = 24394,
  BloodStalk = 24389,

  SoulSlice = 24380,
  SoulScythe = 24381,
  UnveiledGibbet = 24390,
  UnveiledGallows = 24391,
  GrimSwathe = 24392,

  SoulSow = 24387,

  HarvestMoon = 24388,
  ArcaneCircle = 24405,
  PlentifulHarvest = 24385,

  VoidReaping = 24395,
  CrossReaping = 24396,
  GrimReaping = 24397,
  LemureSlice = 24399,
  LemureScythe = 24400,
  Communio = 24398,

  SpinningScythe = 24376,
  NightmareScythe = 24377,
}

local function BasicCombo(target)
  if Player.lastcomboid == Skills.Slice then
    if ReadyCast(target.id, Skills.WaxingSlice) then return true end
  elseif Player.lastcomboid == Skills.WaxingSlice then
    if ReadyCast(target.id, Skills.InfernalSlice) then return true end
  elseif Player.lastcomboid == Skills.SpinningScythe then
    if ReadyCast(Player.id, Skills.NightmareScythe) then return true end
  end
end

local ShroudStack = {}

local lasttime = 0
function profile.Cast(target)
  if TimeSince(lasttime) < 100 then return false end
  lasttime = Now()

  local playerHasReaverStack = PlayerHasBuff(Buffs.SoulReaver)
  local playerHasSacrificeStacks = PlayerHasBuff(Buffs.ImmortalSacrifice)

  local playerHasGibbet = PlayerHasBuff(Buffs.EnhancedGibbet)
  local playerHasGallows = PlayerHasBuff(Buffs.EnhancedGallows)
  local playerHasSoulSow = PlayerHasBuff(Buffs.SoulSow)
  local playerHasShroud = PlayerHasBuff(Buffs.Enshroud)

  local targetDeathsDesign = GetTargetDebuff(Buffs.DeathsDesign)

  local nearby = GetNearbyEnemies(10)

  local soul = Player.gauge[1]
  local shroud = Player.gauge[2] -- unknown

  if #ShroudStack > 0 and playerHasShroud then
    if ReadyCast(target.id, ShroudStack[1]) then
      table.remove(ShroudStack, 1)
      return true
    end

    return false
  end

  if playerHasReaverStack then
    if profile.AOEEnabled and #nearby > 1 then
      if ReadyCast(target.id, Skills.Guillotine) then return true end
    else
      if playerHasGibbet then
        if ReadyCast(target.id, Skills.Gibbet) then return true end
      elseif playerHasGallows then
        if ReadyCast(target.id, Skills.Gallows) then return true end
      else
        -- Whichever one goes off, I guess
        if ReadyCast(target.id, Skills.Gibbet) then return true end
        if ReadyCast(target.id, Skills.Gallows) then return true end
      end
    end
  end

  -- Maintain combo if it's up
  if Player.combotimeremain < 5 then
    if BasicCombo(target) then return true end
  end

  -- Maintain the Death's Design debuff at all times by using Shadow of Death.
  if not targetDeathsDesign or targetDeathsDesign.duration < 15 then
    if #nearby > 1 and profile.AOEEnabled then
      if ReadyCast(Player.id, Skills.WhorlOfDeath) then return true end
    else
      if ReadyCast(target.id, Skills.ShadowOfDeath) then return true end
    end
  end

  -- Use Arcane Circle on cooldown.
  if ReadyCast(Player.id, Skills.ArcaneCircle) then return true end

  -- Use Plentiful Harvest if you have 50 or less Shroud and you have Immortal Sacrifice stacks.
  if shroud <= 50 and playerHasSacrificeStacks then
    if ReadyCast(target.id, Skills.PlentifulHarvest) then return true end
  end

  -- Use Soul Slice if you have 50 or less Soul.
  if soul <= 50 then
    if #nearby > 1 and profile.AOEEnabled then
      if ReadyCast(Player.id, Skills.SoulScythe) then return true end
    else
      if ReadyCast(target.id, Skills.SoulSlice) then return true end
    end
  end

  -- Use Gluttony if you have 50 or more Soul and it is off cooldown.
  if soul >= 50 then
    if IsCapable(Skills.Gluttony) then
      if ReadyCast(target.id, Skills.Gluttony) then return true end
    else
      if ReadyCast(target.id, Skills.BloodStalk) then return true end
    end
  end

  -- Enter your Enshroud phase if you have 50 or more Shroud.
  if shroud >= 50 and #ShroudStack == 0 then
    if ReadyCast(Player.id, Skills.Enshroud) then
      EnshroudStart = Now()

      if profile.AOEEnabled and #nearby > 1 then
        ShroudStack = {
          Skills.GrimReaping,
          Skills.GrimReaping,
          Skills.LemureScythe,
          Skills.GrimReaping,
          Skills.GrimReaping,
          Skills.LemureScythe,
          Skills.Communio
        }
      else
        ShroudStack = {
          Skills.VoidReaping,
          Skills.CrossReaping,
          Skills.LemureSlice,
          Skills.VoidReaping,
          Skills.CrossReaping,
          Skills.LemureSlice,
          Skills.Communio
        }
      end

      return true
    end
  end

  -- Use Harvest Moon if the target is about to jump or die and you still have the Soul Sow buff up.
  if playerHasSoulSow then
    if #nearby > 1 or target.hp.percent <= 5 then
      if ReadyCast(target.id, Skills.HarvestMoon) then return true end
    end
  end

  -- Use an Unveiled action variant if you have 50 or more Soul and 90 or less Shroud.
  if soul >= 50 and shroud <= 90 then
    if #nearby > 1 and profile.AOEEnabled then
      if ReadyCast(target.id, Skills.GrimSwathe) then return true end
    else
      if ReadyCast(target.id, Skills.UnveiledGallows) then return true end
      if ReadyCast(target.id, Skills.UnveiledGibbet) then return true end
    end
  end

  -- Use your combo actions (Slice, Waxing Slice or Infernal Slice) as fillers.
  if BasicCombo(target) then return true end
  if #nearby > 1 and profile.AOEEnabled then
    if ReadyCast(Player.id, Skills.SpinningScythe) then return true end
  else
    if ReadyCast(target.id, Skills.Slice) then return true end
  end

  -- We are out of range if we can't do the basic combo, so...
  -- Use Harvest Moon if you are not in melee range of the target and have the Soul Sow buff up
  if playerHasSoulSow then
    if ReadyCast(target.id, Skills.HarvestMoon) then return true end
  end

  -- Use Harpe if you are not in melee range of the target.
  if ReadyCast(target.id, Skills.Harpe) then return true end

  -- Use Soulsow if the target is untargetable for 5 seconds or more.
  if not target.targetable then
    if ReadyCast(Player.id, Skills.SoulSow) then return true end
  end
end

function profile.Draw()
  profile.AOEEnabled = GUI:Checkbox("AOE Enabled", profile.AOEEnabled)
end

function profile.OnLoad()
  profile.AOEEnabled = ACR.GetSetting("OpenACR_Reaper_AOEEnabled", true)
end

return profile