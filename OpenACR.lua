local OpenACR = {}
local CachedAction = {}

function OpenACR.LoadBehaviorFiles()
  local dataFiles = GetModuleFiles("data")
end

function IsCapable(skillId)
  local action = ActionList:Get(1, skillId)
  return table.valid(action)
    and action.level <= Player.level
end

local function distToTarget(target)
  return math.distance2d(Player.pos.x, Player.pos.z, target.pos.x, target.pos.z)
end

function CastOnTarget(skillId, target)
  if CachedAction.id ~= skillId then
    CachedAction = ActionList:Get(1, skillId)
  end

  return CachedAction:Cast(target.id)
end

function CastOnSelf(skillId)
  if CachedAction.id ~= skillId then
    CachedAction = ActionList:Get(1, skillId)
  end

  return CachedAction:Cast()
end

function SkillIsActuallyReadyOnTarget(skillId, target)
  if CachedAction.id ~= skillId then
    CachedAction = ActionList:Get(1, skillId)
  end

  return CachedAction:IsReady(target.id)
    and not CachedAction.isoncd
end

function ClearCache()
  CachedAction = {}
end

function GetTargetDebuff(target, buff)
  for i,_ in ipairs(target.buffs) do
    if target.buffs[i].id == buff then
      return target.buffs[i]
    end
  end

  return nil
end

function PlayerHasBuff(buff)
  for i,_ in ipairs(Player.buffs) do
    if Player.buffs[i].id == buff then
      return true
    end
  end

  return false
end

function LookupSkill(name)
  for actionId, action in pairs(ActionList:Get(1)) do
    if string.contains(string.lower(action.name), string.lower(name)) and action.level ~= 0 then
      d(action.name .. ': ' .. tostring(actionId))
    end
  end
end