--!strict
--!native
--!optimize 2

local config = require(script:WaitForChild("config"))
local types = require(script:WaitForChild("types"))

export type Signal<T...> = types.Signal<T...>

if not game.ReplicatedStorage.FastTasks then
	error(`FastTasks not found in ReplicatedStorage. Please add https://github.com/TwocelGames/FastTasks.`)
end
local FastTask = require(game.ReplicatedStorage.FastTasks)

local newThread = (config.RUN_SIGNALS_IMMEDIATLY and FastTask.spawn) or FastTask.defer
local resumeThread: any = (config.RUN_SIGNALS_IMMEDIATLY and task.spawn) or task.defer

-- Connection Object
local Connection: types.Connection = {}:: types.Connection
Connection["__index"] = Connection

function Connection:Disconnect()
	local prev = self._prev
	local next = self._next
	prev._next = next
	next._prev = prev
end

-- Signal Object
local Signal: types.Signal = {}:: types.Signal
Signal["__index"] = Signal

-- The signal in itself is a node in the linked list.
function Signal:Connect(callback: types.Callback)
	local prev = self._prev
	local connection: types.Connection = (setmetatable({}, Connection) :: any)
	connection._prev = self._prev
	connection._next = self
	prev._next = connection
	self._prev = connection
	connection._callback = callback
	return connection
end

function Signal:Once(callback: types.Callback)
local prev = self._prev
	local connection: types.Connection = (setmetatable({}, Connection) :: any)
	connection._prev = self._prev
	connection._next = self
	prev._next = connection
	self._prev = connection
	connection._callback = callback
	connection._once = true
	return connection
end

function Signal:Wait()
	local thread = coroutine.running()
	local connection: types.Connection = (setmetatable({}, Connection) :: any)
	connection._prev = self._prev
	connection._next = self
	self._prev._next = connection
	self._prev = connection
	connection._thread = thread

	return coroutine.yield(thread)
end

function Signal:Fire(...)
	local connection = self._next :: types.Connection
	while connection.Disconnect do
		local callback = connection._callback
		if callback then
			newThread(callback, ...)
		end
		local prev = connection._prev
		local next = connection._next		
		if connection._once then
			prev._next = next
			next._prev = prev
		end

		local thread = connection._thread
		if thread then
			resumeThread(thread, ...)
		end

		connection = next:: types.Connection
	end
end

function Signal:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

return function(): types.Signal
	local signal: types.Signal = (setmetatable({}, Signal) :: any)
	signal._prev = signal
	signal._next = signal
	return signal
end