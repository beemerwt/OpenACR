--[[
  OpenUtils
  Author: Beemer

  Just utility functions
]]--

OpenACR_IsReady = true
local AwaitThen = ml_global_information.AwaitThen
local AwaitDo = ml_global_information.AwaitDo

function LookupDuty(name)
  local dutyList = Duty:GetDutyList()
  if not dutyList then
    SendTextCommand("/finder")
  end

  for k,v in pairs(dutyList) do
    if string.contains(string.lower(v.name), string.lower(name)) then
      d(v.name .. ': ' .. tostring(v.id))
    end
  end
end

----------------------------------------------------------------------
--
-- Combat
--
----------------------------------------------------------------------
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

function IsActive(skillId)
  local action = MGetAction(skillId)
  return table.valid(action) and action.usable
end

function IsCapable(skillId)
  local action = MGetAction(skillId)
  return table.valid(action) and action.level <= Player.level
end

function IsOnCooldown(skillId)
  local action = MGetAction(skillId)
  if table.valid(action) then
    return action.isoncd
  end

  return true
end

function IsReady(skillId)
  local action = MGetAction(skillId)
  return table.valid(action) and action:IsReady()
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
  return GetEnemiesNearTarget(Player, 0, radius)
end

function LookupSkill(name)
  for actionId, action in pairs(ActionList:Get(1)) do
    if string.contains(string.lower(action.name), string.lower(name)) then
      d(action.name .. ': ' .. tostring(actionId))
    end
  end
end

function GetEnemiesNearTarget(target, range, radius)
  range = range + radius
	local el = EntityList("alive,attackable,maxdistance=" .. tostring(range))
  if table.valid(el) then
    local proximity = FilterByProximity(el, target.pos, radius)
    if table.valid(proximity) then return proximity end
  end

  return {}
end

----------------------------------------------------------------------
--
-- Navigation
--
----------------------------------------------------------------------
local ForceStop = false
local CurrentNav = nil

function ForceStopMovement()
  d("force stopping movement")
  ForceStop = true
end

function TeleportThenMove(unlock)
  if not ActionIsReady(7,5) then return end

  if Player.localmapid == unlock.map then
    Player:MoveTo(unlock.pos.x, unlock.pos.y, unlock.pos.z)
    return
  end

  ForceStop = false
  Player:Teleport(unlock.node)
  ml_global_information.AwaitThen(5000, 10000,
    function()
      return (not IsLoading() and Player.localmapid == unlock.map) or ForceStop
    end,
    function()
      if ForceStop then return end
      if Player.localmapid ~= unlock.map then return end
      TeleportThenMove(unlock)
    end
  )
end