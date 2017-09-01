
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local FoodHit = env.class("FoodHit", MessageBase)

function FoodHit:ctor()
    FoodHit.super.ctor(self, "H")
    self.curPos = self.byteArray:getPos()
end

function FoodHit:setHitTarget(_id,_dt)
    self.hitID = _id
    self.timeStamp = _dt
    self.byteArray:writeInt(self.hitID)
    self.byteArray:writeFloat(self.timeStamp)
end

function FoodHit:parse(stream)
    self.hitID = stream:readInt()
    self.timeStamp = stream:readFloat()
end

return FoodHit
