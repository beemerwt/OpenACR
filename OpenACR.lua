local OpenACR = {
  ninja = {
    range = 2,
    pveOptionsPath = GetStartupPath()..[[\LuaMods\ffxivminion\class_routines\]].."openacr_ninja_pve.info",
    pvpOptionsPath = GetStartupPath()..[[\LuaMods\OpenACR\\class_routines\]].."openacr_ninja_pvp.info",
    defaults = {
      gRestHP = 75,
      gRestMP = 0,
      gPotionHP = 50,
      gPotionMP = 0,
      gFleeHP = 35,
      gFleeMP = 0,
      gUseSprint = "0",
    }
  },

  active = {
    routine = nil
  }
}

local function GetRoutine()
  -- It will load the file into a lua string that can be parsed or passed to loadstring to be executed
  local fileString = ReadModuleFile({
    m = "OpenACR",
    p = "classes",
    f = class
  })

  if fileString then
    local fileFunction, errorMessage = loadstring(fileString)
    if fileFunction then
      openacr.active.routine = fileFunction
    else
      openacr.active.routine = nil
    end
  end
end

function OpenACR.LoadBehaviorFiles()
  local dataFiles = GetModuleFiles("data")
end

function LookupSkill(name)
  for actionId, action in pairs(ActionList:Get(1)) do
    if action.name == name and action.level ~= 0 then
      d(tostring(actionId))
    end
  end
end

local Player = {
  core = { name = nil },
  misc = { level = 0, job = 0 }
}