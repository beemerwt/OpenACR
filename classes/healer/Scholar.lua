local Scholar = abstractFrom(OpenACR.DefaultProfile)
Scholar.AOE = true
Scholar.DPS = true

Buffs.Bio = 189
Buffs.Bio2 = 189

Skills.Ruin = 17869
Skills.Ruin2 = 17870
Skills.Eos = 17215
Skills.Physick = 190 -- , 16230 }

Skills.Adloquium = 185
Skills.Resurrection = { 173, 16928, 25639 }
Skills.FeyBlessing = { 16543, 16544 }
Skills.Seraph = { 16545, 16546, 16548, 17798, 29237 }
Skills.Consolation = { 16547, 29238, 29241 }
Skills.Recitation = 16542
Skills.Indomitability = { 3583, 18948 }
Skills.WhisperingDawn = { 803, 16537 }
Skills.Protraction = 25867
Skills.Excogitation = { 7434, 18949 }
Skills.Aetherpact = 7423
Skills.SacredSoil = 188 --, 23578 }
Skills.Lustrate = 189 -- 8909, 16863, 23134, 29974, 29976 }
Skills.Succor = { 16862, 18947, 23608, 29973 }
Skills.Broil = 3584 -- , 7435, 16541, 17869, 25865 }

Skills.Esuna = 7568
Skills.Aetherflow = 166
Skills.Bio = 16540
Skills.Bio2 = 17865

function Scholar:OnLoad()
  self.AOE = ACR.GetSetting("OpenACR_Scholar_AOEEnabled", true)
  self.DPS = ACR.GetSetting("OpenACR_Scholar_DPSEnabled", true)
end

function Scholar:Buff()
  if Player.pet == nil and not Player:IsMoving() then
    if ReadyCast(Player.id, Skills.Eos) then return true end
  end

  return false
end

function Scholar:FreeGCDHeals(healTarget, nearby)
  if self.AOE and #nearby > 2 then
    if ReadyCast(Player.id, Skills.Seraph) then return true end
    if ReadyCast(Player.id, Skills.Consolation) then return true end
    if ReadyCast(Player.id, Skills.Recitation) then return true end

    if HasBuff(Player.id, Buffs.Recitation) then
      if ReadyCast(Player.id, Skills.Indomitability) then return true end
    end

    if ReadyCast(Player.id, Skills.FeyBlessing) then return true end
    if ReadyCast(Player.id, Skills.WhisperingDawn) then return true end
  else
    if not HasBuff(healTarget.id, Buffs.Protraction) then
      if ReadyCast(healTarget.id, Skills.Protraction) then
        return true
      end
    end

    if ReadyCast(Player.id, Skills.Recitation) then return true end

    if HasBuff(Player.id, Buffs.Recitation) then
      if ReadyCast(healTarget.id, Skills.Excogitation) then return true end
    end

    if ReadyCast(healTarget.id, Skills.Aetherpact) then return true end
  end

  return false
end

function Scholar:AetherFlowGCDHeals(healTarget, nearby)
  if self.AOE and #nearby > 2 then
    if ReadyCast(Player.id, Skills.SacredSoil) then return true end
    if ReadyCast(Player.id, Skills.Indomitability) then return true end
  else
    if not HasBuff(healTarget.id, Buffs.Excogitation) then
      if ReadyCast(healTarget.id, Skills.Excogitation) then return true end
    end

    if ReadyCast(healTarget.id, Skills.Lustrate) then return true end
  end
end

local function GetLocallyDead()
  local deadPlayers = MEntityList("dead,myparty,targetable,maxdistance=30")
  if table.valid(deadPlayers) then
    -- Do a swiftcast before resurrection (important)
    ReadyCast(Player.id, Skills.Swiftcast)

    for _, v in pairs(deadPlayers) do
      if ReadyCast(v.id, Skills.Resurrection) then return true end
    end
  end
end

function Scholar:BeforeCast()
  local bestHeal = GetBestPartyHealTarget(nil, 30, 85, 0)
  if bestHeal == nil then return false end
  local healsNearby = GetNearbyHeals(15)

  if Player.mp.percent < 50 then
    if ReadyCast(Player.id, Skills.LucidDreaming) then return true end
  end

  if Player.mp.percent < 25 then
    if ReadyCast(Player.id, Skills.Aetherflow) then return true end
  end

  if self:FreeGCDHeals(bestHeal, healsNearby) then return true end
  if self:AetherFlowGCDHeals(bestHeal, healsNearby) then return true end

  if not Player:IsMoving() then
    local debuffedFriend = MPartyMemberWithBuff(SkillMgr.knownDebuffs, "", 30)
    if debuffedFriend ~= nil then
      if ReadyCast(debuffedFriend.id, Skills.Esuna) then return true end
    end

    if self.AOE and #healsNearby > 2 then
      if ReadyCast(Player.id, Skills.Succor) then return true end
    else
      if ReadyCast(bestHeal.id, Skills.Adloquium) then return true end
      if ReadyCast(bestHeal.id, Skills.Physick) then return true end
    end
  end

  return false
end

function Scholar:Cast(target)
  if not self.DPS then return false end
  if table.size(MGetParty()) > 1 and Player.mp.percent < 25 then return false end
  local nearby = GetNearbyEnemies(10)
  local lastcast = Player.castinginfo.lastcastid

  if lastcast ~= Skills.EnergyDrain then
    if ReadyCast(target.id, Skills.EnergyDrain) then return true end
  end

  if IsCapable(Skills.Bio2) then
    if not HasBuff(target.id, Buffs.Bio2) then
      if ReadyCast(target.id, Skills.Bio2) then return true end
    end
  else
    if not HasBuff(target.id, Buffs.Bio) then
      if ReadyCast(target.id, Skills.Bio) then return true end
    end
  end

  if lastcast == Skills.Ruin or lastcast == Skills.Broil then
    if ReadyCast(target.id, Skills.Ruin2) then return true end
  end

  if not Player:IsMoving() then
    if ReadyCast(target.id, Skills.Broil) then return true end
    if ReadyCast(target.id, Skills.Ruin) then return true end
  end

  return false
end

function Scholar:Draw()
  self.AOE = OpenACR.ListCheckboxItem("AOE Enabled", self.AOE)
  self.DPS = OpenACR.ListCheckboxItem("DPS Enabled", self.DPS)
end

return Scholar