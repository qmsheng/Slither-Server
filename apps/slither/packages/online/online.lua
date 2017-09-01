
local string_format = string.format

local json = cc.import("#json")
local gbc  = cc.import("#gbc")
local Session = cc.import("#session")

local Online = cc.class("Online")

local _ONLINE_SET        = "_ONLINE_USERS"
local _ONLINE_CHANNEL    = "_ONLINE_CHANNEL"
local _EVENT = table.readonly({
    ADD_USER    = "ADD_USER",
    REMOVE_USER = "REMOVE_USER",
})

local _CONNECT_TO_SESSIONID = "_CONNECT_TO_SESSIONID"
local _SESSIONID_TO_CONNECT = "_SESSIONID_TO_CONNECT"
local _SESSIONID_TO_USERID  = "_SESSIONID_TO_USERID"
local _USERID_TO_SESSIONID  = "_USERID_TO_SESSIONID"

function Online:ctor(instance)
    self._instance  = instance
    self._redis     = instance:getRedis()
    self._broadcast = gbc.Broadcast:new(self._redis, instance.config.app.websocketMessageFormat)
end

function Online:getAll()
    return self._redis:smembers(_ONLINE_SET)
end

function Online:add(userid, sessionid, connectId)
    local redis = self._redis
    redis:initPipeline()
    -- map sessionid <-> connect id
    redis:hset(_CONNECT_TO_SESSIONID, connectId, sessionid)
    redis:hset(_SESSIONID_TO_CONNECT, sessionid, connectId)
    redis:hset(_SESSIONID_TO_USERID,  sessionid, userid)
    redis:hset(_USERID_TO_SESSIONID,  userid,    sessionid)
    -- add sessionid to set
    redis:sadd(_ONLINE_SET, sessionid)
    -- send event to all clients
    -- redis:publish(_ONLINE_CHANNEL, json.encode({name = _EVENT.ADD_USER, sessionid = sessionid}))
    return redis:commitPipeline()
end

function Online:remove(sessionid)
    local redis = self._redis
    local userid, err = redis:hget(_SESSIONID_TO_USERID, sessionid)
    local connectId, err = redis:hget(_SESSIONID_TO_CONNECT, sessionid)
    if not connectId then
        return nil, err
    end
    if connectId == redis.null then
        return nil, string_format("not found sessionid '%s'", sessionid)
    end

    redis:initPipeline()
    -- remove map
    redis:hdel(_CONNECT_TO_SESSIONID, connectId)
    redis:hdel(_SESSIONID_TO_CONNECT, sessionid)
    redis:hdel(_SESSIONID_TO_USERID, sessionid)
    redis:hdel(_USERID_TO_SESSIONID, userid)
    -- remove sessionid from set
    redis:srem(_ONLINE_SET, sessionid)
    -- redis:publish(_ONLINE_CHANNEL, json.encode({name = _EVENT.REMOVE_USER, sessionid = sessionid}))
    local res, err = redis:commitPipeline()
    if not res then
        return nil, err
    end

    return self._broadcast:sendControlMessage(connectId, gbc.Constants.CLOSE_CONNECT)
end

function Online:getChannel()
    return _ONLINE_CHANNEL
end

function Online:getAllUsers()
    local redis = self._redis
    local users,err = redis:smembers(_ONLINE_SET)
    return users,err
end

function Online:connectId2SessionId(connectId)
    local redis = self._redis
    local sessionid, err = redis:hget(_CONNECT_TO_SESSIONID, connectId)
    if not sessionid then
        return nil, err
    end
    if sessionid == redis.null then
        return nil, string_format("not found connectId '%s'", connectId)
    end
    return sessionid
end

function Online:sendMessage(sessionid, event)
    local redis = self._redis
    -- query connect id by sessionid
    local connectId, err = redis:hget(_SESSIONID_TO_CONNECT, sessionid)
    if not connectId then
        return nil, err
    end

    if connectId == redis.null then
        return nil, string_format("not found sessionid '%s'", sessionid)
    end

    -- send message to connect id
    return self._broadcast:sendMessage(connectId, event)
end

function Online:sendMessageToAll(event)
    return self._broadcast:sendMessageToAll(event)
end

-- id类型有 session, user, connect
function Online:openSession(id,_type)
    local redis = self._redis
    local sid = id
    -- _type = _type or "session"
    if _type == "user" then
        sid = redis:hget(_USERID_TO_SESSIONID, id)
    end
    if _type == "connect" then
        sid = redis:hget(_CONNECT_TO_SESSIONID, id)
    end

    if not sid then
        cc.throw("not set argsument: \"sid\"")
        return nil
    end

    local session = Session:new(redis)
    if not session:start(sid) then
        cc.throw("session is expired, or invalid session id")
        return nil
    end

    return session
end

return Online
