--!strict
--!native
--!optimize 2

local Reader = require(script.Reader)
local Writer = require(script.Writer)
local Types = require(script.Parent.Parent.types)
local Config = require(script.Parent.Parent.Config)

local typeRecord: { Types.BufferType<any> } = {}
local idCounter = 0

local function registerType<T>(read: Types.Read<T>, write: Types.Write<T>): T

	if idCounter > Config.MAX_PACKET_ID then
		error("[TWONET][BUFFERS][REGISTER] Maximum packet count reached, change this value in configs")
	end

	local typeId = idCounter
	idCounter += 1

	local bufferType: Types.BufferType<T> = {
		typeId = idCounter,
		read = read,
		write = write,
	}

	-- The typeId is used as key to retrive they type from dict later on but we cast it to the sample type to trick the typesystem into thinking the id represents the sample type
	-- ie <A...>(0, 1, 2) if 0, 1, 2 r typeIds then A... can be (number string boolean)

	typeRecord[typeId] = bufferType
	return (typeId:: any):: T
end

local Buffers = {}


function Buffers.get<T>(typeId: T): Types.BufferType<T>
	return typeRecord[typeId:: any]
end


function Buffers.getMethodFromSize(size: number)
	if size <= 2 ^ 8 then
		return Writer.u8, Reader.u8
	elseif size <= 2 ^ 16 then
		return Writer.u16, Reader.u16
	elseif size <= 2 ^ 32 then
		return Writer.u32, Reader.u32
	elseif size <= 2 ^ 53 then
		return Writer.f64, Reader.f64
	else
		error("[TWONET][BUFFERS][CONFIG] given size doesn't have a valid writer method")
	end
end

Buffers.reader = Reader
Buffers.writer = Writer
Buffers.register = registerType

Buffers.types = {
	unsigned_8bit_int = registerType(Reader.u8, Writer.u8),
	signed_8bit_int = registerType(Reader.i8, Writer.i8),
	unsigned_16bit_int = registerType(Reader.u16, Writer.u16),
	signed_16bit_int = registerType(Reader.i16, Writer.i16),
	unsigned_32bit_int = registerType(Reader.u32, Writer.u32),
	signed_32bit_int = registerType(Reader.i32, Writer.i32),
	float_32bit = registerType(Reader.f32, Writer.f32),
	float_64bit = registerType(Reader.f64, Writer.f64),
	string = registerType(Reader.string, Writer.string),
	buffer = registerType(Reader.buffer, Writer.buffer),
	boolean = registerType(Reader.boolean, Writer.boolean),
	vector3 = registerType(Reader.vector3, Writer.vector3),
}

return Buffers
