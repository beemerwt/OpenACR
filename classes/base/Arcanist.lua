local Arcanist = {
  AOE = true,
}

function Arcanist:Cast(target)
  local carbuncleTimeleft = Player.gauge[1]
  local transformTimeleft = Player.gauge[2]

  local activeGem = Player.gauge[9]
  local gemCharges = Player.gauge[3]
  local aetherCharges = Player.gauge[10]

  local rubyReady = Player.gauge[5] == 1 and gemCharges == 0
  local topazReady = Player.gauge[6] == 1 and gemCharges == 0
  local emeraldReady = Player.gauge[7] == 1 and gemCharges == 0

  if Player.pet == nil then
    if ReadyCast(Player.id, Skills.Carbuncle) then return true end
  end

  if Player.hp.percent < 50 then
    if ReadyCast(Player.id, Skills.RadiantAegis) then return true end
    if not Player:IsMoving() then
      if ReadyCast(Player.id, Skills.Physick) then return true end
    end
  end

  if Player.mp.percent < 50 then
    if ReadyCast(Player.id, Skills.LucidDreaming) then return true end
  end

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
  self.AOE = GUI:Checkbox("AOE Enabled", self.AOE)
end

function Arcanist:OnLoad()
  self.AOE = ACR.GetSetting("OpenACR_Arcanist_AOEEnabled", true)
end

function Arcanist:Update()
  -- TODO: THIS
  --if MIsCasting() and Player:GetTarget() == nil and then
    --ActionList:StopCasting()
  --end
end

return Arcanist