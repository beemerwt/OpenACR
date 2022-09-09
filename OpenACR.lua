local OpenACR = {
  routines = GetStartupPath() .. [[\LuaMods\OpenACR\routines\]],
  GUI = {
    visible = false,
    open = true,
  },

  classes = {
    [FFXIV.JOBS.NINJA] = true,
    [FFXIV.JOBS.ROGUE] = true,
  },

  Profiles = {},
  CurrentProfile = nil
}

local CachedTarget = nil
local CachedAction = {}
local CachedBuff = nil

OpenACR_IsReady = true

local AwaitDo = ml_global_information.AwaitDo

-- Adds a customizable header to the top of the ffxivminion task window.
function OpenACR.DrawHeader()

end

function OpenACR.DrawCall(event, ticks)
	local gamestate;
	if (GetGameState and GetGameState()) then
		gamestate = GetGameState()
	else
		gamestate = 3
	end

  if ( gamestate == FFXIV.GAMESTATE.INGAME ) then
    OpenACR.GUI.visible, OpenACR.GUI.open = GUI:Begin("Open ACR", OpenACR.GUI.open)
    GUI:Text("Current Class: " .. ffxivminion.classes[Player.job])
    GUI:Separator()
    if OpenACR.CurrentProfile ~= nil and OpenACR.CurrentProfile.Draw then
      OpenACR.CurrentProfile.Draw()
    end
    GUI:End()
	end
end

-- Fired when a user pressed "View Profile Options" on the main ACR window.
function OpenACR.OnOpen()
  -- Do some kind of flash to get their attention on the DrawCall window
  OpenACR.GUI.open = true
end

-- Adds a customizable footer to the top of the ffxivminion task window.
function OpenACR.DrawFooter()

end

function OpenACR.ModuleInit()
  ACR.AddPrivateProfile(OpenACR, "OpenACR")
end

RegisterEventHandler("Gameloop.Draw", OpenACR.DrawCall, "OpenACR.DrawCall")
RegisterEventHandler("Module.Initalize", OpenACR.ModuleInit, "OpenACR.ModuleInit")