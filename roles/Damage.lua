local Damage = {
  DefensivesEnabled = true,
  ControlEnabled = false,
  TrueNorthEnabled = true
}

local Skills = {
  Bloodbath = 7542, -- No GCD
  SecondWind = 7541,
  TrueNorth = 7546,
}

function Damage:Defensives()
  if not self.DefensivesEnabled then return false end

  if Player.hp.percent < 35 then
    if ReadyCast(Player.id, Skills.SecondWind) then return true end
  end

  if Player.hp.percent < 50 then
    if ReadyCast(Player.id, Skills.Bloodbath) then return true end
  end

  return false
end

function Damage:Control()
  if not self.ControlEnabled then return false end
  return false
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
  self.DefensivesEnabled = GUI:Checkbox("Defensives Enabled", self.DefensivesEnabled)
  self.ControlEnabled = GUI:Checkbox("Control Enabled", self.ControlEnabled)
  self.TrueNorthEnabled = GUI:Checkbox("True North", self.TrueNorthEnabled)
end

function Damage:OnLoad()
  self.DefensivesEnabled = ACR.GetSetting("OpenACR_Damage_Defensives", true)
  self.ControlEnabled = ACR.GetSetting("OpenACR_Damage_Control", false)
  self.TrueNorthEnabled = ACR.GetSetting("OpenACR_Damage_TrueNorthEnabled", true)
end

return Damage