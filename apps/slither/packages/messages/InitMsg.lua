
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local InitMsg = env.class("InitMsg", MessageBase)

function InitMsg:ctor()
    InitMsg.super.ctor(self, "A")
    self.curPos = self.byteArray:getPos()
end

function InitMsg:setInitMsg(msg)
    local ba = self.byteArray
    -- map
    ba:writeInt(msg.map.mapRadius)
    ba:writeInt(msg.map.sectorSize)
    ba:writeInt(msg.map.windowSize)
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
    ba:writeFloat(msg.interval)
    ba:writeFloat(msg.timeout)
    ba:writeInt(msg.snakeMaxLength)
    ba:writeFloat(msg.deltaRadius)
    ba:writeInt(msg.snakeMaxRadius)
    ba:writeInt(msg.hitlessTime)
end

function InitMsg:parse(stream)
    self.map = {
        mapRadius  = stream:readInt(),
        sectorSize = stream:readInt(),
        windowSize = stream:readInt(),
    }

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
    self.interval = stream:readFloat()
    self.timeout  = stream:readFloat()
    self.snakeMaxLength = stream:readInt()
    self.deltaRadius    = stream:readFloat()
    self.snakeMaxRadius = stream:readInt()
    self.hitlessTime    = stream:readInt()
end

return InitMsg
