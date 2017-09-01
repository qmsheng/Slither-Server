
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local SpeedUp = env.class("SpeedUp", MessageBase)

function SpeedUp:ctor()
    SpeedUp.super.ctor(self, "s")
    self.curPos = self.byteArray:getPos()
end

function SpeedUp:setSnakeID(sid, isSpeedUp)
    self.byteArray:setPos(self.curPos)
    self.byteArray:writeUInt(sid)
    self.byteArray:writeBool(isSpeedUp)
end

function SpeedUp:parse(stream)
    self.snakeID   = stream:readUInt()
    self.isSpeedUp = stream:readBool()
end

return SpeedUp
