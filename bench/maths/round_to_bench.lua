local chrono = require "chrono"
local maths = require "plugin.warp.maths"

local round_to = maths.round_to

local ITERATIONS = 1e6

local suite = chrono.suite("maths.round_to", { iterations = ITERATIONS, warmup = 100 })

suite:add("round_to multiple of 5", function()
  local _ = round_to(17, 5)
end)

suite:add("round_to multiple of 10", function()
  local _ = round_to(123, 10)
end)

suite:add("round_to multiple of 3", function()
  local _ = round_to(14, 3)
end)

suite:add("round_to already aligned", function()
  local _ = round_to(20, 5)
end)

return suite
