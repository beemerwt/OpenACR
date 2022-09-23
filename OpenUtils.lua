--[[
  OpenUtils
  Author: Beemer

  Just utility functions
]]--

OpenACR_IsReady = true
local AwaitThen = ml_global_information.AwaitThen
local AwaitDo = ml_global_information.AwaitDo

function abstractFrom(t, ...)
  local abstract = table.shallowcopy(t)
  for k, v in pairs(arg) do
    if k ~= "n" then
      if type(v) == "table" then
        for x, y in pairs(v) do
          abstract[x] = y
        end
      else
        abstract[k] = v
      end
    end
  end

  return abstract
end

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
    SetMemoized(memString, action)
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

--- Gets the flattened version of all tables within a table
function table.combine(t, ...)
  local tArgs = { ... }

  for i = 1,#tArgs do
    table.insert(t, tArgs[i])
  end

  local hadTable = false
  for i = 1,#t do
    if type(t[i]) == "table" then
      hadTable = true
      for k, v in pairs(t[i]) do
        table.insert(t, v)
      end
      table.remove(t, i)
    end
  end

  if not hadTable then return t end
  return table.combine(t)
end

-- arg = {...} | arg(tbl, num) = { {tbl}, num }
-- want to unpack tbl

function ReadyCast(targetId, ...)
  local tArgs = {...}
  local wasCast = false
  local t = table.combine({}, tArgs)

  for _,skillId in ipairs(t) do
    local action = MGetAction(skillId)
    if table.valid(action) then
      if action:IsReady(targetId) then
        if action:Cast(targetId) then
          wasCast = true
        else
          local tarStr = targetId == Player.id and "self" or tostring(targetId)
          d(tostring(skillId) .. " was not casted, despite being ready on " .. tarStr)
        end
      end
    end
  end

  return wasCast
end

function GetNearbyEnemies(radius)
  return GetEnemiesNearTarget(Player, 0, radius)
end

function GetNearbyHeals(radius)
  local el = EntityList("alive,friendly,maxdistance=" .. tostring(radius))
  if table.valid(el) then
    return el
  end

  return {}
end

-- Looks up a skill by name and if they have a level requirement
---@param name string
---@param levelIsReq boolean
function LookupSkill(name, levelIsReq, jobIsReq)
  if levelIsReq == nil then levelIsReq = true end
  if jobIsReq == nil then jobIsReq = true end

  for actionId, action in pairs(ActionList:Get(1)) do
    if string.contains(string.lower(action.name), string.lower(name)) then
      if not levelIsReq or (levelIsReq and action.level > 0) then
        if not jobIsReq or (jobIsReq and action.job == Player.job) then
          d("[" .. ffxivminion.classes[Player.job] .. "] " .. action.name .. ': ' .. tostring(actionId))
        end
      end
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