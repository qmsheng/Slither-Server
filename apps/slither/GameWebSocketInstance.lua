
-- local Online    = cc.import("#online")
local Session   = cc.import("#session")
local gbc       = cc.import("#gbc")
local json      = cc.import("cjson.safe")
local Constants = gbc.Constants
local ByteArray = cc.import("framework.utils.ByteArray")
local xxtea     = require("xxtea");

local WebSocketInstance = cc.class("WebSocketInstance", gbc.WebSocketInstanceBaseBinary)

function WebSocketInstance:ctor(config)
    WebSocketInstance.super.ctor(self, config)
    self.redis = self:getRedis()
    local gameConfig = config.server.gamecore
    self.decryptKey  = gameConfig.decryptKey
    self.timeout     = gameConfig.timeout

    -- ngx.say(WebSocketInstance.EVENT.CONNECTED or "66666")
    -- ngx.say(WebSocketInstance.EVENT.DISCONNECTED or "55555")
    -- ngx.say(WebSocketInstance.EVENT.BINARY_MSG or "44444")
    -- CONNECTED
    -- DISCONNECTED
    -- BINARY_MSG

    self._event:bind(WebSocketInstance.EVENT.CONNECTED,     cc.handler(self, self.onConnected))
    self._event:bind(WebSocketInstance.EVENT.DISCONNECTED,  cc.handler(self, self.onDisconnected))
    self._event:bind(WebSocketInstance.EVENT.BINARY_MSG,    cc.handler(self, self.onBinaryMessage))
end

function WebSocketInstance:tryDecrypt(data)
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

function WebSocketInstance:tryEncrypt(data)
    local key = self.decryptKey
    local encrypt_data = xxtea.encrypt(data, key);
    return encrypt_data
end

function WebSocketInstance:onConnected()
    local redis = self:getRedis()

    -- load session
    local sid = self:getConnectToken() -- token is session id
    local session = Session:new(redis)
    session:start(sid)

    -- add user to online users list
    -- local online = Online:new(self)
    local username = session:get("username")
    -- online:add(sid, self:getConnectId())

    -- send all usernames to current client
    -- local users = online:getAll()
    -- online:sendMessage(sid, {name = "LIST_ALL_USERS", users = users})
    local clientMsg = {
        name = "connected",
        sessionid = sid,
        username  = username,
    }
    self:pushMsgToRedis(json.encode(clientMsg), 1)

    -- subscribe online users event
    -- self:subscribe(online:getChannel())

    self._username = username
    self._session  = session
    -- self._online   = online
end

function WebSocketInstance:onDisconnected(event)
    if event.reason ~= gbc.Constants.CLOSE_CONNECT then
        -- connection interrupted unexpectedly, remove user from online list
        cc.printwarn("[websocket:%s] connection interrupted unexpectedly", self:getConnectId())
    end

    local sid = self:getConnectToken() -- token is session id
    -- self._online:remove(sid)

    local clientMsg = {
        name = "disconnected",
        sessionid = sid
    }
    self:pushMsgToRedis(json.encode(clientMsg), 1)
end

function WebSocketInstance:onBinaryMessage(event)
    local data = self:tryDecrypt(event.data)
    if data then
        self:pushMsgToRedis(data, 0)
    end
end

-- msgType, 0 binary, 1 json string
function WebSocketInstance:pushMsgToRedis(data, msgType)
    local connectId = tonumber(self:getConnectId())
    local ba = ByteArray:new()
    ba:writeByte(msgType)
    ba:writeUInt(connectId)
    ba:writeStringUInt(data)
    self.redis:rpush(Constants.WEBSOCKET_MESSAGE_QUEUE_KEY,    ba:getBytes())
end

function WebSocketInstance:heartbeat()
    -- refresh session
    self._session:setKeepAlive()
end

function WebSocketInstance:getUsername()
    return self._username
end

function WebSocketInstance:getSession()
    return self._session
end

function WebSocketInstance:getOnline()
    return self._online
end

return WebSocketInstance
