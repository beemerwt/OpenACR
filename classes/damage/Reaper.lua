local Reaper = abstractFrom(OpenACR.CombatProfile)

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
function Reaper:Cast(target)
  if TimeSince(lasttime) < 100 then return false end
  lasttime = Now()

  local playerHasReaverStack = HasBuff(Player.id, Buffs.SoulReaver)
  local playerHasSacrificeStacks = HasBuff(Player.id, Buffs.ImmortalSacrifice)

  local playerHasGibbet = HasBuff(Player.id, Buffs.EnhancedGibbet)
  local playerHasGallows = HasBuff(Player.id, Buffs.EnhancedGallows)
  local playerHasSoulSow = HasBuff(Player.id, Buffs.SoulSow)
  local playerHasShroud = HasBuff(Player.id, Buffs.Enshroud)

  local targetDeathsDesign = HasBuff(target.id, Buffs.DeathsDesign)

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
    if self.AOEEnabled and #nearby > 1 then
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
    if #nearby > 1 and self.AOEEnabled then
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
    if #nearby > 1 and self.AOEEnabled then
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

      if self.AOEEnabled and #nearby > 1 then
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
    if #nearby > 1 and self.AOEEnabled then
      if ReadyCast(target.id, Skills.GrimSwathe) then return true end
    else
      if ReadyCast(target.id, Skills.UnveiledGallows) then return true end
      if ReadyCast(target.id, Skills.UnveiledGibbet) then return true end
    end
  end

  -- Use your combo actions (Slice, Waxing Slice or Infernal Slice) as fillers.
  if BasicCombo(target) then return true end
  if #nearby > 1 and self.AOEEnabled then
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

function Reaper:Draw()
  self.AOEEnabled = GUI:Checkbox("AOE Enabled", self.AOEEnabled)
end

function Reaper:OnLoad()
  self.AOEEnabled = ACR.GetSetting("OpenACR_Reaper_AOEEnabled", true)
end

return Reaper