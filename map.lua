local G = love.graphics




local function rayBoxIntersection(ox, oy, dx, dy, box)

	if dx > 0 and ox <= box[1] then
		local f = (box[1] - ox) / dx
		local y = oy + dy * f
		if box[2] <= y and y <= box[2] + box[4] then
			return f
		end
	elseif dx < 0 and ox >= box[1] + box[3] then
		local f = (box[1] + box[3] - ox) / dx
		local y = oy + dy * f
		if box[2] <= y and y <= box[2] + box[4] then
			return f
		end
	end

	if dy > 0 and oy <= box[2] then
		local f = (box[2] - oy) / dy
		local x = ox + dx * f
		if box[1] <= x and x <= box[1] + box[3] then
			return f
		end
	elseif dy < 0 and oy >= box[2] + box[4] then
		local f = (box[2] + box[4] - oy) / dy
		local x = ox + dx * f
		if box[1] <= x and x <= box[1] + box[3] then
			return f
		end
	end

	return false
end







Map = Object:new {
	boxes = {
		{ 0, 200, 400, 40 },
		{ 200, 150, 30, 30 },
		{ 160, 180, 20, 20 },
		{ 120, 120, 50, 5 },
		{ 250, 70, 20, 20 },

		{ 80, 90, 20, 20 },

		{ 360, 120, 30, 60 },

		{ 310, 60, 20, 20 },
		{ 100, 0, 200, 15 },
	}
}

function Map:init()

end
function Map:collision(box, axis)
	local d = 0
	for i, b in ipairs(self.boxes) do
		local e = collision(box, b, axis)
		if math.abs(e) > math.abs(d) then d = e end
	end
	return d
end

function Map:rayIntersection(ox, oy, dx, dy)
	local d = nil
	for i, b in ipairs(self.boxes) do
		local e = rayBoxIntersection(ox, oy, dx, dy, b)
		if e and (not d or e < d) then d = e end
	end
	return d
end


function Map:draw()
	G.setColor(200, 100, 100)
	for i, b in ipairs(self.boxes) do
		G.rectangle("fill", unpack(b))
	end
end
