--!strict
--!native
--!optimize 2

local types = require(script.Parent.Parent.types)
local buffers = require(script.Parent.Parent.Shared.Buffers)
local writer = buffers.writer
local Config = require(script.Parent.Parent.Config)

local writeId, readId = buffers.getMethodFromSize(Config.MAX_PACKET_ID - 1)
local writeCount, readCount = buffers.getMethodFromSize(Config.MAX_PACKET_COUNT)

local packetArgWrites: { {types.Write<any>} } = {}
local packetArgReads: { {types.Read<any>} } = {}
local packetArgCounts : { number } = {}

local Process = {}

function Process.register<A...>(packetId: number, ... : A...)
	local typeIds: { any } = table.pack(...)
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

	packetArgWrites[packetId] = writes
	packetArgReads[packetId] = reads
	packetArgCounts[packetId] = count
end

function Process.encode(collection: types.PacketCollection, uniquePackets: number): buffer
	writeId(uniquePackets)
	for id, argCollection in collection do
		local uniqueArgs = #argCollection
		writeId(id)
		writeCount(uniqueArgs)
		local writes = packetArgWrites[id]
		for i = 1, uniqueArgs do
			local args = argCollection[i]
			for j, val in args do
				writes[j](val)
			end
			argCollection[i] = nil
		end		
	end
	return writer.pop()
end

return Process