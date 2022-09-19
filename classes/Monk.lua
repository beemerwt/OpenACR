local Monk = inheritsFrom(DefaultProfile)
Monk.AOE = true

-- Skills
Skills.ForbiddenChakra = 8790
Skills.RiddleOfWind = 7868 -- 9098, 25766
Skills.Brotherhood = 7396 -- 18915
Skills.RiddleOfFire = 7395 -- 9636
Skills.FourPointFury = 16473
Skills.Rockbreaker = 70
Skills.HowlingFist = 25763
Skills.Mantra = 65
Skills.PerfectBalance = 69 -- IsReady works for Player
Skills.MasterfulBlitz = 25674

-- Blitzes that Masterful Blitz performs
Skills.ElixirField = 3545 -- IsReady works for Player
Skills.TornadoKick = 3543 -- 8789 -- IsReady works for Player 
Skills.CelestialRevolution = 25765 -- I'm going to assume IsReady works for Player 
Skills.RisingPhoenix = 25768 -- 29481
Skills.PhantomRush = 25769 -- 29478
Skills.FlintStrike = 25882 -- IsReady works for Player

-- Buffs
Buffs.LeadenFist = 1861
Buffs.Demolish = 246
Buffs.Brotherhood = -1
Buffs.RiddleOfFire = -1
Buffs.RiddleOfWind = -1
Buffs.PerfectBalance = 110

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

local function HasSolar()
  d("Has Solar: " .. tostring(Player.gauge[5] / 2 == 2) .. ', ' .. tostring(Player.gauge[5] / 2 == 3))
  return Player.gauge[5] / 2 == 2 or Player.gauge[5] / 2 == 3
end

local function HasLunar()
  d("Has Lunar: " .. tostring(Player.gauge[5] / 2 == 1) .. ', ' .. tostring(Player.gauge[5] / 2 == 3))
  return Player.gauge[5] / 2 == 1 or Player.gauge[5] / 2 == 3
end

local pbCombo = {}

local usePerfectBalance = false

-- We can just ignore Six-Sided Star, difference in DPS is negligible
-- We also don't care about double-weaving
-- Nor do we really care about drifting...
-- DPS mechanics are ugly, too specific and no normal human is perfect anyway.

function Monk:Cast(target)
  if GetAveragePartyHP() < 50 then
    if ReadyCast(Player.id, Skills.Mantra) then return true end
  end

  -- If any of these are "Ready", prioritize them above all
  if ReadyCast(target.id, Skills.PhantomRush) then return true end
  if ReadyCast(target.id, Skills.TornadoKick) then return true end

  local nearby = GetNearbyEnemies(5)

  if HasBuff(Player.id, Buffs.PerfectBalance) then
    if #pbCombo > 0 then
      d("Successfully entered the PBCombo handler.")
      local targetId = pbCombo[1] == Skills.Rockbreaker and Player.id
        or pbCombo[1] == Skills.ArmOfTheDestroyer and Player.id
        or pbCombo[1] == Skills.FourPointFury and Player.id
        or target.id

      if ReadyCast(targetId, pbCombo[1]) then
        table.remove(pbCombo, 1)
        return true
      end
    end

    return false
  end

  -- Prioritize these after PerfectBalance combo has been handled
  -- This is to prevent misfiring while using pbCombo
  if #nearby > 0 then
    if ReadyCast(Player.id, Skills.ElixirField) then return true end
    if ReadyCast(Player.id, Skills.RisingPhoenix, Skills.FlintStrike) then return true end
    if ReadyCast(Player.id, Skills.CelestialRevolution) then
      d("Error occurred where attempting to create Lunar or Solar chakra")
      return true
    end
  end

  -- Consume Chakra...
  if self.ChakraEnabled then
    if self.AOE and #nearby > 2 then
      if ReadyCast(target.id, Skills.HowlingFist) then return true end
    else
      if ReadyCast(target.id, Skills.ForbiddenChakra, Skills.SteelPeak) then return true end
    end
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

  -- Form Order: None -> Raptor -> Coeurl -> OpoOpo -> Raptor...
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
    -- PB doesn't become useful until level 60
    if self.PerfectBalance and not HasBuff(Player.id, Buffs.PerfectBalance) then
      if ReadyCast(Player.id, Skills.PerfectBalance) then
        d("Perfect Balance Was Cast")
        if not HasLunar() then
          if self.AOE and #nearby > 2 then
            pbCombo = { Skills.Rockbreaker, Skills.Rockbreaker, Skills.Rockbreaker }
          elseif not HasBuff(Player.id, Buffs.LeadenFist) then
            pbCombo = { Skills.DragonKick, Skills.Bootshine, Skills.DragonKick }
          else
            pbCombo = { Skills.Bootshine, Skills.DragonKick, Skills.Bootshine }
          end

          return true
        end

        if not HasSolar() then
          if self.AOE and #nearby > 2 then
            pbCombo = { Skills.ArmOfTheDestroyer, Skills.FourPointFury, Skills.Rockbreaker }
          else
            local first = HasBuff(Player.id, Buffs.LeadenFist) and Skills.Bootshine or Skills.DragonKick
            local second = HasBuff(Player.id, Buffs.DisciplinedFist) and Skills.TrueStrike or Skills.TwinSnakes
            local third = HasBuff(target.id, Buffs.Demolish) and Skills.SnapPunch or Skills.Demolish
            pbCombo = { first, second, third }
          end

          return true
        end

        d("No combo was set?")
        return true
      end
    end

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
  self.ChakraEnabled = OpenACR.ListCheckboxItem("Chakra Enabled", self.ChakraEnabled)
  self.PerfectBalance = OpenACR.ListCheckboxItem("Perfect Balance", self.PerfectBalance)
end

function Monk:OnLoad()
  self.AOE = ACR.GetSetting("OpenACR_Monk_AOEEnabled", true)
  self.ChakraEnabled = ACR.GetSetting("OpenACR_Monk_ChakraEnabled", true)
  self.PerfectBalance = ACR.GetSetting("OpenACR_Monk_PerfectBalance", true)
end

return Monk