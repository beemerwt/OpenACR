local Dragoon = {
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
end

function Dragoon:Draw()

end

function Dragoon:OnUpdate()
end

function Dragoon:OnLoad()

end

return Dragoon