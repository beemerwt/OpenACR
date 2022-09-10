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

function ReadyCast(target, ...)
  for _,v in ipairs(arg) do
    local action = ActionList:Get(1, v)
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
  local attackables = MEntityList("alive,attackable");
  if not table.valid(attackables) then return {} end

  -- Gets targets within range of AOE attacks centered on player
  local nearby = FilterByProximity(attackables, Player.pos, radius);
  if not table.valid(nearby) then return {} end

  return nearby
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

function GetTargetDebuff(buff)
  for i,_ in ipairs(CachedTarget.buffs) do
    if CachedTarget.buffs[i].id == buff then
      return CachedTarget.buffs[i]
    end
  end

  return nil
end

function GetPlayerBuff(buff)
  for i,_ in ipairs(Player.buffs) do
    if Player.buffs[i].id == buff then
      return Player.buffs[i]
    end
  end

  return nil
end

function TargetHasDebuff(debuff)
  debuff = GetTargetDebuff(debuff)
  return debuff ~= nil
end

function PlayerHasBuff(buff)
  buff = GetPlayerBuff(buff)
  return buff ~= nil
end

function LookupSkill(name)
  for actionId, action in pairs(ActionList:Get(1)) do
    if string.contains(string.lower(action.name), string.lower(name)) and action.level ~= 0 then
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