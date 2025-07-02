--!strict
--!native
--!optimize 2

local types = require(script.Parent.Parent.types)
local buffers = require(script.Parent.Parent.Shared.Buffers)
local writer = buffers.writer
local Config = require(script.Parent.Parent.Config)

local MAX_PACKET_COUNT = Config.MAX_PACKET_COUNT - 1
local writeId = buffers.getMethodFromSize(Config.MAX_PACKET_ID - 1)
local writeCount = buffers.getMethodFromSize(MAX_PACKET_COUNT)

local packetArgWrites: { {types.Write<any>} } = {}
local packetArgReads: { {types.Read<any>} } = {}
local packetArgCounts : { number } = {}
local packetArgCollection: types.PacketCollection = {}

local Process = {}

function Process.register<A...>(packetId: number, ...)
	local typeIds: { any } = { ... }
	local writes = {}
	local reads = {}
	local count = 0
	for _, typeId in typeIds do
		local type = buffers.get(typeId)
		if not type then
			error("[TWONET][PACKET][CONSTRUCTOR] packet arg must be valid registered buffer type")
		end
		count += 1
		table.insert(writes, type.write)
		table.insert(reads, type.read)
	end

	packetArgCollection[packetId] = {}
	packetArgWrites[packetId] = writes
	packetArgReads[packetId] = reads
	packetArgCounts[packetId] = count
end

-- Encodes the given collection into a buffer and also clears the collection
function Process.encode(collection: types.PacketCollection, uniquePackets: number): (buffer, number)
	writeId(uniquePackets)
	for id, argCollection in collection do
		local uniqueArgs = #argCollection
		writeId(id)
		if uniqueArgs > MAX_PACKET_COUNT then
			warn("[TWONET][PACKET][ENCODE] Max packet count exceeded, extra packet dropped, packet=", id)
			for i = MAX_PACKET_COUNT + 1, uniqueArgs do
				argCollection[i] = nil
			end
			uniqueArgs = MAX_PACKET_COUNT
		end
		writeCount(uniqueArgs)
		local writes = packetArgWrites[id]
		for i = 1, uniqueArgs do
			local args = argCollection[i]
			for j, val in args do
				writes[j](val)
			end
			argCollection[i] = nil
		end		
		collection[id] = nil
	end
	return writer.pop()
end

Process.packetArgCollection = packetArgCollection
Process.packetArgReads = packetArgReads
Process.packetArgCount = packetArgCounts

return Process