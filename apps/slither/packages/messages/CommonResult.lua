
local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local CommonResult = env.class("CommonResult", MessageBase)

function CommonResult:ctor()
    CommonResult.super.ctor(self, "c")
    self.curPos = self.byteArray:getPos()
end

function CommonResult:setResult(msg,id)
    self.byteArray:setPos(self.curPos)
    local str = env.json.encode(msg)
    if str == nil then
        cc.printerror("CommonResult:setResult nil")
        str = "{}"
    end
    self.byteArray:writeStringUInt(str)
    self.byteArray:writeInt(id or -1)
end

function CommonResult:parse(stream)
    self.msg = env.json.decode(stream:readStringUInt())
    self.id   = stream:readInt()
end

return CommonResult
