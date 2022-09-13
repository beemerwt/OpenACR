local BlueMage = {
  path = GetLuaModsPath()..[[\OpenACR\data\BlueMage.lua]],
  AOE = true,
  ShowRed = true,
  ShowYellow = true,
  isNavigating = false,
}

local Skills = {
  WaterCannon = 11385,
  BombToss = 11396,
  StickyTongue = 11412,
  FlameThrower = 11402 -- maybe
}

local function GoTo(unlock)
  if ActionIsReady(7,5) then
    Player:Teleport(unlock.map)
    ml_global_information.AwaitThen(10000,
      function() return IsLoading() end,
      function() ml_global_information.AwaitThen(1000, 10000,
        function() return not IsLoading() end,
        function()
          if GetLocalAetheryte() == unlock.map and table.valid(unlock.pos) then
            Hacks:TeleportToXYZ(unlock.pos.x, unlock.pos.y, unlock.pos.z)
          end
        end)
      end)
  end
end

function BlueMage:Reset()
  for i,_ in ipairs(Unlocks) do
    Unlocks[i].disabled = false
  end

  self:Save()
end

local function GetEnemiesNearTarget(target, radius)
	local el = EntityList("alive,attackable,onmesh,maxdistance=31")
  if table.valid(el) then
    return FilterByProximity(el, target.pos, radius)
  end

  return nil
end

function BlueMage:Cast(target)
  if MIsCasting() then return false end

  if self.AOE then
    local enemiesInBombRange = GetEnemiesNearTarget(target, 6)
    if table.valid(enemiesInBombRange) then
      if #enemiesInBombRange > 2 then
        if ReadyCast(target.id, Skills.BombToss) then return true end
      end
    end
  end

  if ReadyCast(target.id, Skills.WaterCannon) then return true end
end

function BlueMage:Draw()
  if GUI:Button("Skill Unlockables", 195) then
    Unlocks.GUI.open = not Unlocks.GUI.open
    self:Save()
  end

  GUI:SameLine()
  if GUI:Button("Reset") then self:Reset() end

  self.AOE = OpenACR.ListCheckboxItem("AOE Enabled", self.AOE)

  if Unlocks.GUI.open then
    Unlocks.GUI.visible, Unlocks.GUI.open = GUI:Begin("BLU Unlocks", Unlocks.GUI.open)
    GUI:SetWindowSize(327, 0)

    GUI:Columns(4)
    GUI:SetColumnWidth(-1, 32)
    GUI:Text("=X=")
    GUI:NextColumn()

    GUI:SetColumnWidth(-1, 125)
    GUI:Text("Skill")
    GUI:NextColumn()

    GUI:SetColumnWidth(-1, 130)
    GUI:Text("Mob")
    GUI:NextColumn()

    GUI:SetColumnWidth(-1, 30)
    GUI:Text("Nav")
    GUI:NextColumn()
    GUI:Separator()

    for i,_ in ipairs(Unlocks) do
      if Unlocks[i].mob and not Unlocks[i].disabled then
        -- Hide Column
        if GUI:Checkbox("##"..Unlocks[i].mob, false) then
          Unlocks[i].disabled = true
          self:Save()
        end
        GUI:NextColumn()

        -- Skill Name Column
        GUI:AlignFirstTextHeightToWidgets()
        GUI:Text(Unlocks[i].name)
        GUI:NextColumn()

        -- Mob Column
        local r = math.floor((Unlocks[i].level + 2) / Player.level)
        local g = math.floor(Player.level / (Unlocks[i].level - 2))
        GUI:AlignFirstTextHeightToWidgets()
        GUI:TextColored(r, g, 0.0, 1.0, Unlocks[i].mob)
        GUI:NextColumn()

        -- Nav Column
        if Unlocks[i].map then
          if GUI:Button("Go##"..Unlocks[i].name) then
            GoTo(Unlocks[i])
          end
        end
        GUI:NextColumn()
      end
    end

    GUI:Columns(1)
    GUI:End()
  end
end

function BlueMage:Save()
  local wasSaved = FileSave(self.path, Unlocks)
  if not wasSaved then
    d("There was an error saving file " .. self.path)
  end
end

function BlueMage:OnLoad()
  self.AOE = ACR.GetSetting("OpenACR_BlueMage_AOEEnabled", true)

  -- Create the default data file...
  if not FileExists(self.path) then
    Unlocks = FileLoad(GetLuaModsPath() .. [[\OpenACR\BlueMageUnlocks.lua]])
    Unlocks.GUI = { open = false, visible = true }
    self:Save()
  else
    Unlocks = FileLoad(self.path)
  end
end

function BlueMage:Update()
  local el = MEntityList("alive,attackable")
  if table.valid(el) then
    for id,entity in pairs(el) do
      if entity.contentid then
        
      end
    end
  end
end

return BlueMage