--!strict
--!native
--!optimize 2

local Buffers = require(script.Parent.Buffers)
local Config = require(script.Parent.Parent.Config)

local maxArrayIndex = Config.MAX_ARRAY_INDEX - 1
local writeHeader, readHeader  = Buffers.getMethodFromSize(maxArrayIndex)

local record = {}

local Array = {}

function Array.New<T>(typeId: T)

	if record[typeId] then
		return record[typeId]
	end
	
	local type = Buffers.get(typeId)
	local readType = type.read
	local writeType = type.write

	if not type then
		error("[TWONET][ARRAY][CONSTRUCTOR] array type must be a valid registered buffer type.")
	end

	local function write(val: {T}): number
		local count = #val

		if count > maxArrayIndex then
			error("[TWONET][ARRAY][WRITE] array size overflow.")
		end

		local size = writeHeader(count)
		for i = 1, count do
			size += writeType(val[i])
		end
		return size
	end

	local function read(): ({T}, number)
		local val = {}
		local count, size = readHeader()
		for _ = 1, count do
			local field, fieldSize = readType()
			table.insert(val, field)
			size += fieldSize
		end
		return val, size
	end

	local arrayId = Buffers.register(read, write)
	record[typeId:: any] = arrayId

	return arrayId
end

return Array