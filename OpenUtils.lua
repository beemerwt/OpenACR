--[[
  OpenUtils
  Author: Beemer

  Just utility functions
]]--

function IsCapable(skillId)
  local action = ActionList:Get(1, skillId)
  return table.valid(action) and action.level <= Player.level
end

function CastOnTarget(skillId)
  if CachedAction.id ~= skillId then
    CachedAction = ActionList:Get(1, skillId)
  end

  return CachedAction:Cast(CachedTarget.id)
end

function CastOnSelf(skillId)
  if CachedAction.id ~= skillId then
    CachedAction = ActionList:Get(1, skillId)
  end

  return CachedAction:Cast()
end

function CanCastOnSelf(skillId)
  if CachedAction.id ~= skillId then
    CachedAction = ActionList:Get(1, skillId)
  end

  return CachedAction:IsReady()
end

function ReadyCast(target, ...)
  for _,v in pairs(arg) do
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

function IsOnCooldown(skillId)
  if CachedAction.id ~= skillId then
    CachedAction = ActionList:Get(1, skillId)
  end

  return CachedAction.isoncd
end

function CanCastOnTarget(skillId)
  if CachedAction.id ~= skillId then
    CachedAction = ActionList:Get(1, skillId)
  end

  return not CachedAction.isoncd
    and CachedAction:IsReady(CachedTarget.id);
end

function CastOnTargetIfPossible(skillId)
  if CanCastOnTarget(skillId) then
    if CastOnTarget(skillId) then
      return true
    end
  end

  return false
end

function CastOnSelfIfPossible(skillId)
  if CanCastOnSelf(skillId) then
    if CastOnSelf(skillId) then
      return true
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