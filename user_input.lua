UserInput = 
{
};

function UserInput:processKeyDown(key)
    if love.keyboard.isDown("left") then
        Game:movePlayerLeft();
    elseif love.keyboard.isDown("right") then
        Game:movePlayerRight();
    elseif love.keyboard.isDown("up") then
        Game:rotatePlayer();
    elseif love.keyboard.isDown(" ") and Game:isGameEnded() then
        Game:restartGame();
end
end