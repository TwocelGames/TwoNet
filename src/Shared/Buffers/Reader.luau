--!strict
--!optimize 2
--!native

local Config = require(script.Parent.Parent.Parent.Config)

local readHeader = Config.BUFFER_HEADER_READ
local headerLength = Config.BUFFER_HEADER_LENGTH

local readu8 = buffer.readu8
local readi8 = buffer.readi8
local readu16 = buffer.readu16
local readi16 = buffer.readi16
local readu32 = buffer.readu32
local readi32 = buffer.readi32
local readf32 = buffer.readf32
local readf64 = buffer.readf64
local readstring = buffer.readstring
local copy = buffer.copy
local create = buffer.create

local buf: buffer = nil
local cur = 0

local Reader = {}

-- API
function Reader.setBuffer(bufferToRead: buffer)
	buf = bufferToRead
	cur = 0
end

function Reader.length(): number
	return cur
end

function Reader.reset(): number
	local oldCur = cur
	cur = 0
	return oldCur
end

-- Native Types
function Reader.string(): (string, number)
	local len = readHeader(buf, cur)
	cur += headerLength
	local val = readstring(buf, cur, len)
	cur += len
	return val, len
end

function Reader.buffer(): (buffer, number)
	local len = readHeader(buf, cur)
	cur += headerLength
	local newBuf = create(len)
	copy(newBuf, 0, buf, cur, len)
	cur += len
	return newBuf, len
end

function Reader.u8(): (number, number)
	local val = readu8(buf, cur)
	cur += 1
	return val, 1
end

function Reader.i8(): (number, number)
	local val = readi8(buf, cur)
	cur += 1
	return val, 1
end

function Reader.u16(): (number, number)
	local val = readu16(buf, cur)
	cur += 2
	return val, 2
end

function Reader.i16(): (number, number)
	local val = readi16(buf, cur)
	cur += 2
	return val, 2
end

function Reader.u32(): (number, number)
	local val = readu32(buf, cur)
	cur += 4
	return val, 4
end

function Reader.i32(): (number, number)
	local val = readi32(buf, cur)
	cur += 4
	return val, 4
end

function Reader.f32(): (number, number)
	local val = readf32(buf, cur)
	cur += 4
	return val, 4
end

function Reader.f64(): (number, number)
	local val = readf64(buf, cur)
	cur += 8
	return val, 8
end

-- Custom types
function Reader.boolean(): (boolean, number)
	local val = readu8(buf, cur)
	cur += 1
	return val ~= 0, 1
end

function Reader.vector3(): (Vector3, number)
	local x = readf32(buf, cur)
	local y = readf32(buf, cur + 4)
	local z = readf32(buf, cur + 8)
	cur += 12
	return Vector3.new(x, y, z), 1
end

function Reader.cframe(): (CFrame, number)
	local x = readf32(buf, cur)
	local y = readf32(buf, cur + 4)
	local z = readf32(buf, cur + 8)
	local rx = readf32(buf, cur)
	local ry = readf32(buf, cur + 4)
	local rz = readf32(buf, cur + 8)
	cur += 24
	return CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz), 24
end


return table.freeze(Reader)
