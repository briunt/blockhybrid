local piece = {}
piece.__index = piece

function piece.new()
    local p = {}
    setmetatable(p, piece)

    return p
end

-- resets the piece
function piece:reset()
    -- randomly select a piece to create
    self.index = math.random(1, #piecedata)

    -- randomly select a rotation
    self.rotation = math.random(1, #piecedata[self.index].data)
    
    -- set a position
    self.x = math.random(1, config.board.width - #piecedata[self.index].data[self.rotation][1])
    self.y = 0

    -- general move flag
    self.atbottom = false
    self.bottomcounter = 0

    -- downward movement stuff
    self.counter = 0
    self.downflag = false

    -- sideways movement stuff
    self.sidecounter = 0
    self.canmove = true

    -- rotation stuff
    self.rotatecounter = 0
    self.canrotate = true

    -- reset flag
    self.resetflag = false
    self.resetcounter = 0
end

-- updates the position and checks for collision with board...
function piece:update(dt)
    if self.resetflag then
        self.resetcounter = self.resetcounter + dt
        if self.resetcounter >= config.pieces.spawn then
            self:reset()
        end
    else
        -- get piece to check
        local p = piecedata[self.index].data[self.rotation]

        -- SIDEWAYS MOVEMENT
        local m = 0

        if not(self.canmove) then
            -- timer until you can move
            self.sidecounter = self.sidecounter + dt
            if self.sidecounter >= config.pieces.sidespeed then
                self.canmove = true
                self.sidecounter = 0
            end
        else
            -- get input (only if you aren't already on an edge)
            if love.keyboard.isDown("left") and self.x > 0 then
                m = -1
                self.canmove = false
            elseif love.keyboard.isDown("right") and self.x < config.board.width - #piecedata[self.index].data[self.rotation][1] then
                m = 1
                self.canmove = false
            end
        end

        -- loop through the piece if it can move side to side
        for j=1, #p, 1 do
            for i=1, #p[j], 1 do
                if p[j][i] then
                    -- see if we are trying to move sideways or not.. if so then check for a collision
                    local x = i + self.x + m
                    local y = j + self.y
                    if board.board[x][y].used then
                        -- there is something already there, negate the movement
                        m = 0
                    end
                end
            end
        end

        -- reset the bottom counter if you have moved
        if not(m == 0) then
            self.bottomcounter = 0
        end

        -- move the peice left/right
        self.x = self.x + m

        local y = 1

        -- loop through the piece and see if anything is below it
        self.atbottom = false
        for j=1, #p, 1 do
            for i=1, #p[j], 1 do
                if p[j][i] then
                    -- position to check on board
                    local x = i+self.x
                    local y = j+self.y+1
                    if board.board[x][y].used then
                        self.atbottom = true
                        y = 0
                    end
                end
            end
        end

        if not(self.atbottom) then    
            -- move the piece down
            self.counter = self.counter + dt
            if self.counter >= config.pieces.speed then
                self.counter = self.counter - config.pieces.speed
                self.y = self.y + y
            end            
        else
            self.bottomcounter = self.bottomcounter + dt
            if self.bottomcounter >= config.pieces.bottomspeed then
                -- found a hit, flag for removal
                self.remove = true
                -- add piece to board
                board:add(self.x, self.y, p, piecedata[self.index].colour)
                -- flag piece to be reset
                self.resetflag = true
                if self.y == config.board.loseline then
                    lost = true
                end
            end
        end
    end
end

function piece:drawShadow()
    -- set piece data
    local p = piecedata[self.index].data[self.rotation]
    local s = piecedata[self.index].shadowoffset[self.rotation]    
    -- get and set colour
    local c = {piecedata[self.index].colour[1],piecedata[self.index].colour[2],piecedata[self.index].colour[3],piecedata[self.index].colour[4]}
    c[4] = 0.25
    love.graphics.setColor(c)
    -- calc rectangle
    local x = (self.x) * config.board.size
    local y = (self.y + s) * config.board.size
    local w = #p[1] * config.board.size
    local h = (config.board.height - self.y - s) * config.board.size
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(1,1,1,1)
end

function piece:draw()
    -- draw the piece!
    local p = piecedata[self.index].data[self.rotation]
    for j=1, #p, 1 do
        for i=1, #p[j] do
            if p[j][i] then
                love.graphics.setColor(piecedata[self.index].colour)
                local x = (i-1+self.x) * config.board.size
                local y = (j-1+self.y) * config.board.size
                love.graphics.rectangle("fill", x, y, config.board.size, config.board.size)
            end
        end
    end
    love.graphics.setColor(1,1,1,1)
end

-- moves the piece left/right if you can
-- used in the keypressed based movement which doesn't feel as good as the timer based one.
-- function piece:move(m)
--     if not(self.resetflag) then
--         -- get piece to check
--         local p = piecedata[self.index].data[self.rotation]

--         -- loop through the piece if it can move side to side
--         for j=1, #p, 1 do
--             for i=1, #p[j], 1 do
--                 if p[j][i] then
--                     -- see if we are trying to move sideways or not.. if so then check for a collision
--                     local x = i + self.x + m
--                     local y = j + self.y
--                     if board.board[x][y].used then
--                         -- there is something already there, negate the movement
--                         m = 0
--                     end
--                 end
--             end
--         end

--         -- reset the bottom counter if you have moved
--         if not(m == 0) then
--             self.bottomcounter = 0
--         end

--         -- move the peice left/right
--         self.x = self.x + m
--     end
-- end

function piece:rotate()
    -- check if we can rotate it by looking at next piece
    local r = 1

    -- get ref to layout of rotated piece
    local temprotation = self.rotation + r
    if temprotation > #piecedata[self.index].data then
        temprotation = 1
    end
    p = piecedata[self.index].data[temprotation]
    local tx = self.x
    local ty = self.y

    -- need to test if the piece is bigger than available board... if so then push it up/back 1
    if tx + #p[1] > config.board.width then
        tx = tx - (#p[1] - (config.board.width - tx))
    end
    -- -1 because the last line of the board is used already
    if ty + #p > config.board.height-1 then
        ty = ty - (#p - (config.board.height-1 - ty))
    end

    -- see if any of the piece overlaps with the board
    for j=1, #p, 1 do
        local brk = false
        for i=1, #p[j], 1 do
            if p[j][i] then
                local x = i+tx
                local y = j+ty
                if board.board[x][y].used then
                    -- found an overlap - exit
                    brk = true
                    r = 0
                    break
                end
            end
        end
        if brk then
            break
        end
    end

    -- reset the bottom counter if you have moved
    if not(r == 0) then
        self.bottomcounter = 0
        self.x = tx
        self.y = ty
    end

    -- rotate
    self.rotation = self.rotation + r
    if self.rotation > #piecedata[self.index].data then
        self.rotation = 1
    end
end

-- drop the piece!
function piece:drop()
    local p = piecedata[self.index].data[self.rotation]

    -- determine y position of piece

end

return piece