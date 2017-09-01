
local lapis = require("lapis")

local db    = require("lapis.db")
local Model   = require("lapis.db.model").Model
local Servers = Model:extend("servers")


local app   = lapis.Application()
app:enable("etlua")
-- app.layout = require "views.layout"

app:get("/web", function(self)
    -- return "web"
    return { render = "index" }
end)

app:get("/web/echo", function(self)
    return "echo"
end)

app:get("/web/app", function(self)
    local temp = ""

    for k,v in pairs(app) do
        temp = temp .. " " .. type(v)
    end
    return { render = "user" }
end)

app:get("/web/wxshare", function(self)
    -- local ua = self.req.headers["user-agent"]
    -- ua = string.lower(ua)
    --
    -- if string.find(ua, "android") then
    --     -- self:write("android")
    -- elseif string.find(ua, "apple") then
    --     -- self:write("apple")
    --     -- return { render = "wxshare" ,{title="abc"} }
    -- end

    return { render = "wxshare",layout= false }
end)

app:post("/web/user", function(self)
    db.query("set names utf8")
    ngx.req.read_body()
    -- print("self.params.ip %s",ngx.req.get_body_data())
    local body_data = json.decode(ngx.req.get_body_data())
    local host_ip = self.req.headers["X-Real-IP"] or self.req.remote_addr

    local onlineUsers = (body_data).users
    local roomInfo = (body_data).room
    local roomPlayerCounts = (body_data).roomNum

    Servers:create({
      ip = host_ip,
      online_users = json.encode(onlineUsers),
      room_info    = json.encode(roomInfo),
      room_counts  = json.encode(roomPlayerCounts),
      ts           = db.raw("now()"),
    })

    return {render = "index"}
end)


return app
