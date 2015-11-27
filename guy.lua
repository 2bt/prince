local G = love.graphics
local D = love.keyboard.isDown


function collision(a, b, axis)
	if a[1] >= b[1] + b[3]
	or a[2] >= b[2] + b[4]
	or a[1] + a[3] <= b[1]
	or a[2] + a[4] <= b[2] then
		return 0
	end

	local dx = b[1] + b[3] - a[1]
	local dx2 = b[1] - a[1] - a[3]

	local dy = b[2] + b[4] - a[2]
	local dy2 = b[2] - a[2] - a[4]

	if axis == "x" then
		return math.abs(dx) < math.abs(dx2) and dx or dx2
	else
		return math.abs(dy) < math.abs(dy2) and dy or dy2
	end
end



Guy = Object:new {
	img = G.newImage("sprites.png"),
	size = 24,
	frame_length = 5,
	anims = {
		idle = { 1 },
		run = { 3, 4, 5, 19, 20, 21, },
		jump = { 34, 35, 36 },
		cliff = { 51 },
	},
	rope_length_max = 40
}
genQuads(Guy)
function Guy:init()
	self.tick = 0

	self.x = 50
	self.y = 50
	self.dir = 1
	self.vx = 0
	self.vy = 0

	self.rope_length = 0
	self.rope_state = "off"
	self.rope_x = 0
	self.rope_y = 0
	self.state = "air"
end


function Guy:update()

	-- input
	local ix = bool[D"right"] - bool[D"left"]
	local iy = bool[D"down"] - bool[D"up"]
	local jump = D"x"



	if self.state == "floor" then
		self.vx = math.max(self.vx - 0.25, math.min(self.vx + 0.25, ix * 1))

	elseif self.state == "air" then
		if self.rope_state == "tight" then

			local dx = self.x - self.rope_x
			local dy = self.y - self.rope_y
			local l = (dx^2 + dy^2)^0.5
			dx = dx / l
			dy = dy / l

			self.vx = self.vx + dy * ix * 0.03125
			self.vy = self.vy - dx * ix * 0.03125


		else
			local m = math.max(1, math.abs(self.vx))
			self.vx = math.max(-m, math.min(m, self.vx + ix * 0.175))
		end

	elseif self.state == "cliff" then

		-- let go
		if iy > 0
		or ix == -self.dir then
			self.state = "air"
		end

	end
	if ix ~= 0 then
		self.dir = ix
	end



	local vx = math.min(3, math.max(-3, self.vx))
	self.x = self.x + vx


	-- vertical collision
	local dx = map:collision({ self.x - 5, self.y - 2, 10, 14 }, "x")
	if dx ~= 0 then
		self.x = self.x + dx
		self.vx = 0
	end



	if self.state == "air" or self.state == "floor" then

		self.vy = self.vy + 0.2		-- gravity
		local vy = math.min(3, math.max(-3, self.vy))
		self.y = self.y + vy

		-- horizontal collision
		self.state = "air"
		local dy = map:collision({ self.x - 5, self.y - 2, 10, 14 }, "y")
		if dy ~= 0 then
			self.y = self.y + dy
			self.vy = 0
			if dy < 0 then
				self.state = "floor"
			end
		end

	end


	if self.state == "floor" then
		self.rope_state = "off"

		-- jump
		if jump and not self.jump then
			self.vy = -4
			self.jump_control = true
		end

	elseif self.state == "air" then

		if self.jump_control then
			if not jump and self.vy < -1 then
				self.vy = -1
				self.jump_control = false
			elseif self.vy > -1 then
				self.jump_control = false
			end
		end


		if self.rope_state == "off" then


			-- grap edge
			if self.vy > 0 then
				self.box = nil
				local dx = map:collision({ self.x - 5 + self.dir * 2, self.y - 2, 10, 14 }, "x")
				if dx ~= 0 then
					local box = { self.x - 5 + self.dir * 3, self.y - 7, 10, 10 }
					local dy = map:collision(box, "y")
					box[2] = box[2] + dy

					if -7 < dy and dy <= -2 then

						-- debug
						--self.box = box

						self.vy = 0
						self.vx = 0
						self.x = self.x + dx + self.dir * 2
						self.y = self.y + dy + 3
						self.state = "cliff"
					end
				end
			end


		end


		-- shoot rope
		if self.rope_state == "off" and jump and not self.jump then


			-- try different angles
			local min_d = self.rope_length_max + 10
			local min_dx
			local min_dy
			local i = 0
			for a = 35, 90 do
				local dx = math.cos(a * math.pi / 180) * self.dir
				local dy = -math.sin(a * math.pi / 180)
				if not min_dx then
					min_dx = dx
					min_dy = dy
				end

				local d = map:rayIntersection(self.x, self.y, dx, dy)
				if d and d < min_d then
					min_d = d
					min_dx = dx
					min_dy = dy
					if d <= self.rope_length_max - 4 then
						i = i + 1
						if i > 4 then break end
					end
				end
			end


			self.rope_state = "extend"
			self.rope_dx = min_dx
			self.rope_dy = min_dy
			self.rope_x = self.x + self.rope_dx * 15
			self.rope_y = self.y + self.rope_dy * 15



		elseif self.rope_state == "extend" then

			self.rope_x = self.rope_x + self.rope_dx * 15
			self.rope_y = self.rope_y + self.rope_dy * 15

			local dx = self.rope_x - self.x
			local dy = self.rope_y - self.y

			local len = (dx^2 + dy^2)^0.5

			if len > self.rope_length_max then
				dx = dx / len * self.rope_length_max
				dy = dy / len * self.rope_length_max
				len = self.rope_length_max
			end
			self.rope_length = len

			local d = map:rayIntersection(self.x, self.y, dx, dy)
			if d and d <= 1 then
				self.rope_length = len * d
				self.rope_state = "loose"
				self.rope_x = self.x + dx * d
				self.rope_y = self.y + dy * d
			elseif len == self.rope_length_max then
				self.rope_state = "off"
			end

		elseif self.rope_state == "loose"
		or self.rope_state == "tight" then

			-- change rope lengt
			self.rope_length = math.max(10, math.min(self.rope_length_max, self.rope_length + iy))

			local dx = self.x - self.rope_x
			local dy = self.y - self.rope_y
			local l = (dx^2 + dy^2)^0.5


			if l > self.rope_length then
				self.rope_state = "tight"

				dx = dx / l
				dy = dy / l

				self.x = self.rope_x + dx * self.rope_length
				self.y = self.rope_y + dy * self.rope_length


				-- TODO: more collision checking


				local ovx = self.vx
				local ovy = self.vy

				local dot = dx * self.vy - dy * self.vx
				self.vx = dot * -dy
				self.vy = dot * dx


			else
				self.rope_state = "loose"
			end



			if jump and not self.jump then
				if self.rope_state == "tight" then
					self.vy = self.vy - 1
				end
				self.rope_state = "off"
			end
		end

	elseif self.state == "cliff" then

		-- jump
		if jump and not self.jump then
			self.state = "air"
			self.vy = -2.75
			self.jump_control = true
		end

	end


	-- curtail rope
	if self.rope_state == "off" then
		self.rope_length = math.max(0, self.rope_length - 5)
		local dx = self.rope_x - self.x
		local dy = self.rope_y - self.y
		local len = (dx^2 + dy^2)^0.5
		self.rope_x = self.x + dx / len * self.rope_length
		self.rope_y = self.y + dy / len * self.rope_length
	end


	-- store buttons
	self.jump = jump


	-- animations
	if ix == 0 then
		self.tick = 0
		self.anim = self.anims.idle
	else
		self.tick = self.tick + 1
		self.anim = self.anims.run
	end


end
function Guy:draw()

--	love.timer.sleep(0.1)


	-- rope
	G.setColor(178, 220, 239)
	local dx = self.rope_x - self.x
	local dy = self.rope_y - self.y
	local len = (dx^2 + dy^2)^0.5

	local j = 0
	for i = len, 0, -3 do

		local x = self.x + (self.rope_x - self.x) * i / len
		local y = self.y + (self.rope_y - self.y) * i / len

		G.rectangle("fill", x-1, y-1, 2, 2)
	end


	local f = self.anim[math.floor(self.tick / self.frame_length) % #self.anim + 1]
	if self.state == "air" then
		f = self.anims.jump[1]
--		if math.abs(self.vy) < 1 then
--			f = self.anims.jump[3]
--		elseif math.abs(self.vy) < 3 then
--			f = self.anims.jump[2]
--		else
--			f = self.anims.jump[1]
--		end
	elseif self.state == "cliff" then
		f = self.anims.cliff[1]
	end


	G.setColor(255, 255, 255)
	G.draw(self.img, self.quads[f], math.floor(self.x + 0.5), math.floor(self.y + 0.5),
		0, self.dir, 1, 12, 4)


	-- debug
	if self.box then
		G.rectangle("fill", unpack(self.box))
	end



--	G.setColor(255, 0, 0, 100)
--	G.rectangle("fill", self.x - 5, self.y - 2, 10, 14)
end

