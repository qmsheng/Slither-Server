
local Online    = cc.import("#online")
local Session   = cc.import("#session")
local json      = cc.import("#json")

local gbc       = cc.import("#gbc")
local Constants = gbc.Constants

local InfoAction = cc.class("InfoAction", gbc.ActionBase)

InfoAction.ACCEPTED_REQUEST_TYPE = "worker"

local online = nil
local function getOnline(instance)
    if not online then
        online = Online:new(instance)
    end
    return online
end

function InfoAction:addAction(job)
    local clientId  = job.data.clientId
    local userId    = job.data.userId
    local sessionid = getOnline(self:getInstance()):connectId2SessionId(clientId)
    local pos       = job.data.pos
    local len       = job.data.len

    local session = Session:new(self:getInstance():getRedis())
    if sessionid then
        session:start(sessionid)
        session:set("clientId", clientId)
        session:set("userId",   userId)
        session:set("pos", pos)
        session:set("len", len)
        session:set("kill", 0)
        session:save()
    end
end

function InfoAction:killAction(job)
    local redis = self:getInstance():getRedis()
    local clientId  = job.data.clientId
    local deadId    = job.data.deadId
    local sessionid = getOnline(self:getInstance()):connectId2SessionId(clientId)

    local session = Session:new(redis)
    if sessionid then
        session:start(sessionid)
        local kill = tonumber(session:get("kill")) + 1
        session:set("kill", kill)
        session:save()
    end

    -- deadId
    local sessionid = getOnline(self:getInstance()):connectId2SessionId(deadId)
    local session = Session:new(redis)
    if sessionid then
        session:start(sessionid)
        session:set("isDead", true)
        session:save()
        -- redis:zrem(_LEADERBOARD_KEY_, deadId)
    end
end

function InfoAction:posAction(job)
    local clientId  = job.data.clientId
    local sessionid = getOnline(self:getInstance()):connectId2SessionId(clientId)
    local pos       = job.data.pos

    local session = Session:new(self:getInstance():getRedis())
    if sessionid then
        session:start(sessionid)
        session:set("pos", pos)
        session:save()
    end
end

function InfoAction:lenAction(job)
    local clientId  = job.data.clientId
    local sessionid = getOnline(self:getInstance()):connectId2SessionId(clientId)
    local len       = job.data.len

    local session = Session:new(self:getInstance():getRedis())
    if sessionid then
        session:start(sessionid)
        session:set("len", len)
        session:save()
    end

    -- len = tonumber(len)
    -- local redis = self:getInstance():getRedis()
    -- if redis then
    --     redis:zadd(_LEADERBOARD_KEY_, len, clientId)
    -- end
end

function InfoAction:removeAction(job)
    -- local clientId  = job.data.clientId
    --
    -- local redis = self:getInstance():getRedis()
    -- if redis then
    --     redis:zrem(_LEADERBOARD_KEY_, clientId)
    -- end
end

function InfoAction:leaderAction(job)
    local roomId = job.data.roomId
    local leader = job.data.leadboard
    local minimap= job.data.minimap

    local leader_key = Constants.ROOM_PREFIX .. roomId .. Constants.ROOM_LEADERBOARD
    local minmap_key = Constants.ROOM_PREFIX .. roomId .. Constants.ROOM_MINMAP
    local redis = self:getInstance():getRedis()
    if redis then
        redis:initPipeline()
        redis:set(leader_key, json.encode(leader))
        redis:set(minmap_key, json.encode(minimap))
        redis:commitPipeline()
    end
end

return InfoAction
