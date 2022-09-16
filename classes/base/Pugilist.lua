local Pugilist = { }

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

function Pugilist:Cast(target)
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

return Pugilist