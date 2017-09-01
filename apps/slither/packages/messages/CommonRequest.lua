local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local CommonRequest = env.class("CommonRequest", MessageBase)

function CommonRequest:ctor()
    CommonRequest.super.ctor(self, "r")
    self.curPos = self.byteArray:getPos()
end

function CommonRequest:setRequest(msg, id)
    self.byteArray:setPos(self.curPos)
    self.byteArray:writeStringUInt(env.json.encode(msg))
    self.byteArray:writeInt(id or -1)
end

function CommonRequest:parse(stream)
    self.msg = env.json.decode(stream:readStringUInt())
    self.id  = stream:readInt()
end

return CommonRequest
