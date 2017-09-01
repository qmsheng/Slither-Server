local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local RemoveFoodMsg = env.class("RemoveFoodMsg", MessageBase)

function RemoveFoodMsg:ctor()
    RemoveFoodMsg.super.ctor(self, "f")
    self.curPos = self.byteArray:getPos()
end


function RemoveFoodMsg:removeFood(msg)
    self.byteArray:writeInt(#msg.data)
    for i,v in ipairs(msg.data) do
        self.byteArray:writeInt(v)
    end
end

function RemoveFoodMsg:parse(stream)
    local len = stream:readInt()
    self.data = {}
    for i=1,len do
        table.insert(self.data,stream:readInt())
    end
end

return RemoveFoodMsg
