-- settings state

require("util/gamestate")
require("util/resources")

SettingsState = class("SettingsState", GameState)

function SettingsState:draw()
    love.graphics.setBackgroundColor(17, 17, 17)
    love.graphics.setColor(255, 255, 255)

    love.graphics.clear()
    love.graphics.setFont(resources.fonts.bigger)
    love.graphics.print("Settings", 10, 10)

    local font = resources.fonts.normal
    local s = "<Escape> Cancel -- <Enter> Save"

    love.graphics.setFont(resources.fonts.normal)
    love.graphics.print(s, love.graphics.getWidth() - font:getWidth(s) - 10, love.graphics.getHeight() - font:getHeight() - 10)
end

function MainState:keypressed(k, u)
    if k == "escape" then
        stack:pop()
    elseif k == "return" then
        settings:save()
        stack:pop()
    end
end
