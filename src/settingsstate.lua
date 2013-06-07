-- settings state

require("util/gamestate")
require("util/resources")
require("option")

SettingsState = class("SettingsState", GameState)

function SettingsState:__init()
    self.options = {
        Option("Start Time", "start_time", date()),
        Option("Duration (h)", "duration", 48),
        Option("Title", "title", "BaconGameJam"),
        Option("MPD Host", "mpd_host", "localhost"),
        Option("MPD Port", "mpd_port", "6600"),
        Option("IRC Server", "irc_server", "irc.freenode.net"),
        Option("IRC Channel", "irc_channel", "#mehtestlua"),
        Option("IRC Nickname", "irc_nick", "statuswallbot")
    }
    self.selected = 1
end

function SettingsState:draw()
    love.graphics.setBackgroundColor(17, 17, 17)
    love.graphics.setColor(255, 255, 255)

    love.graphics.clear()
    love.graphics.setFont(resources.fonts.bigger)
    love.graphics.print("Settings", 30, 30)

    for i=1,#self.options do
        self.options[i]:draw(60 + i * 30, i == self.selected)
    end

    love.graphics.setColor(255, 255, 255)
    love.graphics.setFont(resources.fonts.small)
    love.graphics.print("<Escape> Cancel\n<Enter> Save", 200, love.graphics.getHeight() - 60)
end

function SettingsState:keypressed(k, u)
    local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")

    if k == "escape" then
        stack:pop()
    elseif k == "return" then
        for i=1,#self.options do
            settings:set(self.options[i].name, self.options[i].value)
        end
        settings:save()
        stack:pop()
    elseif k == "down" or (k == "tab" and not shift) then
        self.selected = self.selected + 1
        if self.selected > #self.options then self.selected = 1 end
    elseif k == "up" or (k == "tab" and shift) then
        self.selected = self.selected - 1
        if self.selected < 1 then self.selected = #self.options end
    else
        self.options[self.selected]:keypressed(k, u)
    end
end
