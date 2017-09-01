
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local Echo = env.class("Echo", MessageBase)

function Echo:ctor()
    Echo.super.ctor(self, "E")
    self.curPos = self.byteArray:getPos()
end

function Echo:setEcho(msg)
    self.textMessage = msg.text or 1
    self.byteArray:writeFloat(self.textMessage)
    self.count  = msg.count or 1
    self.byteArray:writeInt(self.count)
end

function Echo:parse(stream)
    self.text = stream:readFloat()
    self.count = stream:readInt()
end

return Echo
