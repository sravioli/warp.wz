local chrono = require "chrono"
local list = require "plugin.warp.list"

local cartesian_iter_copy = list.cartesian_iter_copy

local ITERATIONS_HEAVY = 1e4

local suite = chrono.suite(
  "list.cartesian_iter_copy",
  { iterations = ITERATIONS_HEAVY, warmup = 100 }
)

local cart_small = { { 1, 2 }, { "a", "b" } }
local cart_medium = { { 1, 2, 3 }, { "a", "b", "c" }, { true, false } }
local cart_large = { { 1, 2, 3, 4 }, { "a", "b", "c", "d" }, { true, false }, { 10, 20 } }

suite:add("cartesian_iter_copy 2x2 (4)", function()
  for _ in cartesian_iter_copy(cart_small) do
  end
end)

suite:add("cartesian_iter_copy 3x3x2 (18)", function()
  for _ in cartesian_iter_copy(cart_medium) do
  end
end)

suite:add("cartesian_iter_copy 4x4x2x2 (64)", function()
  for _ in cartesian_iter_copy(cart_large) do
  end
end)

return suite
