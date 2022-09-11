local Healer = {
  DefensivesEnabled = true,
  ControlEnabled = true
}

function Healer:Defensives()
  if not self.DefensivesEnabled then return false end
  return false
end

function Healer:Control()
  if not self.ControlEnabled then return false end
  return false
end

function Healer:Draw()
  self.DefensivesEnabled = GUI:Checkbox("Defensives Enabled", self.DefensivesEnabled)
  self.ControlEnabled = GUI:Checkbox("Control Enabled", self.ControlEnabled)
end

function Healer:OnLoad()
  self.DefensivesEnabled = ACR.GetSetting("OpenACR_Healer_Defensives", true)
  self.ControlEnabled = ACR.GetSetting("OpenACR_Healer_Control", true)
end


return Healer
