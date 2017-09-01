
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local Pos = env.class("Pos", MessageBase)

function Pos:ctor()
    Pos.super.ctor(self, "P")
    self.curPos = self.byteArray:getPos()
end

function Pos:setPosQueue(queue)
    self.localQueue = queue
    local count = #queue
    self.byteArray:writeUShort(count)
    for i=1,count-1,3 do
        self.byteArray:writeUInt(queue[i])
        self.byteArray:writeFloat(queue[i+1])
        self.byteArray:writeFloat(queue[i+2])
    end
end

function Pos:parse(stream)
    local pos = {}
    local count = stream:readUShort()
    for i=1,count-1,3 do
        table.insert(pos, stream:readUInt())
        table.insert(pos, stream:readFloat())
        table.insert(pos, stream:readFloat())
    end
    self.pos = pos
end

return Pos
