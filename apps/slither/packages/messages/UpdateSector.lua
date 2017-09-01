local import = import or cc.import
local env = import(".env")

local MessageBase  = env.import(".MessageBase")

local UpdateSector = env.class("UpdateSector", MessageBase)

function UpdateSector:ctor()
    UpdateSector.super.ctor(self, "D")
    self.curPos = self.byteArray:getPos()
end

function UpdateSector:setSectors(sectors)
    self.sectors = sectors
    self.byteArray:writeUShort(#self.sectors)
    for i=1,#self.sectors do
        self.byteArray:writeUShort(self.sectors[i])
    end
end

function UpdateSector:parse(stream)
    local sectorLen = stream:readUShort()
    self.sectors = {}
    for i=1,sectorLen do
        table.insert(self.sectors , stream:readUShort())
    end

end

return UpdateSector
