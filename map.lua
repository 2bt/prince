local G = love.graphics





Map = Object:new {
	img = G.newImage("tiles.png"),
	boxes = {

		{ 0, -8, 400, 16 },
		{ 0, 208, 400, 40 },
		{ 160, 120, 24, 40 },
		{ 128, 144, 32, 16 },
		{ 200, -8, 16, 80 },
		{ 368, 96, 32, 24 },
		{ 280, 56, 32, 16 },
		{ 0, 128, 24, 120 },

		{ 64, 192, 16, 56 },
		{ 264, 192, 40, 56 },

		{ 264, 128, 40, 4, ow=true },
		{ 96, 72, 40, 4, ow=true },
		{ 264, 160, 40, 4, ow=true },
		{ 368, 64, 32, 4, ow=true },
		{ 72, 160, 40, 4, ow=true },


	}
}
genQuads(Map, 8)
function Map:init()

end
function Map:collision(box, axis, dy)
	local d = 0
	for i, b in ipairs(self.boxes) do

		if b.ow and dy ~= "cliff" then
			if axis == "y" and dy then
				if box[2] + box[4] > b[2]
				and box[2] + box[4] - dy - 0.01 <= b[2]
				and box[1] + box[3] > b[1] and box[1] < b[1] + b[3] then

					local e = -(box[2] + box[4] - b[2])
					if math.abs(e) > math.abs(d) then d = e end

				end
			end
		else
			local e = collision(box, b, axis)
			if math.abs(e) > math.abs(d) then d = e end

		end
	end
	return d
end

function Map:rayIntersection(ox, oy, dx, dy)
	local d = nil
	for i, b in ipairs(self.boxes) do
		if not b.ow then

			local e = rayBoxIntersection(ox, oy, dx, dy, b)
			if e and (not d or e < d) then d = e end
		end
	end
	return d
end



function Map:draw()
	for i, b in ipairs(self.boxes) do

		if b.ow then
			G.setColor(255, 255, 255)
			for x = b[1], b[1] + b[3] - 1, 8 do
				G.draw(self.img, self.quads[1], x, b[2])
			end

		else

--			G.setColor(200, 100, 100)
--			G.rectangle("fill", unpack(b))
			G.setColor(255, 255, 255)



			local iy2 = b[4]/8 - 1
			local ix2 = b[3]/8 - 1

			for iy = 0, iy2  do
				local y = b[2] + iy * 8
				for ix = 0, ix2  do
					local x = b[1] + ix * 8


					local m = 68 + bool[0 < ix] + bool[ix == ix2]
					m = m + bool[0 < iy]*32 + bool[iy == iy2]*32

					G.draw(self.img, self.quads[m], x, y)


				end
			end



		end


	end
end
