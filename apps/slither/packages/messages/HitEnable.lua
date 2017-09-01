
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local HitEnable = env.class("HitEnable", MessageBase)

function HitEnable:ctor()
    HitEnable.super.ctor(self, "h")
    self.curPos = self.byteArray:getPos()
end

function HitEnable:setSnakeHitEnable(sid, hitEnable)
    self.byteArray:setPos(self.curPos)
    self.byteArray:writeUInt(sid)
    self.byteArray:writeBool(hitEnable)
end

function HitEnable:parse(stream)
    self.snakeID   = stream:readUInt()
    self.hitEnable = stream:readBool()
end

return HitEnable
