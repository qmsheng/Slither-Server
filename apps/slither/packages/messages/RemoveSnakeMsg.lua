
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local RemoveSnakeMsg = env.class("RemoveSnakeMsg", MessageBase)

function RemoveSnakeMsg:ctor()
    RemoveSnakeMsg.super.ctor(self, "R")
    self.curPos = self.byteArray:getPos()
end

function RemoveSnakeMsg:setSnakeID(msg)
    self.byteArray:writeInt(msg.id)
    self.byteArray:writeInt(msg.reason)
    self.byteArray:writeFloat(msg.ts)
    self.byteArray:writeBool(msg.isDead)
end

function RemoveSnakeMsg:parse(stream)
    self.id = stream:readInt()
    self.reason = stream:readInt()
    self.ts = stream:readFloat()
    self.idDead = stream:readBool()
end

return RemoveSnakeMsg
