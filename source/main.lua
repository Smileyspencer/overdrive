import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/math"
import "CoreLibs/ui"
import "CoreLibs/timer"
import "CoreLibs/animator"
import "CoreLibs/utilities/where"

-- Personal modules.
import 'car'
import 'driver'

-- Packages.
local pd <const> = playdate
local gfx <const> = playdate.graphics
local ui <const> = playdate.ui
local geo <const> = playdate.geometry

-- Constants.
local background <const> = gfx.image.new("images/roadway-small")

local screenCenter <const> = 202
local laneInterval <const> = 52

local shortAnimation <const> = 1000
local mediumAnimation <const> = 1250
local longAnimation <const> = 1500
local veryLongAnimation <const> = 2500
local veryVeryLongAnimation <const> = 5500

minimumLane = -3
maximumLane = 3

-- Properties.
local currentAcceleration = 0
local maxAcceleration = 12

local currentOffset = 0
local maxOffset = 240

local carGenerationThreshold = 99

local animationTime = 500

local driver = nil

local occupiedLanes = {}

local score = 0

local gameOver = 0

-- Debug flags.
local debugCrank = false
local debugDirection = false

---- Prepare functions.

-- Background redraw callback.
function refreshBackground( x, y, width, height )
    if gameOver == 0 then
        gfx.setClipRect( x, y, width, height )
        background:draw( 0, currentOffset - maxOffset )
        background:draw( 0, currentOffset )
        gfx.clearClipRect()

        -- If we need to display the crank indicator to the user, we do so here.
        if pd.isCrankDocked() or currentAcceleration < 2 then
            ui.crankIndicator:update()
        end

        -- Swap image mode for text.
        gfx.setImageDrawMode(playdate.graphics.kDrawModeInverted)
        local text = gfx.drawTextAligned("*" .. score .."*", 400 - 48, 8, kTextAlignment.left)
        gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)
    else
        local text = gfx.drawTextAligned("Final score: *" .. score .."*\n Press \'A\' to restart.", 200, 120, kTextAlignment.center)
        playdate.graphics.sprite.removeAll()
    end
end

-- Prepares everything needed as the game begins.
function setUp()
    -- Set the sprite background drawing callback.
    gfx.sprite.setBackgroundDrawingCallback(refreshBackground)

    -- Set up the crank indicator so it's ready if needed.
    ui.crankIndicator:start()

    -- Create a seed for random generator.
    math.randomseed(pd.getSecondsSinceEpoch())

    driver = Driver()
end

---- Application (Called as application kicks off).
setUp()

---- Callbacks.

-- Updates the game regularly per frame.
function playdate.update()

    if gameOver == 1 then
        -- Need to remove all timers before continuing.
        pd.timer.updateTimers()
        return
    end

    if pd.isCrankDocked() then
        -- print("Crank was docked.")
    end

    local collisions = gfx.sprite.allOverlappingSprites()

    for i = 1, #collisions do
        local collisionPair = collisions[i]
        local sprite1 = collisionPair[1]
        local sprite2 = collisionPair[2]

        if sprite1:isa(Car) then
            sprite1:remove()
        elseif sprite2:isa(Car) then
            sprite2:remove()
        end

        if sprite1:isa(Driver) or sprite2:isa(Driver) then
            gameOver = 1
        end
        
        if sprite1:isa(Driver) or sprite2:isa(Driver) then
            print("Collision")
            gameOver = 1
        end
    end

    local randomTo100 = math.random(100)
    local randomLane = math.random(minimumLane, maximumLane)
    if randomTo100 > carGenerationThreshold then
        if isLaneOccupied(randomLane) == 0 then
            addCar(randomLane, getCarDirection())
        end
    end

    gfx.sprite.redrawBackground()
    gfx.sprite.update()
    pd.timer.updateTimers()
end

-- Updates as the player moves the crank.
function pd.cranked(change, acceleratedChange)
    local normalizedInput = math.floor(acceleratedChange)

    -- Normalize input.
    if normalizedInput < 0 then
        currentAcceleration = 0
    elseif normalizedInput > maxAcceleration then
        currentAcceleration = maxAcceleration
    else 
        currentAcceleration = normalizedInput
    end

    if currentAcceleration < maxAcceleration * .25 then
        animationTime = shortAnimation
    elseif currentAcceleration > maxAcceleration * .75 then
        animationTime = mediumAnimation
    else 
        animationTime = longAnimation
    end

    -- Adjust offset for background.
    if currentOffset < maxOffset then
        currentOffset = currentOffset + currentAcceleration
    else
        currentOffset = 0
    end

    -- Debug the crank if necessary.
    if debugCrank then
        print("CRANK BREAKDOWN")
        print("Normalized Acceleration: " .. normalizedInput)
        print("Final Acceleration: " .. currentAcceleration)
        print("\n\n")
    end

end

    -- The slower you go the more likely cars are to pass you, the faster, the more you're likely to pass cars.
function getCarDirection()

    -- Get % of max speed. 
    local percent = tonumber(currentAcceleration) / tonumber(maxAcceleration)

    -- Normalize that to a value. 
    local chanceValue = percent * 100

    -- Generate a random number in range. 
    local randomValue = math.random(100)

    -- If the generated value is greater than the threshold the car in question should be faster than the driver, else slower.
    if randomValue > chanceValue then
        randomDirection = 1
    else
        randomDirection = 0
    end

    if debugDirection then
        print("RANDOM BREAKDOWN")
        print("Percentage of max:" .. percent)
        print("\n\n")
    end

    return randomDirection
end



function pd.leftButtonDown()
    if currentAcceleration > 0 then
        driver:move(-1)
    end
end

function pd.rightButtonDown()
    if currentAcceleration > 0 then
        driver:move(1)
    end
end

function pd.AButtonDown()
    if gameOver == 1 then
        gameOver = 0
        setUp()
        score = 0
    end
end


function addCar(lane, direction)
    local xPosition = screenCenter + laneInterval * lane

    local start = 0
    local stop = 0
    if direction > 0 then
        start = 240
        stop = 0
    else
        start = 0
        stop = 240
    end

    if animationTime == longAnimation and stop == 240 then
        animationTime = veryLongAnimation
    elseif animationTime == shortAnimation and stop == 240 then
        animationTime = veryVeryLongAnimation
    end

    table.insert(occupiedLanes, lane)
    local laneTimer = pd.timer.new(animationTime, 
        function ()
            table.remove(occupiedLanes, findLane(lane))
            carPassed()
        end
    )

    Car(xPosition, start, xPosition, stop, animationTime)
end

function carPassed()
    print(where())
    if gameOver == 0 then
        score = score + 1
        print("Increased score")
    else
        score = 0
    end

    print(score)
    
end
function isLaneOccupied(lane)
    local result = 0
    for i = 1, #occupiedLanes do
        if occupiedLanes[i] == lane then
            result = 1
        end
    end
    return result
end

function findLane(lane)
    local result = -1
    for i = 1, #occupiedLanes do
        if occupiedLanes[i] == lane then
            result = i
        end
    end
    return result
end

