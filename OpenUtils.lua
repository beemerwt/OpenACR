--[[
  OpenUtils
  Author: Beemer

  Just utility functions
]]--

OpenACR_IsReady = true
local AwaitDo = ml_global_information.AwaitDo

CachedTarget = nil
CachedAction = {}
CachedBuff = nil

function MGetAction(skillId)
  local memString = "MGetAction;"..tostring(skillId)

  local memoized = GetMemoized(memString)
  if memoized then
    return memoized
  else
    local action = ActionList:Get(1, skillId)
    SetMemoized(memString, skillId)
    return action
  end
end

function IsCapable(skillId)
  if CachedAction.id ~= skillId then
    CachedAction = ActionList:Get(1, skillId)
  end

  return table.valid(CachedAction) and CachedAction.level <= Player.level
end

function IsOnCooldown(skillId)
  if CachedAction.id ~= skillId then
    CachedAction = ActionList:Get(1, skillId)
  end

  return CachedAction.isoncd
end

function IsReady(skillId)
  local action = MGetAction(skillId);
  if action == nil then return false end
  return action:IsReady()
end

function ReadyCast(target, ...)
  for _,skillId in ipairs(arg) do
    local action = MGetAction(skillId)
    if table.valid(action) then
      if action:IsReady(target) then
        if action:Cast(target) then
          return true
        end
      end
    end
  end

  return false
end

function GetNearbyEnemies(radius)
  local attackables = MEntityList("alive,attackable,maxdistance=" .. radius);
  if not table.valid(attackables) then return {} end
  return attackables
end

function GetACRTarget()
  CachedTarget = Player:GetTarget()
  return CachedTarget
end

function ClearCache()
  CachedAction = {}
  CachedBuff = nil
  CachedTarget = nil
end

function LookupSkill(name)
  for actionId, action in pairs(ActionList:Get(1)) do
    if string.contains(string.lower(action.name), string.lower(name)) then
      d(action.name .. ': ' .. tostring(actionId))
    end
  end
end

function ForceCast(skillId, targeted)
  if targeted == nil then targeted = true end
  local targetId = targeted and CachedTarget or Player.id
  local action = ActionList:Get(1, skillId)

  OpenACR_IsReady = false
  AwaitDo(0, 1000, function()
    return Player.lastcastid == skillId
  end,
  function()
    if action:IsReady(targetId) then
      action:Cast(targetId)
    end
  end,
  function()
    OpenACR_IsReady = true
  end)
end