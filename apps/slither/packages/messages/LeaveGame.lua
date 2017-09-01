
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local LeaveGame = env.class("LeaveGame", MessageBase)

function LeaveGame:ctor()
    LeaveGame.super.ctor(self, "L")
    self.curPos = self.byteArray:getPos()
end

function LeaveGame:setClientId(sid)
    self.byteArray:setPos(self.curPos)
    self.byteArray:writeStringUInt(sid)
end

function LeaveGame:parse(stream)
    self.clientId = stream:readStringUInt()
end

return LeaveGame
