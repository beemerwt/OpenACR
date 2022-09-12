local Gladiator = {
  AOE = true
}

local Buffs = {
  IronWill = 79,
}

local Skills = {
  FastBlade = 9,
  RiotBlade = 15,
  ShieldBash = 16,
  Sentinel = 17,
  FightOrFlight = 20,
  RageOfHalone = 21,
  CircleOfScorn = 23,
  ShieldLob = 24,
  IronWill = 28,
  TotalEclipse = 7381
}

function Gladiator:Cast(target)
  if not HasBuff(Player.id, Buffs.IronWill) then
    if ReadyCast(Player.id, Skills.IronWill) then return true end
  end

  if Player.hp.percent < 50 then
    if ReadyCast(Player.id, Skills.Sentinel) then return true end
  end

  local nearby = GetNearbyEnemies(8) -- range of Overpower

  if #nearby > 1  or Player.hp.percent < 35 then
    if ReadyCast(Player.id, Skills.FightOrFlight) then return true end
  end

  if self.AOE and #nearby > 2 then
    if ReadyCast(Player.id, Skills.CircleOfScorn) then return true end
    if ReadyCast(Player.id, Skills.TotalEclipse) then return true end
  end

  if Player.lastcomboid == Skills.RiotBlade then
    if ReadyCast(target.id, Skills.RageOfHalone) then return true end
  end

  if Player.lastcomboid == Skills.FastBlade then
    if ReadyCast(target.id, Skills.RiotBlade) then return true end
  end

  if ReadyCast(target.id, Skills.FastBlade) then return true end
  if ReadyCast(target.id, Skills.ShieldLob) then return true end

  return false
end

function Gladiator:Draw()
  self.AOE = GUI:Checkbox("AOE Enabled", self.AOE)
end

function Gladiator:OnLoad()
  self.AOE = ACR.GetSetting("OpenACR_Gladiator_AOEEnabled", true)
end

return Gladiator