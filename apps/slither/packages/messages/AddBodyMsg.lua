
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local AddBodyMsg = env.class("AddBodyMsg", MessageBase)

function AddBodyMsg:ctor()
    AddBodyMsg.super.ctor(self, "J")
    self.curPos = self.byteArray:getPos()
end

function AddBodyMsg:bodyLength(_sid,_len)
    self.byteArray:writeInt(_sid)
    self.byteArray:writeInt(_len)
end

function AddBodyMsg:parse(stream)
    self.snake  = stream:readInt()
    self.len    = stream:readInt()
end

return AddBodyMsg
