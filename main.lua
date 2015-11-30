require("helper")

local G = love.graphics

love.window.setMode(1200, 720)
G.setDefaultFilter("nearest")
local screen = G.newCanvas(400, 240)


require("map")
require("guy")





map = Map()
guy = Guy()



function love.update()

	guy:update()
end


function love.draw()

	screen:renderTo(function()
		G.clear(0, 0, 0)

		map:draw()
		guy:draw()

	end)

--	G.clear(10, 10, 10)

	G.setColor(255, 255, 255)

	local rx = G.getWidth() / 400
	local ry = G.getHeight() / 240
	if rx < ry then
		G.draw(screen, 0, (G.getHeight() - rx * 240) / 2, 0, rx)
	else
		G.draw(screen, (G.getWidth() - ry * 400) / 2, 0, 0, ry)
	end
end
