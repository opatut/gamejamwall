require("mainstate")
require("settingsstate")
require("util/settings")
require("util/resources")
require("util/gamestack")
require("libs/mpd")
require("irc")
require("libs/date")

settings = Settings()
settings:load()
fullscreen = settings:get("fullscreen", false)
savedMode = nil

resources = Resources("data/")

function reset()
    -- start game
    states = {}
    states.main = MainState()
    states.settings = SettingsState()
    stack = GameStack()
    stack:push(states.main)
end

function makeFullscreen()
    w, h, fs = love.graphics.getMode()

    if fs ~= fullscreen then
        if fullscreen then
            savedMode = {w, h}
            modes = love.graphics.getModes()
            table.sort(modes, function(a, b) return a.width*a.height < b.width*b.height end)
            love.graphics.setMode(modes[#modes].width, modes[#modes].height, true)
        else
            dump(savedMode)
            love.graphics.setMode(savedMode[1], savedMode[2], false)
        end
    end
end

function love.load()
    makeFullscreen()

    math.randomseed(os.time())

    -- load images
    resources:addImage("blur1", "blur1.png")
    resources:addImage("blur2", "blur2.png")
--    settings:set("start_time", "2013-06-08 00:00")
--    settings:set("duration", 48)
--    settings:set("title", "BaconGameJam 05")
--    settings:set("mpd_host", "localhost")
--    settings:set("mpd_port", "6600")
--
--    settings:set("irc_server", "irc.freenode.net")
--    settings:set("irc_channel", "#mehtestlua")
--    settings:set("irc_nick", "statuswallbot")

    -- load fonts
    resources:addFont("tiny", "DejaVuSans.ttf", 9)
    resources:addFont("small", "DejaVuSans.ttf", 12)
    resources:addFont("normal", "DejaVuSans.ttf", 18)
    resources:addFont("bigger", "DejaVuSans.ttf", 24)
    resources:addFont("biggest", "DejaVuSansMono-Bold.ttf", 50)

    resources:addFont("mono", "DejaVuSansMono.ttf", 11)
    resources:addFont("monobold", "DejaVuSansMono-Bold.ttf", 11)

    -- load music
    -- resources:addMusic("background", "background.mp3")

    resources:load()

    reset()
end

function love.update(dt)
    stack:update(dt)
end

function love.draw()
    stack:draw()

    -- love.graphics.setFont(resources.fonts.tiny)
    -- love.graphics.print("FPS: " .. love.timer.getFPS(), 5, 5)
end

function love.keypressed(k, u)
    stack:keypressed(k, u)
end

function love.mousepressed( x, y, button )
    stack:mousepressed(x, y, button)
end

function love.quit()
end
