local Lancer = {
}

local Buffs = {
  PowerSurge = 2720, -- Damage increase
}

local Skills = {
  TrueThrust = 75,
  VorpalThrust = 78, -- Combos with TrueThrust

  LifeSurge = 83, -- First weapon skill afterwards is crit, increases damage when already under crit bonus, absorbs portion of damage as HP, can't be applied to DOT
  PiercingTalon = 90, -- Ranged
  Disembowel = 87,
  FullThrust = 84, -- Follows Vorpal in combo
  LanceCharge = 85,
  ChaosThrust = 88, -- Cast after Disembowel, also applies DOT
}

function Lancer:Cast(target)
  local playerHasPowerSurge = HasBuff(Player.id, Buffs.PowerSurge, 0, 3)

  -- Just cast on cooldown
  if ReadyCast(Player.id, Skills.LanceCharge) then return true end

  if Player.lastcomboid == Skills.VorpalThrust then
    if ReadyCast(target.id, Skills.FullThrust) then return true end
  elseif Player.lastcomboid == Skills.TrueThrust then
    if not playerHasPowerSurge then
      if ReadyCast(target.id, Skills.Disembowel) then return true end
    end
    if ReadyCast(target.id, Skills.VorpalThrust) then return true end
  elseif Player.lastcomboid == Skills.Disembowel then
    if ReadyCast(target.id, Skills.ChaosThrust) then return true end
  else
    if ReadyCast(target.id, Skills.TrueThrust) then return true end
    if ReadyCast(target.id, Skills.PiercingTalon) then return true end -- will default cast if too far away for melee
  end

  return false
end

function Lancer:Draw()

end

function Lancer:OnLoad()

end

return Lancer