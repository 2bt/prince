Object = {}
function Object:new(o)
	o = o or {}
	setmetatable(o, self)
	local m = getmetatable(self)
	self.__index = self
	self.__call = m.__call
	self.super = m.__index and m.__index.init
	return o
end
setmetatable(Object, { __call = function(self, ...)
	local o = self:new()
	if o.init then o:init(...) end
	return o
end })


bool = { [true] = 1, [false] = 0 }


function updateList(x)
	local i = 1
	for j, b in ipairs(x) do
		x[j] = nil
		if b:update() ~= "kill" then
			x[i] = b
			i = i + 1
		else
			if b.kill then b:kill() end
		end
	end
end
function drawList(x, layer)
	if layer then
		for _, o in ipairs(x) do
			if o.layer == layer then o:draw() end
		end
	else
		for _, o in ipairs(x) do o:draw() end
	end
end

function makeRandomGenerator(seed)
	local rg = love.math.newRandomGenerator(seed)
	return {
		int = function(a, b)
			return b and rg:random(a, b) or rg:random(a)
		end,
		float = function(a, b)
			return a + rg:random() * (b - a)
		end
	}
end


function genQuads(obj, size)
	size = size or obj.size
	obj.quads = makeQuads(
		obj.img:getWidth(),
		obj.img:getHeight(),
		size)
end

function makeQuads(w, h, s)
	local quads = {}
	for y = 0, h - s, s do
		for x = 0, w - s, s do
			table.insert(quads, love.graphics.newQuad(x, y, s, s, w, h))
		end
	end
	return quads
end


function sign(x)
	if x < 0 then return -1 end
	return 1
end


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



function rayBoxIntersection(ox, oy, dx, dy, box)

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




