
local json      = require("cjson.safe")
local ev 		= require("ev")
local socket 	= require("socket")
local xxtea     = require("xxtea");

local Session    = cc.import("#session")
local Online     = cc.import("#online")

local messages   = cc.import("#messages")
local ServerBase = cc.import(".ServerBase")
local UDPServer = cc.class("UDPServer", ServerBase)

local evloop = ev.Loop.default
function UDPServer:ctor(ip, port, _gbcInstance)
    UDPServer.super.ctor(self, ip, port, _gbcInstance)
    self.messageBuffer = {}
    self.clientsIpMap  = {}
    -- self.online = Online:new(_gbcInstance)

    local config = _gbcInstance.config
    local gameConfig = config.server.gamecore
    self.decryptKey = gameConfig.decryptKey
    self.timeout    = gameConfig.timeout
end

local function ipPortKey(ip, port)
    return ip .. ":" .. port
end

function UDPServer:shouldAcceptClient(sessionid)
    if self.gbcInstance then
        local session = Session:new(self.gbcInstance:getRedis())
        if not session:start(sessionid) then
            -- cc.printinfo("session is expired, or invalid session id")
            return false
        else
            return true
        end
    end
    return false
end

function UDPServer:tryDecrypt(data)
    local result, ret = pcall(function(stream)
        local key = self.decryptKey
        local decrypt_data = xxtea.decrypt(stream, key);
        return decrypt_data
    end, data)
    if result then
        return ret
    end
    return nil
end

function UDPServer:tryEncrypt(data)
    local key = self.decryptKey
    local encrypt_data = xxtea.encrypt(data, key);
    return encrypt_data
end

function UDPServer:_data_handler(data, ip, port)
    data = self:tryDecrypt(data)
    if not data then return end

    local key = ipPortKey(ip, port)
    local clientId = self.clientsIpMap[key]
    if not clientId then
        -- EnterGame Msg
        local ba  = messages.env.new(messages.CommonResult)
        local msg = messages.parse(data)
        local isok = false
        if msg and msg.name == "e" and msg.sessionid then
            local sessionid = msg.sessionid
            if self:shouldAcceptClient(sessionid) then
                local client_var = {
                    ip   = ip,
                    port = port,
                    sessionid = sessionid,
                    userId    = msg.userId,
                }
                local clientId = self:addClient(client_var)
                self.clientsIpMap[key] = clientId
                self.clients[clientId].lastHeartbeat = socket.gettime()

                local event = {
                    name     = "open",
                    clientId = clientId,
                    sessionid= sessionid,
                    userId   = msg.userId,
                }
                self.eventCallBack(event)
                -- self.online:add(sessionid, clientId)
                isok = true
            end
        end
        if isok then
            ba:setResult(0,"OK")
        else
            ba:setResult(-1,"Error")
        end
        self.sock:sendto(self:tryEncrypt(ba:getRawStream(), self.decryptKey), ip, port)
    else
        if self.clients[clientId] then
            local event = {
                name     = "message",
                clientId = clientId,
                data     = data
            }
            self.eventCallBack(event)
            self.clients[clientId].lastHeartbeat = socket.gettime()
        end
    end
end

function UDPServer:_checkClientAlive()
    local now = socket.gettime()
    local removed = {}
    for id,var in pairs(self.clients) do
        if now - var.lastHeartbeat > self.timeout then
            table.insert(removed, id)
        end
    end
    for i,id in ipairs(removed) do
        self:removeClient(id)
    end
end

function UDPServer:send(clientId, msg, msg_type)
    table.insert(self.messageBuffer, {
        clientId = clientId,
        msg      = msg
    })
end

function UDPServer:removeClient(clientId)
    local client_var = self.clients[clientId]
    if client_var then
        UDPServer.super.removeClient(self, clientId)
        local event = {
            name     = "close",
            clientId = clientId,
            sessionid= client_var.sessionid
        }
        self.eventCallBack(event)
        -- self.online:remove(client_var.sessionid)
    end
end

function UDPServer:broadcast(msg)
    -- for k,ws in pairs(self.clients) do
    --     ws:send(msg)
    -- end
end

function UDPServer:processBuffer()
    if #self.messageBuffer > 0 then
        for i,v in ipairs(self.messageBuffer) do
            local clientId = v.clientId
            if self.clients[clientId] then
                local ip   = self.clients[v.clientId].ip
                local port = self.clients[v.clientId].port
                self.sock:sendto(self:tryEncrypt(v.msg, self.decryptKey), ip, port)
            end
        end
        self.messageBuffer = {}
    end
end

function UDPServer:listen()
    local udp_sock = socket.udp()
    local result, err = udp_sock:setsockname("*", self.port)
    if not err then
        udp_sock:settimeout(0)
        self.sock = udp_sock

        local udp_receive_io = ev.IO.new(function(io,loop)
            local data, ip, port = udp_sock:receivefrom()
            if data then
                self:_data_handler(data, ip, port)
            end
        end,udp_sock:getfd(),ev.READ)

        -- local udp_send_io = ev.IO.new(function(io,loop)
        --     if #self.messageBuffer > 0 then
        --         for i,v in ipairs(self.messageBuffer) do
        --             local ip   = self.clients[v.clientId].ip
        --             local port = self.clients[v.clientId].ip
        --             print(v.msg)
        --             udp_sock:sendto(v.msg, ip, port)
        --         end
        --         self.messageBuffer = {}
        --     end
        -- end,udp_sock:getfd(),ev.WRITE)

        udp_receive_io:start(evloop)
        -- udp_send_io:start(evloop)

        local timer = ev.Timer.new(function()
            self:processBuffer()
        end,1/200,1/200)
        timer:start(evloop)

        local checkTimer = ev.Timer.new(function()
            self:_checkClientAlive()
        end,1.0,1.0)
        checkTimer:start(evloop)
    else
        cc.throw("%s", err)
        return err
    end
end

return UDPServer
