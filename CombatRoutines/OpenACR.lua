-- The Main Profile Hook for OpenACR
OpenACR = {
  MainPath = GetLuaModsPath() .. [[\OpenACR\]],

  GUI = {
    name = "OpenACR",
    visible = false,
    open = true,
  },

  classes = {
    [FFXIV.JOBS.NINJA] = true,
    [FFXIV.JOBS.ROGUE] = true
  },

  -- All of the jobs implemented so far...
  profiles = {
    [FFXIV.JOBS.NINJA] = "OpenNinja.lua",
    [FFXIV.JOBS.ROGUE] = "OpenNinja.lua",
  },

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
    OpenACR.CurrentProfile.DrawHeader()
  end
end

-- Adds a customizable footer to the top of the ffxivminion task window.
function OpenACR.DrawFooter()
  if OpenACR.CurrentProfile and OpenACR.CurrentProfile.DrawFooter then
    OpenACR.CurrentProfile.DrawFooter()
  end
end

function OpenACR.Cast()
  if OpenACR.CurrentProfile and OpenACR.CurrentProfile.Cast then
    OpenACR.CurrentProfile.Cast()
  end
end

function OpenACR.Draw()
  OpenACR.GUI.visible, OpenACR.GUI.open = GUI:Begin(OpenACR.GUI.name, OpenACR.GUI.open)

  GUI:AlignFirstTextHeightToWidgets()

  -- GUI:SetColumnWidth(-1, GUI:GetWindowWidth())
  GUI:Text("Current Class: " .. ffxivminion.classes[Player.job])

  GUI:PushItemWidth(-1.0)
  if GUI:Button("Reload") then OpenACR.ReloadProfile() end
  GUI:PopItemWidth()

  if OpenACR.CurrentProfile and OpenACR.CurrentProfile.Draw then
    GUI:Separator()
    OpenACR.CurrentProfile.Draw()
  end

  GUI:End()
end

local isNoticeActive = false
function OpenACR.OnUpdate(event, tickcount)
  --[[
  if OpenACR.CurrentProfile == nil and not isNoticeActive then
    isNoticeActive = true
    ffxiv_dialog_manager.IssueStopNotice("OpenACR", "A profile for this class does not exist or was unable to load.")
  end
  ]]--
end

function OpenACR.OnLoad()
  local jobId = Player.job
  OpenACR.CurrentProfile = OpenACR.LoadProfile(jobId)
  if OpenACR.CurrentProfile and OpenACR.CurrentProfile.OnLoad then
    OpenACR.CurrentProfile.OnLoad()
  end
end

-- Just reloads the profile file for player's current job
function OpenACR.ReloadProfile()
  log('Reloading profile')
  OpenACR.OnLoad()
end

-- Loads profile from jobId
function OpenACR.LoadProfile(jobId)
  log('Loading profile ' .. ffxivminion.classes[jobId])
  if not OpenACR.profiles[jobId] then
    log("Tried loading " .. jobId .. " but no profile was available.")
    return nil
  end

  local profile, errorMessage = loadfile(OpenACR.MainPath .. [[\classes\]] .. OpenACR.profiles[jobId], "t")
  if profile then
    return profile()
  end

  -- ffxiv_dialog_manager.IssueNotice("Unable to load profile for " .. ffxivminion.classes[jobId], errorMessage)
  return nil
end

-- Return the profile to ACR, so it can be read.
return OpenACR