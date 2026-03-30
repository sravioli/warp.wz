local chrono = require "chrono"
local list = require "plugin.warp.list"

local reverse = list.reverse

local ITERATIONS_ALLOC = 1e5

local suite =
  chrono.suite("list.reverse", { iterations = ITERATIONS_ALLOC, warmup = 100 })

suite:add("reverse small (5)", function()
  local t = { 1, 2, 3, 4, 5 }
  reverse(t)
end)

suite:add("reverse medium (100)", function()
  local t = {}
  for i = 1, 100 do
    t[i] = i
  end
  reverse(t)
end)

return suite
