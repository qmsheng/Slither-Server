
local Online    = cc.import("#online")
local Session   = cc.import("#session")
local json      = cc.import("#json")

local gbc       = cc.import("#gbc")
local Constants = gbc.Constants

local SnakeAction = cc.class("SnakeAction", gbc.ActionBase)

local _LEADERBOARD_KEY_ = "_SLITHER_LEADER_"
local _MINIMAP_KEY_     = "_SLITHER_MINIMAP_"

local _opensession

--  每秒更新2次
local _cacheLeader = nil
local _leaderLastUpdate = ngx.now()
function SnakeAction:leaderAction(args)
    local ret = {}
    if _cacheLeader == nil or ngx.now() - _leaderLastUpdate > 0.5 then
        local redis = self:getInstance():getRedis()
        _leaderLastUpdate = ngx.now()

        local leader = {}
        local leads = json.decode(redis:get(_LEADERBOARD_KEY_))
        for i,v in ipairs(leads) do
            table.insert(leader,{
                username = v.nick,
                len      = math.floor(v.len),
            })
        end
        _cacheLeader = leader
    end
    ret.leader = _cacheLeader

    local len = args.len
    local rank = 100

    ret.user = rank+1
    return ret
end

local mapLastUpdate = ngx.now()
local minimap = nil
function SnakeAction:minimapAction(args)
    if minimap == nil or ngx.now() - mapLastUpdate > 0.5 then
        mapLastUpdate = ngx.now()
        local redis = self:getInstance():getRedis()
        local ret = {}
        local snakes = json.decode(redis:get(_MINIMAP_KEY_))
        for i,v in ipairs(snakes) do
            table.insert(ret, v.id)
            table.insert(ret, v.x)
            table.insert(ret, v.y)
        end

        minimap = ret
    end

    return minimap
end

function SnakeAction:killAction(args)
    local ret = {}
    local id = args.id
    if id then
        local online = Online:new(self:getInstance())
        local sessionid = online:connectId2SessionId(id)
        if sessionid then
            local session = _opensession(self:getInstance(), sessionid)
            ret.len   = math.floor(tonumber(session:get("len")))
            ret.count = session:get("kill")
        end
    end
    return ret
end

-- private
_opensession = function(instance, sessionid)
    local sid = sessionid
    if not sid then
        -- cc.throw("not set argsument: \"sid\"")
        return nil
    end

    local session = Session:new(instance:getRedis())
    if not session:start(sid) then
        -- cc.throw("session is expired, or invalid session id")
        return nil
    end

    return session
end

return SnakeAction
