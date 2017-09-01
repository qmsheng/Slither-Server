
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local AddFoodMsg = env.class("AddFoodMsg", MessageBase)

function AddFoodMsg:ctor()
    AddFoodMsg.super.ctor(self, "F")
    self.curPos = self.byteArray:getPos()
end

function AddFoodMsg:setFoodMsg(msg)
    self.byteArray:writeInt(#msg.data)
    for i,v in ipairs(msg.data) do
        self.byteArray:writeInt(v[1])
        self.byteArray:writeFloat(v[2])
        self.byteArray:writeFloat(v[3])
        self.byteArray:writeFloat(v[4])
    end
end

function AddFoodMsg:parse(stream)
    local len = stream:readInt()
    self.data = {}
    for i=1,len do
        local d =  {
            stream:readInt(),
            stream:readFloat(),
            stream:readFloat(),
            stream:readFloat()
        }
        table.insert(self.data,d)
    end
end

return AddFoodMsg
