local import = import or cc.import
local env = import(".env")

local Message = env.class("Message")

function Message:ctor(msgName)
    self.name = msgName or "unknown"
    self.byteArray = env.newByteArray()
    self.byteArray:writeString(self.name)
end

function Message:getRawStream()
    return self.byteArray:getBytes()
end

function Message:getPackedStream()
    local buffer = env.newByteArray()
    buffer:writeStringUInt("client.event")
    buffer:writeBytes(self.byteArray)
    return buffer:getBytes()
end

return Message
