--!strict
--!native
--!optimize 2

local Packet = require(script.Parent.Parent.Shared.SharedPacket)
local types = require(script.Parent.Parent.types)
local Signal = require(script.Parent.Parent.Parent.FastSig)

local ServerPacket: types.Packet = Packet:New()
ServerPacket["__index"] = ServerPacket

function ServerPacket:FireClient()
	
end

function ServerPacket:FireAllClients()
	
end

function ServerPacket:FireClients()
	print("YeeHaw")
end

function ServerPacket:New(...)
	local packet: types.Packet = Packet.New(self, ...)
	packet.OnServerEvent = Signal()
	return packet
end

return table.freeze(ServerPacket)