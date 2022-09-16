local Marauder = {
  AOE = true,
}

function Marauder:Cast(target)
  local playerHasSurgingTempest = HasBuff(Player.id, Buffs.SurgingTempest, 0, 15)
  local playerHasDefiance = HasBuff(Player.id, Buffs.Defiance)

  if not playerHasDefiance then
    if ReadyCast(Player.id, Skills.Defiance) then return true end
  end

  if Player.hp.percent < 35 then
    if ReadyCast(Player.id, Skills.ThrillOfBattle) then return true end
  end

  if Player.hp.percent < 50 then
    if ReadyCast(Player.id, Skills.Vengeance) then return true end
  end

  local nearby = GetNearbyEnemies(8) -- range of Overpower

  if playerHasSurgingTempest or #nearby > 2 then
    if ReadyCast(Player.id, Skills.Berserk) then return true end
  end

  if self.AOE and #nearby > 2 then
    if ReadyCast(Player.id, Skills.Overpower) then return true end
  end

  if Player.lastcomboid == Skills.Maim then
    if not playerHasSurgingTempest then
      if ReadyCast(target.id, Skills.StormsEye) then return true end
    end

    if ReadyCast(Player.id, Skills.Berserk) then return true end
    if ReadyCast(target.id, Skills.StormsPath) then return true end
  end

  if Player.lastcomboid == Skills.HeavySwing then
    if ReadyCast(target.id, Skills.Maim) then return true end
  end

  if ReadyCast(target.id, Skills.HeavySwing) then return true end
  if ReadyCast(target.id, Skills.Tomahawk) then return true end

  return false
end

function Marauder:Draw()
  self.AOE = GUI:Checkbox("AOE Enabled", self.AOE)
end

function Marauder:OnLoad()
  self.AOE = ACR.GetSetting("OpenACR_Marauder_AOEEnabled", true)
end

return Marauder