
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local ClientSnake = env.class("ClientSnake", MessageBase)

function ClientSnake:ctor()
    ClientSnake.super.ctor(self, "C")
    self.curPos = self.byteArray:getPos()
end

function ClientSnake:setPosQueue(queue)
    local ba  = self.byteArray
    local len = #queue
    ba:writeInt(len)
    for i,v in ipairs(queue) do
        ba:writeFloat(v.x)
        ba:writeFloat(v.y)
    end

end

function ClientSnake:parse(stream)
    local posLen = stream:readInt()
    self.snakeBody = {}
    for i=1,posLen do
        table.insert(self.snakeBody, {
            x = stream:readFloat(),
            y = stream:readFloat(),
        })
    end

end

return ClientSnake
