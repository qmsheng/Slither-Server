local UserData = cc.class("UserData")

function UserData:ctor()

end

function UserData:setData(_data)
    self.sessionID  = _data.sessionID
    self.userName   = _data.userName
    self.ip         = _data.ip
    self.device     = _data.device
    self.level      = _data.level
    self.roomStatus = _data.roomStatus
    self.serverID   = _data.serverID
end

function UserData:enterRoom(_roomID)
    self.roomStatus = _roomID
end

function UserData:levelRoom()
    self.roomStatus = nil
end


return UserData
