local Monk = {

}

local Buffs = {
  RaptorForm = 108,
  CoeurlForm = 109,
  OpoOpoForm = 107,
  DisciplinedFist = 3001,
}

local Skills = {
  Bootshine = 53, -- Changes form to Raptor
  ArmOfTheDestroyer = 62, -- Changes form to Raptor, if used from opo-opo does more damage (useless)
  DragonKick = 74, -- Changes form to Raptor, if used from opo-opo grants Leaden Fist ()

  TrueStrike = 54, -- Can only be executed in Raptor form, Changes form to Coeurl
  TwinSnakes = 61, -- Can only be executed in Raptor form, Changes form to Coeurl, Grants Disciplined Fist (Damage Increase)

  SnapPunch = 56, -- Can only be executed in Coeurl form, Changes form to opo-opo
  Demolish = 66, -- Can only be executed in Coeurl form, Changes form to opo-opo, Grants Damage Over Time

  Meditation = 3546, -- UNKNOWN Changes to SteelPeak, so maybe use this if SteelPeak doesn't work?
  SteelPeak = -1, -- Can only be used while Fifth Chakra, will use all of the Chakra

  Mantra = 65, -- Increases HP Recovery by 10% for everyone
}

local function GetCurrentForm()
  for i,_ in ipairs(Player.buffs) do
    if Player.buffs[i].id == Buffs.OpoOpoForm then
      return Buffs.OpoOpoForm
    elseif Player.buffs[i].id == Buffs.CoeurlForm then
      return Buffs.CoeurlForm
    elseif Player.buffs[i].id == Buffs.RaptorForm then
      return Buffs.RaptorForm
    end
  end

  return 0
end

function Monk.Cast(target)
end

function Monk.Draw()
end

function Monk.OnLoad()
end

return Monk