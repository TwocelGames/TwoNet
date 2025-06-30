--!strict
--!optimize 2

return table.freeze{

	sweeperThreshold = 25, -- the number of threads to be inside to pool before we start removing them

	sweeperInterval = 5, -- the number of seconds between sweeps

	sweeperRemovalPercent = 1, -- the percentage of threads to remove from the pool each sweep

}