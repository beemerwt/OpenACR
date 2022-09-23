local BlueMage = abstractFrom(OpenACR.CombatProfile)

local function StopNav()
  if MIsCasting(true) then ActionList:StopCasting() end
  if Player:IsMoving() then Player:Stop(true) end
  ForceStopMovement() -- set ForceStop so the timer stops
  for i,_ in ipairs(Unlocks) do
    Unlocks[i].isNavigating = false
  end
end

local function StartNav(idx)
  StopNav()
  for i,_ in ipairs(Unlocks) do
    if Unlocks[i].isNavigating then
      Unlocks[i].isNavigating = false
    end
  end

  TeleportThenMove(Unlocks[idx])
  Unlocks[idx].isNavigating = true
end

local function OpenDutyFinder()
  SendTextCommand("/finder")
end

local function CalcUnlockColumnWidths()
  Unlocks.GUI.LargestSkillText = 0
  Unlocks.GUI.LargestMobText = 0
  Unlocks.GUI.LargestSourceText = 0

  for i,_ in ipairs(Unlocks) do
    if not Unlocks[i].disabled then
      local nt,_ = GUI:CalcTextSize(Unlocks[i].name)
      local mt,_ = GUI:CalcTextSize(Unlocks[i].mob)
      local st,_ = GUI:CalcTextSize(Unlocks[i].source)

      if nt ~= nil and Unlocks.GUI.LargestSkillText < nt then
        Unlocks.GUI.LargestSkillText = nt
      end

      if mt ~= nil and Unlocks.GUI.LargestMobText < mt then
        Unlocks.GUI.LargestMobText = mt
      end

      if st ~= nil and Unlocks.GUI.LargestSourceText < st then
        Unlocks.GUI.LargestSourceText = st
      end
    end
  end

  Unlocks.GUI.LargestSkillText = Unlocks.GUI.LargestSkillText + 15
  Unlocks.GUI.LargestMobText = Unlocks.GUI.LargestMobText + 15
  Unlocks.GUI.LargestSourceText = Unlocks.GUI.LargestSourceText + 15
end

function BlueMage:Reset()
  Unlocks = FileLoad(GetLuaModsPath() .. [[\OpenACR\BlueMageUnlocks.lua]])
  Unlocks.GUI = { open = false, visible = true }
  OpenACR.SaveSettings("BlueMageUnlocks", Unlocks)

  CalcUnlockColumnWidths()
end

function BlueMage:Cast(target)
  if MIsCasting() then return false end
  local dutyInfo = Duty:GetActiveDutyInfo()
  local InDungeon = table.valid(dutyInfo) and dutyInfo.dutytype == 32771

  if IsActive(Skills.BasicInstinct) and InDungeon and not HasBuff(Player.id, Buffs.BasicInstinct) then
    if ReadyCast(Player.id, Skills.BasicInstinct) then return true end
  end

  if IsActive(Skills.WhiteWind) and Player.hp.percent < 50 then
    if ReadyCast(Player.id, Skills.WhiteWind) then return true end
  end

  if IsActive(Skills.FlyingSardine) and target.castinginterruptable then
    if ReadyCast(target.id, Skills.FlyingSardine) then return true end
  end

  if self.AOE then
    local nearby = GetNearbyEnemies(5)
    local playerHasSwiftcast = HasBuff(Player.id, Buffs.Swiftcast)

    if IsActive(Skills.BadBreath) and #nearby > 1 and not HasBuff(target.id, Buffs.BadBreath) then
      if ReadyCast(Player.id, Skills.BadBreath) then return true end
    end

    if #nearby > 2 then
      if IsActive(Skills.PeculiarLight) and not HasBuff(target.id, Buffs.PeculiarLight) then
        if ReadyCast(Player.id, Skills.PeculiarLight) then return true end
      end

      -- Casts swiftcast for instant thousand needles
      if IsActive(Skills.ThousandNeedles) then
        if not playerHasSwiftcast then
          if ReadyCast(Player.id, Skills.Swiftcast) then return true end
        else
          if ReadyCast(Player.id, Skills.ThousandNeedles) then return true end
        end
      end

      -- Prioritize better DPS
      if IsActive(Skills.MindBlast) then
        if ReadyCast(Player.id, Skills.MindBlast) then return true end
      elseif IsActive(Skills.Plaincracker) then
        if ReadyCast(Player.id, Skills.Plaincracker) then return true end
      end
    end

    -- ranged AOE, DPS is the same as Plaincracked but it's much further
    if IsActive(Skills.BombToss) then
      local enemiesInBombRange = GetEnemiesNearTarget(target, 25, 6)
      if table.valid(enemiesInBombRange) then
        if #enemiesInBombRange > 2 then
          if ReadyCast(target.id, Skills.BombToss) then return true end
        end
      end
    end
  end

  if IsActive(Skills.Offguard) and not HasBuff(target.id, Buffs.Offguard) then
    if ReadyCast(target.id, Skills.Offguard) then return true end
  end

  if IsActive(Skills.BloodDrain) and Player.mp.percent < 20 then
    if ReadyCast(target.id, Skills.BloodDrain) then return true end
  end

  -- In order of Highest DPS
  if ReadyCast(target.id, Skills.Glower) then return true end
  if ReadyCast(target.id, Skills.WaterCannon) then return true end
end

function BlueMage:Draw()
  if GUI:Button("Skill Unlockables", 195) then
    Unlocks.GUI.open = not Unlocks.GUI.open
    OpenACR.SaveSettings("BlueMageUnlocks", Unlocks)
  end

  GUI:SameLine()
  if GUI:Button("Reset") then self:Reset() end

  self.AOE = OpenACR.ListCheckboxItem("AOE Enabled", self.AOE)

  if Unlocks.GUI.open then
    GUI:SetNextWindowSize(Unlocks.GUI.LargestSkillText + Unlocks.GUI.LargestMobText + Unlocks.GUI.LargestSourceText + 62 + 10, 0, GUI.SetCond_FirstUseEver)
    Unlocks.GUI.visible, Unlocks.GUI.open = GUI:Begin("BLU Unlocks", Unlocks.GUI.open)

    GUI:Columns(4)
    GUI:SetColumnWidth(-1, 62)
    GUI:Text("=X=") GUI:SameLine() GUI:Text("Nav") GUI:SameLine()
    GUI:NextColumn()

    GUI:SetColumnWidth(-1, Unlocks.GUI.LargestSkillText)
    GUI:Text("Skill")
    GUI:NextColumn()

    GUI:SetColumnWidth(-1, Unlocks.GUI.LargestMobText)
    GUI:Text("Mob")
    GUI:NextColumn()

    GUI:SetColumnWidth(-1, Unlocks.GUI.LargestSourceText)
    GUI:Text("Source")
    GUI:NextColumn()
    GUI:Separator()

    for i,_ in ipairs(Unlocks) do
      if Unlocks[i].mob and not Unlocks[i].disabled then
        -- Hide Column
        if GUI:Checkbox("##"..Unlocks[i].mob, false) then
          Unlocks[i].disabled = true
          OpenACR.SaveSettings("BlueMageUnlocks", Unlocks)

          CalcUnlockColumnWidths()
        end
        GUI:SameLine()

        -- Nav Column
        if Unlocks[i].isNavigating then
          if GUI:Button("Stop##"..Unlocks[i].name) then StopNav() end
        else
          if GUI:Button("Go##"..Unlocks[i].name) then
            d("Go button pressed for " .. Unlocks[i].name)
            if Unlocks[i].pos then
              StartNav(i)
            elseif not InInstance() then
              OpenDutyFinder()
            end
          end
        end
        GUI:NextColumn()

        -- Skill Name Column
        GUI:AlignFirstTextHeightToWidgets()
        GUI:Text(Unlocks[i].name)
        GUI:NextColumn()

        -- Mob Column
        local r = Unlocks[i].source == "World" and math.floor((Unlocks[i].level + 2) / Player.level)
          or Player.level <= Unlocks[i].level and 1 or 0
        local g = Unlocks[i].source == "World" and math.floor(Player.level / (Unlocks[i].level - 2))
          or Player.level >= Unlocks[i].level and 1 or 0

        GUI:AlignFirstTextHeightToWidgets()
        GUI:TextColored(r, g, 0.0, 1.0, Unlocks[i].mob)
        GUI:NextColumn()

        -- Source Column
        GUI:AlignFirstTextHeightToWidgets()
        GUI:Text(Unlocks[i].source)
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
  if not OpenACR.Settings['BlueMageUnlocks'] then
    self:Reset()
  else
    Unlocks = OpenACR.Settings['BlueMageUnlocks']
  end

  for i,_ in ipairs(Unlocks) do
    local trimmedName = Unlocks[i].name:gsub('[%p%c%s]', '')
    if trimmedName == '1000Needles' then trimmedName = 'ThousandNeedles' end
    if trimmedName == '4tonzeWeight' then trimmedName = 'FourTonWeight' end
    if Skills[trimmedName] then
      if IsActive(Skills[trimmedName]) then
        Unlocks[i].disabled = true
      end
    end
  end

  CalcUnlockColumnWidths()
end

return BlueMage