local UserManager = cc.class("UserManager")

function UserManager:ctor()
    self.allUsers = {}
end

function UserManager:addUser(_user)
    self.allUsers[_user.sessionID] = _user
end

function UserManager:delUser(_sid)
    self.allUsers[_sid] = nil
end

function UserManager:getUserBySession(_sid)
    return self.allUsers[_sid]
end

function UserManager:checkUserStatus(_sid)

end


return UserManager
