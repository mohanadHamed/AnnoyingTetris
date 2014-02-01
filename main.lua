require("game")
require("renderer")
require("user_input")

function love.load()
    Game:init();
    Renderer:init();
end

function love.update(dt)
    Game:update(dt);
end

function love.draw()
	Renderer:renderAllObjects();
end

function love.keypressed(key, unicode)
    UserInput:processKeyDown(key);
end