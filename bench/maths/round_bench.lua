local chrono = require "chrono"
local maths = require "plugin.warp.maths"

local round = maths.round

local ITERATIONS = 1e6

local suite = chrono.suite("maths.round", { iterations = ITERATIONS, warmup = 100 })

suite:add("round positive float", function()
  local _ = round(3.7)
end)

suite:add("round negative float", function()
  local _ = round(-3.7)
end)

suite:add("round half-to-even (0.5)", function()
  local _ = round(0.5)
end)

suite:add("round half-to-even (1.5)", function()
  local _ = round(1.5)
end)

suite:add("round integer (noop)", function()
  local _ = round(42)
end)

suite:add("math.floor(x+0.5) baseline", function()
  local _ = math.floor(3.7 + 0.5)
end)

return suite
