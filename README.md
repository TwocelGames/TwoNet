# TwoNet

TwoNet is a Roblox networking library designed to simplify and strongly-type communication between the server and clients. It provides a clean API for defining, sending, and receiving packets with type safety, reducing bugs and improving code maintainability.

## Benefits

- **Type Safety:** Define packet structures with strict type checking.
- **Ease of Use:** Simple API for creating and using packets.
- **Consistency:** Centralizes packet definitions for both server and client.
- **Performance:** Lightweight and optimized for Roblox games.

## Installion

Add using Wally

```toml
	[dependencies]
	TwoNet = "twocelgames/Twonet@1.0.0"
```

## Getting Started

### 1. Define Your Packets

Create a `Packets.luau` file in `ReplicatedStorage`:

```luau
-- Packets.luau

local TwoNet = require(TwoNet)
local types = TwoNet.types

return table.freeze{
	PacketOne = Twonet.packet(types.string, types.boolean)
}
```

### 2. Using Packets in Server and Client

Require your `Packets` module on both the server and client:

```luau
local Packets = require(game.ReplicatedStorage.Packets)
```

#### Server Example

```luau
-- Fire a packet to a client
Packets.PacketOne:FireClient(player, "Hello", false)

-- Listen for a packet from a client
Packets.PacketOne.OnServerEvent:Connect(function(player, str, num)
	print(str, num)
end)
```

#### Client Example

```luau
-- Fire a packet to the server
Packets.PacketOne:FireServer("Hello", true)

-- Listen for a packet from the server
Packets.PacketOne.OnClientEvent:Connect(function(str, num)
	print(str, num)
end)
```

## API Guide

- `packet:New(...types)`  
	Creates a new strongly-typed packet.

- `Packet.OnServerEvent`  
	Event for server to listen to client packets.

- `Packet.OnClientEvent`  
	Event for client to listen to server packets.

- `Packet:FireServer(...)`  
	Client sends a packet to the server.	

- `Packet:FireClient(player, ...)`  
	Server sends a packet to a client.

-  `Packet:FireClients(players ...)`  
	Server sends a packet to a table of clients.

-  `Packet:FireAllClient(...)`  
	Server sends a packet to all of the clients.

	## Supported Types

	TwoNet provides several built-in types for packet definitions, as found in `buffers.luau`:

	- `types.string` &mdash; Roblox string
	- `types.boolean` &mdash; Roblox boolean
	- `types.string` &mdash; Roblox string  
	- `types.buffer` &mdash; Roblox buffer  
	- `types.signed_8bit_int`, `types.signed_16bit_int`, `types.signed_32bit_int`, `types.signed_64bit_int` &mdash; Signed integers  
	- `types.unsigned_8bit_int`, `types.unsigned_16bit_int`, `types.unsigned_32bit_int`, `types.unsigned_64bit_int` &mdash; Unsigned integers  
	- `types.float_32`, `types.float_64` &mdash; Floating point numbers  
	- `types.vector3` &mdash; Roblox Vector3  
	- `types.cframe` &mdash; Roblox CFrame  
	- `types.struct` &mdash; Define a struct using the above types  
	- `types.array` &mdash; Array structure for the above types  

