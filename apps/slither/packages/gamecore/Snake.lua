
local helper     = cc.import(".helper")
local cc         = cc.import(".ccmath")
local json       = cc.import("cjson.safe")
local Sector     = cc.import(".Sector")
local SnakeBody  = cc.import(".SnakeBody")
local SectorEvent= cc.import(".SectorEvent")
local Food       = cc.import(".Food")
local messages   = cc.import("#messages")
local SnakePos   = cc.import(".SnakePos")
local Snake      = cc.class("Snake")

-- local allSkinId = {101,102,103,104,105,106,201,202,203,204,205,206}
local allSkinId = {202,204,201,203,207,208,209,210}

local _snakeIDCount = 1

function Snake:ctor (sid, clientId, nick, ts, sectorEvent)
    self.id    = _snakeIDCount
    self.sessionid = sid
    self.clientId  = clientId
    self.nick  = #nick>0 and nick or self.id
    self.bornTs   = ts
    self.sectorEvent = sectorEvent
    self.isAlive  = true
    self.userId   = ""
    self.skinId   = allSkinId[math.random(1, #allSkinId)]
    --开场不碰撞
    self.hitEnable = false

    self.delay        = GameConfig.updateInterval
    self.lastUpdateTs = ts
    self.lastBroadcast= ts
    self.posQueue = {}
    self.speedUp  = false

    self.sectors     = {}
    self.headSector  = -1
    self.viewSectors = {}
    self.viewSnakes  = {}
    self.headPath    = {}
    self.lead   = -1


    _snakeIDCount = _snakeIDCount +1
end

function Snake:removeSector(s)
    self.sectors[s] = nil
end

-- 更新自身所处的sector, 返回变化情况
function Snake:updateSectors()
    local ret = {}
    if self.pos then
        self.headSector = Sector.mapPosToSectorID(self.pos[1])
        local arr = {}
        for i,p in ipairs(self.pos) do
            local s = Sector.mapPosToSectorID(p)
            arr[s] = true
            -- 新进入的sector
            if self.sectors[s] == nil then
                ret[s] = true
            end
        end
        -- 离开的sector
        for k,v in pairs(self.sectors) do
            if not arr[k] then
                ret[k] = false
            end
        end
        self.sectors = arr
    end

    return ret
end

function Snake:updateSectorsByClient(sectors)
    local ret = {}
    self.headSector = sectors[1]

    local arr = {}
    for i,v in ipairs(sectors) do
        arr[v] = true
        -- 新进入的sector
        if self.sectors[v] == nil then
            ret[v] = true
        end
    end

    -- 离开的sector
    for k,v in pairs(self.sectors) do
        if not arr[k] then
            ret[k] = false
        end
    end
    self.sectors = arr
    return ret
end

function Snake:getViewSectors()
    local ret = {}
    for v,_ in pairs(self.viewSectors) do
        table.insert(ret, v)
    end
    return ret
end

function Snake:updateViewSectors()
    local ret = {}
    if self.headSector ~= -1 then
        local arr = {}
        for i,v in ipairs(Sector.getSurroundedSector(self.headSector, GameConfig.windowSize-1)) do
        -- for i,v in ipairs(Sector.getSurroundedSector(self.headSector, 1)) do
            arr[v] = true
        end
        -- arr[self.headSector] = true

        for k,v in pairs(arr) do
            if self.viewSectors[k] == nil then
                ret[k] = true
            end
        end
        -- remove
        for k,v in pairs(self.viewSectors) do
            if arr[k] == nil then
                ret[k] = false
            end
        end
        self.viewSectors = arr
    end
    return ret
end

function Snake:getViewSnakes()
    return table.keys(self.viewSnakes)
end

function Snake:updateViewSnakes()
    local ret = {}
    local snakes = {}
    for sectorid,_ in pairs(self.viewSectors) do
        for i,snakeid in ipairs(self.sectorEvent:getSnakesInSector(sectorid)) do
            snakes[snakeid] = true
        end
    end
    for snakeid,_ in pairs(snakes) do
        if not self.viewSnakes[snakeid] then
            ret[snakeid] = true
        end
    end

    for snakeid,_ in pairs(self.viewSnakes) do
        if not snakes[snakeid] then
            ret[snakeid] = false
        end
    end
    self.viewSnakes = snakes
    return ret
end

function Snake:pushPos(pos)
    table.insert(self.posQueue, pos)
    self:setHeadPos(pos)
end

function Snake:popPos()
    local ret = {}
    for i,p in ipairs(self.posQueue) do
        table.insert(ret, p.id)
        table.insert(ret, p.x)
        table.insert(ret, p.y)
    end
    return ret
end

function Snake:clearPosQueue()
    self.posQueue = {}
end

function Snake:setHeadPos(pos)
    -- 增加身体长度和半径
    local addLen =  math.floor(self.len) - #self.pos
    if addLen > 0 then
        -- cc.printinfo("addLen",addLen)
        if self.len < GameConfig.snakeMaxLength then
            for i=1,addLen do
                local p = cc.p(self.snakePos.poses[#self.snakePos.poses].x,
                                self.snakePos.poses[#self.snakePos.poses].y)

                table.insert(self.pos,p)
                self.snakePos:addBody()

                self.radius = self.radius + GameConfig.deltaRadius
                if self.radius > GameConfig.snakeMaxRadius then self.radius = GameConfig.snakeMaxRadius end
            end
        end
        -- self.len = #self.pos
        if self.len > self.lastLen then
            self.lastLen = self.len
            -- cc.printinfo("setHeadPos %d" , self.len)
            local msg = {
                name    = "addBody",
                snake   = self.id,
                len     = self.len - 1,
            }
            local dst = {}
            for v,_ in pairs(self.viewSectors) do
                table.insert(dst, v)
            end
            helper.updateSnakeLen(self.id, self.len - 1)
            local ba = messages.env.new(messages.AddBody)
            ba:bodyLength(self.id , self.len - 1)
            self.sectorEvent:processMessage(self.headSector, dst, ba,"binary")
        end
    end
    self.pos[1] = pos

    -- update body
    local distance = self.radius
    local poses = self.pos

    self.snakePos:update(pos)
    -- self.pos = self.snakePos.poses
    for i=2,#self.snakePos.poses do
        self.pos[i] = cc.p(self.snakePos.poses[i].x , self.snakePos.poses[i].y)
    end

    if self.speedUp and  #self.pos > 20 then
        self.len = self.len - 0.03
        self._diff  = self._diff + 0.03
        if self._diff > 0.2 then
            local p = self.pos[#self.pos]
            local radius = math.random(GameConfig.foodRadius[1], GameConfig.foodRadius[2]) / 5
            local pos = {
                x = p.x ,
                y = p.y
            }
            local food = Food:new(pos, radius)
            self.sectorEvent:addFoodBySpeedUp(food)
            self._diff = 0
        end

        if self.len < self.lastLen then
            self.lastLen = self.len
            local msg = {
                name    = "removeBody",
                snake   = self.id,
                len     = self.len - 1,
            }
            local dst = {}
            for v,_ in pairs(self.viewSectors) do
                table.insert(dst, v)
            end

            helper.updateSnakeLen(self.id, self.len - 1)
            local ba = messages.env.new(messages.RemoveBody)
            ba:bodyLength(self.id , self.len - 1)
            self.sectorEvent:processMessage(self.headSector, dst, ba,"binary")
        end

        if math.floor(self.len)  < #self.pos then
            if self.len < GameConfig.snakeMaxLength then
                self.radius = self.radius - GameConfig.deltaRadius
                local p = table.remove(self.pos,#self.pos)
                -- table.remove(self.bodys,#self.bodys)
                self.snakePos:removeBody()
            end
        end
    else
        self._diff = 0
    end
end

function Snake:init(pos, len, radius , isAi)
    self.len       = len
    self.lastLen   = len
    self.radius    = radius
    self.velocity  = GameConfig.snakeVelocity
    self.speed     = cc.pGetLength(self.velocity)
    self.steeringForce = cc.p(0,0)
    self.wanderAngle = 0
    self.isAi      = isAi
    -- 初始化body
    local arr = {pos}
    for i=1,len-1 do
        local n = arr[i]
        local p = {
            x = n.x - 15,
            y = n.y,
        }
        table.insert(arr, p)
    end
    self.pos = arr
    helper.updateSnakeLen(self.id, self.len - 1)
    self.len = #self.pos
    -- 截取小数点后两位
    for i=1,#self.pos do
        self.pos[i].x = math.floor(self.pos[i].x*100)/100
        self.pos[i].y = math.floor(self.pos[i].y*100)/100
    end

    self.snakePos = SnakePos:new(self.pos)
end

function Snake:arrive (targetPos , _ts)
    self.ts = _ts
    local desiredVelocity = cc.pSub(targetPos , self.pos[1])
    desiredVelocity = cc.pNormalize(desiredVelocity)
    desiredVelocity = cc.pMul(desiredVelocity  ,self.speed)

    local force = cc.pSub(desiredVelocity , self.velocity)
    self.steeringForce = cc.pAdd(self.steeringForce ,force)
    self:steerUpdate()
end

--规避
function Snake:flee (targetPos , _ts,_dt)
    self.ts = _ts
    self.vecFx = _dt/(1/60)
    local desiredVelocity = cc.pSub(targetPos , self.pos[1])
    desiredVelocity = cc.pNormalize(desiredVelocity)
    desiredVelocity = cc.pMul(desiredVelocity ,self.speed)

    local force = cc.pSub(desiredVelocity , self.velocity)
    self.steeringForce = cc.pSub(self.steeringForce ,force)
    self:steerUpdate()
    -- self.velocity = desiredVelocity
    -- self:steerUpdate()
end

--漫游
function Snake:wander(_ts , _dt)
    self.ts = _ts
    self.vecFx = _dt/(1/60)
    local p = cc.pNormalize(self.velocity)
    p = cc.pMul(p , 10)

    local offsetP = cc.pForAngle(self.wanderAngle)
    offsetP       = cc.pMul(offsetP , 5)
    self.wanderAngle = self.wanderAngle + (math.random(-50, 50)/100) * 2
    local force   = cc.pAdd(p,offsetP)
    self.steeringForce = cc.pAdd(self.steeringForce ,force)
    self:steerUpdate()


end

function Snake:steerUpdate()
    self.steeringForce = cc.pTruncate(self.steeringForce , 2)
    self.steeringForce = cc.pMul(self.steeringForce ,1/5)
    self.velocity = cc.pAdd(self.velocity  , self.steeringForce)
    self.steeringForce = cc.p(0,0)

    self.velocity = cc.pTruncate(self.velocity , self.speed * self.vecFx)
    -- self.velocity = cc.pMul(self.velocity , self.vecFx)


    local p = cc.pAdd(self.pos[1] ,self.velocity)
    self:isBoundry(p)

    local rp = cc.pAdd(self.pos[1] , self.velocity)


    local t = {
        x  = cc.round(rp.x),
        y  = cc.round(rp.y),
        speedUp = 0,
        ts = cc.round(self.ts,3)
    }

    self:pushPos(t)
end

function Snake:isBoundry(p)
    local cp = cc.pSub(p , cc.p( GameConfig.mapRadius, GameConfig.mapRadius))
    local dis =  cc.pGetLength(cp)

    if dis > GameConfig.mapRadius then
        self.velocity = cc.pMul(self.velocity , -1)
    end


end

function Snake:update (vel, ts)
    local dt = ts - self.lastUpdateTs

    -- 增加身体长度
    local distance = self.radius
    if math.floor(self.len) > #self.pos then
        local p = {
            x = self.pos[#self.pos].x,
            y = self.pos[#self.pos].y,
        }
        table.insert(self.pos,p)
    end
    -- 头部的位置根据上次的速度直接计算
    local headPos = cc.pAdd( self.pos[1], cc.pMul(self.velocity, dt) )
    self.pos[1] = headPos

    -- update body
    local poses = self.pos
    for i=2,#poses do
        local dir = cc.pSub(poses[i], poses[i-1])
        dir = cc.pNormalize(dir)
        dir = cc.pMul(dir, distance)
        poses[i] = cc.pAdd(poses[i-1], dir)
    end

    -- 截取小数点后两位
    for i=1,#self.pos do
        self.pos[i].x = math.floor(self.pos[i].x*100)/100
        self.pos[i].y = math.floor(self.pos[i].y*100)/100
    end

    -- 更新状态
    self.velocity     = vel
    self.lastUpdateTs = ts
    self.lastHeartbeat= ts
end

function Snake:getData()
    local data = {
        id      = self.id,
        nick    = self.nick,
        len     = self.len,
        radius  = self.radius,
        velocity= self.velocity,
        pos     = self.pos,
        ts      = self.lastUpdateTs,
        skin    = self.skinId,
        hitEnable = self.hitEnable
    }
    -- cc.printinfo("len %f",self.len)
    -- cc.printinfo("pos %f",#self.pos)
    return data
end

function Snake:sendMessage(msg)
    helper.sendMessage(self.clientId, msg)
end

function Snake:sendBinaryMessage(msg)
    helper.sendMessage(self.clientId, msg:getRawStream(), true)
end

return Snake
