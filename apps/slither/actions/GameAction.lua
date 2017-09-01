
local Online    = cc.import("#online")
local Session   = cc.import("#session")
local gbc       = cc.import("#gbc")
local json      = cc.import("#json")
local Constants = gbc.Constants

local GameAction = cc.class("GameAction", gbc.ActionBase)
GameAction.ACCEPTED_REQUEST_TYPE = "websocket"

-- 用户进入游戏房间
function GameAction:tryAction(args)
    local username  = args.username
    local sessionid = args.sessionid
    local roomid    = args.roomid
    local passwd    = args.passwd

    if not sessionid then
        cc.throw("not set argsument: \"sessionid\"")
    end

    local result = {}
    -- local online = Online:new(self:getInstance())
    -- local session = online:openSession(sessionid)
    if session then
        result.ok = 1
    else
        result.ok = 0
    end
    return result
end

-- 创建访问, 返回房间id
function GameAction:roomcreateAction(args)
    local instance = self:getInstance()
    local redis = instance:getRedis()

    local userid    = instance:getUserID()
    local rname     = args.roomname
    local rpass     = args.roompass

    local ROOM_NEXT_ID_KEY = Constants.ROOM_PREFIX .. Constants.ROOM_NEXT_ID_KEY
    -- 创建
    local ok = true
    local result = {}

    if ok then
        local roomid = tostring(redis:incr(ROOM_NEXT_ID_KEY))
        local room_key = Constants.ROOM_LIST .. roomid

        local room = {
            roomid = roomid,
            owner  = userid,
            rname  = rname,
            rpass  = rpass,
            createDate = ngx.now(),
        }

        -- 房间有效期
        local expired = instance.config.server.GameConfig.roomExpired
        redis:set(room_key, json.encode(room), "EX", expired)

        result = room
    end
    return result
end

-- 每次返回5个,随机
function GameAction:roomlistAction(args)
    local instance = self:getInstance()
    local redis = instance:getRedis()

    local ids = {}
    local keys,err = redis:keys(Constants.ROOM_LIST .. "*")
    if not err then
        local len = #keys
        if len <=5 then
            for i=1,len do
                ids[i] = true
            end
        else
            for i=1,5 do
                local id = math.random(1, len)
                while ids[id] do
                    id = math.random(1, len)
                end
                ids[id] = true
            end
        end
    end

    local result = {}
    for i,_ in pairs(ids) do
        local key = keys[i]
        local room = json.decode(redis:get(key))
        table.insert(result,{
            roomid = room.roomid,
            locked = (room.rpass ~= nil),
            owner  = room.owner,
            rname  = room.rname,
        })
    end

    return result
end

-- 邀请好友加入
function GameAction:roominviteAction(args)
    local msgid     = args.msgid
end

function GameAction:signoutAction(args)
    -- remove user from online list
    local session = _opensession(self:getInstance(), args)
    local online = Online:new(self:getInstance())
    online:remove(session:get("username"))
    -- delete session
    session:destroy()
    return {ok = "ok"}
end

return GameAction
