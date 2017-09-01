
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local SnakeHit = env.class("SnakeHit", MessageBase)

function SnakeHit:ctor()
    SnakeHit.super.ctor(self, "B")
    self.curPos = self.byteArray:getPos()
end

function SnakeHit:setHitTarget(_id,_dt)
    self.hitID = _id
    self.timeStamp = _dt
    self.byteArray:writeInt(self.hitID)
    self.byteArray:writeFloat(self.timeStamp)
end

function SnakeHit:parse(stream)
    self.hitID = stream:readInt()
    self.timeStamp = stream:readFloat()
end

return SnakeHit
