local Monk = {
  AOE = true,
}

-- Skills
Skills.ForbiddenChakra = 8790
Skills.RiddleOfWind = 7868 -- 9098, 25766
Skills.Brotherhood = 7396 -- 18915
Skills.RiddleOfFire = 7395 -- 9636
Skills.FourPointFury = 16473
Skills.RockBreaker = 70
Skills.HowlingFist = 25763
Skills.Mantra = 65
Skills.MasterfulBlitz = 25674

-- Buffs
Buffs.LeadenFist = -1
Buffs.Demolish = 246
Buffs.Brotherhood = -1
Buffs.RiddleOfFire = -1
Buffs.RiddleOfWind = -1

local windowBlitz = 0

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

local function GetAveragePartyHP()
  local party = MGetParty()
  local totalPercent = 0
  if not party then return Player.hp.percent end

  for _,player in pairs(party) do
    totalPercent = totalPercent + player.hp.percent
  end

  return totalPercent / #party
end

function Monk:Cast(target)
  local nearby = GetNearbyEnemies(5)

  -- Consume Chakra...
  if self.AOE and #nearby > 2 then
    if ReadyCast(target.id, Skills.HowlingFist) then return true end
  else
    if ReadyCast(target.id, Skills.ForbiddenChakra, Skills.SteelPeak) then return true end
  end


  if GetAveragePartyHP() < 50 then
    if ReadyCast(Player.id, Skills.Mantra) then return true end
  end

  -- Put this above window "handler" because we have to ensure both get casted
  if not HasBuff(Player.id, Buffs.RiddleOfWind) then
    if ReadyCast(Player.id, Skills.Brotherhood) then return true end
    if ReadyCast(Player.id, Skills.RiddleOfFire) then
      windowBlitz = 0
      return true
    end
  end

  -- Window
  if HasBuff(Player.id, Buffs.RiddleOfFire) then
    -- Even Window
    if windowBlitz < 2 and HasBuff(Player.id, Buffs.Brotherhood) then
      -- Second usage of Blitz
      if ReadyCast(target.id, Skills.MasterfulBlitz) then
        windowBlitz = windowBlitz + 1
        return true
      end

    -- Odd Windows
    elseif windowBlitz < 1 then
      -- One usage of Masterful Blitz
      if ReadyCast(target.id, Skills.MasterfulBlitz) then
        windowBlitz = windowBlitz + 1
        return true
      end
    end
  end

  if not HasBuff(Player.id, Buffs.RiddleOfFire) then
    if ReadyCast(Player.id, Skills.RiddleOfWind) then return true end
  end

  local form = GetCurrentForm()
  if form == Buffs.RaptorForm then
    if not HasBuff(Player.id, Buffs.DisciplinedFist, 0, 6) then
      if ReadyCast(target.id, Skills.TwinSnakes) then return true end
    end

    if self.AOE and #nearby > 2 then
      if ReadyCast(Player.id, Skills.FourPointFury) then return true end
    end

    if ReadyCast(target.id, Skills.TrueStrike) then return true end
  elseif form == Buffs.CoeurlForm then
    if not HasBuff(target.id, Buffs.Demolish, 0, 6) then
      if ReadyCast(target.id, Skills.Demolish) then return true end
    end

    if self.AOE and #nearby > 2 then
      if ReadyCast(Player.id, Skills.Rockbreaker) then return end
    end

    if ReadyCast(target.id, Skills.SnapPunch) then return true end
  elseif form == Buffs.OpoOpoForm then
    if not HasBuff(Player.id, Buffs.LeadenFist) then
      if ReadyCast(target.id, Skills.DragonKick) then return true end
    end
  end

  if self.AOE and #nearby > 2 then
    if ReadyCast(Player.id, Skills.ArmOfTheDestroyer) then return true end
  end

  if ReadyCast(target.id, Skills.Bootshine) then return true end
end

function Monk:Draw()
  self.AOE = OpenACR.ListCheckboxItem("AOE Enabled", self.AOE)
end

function Monk:OnLoad()
  self.AOE = ACR.GetSetting("OpenACR_Monk_AOEEnabled", true)
end

return Monk