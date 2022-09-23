local Samurai = abstractFrom(OpenACR.CombatProfile)

local GCDFiller = {
  [1] = {
    Skills.HissatsuYaten,
    Skills.Enpi
  },

  [2] = {
    Skills.Hakaze,
    Skills.Yukikaze,
    Skills.Hagakure
  },

  [3] = {
    Skills.Hakaze,
    Skills.Shifu,
    Skills.Jinpu,
    Skills.Kasha,
    Skills.Gekko,
    Skills.Hagakure
  }
}

local Combos = {
  FugaMangetsu = { Skills.Fuga, Skills.Mangetsu },
  FugaOka = { Skills.Fuga, Skills.Oka },
  MidareSetsugekka = {
    Skills.Hakaze,
    Skills.Yukikaze,
    Skills.Hakaze,
    Skills.Jinpu,
    Skills.Gekko,
    Skills.Hakaze,
    Skills.Shifu,
    Skills.Kasha,
    Skills.MidareSetsugekka
  },

  SenGetsu = { Skills.Hakaze, Skills.Jinpu, Skills.Gekko }, -- Also grants Fugetsu
  SenKa = { Skills.Hakaze, Skills.Shifu, Skills.Kasha }, -- Also grants Fuka
  SenSetsu = { Skills.Hakaze, Skills.Yukikaze }
}

local nearby = {}

local function GetSen()
  local sen = Player.gauge[2]
  local setsu = math.floor(sen / 1) % 2 == 1
  local getsu = math.floor(sen / 2) % 2 == 1
  local ka    = math.floor(sen / 4) % 2 == 1
  return setsu, getsu, ka
end

local function BasicCombo(target)
  local sen = Player.gauge[2]
  local setsu = math.floor(sen / 1) % 2 == 1
  local getsu = math.floor(sen / 2) % 2 == 1
  local ka    = math.floor(sen / 4) % 2 == 1

  -- Perform final part of combo
  if setsu and getsu and ka then
    if ReadyCast(target.id, Skills.MidareSetsugekka) then return true end
  elseif sen > 3 and #nearby > 2 then
    if ReadyCast(target.id, Skills.TenkaGoken) then return true end
  end

  -- Maintain buffs and debuffs
  local playerHasFuka = HasBuff(Player.id, Buffs.Fuka)
  local playerHasFugetsu = HasBuff(Player.id, Buffs.Fugetsu)
  local targetHiganbana = HasBuff(target.id, Buffs.Higanbana)

  if not targetHiganbana and Player.lastcomboid == Skills.Hakaze then
    if ReadyCast(target.id, Skills.Higanbana) then return true end
    return false
  end

  -- Ending of Combo (Above all, don't waste the GCD it took to get here)
  if Player.lastcomboid == Skills.Shifu then
    if ReadyCast(target.id, Skills.Kasha) then return true end
  elseif Player.lastcomboid == Skills.Jinpu then
    if ReadyCast(target.id, Skills.Gekko) then return true end
  end

  -- Intermittent stage of combo
  if Player.lastcomboid == Skills.Hakaze and Player.timesincecast < 30000 then
    -- Generate setsu
    if not setsu then
      if ReadyCast(target.id, Skills.Yukikaze) then return true end
    end

    -- Get Fuka status, will finish combo in next loop
    if not playerHasFuka then
      -- ensure that we aren't using this before refreshing Midare
      if (not setsu and not ka) and (not getsu and not ka) then
        if ReadyCast(target.id, Skills.Shifu) then return true end
      end
    end

    -- Get Fugetsu, will finish combo in next loop
    if not playerHasFugetsu then
      -- ensure that we aren't using this before refreshing Midare
      if (not setsu and not getsu) and (not ka and not getsu) then
        if ReadyCast(target.id, Skills.Jinpu) then return true end
      end
    end

    return false
  elseif Player.lastcomboid == Skills.Fuga then
    -- Get Fuka, will finish combo in next loop
    if not playerHasFuka then
      -- ensure that we aren't using this before refreshing Midare
      if (not setsu and not ka) and (not getsu and not ka) then
        if ReadyCast(target.id, Skills.Oka) then return true end
      end
    end

    -- Get Fugetsu, will finish combo in next loop
    if not playerHasFugetsu then
      -- ensure that we aren't using this before refreshing Midare
      if (not setsu and not ka) and (not getsu and not ka) then
        if ReadyCast(target.id, Skills.Mangetsu) then return true end
      end
    end

    return false
  end

  -- Perform start of combo
  if Samurai.AOE and #nearby > 2 and (not ka and not getsu) then
    if ReadyCast(target.id, Skills.Fuga) then return true end
  else
    if ReadyCast(target.id, Skills.Hakaze) then return true end
  end

  return false
end

local CurrentCombo = {}
function Samurai:Cast(target)
  if #CurrentCombo > 0 then
    local action = ActionList:Get(1, CurrentCombo[1])
    if not table.valid(action) then
      d("Invalid action: " .. tostring(CurrentCombo[1]))
      CurrentCombo = {}
      return false
    end

    if action:IsReady(target.id) then
      if action:Cast(target.id) then
        table.remove(CurrentCombo, 1)
        return true
      end
    end

    return false
  end

  nearby = GetNearbyEnemies(10)
  if BasicCombo(target) then return true end
  return false
end

function Samurai:Draw()
  self.AOE = GUI:Checkbox("AOE Enabled", self.AOE)

end

function Samurai:OnLoad()
  self.AOE = ACR.GetSetting("OpenACR_Samurai_AOEEnabled", true)
end

return Samurai