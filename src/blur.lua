require("util/helper")

Blur = class("Blur")

function Blur:__init(x, y, s, dx, dy)
    self.x = x
    self.y = y
    self.s = s
    self.dx = dx
    self.dy = dy
    self.l = 0
    self.time = 5 + math.random() * 10

    local imgs = {resources.images.blur1, resources.images.blur2}
    self.img = imgs[math.random(1,#imgs)]
end

function Blur:update(dt)
    self.x = self.x + dt * self.dx
    self.y = self.y + dt * self.dy
    self.l = self.l + dt / self.time
end

function Blur:draw()
    local a = 0
    if self.l < 0.25 then a = 4 * self.l
    else a = 1 - ((self.l - 0.25) * 4 / 3) end
    love.graphics.setColor(255, 255, 255, math.max(0, a*60*(1-self.s*1.3)))
    love.graphics.draw(self.img, self.x, self.y, 0, self.s, self.s, 128, 128)
end
