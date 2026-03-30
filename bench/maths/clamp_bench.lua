local chrono = require "chrono"
local maths = require "plugin.warp.maths"

local clamp = maths.clamp
local min, max = math.min, math.max

local ITERATIONS = 1e6

local suite = chrono.suite("maths.clamp", { iterations = ITERATIONS, warmup = 100 })

suite:add("clamp within range", function()
  local _ = clamp(5, 0, 10)
end)

suite:add("clamp below minimum", function()
  local _ = clamp(-5, 0, 10)
end)

suite:add("clamp above maximum", function()
  local _ = clamp(15, 0, 10)
end)

suite:add("clamp at boundary (min)", function()
  local _ = clamp(0, 0, 10)
end)

suite:add("clamp at boundary (max)", function()
  local _ = clamp(10, 0, 10)
end)

suite:add("manual min/max baseline", function()
  local _ = max(0, min(10, 5))
end)

return suite
