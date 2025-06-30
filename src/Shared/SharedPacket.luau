--!strict
--!native
--!optimize 2

local types = require(script.Parent.Parent.types)

local Packet: types.Packet = {}:: types.Packet
Packet["__index"] = Packet

function Packet:FireServer()
	error("FireServer is not allowed on the server")
end

function Packet:FireClient()
	error("FireClient is not allowed on the client")
end

function Packet:FireAllClients()
	error("FireAllClients is not allowed on the client")
end

function Packet:FireClients()
	error("FireClients is not allowed on the client")
end

local packetIdCounter = -1

function Packet:New()
	local packet: types.Packet = setmetatable({}, self):: any
	packet._id = packetIdCounter
	packetIdCounter += 1
	return packet
end

return table.freeze(Packet)