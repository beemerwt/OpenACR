local profile = {

  AOEEnabled = true
}

local Skills = {
  MeikyoShisui = 7499,
  Gekko = 7481,
  Kasha = 7482,
  Shifu = 7479,
  Shoha = 16487,
  Enpi = 7486,
  Hagakure = 7495,
  Ikishoten = 16482,
  Yukikaze = 7480,
  Hakaze = 7477,
  Higanbana = 7489,

  HissatsuSenei = 16481,
  HissatsuShinten = 7490,
  HissatsuGyoten = 7492,
  HissatsuYaten = 7493,

  MidareSetsugekka = 7487,
  KaeshiSetsugekka = 16486,

  OgiNamikiri = 25781,
  KaeshiNamikiri = 25782,
}

local Buffs = {
  Fuka = 1299, -- Cooldown Reduction
  Fugetsu = 1298, -- Increase Damage
  Higanbana = 1228, -- Damage over Time
}

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

local CurrentCombo = {}
function profile.Cast(target)
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

  local nearby = GetNearbyEnemies(10)

  -- Maintain buffs and debuffs
  local targetHiganbana = GetTargetDebuff(Buffs.Higanbana)
  local playerHasFuka = PlayerHasBuff(Buffs.Fuka)
  local playerHasFugetsu = PlayerHasBuff(Buffs.Fugetsu)

  if not targetHiganbana or targetHiganbana.duration < 8 then
    CurrentCombo = table.shallowcopy(Combos.SenSetsu)
    table.insert(CurrentCombo, Skills.Higanbana)
    return true
  end

  if #nearby > 1 and profile.AOEEnabled then
    if not playerHasFuka then
      CurrentCombo = table.shallowcopy(Combos.FugaOka)
      return true
    end

    if not playerHasFugetsu then
      CurrentCombo = table.shallowcopy(Combos.FugaMangetsu)
      return true
    end
  else
    if not playerHasFuka then
      CurrentCombo = table.shallowcopy(Combos.SenKa)
      return true
    end

    if not playerHasFugetsu then
      CurrentCombo = table.shallowcopy(Combos.SenGetsu)
      return true
    end
  end

  return false
end

function profile.Draw()
  profile.AOEEnabled = GUI:Checkbox("AOE Enabled", profile.AOEEnabled)

end

function profile.OnLoad()
  profile.AOEEnabled = ACR.GetSetting("OpenACR_Samurai_AOEEnabled", true)
end

return profile