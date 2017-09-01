
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local HeartBeat = env.class("HeartBeat", MessageBase)

function HeartBeat:ctor()
    HeartBeat.super.ctor(self, "T")
    self.curPos = self.byteArray:getPos()
end

function HeartBeat:setClientId(sid)
    self.byteArray:writeInt(sid)
end

function HeartBeat:parse(stream)
    self.clientId = stream:readInt()
end

return HeartBeat
