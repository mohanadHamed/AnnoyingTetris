
Renderer = 
{ 
	SCREEN_WIDTH  = 640;
	SCREEN_HEIGHT = 640;

	BLOCK_WIDTH = 38;
	BLOCK_HEIGHT = 38;
	
	-- set pattern block color
	PATTERN_COLOR_R = 255;
	PATTERN_COLOR_G = 255;
	PATTERN_COLOR_B = 0;
	PATTERN_COLOR_ALPHA = 255;
	
	-- set wall block color
	WALL_COLOR_R = 0;
	WALL_COLOR_G = 0;
	WALL_COLOR_B = 255;
	WALL_COLOR_ALPHA = 255;

	-- set empty block color
	EMPTY_COLOR_R = 50;
	EMPTY_COLOR_G = 50;
	EMPTY_COLOR_B = 50;
	EMPTY_COLOR_ALPHA = 255;
	
	
	-- score positions
	m_scoreLabelX = 0;
	m_scoreLabelY = 0;
	m_scoreValueX = 0;
	m_scoreValueY = 0;
	
	-- level positions
	m_levelLabelX = 0;
	m_levelLabelY = 0;
	m_levelValueX = 0;
	m_levelValueY = 0;
	
	-- fonts
	m_scoreFont = nil;
	m_gameEndMessageFont = nil;
	
};

function Renderer:init()
    
    love.window.setMode(self.SCREEN_WIDTH,
     					self.SCREEN_HEIGHT,
     					{resizable=true, vsync=false, minwidth=self.SCREEN_WIDTH, minheight=self.SCREEN_HEIGHT}
     					);
     					
    self.m_scoreLabelX = self.SCREEN_WIDTH * 0.75;
    self.m_scoreLabelY = self.SCREEN_HEIGHT * 0.35;
    self.m_scoreValueX = self.SCREEN_WIDTH * 0.75;
    self.m_scoreValueY = self.SCREEN_HEIGHT * 0.45;
    
     					
    self.m_levelLabelX = self.SCREEN_WIDTH * 0.75;
    self.m_levelLabelY = self.SCREEN_HEIGHT * 0.55;
    self.m_levelValueX = self.SCREEN_WIDTH * 0.75;
    self.m_levelValueY = self.SCREEN_HEIGHT * 0.65;
    
    self.m_scoreFont = love.graphics.newFont(40);
    self.m_gameEndMessageFont = love.graphics.newFont(30);
    
end

function Renderer:renderAllObjects()
    	
    	-- render landed blocks
	    for i=0, Game.BOARD_ROWS - 1 do
      		for j=0, Game.BOARD_COLS - 1 do
        		 if Game:landedBlocks()[i][j] == Game.BlockType.PATTERN then
        		 	love.graphics.setColor(self.PATTERN_COLOR_R, self.PATTERN_COLOR_G, self.PATTERN_COLOR_B, self.PATTERN_COLOR_ALPHA);
				 elseif Game:landedBlocks()[i][j] == Game.BlockType.WALL then
        		 	love.graphics.setColor(self.WALL_COLOR_R, self.WALL_COLOR_G, self.WALL_COLOR_B, self.WALL_COLOR_ALPHA);
				else -- empty
				 	love.graphics.setColor(self.EMPTY_COLOR_R, self.EMPTY_COLOR_G, self.EMPTY_COLOR_B, self.EMPTY_COLOR_ALPHA);
        		end
        		
        		local blockX = self.BLOCK_WIDTH * j;
        		local blockY = self.BLOCK_HEIGHT * i;

				-- draw block filled with color according to its type
				love.graphics.rectangle("fill",
										blockX,
										blockY,
										self.BLOCK_WIDTH,
										self.BLOCK_HEIGHT);
				
				-- draw outlined rectangle for all block types	
				love.graphics.setColor(0,0,0,100);					
				love.graphics.rectangle("line",
										blockX,
										blockY,
										self.BLOCK_WIDTH,
										self.BLOCK_HEIGHT);
      		end
    	end
    	
    	
    	-- render player object
		for i=0, 3 do
      		for j=0, 3 do
        		if Game:getPlayerPatternBlock(i, j) == Game.BlockType.PATTERN then
        		local blockX = self.BLOCK_WIDTH * (Game:player().startCol + j);
        		local blockY = self.BLOCK_HEIGHT * (Game:player().startRow + i);
        		 
        		love.graphics.setColor(self.PATTERN_COLOR_R, self.PATTERN_COLOR_G, self.PATTERN_COLOR_B, self.PATTERN_COLOR_ALPHA);
				love.graphics.rectangle("fill",
										blockX,
										blockY,
										self.BLOCK_WIDTH,
										self.BLOCK_HEIGHT);
													
				-- draw outlined rectangle for player blocks	
				love.graphics.setColor(0, 0, 0, 20);					
				love.graphics.rectangle("line",
										blockX,
										blockY,
										self.BLOCK_WIDTH,
										self.BLOCK_HEIGHT);
        		end
      		end
    	end
    	
    	    
    	-- render the score
		love.graphics.setColor(225, 225, 0, 255);
		love.graphics.setFont(self.m_scoreFont);						
		love.graphics.printf("Score",
							self.m_scoreLabelX,
							self.m_scoreLabelY,
							self.SCREEN_WIDTH,
							"left"
							);
												
		love.graphics.printf(Game:score(),
							self.m_scoreValueX,
							self.m_scoreValueY,
							self.SCREEN_WIDTH,
							"left");


    	-- render the score
		love.graphics.printf("Level",
							self.m_levelLabelX,
							self.m_levelLabelY,
							self.SCREEN_WIDTH,
							"left"
							);
												
		love.graphics.printf(Game:level(),
							self.m_levelValueX,
							self.m_levelValueY,
							self.SCREEN_WIDTH,
							"left");

    	-- render game end message
    	if Game:isGameEnded() then
    		    
    		    love.graphics.setColor(255, 0, 0, 50);
				love.graphics.rectangle("fill",
										0,
										0,
										self.SCREEN_WIDTH,
										self.SCREEN_HEIGHT);
				
				
    		    love.graphics.setColor(30, 30, 30, 200);
				love.graphics.rectangle("fill",
										self.SCREEN_WIDTH * 0.2,
										self.SCREEN_HEIGHT * 0.3,
										self.SCREEN_WIDTH * 0.6,
										self.SCREEN_HEIGHT * 0.27);
				
				love.graphics.setColor(225, 225, 225, 255);
    		    love.graphics.setFont(self.m_gameEndMessageFont);						
    			love.graphics.printf("Your score: "..Game:score().."\n\n Press space to restart",
    						 		0,
    						 		self.SCREEN_HEIGHT * 0.35,
    						 		self.SCREEN_WIDTH,
    						 		"center");
    	end
    
end