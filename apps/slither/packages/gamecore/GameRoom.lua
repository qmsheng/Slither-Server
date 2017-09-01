
local helper     = cc.import(".helper")
local cc         = cc.import(".ccmath")
local json       = cc.import("cjson.safe")
local Snake      = cc.import(".Snake")
local Food       = cc.import(".Food")
local socket     = cc.import("socket")
local Sector     = cc.import(".Sector")
local SectorEvent= cc.import(".SectorEvent")
local messages   = cc.import("#messages")
local ByteArray  = messages.env.ByteArray
local ev         = cc.import("ev")

local gbc        = cc.import("#gbc")
local Constants  = gbc.Constants
local Session    = cc.import("#session")
local Online     = cc.import("#online")

local io_flush      = io.flush
local table_insert  = table.insert
local evloop = ev.Loop.default

local GameRoom   = cc.class("GameRoom")
local _g_roomid  = 0
function GameRoom:ctor (gbcInstance)
    self.gbcInstance     = gbcInstance
    self.online = Online:new(gbcInstance)
    _g_roomid = _g_roomid + 1
    self.id = _g_roomid

    -- 暂时使用全局config
    self.config = GameConfig
    self.serverTimeout = 3

    self.sectorEvent= SectorEvent:new(self)
    self.sessionMap = {}
    self.snakes     = {}
    self.snakeCount = 0
    self.sectors    = {}
    self.foods      = {}
    self.scheduledTasks = {}
    self.messagePool    = {}
    self.timers         = {}
    self.addSnakeQueue  = {}

    self.mapCenter  = {
        x = self.config.mapRadius,
        y = self.config.mapRadius,
    }

    self.initTs         = socket.gettime()
    self.elapseTs       = 0
    self.lastBroadcast  = 0

    self:initGame()
end

function GameRoom:pushClientMessage(msg)
    table_insert(self.messagePool, msg)
end

function GameRoom:initGame ()
    local config = self.config
    -- 初始化sectors
    local x_count = config.mapRadius / config.sectorSize * 2
    local y_count = config.mapRadius / config.sectorSize * 2

    for y=1,y_count do
        for x=1,x_count do
            local id = (y-1)*x_count + x
            local xx = (x-1)*config.sectorSize
            local yy = (y-1)*config.sectorSize
            local rect = cc.rect(xx,yy,config.sectorSize,config.sectorSize)
            local sector = Sector:new(id, rect)
            table_insert(self.sectors, sector)
        end
    end

    self:addFoodRandom(config.foodMaxCount)

    -- loop timer
    self.lastUpdateTime = socket.gettime()
    local timer = ev.Timer.new(function()
        local timeNow = socket.gettime()
        local dt = timeNow - self.lastUpdateTime
        self:update(dt)
        self.lastUpdateTime = timeNow
        io_flush()
    end, config.loopInterval, config.loopInterval)
    timer:start(evloop)
    self.loopTimer = timer
    table.insert(self.timers, timer)

    -- checkAliveTimer
    local checkTimer = ev.Timer.new(function()
        self:checkSnakeAlive()
    end, 1.0, 0.1)
    checkTimer:start(evloop)
    self.checkTimer = checkTimer
    table.insert(self.timers, checkTimer)

    -- leadboard and mini map
    local timer = ev.Timer.new(function()
        self:updateTop10AndMinimap()
    end, 0.5, 0.2)
    timer:start(evloop)
    self.leadboardTimer = timer
    table.insert(self.timers, timer)

    cc.printinfo("room %d init ok.", self.id)
end

function GameRoom:stopAllTimer()
    for _,timer in ipairs(self.timers) do
        timer:stop(evloop)
    end
    self.timers = {}
end

function GameRoom:processClientMessage()
    local pool = self.messagePool
    self.messagePool = {}

    for _,msg in ipairs(pool) do
        local msgName = msg.name
        local sid     = self.sessionMap[msg.clientId]
        if msgName == "connected" then
            local clientId  = msg.clientId
            local sessionid = msg.sessionid
            local nick      = msg.username or tostring(msg.clientId)
            local isNew = true
            local snake = nil
            for k,v in pairs(self.snakes) do
                if v.sessionid == sessionid then
                    isNew = false
                    snake = v
                    break
                end
            end
            if isNew then
                cc.printinfo("new snake:  %s,%s", clientId, sessionid)
                self:addSnake(sessionid, clientId, msg.userId, nick)
            else
                cc.printinfo("reconnect snake:  %s,%s", clientId, sessionid)
                self.sessionMap[snake.clientId] = nil
                snake.clientId = clientId
                self.sessionMap[snake.clientId] = snake.id
            end
        elseif msgName == "disconnected" then
            if sid then
                self:removeSnake(sid, 0)
                self:destroySnake(sid)
                cc.printinfo("leave room %s", sid)
                -- session
                local session = Session:new(self.gbcInstance:getRedis())
                if session:start(msg.sessionid) then
                    session:destroy()
                end
            end
        elseif msgName == "Ready" then
            local nick = msg.userName
            self:initSnake(sid, nick)
        elseif msgName == "SnakeHit" then
            -- local snake  = self.snakes[sid]
            -- local data = msg.snakeBody
            -- for i=1,#data do
            --     snake.pos[i] = data[i]
            -- end
            -- snake.len = #data
            self:snakeCrashSnake(sid, msg.hitID)
        elseif msgName  == "ClientSnake" then
            local snake  = self.snakes[sid]
            cc.printinfo("ClientSnake %s", sid)
            if snake then
                local data = msg.snakeBody
                for i=1,#data do
                    snake.pos[i] = data[i]
                end
                -- cc.dump(snake.pos)
                -- cc.printinfo("snake.pos[1] %f   %f",snake.pos[i].x , snake.pos[i].y)

                -- queue
                local sq = self.addSnakeQueue[sid]
                if sq then
                    local msg = {
                        name    = "addSnake",
                        snake   = snake:getData(),
                        ts      = self.elapseTs,
                    }
                    local ba = messages.env.new(messages.AddSnake)
                    ba:addSnake(msg)

                    for k,v in pairs(sq) do
                        local s = self.snakes[k]
                        if s and s.isAlive then
                            s:sendBinaryMessage(ba)
                            cc.printinfo("%s send to %s", sid, k)
                            -- cc.dump(msg)
                        end
                    end
                    self.addSnakeQueue[sid] = nil
                end
            end
        elseif msgName  == "CommonRequest" then
            local snake  = self.snakes[sid]
            if msg.msg.name == "GetSnakeData" then
                cc.printinfo("addSnake request")
                if snake and self.snakes[msg.id] and self.snakes[msg.id].isAlive then
                    msg = {
                        name    = "addSnake",
                        snake   = self.snakes[msg.id]:getData(),
                        ts      = self.elapseTs,
                    }
                    local ba = messages.env.new(messages.AddSnake)
                    ba:addSnake(msg)
                    snake:sendBinaryMessage(ba)
                end
            end
        elseif msgName == "Pos" then
            local snake  = self.snakes[sid]
            local poses  = msg.pos
            if snake and snake.isAlive and poses[1] then
                if snake.hitEnable == false then
                    if self.elapseTs - snake.bornTs > self.config.hitlessTime then
                        snake.hitEnable = true
                        if snake then
                            local _m = messages.env.new(messages.HitEnable)
                            _m:setSnakeHitEnable(sid, snake.hitEnable)
                            for _,id in pairs(snake:getViewSnakes()) do
                                local s = self.snakes[id]
                                if s then
                                    s:sendBinaryMessage(_m)
                                end
                            end
                        end
                    end
                end
                for i=1,#poses-1,3 do
                    snake:pushPos({
                        id      = poses[i],
                        x       = poses[i+1],
                        y       = poses[i+2],
                    })
                end
                snake.lastHeartbeat = self.elapseTs
            end
        elseif msgName == "FoodHit" then
            self:eatFood(sid,msg.hitID)
        elseif msgName == "Sectors" then
            local snake  = self.snakes[sid]
            if snake and snake.isAlive then
                local sectorChanged = snake:updateSectorsByClient(msg.sectors)
                local viewChanged   = snake:updateViewSectors()

                for k,v in pairs(sectorChanged) do
                    local sector = self.sectors[k]
                    if sector and v then
                        self.sectors[k]:addSnake(sid)
                    elseif sector then
                        self.sectors[k]:removeSnake(sid)
                    end
                end

                for k,v in pairs(viewChanged) do
                    if v then
                        self.sectorEvent:snakeEnter(sid, k)
                    else
                        self.sectorEvent:snakeLeave(sid, k)
                    end
                end
                helper.updateSnakePos(sid,snake.pos[1])
            end
        elseif msgName == "Echo" then
            local ba = messages.env.new(messages.Echo)
            ba:setEcho({
                text = msg.text,
                count= self.snakeCount,
            })
            helper.sendMessage(msg.clientId, ba:getRawStream(), true)
        elseif msgName == "HeartBeat" then
            local snake  = self.snakes[sid]
            if snake then
                snake.lastHeartbeat = self.elapseTs
            end
        elseif msgName == "EnterGame" then
            self:snakeEnterGame(sid, msg.sessionid, msg.userId)
        elseif msgName == "LeaveGame" then
            local sessionid = msg.sessionid
            local clientId = sessionid
            -- helper.removeClient(clientId)
        elseif msgName == "SpeedUp" then
            local snake  = self.snakes[sid]
            snake.speedUp = msg.isSpeedUp
            if snake then
                local _m = messages.env.new(messages.SpeedUp)
                _m:setSnakeID(sid, msg.isSpeedUp)
                for _,id in pairs(snake:getViewSnakes()) do
                    local s = self.snakes[id]
                    if s then
                        s:sendBinaryMessage(_m)
                    end
                end
            end
        end
    end
end

function GameRoom:updateTop10AndMinimap()
    local leads     = {}
    local minimap   = {}

    -- local snakeArr = table.values(self.snakes)
    local snakeArr = {}
    table.walk(self.snakes, function(s)
        if s.isAlive then
            s.lead = -1
            table.insert(snakeArr, s)
        end
    end)

    table.sort(snakeArr, function(m, n)
        return m.len > n.len
    end)

    for i=1,10 do
        local snake = snakeArr[i]
        if snake then
            snake.lead = i
            table.insert(leads, {
                id      = snake.id,
                len     = math.floor(snake.len-1),
                nick    = snake.nick,
            })
        end
    end

    for k,snake in pairs(self.snakes) do
        if snake and snake.isAlive then
            table.insert(minimap, {
                id  = snake.id,
                x   = math.floor(snake.pos[1].x),
                y   = math.floor(snake.pos[1].y),
                lead = snake.lead,
            })
        end
    end

    helper.updateTop10AndMinimapForRoom(self.id, leads, minimap)

    -- push to all
    local msg = messages.env.new(messages.CommonResult)
    msg:setResult({
        name = "MiniMap",
        data = minimap,
    })
    table.walk(self.snakes, function(s)
        if s then
            s:sendBinaryMessage(msg)
        end
    end)

    msg = messages.env.new(messages.CommonResult)
    msg:setResult({
        name = "LeaderBoard",
        data = leads,
    })
    table.walk(self.snakes, function(s)
        if s then
            s:sendBinaryMessage(msg)
        end
    end)
end

function GameRoom:addSnake (sessionid, clientId, userId, nick)
    local snake = Snake:new(sessionid, clientId, nick, self.elapseTs, self.sectorEvent)
    local a = math.random() * math.pi * 2
    local pos = {
        x = self.mapCenter.x + math.cos(a) * (self.config.mapRadius /2),
        y = self.mapCenter.y + math.sin(a) * (self.config.mapRadius /2),
    }
    snake:init(pos, self.config.snakeLength, self.config.bodyRadius)
    snake.isAlive  = false
    snake.sessionid= sessionid
    snake.clientId = clientId
    snake.userId   = userId

    local snakeId = snake.id
    self.sessionMap[clientId] = snakeId
    self.snakes[snakeId] = snake
    self.snakeCount = self.snakeCount + 1
end

function GameRoom:removeSnake (sid, _reason, _isDead)
    local snake = self.snakes[sid]
    if snake then
        if snake.isAlive then
            self:addFoodBySnake(snake)
            snake.isAlive = false
            self.snakeCount = self.snakeCount - 1
        end

        if not _isDead then
            _isDead = false
        end

        local msg = {
            name = "removeSnake",
            id   = sid,
            ts   = self.elapseTs,
            isDead = _isDead,
            reason = _reason,
        }
        local ba = messages.env.new(messages.RemoveSnake)
        ba:setSnakeID(msg)

        self.sectorEvent:processMessage(snake.headSector, snake:getViewSectors(), ba, "binary")

        --  从对应的sectors里清除
        -- for k,v in pairs(snake.sectors) do
        --     self.sectors[k]:removeSnake(sid)
        -- end
        -- self.snakes[sid]  = nil

        -- helper.removeClient(sid)
        -- self.online:remove(snake.sessionid)
    end
end

function GameRoom:destroySnake(snakeId)
    local snake = self.snakes[snakeId]
    if snake and not snake.isAlive then
        self.sessionMap[snake.clientId] = nil
        -- 从对应的sectors里清除
        for k,v in pairs(snake.sectors) do
            self.sectors[k]:removeSnake(snakeId)
        end
        self.snakes[snakeId]  = nil

        helper.removeClient(snakeId)
    end
end

function GameRoom:initSnake (sid, nick)
    local snake = self.snakes[sid]
    snake.isAlive = true
    if nick then snake.nick = nick end

    -- 加入对应的sector
    local arr = snake:updateSectors()
    for k,v in pairs(arr) do
        if v then
            self.sectors[k]:addSnake(sid)
        end
    end
    -- 地图信息
    local msg = {
        name = "init",
        map = {
            mapRadius   = self.config.mapRadius,
            sectorSize  = self.config.sectorSize,
            windowSize  = self.config.windowSize,
        },
        snake = snake:getData(),
        ts = self.elapseTs,
        -- lastBroadcast = self.lastBroadcast,
        interval = self.config.updateInterval,
        timeout  = self.serverTimeout,
        snakeMaxLength = self.config.snakeMaxLength,
        deltaRadius    = self.config.deltaRadius,
        snakeMaxRadius = self.config.snakeMaxRadius,
        hitlessTime    = self.config.hitlessTime,
    }
    local ba = messages.env.new(messages.Init)
    ba:setInitMsg(msg)
    snake:sendBinaryMessage(ba)
end

function GameRoom:snakeEnterGame(sid, sessionid, userId)
    local snake = self.snakes[sid]
    snake.sessionid = sessionid
    snake.userId = userId
    local viewSectors = snake:updateViewSectors()
    for k,v in pairs(viewSectors) do
        self.sectorEvent:snakeEnter(snake.id, k)
    end

    -- cc.printinfo("sid: %s, userId: %s", sid, snake.userId)
    self.online:add(sessionid, snake.clientId)
    helper.addClient(sid, snake.userId, snake.location, snake.len)
end

function GameRoom:update (dt)
    self.elapseTs = self.elapseTs + dt
    if self.elapseTs - self.lastBroadcast >= self.config.updateInterval then
        -- broadcast 消息
        self.lastBroadcast = self.elapseTs

        -- 检测当前食物数量
        local foodCount = table.length(self.foods)
        if foodCount < self.config.foodMaxCount*0.9 then
            self:addFoodRandom(self.config.foodMaxCount - foodCount)
        end


        for sid,snake in pairs(self.snakes) do
            -- 处理add, remove snake
            local snakesChanged =  snake:updateViewSnakes()
            for id,v in pairs(snakesChanged) do
                local msg = nil
                local ba  = nil
                if v and self.snakes[id] and self.snakes[id].isAlive then
                    msg = {
                        name    = "addSnake",
                        snake   = self.snakes[id]:getData(),
                        ts      = self.elapseTs,
                    }
                    ba = messages.env.new(messages.AddSnake)
                    ba:addSnake(msg)
                    -- self:requestSnakeData(sid, id)
                else
                    msg = {
                        name = "removeSnake",
                        id   = id,
                        ts   = self.elapseTs,
                        reason = 0,
                    }
                    ba = messages.env.new(messages.RemoveSnake)
                    ba:setSnakeID(msg)
                end
                if ba then snake:sendBinaryMessage(ba) end
            end

            local allsnakedata = {}

            -- local viewSectors = snake:getViewSectors()
            -- for _,v in ipairs(viewSectors) do
            --     local sector = self.sectors[v]
            --     for _,id in ipairs(sector.snakes) do
            --         viewSnakes[id] = true
            --     end
            -- end
            local viewSnakes = snake:getViewSnakes()
            local isSelfIn = false
            for _,id in pairs(viewSnakes) do
                if id == snake.id then
                    isSelfIn = true
                    break
                end
            end
            if not isSelfIn then
                table_insert(viewSnakes, snake.id)
            end

            for _,id in pairs(viewSnakes) do
                local s = self.snakes[id]
                if s then
                    local q = s:popPos()
                    if #q > 0 then
                        table_insert(allsnakedata, {
                            id    = s.id,
                            queue = q,
                        })
                    end
                end
            end
            local msg = {
                -- name = "updateSnake",
                data = allsnakedata,
                ts   = self.elapseTs,
            }
            local ba = messages.env.new(messages.UpdateSnake)
            ba:setUpdateSnake(msg)
            snake:sendBinaryMessage(ba)
        end

        for sid,snake in pairs(self.snakes) do
            snake:clearPosQueue()
        end

        -- for k,s in pairs(self.snakes) do
        --     local msg = {
        --         name = "debugData",
        --         data = s:getData(),
        --         ts   = self.elapseTs,
        --     }
        --     local ba = messages.env.new(messages.Debug)
        --     ba:addSnake(msg)
        --
        --     for i,snake in pairs(self.snakes) do
        --         snake:sendBinaryMessage(ba)
        --     end
        -- end
    end
    -- 处理延时任务
    local index = 1
    local task = self.scheduledTasks[index]
    while task ~= nil do
        if self.elapseTs >= task.ts then
            task.func()
            table.remove(self.scheduledTasks, index)
        else
            index = index + 1
        end
        task = self.scheduledTasks[index]
    end

    -- 处理client 消息
    self:processClientMessage()

    --检测食物碰撞
    for sid,snake in pairs(self.snakes) do
        -- if snake and snake.isAlive then
        --     local rw = snake.radius*4
        --     local rh = snake.radius*4
        --     local rect = cc.rect(
        --         snake.pos[1].x - rw/2,
        --         snake.pos[1].y - rh/2,
        --         rw, rh
        --     )
        --     local resultfoodid = {}
        --
        --     for fid,f in pairs(self.foods) do
        --         if cc.rectContainsPoint(rect, f.pos) then
        --             if cc.pGetDistance(f.pos, snake.pos[1]) < f.radius+snake.radius*1.0 then
        --                 table_insert(resultfoodid, f.id)
        --             end
        --         end
        --     end
        --     if #resultfoodid > 0 then
        --         for _,fid in ipairs(resultfoodid) do
        --             self:eatFood(sid, fid)
        --         end
        --     end

            -- 检测蛇的碰撞
            -- local rect = cc.rect(snake.pos[1].x, snake.pos[1].y, snake.radius*3, snake.radius*3)
            -- local rw = snake.radius*4
            -- local rh = snake.radius*4
            -- local rect = cc.rect(
            --     snake.pos[1].x - rw/2,
            --     snake.pos[1].y - rh/2,
            --     rw, rh
            -- )
            -- for k,v in pairs(self.snakes) do
            --     if k ~= sid and v.isAlive then
            --         for i=2,#v.pos do
            --             local p = v.pos[i]
            --             if cc.rectContainsPoint(rect, p) then
            --                 if cc.pGetDistance(p, snake.pos[1]) < v.radius+snake.radius then
            --                     self:snakeCrashSnake(sid, k)
            --                     break
            --                 end
            --             end
            --         end
            --     end
            -- end

        -- end
    end
end

function GameRoom:snakeCrashSnake(sid1, sid2)
    -- cc.printwarn("%s    die   %s", sid1, sid2)
    local snake = self.snakes[sid1]
    if snake and snake.isAlive then
        snake.isAlive = false
        self.snakeCount = self.snakeCount - 1
        -- push remove
        self:removeSnake(sid1, sid2, true)
        if sid1 ~= sid2 then
            helper.recordSnakeKill(sid2, sid1)
        end
        -- 身体变成食物
        self:addFoodBySnake(snake)
    end
end

function GameRoom:addFood(food)
    local id = food.id
    local sector = self.sectors[food.sector]
    if id and sector then
        self.foods[id] = food
        sector:addFood(id)
    end
end

function GameRoom:removeFood(foodid)
    local food = self.foods[foodid]
    self.sectors[food.sector]:removeFood(foodid)
    self.foods[foodid] = nil
end

function GameRoom:eatFood(sid, fid)
    local snake = self.snakes[sid]
    local food  = self.foods[fid]
    if snake and food then
        snake.len = snake.len + self.foods[fid].radius / snake.radius

        self:removeFood(fid)
        --  广播
        local msg = {
            name = "eatFood",
            id   = fid,
            snake= sid,
        }

        local ba = messages.env.new(messages.EatFood)
        ba:setEatFood(fid,sid)

        self.sectorEvent:processMessage(snake.headSector, snake:getViewSectors(), ba,"binary")
    end
end

function GameRoom:getAllFoodData()
    local data = {}
    for fid,f in pairs(self.foods) do
        table_insert(data, f.id)
        table_insert(data, f.radius)
        table_insert(data, f.pos.x)
        table_insert(data, f.pos.y)
    end
    return data
end

function GameRoom:addFoodRandom(num)
    local pNum = math.floor(self.config.mapRadius / 60)
    local d = (num - pNum) / (pNum * (pNum - 1) / 2)
    d = math.max(d, 0)
    local r = 1
    for i=1,pNum do
            local radius = math.random(self.config.foodRadius[1], self.config.foodRadius[2])
            local l = 2 * math.pi * r

            local foodNum = 1 + d *(i-1)
            foodNum = math.floor(foodNum)

            for k =1,foodNum do
                local a = math.random(-math.pi * 2000,  math.pi * 2000)/1000
                local r = math.random(r - 30, r + 30)
                local pos = {
                    x = self.mapCenter.x + math.cos(a) * r,
                    y = self.mapCenter.y + math.sin(a) * r,
                }
                local food = Food:new(pos, radius)
                self:addFood(food)
            end
        r = r + 60
    end
end

function GameRoom:addFoodBySnake(snake)
    local poses      = snake.pos
    local baseRadius = snake.radius

    local foodData = {}
    local foodSectors = {}
    local totalRadius = 0
    local perRadis = 0
    for i=1,#poses do
        baseRadius = baseRadius - self.config.deltaRadius
        totalRadius = totalRadius + baseRadius
    end
    perRadis = (totalRadius/#poses) * 0.8

    for i,p in ipairs(poses) do
        if i > 0 then
            local radius = perRadis
            local a = math.random() * math.pi * 2
            -- local r = math.random(self.config.foodRadius[1], self.config.foodRadius[2])
            local r = radius*2
            local pos = {
                x = cc.round(p.x + math.cos(a) * r),
                y = cc.round(p.y + math.sin(a) * r),
            }
            if cc.pGetLength(cc.pSub(pos, cc.p(self.config.mapRadius,self.config.mapRadius))) < self.config.mapRadius - 50 then
                -- local pos = p
                local food = Food:new(pos, perRadis)
                self:addFood(food)
                table_insert(foodData, food:getData())
                foodSectors[food.sector] = true
            end
        end
    end

    local viewSectors = {}
    for k,_ in pairs(foodSectors) do
        for _,v in ipairs(Sector.getSurroundedSector(k, self.config.windowSize-1)) do
            viewSectors[v] = true
        end
    end
    local dst = {}
    for k,v in pairs(viewSectors) do
        table_insert(dst, k)
    end
    local msg = {
        name = "addFood",
        data = foodData,
    }

    local ba = messages.env.new(messages.AddFood)
    ba:setFoodMsg(msg)
    -- snake:sendBinaryMessage(ba)

    self.sectorEvent:processMessage(nil, dst, ba,"binary")
end

function GameRoom:checkSnakeAlive()
    local now = self.elapseTs
    for sid,snake in pairs(self.snakes) do
        if snake and snake.isAlive and snake.lastHeartbeat then
            if now - snake.lastHeartbeat > self.serverTimeout then
                self:removeSnake(sid, -1, true)
                break
            end
        end
    end
end

-- masterId 请求 slaveId的数据
function GameRoom:requestSnakeData(masterId, slaveId)
    cc.printinfo("%s request %s", masterId, slaveId)
    local snake = self.snakes[slaveId]
    if snake and snake.isAlive and masterId ~= slaveId then
        -- add to queue
        local sq = self.addSnakeQueue[slaveId] or {}
        sq[masterId] = true
        self.addSnakeQueue[slaveId] = sq

        -- send to slaveId
        local msg = messages.env.new(messages.CommonRequest)
        msg:setRequest({
            name = "GetSnakeData"
        },masterId)
        snake:sendBinaryMessage(msg)
    end
end

function GameRoom:destroy ()
    -- 从redis里删除room相关的key
    local redis = self.gbcInstance:getRedis()
    if redis then
        local room_key = Constants.ROOM_PREFIX .. self.id
        -- local keys,err = redis:keys(room_key .. "*")
        -- if not err then
        --     -- cc.dump(keys)
        --     redis:initPipeline()
        --     for i,v in ipairs(keys) do
        --         redis:del(v)
        --     end
        --     redis:commitPipeline()
        -- end

        -- 使用redis内置lua脚本快速删除
        local fmt = "return redis.call('del',unpack(redis.call('keys','%s')))"
        local cmdStr = string.format(fmt, room_key .. "*")
        redis:eval(cmdStr, 0)
    end
end

return GameRoom
