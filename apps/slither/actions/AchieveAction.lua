
local gbc = cc.import("#gbc")
local AchieveAction = cc.class("AchieveAction", gbc.ActionBase)
local Model = require("lapis.db.model").Model
local Users = Model:extend("users")
local Achievements = Model:extend("achievements")
local Users_Achieve = Model:extend("users_achievements")
local InfoCode = cc.import(".InfoCode")

--获取成就列表
function AchieveAction:checkAction(args)
    local id = args.id
    if not id then
        cc.throw("not set argument: \"id\"")
    end
    local user = Users:find(id)
    local value = {}
    value = {
        points = user.achieveScore
    }

    local achieve = {}

    achieve.killNum   = user.killNum
    achieve.singleLen = user.singleLen
    achieve.totalLen  = user.totalLen
    achieve.level     = user.level
    achieve.follower  = user.follower
    achieve.following = user.following

    local ach = Users_Achieve:select("where user_id = ?" , id)
    local achieveID = {}
    for i,v in ipairs(ach) do
        table.insert(achieveID ,v.achieve_id)
    end

    value.achieveID = achieveID
    value.achieve = achieve

    return value
end

function AchieveAction:getrewardAction(args)
    local archieveID = args.aid
    if not archieveID then
        cc.throw("not set argument: \"aid\"")
    end
    local userID     = args.uid
    if not userID then
        cc.throw("not set argument: \"uid\"")
    end

    local user = Users:find(userID)
    local data = Achievements:find(archieveID)
    local key = data.type
    local value = data.value
    local _reward = data.reward

    local result = {}
    if user[key] >= value then
        Users_Achieve.primary_key = {"user_id"}
        local raw = Users_Achieve:select("where user_id = ?" , userID)
        for i,v in ipairs(raw) do
            if tonumber(v.achieve_id) == tonumber(archieveID) then
                result = {
                    error = InfoCode.ACHIEVEMENT_REWARD_GOT
                }
                return result
            end
        end

        result = {
            reward = _reward
        }

        local user_achieve = {
            user_id = userID,
            achieve_id = archieveID,
        }
        Users_Achieve:create(user_achieve)


        local user = Users:find(userID)
        user.achieveScore = user.achieveScore + _reward
        user:update("achieveScore")
    else
        result = {
            error = InfoCode.ACHIEVEMENT_REWARD_FAIL
        }
    end


    return result
end

--获取等级进度
function AchieveAction:levelAction(args)
    local id = args.id
    if not id then
        cc.throw("not set argument: \"id\"")
    end
    local user = Users:find(id)
    local _exp = user.exp
    local _levelReward = user.level_reward

    local result = {
        exp = _exp,
        levelRewad = _levelReward
    }
    return result
end

function AchieveAction:levelrewardAction(args)
    local id = args.id
    if not id then
        cc.throw("not set argument: \"id\"")
    end
    local rewardLevel = tonumber(args.level)
    if not rewardLevel then
        cc.throw("not set argument: \"level\"")
    end
    local user = Users:find(id)
    local _levelReward = tonumber(user.level_reward)
    local _level       = tonumber(user.level)
    local result       = {}
    if _level >= rewardLevel and rewardLevel > _levelReward then
        result = {
            reward = 1
        }
        user.level_reward = rewardLevel
        user:update("level_reward")
    else
        result = {
            error = InfoCode.ACHIEVEMENT_REWARD_FAIL
        }
    end
    return result

end

return AchieveAction
