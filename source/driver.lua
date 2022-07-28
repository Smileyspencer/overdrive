import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/animation"

-- Packages.
local gfx <const> = playdate.graphics
local geo <const> = playdate.geometry

-- Constants.
local laneInterval <const> = 52
local yPosition <const> = 120
local screenCenter <const> = 202

-- Properties.
local position = 0

-- Class definition.
class('Driver').extends(playdate.graphics.sprite)

function Driver:init()
    Driver.super.init(self)

    position = 0

    local driverImage <const> = gfx.image.new("images/driver-small")
    self:setImage(driverImage:invertedImage())

    self:setCollideRect( 0, 0, self:getSize())

    -- Set position for the car. 
    self:moveTo(screenCenter, yPosition)
    self:add()
end

function Driver:move(change)
    -- If you can't move further, do not continue.
    if position + change < minimumLane or position + change > maximumLane then
        return
    end

    -- Calculate position prioer to change.
    local positionBeforePress = position

    -- Calculate and set position after change.
    position = positionBeforePress + change

    -- Create a line from current to new position.
    local startingPosition = screenCenter + positionBeforePress * laneInterval
    local endingPosition = screenCenter + position * laneInterval
    local segment = geo.lineSegment.new(startingPosition, yPosition, endingPosition, yPosition)

    -- Create a new animator for the line.
    local animator = gfx.animator.new(100, segment, playdate.easingFunctions.linear)
    self:setAnimator(animator)

    -- Move the player
    self:moveTo(endingPosition, yPosition)
end