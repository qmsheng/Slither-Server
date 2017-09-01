
local gbc = cc.import("#gbc")
local ChatAction = cc.class("ChatAction", gbc.ActionBase)

-- 只允许通过websocket访问
ChatAction.ACCEPTED_REQUEST_TYPE = "websocket"

local db        = require("lapis.db")
local Model     = require("lapis.db.model").Model
local ChartLogs = Model:extend("chat_logs")

function ChatAction:sendmessageAction(arg)
    local instance = self:getInstance()
    local online   = instance:getOnline()
    -- target user id
    local target = arg.target
    if not target then
        cc.throw("not set argument: \"target\"")
    end

    local message = arg.message
    if not message then
        cc.throw("not set argument: \"message\"")
    end

    -- 记录到数据库
    local row = ChartLogs:create({
        from = instance:getUserID(),
        to   = target,
        message = message,
        time    = db.raw("now()"),
    })

    -- 是否在线
    local targetSession = online:openSession(target, "user")
    if targetSession then
        -- forward message to other client
        online:sendMessage(targetSession:getSid(), {
            name      = "MESSAGE",
            sender    = instance:getUserID(),
            body      = message,
        })
    end

    return {
        ok = 1
    }
end

function ChatAction:sendmessagetoallAction(arg)
    local message = arg.message
    if not message then
        cc.throw("not set argument: \"message\"")
    end

    -- forward message to all clients
    local instance = self:getInstance()
    instance:getOnline():sendMessageToAll({
        name      = "MESSAGE",
        sender    = instance:getUserID(),
        recipient = recipient,
        body      = message,
    })
end

return ChatAction
