local OpenACR = {}
local CachedTarget = nil
local CachedAction = {}
local CachedBuff = nil

OpenACR_IsReady = true

--[[
  Useful notes about minionlib api

  ml_global_information has a lot of good coroutine functionality

  function AwaitDo(mintimer, maxtimer, evaluator, dowhile, followall)
    -- It will NEVER continue until evaluator is true or maxtimer
    -- It will ONLY continue when mintimer has passed
    -- dowhile AND followall will ALWAYS execute
    -- evaluator determines within the time when it finishes, which then calls followall
]]--

function OpenACR.LoadBehaviorFiles()
  local dataFiles = GetModuleFiles("data")
end

function IsCapable(skillId)
  local action = ActionList:Get(1, skillId)
  return table.valid(action)
    and action.level <= Player.level
end

local function distToTarget()
  return math.distance2d(Player.pos.x, Player.pos.z, CachedTarget.pos.x, CachedTarget.pos.z)
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
    and not CachedAction.isoncd
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
  local debuff = GetTargetDebuff(debuff)
  return debuf ~= nil
end

function PlayerHasBuff(buff)
  local buff = GetPlayerBuff(buff)
  return buff ~= nil
end

function LookupSkill(name)
  for actionId, action in pairs(ActionList:Get(1)) do
    if string.contains(string.lower(action.name), string.lower(name)) and action.level ~= 0 then
      d(action.name .. ': ' .. tostring(actionId))
    end
  end
end