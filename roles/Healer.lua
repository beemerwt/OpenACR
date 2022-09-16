local Healer = {
  DefensivesEnabled = true,
  ControlEnabled = true
}

function Healer:Defensives()
  return false
end

function Healer:Control(target)
  return false
end

function Healer:Cast(target)
  -- TODO: Make HP Percent adjustable
  if self.DefensivesEnabled then
    if self:Defensives() then
      return true
    end
  end

  if self.ControlEnabled then
    if self:Control(target) then
      return true
    end
  end

  return false
end

function Healer:Draw()
  self.DefensivesEnabled = OpenACR.ListCheckboxItem("Defensives Enabled", self.DefensivesEnabled, 170)
  self.ControlEnabled = OpenACR.ListCheckboxItem("Control Enabled", self.ControlEnabled, 170)
end

function Healer:OnLoad()
  self.DefensivesEnabled = ACR.GetSetting("OpenACR_Healer_Defensives", true)
  self.ControlEnabled = ACR.GetSetting("OpenACR_Healer_Control", true)
end


return Healer
