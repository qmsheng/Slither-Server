
local gbc = cc.import("#gbc")
local FriendsAction = cc.class("FriendsAction", gbc.ActionBase)

local Model = require("lapis.db.model").Model
local Friends = Model:extend("friends")
local Users   = Model:extend("users")
local FriendRequest =  Model:extend("friendRequest")

local json      = cc.import("cjson.safe")
local _getFrindsNameByID
local _insertFriend

--获取好友列表
function FriendsAction:friendlistAction(args)
    local playerID  = args.id
    local friends = {}

    Friends.primary_key = {"userID"}
    local user = Friends:find(playerID)
    if user == nil then
        return {}
    end

    friends = json.decode(user.lists)

    local result = _getFrindsNameByID(friends)
    return result
end

function FriendsAction:addfriendAction(args)
    local playerID = args.id
    local targetID = args.target
    local result = {}
    Friends.primary_key = {"userID"}
    if playerID == targetID then
        result = {error = "不能添加自己"}
        return result
    else
        result = Friends:find(playerID)
    end

    if result == nil then
        result = { msg = "请求已经发送"}
    else
        local friends = json.decode(result.lists)
        for i,v in ipairs(friends) do
            if v == targetID then
                result = {error = "已经是好友"}
                return result
            end
        end
    end

    FriendRequest:create({
        userID = playerID,
        friendID = targetID
    })
    --
    result = { msg = "请求已经发送"}
    return result
end

function FriendsAction:acceptAction(args)
    local isAccept = args.accept
    local id       = args.id
    local friendR  = FriendRequest:find(id)
    local result   = {}

    if tonumber(isAccept) == 1 then
        local playerID = friendR.userID
        local targetID = friendR.friendID
        _insertFriend(playerID,targetID)
        _insertFriend(targetID,playerID)

        --添加成功返回新好友
        result = _getFrindsNameByID({friendR.friendID})
    end
    friendR:delete()
    return result[1]

end

function FriendsAction:deletefriendAction(args)
    local playerID = math.min(args.id,args.target)
    local targetID = math.max(args.id,args.target)
    Friends.primary_key = {"userID", "friendID"}
    local result = {}
    local friendData =  Friends:find(playerID,targetID)
    if friendData == nil then
        result = { error = "删除失败" }
        return result
    end
    friendData:delete()

    result = _getFrindsNameByID({args.target})
    return result[1]
end

_deleteFriends = function(_playerID,_friendID)

end

--根据id获取好友昵称
_getFrindsNameByID = function(allID)
    return Users:find_all(allID, {
      fields = "name,id"
    })
end

--玩家插入好友
_insertFriend = function(_playerID,_friendID)
    Friends.primary_key = {"userID"}
    local user = Friends:find(_playerID)
    local friends = {}
    if user == nil then
        table.insert(friends , _friendID)
        friends = json.encode(friends)
        Friends:create({
            userID = _playerID,
            lists = friends,
            friendID = 3
        })

    else
        friends =  json.decode(user.lists)
        if friends == nil then
            friends = {}
        end
        table.insert(friends , _friendID)
        user.lists = json.encode(friends)
        user:update("lists")
    end

end


return FriendsAction
