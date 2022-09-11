local Dragoon = {

  phase = ""
}

local Skills = {
  TrueThrust = -1,
  VorpalThrust = -1, -- Combos with TrueThrust

  LifeSurge = -1, -- First weapon skill afterwards is crit, increases damage when already under crit bonus, absorbs portion of damage as HP, can't be applied to DOT

  PiercingTalon = -1, -- Ranged

  Disembowel = -1,
  FullThrust = -1,
  LanceCharge = -1,
  ChaosThrust = -1,
}

function Dragoon:Cast(target)
  -- Lancer
  if self.phase == "DEFENSIVE" then
    
  end

  if self.phase == "ATTACK" then
    
  end

  if IsReady(target.id, Skills.PiercingTalon) then
    return next(target.id, Skills.PiercingTalon)
  end
end

function Dragoon:Draw()

end

function Dragoon:OnUpdate()

  self.phase = "DAMAGE"
end

function Dragoon:OnLoad()

end

return Dragoon