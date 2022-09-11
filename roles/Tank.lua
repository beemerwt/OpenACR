local Tank = {
  DefensivesEnabled = true,
  ControlEnabled = false,
  ProvokeEnabled = true,
}

local Skills = {
  -- Defensives
  Rampart = 7531,
  Reprisal = 7535,

  -- Control
  LowBlow = 7540,
  Interject = 7538,

  Provoke = 7533,
  ArmsLength = 7548,
  Shirk = 7537,
}

function Tank:Defensives()
  if not self.DefensivesEnabled then return false end

  if Player.hp.percent < 35 then
    if ReadyCast(Player.id, Skills.Rampart) then return true end
  end

  if Player.hp.percent < 50 then
    if ReadyCast(Player.id, Skills.Reprisal) then return true end
  end

  return false
end

function Tank:Provoke()
  
end

function Tank:Draw()
  self.DefensivesEnabled = GUI:Checkbox("Defensives Enabled", self.DefensivesEnabled)
  self.ControlEnabled = GUI:Checkbox("Control Enabled", self.ControlEnabled)
  self.ProvokeEnabled = GUI:Checkbox("Provoke", self.ProvokeEnabled)
end

function Tank:OnLoad()
  self.DefensivesEnabled = ACR.GetSetting("OpenACR_Tank_Defensives", true)
  self.ControlEnabled = ACR.GetSetting("OpenACR_Tank_Control", false)
  self.ProvokeEnabled = ACR.GetSetting("OpenACR_Tank_Provoke", true)
end

return Tank