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
  if Player.hp.percent < 35 then
    if ReadyCast(Player.id, Skills.Rampart) then return true end
  end

  if Player.hp.percent < 50 then
    if ReadyCast(Player.id, Skills.Reprisal) then return true end
  end

  return false
end

function Tank:Control(target)
  return false
end

function IsFirstEnemyNearbyTargetingMe()
  local el = EntityList("aggro,incombat,attackable,maxdistance=25")
  if not table.valid(el) then return end
  for _,entity in pairs(el) do
    if entity.targetid ~= Player.id then
      return entity
    end
  end
end

-- Provokes the first target that isn't focused on the Tank
function Tank:Provoke()
  local el = EntityList("aggro,incombat,attackable,maxdistance=25")
  if table.valid(el) then
    for id,entity in pairs(el) do
      if entity.targetid ~= Player.id then
        if ReadyCast(id, Skills.Provoke) then
          return true
        end
      end
    end
  end

  return false
end

function Tank:Cast(target)
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