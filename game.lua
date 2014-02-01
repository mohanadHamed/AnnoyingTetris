
Game = {

	-- define full board size ( rows = 16, columns = 10)
	BOARD_COLS = 10 + 2; -- two additional blocks (left and right boundaries)
	BOARD_ROWS = 16 + 1; -- one additional block (bottom boundary)

   -- Block types.
    BlockType = { 
        EMPTY        =  0,   -- Block is empty
        PATTERN 	 =  1,   -- block is a part of player pattern or landed pattern
        WALL	     =  2,   -- block is wall block (boundary block)
    };
    
    m_playerObj = nil; -- player object
    m_board = nil; 	   -- contains board info and blocks
    m_timeSinceLastMove = 0;
    m_gameEnded = false;
    m_landedSpaceInfo = nil; -- used help deciding worst block
    m_score = 0;
    m_level = 0;
    m_completedRowAudioSource = nil;
    m_landingAudioSource = nil;
    
    m_patternI = nil;
    m_patternJ = nil;
    m_patternL = nil;
    m_patternO = nil;
    m_patternS = nil;
    m_patternT = nil;
    m_patternZ = nil;
};

-- Methods for getting properties
------------------------------------------------------------------------------
function Game:player()   
	return m_playerObj;
end

function Game:getPlayerPatternBlock(i, j)   
	return m_playerObj.pattern[m_playerObj.rotationIndex][i][j];
end

function Game:landedBlocks()   
	return m_board.landedBlocks;
end

function Game:isGameEnded()   
	return self.m_gameEnded;
end

function Game:score()   
	return self.m_score;
end

function Game:level()   
	return self.m_level;
end

-------------------------------------------------------------------------------

-- Player control methods
-------------------------------------------------------------------------------
function Game:movePlayerLeft()
	if not Game:playerWillCollide(m_playerObj.rotationIndex,
								  m_playerObj.startRow,
								  m_playerObj.startCol - 1) then    
		m_playerObj.startCol = m_playerObj.startCol - 1;
	end
end

function Game:movePlayerRight()
	if not Game:playerWillCollide(m_playerObj.rotationIndex,
								  m_playerObj.startRow,
								  m_playerObj.startCol + 1) then    
		m_playerObj.startCol = m_playerObj.startCol + 1;
	end
end

function Game:movePlayerDown()
	if not Game:playerWillCollide(m_playerObj.rotationIndex,
								  m_playerObj.startRow + 1,
								  m_playerObj.startCol) then    
		m_playerObj.startRow = m_playerObj.startRow + 1;
	else
		Game:landPlayerPattern();
	end
	
	self.m_timeSinceLastMove = 0.0;
end

function Game:rotatePlayer()
	local rotateIndex = (m_playerObj.rotationIndex + 1) % 4;
	while Game:playerWillCollide(rotateIndex, m_playerObj.startRow, m_playerObj.startCol)
	do 
		rotateIndex = (rotateIndex + 1) % 4;
	end
	  
	m_playerObj.rotationIndex = rotateIndex;
end

-- Reset player to start position after landing
-------------------------------------------------------------------------------
function Game:resetPlayerObject()

	if not self.m_gameEnded then
		-- initialize player object
		m_playerObj = {};
		m_playerObj.startRow = 0;
		m_playerObj.startCol = (self.BOARD_COLS / 2) - 1;
		m_playerObj.rotationIndex = 0;
		--m_playerObj.pattern = Game:getRandomPattern();
		m_playerObj.pattern = Game:getWorstPattern();
	
		if Game:playerWillCollide(m_playerObj.rotationIndex, m_playerObj.startRow, m_playerObj.startCol)
		then
			self.m_gameEnded = true;
		end	
	end
end
-------------------------------------------------------------------------------


-- Restarting game
-------------------------------------------------------------------------------
function Game:restartGame()

	self.m_gameEnded = false;
	Game:init();
	
end
-------------------------------------------------------------------------------

-- Check if the player collides with wall or other landed blocks
-------------------------------------------------------------------------------
function Game:playerWillCollide(rotationIndex, row, col)   
	local collision = false;
	
	for i=0, 3 do
      for j=0, 3 do
		  -- make sure that indices will not exceed array limits
		  local landedBlocksRow = math.min( i + row, self.BOARD_ROWS - 1);
		  local landedBlocksCol = math.min( j + col, self.BOARD_COLS - 1);
	  
		  if m_board.landedBlocks[landedBlocksRow][landedBlocksCol] ~= self.BlockType.EMPTY and
			 m_playerObj.pattern[rotationIndex][i][j]
			 ~= self.BlockType.EMPTY
			 then
			 collision = true;
			 break;
        	end
      end
    end
    
    return collision;
end

-------------------------------------------------------------------------------

-- Pattern landing
------------------------------------------------------------------------------
function Game:landPlayerPattern()   
	
	if not self.m_gameEnded then
		for i=0, 3 do
			for j=0, 3 do
				-- make sure that indices will not exceed array limits
				local landedBlocksRow = math.min( i + m_playerObj.startRow, self.BOARD_ROWS - 1);
				local landedBlocksCol = math.min( j + m_playerObj.startCol, self.BOARD_COLS - 1);
				if m_board.landedBlocks[landedBlocksRow][landedBlocksCol] == self.BlockType.EMPTY and
					m_playerObj.pattern[m_playerObj.rotationIndex][i][j]
					~= self.BlockType.EMPTY
					then
					m_board.landedBlocks[landedBlocksRow][landedBlocksCol] =
						m_playerObj.pattern[m_playerObj.rotationIndex][i][j];

					if landedBlocksRow < m_board.minRow then
						m_board.minRow = landedBlocksRow;
					end

					if landedBlocksCol < m_board.minCol then
						m_board.minCol = landedBlocksCol;
				
					elseif landedBlocksCol > m_board.maxCol then
						m_board.maxCol = landedBlocksCol;
					end
				
				end
		  end
		end
	
		self.m_landingAudioSource:play();
		Game:resetPlayerObject();
		Game:findAndDeleteCompletedRows();
    end
end
-------------------------------------------------------------------------------

-- Find completed rows and delete them
------------------------------------------------------------------------------
function Game:findAndDeleteCompletedRows()   
	
	for i= m_board.minRow, self.BOARD_ROWS - 2 do -- exclude wall blocks
		local rowCompleted = true;
		for j=1, self.BOARD_COLS - 2 do -- exclude wall blocks
			if m_board.landedBlocks[i][j] == self.BlockType.EMPTY
			then
				rowCompleted = false;
				break;
			end		
      	end
      	
      	if rowCompleted then
      		Game:deleteLandedRow(i);
      	end
    end
end
-------------------------------------------------------------------------------

-- Delete completed row from landed blocks
------------------------------------------------------------------------------
function Game:deleteLandedRow(row)   
	
	-- shift down blocks that are above completed row
	for i= row, m_board.minRow + 1, -1 do
		for j=1, self.BOARD_COLS - 2 do -- exclude wall blocks
			m_board.landedBlocks[i][j] = m_board.landedBlocks[i - 1][j];		
      	end
    end
   
   -- clear the first row
	for j=1, self.BOARD_COLS - 2 do -- exclude wall blocks
		m_board.landedBlocks[m_board.minRow ][j] = self.BlockType.EMPTY;		
	end
    
    -- increase minimum row
    m_board.minRow = m_board.minRow + 1;
    
    Game:updateScoreAndLevel();
    
    -- play sound effect
    self.m_completedRowAudioSource:play();
end
-------------------------------------------------------------------------------

-- Update score and level after row completion
-------------------------------------------------------------------------------
function Game:updateScoreAndLevel()

    -- increase the score
    self.m_score = self.m_score + 1
    
    -- update the level
    if (self.m_score % 4) == 0 then
    	self.m_level = self.m_level + 1;
    end
    
end
-------------------------------------------------------------------------------


-- Initialize the game
-------------------------------------------------------------------------------
function Game:init()

	self.m_timeSinceLastMove = 0.0;
	self.m_gameEnded = false;
	self.m_score = 0;
	self.m_level = 1;
	self.m_completedRowAudioSource = love.audio.newSource("point.wav", "static");
	self.m_landingAudioSource = love.audio.newSource("landing.wav", "static");
	
	-- set random seed
	math.randomseed(os.time());
	
	-- initialize patters
	-- we have 7 patterns (I, J, L, O, S, T, and Z); each pattern has 4 rotations
	
	-- initialize pattern I
	Game:initializePatternI();
	
	-- initialize pattern J
	Game:initializePatternJ();
	
	-- initialize pattern L
	Game:initializePatternL();

	-- initialize pattern O
	Game:initializePatternO();

	-- initialize pattern S
	Game:initializePatternS();

	-- initialize pattern T
	Game:initializePatternT();

	-- initialize pattern Z
	Game:initializePatternZ();
	
	-- initialize board:
	Game:initBoard();

end
-------------------------------------------------------------------------------

-- initialize the board tile including walls
-------------------------------------------------------------------------------
function Game:initBoard()

	m_board = {};
	m_board.minRow = self.BOARD_ROWS - 1; -- minimum row containing non-empty blocks
	m_board.minCol = self.BOARD_COLS - 1; -- minimum column containing non-empty blocks
	m_board.maxCol = 0; -- maximum column containing non-empty blocks
	 
	-- initialize landed blocks array:
	m_board.landedBlocks = {}          -- create the matrix
    for i=0, self.BOARD_ROWS - 1 do
      m_board.landedBlocks[i] = {};     -- create a new row
      for j=0, self.BOARD_COLS - 1 do
      if j == 0 or
      	 j == self.BOARD_COLS - 1 or
      	 i == self.BOARD_ROWS - 1 then
        	m_board.landedBlocks[i][j] = self.BlockType.WALL;
        else
        	m_board.landedBlocks[i][j] = self.BlockType.EMPTY;
        end
      end
    end
	
	Game:resetPlayerObject();
	
end
-------------------------------------------------------------------------------

-- Move down player object automatically
-- speed depends on user level
-------------------------------------------------------------------------------
function Game:update(dt)
	self.m_timeSinceLastMove = self.m_timeSinceLastMove + dt;
	if self.m_timeSinceLastMove >= math.max(1.0, 1.0 - ((self.m_level - 1) / 3)) then
		Game:movePlayerDown();
	end
	
	if love.keyboard.isDown("down") and self.m_timeSinceLastMove >= 0.05
	then
		Game:movePlayerDown();
	end
		
end
-------------------------------------------------------------------------------

-- initialize pattern I
-------------------------------------------------------------------------------
function Game:initializePatternI()
	m_patternI = {};
	for i=0, 3 do
		m_patternI[i] = {};
		for j=0, 3 do
		  m_patternI[i][j] = {};    -- create a new row
		  for k=0,3 do
			m_patternI[i][j][k] = self.BlockType.EMPTY;
		  end
		end
    end
    
	-- angle 0
	m_patternI[0][0][1] = self.BlockType.PATTERN;
	m_patternI[0][1][1] = self.BlockType.PATTERN;
	m_patternI[0][2][1] = self.BlockType.PATTERN;
	m_patternI[0][3][1] = self.BlockType.PATTERN;

	
	-- angle 90
	m_patternI[1][1][0] = self.BlockType.PATTERN;
	m_patternI[1][1][1] = self.BlockType.PATTERN;
	m_patternI[1][1][2] = self.BlockType.PATTERN;
	m_patternI[1][1][3] = self.BlockType.PATTERN;
	
	-- angle 180
	m_patternI[2][0][2] = self.BlockType.PATTERN;
	m_patternI[2][1][2] = self.BlockType.PATTERN;
	m_patternI[2][2][2] = self.BlockType.PATTERN;
	m_patternI[2][3][2] = self.BlockType.PATTERN;
	
	-- angle 270
	m_patternI[3][2][0] = self.BlockType.PATTERN;
	m_patternI[3][2][1] = self.BlockType.PATTERN;
	m_patternI[3][2][2] = self.BlockType.PATTERN;
	m_patternI[3][2][3] = self.BlockType.PATTERN;
end
-------------------------------------------------------------------------------

-- initialize pattern J
-------------------------------------------------------------------------------
function Game:initializePatternJ()
	m_patternJ = {};
	for i=0, 3 do
		m_patternJ[i] = {};
		for j=0, 3 do
		  m_patternJ[i][j] = {};    -- create a new row
		  for k=0,3 do
			m_patternJ[i][j][k] = self.BlockType.EMPTY;
		  end
		end
    end
    
	-- angle 0
	m_patternJ[0][0][1] = self.BlockType.PATTERN;
	m_patternJ[0][1][1] = self.BlockType.PATTERN;
	m_patternJ[0][2][1] = self.BlockType.PATTERN;
	m_patternJ[0][2][0] = self.BlockType.PATTERN;

	
	-- angle 90
	m_patternJ[1][0][0] = self.BlockType.PATTERN;
	m_patternJ[1][1][0] = self.BlockType.PATTERN;
	m_patternJ[1][1][1] = self.BlockType.PATTERN;
	m_patternJ[1][1][2] = self.BlockType.PATTERN;
	
	-- angle 180
	m_patternJ[2][0][1] = self.BlockType.PATTERN;
	m_patternJ[2][0][2] = self.BlockType.PATTERN;
	m_patternJ[2][1][1] = self.BlockType.PATTERN;
	m_patternJ[2][2][1] = self.BlockType.PATTERN;
	
	-- angle 270
	m_patternJ[3][1][0] = self.BlockType.PATTERN;
	m_patternJ[3][1][1] = self.BlockType.PATTERN;
	m_patternJ[3][1][2] = self.BlockType.PATTERN;
	m_patternJ[3][2][2] = self.BlockType.PATTERN;
end
-------------------------------------------------------------------------------

-- initialize pattern L
-------------------------------------------------------------------------------
function Game:initializePatternL()
	m_patternL = {};
	for i=0, 3 do
		m_patternL[i] = {};
		for j=0, 3 do
		  m_patternL[i][j] = {};    -- create a new row
		  for k=0,3 do
			m_patternL[i][j][k] = self.BlockType.EMPTY;
		  end
		end
    end
    
	-- angle 0
	m_patternL[0][0][1] = self.BlockType.PATTERN;
	m_patternL[0][1][1] = self.BlockType.PATTERN;
	m_patternL[0][2][1] = self.BlockType.PATTERN;
	m_patternL[0][2][2] = self.BlockType.PATTERN;

	
	-- angle 90
	m_patternL[1][1][0] = self.BlockType.PATTERN;
	m_patternL[1][1][1] = self.BlockType.PATTERN;
	m_patternL[1][1][2] = self.BlockType.PATTERN;
	m_patternL[1][2][0] = self.BlockType.PATTERN;
	
	-- angle 180
	m_patternL[2][0][0] = self.BlockType.PATTERN;
	m_patternL[2][0][1] = self.BlockType.PATTERN;
	m_patternL[2][1][1] = self.BlockType.PATTERN;
	m_patternL[2][2][1] = self.BlockType.PATTERN;
	
	-- angle 270
	m_patternL[3][0][2] = self.BlockType.PATTERN;
	m_patternL[3][1][0] = self.BlockType.PATTERN;
	m_patternL[3][1][1] = self.BlockType.PATTERN;
	m_patternL[3][1][2] = self.BlockType.PATTERN;
end
-------------------------------------------------------------------------------

-- initialize pattern O
-------------------------------------------------------------------------------
function Game:initializePatternO()
	m_patternO = {};
	for i=0, 3 do
		m_patternO[i] = {};
		for j=0, 3 do
		  m_patternO[i][j] = {};    -- create a new row
		  for k=0,3 do
			m_patternO[i][j][k] = self.BlockType.EMPTY;
		  end
		end
    end
    
	-- angle 0
	m_patternO[0][0][0] = self.BlockType.PATTERN;
	m_patternO[0][0][1] = self.BlockType.PATTERN;
	m_patternO[0][1][0] = self.BlockType.PATTERN;
	m_patternO[0][1][1] = self.BlockType.PATTERN;

	
	-- angle 90
	m_patternO[1][0][0] = self.BlockType.PATTERN;
	m_patternO[1][0][1] = self.BlockType.PATTERN;
	m_patternO[1][1][0] = self.BlockType.PATTERN;
	m_patternO[1][1][1] = self.BlockType.PATTERN;
	
	-- angle 180
	m_patternO[2][0][0] = self.BlockType.PATTERN;
	m_patternO[2][0][1] = self.BlockType.PATTERN;
	m_patternO[2][1][0] = self.BlockType.PATTERN;
	m_patternO[2][1][1] = self.BlockType.PATTERN;
	
	-- angle 270
	m_patternO[3][0][0] = self.BlockType.PATTERN;
	m_patternO[3][0][1] = self.BlockType.PATTERN;
	m_patternO[3][1][0] = self.BlockType.PATTERN;
	m_patternO[3][1][1] = self.BlockType.PATTERN;
end
-------------------------------------------------------------------------------

-- initialize pattern S
-------------------------------------------------------------------------------
function Game:initializePatternS()
	m_patternS = {};
	for i=0, 3 do
		m_patternS[i] = {};
		for j=0, 3 do
		  m_patternS[i][j] = {};    -- create a new row
		  for k=0,3 do
			m_patternS[i][j][k] = self.BlockType.EMPTY;
		  end
		end
    end
    
	-- angle 0
	m_patternS[0][1][1] = self.BlockType.PATTERN;
	m_patternS[0][1][2] = self.BlockType.PATTERN;
	m_patternS[0][2][0] = self.BlockType.PATTERN;
	m_patternS[0][2][1] = self.BlockType.PATTERN;

	
	-- angle 90
	m_patternS[1][0][0] = self.BlockType.PATTERN;
	m_patternS[1][1][0] = self.BlockType.PATTERN;
	m_patternS[1][1][1] = self.BlockType.PATTERN;
	m_patternS[1][2][1] = self.BlockType.PATTERN;
	
	-- angle 180
	m_patternS[2][0][1] = self.BlockType.PATTERN;
	m_patternS[2][0][2] = self.BlockType.PATTERN;
	m_patternS[2][1][0] = self.BlockType.PATTERN;
	m_patternS[2][1][1] = self.BlockType.PATTERN;
	
	-- angle 270
	m_patternS[3][0][1] = self.BlockType.PATTERN;
	m_patternS[3][1][1] = self.BlockType.PATTERN;
	m_patternS[3][1][2] = self.BlockType.PATTERN;
	m_patternS[3][2][2] = self.BlockType.PATTERN;
end
-------------------------------------------------------------------------------

-- initialize pattern T
-------------------------------------------------------------------------------
function Game:initializePatternT()
	m_patternT = {};
	for i=0, 3 do
		m_patternT[i] = {};
		for j=0, 3 do
		  m_patternT[i][j] = {};    -- create a new row
		  for k=0,3 do
			m_patternT[i][j][k] = self.BlockType.EMPTY;
		  end
		end
    end
    
	-- angle 0
	m_patternT[0][1][0] = self.BlockType.PATTERN;
	m_patternT[0][1][1] = self.BlockType.PATTERN;
	m_patternT[0][1][2] = self.BlockType.PATTERN;
	m_patternT[0][2][1] = self.BlockType.PATTERN;

	
	-- angle 90
	m_patternT[1][0][1] = self.BlockType.PATTERN;
	m_patternT[1][1][0] = self.BlockType.PATTERN;
	m_patternT[1][1][1] = self.BlockType.PATTERN;
	m_patternT[1][2][1] = self.BlockType.PATTERN;
	
	-- angle 180
	m_patternT[2][0][1] = self.BlockType.PATTERN;
	m_patternT[2][1][0] = self.BlockType.PATTERN;
	m_patternT[2][1][1] = self.BlockType.PATTERN;
	m_patternT[2][1][2] = self.BlockType.PATTERN;
	
	-- angle 270
	m_patternT[3][0][1] = self.BlockType.PATTERN;
	m_patternT[3][1][1] = self.BlockType.PATTERN;
	m_patternT[3][1][2] = self.BlockType.PATTERN;
	m_patternT[3][2][1] = self.BlockType.PATTERN;
end
-------------------------------------------------------------------------------

-- initialize pattern Z
-------------------------------------------------------------------------------
function Game:initializePatternZ()
	m_patternZ = {};
	for i=0, 3 do
		m_patternZ[i] = {};
		for j=0, 3 do
		  m_patternZ[i][j] = {};    -- create a new row
		  for k=0,3 do
			m_patternZ[i][j][k] = self.BlockType.EMPTY;
		  end
		end
    end
    
	-- angle 0
	m_patternZ[0][1][0] = self.BlockType.PATTERN;
	m_patternZ[0][1][1] = self.BlockType.PATTERN;
	m_patternZ[0][2][1] = self.BlockType.PATTERN;
	m_patternZ[0][2][2] = self.BlockType.PATTERN;

	
	-- angle 90
	m_patternZ[1][0][1] = self.BlockType.PATTERN;
	m_patternZ[1][1][0] = self.BlockType.PATTERN;
	m_patternZ[1][1][1] = self.BlockType.PATTERN;
	m_patternZ[1][2][0] = self.BlockType.PATTERN;
	
	-- angle 180
	m_patternZ[2][0][0] = self.BlockType.PATTERN;
	m_patternZ[2][0][1] = self.BlockType.PATTERN;
	m_patternZ[2][1][1] = self.BlockType.PATTERN;
	m_patternZ[2][1][2] = self.BlockType.PATTERN;
	
	-- angle 270
	m_patternZ[3][0][2] = self.BlockType.PATTERN;
	m_patternZ[3][1][1] = self.BlockType.PATTERN;
	m_patternZ[3][1][2] = self.BlockType.PATTERN;
	m_patternZ[3][2][1] = self.BlockType.PATTERN;
end
-------------------------------------------------------------------------------


-- get worst pattern (I, J, L, O, S, T, Z)
-- 1 - Arrange the patterns from less useful to more useful as follows: S,Z,O,I,L,J,T
-- 2 - Start with less useful Pattern (S) and check its specific conditions 
-- 		and choose it if it is the worst block for current landed objects otherwise
-- 		go to next pattern (Z)
-- 3- Repeat step 2 for all remaining patterns.
-------------------------------------------------------------------------------
function Game:getWorstPattern()
	
	local worstPattern = nil;
	
	-- fill space info array
	Game:fillLandedSpaceInfo();
	
	if Game:isPatternSWorst() then
		worstPattern = m_patternS;
	elseif Game:isPatternZWorst() then
		worstPattern = m_patternZ;
	elseif Game:isPatternOWorst() then
		worstPattern = m_patternO;
	elseif Game:isPatternIWorst() then
		worstPattern = m_patternI;
	elseif Game:isPatternLWorst() then
		worstPattern = m_patternL;
	elseif Game:isPatternJWorst() then
		worstPattern = m_patternJ;
	else
		worstPattern = m_patternT;
	end	
	
	return worstPattern;
end
-------------------------------------------------------------------------------


-- Checks whether the space block has non-empty patterns above it
-------------------------------------------------------------------------------
function Game:hasPatternsAbove(spaceBlock)
	
	local result = false;
	tempRow = spaceBlock.row;
	while tempRow >= m_board.minRow do
		if m_board.landedBlocks[tempRow][spaceBlock.col]
			~= self.BlockType.EMPTY then
			result = true;
			break;
		end
		tempRow = tempRow - 1;
	end
	
	return result;
end
-------------------------------------------------------------------------------

-- Check the cases that decides whether Pattern S is worst for user current case 
-------------------------------------------------------------------------------
function Game:isPatternSWorst()
	
	local isWorst = true;
	local maxPlayAreaRow = self.BOARD_ROWS - 2; -- exclude bottom wall
	local maxPlayAreaCol = self.BOARD_COLS - 2; -- exclude left and right walls
	local minPlayAreaCol = 1; -- exclude left wall
	
	if m_board.minRow < maxPlayAreaRow then
		local startRow = m_board.minRow;
		local endRow = math.min(startRow + 8, maxPlayAreaRow); 
		for row = startRow, endRow do
			 
			-- case 1
			if m_landedSpaceInfo[row].numSpaces == 1 and
				m_landedSpaceInfo[row].spaces[0].col ~= minPlayAreaCol and 
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[0])
			then
				isWorst = false;
				break;
			end
		
			-- case 2
			-- contiguous two spaces
			if m_landedSpaceInfo[row].numSpaces == 2 and
				(m_landedSpaceInfo[row].spaces[1].col - m_landedSpaceInfo[row].spaces[0].col) == 1 and
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[0]) and 
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[1])
			then
				isWorst = false;
				break;
			end
		end
	end
	
	return isWorst;
end
-------------------------------------------------------------------------------

-- Check the cases that decides whether Pattern Z is worst for user current case 
-------------------------------------------------------------------------------
function Game:isPatternZWorst()
	
	local isWorst = true;
	local maxPlayAreaRow = self.BOARD_ROWS - 2; -- exclude bottom wall
	local maxPlayAreaCol = self.BOARD_COLS - 2; -- exclude left and right walls
	local minPlayAreaCol = 1; -- exclude left wall
	
	if m_board.minRow < maxPlayAreaRow then
		local startRow = m_board.minRow;
		local endRow = math.min(startRow + 8, maxPlayAreaRow); 
		for row = startRow, endRow do
			 
			-- case 1
			if m_landedSpaceInfo[row].numSpaces == 1 and
				m_landedSpaceInfo[row].spaces[0].col ~= maxPlayAreaCol and 
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[0])
			then
				isWorst = false;
				break;
			end
	--[[	
			-- case 2
			-- contiguous two spaces
			if m_landedSpaceInfo[row].numSpaces == 2 and
				(m_landedSpaceInfo[row].spaces[1].col - m_landedSpaceInfo[row].spaces[0].col) == 1 and
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[0]) and
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[1])
			then
				isWorst = false;
				break;
			end
			--]]
		end
	end
	
	return isWorst;
end
-------------------------------------------------------------------------------

-- Check the cases that decides whether Pattern O is worst for user current case 
-------------------------------------------------------------------------------
function Game:isPatternOWorst()
	
	local isWorst = true;
	local maxPlayAreaRow = self.BOARD_ROWS - 2; -- exclude bottom wall
	local maxPlayAreaCol = self.BOARD_COLS - 2; -- exclude left and right walls
	local minPlayAreaCol = 1; -- exclude left wall
	
	if m_board.minRow < maxPlayAreaRow then
		local startRow = m_board.minRow;
		local endRow = maxPlayAreaRow; 
		local averageSpacesPerRow = 0;
		local totalSpaces = 0;
		
		for row = startRow, endRow do
			totalSpaces = totalSpaces + m_landedSpaceInfo[row].numSpaces;
		end	
		
		averageSpacesPerRow = totalSpaces / (endRow - startRow + 1);
		if averageSpacesPerRow < ((self.BOARD_COLS - 2)  / 2) then
			-- case 1
			isWorst = false;
		else
			for row = startRow, endRow do
				-- case 2
				-- contiguous two spaces
				if m_landedSpaceInfo[row].numSpaces == 2 and
					(m_landedSpaceInfo[row].spaces[1].col - m_landedSpaceInfo[row].spaces[0].col) == 1 and
					not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[0]) and
					not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[1])
				then
					isWorst = false;
					break;
				end
			
			end
		end
	end
	
	return isWorst;
end
-------------------------------------------------------------------------------

-- Check the cases that decides whether Pattern I is worst for user current case 
-------------------------------------------------------------------------------
function Game:isPatternIWorst()
	
	local isWorst = true;
	local maxPlayAreaRow = self.BOARD_ROWS - 2; -- exclude bottom wall
	local maxPlayAreaCol = self.BOARD_COLS - 2; -- exclude left and right walls
	local minPlayAreaCol = 1; -- exclude left wall
	
	if m_board.minRow < maxPlayAreaRow then
		local startRow = m_board.minRow;
		local endRow = maxPlayAreaRow; 
		for row = startRow, endRow do
			 
			-- case 1
			if m_landedSpaceInfo[row].numSpaces == 1 and
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[0]) and
				(row - startRow) >= 2
			then
				isWorst = false;
				break;
			end
		
		--[[
			-- case 2
			-- horizontal four spaces
			if m_landedSpaceInfo[row].numSpaces == 4 and
				(m_landedSpaceInfo[row].spaces[1].col - 
					m_landedSpaceInfo[row].spaces[0].col) == 1 and
					(m_landedSpaceInfo[row].spaces[2].col - 
					m_landedSpaceInfo[row].spaces[1].col) == 1 and
					(m_landedSpaceInfo[row].spaces[3].col - 
					m_landedSpaceInfo[row].spaces[2].col) == 1
			then
				isWorst = false;
				break;
			end
			--]]
		end
	end
	
	return isWorst;
end
-------------------------------------------------------------------------------

-- Check the cases that decides whether Pattern L is worst for user current case 
-------------------------------------------------------------------------------
function Game:isPatternLWorst()
	
	local isWorst = true;
	local maxPlayAreaRow = self.BOARD_ROWS - 2; -- exclude bottom wall
	local maxPlayAreaCol = self.BOARD_COLS - 2; -- exclude left and right walls
	local minPlayAreaCol = 1; -- exclude left wall
	
	if m_board.minRow < maxPlayAreaRow then
		local startRow = m_board.minRow;
		local endRow = math.min(startRow + 3, maxPlayAreaRow); 
		for row = startRow, endRow do
			 
			-- case 1
			if m_landedSpaceInfo[row].numSpaces == 1 and
				m_landedSpaceInfo[row].spaces[0].col > 1 and
				(row - startRow) <= 1 and
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[0])
			then
				isWorst = false;
				break;
			end
		
			-- case 2
			-- contiguous two spaces
			if m_landedSpaceInfo[row].numSpaces == 2 and
				(m_landedSpaceInfo[row].spaces[1].col - m_landedSpaceInfo[row].spaces[0].col) == 1 and
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[0]) and
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[1])
			then
				isWorst = false;
				break;
			end
			
			-- case 3
			-- contiguous three spaces
			if m_landedSpaceInfo[row].numSpaces == 3 and
				(m_landedSpaceInfo[row].spaces[1].col - m_landedSpaceInfo[row].spaces[0].col) == 1 and
				(m_landedSpaceInfo[row].spaces[2].col - m_landedSpaceInfo[row].spaces[1].col) == 1
			then
				isWorst = false;
				break;
			end
		end
	end
	
	return isWorst;
end
-------------------------------------------------------------------------------

-- Check the cases that decides whether Pattern J is worst for user current case 
-------------------------------------------------------------------------------
function Game:isPatternJWorst()
	
	local isWorst = true;
	local maxPlayAreaRow = self.BOARD_ROWS - 2; -- exclude bottom wall
	local maxPlayAreaCol = self.BOARD_COLS - 2; -- exclude left and right walls
	local minPlayAreaCol = 1; -- exclude left wall
	
	if m_board.minRow < maxPlayAreaRow then
		local startRow = m_board.minRow;
		local endRow = math.min(startRow + 3, maxPlayAreaRow); 
		for row = startRow, endRow do
		--[[	 
			-- case 1
			if m_landedSpaceInfo[row].numSpaces == 1 and
				m_landedSpaceInfo[row].spaces[0].col < maxPlayAreaCol and
				(row - startRow) <= 1 and
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[0])
			then
				isWorst = false;
				break;
			end
		
			-- case 2
			-- contiguous two spaces
			if m_landedSpaceInfo[row].numSpaces == 2 and
				(m_landedSpaceInfo[row].spaces[1].col - m_landedSpaceInfo[row].spaces[0].col) == 1 and
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[0]) and
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[1])
			then
				isWorst = false;
				break;
			end
			--]]
			-- case 3
			-- contiguous three spaces
			if m_landedSpaceInfo[row].numSpaces == 3 and
				(m_landedSpaceInfo[row].spaces[1].col - m_landedSpaceInfo[row].spaces[0].col) == 1 and
				(m_landedSpaceInfo[row].spaces[2].col - m_landedSpaceInfo[row].spaces[1].col) == 1 and
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[0]) and
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[1]) and
				not Game:hasPatternsAbove(m_landedSpaceInfo[row].spaces[2])
			then
				isWorst = false;
				break;
			end
		end
	end
	
	return isWorst;
end
-------------------------------------------------------------------------------

-- gets a list of empty blocks for a specific landed row and then
-- fills the global spaces array to be used by worst block functions
-------------------------------------------------------------------------------
function Game:fillLandedSpaceInfo()
	
	m_landedSpaceInfo = {}; -- clear space info

	for row = m_board.minRow, self.BOARD_ROWS - 2 do
		m_landedSpaceInfo[row] = {};
		m_landedSpaceInfo[row].numSpaces = 0;
		m_landedSpaceInfo[row].spaces = {};
		for col = 1, self.BOARD_COLS - 2 do
			if m_board.landedBlocks[row][col] == self.BlockType.EMPTY
			then
				m_landedSpaceInfo[row].numSpaces = m_landedSpaceInfo[row].numSpaces + 1;
				m_landedSpaceInfo[row].spaces[m_landedSpaceInfo[row].numSpaces - 1] = {};
				m_landedSpaceInfo[row].spaces[m_landedSpaceInfo[row].numSpaces - 1].row = row;
				m_landedSpaceInfo[row].spaces[m_landedSpaceInfo[row].numSpaces - 1].col = col;
			end
		end
	end
	
end
-------------------------------------------------------------------------------


-- get average rating ( lowest = worst)
-------------------------------------------------------------------------------
--[[function Game:getPatternAverageRating(pattern)
	
	local startRow = math.min(m_board.minRow, self.BOARD_ROWS - 5);
	local endRow = math.min(startRow + 3, self.BOARD_ROWS - 2); -- exclude bottom wall
	local patternAverageRating = {}
	
	for rotationIndex = 0, 3 do
		patternAverageRating[rotationIndex] = 0;
		for startCol = 1, self.BOARD_COLS - 3 - 2 do -- exclude left and right walls
			local i = 0; -- for relative pattern indexing
			for row = startRow, endRow do 
				local j = 0; -- for relative pattern indexing
				local endCol = startCol + 3;
				for col = startCol, endCol do
					if m_board.landedBlocks[row][col] == pattern[rotationIndex][i][j] and
					pattern[rotationIndex][i][j] == self.BlockType.EMPTY
					then
						patternAverageRating[rotationIndex] = 
							patternAverageRating[rotationIndex] + 1;
					end
				j = j + 1;
				end
				i = i + 1;
			end
		end	
	end
	
	return (patternAverageRating[0] +
			patternAverageRating[1] +
			patternAverageRating[2] +
			patternAverageRating[3]) / 4.0;
end
--]]
-------------------------------------------------------------------------------