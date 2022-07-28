import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/animation"

-- Constants.
local geo <const> = playdate.geometry
local anim <const> = playdate.graphics.animator

-- Class definition.
class('Car').extends(playdate.graphics.sprite)

function Car:init( x, y, x2, y2, animationTime)
    Car.super.init(self)

    local car =  playdate.graphics.image.new("images/driver-small")
    self:setImage(car:invertedImage())

    self:setCollideRect( 0, 0, self:getSize())

    local segment = geo.lineSegment.new(x, y, x2, y2)
    local animator = anim.new(animationTime, segment, playdate.easingFunctions.linear)

    self:moveTo(x, y)
    self:add()

    self:setAnimator(animator)
    self:moveTo(x2, y2)

    playdate.timer.new(animationTime, 
        function ()
            self:remove()
        end
    )
end