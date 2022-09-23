local Basic = inheritsFrom(CraftingProfile)

Skills.BasicSynthesis = {
  [12] = 100045,
}

Skills.BasicTouch = 100002
Skills.MastersMend = 100003
Skills.StandardTouch = 100004
Skills.MastersMend2 = 100005
Skills.StandardSynthesis = 100007
Skills.AdvancedTouch = 100008

function Basic:OnLoad()

end

function Basic:Perform()
  local action = ActionList:Get(9, Skills.BasicSynthesis[Player.job])
  if action:IsReady() then
    return action:Cast()
  end

  return false
end

return Basic

