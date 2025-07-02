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

local Players = game:GetService("Players")
local remote = script.Parent.Parent:WaitForChild("TwoNetRemote")

local reader = Buffers.reader
local retryTimeout = Config.PLAYER_NOT_LOADED_RETRY_TIMEOUT
local packetArgReads = Process.packetArgReads
local packetArgCounts = Process.packetArgCount

local _, readId = Buffers.getMethodFromSize(Config.MAX_PACKET_ID - 1)
local _, readCount = Buffers.getMethodFromSize(Config.MAX_PACKET_COUNT)

local ServerPacket: types.Packet = Packet:New()
ServerPacket["__index"] = ServerPacket

local playerPackets: { [ Player ]: types.PacketCollection } = {}
local groupPackets: { [ { Player} ]: types.PacketCollection } = setmetatable({}, {__mode = "k"}):: any
local globalPackets: types.PacketCollection = table.clone(Process.packetArgCollection)

local pendingPlayerPackets : { [ Player ]: types.PacketCollection } = {}
local pendingPlayerPacketsCount : { [ Player ]: number } = {}

local pendingGroupPackets: { [ { Player } ]: types.PacketCollection } = {}
local pendingGroupPacketsCount : { [ { Player } ]: number } = {}

local pendingGlobalPackets: types.PacketCollection = {}
local pendingGlobalPacketsCount = 0

local pendingDecodeQueue : { {player: Player, buf: buffer} } = {}
local packetSignals: { Signal.Signal<(Player, ...any)> } = {}

local playerDataSizeRecord: { [Player]: number } = {}
local playerPacketCountRecord: { [Player]: number } = {}

local playerDataSizeLimit = Config.MAX_PLAYER_DATA_PER_CYCLE
local playerPacketCountLimit = Config.MAX_PLAYER_PACKETS_PER_CYCLE
local cycleTime = Config.CYCLE_TIME


function ServerPacket:FireClient(player, ...)
	local packetCollection = playerPackets[player]

	if not packetCollection then
		local start = os.clock()
		repeat 
			task.wait() 
			packetCollection = playerPackets[player] 
		until packetCollection or os.clock() - start > retryTimeout
		if not packetCollection then
			error("[TWONET][PACKETS][FIRECLIENT] could not find player's packet collection. packet has been dropped.")
		end
	end

	local argCollection = packetCollection[self._id]
	table.insert(argCollection, table.pack(...))

	-- When first arg is inserted
	if #argCollection == 1 then
		local pendingPacketCollection = pendingPlayerPackets[player]
		if not pendingPacketCollection then
			pendingPacketCollection = {}
			pendingPlayerPackets[player] = pendingPacketCollection
		end
		pendingPacketCollection[self._id] = argCollection
		pendingPlayerPacketsCount[player] += 1
	end
end

function ServerPacket:FireClients(players, ...)
	local packetCollection = groupPackets[players]

	if not packetCollection then
		packetCollection = table.clone(Process.packetArgCollection)
		groupPackets[players] = packetCollection
	end

	local argCollection = packetCollection[self._id]
	table.insert(argCollection, table.pack(...))

	-- When first arg is inserted
	if #argCollection == 1 then
		local pendingPacketCollection = pendingGroupPackets[players]
		if not pendingPacketCollection then
			pendingPacketCollection = {}
			pendingGroupPackets[players] = pendingPacketCollection
		end
		pendingPacketCollection[self._id] = argCollection
		pendingGroupPacketsCount[players] += 1
	end
end

function ServerPacket:FireAllClients(...)
	local argCollection = globalPackets[self._id]
	table.insert(argCollection, table.pack(...))
	if #argCollection == 1 then
		pendingGlobalPackets[self._id] = argCollection
		pendingGlobalPacketsCount += 1
	end
end

function ServerPacket:New(...)
	local packet: types.Packet = Packet.New(self, ...)
	local signal = Signal()
	packetSignals[packet._id] = signal
	packet.OnServerEvent = signal 
	Process.register(packet._id, ...)
	return packet
end


Players.PlayerAdded:Connect(function(player)
	playerPackets[player] = table.clone(Process.packetArgCollection)
	playerDataSizeRecord[player] = 0
	playerPacketCountRecord[player] = 0
end)

Players.PlayerRemoving:Connect(function(player)
	playerPackets[player] = nil
	playerDataSizeRecord[player] = nil
	playerPacketCountRecord[player] = nil
end)

remote.OnServerEvent:Connect(function(player, buf)
	if typeof(buf) ~= "buffer" then
		warn("[TWONET][PACKETS][DECODE] player sending invalid data, type ~= buffer, player=", player.Name)
		if Config.CAN_KICK then
			player:Kick(Config.PLAYER_KICK_MESSAGE)
		end
		return
	end
	table.insert(pendingDecodeQueue, {player = player, buf = buf})
end)

local argTable = {}
local lastCycleTime = 0
RunService.Heartbeat:Connect(function()
	-- Packet decoding
		for i, data in pendingDecodeQueue do
			local player = data.player

			local playerDataSize = playerDataSizeRecord[player] or 0
			if  playerDataSize > playerDataSizeLimit then
				warn("[TWONET][PACKETS][DECODE] player is sending too much data, packets have been dropped, player=", player.Name)
				if Config.CAN_KICK then
					player:Kick(Config.PLAYER_KICK_MESSAGE)
				end
				continue
			end

			reader.setBuffer(data.buf)

			local uniquePackets = readId()

			for _ = 1, uniquePackets do
				local packetId = readId()
				local packetCount = readCount()
				local playerPacketCount = (playerPacketCountRecord[player] or 0) + packetCount
				playerPacketCountRecord[player] = playerPacketCount

				if playerPacketCount > playerPacketCountLimit then
					warn("[TWONET][PACKETS][DECODE] player is sending too many packets, packets dropped, player=", player.Name)
					if Config.CAN_KICK then
						player:Kick(Config.PLAYER_KICK_MESSAGE)
					end
					break
				end


				local signal = packetSignals[packetId]
				if not signal then
					warn("[TWONET][PACKETS][DECODE] player sent packet with invalid packetId, player=", player.Name)
					if Config.CAN_KICK then
						player:Kick(Config.PLAYER_KICK_MESSAGE)
					end
					break
				end
				local reads = packetArgReads[packetId]
				local argCount = packetArgCounts[packetId]
				for _ = 1, packetCount do
					for j = 1, argCount do
						argTable[j] = reads[j]()
					end
					signal:Fire(player, unpack(argTable))
					table.clear(argTable)
				end
			end

			playerDataSizeRecord[player] += reader.length()
		end

		table.clear(pendingDecodeQueue)

		-- Global Packets
		if pendingGlobalPacketsCount > 0 then
			local buf = Process.encode(pendingGlobalPackets, pendingGlobalPacketsCount)
			remote:FireAllClients(buf)
			pendingGlobalPacketsCount = 0
		end

		-- Group Packets
		for players, packetCollection in pendingGroupPackets do
			local buf = Process.encode(packetCollection, pendingGroupPacketsCount[players])
			for _, player in players do
				remote:FireClient(player, buf)
			end
			pendingGroupPacketsCount[players] = 0
			pendingGroupPackets[players] = nil
		end

		--Indivdual Player Packets
		for player, packetCollection in pendingPlayerPackets do
			local buf = Process.encode(packetCollection, pendingPlayerPacketsCount[player])
			remote:FireClient(player, buf)
			pendingPlayerPacketsCount[player] = 0
			pendingPlayerPackets[player] = nil
		end

		-- Ratelimiter Reset
		if os.clock() - lastCycleTime > cycleTime then
			for player, _ in playerDataSizeRecord do
				playerDataSizeRecord[player] = 0
				playerPacketCountRecord[player] = 0
			end
			lastCycleTime = os.clock()
		end

end)

return table.freeze(ServerPacket)