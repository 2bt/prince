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
end


function Guy:update()

	-- input
	local ix = bool[D"right"] - bool[D"left"]
	local iy = bool[D"down"] - bool[D"up"]
	local jump = D"x"



	if not self.in_air then
		self.vx = math.max(self.vx - 0.25, math.min(self.vx + 0.25, ix * 1))
	else
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
	end
	local vx = math.min(3, math.max(-3, self.vx))
	self.x = self.x + vx


	-- vertical collision
	local dx = map:collision({ self.x - 5, self.y - 2, 10, 14 }, "x")
	if dx ~= 0 then
		self.x = self.x + dx
		self.vx = 0
	end


	self.vy = self.vy + 0.2
	local vy = math.min(3, math.max(-3, self.vy))
	self.y = self.y + vy



	-- horizontal collision
	self.in_air = true
	local dy = map:collision({ self.x - 5, self.y - 2, 10, 14 }, "y")
	if dy ~= 0 then
		self.y = self.y + dy
		self.vy = 0
		if dy < 0 then
			self.in_air = false
		end
	end




	if not self.in_air then
		-- jump
		if jump and not self.jump then
			self.vy = -4
			self.jump_control = true
		end
		self.rope_state = "off"
	else

		if self.jump_control then
			if not jump and self.vy < -1 then
				self.vy = -1
				self.jump_control = false
			elseif self.vy > -1 then
				self.jump_control = false
			end
		end



		if self.rope_state == "off" and jump and not self.jump then


			-- try different angles
			for a = 35, 90 do
				local dx = math.cos(a * math.pi / 180) * self.dir
				local dy = -math.sin(a * math.pi / 180)
				local d = map:rayIntersection(self.x, self.y, dx, dy)
				if d and d <= self.rope_length_max then
					self.rope_length = d
					self.rope_state = "loose"
					self.rope_x = self.x + dx * d
					self.rope_y = self.y + dy * d
					break
				end
			end



--			local dx = self.dir / (2^0.5)
--			local dy = -1 / (2^0.5)
--			local d = map:rayIntersection(self.x, self.y, dx, dy)
--			if d and d <= self.rope_length_max then
--				self.rope_length = d
--				self.rope_state = "loose"
--				self.rope_x = self.x + dx * d
--				self.rope_y = self.y + dy * d
--			end

--			self.rope_x = self.x
--			self.rope_y = self.y
--			self.rope_dx = 0
--			self.rope_dy = 0
--			self.rope_state = "extend"

		elseif self.rope_state == "extend" then

			local dx = self.dir / (2^0.5) * 10
			local dy =       -1 / (2^0.5) * 10

			self.rope_dx = self.rope_dx + dx
			self.rope_dy = self.rope_dy + dy
			self.rope_x = self.x + self.rope_dx
			self.rope_y = self.y + self.rope_dy

			self.rope_length = (self.rope_dx^2 + self.rope_dx^2)^0.5
			if self.rope_length > self.rope_length_max then
				self.rope_state = "curtail"
			else

				local d = map:rayIntersection(self.x, self.y, self.rope_dx, self.rope_dy)
				if d and d <= 1 then
					self.rope_length = self.rope_length * d
					self.rope_state = "loose"
					self.rope_x = self.x + self.rope_dx * d
					self.rope_y = self.y + self.rope_dy * d
				end

			end


		elseif self.rope_state == "curtail" then

			self.rope_length = math.max(0, self.rope_length - 5)
			if self.rope_length == 0 then
				self.rope_state = "off"
			else
				local dx = self.rope_x - self.x
				local dy = self.rope_y - self.y
				local l = (dx^2 + dy^2)^0.5
				self.rope_x = self.x + dx / l * self.rope_length
				self.rope_y = self.y + dy / l * self.rope_length
			end

		elseif self.rope_state ~= "off" then

			-- change rope lengt
			self.rope_length = math.max(10, math.min(self.rope_length_max, self.rope_length + iy))

			local dx = self.x - self.rope_x
			local dy = self.y - self.rope_y
			local l = (dx^2 + dy^2)^0.5


			if l > self.rope_length then
				dx = dx / l
				dy = dy / l

				self.x = self.rope_x + dx * self.rope_length
				self.y = self.rope_y + dy * self.rope_length



				local ovx = self.vx
				local ovy = self.vy

				local dot = dx * self.vy - dy * self.vx
				self.vx = dot * -dy
				self.vy = dot * dx


				self.rope_state = "tight"
			else
				self.rope_state = "loose"
			end



			if jump and not self.jump then
				if self.rope_state == "tight" then
					self.vy = self.vy - 1
				end
				self.rope_state = "curtail"
			end
		end


	end
	self.jump = jump


	if ix == 0 then
		self.tick = 0
		self.anim = self.anims.idle
	else
		self.dir = ix
		self.tick = self.tick + 1
		self.anim = self.anims.run
	end


end
function Guy:draw()

--	love.timer.sleep(0.1)


	-- rope
	G.setColor(178, 220, 239)
	if self.rope_state ~= "off" then
		G.line(self.x, self.y, self.rope_x, self.rope_y)
	end


	local f = self.anim[math.floor(self.tick / self.frame_length) % #self.anim + 1]
	if self.in_air then
		if math.abs(self.vy) < 1 then
			f = self.anims.jump[3]
		elseif math.abs(self.vy) < 3 then
			f = self.anims.jump[2]
		else
			f = self.anims.jump[1]
		end
	end


	G.setColor(255, 255, 255)
	G.draw(self.img, self.quads[f], math.floor(self.x + 0.5), math.floor(self.y + 0.5),
		0, self.dir, 1, self.size / 2, self.size / 2)



--	G.setColor(0, 255, 0)
--	local d = map:rayIntersection(self.x, self.y, -1, 1)
--	if d then
--		G.line(self.x, self.y, self.x - 1 * d, self.y + 1 * d)
--	end


--	G.setColor(255, 255, 255, 10)
--	G.rectangle("fill", self.x - 5, self.y - 2, 10, 14)
end

