--!strict
--!optimize 2
--!native

export type func = (...any) -> ()

local config = require(script.config)

local threshold = config.sweeperThreshold
local interval = config.sweeperInterval
local removalPercent = config.sweeperRemovalPercent
local threadPool: { thread } = {}

task.defer(function()
	while true do
		task.wait(interval)

		local threadCount = #threadPool
		if threadCount > threshold then
			local removalCount = math.floor( (threadCount - threshold) * removalPercent)
			for _ = 1, removalCount do
				local thread = table.remove(threadPool)
				if thread then
					coroutine.close(thread)
				end
			end
		end

	end
end)

local function resume(f: func, ... : any)
	f(...)
	table.insert(threadPool, coroutine.running())
end

local function halt()
	while true do
		resume(coroutine.yield())
	end
end

local FastTask = {}

function FastTask.spawn(f: func, ... : any)
	return task.spawn(table.remove(threadPool) or task.spawn(halt), f, ...)
end

function FastTask.defer(f: func, ... : any)
	return task.defer(table.remove(threadPool) or task.spawn(halt), f, ...)
end

function FastTask.delay(delay: number, f: func, ... : any)
	return task.delay(delay, table.remove(threadPool) or task.spawn(halt), f, ...)
end


return table.freeze(FastTask)