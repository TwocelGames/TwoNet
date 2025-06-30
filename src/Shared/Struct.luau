--!strict
--!native
--!optimize 2

local Buffers = require(script.Parent.Buffers)

local Struct = {}

function Struct.New<T>(layout: T)

	if typeof(layout) ~= "table" then
		error("[TWONET][STRUCTS][CONSTRUCTOR] layout must be of table type")
	end

	local keys = {}
	local writes = {}
	local reads = {}
	local count = 0

	for k, _ in layout do
		if typeof(k) ~= "string" then
			error("[TWONET][STRUCTS][CONSTRUCTOR] layout keys must be of string type")
		end
		count += 1
		table.insert(keys, k)
	end
	table.sort(keys)

	for i = 1, count do
		local key = keys[i]
		local typeId = layout[key]

		local bufferType = Buffers.get(typeId)
		if not bufferType then
			error("[TWONET][STRUCTS][CONSTRUCTOR] layout values must be a valid registered bufferType")
		end
		table.insert(writes, bufferType.write)
		table.insert(reads, bufferType.read)
	end

	local function write(vals: T): number
		-- We can safely cast here because the typesystem won't allow a different struct to be passed upstream
		local values: {[string]: any} = vals:: any

		local size = 0

		for i = 1, count do
			local key = keys[i]
			local val = values[key]
			size += writes[i](val)
		end

		return size
	end

	local function read(): (T, number)
		local values = {}

		local size = 0

		for i = 1, count do
			local key = keys[i]
			local val, fieldSize = reads[i]()
			values[key] = val
			size += fieldSize
		end
		
		return values:: any, size
	end
	
	return Buffers.register(read, write)
end


return table.freeze(Struct)
