local Arcanist = inheritsFrom(DefaultProfile)
Arcanist.AOE = true
Arcanist.HealerPriority = false
Arcanist.Damage = true

function Arcanist:OnLoad()
  self.AOE = ACR.GetSetting("OpenACR_Arcanist_AOEEnabled", true)
  self.HealerPriority = ACR.GetSetting("OpenACR_Arcanist_HealerPriority", false)
  self.Damage = ACR.GetSetting("OpenACR_Arcanist_Damage", true)
end

function Arcanist:Update()
  -- TODO: THIS
  --if MIsCasting() and Player:GetTarget() == nil and then
    --ActionList:StopCasting()
  --end
end

local lastTime = 0
local elapsed = 0
function Arcanist:Buff()
  -- Pet disappears between transformations
  -- We keep track of time elapsed since we last saw them
  -- if it was more than 10s then we resummon them.
  if Player.pet == nil then
    elapsed = elapsed + TimeSince(lastTime)

    if elapsed > 10000 then
      if ReadyCast(Player.id, Skills.Carbuncle) then return true end
    end
  else
    elapsed = 0
  end

  lastTime = Now()
  return false
end

Skills.Resurrection = 16928 -- 173, 25639,

function Arcanist:BeforeCast()
  if self.HealerPriority then
    local bestHeal = GetBestPartyHealTarget(nil, 30, 85)
    if bestHeal ~= nil and not Player:IsMoving() then
      if ReadyCast(bestHeal.id, Skills.Physick) then return true end
    end
  end

  local deadPlayers = MEntityList("dead,myparty,targetable,maxdistance=30")
  if table.valid(deadPlayers) then
    -- Do a swiftcast before resurrection (important)
    ReadyCast(Player.id, Skills.Swiftcast)

    for _, v in pairs(deadPlayers) do
      if ReadyCast(v.id, Skills.Resurrection) then return true end
    end
  end

  -- Protect self from dying with Radiant Aegis
  if Player.hp.percent < 50 then
    if ReadyCast(Player.id, Skills.RadiantAegis) then return true end
  end

  if Player.mp.percent < 50 then
    if ReadyCast(Player.id, Skills.LucidDreaming) then return true end
  end

  return false
end

function Arcanist:Cast(target)
  if not self.Damage then return false end
  local carbuncleTimeleft = Player.gauge[1]
  local transformTimeleft = Player.gauge[2]

  local activeGem = Player.gauge[9]
  local gemCharges = Player.gauge[3]
  local aetherCharges = Player.gauge[10]

  local rubyReady = Player.gauge[5] == 1 and gemCharges == 0
  local topazReady = Player.gauge[6] == 1 and gemCharges == 0
  local emeraldReady = Player.gauge[7] == 1 and gemCharges == 0

  local nearby = GetNearbyEnemies(10)

  if not rubyReady and not topazReady and not emeraldReady and activeGem == 0 then
    if ReadyCast(Player.id, Skills.Aethercharge) then return true end
  end

  if Player.lastcastid ~= Skills.EnergyDrain or Player.lastcastid ~= Skills.Fester then
    if ReadyCast(target.id, Skills.EnergyDrain) then return true end
    if ReadyCast(target.id, Skills.Fester) then return true end
  end

  if activeGem == 0 then
    if ReadyCast(target.id, Skills.Ruby, Skills.Topaz, Skills.Emerald) then
      return true
    end
  end

  if self.AOE and #nearby > 2 then  
    if ReadyCast(target.id, Skills.RubyOutburst, Skills.TopazOutburst, Skills.EmeraldOutburst) then return true end
    if ReadyCast(target.id, Skills.Outburst) then return true end
  end

  if not Player:IsMoving() then
    if ReadyCast(target.id, Skills.RubyRuin) then return true end
  end

  if ReadyCast(target.id, Skills.TopazRuin2, Skills.TopazRuin) then return true end
  if ReadyCast(target.id, Skills.EmeraldRuin2, Skills.EmeraldRuin) then return true end

  if not Player:IsMoving() then
    if ReadyCast(target.id, Skills.Ruin2, Skills.Ruin) then return true end
  end

  return false
end

function Arcanist:Draw()
  self.AOE = OpenACR.ListCheckboxItem("AOE Enabled", self.AOE)
  self.HealerPriority = OpenACR.ListCheckboxItem("Healer Priority", self.HealerPriority)
  self.Damage = OpenACR.ListCheckboxItem("Damage", self.Damage)
end

return Arcanist