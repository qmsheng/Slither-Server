
local json      = cc.import("cjson.safe")
local ev        = require('ev')
local gbc       = cc.import("#gbc")
local Constants = gbc.Constants
local messages  = cc.import("#messages")
local ServerBase             = cc.import(".ServerBase")
local NginxWebsocketServer   = cc.class("NginxWebsocketServer", ServerBase)

local evloop = ev.Loop.default

function NginxWebsocketServer:ctor(ip, port, protocol, _gbcInstance)
    NginxWebsocketServer.super.ctor(self, ip, port, _gbcInstance)
    self.protocol = protocol
    self.redis    = _gbcInstance:getRedis()
    self.redis_sub= _gbcInstance:getSubRedis()
end

function NginxWebsocketServer:send(clientId, msg, msg_type)
    local connectChannel = Constants.CONNECT_CHANNEL_PREFIX .. clientId
    local ok, err = self.redis_sub:publish(connectChannel, self:tryEncrypt(msg))
end

function NginxWebsocketServer:broadcast(msg)
    -- for k,ws in pairs(self.clients) do
    --     ws:send(msg)
    -- end
end

function NginxWebsocketServer:processBuffer()
    local maxCount = 1000
    local count = 0
    while count < maxCount do
        local result, err = self.redis:lpop(Constants.WEBSOCKET_MESSAGE_QUEUE_KEY)
        if result then
            local ba = messages.env.newByteArray()
            ba:writeBuf(result)
            ba:setPos(1)
            local msgType  = ba:readByte()
            local clientId = ba:readUInt()
            local data     = ba:readStringUInt()
            if msgType == 0 then
                local event = {
                    name     = "message",
                    clientId = clientId,
                    data     = data
                }
                self.eventCallBack(event)
            elseif msgType == 1 then
                local msg = json.decode(data)
                if msg.name == "connected" then
                    self:addClient({
                        sessionid= msg.sessionid,
                        clientId = clientId,
                    })

                    local event = {
                        name = "connected",
                        clientId = clientId,
                        sessionid= msg.sessionid,
                        username = msg.username,
                        userId   = "User_" .. clientId,
                    }
                    self.eventCallBack(event)
                elseif msg.name == "disconnected" then
                    self:removeClient(clientId)
                    local event = {
                        name     = "disconnected",
                        clientId = clientId,
                        sessionid= msg.sessionid,
                    }
                    self.eventCallBack(event)
                end
            end
        else
            break
        end
    end
end

function NginxWebsocketServer:listen()
    local timer = ev.Timer.new(function()
        self:processBuffer()
    end,1/100,1/100)
    timer:start(evloop)
end

return NginxWebsocketServer
