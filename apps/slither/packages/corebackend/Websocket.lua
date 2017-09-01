
local json      = cc.import("cjson.safe")
local ev        = require('ev')
local websocket = require('websocket')

local ServerBase        = cc.import(".ServerBase")
local WebsocketServer   = cc.class("WebsocketServer", ServerBase)

local evloop = ev.Loop.default

function WebsocketServer:ctor(ip, port, protocol, _gbcInstance)
    WebsocketServer.super.ctor(self, ip, port, _gbcInstance)
    self.protocol = protocol
end

function WebsocketServer:_websocket_handler(ws)
    local clientId = self:addClient(ws)

    local event = {
        name = "open",
        clientId = clientId,
        sessionid= "Session_" .. clientId,
        userId   = "User_" .. clientId,
    }
    self.eventCallBack(event)

    ws:on_message(function(ws,message)
        local event = {
            name = "message",
            clientId = ws.clientId,
            data = self:tryDecrypt(message)
        }
        self.eventCallBack(event)
    end)

    ws:on_close(function()
        self:removeClient(ws.clientId)
        local event = {
            name = "close",
            clientId = ws.clientId
        }
        self.eventCallBack(event)
    end)

    ws:on_error(function(ws, err)
        cc.printinfo("err, %s, %s", ws.clientId, err)
    end)
end

function WebsocketServer:send(clientId, msg, msg_type)
    local ws = self.clients[clientId]
    if msg_type == "binary" then
        msg_type = websocket.BINARY
    else
        msg_type = websocket.TEXT
    end
    if ws then
        ws:send(self:tryEncrypt(msg),msg_type)
    end
end

function WebsocketServer:broadcast(msg)
    for k,ws in pairs(self.clients) do
        ws:send(msg)
    end
end

function WebsocketServer:listen()
    self.server = websocket.server.ev.listen({
        port = self.port,
        protocols = {
            [self.protocol] = function(ws) self:_websocket_handler(ws) end
        }
    })
end

return WebsocketServer
