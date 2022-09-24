-- The Main Profile Hook for OpenACR
OpenACR = {
  MainPath = GetLuaModsPath() .. [[\OpenACR]],

  GUI = {
    name = "OpenACR",
    visible = true,
    open = true,
  },

  MonitoredSkills = {},

  classes = {
    [FFXIV.JOBS.GLADIATOR] = true,
    [FFXIV.JOBS.MARAUDER] = true,
    -- DRK
    -- GUN
    [FFXIV.JOBS.ROGUE] = true,
    [FFXIV.JOBS.PUGILIST] = true,
    [FFXIV.JOBS.LANCER] = true,

    [FFXIV.JOBS.SCHOLAR] = true,

    [FFXIV.JOBS.MONK] = true,
    [FFXIV.JOBS.DRAGOON] = true,
    [FFXIV.JOBS.NINJA] = true,
    [FFXIV.JOBS.SAMURAI] = true,
    [FFXIV.JOBS.REAPER] = true,

    [FFXIV.JOBS.DANCER] = true,
    [FFXIV.JOBS.ARCANIST] = true,
    [FFXIV.JOBS.BLUEMAGE] = true,

    [FFXIV.JOBS.LEATHERWORKER] = true
  },

  -- All of the jobs implemented so far...
  profiles = {
    -- Base classes
    [FFXIV.JOBS.GLADIATOR] = "base\\Gladiator.lua",
    [FFXIV.JOBS.MARAUDER] = "base\\Marauder.lua",

    [FFXIV.JOBS.PUGILIST] = "base\\Pugilist.lua",
    [FFXIV.JOBS.LANCER] = "base\\Lancer.lua",
    [FFXIV.JOBS.ROGUE] = "base\\Rogue.lua",
    [FFXIV.JOBS.ARCANIST] = "base\\Arcanist.lua",

    -- Advanced Melee DPS
    [FFXIV.JOBS.MONK] = "damage\\Monk.lua",
    [FFXIV.JOBS.DRAGOON] = "damage\\Dragoon.lua",
    [FFXIV.JOBS.NINJA] = "damage\\Ninja.lua",
    [FFXIV.JOBS.SAMURAI] = "damage\\Samurai.lua",
    [FFXIV.JOBS.REAPER] = "damage\\Reaper.lua",

    [FFXIV.JOBS.SCHOLAR] = "healer\\Scholar.lua",

    -- Advanced Ranged DPS
    [FFXIV.JOBS.DANCER] = "damage\\Dancer.lua",

    [FFXIV.JOBS.BLUEMAGE] = "damage\\BlueMage.lua",

    [FFXIV.JOBS.LEATHERWORKER] = "crafter\\basic.lua"
  },

  CurrentRole = nil,
  CurrentProfile = nil,
}

OpenACR.DefaultProfile = {
  OnLoad = function(self) end,
  Update = function(self) end,

  DrawHeader = function(self) end,
  Draw = function(self) end,
  DrawFooter = function(self) end,
}

OpenACR.CombatProfile = abstractFrom(OpenACR.DefaultProfile, {
  IsPvPCapable = function(self) return false end,
  Cast = function(self) return false end,
  PvPCast = function(self) return false end,
})

OpenACR.CraftingProfile = abstractFrom(OpenACR.DefaultProfile, {
  Perform = function(self) return false end
})

OpenACR.RolePath = OpenACR.MainPath .. [[\roles\]]
OpenACR.ClassPath = OpenACR.MainPath .. [[\classes\]]

-- Handles all settings that are not relevant to the individual ACR.
-- Like GUI, unlocks, etc.
OpenACR.SettingsFile = OpenACR.MainPath .. [[\data\settings.lua]]
OpenACR.Settings = {}

OpenACR.IsPvP = false

local function log(...)
  local str = '[OpenACR] '
  for i,_ in ipairs(arg) do
    str = str .. arg[i]
  end

  d(str)
end

function OpenACR.Craft()
  return OpenACR.CurrentProfile:Perform()
end

function OpenACR.Combat()
  if OpenACR.CurrentRole == nil then return false end
  if OpenACR.CurrentRole:Cast() then return true end
  if OpenACR.CurrentProfile:Cast() then return true end
end

function OpenACR.PvP()
  local target = MGetTarget()
  return OpenACR.CurrentProfile:PvPCast(target)
end

function OpenACR.Cast()
  if not Player.alive then return false end
  if OpenACR.CurrentProfile == nil then return false end

  if IsCrafter(Player.job) then
    return OpenACR.Craft()
  elseif OpenACR.IsPvP and OpenACR.CurrentProfile:IsPvPCapable() then
    return OpenACR.PvP()
  else
    return OpenACR.Combat()
  end
end

-- Fired when a user pressed "View Profile Options" on the main ACR window.
function OpenACR.OnOpen()
  OpenACR.GUI.open = true
end

-- Adds a customizable header to the top of the ffxivminion task window.
function OpenACR.DrawHeader()
  OpenACR.CurrentProfile:DrawHeader()
end

-- Adds a customizable footer to the top of the ffxivminion task window.
function OpenACR.DrawFooter()
  OpenACR.CurrentProfile:DrawFooter()
end

function OpenACR.Draw()
  if not OpenACR.GUI.open then return end

  GUI:SetNextWindowSize(225, 270)
  OpenACR.GUI.visible, OpenACR.GUI.open = GUI:Begin(OpenACR.GUI.name, OpenACR.GUI.open, GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoScrollWithMouse)

  if OpenACR.GUI.visible then
    GUI:AlignFirstTextHeightToWidgets()
    GUI:Text("Current Role: " .. GetRoleString(Player.job))
    GUI:SameLine(140)
    if OpenACR.RightButton("Reload") then OpenACR.ReloadRole() end

    GUI:AlignFirstTextHeightToWidgets()
    GUI:Text("Current Class: " .. ffxivminion.classes[Player.job])
    GUI:SameLine(140)
    if OpenACR.RightButton("Reload##1") then OpenACR.ReloadProfile() end

    if OpenACR.CurrentRole then
      GUI:Separator()
      GUI:Text("Role")
      OpenACR.CurrentRole:Draw()
    end

    if OpenACR.CurrentProfile then
      GUI:Separator()
      GUI:Text("Class")
      OpenACR.CurrentProfile:Draw()
    end
  end

  GUI:End()
end

local function Monitor(skill)
  local action = ActionList:Get(1, skill.id)

  local isPlayerReady = action:IsReady(Player.id)
  if skill.wasPlayerReady ~= isPlayerReady then
    d("IsReady for Player on " .. action.name .. " changed to " .. tostring(isPlayerReady) .. " after " .. tostring(Player.castinginfo.lastcastid))
    skill.wasPlayerReady = isPlayerReady
  end

  local target = Player:GetTarget()
  if target ~= nil then
    local isTargetReady = action:IsReady(target.id)
    if skill.wasTargetReady ~= isTargetReady then
      d("IsReady for Target on " .. action.name .. " changed to " .. tostring(isTargetReady) .. " after " .. tostring(Player.castinginfo.lastcastid))
      skill.wasTargetReady = isTargetReady
    end
  end

  return skill
end

function OpenACR.OnUpdate(event, tickcount)
  if not OpenACR.CurrentProfile then return end
  OpenACR.IsPvP = IsPVPMap(Player.localmapid)

  if OpenACR.BotRunning then
    FFXIV_Common_BotRunning = false

    if ml_task_hub:CurrentTask() ~= nil then
      ml_task_hub:Update()
    end
  end

  OpenACR.CurrentProfile:Update()

  for i,_ in ipairs(OpenACR.MonitoredSkills) do
    OpenACR.MonitoredSkills[i] = Monitor(OpenACR.MonitoredSkills[i])
  end
end

function OpenACR.OnLoad()
  OpenACR.ReloadRole()
  OpenACR.ReloadProfile()
  OpenACR.LoadSettings()
end

function OpenACR.MonitorSkill(skillId)
  if not table.contains(OpenACR.MonitoredSkills, skillId) then
    d("Monitoring " .. tostring(skillId))
    table.insert(OpenACR.MonitoredSkills, { id = skillId })
  end
end

-- Just reloads the profile file for player's current job
function OpenACR.ReloadProfile()
  local jobId = Player.job
  log('Loading profile ' .. ffxivminion.classes[jobId])
  if not OpenACR.profiles[jobId] then
    log("Tried loading " .. jobId .. " but no profile was available.")
    return
  end

  local profile, errorMessage = loadfile(OpenACR.ClassPath .. OpenACR.profiles[jobId], "t")
  if profile then
    OpenACR.CurrentProfile = profile()
    OpenACR.CurrentProfile:OnLoad()
  else
    log('An error occurred while loading ' .. ffxivminion.classes[jobId] .. ' profile...')
    log(errorMessage)
  end
end

function OpenACR.ReloadRole()
  local rolestr = GetRoleString(Player.job)
  local rolefile = rolestr == "DPS" and "Damage.lua"
    or rolestr == "Healer" and "Healer.lua"
    or rolestr == "Tank" and "Tank.lua"
    or nil

  if rolefile then
    local role, roleError = loadfile(OpenACR.RolePath .. rolefile, "t")
    if role then
      OpenACR.CurrentRole = role()
      if OpenACR.CurrentRole then
        OpenACR.CurrentRole:OnLoad()
      end
    else
      log('An error occurred while loading ' .. rolestr .. ' role...')
      log(roleError)
    end
  end
end

function OpenACR.SaveSettings(key, value)
  if key == nil then
    local wasSaved = FileSave(OpenACR.MainPath .. [[\data\settings.lua]], OpenACR.Settings)
    if not wasSaved then d("There was an error saving user settings.") end
    return wasSaved
  else
    OpenACR.Settings[key] = value
    OpenACR.SaveSettings()
  end
end

function OpenACR.LoadSettings()
  if not FileExists(OpenACR.SettingsFile) then
    OpenACR.SaveSettings() -- Will save default settings
  else
    OpenACR.Settings = FileLoad(OpenACR.SettingsFile)
  end
end

function OpenACR.ListCheckboxItem(text, value, align_x)
  GUI:AlignFirstTextHeightToWidgets()
  align_x = align_x == nil and 185 or align_x
  GUI:Text(text) GUI:SameLine(align_x)
  return GUI:Checkbox("##"..text, value)
end

function OpenACR.RightButton(text, value)
  local x,_ = GUI:CalcTextSize(text)
  local w,_= GUI:GetWindowSize()
  local leftOfButton = w - 5 - x - 5
  return GUI:Button(text, value)
end

-- Return the profile to ACR, so it can be read.
return OpenACR