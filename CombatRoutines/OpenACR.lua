-- The Main Profile Hook for OpenACR
OpenACR = {
  MainPath = GetLuaModsPath() .. [[\OpenACR\]],

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

    [FFXIV.JOBS.ARCANIST] = "Arcanist.lua"
  },

  CurrentRole = nil,
  CurrentProfile = nil,
}

local function log(...)
  local str = '[OpenACR] '
  for i,_ in ipairs(arg) do
    str = str .. arg[i]
  end

  d(str)
end

-- Fired when a user pressed "View Profile Options" on the main ACR window.
function OpenACR.OnOpen()
  log('OnOpen Called')
  -- Do some kind of flash to get their attention on the DrawCall window
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

function OpenACR.Cast()
  local target = MGetTarget()
  if target == nil then return false end
  if not target.attackable then return false end

  if OpenACR.CurrentRole:Cast(target) then return true end

  if OpenACR.CurrentProfile and OpenACR.CurrentProfile.Cast then
    if OpenACR.CurrentProfile:Cast(target) then return true end
  end
end

function OpenACR.Draw()
  if not OpenACR.GUI.open then return end

  OpenACR.GUI.visible, OpenACR.GUI.open = GUI:Begin(OpenACR.GUI.name, OpenACR.GUI.open, GUI.WindowFlags_NoResize)

  if OpenACR.GUI.visible then
    GUI:Text("Current Role: " .. GetRoleString(Player.job))
    GUI:Text("Current Class: " .. ffxivminion.classes[Player.job])

    if GUI:Button("Reload Role") then OpenACR.ReloadRole() end
    GUI:SameLine()
    if GUI:Button("Reload Profile") then OpenACR.ReloadProfile() end

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
end

function OpenACR.OnLoad()
  OpenACR.ReloadRole()
  OpenACR.ReloadProfile()
end

-- Just reloads the profile file for player's current job
function OpenACR.ReloadProfile()
  local jobId = Player.job
  log('Loading profile ' .. ffxivminion.classes[jobId])
  if not OpenACR.profiles[jobId] then
    log("Tried loading " .. jobId .. " but no profile was available.")
    return
  end

  local profile, errorMessage = loadfile(OpenACR.MainPath .. [[\classes\]] .. OpenACR.profiles[jobId], "t")
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

  local role, roleError = loadfile(OpenACR.MainPath .. [[\roles\]] .. rolefile, "t")
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

-- Return the profile to ACR, so it can be read.
return OpenACR