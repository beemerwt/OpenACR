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
  ArmOfTheDestroyer = -1, -- Changes form to Raptor, if used from opo-opo does more damage (useless)
  DragonKick = -1, -- Changes form to Raptor, if used from opo-opo grants Leaden Fist ()

  TrueStrike = 54, -- Can only be executed in Raptor form, Changes form to Coeurl
  TwinSnakes = -1, -- Can only be executed in Raptor form, Changes form to Coeurl, Grants Disciplined Fist (Damage Increase)

  SnapPunch = 56, -- Can only be executed in Coeurl form, Changes form to opo-opo
  Demolish = -1, -- Can only be executed in Coeurl form, Changes form to opo-opo, Grants Damage Over Time

  Meditation = -1, -- Changes to SteelPeak, so maybe use this if SteelPeak doesn't work?
  SteelPeak = -1, -- Can only be used while Fifth Chakra, will use all of the Chakra

  Mantra = -1, -- Increases HP Recovery by 10% for everyone
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
  -- Pugilist
  local playerHasDisciplinedFist = HasBuff(Player.id, Buffs.DisciplinedFist)
  local playerHasLeadenFist = HasBuff(Player.id, Buffs.LeadenFist)
  local targetHasDemolish = HasBuff(target.id, Buffs.Demolish)
  local playerForm = GetCurrentForm()

  if playerForm == Buffs.OpoOpoForm then
    if not playerHasLeadenFist then
      if ReadyCast(target.id, Skills.DragonKick) then return true end
    end

    if ReadyCast(target.id, Skills.Bootshine) then return true end
  end

  if playerForm == Buffs.CoeurlForm then
    if not targetHasDemolish then
      if ReadyCast(target.id, Skills.Demolish) then return true end
    end

    if ReadyCast(target.id, Skills.SnapPunch) then return true end
  end

  if playerForm == Buffs.RaptorForm then
    if not playerHasDisciplinedFist then
      if ReadyCast(target.id, Skills.TwinSnakes) then return true end
    end

    if ReadyCast(target.id, Skills.TrueStrike) then return true end
  end

  if playerForm == 0 then
    if ReadyCast(target.id, Skills.Bootshine) then return true end
  end
end

function Monk.Draw()
end

function Monk.OnLoad()
end

return Monk