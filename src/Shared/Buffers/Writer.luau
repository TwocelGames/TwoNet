--!strict
--!native
--!optimize 2

local Config = require(script.Parent.Parent.Parent.Config)

local create = buffer.create
local copy = buffer.copy
local bufferLen = buffer.len

local writeheader = Config.BUFFER_HEADER_WRITE
local headerLength = Config.BUFFER_HEADER_LENGTH
local maxHeaderData = Config.MAX_HEADER_DATA - 1

local writeu8 = buffer.writeu8
local writei8 = buffer.writei8
local writeu16 = buffer.writeu16
local writei16 = buffer.writei16
local writeu32 = buffer.writeu32
local writei32 = buffer.writei32
local writef32 = buffer.writef32
local writef64 = buffer.writef64
local writestring = buffer.writestring

local size = Config.BUFFER_START_SIZE
local scale = Config.BUFFER_SCALE_FACTOR
local brake = Config.BUFFER_SCALE_BRAKE
local buf = create(size)
local cur = 0

local function reserve(bytes: number): number
	local startIndex = cur
	local requiredSize = startIndex + bytes

	if requiredSize > size then
		local newSize = math.max(requiredSize, size * scale)
		scale -= ( ( scale - 1 ) * brake )

		local newBuf = create(newSize)
		copy(newBuf, 0, buf, 0, cur)

		buf = newBuf
		size = newSize
	end

	cur = requiredSize

	return startIndex
end

local Writer = {}

-- API
function Writer.pop(): (buffer, number)
	local oldCur = cur
	local newBuf = create(oldCur)
	copy(newBuf, 0, buf, 0, oldCur)
	cur = 0
	return newBuf, oldCur
end

function Writer.length(): number
	return cur
end

function Writer.getBuffer(): buffer
	return buf
end

function Writer.reset(): number
	local oldCur = cur
	cur = 0
	return oldCur
end

-- Native Types
function Writer.string(val: string): number
	local len = #val
	assert(len <= maxHeaderData, "[TWONET][BUFFERS][WRITER]: String size overflow")
	local startIndex = reserve(len + headerLength)
	writeheader(buf, startIndex, len)
	writestring(buf, startIndex + headerLength, val, len)
	return len
end

function Writer.buffer(val: buffer): number
	local len = bufferLen(val)
	assert(len <= maxHeaderData, "[TWONET][BUFFERS][WRITER]: Buffer size overflow")
	local startIndex = reserve(len + headerLength)
	writeheader(buf, startIndex, len)
	copy(buf, startIndex + headerLength, val, 0, len)
	return len
end

function Writer.u8(val: number): number
	local startIndex = reserve(1)
	writeu8(buf, startIndex, val)
	return 1
end

function Writer.i8(val: number): number
	local startIndex = reserve(1)
	writei8(buf, startIndex, val)
	return 1
end

function Writer.u16(val: number): number
	local startIndex = reserve(2)
	writeu16(buf, startIndex, val)
	return 2
end

function Writer.i16(val: number): number
	local startIndex = reserve(2)
	writei16(buf, startIndex, val)
	return 2
end

function Writer.u32(val: number): number
	local startIndex = reserve(4)
	writeu32(buf, startIndex, val)
	return 4
end

function Writer.i32(val: number): number
	local startIndex = reserve(4)
	writei32(buf, startIndex, val)
	return 4
end

function Writer.f32(val: number): number
	local startIndex = reserve(4)
	writef32(buf, startIndex, val)
	return 4
end

function Writer.f64(val: number): number
	local startIndex = reserve(8)
	writef64(buf, startIndex, val)
	return 8
end


-- Custom Types

function Writer.boolean(val: boolean): number
	local startIndex = reserve(1)
	writeu8(buf, startIndex, val and 1 or 0)
	return 1
end

function Writer.vector3(val: Vector3): number
	local startIndex = reserve(12)
	writef32(buf, startIndex, val.X)
	writef32(buf, startIndex + 4, val.Y)
	writef32(buf, startIndex + 8, val.Z)
	return 12
end

function Writer.cframe(val: CFrame): number
	local startIndex = reserve(12)
	local pos = val.Position
	writef32(buf, startIndex, pos.X)
	writef32(buf, startIndex + 4, pos.Y)
	writef32(buf, startIndex + 8, pos.Z)
	local rx, ry, rz = val:ToEulerAnglesXYZ()
	writef32(buf, startIndex + 12, rx)
	writef32(buf, startIndex + 16, ry)
	writef32(buf, startIndex + 20, rz)
	return 24
end

return table.freeze(Writer)
