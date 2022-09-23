local Dancer = {
  AutoPartner = true,
  AutoPeloton = true,
}

local function GetBestDancePartner()
  if PartyMembers == nil then return nil end
  -- Ninja → Reaper/Monk → Dragoon/Samurai → Black Mage/Red Mage → Summoner → Machinist → Bard → Dancer
  local rating = 0
  local member = nil

  for k,v in pairs(PartyMembers) do
    -- If they are a ninja, just use them
    if v.job == FFXIV.JOBS.NINJA then return v end
    local vrating = v.job == FFXIV.JOBS.REAPER and 7
      or v.job == FFXIV.JOBS.MONK and 7
      or v.job == FFXIV.JOBS.DRAGOON and 6
      or v.job == FFXIV.JOBS.SAMURAI and 6
      or v.job == FFXIV.JOBS.BLACKMAGE and 5
      or v.job == FFXIV.JOBS.REDMAGE and 5
      or v.job == FFXIV.JOBS.SUMMONER and 4
      or v.job == FFXIV.JOBS.MACHINIST and 3
      or v.job == FFXIV.JOBS.BARD and 2
      or v.job == FFXIV.JOBS.DANCER and 1
      or 0

    if vrating > rating then
      member = v
      rating = vrating
    end
  end

  return member
end

function Dancer:Cast(target)
  local playerHasPartner = HasBuff(Player.id, Buffs.ClosedPosition)
  local playerHasPeloton = HasBuff(Player.id, Buffs.Peloton)

  if self.AutoPeloton and Player:IsMoving() and not playerHasPeloton then
    if ReadyCast(Player.id, Skills.Peloton) then return true end
  end

  if self.AutoPartner and not playerHasPartner then
    local partner = GetBestDancePartner()
    if partner ~= nil then
      if ReadyCast(partner.id, Skills.ClosedPosition) then return true end
    end
  end


end

function Dancer:Draw()
  self.AutoPartner = GUI:Checkbox("Auto Partner", self.AutoPartner)
  self.AutoPeloton = GUI:Checkbox("Auto Peloton", self.AutoPeloton)
end

function Dancer:OnLoad()
  self.AutoPeloton = ACR.GetSetting("OpenACR_Dancer_AutoPeloton", true)
  self.AutoPartner = ACR.GetSetting("OpenACR_Dancer_AutoPartner", true)
end

return Dancer