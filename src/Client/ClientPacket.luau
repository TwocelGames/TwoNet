--!strict
--!native
--!optimize 2

local Packet = require(script.Parent.Parent.Shared.SharedPacket)
local types = require(script.Parent.Parent.types)
local Signal = require(script.Parent.Parent.Parent.FastSig)

local ClientPacket: types.Packet = Packet:New()
ClientPacket["__index"] = ClientPacket

function ClientPacket:FireServer()
	
end

function ClientPacket:New(...)
	local packet: types.Packet = Packet.New(self, ...)
	packet.OnClientEvent = Signal()
	return packet
end

return table.freeze(ClientPacket)