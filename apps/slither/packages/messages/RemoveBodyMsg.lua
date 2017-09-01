
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local RemoveBodyMsg = env.class("RemoveBodyMsg", MessageBase)

function RemoveBodyMsg:ctor()
    RemoveBodyMsg.super.ctor(self, "j")
    self.curPos = self.byteArray:getPos()
end

function RemoveBodyMsg:bodyLength(_sid,_len)
    self.byteArray:writeInt(_sid)
    self.byteArray:writeInt(_len)
end

function RemoveBodyMsg:parse(stream)
    self.snake  = stream:readInt()
    self.len    = stream:readInt()
end

return RemoveBodyMsg
