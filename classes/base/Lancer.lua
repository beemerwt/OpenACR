local Lancer = {
}

function Lancer:Cast(target)
  local playerHasPowerSurge = HasBuff(Player.id, Buffs.PowerSurge, 0, 3)
  local playerHasLifeSurge = HasBuff(Player.id, Buffs.LifeSurge)

  local isFullThrustCapable = IsCapable(Skills.FullThrust)

  -- Just cast on cooldown
  if ReadyCast(Player.id, Skills.LanceCharge) then return true end

  if Player.lastcomboid == Skills.VorpalThrust then
    -- Cast life surge before Full Thrust for max damage
    if not playerHasLifeSurge and isFullThrustCapable then
      if ReadyCast(Player.id, Skills.LifeSurge) then return true end
    end

    if ReadyCast(target.id, Skills.FullThrust) then return true end
  end

  if Player.lastcomboid == Skills.Disembowel then
    if ReadyCast(target.id, Skills.ChaosThrust) then return true end
  end

  if Player.lastcomboid == Skills.TrueThrust then
    if not playerHasPowerSurge then
      if ReadyCast(target.id, Skills.Disembowel) then return true end
    end

    -- Before you can cast Full Thrust, opimize so that it can do the most damage
    if not playerHasLifeSurge and not isFullThrustCapable then
      if ReadyCast(Player.id, Skills.LifeSurge) then return true end
    end

    if ReadyCast(target.id, Skills.VorpalThrust) then return true end
  end

  if ReadyCast(target.id, Skills.TrueThrust) then return true end
  if ReadyCast(target.id, Skills.PiercingTalon) then return true end -- will default cast if too far away for melee
  return false
end

return Lancer