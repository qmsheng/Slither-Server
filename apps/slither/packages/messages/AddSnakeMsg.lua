
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local AddSnakeMsg = env.class("AddSnakeMsg", MessageBase)

function AddSnakeMsg:ctor()
    AddSnakeMsg.super.ctor(self, "S")
    self.curPos = self.byteArray:getPos()
end

function AddSnakeMsg:addSnake(msg)
    local ba = self.byteArray
    -- snake
    ba:writeInt(msg.snake.id)
    ba:writeStringUInt(msg.snake.nick)
    ba:writeFloat(msg.snake.radius)
    ba:writeInt(msg.snake.len)
    ba:writeShort(msg.snake.skin)
    ba:writeInt(#msg.snake.pos)
    for i,v in ipairs(msg.snake.pos) do
        ba:writeFloat(v.x)
        ba:writeFloat(v.y)
    end
    ba:writeFloat(msg.snake.velocity.x)
    ba:writeFloat(msg.snake.velocity.y)
    ba:writeBool(msg.snake.hitEnable)
    -- ts
    ba:writeFloat(msg.ts)

end

function AddSnakeMsg:parse(stream)
    self.snake = {}
    self.snake.id       = stream:readInt()
    self.snake.nick     = stream:readStringUInt()
    self.snake.radius   = stream:readFloat()
    self.snake.len      = stream:readInt()
    self.snake.skin     = stream:readShort()
    local posLen = stream:readInt()
    self.snake.pos = {}
    for i=1,posLen do
        table.insert(self.snake.pos, {
            x = stream:readFloat(),
            y = stream:readFloat(),
        })
    end

    self.snake.velocity = {
        x = stream:readFloat(),
        y = stream:readFloat(),
    }

    self.snake.hitEnable = stream:readBool()
    self.ts = stream:readFloat()
end

return AddSnakeMsg
