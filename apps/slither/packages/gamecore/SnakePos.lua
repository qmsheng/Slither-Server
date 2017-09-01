
local SnakePos = cc.class("SnakePos")

function SnakePos:deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[self:deepcopy(orig_key)] = self:deepcopy(orig_value)
        end
        setmetatable(copy, self:deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function SnakePos:ctor(poses)
    self.poses     = self:deepcopy(poses)
    local calcData = {}
    self.distance = 12

    calcData[1] = {
        speed = 0,
        distance = self.distance,
        savePos  = self:deepcopy(poses[1]),
        velocity = cc.pSub(poses[1], poses[1]),
        isSpeedUp = false,
    }

    for i=2,#poses do
        calcData[i] = {
            speed = 0,
            distance = self.distance,
            savePos  = cc.p(poses[i-1].x - self.distance, poses[i-1].y),
            toPos    = cc.p(poses[i-1].x - self.distance, poses[i-1].y),
            velocity = cc.pSub(poses[i-1], poses[i]),
            isSpeedUp = false,
        }
    end
    self.calcData   = calcData
end

function SnakePos:update(_p)
    local poses = self.poses
    local calcData = self.calcData
    -- head
    local data = calcData[1]
    data.velocity = cc.pSub(_p, poses[1])
    data.speed    = cc.pGetLength(data.velocity)
    local _speed = data.speed
    poses[1] = _p
    -- update后续的节点
    for i=2,#poses do
        local pData = calcData[i-1]
        local cData = calcData[i]
        cData.speed = _speed
        local pl = cc.pSub(poses[i-1], cData.savePos)
        local dis = cc.pGetLength(pl)
        local pos = poses[i]
        local tox,toy = cData.toPos.x , cData.toPos.y
        if cData.distance >= self.distance and pData.speed ~= 0 then
            local tox = cData.savePos.x + ( (cData.distance - self.distance)*pData.velocity.x/pData.speed )
            local toy = cData.savePos.y + ( (cData.distance - self.distance)*pData.velocity.y/pData.speed )
            cData.toPos.x = tox
            cData.toPos.y = toy
            local dx = tox - pos.x
            local dy = toy - pos.y
            local dl = cc.pGetLength(cc.p(dx,dy))
            local s = cData.speed
            if s > dl and dl~=0 then s = dl end
            if dl == 0 then
                cData.velocity = cc.p(0,0)
            else
                cData.velocity = cc.p(s*dx/dl, s*dy/dl)
            end

            -- cData.speed = cc.pGetLength(cData.velocity)
            cData.distance = 0
            cData.savePos  = self:deepcopy(poses[i-1])
        end
        cData.distance = cData.distance + pData.speed 
        if math.abs(cData.toPos.x - pos.x) <= math.abs(cData.velocity.x) then
            pos.x = cData.toPos.x
        else
            pos.x = pos.x + cData.velocity.x
        end
        if math.abs(cData.toPos.y - pos.y) <= math.abs(cData.velocity.y) then
           pos.y = cData.toPos.y
        else
           pos.y = pos.y + cData.velocity.y
        end
       poses[i] = pos
       cData.speed = cc.pGetLength(cData.velocity)
    end
end

function SnakePos:addBody()
    local pos = self:initOnePoint()
    table.insert(self.calcData,pos)

    local p   = cc.p(self.poses[#self.poses].x , self.poses[#self.poses].y)
    table.insert(self.poses,p)

end

function SnakePos:initOnePoint()
    local lastPos = self.poses[#self.poses]
    local p = {
        speed = 0,
        distance = self.distance,
        savePos  = cc.p(lastPos.x , lastPos.y),
        toPos    = cc.p(lastPos.x - self.distance, lastPos.y),
        velocity = cc.pSub(self.poses[#self.poses-1], lastPos),
        isSpeedUp = false,
    }
    return p
end

function SnakePos:removeBody()
    table.remove(self.poses,#self.poses)
    table.remove(self.calcData,#self.calcData)
end

return SnakePos
