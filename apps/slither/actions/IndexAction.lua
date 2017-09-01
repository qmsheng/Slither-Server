
local Online = cc.import("#online")
local Session = cc.import("#session")

local gbc = cc.import("#gbc")
local IndexAction = cc.class("IndexAction", gbc.ActionBase)

--  禁止访问 /
function IndexAction:indexAction(args)
    return ngx.exit(404)
end

return IndexAction
