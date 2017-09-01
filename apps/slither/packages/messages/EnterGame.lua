
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local EnterGame = env.class("EnterGame", MessageBase)

function EnterGame:ctor()
    EnterGame.super.ctor(self, "e")
    self.curPos = self.byteArray:getPos()
end

function EnterGame:setSessionId(sid, uid)
    self.byteArray:setPos(self.curPos)
    self.byteArray:writeStringUInt(sid)
    self.byteArray:writeStringUInt(uid)
end

function EnterGame:parse(stream)
    self.sessionid = stream:readStringUInt()
    self.userId    = stream:readStringUInt()
end

return EnterGame
