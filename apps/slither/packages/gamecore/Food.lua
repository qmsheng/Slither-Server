
local helper     = cc.import(".helper")
local Sector     = cc.import(".Sector")

local Food = cc.class("Food")

local gFoodID = 1
function Food:ctor (pos, radius)
    self.id        = gFoodID
    self.pos       = pos
    self.radius    = radius

    self.pos.x = math.floor(self.pos.x*100)/100
    self.pos.y = math.floor(self.pos.y*100)/100
    self.sector = Sector.mapPosToSectorID(self.pos)

    gFoodID = gFoodID + 1
end

function Food:getData()
    return {
        self.id,self.radius,self.pos.x,self.pos.y
    }
end

return Food
