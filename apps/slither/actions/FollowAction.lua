local gbc = cc.import("#gbc")
local FollowAction = cc.class("FollowAction", gbc.ActionBase)

local Model = require("lapis.db.model").Model
local Follow = Model:extend("follow")
local Users   = Model:extend("users")
local InfoCode = cc.import(".InfoCode")

--关注某个用户
function FollowAction:addfollowAction(args)
    local playerID = args.id
    local targetID = args.target

    local result = {}
    Follow.primary_key = {"userID" , "followID"}
    if playerID == targetID then
        result = {error = InfoCode.CAN_NOT_FOLLOW}
        return result
    else
        result = Follow:find(playerID , targetID)
    end

    if result ~= nil then
        result = {error = InfoCode.ALREADY_FOLLOW}
        return result
    end

    Follow:create({
        userID = playerID,
        followID = targetID,
        status   = 0
    })

    result = _getFrindsNameByID({targetID})
    return result
end

--获取我正在关注的人
function FollowAction:followingAction(args)
    local playerID = args.id
    local result = {}
    Follow.primary_key = {"userID"}
    local list = Follow:select("where userID = ?" , playerID)
    if list == nil then
        return  result
    end
    for i,v in ipairs(list) do
        table.insert(result,v.followID)
    end
    result = _getFrindsNameByID(result)
    return result
end

--获取没有被确认的被关注信息
function FollowAction:getmsgAction(args)
    local id = args.id
    Follow.primary_key = {"followID"}
    local result = Follow:select()

    local users = Follow:find_all({id}, {
      key = "followID",
      where = {
        status = 0
      }
    })
    return users
end

--确认被关注的信息
function FollowAction:confirmAction(args)
    local id = args.id
    Follow.primary_key = {"followID"}
    local result = Follow:select()

    local users = Follow:find_all({id}, {
      key = "followID",
      where = {
        status = 0
      }
    })

    for i,v in ipairs(users) do
        v.status = 1
        v:update("status")
    end
    return {}
end

--获取关注我的人
function FollowAction:followerAction(args)
    local playerID = args.id
    local result = {}
    local list = Follow:select("where followID = ?" , playerID)
    if list == nil then
        return  result
    end
    for i,v in ipairs(list) do
        table.insert(result,v.userID)
    end
    result = _getFrindsNameByID(result)
    return result
end

--取消关注
function FollowAction:delfollowAction(args)
    local playerID = args.id
    local targetID = args.target

    local result = {}
    Follow.primary_key = {"userID" , "followID"}
    result = Follow:find(playerID , targetID)
    if result == nil then
        result = {error = InfoCode.DELETE_ERROE}
        return result
    end
    result:delete()
    result = { msg = InfoCode.DELETE_SUCCESS}
    return result 
end

--响应关注信息
function FollowAction:respondfollowAction(args)
    local id = args.id
    local result = {}
    Follow.primary_key = {"id"}
    result = Follow:find(id)

    if result == nil then
        result = {error = InfoCode.SQL_DATA_NIL}
        return result
    end
    result.status = 1
    result:update("status")
    return status
end

--根据id获取好友昵称
_getFrindsNameByID = function(allID)
    return Users:find_all(allID, {
      fields = "name,id"
    })
end

return FollowAction
