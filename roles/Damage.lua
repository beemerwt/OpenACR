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

function Damage:Defensives()
  if self.SecondWindEnabled then
    if ReadyCast(Player.id, Skills.SecondWind) then
      return true
    end
  end

  if self.BloodbathEnabled then
    if ReadyCast(Player.id, Skills.Bloodbath) then
      return true
    end
  end

  return false
end

function Damage:Control()

end

-- This is more for utility purposes.
-- Call this function specifically in cases where it's needed.
function Damage:TrueNorth()
  if not self.TrueNorthEnabled then return false end

  local action = ActionList:Get(1, Skills.TrueNorth)
  if action.cd >= 50 and action:IsReady() then
    if action:Cast() then
      return true
    end
  end

  return false
end

function Damage:Draw()
  self.BloodbathEnabled = GUI:Checkbox("Bloodbath", self.BloodbathEnabled)
  self.SecondWindEnabled = GUI:Checkbox("Second Wind", self.SecondWindEnabled)
  self.TrueNorthEnabled = GUI:Checkbox("True North", self.TrueNorthEnabled)
end

function Damage:OnLoad()
  self.BloodbathEnabled = ACR.GetSetting("OpenACR_Damage_BloodbathEnabled", true)
  self.SecondWindEnabled = ACR.GetSetting("OpenACR_Damage_SecondWindEnabled", true)
  self.TrueNorthEnabled = ACR.GetSetting("OpenACR_Damage_TrueNorthEnabled", true)
end

return Damage