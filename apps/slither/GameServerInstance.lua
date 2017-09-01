
local io_flush      = io.flush
local os_date       = os.date
local os_time       = os.time
local string_format = string.format
local string_lower  = string.lower
local tostring      = tostring
local type          = type

local Online    = cc.import("#online")
local Session   = cc.import("#session")
local json      = cc.import("#json")
local gbc       = cc.import("#gbc")
local ev        = require("ev")
local scoket    = require("socket")
local Constants = gbc.Constants
local InstanceBase = gbc.InstanceBase

local gamecore          = cc.import("#gamecore")
local WebsocketServer   = cc.import("#corebackend").Websocket
local UDPServer         = cc.import("#corebackend").UDP
local NginxWebsocket    = cc.import("#corebackend").NginxWebsocket

local ServerInstance = cc.class("ServerInstance", InstanceBase)

function ServerInstance:ctor(config, args, tag)
    socket.sleep(2)
    ServerInstance.super.ctor(self, config, Constants.WORKER_REQUEST_TYPE)
    self._tag = tag or "Server"
    local gameConfig = config.server.gamecore
    local socketInstance
    if gameConfig.type == "udp" then
        socketInstance = UDPServer:new("127.0.0.1", gameConfig.port, self)
    else
        socketInstance = NginxWebsocket:new("127.0.0.1", gameConfig.port, gameConfig.protocol, self)
    end

    local game = gamecore:new(socketInstance, self)
    socketInstance:setEventCallback(function(event)
        game:onClientEvent(event)
    end)
    socketInstance:listen()

    self.gamecore = game
end

-- local updateInterval = 1.0/100
function ServerInstance:run()
    -- local lastUpdateTime = socket.gettime()
    -- local timer = ev.Timer.new(function()
    --     local timeNow = socket.gettime()
    --     local dt = timeNow - lastUpdateTime
    --     self.gamecore:update(dt)
    --     lastUpdateTime = timeNow
    --     io_flush()
    -- end,updateInterval,updateInterval)
    -- timer:start(ev.Loop.default)

    return ev.Loop.default:loop()
end

return ServerInstance
