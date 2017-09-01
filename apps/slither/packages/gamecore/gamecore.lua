
local helper     = cc.import(".helper")
local cc         = cc.import(".ccmath")
local json       = cc.import("cjson.safe")
local socket     = cc.import("socket")
local messages   = cc.import("#messages")
local ByteArray  = messages.env.ByteArray
local GameRoom   = cc.import(".GameRoom")

local gbc        = cc.import("#gbc")
local Constants  = gbc.Constants
local Session    = cc.import("#session")
local Online     = cc.import("#online")
local evloop     = ev.Loop.default

local table_insert = table.insert

local gamecore   = cc.class("gamecore")
function gamecore:ctor (socketInstance, gbcInstance)
    self.socketInstance  = socketInstance
    self.gbcInstance     = gbcInstance
    helper.init(socketInstance, gbcInstance)
    self.online = Online:new(gbcInstance)
    self.redis  = gbcInstance:getRedis()

    -- GameConfig设置为全局变量
    cc.exports.GameConfig = gbcInstance.config.server.GameConfig

    self.gameRooms = {}
    self.sessionToRoom   = {}
    self.clientToRoom    = {}
    self.clientToSession = {}

    self:initGame()
    io.flush()
end

function gamecore:initGame ()
    local checkTimer = ev.Timer.new(function()
        self:checkRooms()
    end, 10.0, 10.0)
    checkTimer:start(evloop)
    self.checkTimer = checkTimer
    -- table.insert(self.timers, checkTimer)
    cc.printinfo("Game init.")
end

function gamecore:update (dt)
    -- table.walk(self.gameRooms, function(room)
    --     room:update(dt)
    -- end)
end

function gamecore:onClientEvent(event)
    local e_name = event.name
    local message = {}
    if e_name == "connected" then
        message.name = "connected"
        message.clientId  = event.clientId
        message.sessionid = event.sessionid
        message.userId    = event.userId
        cc.printinfo("connected: %s", message.clientId)
        local roomId = self.sessionToRoom[message.sessionid]
        if not roomId then
            roomId = self:getAvailableRoom().id
            self.sessionToRoom[message.sessionid] = roomId
            self.clientToRoom[message.clientId]   = roomId
            self.clientToSession[message.clientId]= message.sessionid
        else

        end
    elseif e_name == "disconnected" then
        message.name = "disconnected"
        message.clientId  = event.clientId
        message.sessionid = event.sessionid
        -- self.sessionToRoom[message.sessionid] = nil
        -- self.clientToRoom[message.clientId]   = nil
        -- self.clientToSession[message.clientId]= nil
    elseif e_name == "message" then
        message = messages.parse(event.data)
        message.clientId = event.clientId
    end

    local roomId = self.clientToRoom[message.clientId]
    if roomId and self.gameRooms[roomId] then
        self.gameRooms[roomId]:pushClientMessage(message)
    end

    -- clean
    if e_name == "disconnected" then
        self.sessionToRoom[message.sessionid] = nil
        self.clientToRoom[message.clientId]   = nil
        self.clientToSession[message.clientId]= nil
    end
end

function gamecore:getAvailableRoom()
    local room = nil
    table.walk(self.gameRooms, function(r)
        room = room or r
        if room.snakeCount > r.snakeCount then
            room = r
        end
    end)

    if not room or room.snakeCount >= GameConfig.roomMaxUser then
        room = self:addRoom()
    end

    return room
end

function gamecore:addRoom()
    local room = GameRoom:new(self.gbcInstance)
    self.gameRooms[room.id] = room
    cc.printinfo("addRoom: %s", room.id)
    return room
end

function gamecore:removeRoom(roomId)
    local room = self.gameRooms[roomId]
    if room then
        cc.printinfo("removeRoom: %s", roomId)
        room:stopAllTimer()
        room:destroy()
        self.gameRooms[roomId] = nil
    end
    io.flush()
end

function gamecore:checkRooms()
    table.walk(self.gameRooms, function(room)
        -- cc.printinfo("%s count: %s",room.id, room.snakeCount)
        if room.snakeCount ==  0 then
            room.__checkTimes = room.__checkTimes or 0
            room.__checkTimes = room.__checkTimes + 1
            if room.__checkTimes >= 3 then
                self:removeRoom(room.id)
            end
            return
        else
            room.__checkTimes = 0
        end
    end)

    -- 更新rooms状态数据
    local _key = Constants.STATUS_ROOMS
    local result = json.decode(self.redis:get(_key) or "{}")
    table.walk(self.gameRooms, function(room)
        result[room.id] = {
            snakeCount = room.snakeCount,
        }
    end)

    self.redis:set(_key, json.encode(result))
end

return gamecore
