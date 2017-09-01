
local Online = cc.import("#online")
local Session = cc.import("#session")

local gbc = cc.import("#gbc")
local UserAction = cc.class("UserAction", gbc.ActionBase)
local SensitiveWordFilter = cc.import("#wordfilter").SensitiveWordFilter
local sentive_words       = cc.import("#wordfilter").words

local db    = require("lapis.db")
local Model = require("lapis.db.model").Model
local Users = Model:extend("users")

local _opensession
local _hasSensitiveWords
local _sensitiveWordFilter = SensitiveWordFilter:new()
_sensitiveWordFilter:regSensitiveWords(sentive_words)

function UserAction:signupAction(args)
    local username      = args.username
    local sdkid         = args.sdkid
    local channel       = args.channel
    local devicetype    = args.devicetype
    local deviceid      = args.deviceid
    local userip        = ngx.var.remote_addr

    if not username then
        cc.throw("not set argsument: \"username\"")
    end

    local nameLegal     = not _hasSensitiveWords(username)
    local nameAvailable = _nameAvailable(username)
    local userid, ok    = -1, 0
    if nameLegal and nameAvailable then
        local row = Users:create({
            name    = username,
            channel = channel,
            sdkid   = sdkid,
            regDate  = db.raw("now()"),
            lastDate = db.raw("now()"),
            lastIP   = userip,
        })
        userid = row.id
        ok = 1
    end

    return {
        ok        = ok,
        legal     = nameLegal,
        available = nameAvailable,
        userid    = userid,
    }
end

function UserAction:signinAction(args)
    local username = args.username
    local userid   = args.userid
    if not username or not userid then
        cc.throw("not set arguments: \"username\" or \"userid\"")
    end

    local online = Online:new(self:getInstance())

    local result = {}
    local session = Session:new(self:getInstance():getRedis())

    -- for kk,vv in pairs(session) do
    --     -- ngx.say(kk)
    --     if kk == '_redis' then
    --         for k,v in pairs(vv) do
    --             -- ngx.say(k)
    --             if k == '_config' then
    --                 for k1,v1 in pairs(v) do
    --                     ngx.say(k1)
    --                     ngx.say(v1)
    --                 end
    --             end
    --         end
    --     end
    -- end
    -- ngx.exit(200)

    session:start()
    session:set("username", username)
    session:set("userid",   userid)
    session:save()

    local config = self:getInstance().config
    local gameConfig = config.server.gamecore

    result = {
        ok     = 1,
        sid    = session:getSid(),
        userid = userid,
        server = nil,
        port   = gameConfig.port,
    }

    return result
end

function UserAction:signoutAction(args)
    -- remove user from online list
    local session = _opensession(self:getInstance(), args)
    local online = Online:new(self:getInstance())
    online:remove(session:get("username"))
    -- delete session
    session:destroy()
    return {ok = "ok"}
end

function UserAction:addjobAction(args)
    local sid = args.sid
    if not sid then
        cc.throw("not set argsument: \"sid\"")
    end

    local instance = self:getInstance()
    local redis = instance:getRedis()
    local session = Session:new(redis)
    if not session:start(sid) then
        cc.throw("session is expired, or invalid session id")
    end

    local delay = cc.checkint(args.delay)
    if delay <= 0 then
        delay = 1
    end
    local message = args.message
    if not message then
        cc.throw("not set argument: \"message\"")
    end

    -- send message to job
    local jobs = instance:getJobs()
    local job = {
        action = "/jobs/jobs.echo",
        delay  = delay,
        data   = {
            username = session:get("username"),
            message = message,
        }
    }
    local ok, err = jobs:add(job)
    if not ok then
        return {err = err}
    else
        return {ok = "ok"}
    end
end

-- private
_opensession = function(instance, args)
    local sid = args.sid
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

_hasSensitiveWords = function (word)
    return _sensitiveWordFilter:replaceSensitiveWord(word)
end

_nameAvailable = function (name)
    local rows = Users:select("where name = ?", name)
    return rows and #rows == 0
end

return UserAction
