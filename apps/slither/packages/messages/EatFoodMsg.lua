
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local EatFoodMsg = env.class("EatFoodMsg", MessageBase)

function EatFoodMsg:ctor()
    EatFoodMsg.super.ctor(self, "G")
    self.curPos = self.byteArray:getPos()
end

function EatFoodMsg:setEatFood(_fid,_sid)
    self.byteArray:writeInt(_fid)
    self.byteArray:writeInt(_sid)
end

function EatFoodMsg:parse(stream)
    self.id = stream:readInt()
    self.snake = stream:readInt()
end

return EatFoodMsg
