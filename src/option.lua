-- an option in the settings state

require("util/helper")

Option = class("Option")

function Option:__init(title, name, default)
    self.title = title
    self.name = name
    self.value = settings:get(name, default)
end

function Option:draw(y, active)
    love.graphics.setFont(resources.fonts.normal)

    love.graphics.setColor(255, 255, 255, active and 255 or 100)
    love.graphics.printf(self.title, 30, y, 160, "right")
    love.graphics.print(self.value .. (active and "_" or ""), 200, y)
end

function Option:keypressed(k, u)
    if k == "backspace" then
        self.value = string.sub(self.value, 1, -2)
    elseif u >= 32 and u < 127 then
        self.value = self.value .. string.char(u)
    end
end
