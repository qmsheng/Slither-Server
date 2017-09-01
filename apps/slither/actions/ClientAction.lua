
local Online = cc.import("#online")
local Session = cc.import("#session")

local gbc = cc.import("#gbc")
local ClientAction = cc.class("ClientAction", gbc.ActionBase)

function ClientAction:upgradeAction(args)
    local result = {
        upgrade = false,
    }
    local build_num = args.build
    local server_build = self:getInstanceConfig().server.client_build

    if tonumber(server_build) > tonumber(build_num) then
        result.upgrade = true
        result.url     = "https://itunes.apple.com/cn/app/she-she-zong-dong-yuan-tan/id1148789977?mt=8"
    end

    return result
end

return ClientAction
