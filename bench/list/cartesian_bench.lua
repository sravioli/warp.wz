local chrono = require "chrono"
local list = require "plugin.warp.list"

local cartesian = list.cartesian

local ITERATIONS_HEAVY = 1e4

local suite =
  chrono.suite("list.cartesian", { iterations = ITERATIONS_HEAVY, warmup = 100 })

local cart_small = { { 1, 2 }, { "a", "b" } }
local cart_medium = { { 1, 2, 3 }, { "a", "b", "c" }, { true, false } }
local cart_large = { { 1, 2, 3, 4 }, { "a", "b", "c", "d" }, { true, false }, { 10, 20 } }
local cart_larger = {
  { 1, 2, 3, 4, 5, 6 },
  { "a", "b", "c", "d", "e" },
  { true, false, true, false, true, false },
  { 10, 20, 30, 40, 50, 60 },
}

suite:add("cartesian 2x2 (4)", function()
  local _ = cartesian(cart_small)
end)

suite:add("cartesian 3x3x2 (18)", function()
  local _ = cartesian(cart_medium)
end)

suite:add("cartesian 4x4x2x2 (64)", function()
  local _ = cartesian(cart_large)
end)

suite:add("cartesian 6x5x6x6 (10800)", function()
  local _ = cartesian(cart_larger)
end)

return suite
