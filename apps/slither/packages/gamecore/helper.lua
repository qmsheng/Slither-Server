
local json       = cc.import("cjson.safe")
local Session    = cc.import("#session")
local Online     = cc.import("#online")

local _M = {
    socketInstance = nil,
    gbcInstance    = nil,
}

local redis = nil
local jobs  = nil

function _M.init(socket, gbc)
    _M.socketInstance = socket
    _M.gbcInstance    = gbc
    redis = gbc:getRedis()
    jobs  = gbc:getJobs()
end

function _M.sendMessage (cid, msg, binary)
    local buffer = (binary==true) and msg or json.encode(msg)
    _M.socketInstance:send(cid, buffer, binary and "binary" or nil)
end

function _M.sendMessageToAll (msg)
    local buffer = json.encode(msg)
    _M.socketInstance:broadcast(buffer)
end

function _M.addClient(clientId, userId, pos, len)
    local job = {
       action = "/jobs/info.add",
       delay  = 0,
       data   = {
           clientId = clientId,
           userId   = userId,
           pos      = pos,
           len      = len,
       }
    }
    local ok, err = jobs:add(job)
end

function _M.updateSnakePos(clientId, pos)
    -- local job = {
    --     action = "/jobs/info.pos",
    --     delay  = 0,
    --     data   = {
    --         clientId = clientId,
    --         pos      = pos,
    --     }
    -- }
    -- local ok, err = jobs:add(job)
end

function _M.recordSnakeKill(clientId, deadId)
    local job = {
        action = "/jobs/info.kill",
        delay  = 0,
        data   = {
            clientId = clientId,
            deadId   = deadId,
        }
    }
    local ok, err = jobs:add(job)
end

function _M.updateSnakeLen(clientId, len)
    -- local job = {
    --     action = "/jobs/info.len",
    --     delay  = 0,
    --     data   = {
    --         clientId = clientId,
    --         len      = len,
    --     }
    -- }
    -- local ok, err = jobs:add(job)
end

function _M.removeClient(clientId)
    _M.socketInstance:removeClient(clientId)
    local job = {
        action = "/jobs/info.remove",
        delay  = 0,
        data   = {
            clientId = clientId,
        }
    }
    local ok, err = jobs:add(job)
end

function _M.updateTop10AndMinimapForRoom(roomId, leadboard, minimap)
    local job = {
        action = "/jobs/info.leader",
        delay  = 0,
        data   = {
            roomId      = roomId,
            leadboard   = leadboard,
            minimap     = minimap,
        }
    }
    local ok, err = jobs:add(job)
end

return _M
