
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local Ready = env.class("Ready", MessageBase)

function Ready:ctor()
    Ready.super.ctor(self, "Y")
    self.curPos = self.byteArray:getPos()
end

function Ready:setDelay(delay,_name)
    self.byteArray:setPos(self.curPos)
    self.byteArray:writeFloat(delay)
    self.byteArray:writeStringUInt(_name)
end

function Ready:parse(stream)
    self.delay = stream:readFloat()
    self.userName = stream:readStringUInt()
end

return Ready
