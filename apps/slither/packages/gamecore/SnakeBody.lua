local SnakeBody = cc.class("SnakeBody")
local cc     = cc.import(".ccmath")

function SnakeBody:ctor(_parent , _pos)
    self.parentBody = _parent
    self.location   = _pos
    self.velocity   = cc.p(0,0)
    self.speed      = _parent.speed
    self.r          = _parent.r

    self.distance   = 12
    self.tracerDis  = 12

    self.savex      = self.parentBody.location.x
    self.tox        = self.parentBody.location.x - self.distance
    self.savey      = self.parentBody.location.y;
    self.toy        = self.parentBody.location.y;
    self:onRender()
end

function SnakeBody:onVelocity(x, y)
    self.tox = x or self.tox;
    self.toy = y or self.toy;

    local disX = self.tox - self.location.x;
    local disY = self.toy - self.location.y;
    local dis = cc.pGetLength(cc.p(disX , disY))

    -- self.velocity.x = self.speed * disX / dis or 0;
    -- self.velocity.y = self.speed * disY / dis or 0;

    if dis == 0 then
        self.velocity.x =  0
        self.velocity.y =  0
    else
        local s = self.speed
        if s > dis then
            s = dis
        end

        self.velocity.x =  s * disX / dis
        self.velocity.y =  s * disY / dis
    end

end

function SnakeBody:onRender()
    local R = 12
    self.distance   = R
    self.speed      = self.parentBody.speed

    local pl = cc.pSub(self.parentBody.location, cc.p(self.savex,self.savey))
    local dis = cc.pGetLength(pl)

    if  dis >= self.distance   and  self.parentBody.speed ~= 0 then

        local ll = cc.pSub(self.parentBody.location, cc.p(self.savex,self.savey))
        local d = cc.pGetLength(ll)
        self.tox = self.savex + (( d - self.distance) * self.parentBody.velocity.x / self.parentBody.speed);
        self.toy = self.savey + (( d - self.distance) * self.parentBody.velocity.y / self.parentBody.speed);

         self:onVelocity(self.tox, self.toy);

         self.tracerDis = 0;
         self.savex = self.parentBody.location.x
         self.savey = self.parentBody.location.y
    end

    self.tracerDis = self.parentBody.speed + self.tracerDis;

    if math.abs(self.tox - self.location.x) <= math.abs(self.velocity.x) then
        self.location.x = self.tox;
    else
        self.location.x = self.location.x + self.velocity.x
    end


   if math.abs(self.toy - self.location.y) <= math.abs(self.velocity.y) then
       self.location.y = self.toy;
   else
       self.location.y = self.location.y + self.velocity.y
   end

   self.speed = cc.pGetLength(self.velocity)
end



return SnakeBody
