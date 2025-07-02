--!strict
local types = require(script.types)
local packet: types.Packet  = game:GetService("RunService"):IsClient() and require(script.Client.ClientPacket) or require(script.Server.ServerPacket)
local buffers = require(script.Shared.Buffers)
local signal = require(script.Parent.FastSig)

export type Packet<A...> = types.Packet<A...>
export type Signal<A...> = signal.Signal<A...>

local lib = {}

function lib.packet<A...>(...: A...): types.Packet<A...>
	return packet:New(...) :: types.Packet<A...>
end

lib.types = table.freeze(buffers.types)

return lib

