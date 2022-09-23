local Ninja = abstractFrom(OpenACR.CombatProfile)
local TargetHasTrickAttack = false
local TargetHasMug = false

local Mudras = {
  Fuma   = { 'ten' },

  Raiton = { 'ten', 'chi' }, -- 9
  Katon  = { 'chi', 'ten' }, -- 6

  Hyosho = { 'ten', 'jin' }, -- 13
  Goka   = { 'jin', 'ten' }, -- 7

  Huton  = { 'jin', 'chi', 'ten' }, -- 27
  Doton  = { 'ten', 'jin', 'chi' }, -- 45, 39 (Jin Ten Chi)
  Suiton = { 'ten', 'chi', 'jin' }, -- 57
}

local MudraActions = {
  [1] = Skills.Fuma,
  [6] = Skills.Katon,
  [7] = Skills.Goka,
  [9] = Skills.Raiton,
  [13] = Skills.Hyosho,
  [27] = Skills.Huton,
  [45] = Skills.Doton,
  [57] = Skills.Suiton
}

local function IsNinjutsuReady()
  return HasBuff(Player.id, Buffs.Kassatsu) or not IsOnCooldown(Skills.Ten)
end

local StartMudra = 0
local MudraQueue = {}
local function QueueMudra(mudra)
  MudraQueue = table.shallowcopy(mudra)
  StartMudra = Now()
  return true
end

local function Ninjutsu(numNearby)
  if not IsCapable(Skills.Ninjutsu) then return false end
  if not IsNinjutsuReady() then return false end

  if numNearby > 2 and Ninja.AOEEnabled then
    if not HasBuff(Player.id, Buffs.Doton) and IsCapable(Skills.Doton) then
      return QueueMudra(Mudras.Doton)
    end

    if HasBuff(Player.id, Buffs.Kassatsu) and IsCapable(Skills.Goka) then
      return QueueMudra(Mudras.Goka);
    end

    if IsCapable(Skills.Katon) then
      return QueueMudra(Mudras.Katon);
    end
  end

  local isMudraTransitioning = HasBuff(Player.id, Buffs.Mudra, 57)
  -- Use Suiton to set up Trick Attack when there is less than 20 seconds left on Trick Attack's cooldown.
  if not HasBuff(Player.id, Buffs.Suiton) and not isMudraTransitioning and IsCapable(Skills.Suiton) then
    local TrickAttack = ActionList:Get(1, Skills.TrickAttack)
    if TrickAttack.cdmax - TrickAttack.cd < 20 then
      return QueueMudra(Mudras.Suiton)
    end
  end

  if numNearby > 1 and Ninja.AOEEnabled then
    if not HasBuff(Player.id, Buffs.Doton) and IsCapable(Skills.Doton) then
      return QueueMudra(Mudras.Doton)
    end

    if HasBuff(Player.id, Buffs.Kassatsu) and IsCapable(Skills.Goka) then
      return QueueMudra(Mudras.Goka) -- Goka Mekkyaku for multi-target
    end
  end

  if HasBuff(Player.id, Buffs.Kassatsu) and IsCapable(Skills.Hyosho) then
    return QueueMudra(Mudras.Hyosho) -- Hyosho Ranryu for single-target
  end

  if IsCapable(Skills.Raiton) then
    return QueueMudra(Mudras.Raiton)
  end

  if IsCapable(Skills.Fuma) then
    return QueueMudra(Mudras.Fuma)
  end

  return false
end

local function CastMudra(name)
  if name == 'ten' then
    local ten = ActionList:Get(1, Skills.Ten)
    local mudraTen = ActionList:Get(1, Skills.MudraTen)
    if ten:IsReady() or mudraTen:IsReady() then
      return ten:Cast()
    end
    -- return ReadyCast(Player.id, Skills.Ten, Skills.MudraTen)
  elseif name == 'chi' then
    local chi = ActionList:Get(1, Skills.Chi)
    local mudraChi = ActionList:Get(1, Skills.MudraChi)
    if chi:IsReady() or mudraChi:IsReady() then
      return chi:Cast()
    end
    -- return ReadyCast(Player.id, Skills.Chi, Skills.MudraChi)
  elseif name == 'jin' then
    local jin = ActionList:Get(1, Skills.Jin)
    local mudraJin = ActionList:Get(1, Skills.MudraJin)
    if jin:IsReady() or mudraJin:IsReady() then
      return jin:Cast()
    end
    --return ReadyCast(Player.id, Skills.Jin, Skills.MudraJin)
  end

  return false
end

local function BasicCombo(target)
  if Player.lastcomboid == Skills.DeathBlossom then
    return ReadyCast(Player.id, Skills.HakkeMujinsatsu)
  elseif Player.lastcomboid == Skills.GustSlash and Player.gauge[2] > 30000 then
    return ReadyCast(target.id, Skills.AeolianEdge)
  elseif Player.lastcomboid == Skills.SpinningEdge then
    return ReadyCast(target.id, Skills.GustSlash)
  end

  return false
end

local function GetBuff(id)
  for i,_ in ipairs(Player.buffs) do
    if Player.buffs[i].id == id then
      return Player.buffs[i]
    end
  end

  return nil
end

local function DidNotCastMudraLast()
  return not In(Player.lastcastid,
    Skills.Ten,
    Skills.Chi,
    Skills.Jin,
    Skills.MudraTen,
    Skills.MudraChi,
    Skills.MudraJin)
end

local usedFuma = false
local usedRaiton = false
local usedSuiton = false

-- The Cast() function is where the magic happens.
-- Action code should be called and fired here.
function Ninja:Cast(target)
  TargetHasTrickAttack  = HasBuff(target.id, Buffs.TrickAttack)
  TargetHasMug          = HasBuff(target.id, Buffs.Mug)
  local playerTCJ       = GetBuff(Buffs.TenChiJin)
  local playerMudra     = GetBuff(Buffs.Mudra)

  -- TimeSince Failsafe
  if #MudraQueue > 0 and TimeSince(StartMudra) < 6000 then
    if CastMudra(MudraQueue[1]) then
      table.remove(MudraQueue, 1)
      return true
    end

    return false
  end

  if playerTCJ ~= nil then
    if playerTCJ.stacks == 0 then
      if ReadyCast(target.id, Skills.TCJFuma) then
        return true
      end
    end

    if playerTCJ.stacks == 1 then
      if ReadyCast(target.id, Skills.TCJRaiton) then
        return true
      end
    end

    if playerTCJ.stacks == 9 then
      if ReadyCast(target.id, Skills.TCJSuiton) then
        return true
      end
    end

    return false
  end

  if playerMudra ~= nil then
    local id = MudraActions[playerMudra.stacks]
    if id == Skills.Huton or id == Skills.Doton then
      if ReadyCast(Player.id, id) then return true end
    else
      if ReadyCast(target.id, id) then return true end
    end

    return false
  end

  local nearby = GetNearbyEnemies(5)

  -- Cast Huton if player doesn't have it.
  if Player.gauge[2] == 0 and IsNinjutsuReady() and IsCapable(Skills.Huton) then
    return QueueMudra(Mudras.Huton)
  end

  if self.ACEnabled and Player.gauge[2] < 30000 then
    local isImmediate = Player.gauge[2] <= 3000 and Player.gauge[2] > 0
    if isImmediate or Player.lastcomboid == Skills.GustSlash then
      if ReadyCast(target.id, Skills.ArmorCrush) then return true end
    end
  end

  if self.RaijuEnabled and #nearby < 2 then
    if HasBuff(Player.id, Buffs.RaijuReady) then
      if ReadyCast(target.id, Skills.FleetingRaiju, Skills.ForkedRaiju) then
        return true
      end
    end
  end

  if self.NinkiEnabled then
    local ninkiPower = Player.gauge[1]

    -- Bunshin = Kamaitachi | Cast both on cooldown
    if ReadyCast(target.id, Skills.Kamaitachi) then return true end
    if ReadyCast(Player.id, Skills.Bunshin) then return true end

    -- Ninki Management, The big thing is that you will never want to overcap it
    if #nearby > 2 then
      if ReadyCast(target.id, Skills.Hellfrog) then return true end
    elseif TargetHasTrickAttack or ninkiPower >= 85 then
      if ReadyCast(target.id, Skills.Bhavacakra) then return true end
    end
  end

  if self.TCJEnabled then
    if TargetHasTrickAttack or TargetHasMug then
      if (self.MeisuiEnabled and not IsOnCooldown(Skills.Meisui)) or not self.MeisuiEnabled then
        if ReadyCast(Player.id, Skills.TenChiJin) then return true end
      end
    end
  end

  if self.TAEnabled then
    if ReadyCast(target.id, Skills.TrickAttack) then return true end
  end

  if self.AssassinateEnabled then
    if (TargetHasTrickAttack or TargetHasMug) and #nearby < 3 then
      if ReadyCast(target.id, Skills.Assassinate, Skills.DreamWithinADream) then return true end
    end
  end

  if self.MeisuiEnabled and IsOnCooldown(Skills.TrickAttack) then
    if ReadyCast(Player.id, Skills.Meisui) then return true end
  end

  if self.NinjutsuEnabled then
    if Ninjutsu(#nearby) then
      return true
    end

    -- BUG: There is a frame inbetween where this is false and causes it to be cast before all charges are expended
    if not IsNinjutsuReady() and playerMudra ~= nil and DidNotCastMudraLast() then
      if ReadyCast(Player.id, Skills.Kassatsu) then return true end
    end
  end

  if self.ComboEnabled then
    if BasicCombo(target) then return true end
    if self.AOEEnabled and #nearby > 2 and IsCapable(Skills.DeathBlossom) then
      if ReadyCast(Player.id, Skills.DeathBlossom) then return true end
    else
      if ReadyCast(target.id, Skills.SpinningEdge) then return true end
    end
  end

  if self.ThrowingEnabled then
    if ReadyCast(target.id, Skills.ThrowingDagger) then return true end
  end

  return false
end

function Ninja:CastPvP(target)

end

-- The Draw() function provides a place where a developer can show custom options.
function Ninja:Draw()
  GUI:BeginChild("Class##SkillWindow", 0.0, 0.0, true)
  self.AOEEnabled = OpenACR.ListCheckboxItem("AOE Enabled", self.AOEEnabled, 160)
  self.ComboEnabled = OpenACR.ListCheckboxItem("Combo Enabled", self.ComboEnabled, 160)
  self.NinkiEnabled = OpenACR.ListCheckboxItem("Ninki Enabled", self.NinkiEnabled, 160)
  self.NinjutsuEnabled = OpenACR.ListCheckboxItem("Ninjutsu Enabled", self.NinjutsuEnabled, 160)
  self.RaijuEnabled = OpenACR.ListCheckboxItem("Raiju Enabled", self.RaijuEnabled, 160)
  self.TCJEnabled = OpenACR.ListCheckboxItem("Ten Chi Jin", self.TCJEnabled, 160)
  self.ACEnabled = OpenACR.ListCheckboxItem("Armor Crush", self.ACEnabled, 160)
  self.ThrowingEnabled = OpenACR.ListCheckboxItem("Throwing Dagger", self.ThrowingEnabled, 160)
  self.AssassinateEnabled = OpenACR.ListCheckboxItem("Assassinate", self.AssassinateEnabled, 160)
  self.MeisuiEnabled = OpenACR.ListCheckboxItem("Meisui", self.MeisuiEnabled, 160)
  self.TAEnabled = OpenACR.ListCheckboxItem("Trick Attack", self.TAEnabled, 160)
  GUI:EndChild()
end

function Ninja:DrawPvP()

end

-- The OnLoad() function is fired when a profile is prepped and loaded by ACR.
function Ninja:OnLoad()
  self.ComboEnabled = ACR.GetSetting("OpenACR_Ninja_ComboEnabled", true)
  self.NinkiEnabled = ACR.GetSetting("OpenACR_Ninja_NinkiEnabled", true)
  self.AOEEnabled = ACR.GetSetting("OpenACR_Ninja_AOEEnabled", true)
  self.NinjutsuEnabled = ACR.GetSetting("OpenACR_Ninja_NinjutsuEnabled", true)
  self.RaijuEnabled = ACR.GetSetting("OpenACR_Ninja_RaijuEnabled", true)
  self.TCJEnabled = ACR.GetSetting("OpenACR_Ninja_TenChiJinEnabled", true)
  self.ACEnabled = ACR.GetSetting("OpenACR_Ninja_ArmorCrushEnabled", true)
  self.ThrowingEnabled = ACR.GetSetting("OpenACR_Ninja_ThrowingDaggerEnabled", true)
  self.AssassinateEnabled = ACR.GetSetting("OpenACR_Ninja_AssassinateEnabled", true)
  self.MeisuiEnabled = ACR.GetSetting("OpenACR_Ninja_MeisuiEnabled", true)
  self.TAEnabled = ACR.GetSetting("OpenACR_Ninja_TrickAttackEnabled", true)
end

-- The OnClick function is fired when a user clicks on the ACR party interface.
-- It accepts 5 parameters:
-- mouse /int/ - Possible values are 0 (Left-click), 1 (Right-click), 2 (Middle-click)
-- shiftState /bool/ - Is shift currently pressed?
-- controlState /bool/ - Is control currently pressed?
-- altState /bool/ - Is alt currently pressed?
-- entity /table/ - The entity information for the party member that was clicked on.
function Ninja:OnClick(mouse,shiftState,controlState,altState,entity)

end

-- The OnUpdate() function is fired on the gameloop, like any other OnUpdate function found in FFXIVMinion code.
function Ninja:OnUpdate(event, tickcount)
end

-- Return the profile to ACR, so it can be read.
return Ninja