local BlueMage = {

}

local Skills = {
  WaterCannon = 11385
}

function BlueMage:Cast(target)
  if ReadyCast(target.id, Skills.WaterCannon) then return true end
end

function BlueMage:Draw()

end

function BlueMage:OnLoad()

end

return BlueMage