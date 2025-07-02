--!strict
local TwoNet = require(game.ReplicatedStorage.Packages.TwoNet)
local Types = TwoNet.types

return table.freeze{
	HelloPacket = TwoNet.packet(Types.string)
}