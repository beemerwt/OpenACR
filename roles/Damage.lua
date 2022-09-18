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
  if Player.hp.percent < 35 then
    if ReadyCast(Player.id, Skills.SecondWind) then return true end
  end

  if Player.hp.percent < 50 then
    if ReadyCast(Player.id, Skills.Bloodbath) then return true end
  end

  return false
end

function Damage:Control(target)
  local cinfo = target.castinginfo
  if table.valid(cinfo) then
    if cinfo.castinginterruptible then
      if ReadyCast(target.id, Skills.LegSweep) then
        return true
      end
    end
  end

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

function Damage:Cast(target)
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

function Damage:Draw()
  self.DefensivesEnabled = OpenACR.ListCheckboxItem("Defensives Enabled", self.DefensivesEnabled, 170)
  self.ControlEnabled = OpenACR.ListCheckboxItem("Control Enabled", self.ControlEnabled, 170)
  self.TrueNorthEnabled = OpenACR.ListCheckboxItem("True North", self.TrueNorthEnabled, 170)
end

function Damage:OnLoad()
  self.DefensivesEnabled = ACR.GetSetting("OpenACR_Damage_Defensives", true)
  self.ControlEnabled = ACR.GetSetting("OpenACR_Damage_Control", false)
  self.TrueNorthEnabled = ACR.GetSetting("OpenACR_Damage_TrueNorthEnabled", true)
end

return Damage