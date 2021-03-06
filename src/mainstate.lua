-- main state

require("util/gamestate")
require("util/resources")

require("blur")

MainState = class("MainState", GameState)

colors = {
    {0, 71, 189},
    {2, 136, 217},
    {7, 185, 252},
    {0, 149, 67},
    {0, 171, 56},
    {154, 249, 0},
    {255, 179, 0},
    {255, 206, 0},
    {255, 230, 59},
    {234, 0, 52},
    {253, 71, 3},
    {255,  130, 42},
    {130, 0, 172},
    {182, 16, 191},
    {204, 114, 245}
}

function MainState:__init()
    self.irc_log = {}
    self.lifetime = 0
    self.updateTimer = 0
    self.blurs = {}

    self:readConfig()
end

function MainState:readConfig()
    self.start_time = date(settings:get("start_time", tostring(date())))
    self.duration = settings:get("duration", 48)
    self.end_time = date(self.start_time):addhours(self.duration)

    self.mpd_host = settings:get("mpd_host", "localhost")
    self.mpd_port = settings:get("mpd_port", 6600)

    self.irc_server = settings:get("irc_server", "")
    self.irc_channel = settings:get("irc_channel", "")
    self.irc_nick = settings:get("irc_nick", "")

    self:startMpd()
    self:connectIrc()
end

function MainState:startMpd()
    if self.mpd then
        self.mpd:close()
    end

    local status, err = pcall(function()
        self.mpd = mpd.connect(self.mpd_host, self.mpd_port, true)
    end)

    if not status then
        print(err)
        self.mpd = nil
    end
end

function MainState:updateMpd()
    if not self.mpd then self:startMpd() end
    if not self.mpd then return end
    self.mpd_status = self.mpd:status()
    self.mpd_song = self.mpd:currentsong()
end

function MainState:ircAction(type, user, message)
    table.insert(self.irc_log, {
        type = type,
        user = user,
        message = message or "",
        time = date()
    })
end

function MainState:connectIrc()
    -- print(self.irc_server, self.irc_channel, self.irc_nick)
    if self.irc_server == "" or self.irc_channel == "" or self.irc_nick == "" then return end

    self.irc = irc.new{nick = self.irc_nick}

    self.irc:hook("OnChat", function(user, channel, message)
        self:ircAction("chat", user, message)
    end)

    self.irc:hook("OnJoin", function(user, channel)
        self:ircAction("join", user)
    end)

    self.irc:hook("OnPart", function(user, channel)
        self:ircAction("part", user)
    end)

    self.irc:hook("NickChange", function(user, newnick, channel)
        self:ircAction("nick", user, newnick)
    end)

    self.irc:connect(self.irc_server)
    self.irc:join(self.irc_channel)
    self.irc:trackUsers(true)
end

function MainState:updateIrc()
    if self.irc then
        self.irc:think()
    end
end


function MainState:draw()
    love.graphics.setBackgroundColor(hsl2rgb(self.hue, 50, 20))
    love.graphics.clear()

    for i = 1, #self.blurs do
        self.blurs[i]:draw()
    end

    local x = love.graphics.getWidth() - 40
    local y = 40
    local w = love.graphics.getWidth() / 2 - 60

    love.graphics.setColor(0, 0, 0, 128)
    love.graphics.rectangle("fill", love.graphics.getWidth() / 2 + 10, 30, love.graphics.getWidth() / 2 - 40, 120)
    love.graphics.rectangle("fill", 30, 30, love.graphics.getWidth() / 2 - 40, 120)
    love.graphics.rectangle("fill", 30, 170, love.graphics.getWidth() - 60, love.graphics.getHeight() - 200)

    if self.mpd and self.mpd_status and self.mpd_song then
        local status = self.mpd_status
        local song = self.mpd_song
        local elapsed = (status.state=="stop" and 0 or status.elapsed)

        love.graphics.setColor(255, 255, 255)
        love.graphics.setFont(resources.fonts.normal)
        love.graphics.printf(song.Title or song.file, x - w, y, w, "right")

        love.graphics.setColor(255, 255, 255, 128)
        love.graphics.setFont(resources.fonts.small)
        love.graphics.printf(song.Artist or "", x - w, y+30, w, "right")
        love.graphics.printf(song.Album or "", x - w, y+50, w, "right")

        love.graphics.setColor(255, 255, 255, 70)
        love.graphics.setFont(resources.fonts.tiny)
        love.graphics.printf(status.state .. " | " .. status.volume .. "% | " ..
            "Song " .. song.Pos .. "/" .. status.playlistlength ..  " | " ..
            formatDuration(elapsed) .. " [" .. formatDuration(song.Time) ..
            "]", x - w, y+73, w, "right")

        love.graphics.setColor(50, 50, 50)
        love.graphics.rectangle("fill", x - w, y + 96, w, 1)
        love.graphics.setColor(255, 128, 0)
        love.graphics.rectangle("fill", x - w, y + 96, (elapsed/song.Time) * w, 1)
        love.graphics.rectangle("fill", x - w + w * (elapsed/song.Time) - 1, y + 93, 2, 7)
    else
        love.graphics.setColor(255, 255, 255, 128)
        love.graphics.setFont(resources.fonts.normal)
        love.graphics.printf("MPD Offline", x - w, y, w, "right")
    end

    local w = love.graphics.getWidth() / 2 - 60
    local x = 40
    local y = 40

    love.graphics.setColor(255, 255, 255, 128)
    love.graphics.setFont(resources.fonts.tiny)

    love.graphics.printf(self.start_time .. " to " .. self.end_time, x, y+5, w, "center")

    local now = date():addhours(0)
    local diff, state

    if now < self.start_time then
        diff = date.diff(self.start_time, now)
        state = 1
    elseif now > self.end_time then
        diff = date.diff(now, self.end_time)
        if diff:spanseconds() <= 10 then
            diff = date.diff(self.end_time, self.end_time)
        end
        state = 3
    else
        diff = date.diff(self.end_time, now)
        state = 2
    end

    love.graphics.setColor(255, 255, 255)

    local min = diff:spanminutes()
    local sec = diff:spanseconds()

    if state < 3 then
        if sec <= 10 then
            love.graphics.setColor(255, 0, 0, self.lifetime%0.4 < 0.2 and 255 or 0)
        elseif min <= 1 then
            love.graphics.setColor(255, 0, 0)
        elseif min <= 10 then
            love.graphics.setColor(255, 255, 0)
        end
    elseif state == 3 then
        if sec <= 10 then
            love.graphics.setColor(255, 0, 0, self.lifetime%0.4 < 0.2 and 255 or 0)
        end
    end

    love.graphics.setFont(resources.fonts.biggest)
    local delta = diff:fmt("%X")
    if diff:spandays() >= 1 then
        delta = math.floor(diff:spandays()) .. "d" .. delta
    end
    love.graphics.printf(delta, x, y + 24, w, "center")


    if state == 2 then
        local progress = 1 - (diff:spanhours() / self.duration)
        local r = 40
        local a = -math.pi/2

        love.graphics.setColor(255, 255, 255, 20)
        love.graphics.rectangle("fill", x, y + 93, w, 7)
        --love.graphics.arc("fill", love.graphics.getWidth() / 2 - r - 20, y+50, r, a, a - math.pi * 2)
        love.graphics.setColor(255, 128, 0)
        love.graphics.rectangle("fill", x, y + 93, w * progress, 7)
        --love.graphics.arc("fill", love.graphics.getWidth() / 2 - r - 20, y+50, r, a, a - math.pi * 2 * progress )
    else
        love.graphics.setFont(resources.fonts.normal)
        love.graphics.printf(state == 1 and "Starting soon" or "Finished", x, y + 82, w, "center")
    end


    local x = 40
    local w = love.graphics.getWidth() - 80
    local x1 = 220
    local w1 = w - x1 + x + 5
    local y = love.graphics.getHeight() - 40
    local font1 = resources.fonts.monobold
    local font2 = resources.fonts.mono
    font1:setLineHeight(1.2)
    font2:setLineHeight(1.2)

    local i = 0
    while y > 190 and i < #self.irc_log do
        local log = self.irc_log[#self.irc_log-i]

        local nick = log.user.nick
        local access = log.user.access
        local message = log.message
        local color = {255, 255, 255, 200}
        if log.type == "join" then
            message = "++ joined the channel ++"
            color = {0, 200, 0, 160}
        elseif log.type == "part" then
            message = "++ left the channel ++"
            color = {255, 0, 0, 160}
        elseif log.type == "nick" then
            message = "is now known as " .. message
            color = {255, 255, 255, 120}
        end

        -- calculate height
        local width, lines = font2:getWrap(message, w1)
        y = y - lines * font2:getHeight() * font2:getLineHeight()

        local hash = string.hashcode(nick)
        local nickwidth = font1:getWidth(nick)
        local accesswidth = font1:getWidth(access)

        love.graphics.setFont(font1)

        love.graphics.setColor(255, 255, 255, 200)
        love.graphics.print(log.time:fmt("%X"), x, y)

        love.graphics.setColor(255, 255, 255)
        love.graphics.print(access, x1 - 12 - nickwidth - accesswidth, y)
        love.graphics.setColor(unpack(colors[hash%#colors + 1]))
        love.graphics.print(nick, x1 - 10 - nickwidth, y)

        love.graphics.setFont(font2)
        love.graphics.setColor(unpack(color))
        love.graphics.printf(message, x1, y, w1, "left")

        i = i + 1
    end

    font1:setLineHeight(1)
    font2:setLineHeight(1)
end

function MainState:update(dt)
    self.lifetime = self.lifetime + dt
    self.updateTimer = self.updateTimer - dt
    if self.updateTimer <= 0 then
        self:updateMpd()
        self.updateTimer = 0.5
    end

    self.hue = self.lifetime * 6 % 255

    self:updateIrc()

    for i = 1, #self.blurs do
        self.blurs[i]:update(dt)
    end

    for i=#self.blurs,1,-1 do
        if self.blurs[i].l >= 1 then -- could be any other complex condition
            table.remove(self.blurs, i)
        end
    end

    local b = 100
    local s = 15
    if settings:get("animate", true) then
        for i=#self.blurs,200 do
            table.insert(self.blurs, Blur(
                math.random(-b, love.graphics.getWidth()+b),
                math.random(-b, love.graphics.getHeight()+b),
                0.1 + math.random() * 5.0,
                -0.5*s+s*math.random(),
                -0.9*s+s*math.random(),
                self.hue
                ))
        end
    end
end

function MainState:keypressed(k, u)
    if k == "escape" or k == "q" then
        stack:pop()
    elseif k == "tab" then
        stack:push(states.settings)
    elseif k == "f" then
        fullscreen = not fullscreen
        settings:set("fullscreen", fullscreen)
        settings:save()
        makeFullscreen()
    elseif k == "a" then
        local a = settings:get("animate", true)
        settings:set("animate", not a)
        settings:save()
    end
end
