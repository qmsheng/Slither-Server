local SnakeHead = cc.class("SnakeHead")
local cc     = cc.import(".ccmath")

function SnakeHead:ctor(_snakeData)
    self.location = _snakeData.pos
    self.velocity = _snakeData.velocity
    self.r        = _snakeData.radius
    self.speed =  cc.pGetLength(self.velocity)
end

function SnakeHead:setHeadPos(pos)
    self.velocity = cc.pSub(pos , self.location)
    self.speed    = cc.pGetLength(self.velocity)
    self.location = pos
end

return SnakeHead
