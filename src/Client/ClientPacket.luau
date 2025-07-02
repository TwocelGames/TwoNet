--!strict
--!native
--!optimize 2

local Packet = require(script.Parent.Parent.Shared.SharedPacket)
local types = require(script.Parent.Parent.types)
local Signal = require(script.Parent.Parent.Parent.FastSig)
local Process = require(script.Parent.Parent.Shared.Process)
local Config = require(script.Parent.Parent.Config)
local Buffers = require(script.Parent.Parent.Shared.Buffers)
local RunService = game:GetService("RunService")

local remote = script.Parent.Parent:WaitForChild("TwoNetRemote")
local reader = Buffers.reader

local _, readId = Buffers.getMethodFromSize(Config.MAX_PACKET_ID - 1)
local _, readCount = Buffers.getMethodFromSize(Config.MAX_PACKET_COUNT)

local cycleTime = Config.CYCLE_TIME
local packetArgReads = Process.packetArgReads
local packetArgCounts = Process.packetArgCount

local packetCollection = Process.packetArgCollection
local pendingPacketCollection = {}
local pendingPacketsCount = 0
local packetSignals = {}

local dataSentThisCycle = 0
local packetsSentThisCycle = 0

local maxDataPerCycle = Config.MAX_PLAYER_DATA_PER_CYCLE
local maxPacketsPerCycle = Config.MAX_PLAYER_PACKETS_PER_CYCLE

local ClientPacket: types.Packet = Packet:New()
ClientPacket["__index"] = ClientPacket

function ClientPacket:FireServer(...)
	local argCollection = packetCollection[self._id]
	table.insert(argCollection, {...})
	if #argCollection == 1 then
		pendingPacketCollection[self._id] = argCollection
		pendingPacketsCount += 1
	end
	packetsSentThisCycle += 1
end

function ClientPacket:New(...)
	local packet: types.Packet = Packet.New(self, ...)
	local signal = Signal()
	Process.register(packet._id, ...)
	packetSignals[packet._id] = signal
	packet.OnClientEvent = signal
	return packet
end

local pendingDecodeQueue = {}

remote.OnClientEvent:Connect(function(buf: buffer)
	table.insert(pendingDecodeQueue, buf)
end)

local argTable = {}
local lastCycleTime = 0

RunService.Heartbeat:Connect(function()
	-- Packet decoding
		for i, buf in pendingDecodeQueue do
			reader.setBuffer(buf)

			local uniquePackets = readId()

			for _ = 1, uniquePackets do
				local packetId = readId()
				local packetCount = readCount()

				local signal = packetSignals[packetId]

				if not signal then
					warn("[TWONET][PACKETS][DECODE] unknown packet recived, packets might be loading...")
					continue
				end

				local reads = packetArgReads[packetId]
				local argCount = packetArgCounts[packetId]

				for _ = 1, packetCount do
					for j = 1, argCount do
						argTable[j] = reads[j]()
					end
					signal:Fire(unpack(argTable))
					table.clear(argTable)
				end
			end
		end
		table.clear(pendingDecodeQueue)

		-- Packet encoding
		if pendingPacketsCount > 0 then
			if dataSentThisCycle > maxDataPerCycle then
				warn("[TWONET][PACKETS][DECODE] data limit exceeded, packets have been delayed")
				return
			end
			if packetsSentThisCycle > maxPacketsPerCycle then
				warn("[TWONET][PACKETS][DECODE] packet limit exceeded, packets have been delayed")
				return
			end

			local buf, size = Process.encode(pendingPacketCollection, pendingPacketsCount)
			remote:FireServer(buf)
			pendingPacketsCount = 0
			dataSentThisCycle += size
		end

		-- Ratelimiter Reset
		if os.clock() - lastCycleTime > cycleTime then
			dataSentThisCycle = 0
			packetsSentThisCycle = 0
			lastCycleTime = os.clock()
		end
end)

return table.freeze(ClientPacket)
