local Tank = abstractFrom(OpenACR.CombatProfile)

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
  local nearby = GetNearbyEnemies(5)
  if #nearby > 4 or (Player.hp.percent < 50 and #nearby > 2) then
    if ReadyCast(Player.id, Skills.Reprisal) then return true end
  end

  if Player.hp.percent < 35 or (Player.hp.percent < 50 and #nearby < 3) then
    if ReadyCast(Player.id, Skills.Rampart) then return true end
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
  self.DefensivesEnabled = OpenACR.ListCheckboxItem("Defensives Enabled", self.DefensivesEnabled)
  self.ControlEnabled = OpenACR.ListCheckboxItem("Control Enabled", self.ControlEnabled)
  self.ProvokeEnabled = OpenACR.ListCheckboxItem("Provoke", self.ProvokeEnabled)
end

function Tank:OnLoad()
  self.DefensivesEnabled = ACR.GetSetting("OpenACR_Tank_Defensives", true)
  self.ControlEnabled = ACR.GetSetting("OpenACR_Tank_Control", false)
  self.ProvokeEnabled = ACR.GetSetting("OpenACR_Tank_Provoke", true)
end

return Tank