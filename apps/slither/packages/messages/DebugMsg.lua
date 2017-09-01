
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local DebugMsg = env.class("DebugMsg", MessageBase)

function DebugMsg:ctor()
    DebugMsg.super.ctor(self, "X")
    self.curPos = self.byteArray:getPos()
end

function DebugMsg:addSnake(msg)
    local ba = self.byteArray
    -- snake
    ba:writeInt(msg.data.id)
    ba:writeStringUInt(msg.data.nick)
    ba:writeFloat(msg.data.radius)
    ba:writeInt(msg.data.len)
    ba:writeInt(#msg.data.pos)
    for i,v in ipairs(msg.data.pos) do
        ba:writeFloat(v.x)
        ba:writeFloat(v.y)
    end
    ba:writeFloat(msg.data.velocity.x)
    ba:writeFloat(msg.data.velocity.y)
    -- ts
    ba:writeFloat(msg.ts)

end

function DebugMsg:parse(stream)
    self.data = {}
    self.data.id       = stream:readInt()
    self.data.nick     = stream:readStringUInt()
    self.data.radius   = stream:readFloat()
    self.data.len      = stream:readInt()
    local posLen = stream:readInt()
    self.data.pos = {}
    for i=1,posLen do
        table.insert(self.data.pos, {
            x = stream:readFloat(),
            y = stream:readFloat(),
        })
    end

    self.data.velocity = {
        x = stream:readFloat(),
        y = stream:readFloat(),
    }

    self.ts = stream:readFloat()
end

return DebugMsg
