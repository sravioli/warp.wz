local chrono = require "chrono"
local list = require "plugin.warp.list"

local contains = list.contains

local ITERATIONS = 1e6

local suite = chrono.suite("list.contains", { iterations = ITERATIONS, warmup = 100 })

local small_list = { 1, 2, 3, 4, 5 }
local medium_list = {}
for i = 1, 100 do
  medium_list[i] = i
end

suite:add("contains hit (first)", function()
  local _ = contains(small_list, 1)
end)

suite:add("contains hit (last)", function()
  local _ = contains(small_list, 5)
end)

suite:add("contains miss", function()
  local _ = contains(small_list, 99)
end)

suite:add("contains medium hit (last)", function()
  local _ = contains(medium_list, 100)
end)

suite:add("contains medium miss", function()
  local _ = contains(medium_list, 999)
end)

return suite
