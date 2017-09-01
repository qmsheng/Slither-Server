
local Online = cc.import("#online")
local Session = cc.import("#session")

local gbc = cc.import("#gbc")
local RankAction = cc.class("RankAction", gbc.ActionBase)

local Model = require("lapis.db.model").Model
local Users = Model:extend("users")

function RankAction:lengthAction()
    local allUserData = Users:select()
    local topScore = {}
    for i,v in ipairs(allUserData) do
        local user = {}
        user.name       = v.name
        user.topScore   = v.topScore
        table.insert(topScore,user)
    end

    table.sort(topScore, function(m, n)
        return m.topScore > n.topScore
    end)

    return topScore
end

function RankAction:levelAction()
    local allUserData = Users:select()
    local levels = {}
    for i,v in ipairs(allUserData) do
        local user = {}
        user.name    = v.name
        user.level   = v.level
        table.insert(levels,user)
    end

    table.sort(levels, function(m, n)
        return m.level > n.level
    end)

    return levels
end

function RankAction:killAction()
    local allUserData = Users:select()
    local kills = {}
    for i,v in ipairs(allUserData) do
        local user = {}
        user.name       = v.name
        user.killNum    = v.killNum
        table.insert(kills,user)
    end

    table.sort(kills, function(m, n)
        return m.killNum > n.killNum
    end)

    return kills
end

function RankAction:achievescoreAction()
    local allUserData = Users:select()
    local achieves = {}
    for i,v in ipairs(allUserData) do
        local user = {}
        user.name           = v.name
        user.achieveScore   = v.achieveScore
        table.insert(achieves,user)
    end

    table.sort(achieves, function(m, n)
        return m.achieveScore > n.achieveScore
    end)

    return achieves
end

return RankAction
