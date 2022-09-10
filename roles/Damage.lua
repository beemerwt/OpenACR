local Damage = {
  BloodbathEnabled = true,
  SecondWindEnabled = true,
  TrueNorthEnabled = true
}

local Skills = {
  Bloodbath = 7542, -- No GCD
  SecondWind = 7541,
  TrueNorth = 7546,
}

function Damage.Defensives()
  if Damage.SecondWindEnabled then
    if CastOnSelfIfPossible(Skills.SecondWind) then
      return true
    end
  end

  if Damage.BloodbathEnabled then
    if CastOnSelfIfPossible(Skills.Bloodbath) then
      return true
    end
  end

  return false
end

function Damage.Control()

end

-- This is more for utility purposes.
-- Call this function specifically in cases where it's needed.
function Damage.TrueNorth()
  if not Damage.TrueNorthEnabled then return false end

  local action = ActionList:Get(1, Skills.TrueNorth)
  if action.cd >= 50 and action:IsReady() then
    if action:Cast() then
      return true
    end
  end

  return false
end

function Damage.Draw()
  Damage.BloodbathEnabled = GUI:Checkbox("Bloodbath", Damage.BloodbathEnabled)
  Damage.SecondWindEnabled = GUI:Checkbox("Second Wind", Damage.SecondWindEnabled)
  Damage.TrueNorthEnabled = GUI:Checkbox("True North", Damage.TrueNorthEnabled)
end

function Damage.OnLoad()
  Damage.BloodbathEnabled = ACR.GetSetting("OpenACR_Damage_BloodbathEnabled", true)
  Damage.SecondWindEnabled = ACR.GetSetting("OpenACR_Damage_SecondWindEnabled", true)
  Damage.TrueNorthEnabled = ACR.GetSetting("OpenACR_Damage_TrueNorthEnabled", true)
end

return Damage