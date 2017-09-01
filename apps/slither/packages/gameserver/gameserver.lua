local json   = cc.import("#json")

local _CURRENT_SERVER_EVENT_KEY_ = "_SERVER_EVENT_KEY_1"
local _LAST_SERVER_EVENT_KEY_    = "_SERVER_EVENT_KEY_2"

local _M = cc.class("gameserver")

function _M:ctor (instance)
    self._instance = instance
end

function _M:addClientMessage (event)
    local redis = self._instance:getRedis()
    redis:rpush(_CURRENT_SERVER_EVENT_KEY_, json.encode(event))
end

function _M:swapClientMessage()
    local t = _CURRENT_SERVER_EVENT_KEY_
    _CURRENT_SERVER_EVENT_KEY_ = _LAST_SERVER_EVENT_KEY_
    _LAST_SERVER_EVENT_KEY_ = t
end

function _M:getClientMessage ()
    local redis = self._instance:getRedis()
    local result, err = redis:lpop(_LAST_SERVER_EVENT_KEY_)

    if type(result) == "string" then
        -- cc.printinfo("getClientMessage: %s", result)
        local msg = json.decode(result)
        return msg
    elseif type(result) == "table" then
        -- cc.printinfo("getClientMessage: %s", result)
        local msg = json.decode(result[2])
        return msg
    else
        -- cc.printinfo("getClientMessage: %s", json.encode(result))
    end
end

return _M
