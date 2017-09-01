
local helper     = cc.import(".helper")

local Sector = cc.class("Sector")

function Sector:ctor (id, rect)
    self.id        = id
    self.rect      = rect

    --周围的sectors
    -- self.surround  = Sector.getSurroundedSector(self.id, GameConfig.windowSize-1)

    self.snakes    = {}
    self.snakeFlags= {}
    self.foods     = {}
    self.foodFlags = {}
end

function Sector:hasSnake(sid)
    return self.snakeFlags[sid]
end

function Sector:addSnake(sid)
    if not self.snakeFlags[sid] then
        self.snakeFlags[sid] = true
        table.insert(self.snakes, sid)
    end
end

function Sector:removeSnake(sid)
    if self.snakeFlags[sid] then
        for i,v in ipairs(self.snakes) do
            if v == sid then
                table.remove(self.snakes, i)
                self.snakeFlags[sid] = false
                break
            end
        end
    end
end

function Sector:hasFood(fid)
    return self.foodFlags[fid]
end

function Sector:addFood(fid)
    if not self.foodFlags[fid] then
        self.foodFlags[fid] = true
        table.insert(self.foods, fid)
    end
end

function Sector:removeFood(fid)
    if self.foodFlags[fid] then
        for i,v in ipairs(self.foods) do
            if v == fid then
                table.remove(self.foods, i)
                self.foodFlags[fid] = false
                break
            end
        end
    end
end

-- SectorID计算, 从1开始
function Sector.mapPosToSectorID(pos)
    local xx = math.floor(pos.x / GameConfig.sectorSize)
    local yy = math.floor(pos.y / GameConfig.sectorSize)
    local rowCount = GameConfig.mapRadius / GameConfig.sectorSize * 2
    -- cc.printinfo("%f,%f", pos.x, pos.y)
    return xx + yy*rowCount + 1
end

function Sector.getSurroundedSector(sectorid, rad)
    local rowCount = GameConfig.mapRadius / GameConfig.sectorSize * 2
    local xx = (sectorid-1) % rowCount
    local yy = math.floor( (sectorid-1) / rowCount)

    local ret = {}
    local sx = xx - rad
    local ex = xx + rad
    local sy = yy - rad
    local ey = yy + rad

    for y=sy,ey do
        for x=sx,ex do
            if x>=0 and y>=0 and x<=rowCount-1 and y<=rowCount-1 then
                table.insert(ret, x+y*rowCount+1)
            end
        end
    end

    return ret
end

return Sector
