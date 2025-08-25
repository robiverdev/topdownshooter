function love.load()
    -- Seed random number generator for unpredictable zombie spawning
    math.randomseed(os.time())

    -- Load all game images into sprites table
    sprites = {}
    sprites.background = love.graphics.newImage('sprites/background.png')
    sprites.bullet = love.graphics.newImage('sprites/bullet.png')
    sprites.player = love.graphics.newImage('sprites/player.png')
    sprites.zombie = love.graphics.newImage('sprites/zombie.png')

    -- Set up player starting position (center of screen) and movement speed
    player = {}
    player.x = love.graphics.getWidth() /2
    player.y = love.graphics.getHeight() / 2
    player.speed = 180

    -- Create font for displaying text
    font = love.graphics.newFont(30)
    
    -- Initialize empty tables to store zombies and bullets
    zombies = {}
    bullets = {}

    -- Game state: 1 = menu/start screen, 2 = playing
    gameState = 1
    score = 0
    
    -- Timer system for zombie spawning
    maxTime = 2        -- Time between zombie spawns (gets faster over time)
    timer = maxTime    -- Current countdown timer
end

function love.update(dt)
    -- Only allow player movement when actually playing (gameState 2)
    if gameState == 2 then
        -- Player movement using WASD keys
        if love.keyboard.isDown("d") and player.x < love.graphics.getWidth() then
            player.x = player.x + player.speed*dt
        end

        if love.keyboard.isDown("a") and player.x > 0 then
            player.x = player.x - player.speed*dt
        end

        if love.keyboard.isDown("w") and player.y > 0 then
            player.y = player.y - player.speed*dt
        end

        if love.keyboard.isDown("s") and player.y <= love.graphics.getHeight() then
            player.y = player.y + player.speed*dt
        end
    end

    -- Update zombie positions - make them move toward the player
    for i, z in ipairs(zombies) do
        z.x = z.x + (math.cos(zombiePlayerAngle(z)) * z.speed * dt)
        z.y = z.y + (math.sin(zombiePlayerAngle(z)) * z.speed * dt)

        -- Check if zombie touched player (collision detection)
        if distanceBetween(z.x, z.y, player.x, player.y) < 30 then
            -- Game over: clear all zombies and reset to menu
            for i,z in ipairs(zombies) do
                zombies[i] = nil
                gameState = 1
                player.x = love.graphics.getWidth() / 2
                player.y = love.graphics.getHeight() / 2
             end
         end
    end

    -- Update bullet positions - make them fly in the direction they were shot
    for i,b in ipairs(bullets) do
        b.x = b.x + (math.cos(b.direction) * b.speed * dt)
        b.y = b.y + (math.sin(b.direction) * b.speed * dt)
    end

    -- Remove bullets that have gone off screen (cleanup)
    for i = #bullets, 1, -1 do 
        local b = bullets[i]
        if b.x < 0 or b.y < 0 or b.x > love.graphics.getWidth() or b.y > love.graphics.getHeight() then
            table.remove(bullets, i)
        end
    end

    -- Check for bullet-zombie collisions
    for i, z in ipairs(zombies) do
        for j, b in ipairs(bullets) do
            if distanceBetween(z.x, z.y, b.x, b.y) < 20 then
                -- Mark both zombie and bullet for removal
                z.dead = true
                b.dead = true
                score = score + 1  -- Increase score
            end
        end
    end

    -- Remove dead zombies from the game
    for i = #zombies, 1, -1 do
        local z = zombies[i]
        if z.dead == true then 
            table.remove(zombies, i)
        end
    end

    -- Remove "dead" bullets from the game
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        if b.dead == true then
            table.remove(bullets, i)
        end
    end

    -- Zombie spawning timer (only during gameplay)
    if gameState == 2 then
        timer = timer - dt  -- Countdown timer
        if timer <= 0 then
            spawnZombie()           -- Create a new zombie
            maxTime = 0.95 * maxTime  -- Make next spawn slightly faster
            timer = maxTime         -- Reset timer
        end
    end
end

function love.draw()
    -- Draw background image
    love.graphics.draw(sprites.background, 0, 0 )

    -- Show start screen instructions
    if gameState == 1 then
        love.graphics.setFont(font)
        love.graphics.printf("Click anywhere to begin", 0, 50, love.graphics.getWidth(), "center")
    end

    -- Always show current score
    love.graphics.printf("Score: " .. score, 0, love.graphics.getHeight() - 100, love.graphics.getWidth(), "center")

    -- Draw player sprite, rotated to face mouse cursor
    love.graphics.draw(sprites.player, player.x, player.y, playerMouseAngle(), nil, nil, sprites.player:getWidth()/2, sprites.player:getHeight()/2)

    -- Draw all zombies, rotated to face the player
    for i, z in ipairs(zombies) do
        love.graphics.draw(sprites.zombie, z.x, z.y, zombiePlayerAngle(z), nil, nil, sprites.zombie:getWidth()/2, sprites.zombie:getHeight()/2)
    end

    -- Draw all bullets (scaled down to 25% size)
    for i, b in ipairs(bullets) do
        love.graphics.draw(sprites.bullet, b.x, b.y, nil, 0.25, nil, sprites.bullet:getWidth()/2, sprites.bullet:getHeight()/2)
    end
end

function love.keypressed(key)
    if key == "space" then
        spawnZombie()  -- Debug: spawn zombie manually with spacebar
    end
end

function love.mousepressed(x,y,button)
    if button == 1 and gameState == 2 then
        -- Left click during gameplay: shoot bullet
        spawnBullet()
    elseif button == 1 and gameState == 1 then
        -- Left click on menu: start the game
        gameState = 2
        maxTime = 2
        timer = maxTime
        score = 0
    end
end

-- Calculate angle from player to mouse cursor (for player rotation)
function playerMouseAngle()
    -- Add math.pi to flip the sprite so it faces the correct direction
    return math.atan2(player.y - love.mouse.getY(), player.x - love.mouse.getX()) + math.pi
end

-- Calculate angle from zombie to player (for zombie rotation and movement)
function zombiePlayerAngle(enemy)
    return math.atan2(player.y - enemy.y, player.x - enemy.x)
end

-- Create a new zombie at a random position outside the screen
function spawnZombie()
   local zombie = {}

   -- Randomly choose which side of screen to spawn from (1=left, 2=right, 3=top, 4=bottom)
   local side = math.random(1, 4)

   if side == 1 then
    -- Spawn on left side
    zombie.x = -30
    zombie.y = math.random(0, love.graphics.getHeight())
   elseif side == 2 then 
    -- Spawn on right side
    zombie.x = love.graphics.getWidth() + 30
    zombie.y = math.random(0, love.graphics.getHeight())
   elseif side == 3 then
    -- Spawn on top
    zombie.x = math.random(0, love.graphics.getWidth())
    zombie.y = -30
   elseif side == 4 then
    -- Spawn on bottom
    zombie.x = math.random(0, love.graphics.getWidth())
    zombie.y = love.graphics.getHeight() + 30
   end

   -- Set zombie properties
   zombie.speed = 140
   zombie.dead = false
   
   -- Add zombie to the zombies table
   table.insert(zombies, zombie)
end

-- Create a new bullet at player's position, flying toward mouse cursor
function spawnBullet()
    local bullet = {}
    bullet.x = player.x           -- Start at player position
    bullet.y = player.y
    bullet.speed = 500            -- Bullet flies fast
    bullet.dead = false
    bullet.direction = playerMouseAngle()  -- Fly toward where mouse is pointing
    
    -- Add bullet to the bullets table
    table.insert(bullets, bullet)
end

-- Helper function to calculate distance between two points
function distanceBetween(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end