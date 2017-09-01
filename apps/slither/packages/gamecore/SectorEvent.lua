
local helper     = cc.import(".helper")
local Sector     = cc.import(".Sector")
local messages   = cc.import("#messages")
local ByteArray  = messages.env.ByteArray
local SectorEvent = cc.class("SectorEvent")

function SectorEvent:ctor(room)
    self.room = room
end

function SectorEvent:getSnakesInSector(sectorid)
    local sector = self.room.sectors[sectorid]
    if sector then
        return sector.snakes
    end
    return nil
end

-- 处理一个普通消息, 发给指定的snake
function SectorEvent:addSnakeMessage(snake, msg)

end

function SectorEvent:snakeEnter(snakeid, sectorid)
    local snake  = self.room.snakes[snakeid]
    local sector = self.room.sectors[sectorid]
    -- addSnake
    -- print(snakeid .. "  snakeEnter " .. sectorid)
    -- cc.dump(sector.snakes)

    -- for i,sid in ipairs(sector.snakes) do
    --     if sid ~= snake.id then
    --         local msg = {
    --             name    = "addSnake",
    --             snake   = self.room.snakes[sid]:getData(),
    --             ts      = self.room.elapseTs,
    --         }
    --         snake:sendMessage(msg)
    --         dump(sid)
    --     end
    -- end
    -- -- 向所有能看得见自身所在sector的snake发送自己
    -- local sectors = Sector.getSurroundedSector(sectorid, GameConfig.windowSize-1)
    -- local sectors = {sectorid}
    -- for i,v in ipairs(sectors) do
    --     local sector = self.room.sectors[v]
    --     for i,id in ipairs(sector.snakes) do
    --         local s = self.room.snakes[id]
    --         if snakeid ~= s.id then
    --             local msg = {
    --                 name    = "addSnake",
    --                 snake   = snake:getData(),
    --                 ts      = self.room.elapseTs,
    --             }
    --             s:sendMessage(msg)
    --             dump(id)
    --         end
    --     end
    -- end

    -- addFood
    local foodData, flag = {}, 0
    for i,fid in pairs(sector.foods) do
        table.insert(foodData, self.room.foods[fid]:getData())
        flag = flag + 1

        if flag == 100 then
            local msg = {
                name = "addFood",
                data = foodData,
            }

            local ba = messages.env.new(messages.AddFood)
            ba:setFoodMsg(msg)
            snake:sendBinaryMessage(ba)
            -- snake:sendMessage(msg)
            foodData = {}
            flag = 0
        end
    end
    if #foodData > 0 then
        local msg = {
            name = "addFood",
            data = foodData,
        }
        -- snake:sendMessage(msg)
        local ba = messages.env.new(messages.AddFood)
        ba:setFoodMsg(msg)
        snake:sendBinaryMessage(ba)
    end

end

function SectorEvent:snakeLeave(snakeid, sectorid)
    local snake  = self.room.snakes[snakeid]
    local sector = self.room.sectors[sectorid]
    -- removeSnake

    -- print(snakeid .. "  snakeLeave " .. sectorid)

    -- for i,sid in ipairs(sector.snakes) do
    --     if sid ~= snake.id then
    --         local viewSectors = snake.viewSectors
    --         local flag = true
    --         for k,v in pairs(viewSectors) do
    --             local sec = self.room.sectors[k]
    --             if sec:hasSnake(sid) then
    --                 flag = false
    --             end
    --         end
    --         if flag then
    --             local msg = {
    --                 name = "removeSnake",
    --                 id   = sid,
    --                 ts   = self.room.elapseTs,
    --             }
    --             snake:sendMessage(msg)
    --         end
    --     end
    -- end
    --
    -- -- 向所有能看得见自身所在sector的snake发送自己
    -- local sectors = Sector.getSurroundedSector(sectorid, GameConfig.windowSize-1)
    -- local sectors = {sectorid}
    -- for i,v in ipairs(sectors) do
    --     local sector = self.room.sectors[v]
    --     for i,id in ipairs(sector.snakes) do
    --         local s = self.room.snakes[id]
    --         if snakeid ~= s.id then
    --             local msg = {
    --                 name = "removeSnake",
    --                 id   = snakeid,
    --                 ts   = self.room.elapseTs,
    --             }
    --             s:sendMessage(msg)
    --         end
    --     end
    -- end

    -- removeFood
    local foodData, flag = {}, 0
    for i,fid in pairs(sector.foods) do
        table.insert(foodData, fid)
        flag = flag + 1

        if flag == 100 then
            local msg = {
                name = "removeFood",
                data = foodData,
            }

            local ba = messages.env.new(messages.RemoveFood)
            ba:removeFood(msg)
            snake:sendBinaryMessage(ba)

            foodData = {}
            flag = 0
        end
    end
    if #foodData > 0 then
        local msg = {
            name = "removeFood",
            data = foodData,
        }
        local ba = messages.env.new(messages.RemoveFood)
        ba:removeFood(msg)
        snake:sendBinaryMessage(ba)
    end

end

-- 处理一个广播消息, 发生sector, 目标sector数组, 消息msg
function SectorEvent:processMessage(src, dst, msg , type)
    local snakes = {}
    for _,v in ipairs(dst) do
        local sector = self.room.sectors[v]
        for i,sid in ipairs(sector.snakes) do
            snakes[sid] = true
        end
    end
    for sid,v in pairs(snakes) do
        local snake = self.room.snakes[sid]
        if type == "binary" then
            if snake then snake:sendBinaryMessage(msg) end
        else
            if snake then snake:sendMessage(msg) end
        end
        -- if snake then snake:sendMessage(msg) end
    end
end

function SectorEvent:addFoodBySpeedUp(food)
    self.room:addFood(food)
    local foodSector = food.sector
    local sectors = Sector.getSurroundedSector(foodSector, GameConfig.windowSize-1)
    local foodData = {food:getData()}

    local msg = {
        name = "addFood",
        data = foodData,
    }

    local ba = messages.env.new(messages.AddFood)
    ba:setFoodMsg(msg)

    self:processMessage(nil,sectors,ba,"binary")
end

return SectorEvent
