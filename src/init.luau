--!strict
local types = require(script.types)
local packet: types.Packet  = game:GetService("RunService"):IsClient() and require(script.Client.ClientPacket) or require(script.Server.ServerPacket)

local function constructor<A...>(...: A...): types.Packet<A...>
	return packet:New(...) :: types.Packet<A...>
end

return constructor

