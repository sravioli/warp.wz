local chrono = require "chrono"
local tbl = require "plugin.warp.table"

local deepcopy = tbl.deepcopy

local ITERATIONS_ALLOC = 1e5

local suite =
  chrono.suite("tbl.deepcopy", { iterations = ITERATIONS_ALLOC, warmup = 100 })

local small_list = { 1, 2, 3, 4, 5 }
local medium_list = {}
for i = 1, 100 do
  medium_list[i] = i
end
local nested_tbl = {
  { 1, 2, { 3, 4 } },
  { a = { b = { c = 5 } } },
  "leaf",
}

suite:add("deepcopy flat small (5)", function()
  local _ = deepcopy(small_list)
end)

suite:add("deepcopy flat medium (100)", function()
  local _ = deepcopy(medium_list)
end)

suite:add("deepcopy nested", function()
  local _ = deepcopy(nested_tbl)
end)

suite:add("deepcopy non-table", function()
  local _ = deepcopy(42)
end)

return suite
