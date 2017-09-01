
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local UpdateSnakeMsg = env.class("UpdateSnakeMsg", MessageBase)

function UpdateSnakeMsg:ctor()
    UpdateSnakeMsg.super.ctor(self, "U")
    self.curPos = self.byteArray:getPos()
end

function UpdateSnakeMsg:setUpdateSnake(msg)
    local ba = self.byteArray

    ba:writeUShort(#msg.data)
    for i,data in ipairs(msg.data) do
        ba:writeUShort(data.id)
        local snakePosLen = #data.queue
        ba:writeUShort(snakePosLen)
        for j=1,snakePosLen-1,3 do
            ba:writeUInt(data.queue[j])
            ba:writeFloat(data.queue[j+1])
            ba:writeFloat(data.queue[j+2])
        end
    end
    ba:writeFloat(msg.ts)
end

function UpdateSnakeMsg:parse(stream)
    self.data = {}
    local allsnakedata = {}

    local snakeLen = stream:readUShort()

    while snakeLen > 0 do
        local id = stream:readUShort()
        local posLen = stream:readUShort()
        local pos ={}
        for i=1,posLen-1,3 do
            table.insert(pos,stream:readUInt())
            table.insert(pos,stream:readFloat())
            table.insert(pos,stream:readFloat())
        end

        table.insert(allsnakedata, {
            id    = id,
            queue = pos,
        })

        snakeLen = snakeLen - 1
    end

    self.data = allsnakedata
    self.ts = stream:readFloat()

end

return UpdateSnakeMsg
