
local ServerBase = cc.class("ServerBase")

function ServerBase:ctor(ip, port, _gbcInstance)
    self.ip     = ip
    self.port   = port
    self.gbcInstance = _gbcInstance
    self.clients= {}
    self.eventCallBack = function() end

    local gameConfig = _gbcInstance.config.server.gamecore
    self.decryptKey  = gameConfig.decryptKey
    self.timeout     = gameConfig.timeout
end

function ServerBase:tryDecrypt(data)
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

function ServerBase:tryEncrypt(data)
    local key = self.decryptKey
    local encrypt_data = xxtea.encrypt(data, key);
    return encrypt_data
end

local _c_id = 0
function ServerBase:generateClientID()
    _c_id = _c_id + 1
    return _c_id
end

function ServerBase:shouldAcceptClient()
    return true
end

function ServerBase:addClient(client_var, _clientId)
    local clientId = _clientId or self:generateClientID()
    self.clients[clientId] = client_var
    client_var.clientId = clientId
    return clientId
end

function ServerBase:removeClient(clientId)
    local client_var = self.clients[clientId]
    self.clients[clientId] = nil
    return client_var
end

function ServerBase:setEventCallback(_callback)
    self.eventCallBack = _callback
end

function ServerBase:listen()
end

function ServerBase:send(clientId, msg, msg_type)
end

function ServerBase:broadcast(msg)
end

function ServerBase:close(clientId)
end

return ServerBase
