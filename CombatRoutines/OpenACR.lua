-- The Main Profile Hook for OpenACR
OpenACR = {
  MainPath = GetLuaModsPath() .. [[\OpenACR]],

  GUI = {
    name = "OpenACR",
    visible = true,
    open = true,
  },

  classes = {
    [FFXIV.JOBS.GLADIATOR] = true,
    [FFXIV.JOBS.MARAUDER] = true,
    -- DRK
    -- GUN
    [FFXIV.JOBS.ROGUE] = true,
    [FFXIV.JOBS.PUGILIST] = true,
    [FFXIV.JOBS.LANCER] = true,

    [FFXIV.JOBS.MONK] = true,
    [FFXIV.JOBS.DRAGOON] = true,
    [FFXIV.JOBS.NINJA] = true,
    [FFXIV.JOBS.SAMURAI] = true,
    [FFXIV.JOBS.REAPER] = true,

    [FFXIV.JOBS.DANCER] = true,
    [FFXIV.JOBS.ARCANIST] = true,
    [FFXIV.JOBS.BLUEMAGE] = true,
  },

  -- All of the jobs implemented so far...
  profiles = {
    -- Base classes
    [FFXIV.JOBS.GLADIATOR] = "Gladiator.lua",
    [FFXIV.JOBS.MARAUDER] = "Marauder.lua",

    [FFXIV.JOBS.PUGILIST] = "Pugilist.lua",
    [FFXIV.JOBS.LANCER] = "Lancer.lua",
    [FFXIV.JOBS.ROGUE] = "Rogue.lua",


    -- Advanced Melee DPS
    [FFXIV.JOBS.MONK] = "Monk.lua",
    [FFXIV.JOBS.DRAGOON] = "Dragoon.lua",
    [FFXIV.JOBS.NINJA] = "Ninja.lua",
    [FFXIV.JOBS.SAMURAI] = "Samurai.lua",
    [FFXIV.JOBS.REAPER] = "Reaper.lua",

    -- Advanced Ranged DPS
    [FFXIV.JOBS.DANCER] = "Dancer.lua",

    [FFXIV.JOBS.ARCANIST] = "Arcanist.lua",
    [FFXIV.JOBS.BLUEMAGE] = "BlueMage.lua",
  },

  CurrentRole = nil,
  CurrentProfile = nil,
}

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

function OpenACR.Cast()
  if not OpenACR.CurrentRole then return false end
  if not OpenACR.CurrentProfile then return false end

  local target = MGetTarget()
  if target == nil then return false end

  if OpenACR.IsPvP and OpenACR.CurrentProfile.PvPCapable then
    if OpenACR.CurrentProfile.PvPCast then
      if OpenACR.CurrentProfile:PvPCast(target) then return true end
    end
  else
    if not target.attackable then return false end
    if OpenACR.CurrentRole:Cast(target) then return true end
    if OpenACR.CurrentProfile.Cast then
      if OpenACR.CurrentProfile:Cast(target) then return true end
    end
  end
end

-- Fired when a user pressed "View Profile Options" on the main ACR window.
function OpenACR.OnOpen()
  OpenACR.GUI.open = true
end

-- Adds a customizable header to the top of the ffxivminion task window.
function OpenACR.DrawHeader()
  if OpenACR.CurrentProfile and OpenACR.CurrentProfile.DrawHeader then
    OpenACR.CurrentProfile:DrawHeader()
  end
end

-- Adds a customizable footer to the top of the ffxivminion task window.
function OpenACR.DrawFooter()
  if OpenACR.CurrentProfile and OpenACR.CurrentProfile.DrawFooter then
    OpenACR.CurrentProfile:DrawFooter()
  end
end

function OpenACR.Draw()
  if not OpenACR.GUI.open then return end

  GUI:SetNextWindowSize(195, 270)
  OpenACR.GUI.visible, OpenACR.GUI.open = GUI:Begin(OpenACR.GUI.name, OpenACR.GUI.open, GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoScrollWithMouse)

  if OpenACR.GUI.visible then
    GUI:AlignFirstTextHeightToWidgets()
    GUI:Text("Current Role: " .. GetRoleString(Player.job))
    GUI:SameLine(140)
    if GUI:Button("Reload") then OpenACR.ReloadRole() end

    GUI:AlignFirstTextHeightToWidgets()
    GUI:Text("Current Class: " .. ffxivminion.classes[Player.job])
    GUI:SameLine(140)
    if GUI:Button("Reload##1") then OpenACR.ReloadProfile() end

    if OpenACR.CurrentRole ~= nil then
      GUI:Separator()
      GUI:Text("Role")
      OpenACR.CurrentRole:Draw()
    end

    if OpenACR.CurrentProfile and OpenACR.CurrentProfile.Draw then
      GUI:Separator()
      GUI:Text("Class")
      OpenACR.CurrentProfile:Draw()
    end
  end

  GUI:End()
end

function OpenACR.OnUpdate(event, tickcount)
  OpenACR.IsPvP = IsPVPMap(Player.localmapid)

  if OpenACR.BotRunning then
    FFXIV_Common_BotRunning = false

    if ml_task_hub:CurrentTask() ~= nil then
      ml_task_hub:Update()
    end
  end

  if OpenACR.CurrentProfile and OpenACR.CurrentProfile.Update then
    OpenACR.CurrentProfile:Update()
  end
end

function OpenACR.OnLoad()
  OpenACR.ReloadRole()
  OpenACR.ReloadProfile()
  OpenACR.LoadSettings()
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
    if OpenACR.CurrentProfile and OpenACR.CurrentProfile.OnLoad then
      OpenACR.CurrentProfile:OnLoad()
    end
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
  align_x = align_x == nil and 170 or align_x
  GUI:Text(text) GUI:SameLine(align_x)
  return GUI:Checkbox("##"..text, value)
end

-- Return the profile to ACR, so it can be read.
return OpenACR