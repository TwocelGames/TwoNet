--!strict

local Sig = require(script.Parent.Parent.FastSig)



export type Packet<T... = (...any)> = {
	FireServer: (Packet<T...>, T...) -> (),
	FireClient: (Packet<T...>, Player, T...) -> (),
	FireAllClients: (Packet<T...>, T...) -> (),
	FireClients: (Packet<T...>, Players: {Player}, T...) -> (),

	OnServerEvent: Sig.Signal<(Player, T...)>,
	OnClientEvent: Sig.Signal<(T...)>,

	New: (Packet<T...>, T...) -> Packet<T...>,
	_id: number,
}

return 0