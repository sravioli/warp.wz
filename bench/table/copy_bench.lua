local chrono = require "chrono"
local tbl = require "plugin.warp.table"

local copy = tbl.copy

local ITERATIONS_ALLOC = 1e5

local suite = chrono.suite("tbl.copy", { iterations = ITERATIONS_ALLOC, warmup = 100 })

local small_list = { 1, 2, 3, 4, 5 }
local medium_list = {}
for i = 1, 100 do
  medium_list[i] = i
end
local hash_only = { a = 1, b = 2, c = 3 }

suite:add("copy small (5)", function()
  local _ = copy(small_list)
end)

suite:add("copy medium (100)", function()
  local _ = copy(medium_list)
end)

suite:add("copy hash-only", function()
  local _ = copy(hash_only)
end)

suite:add("copy non-table", function()
  local _ = copy(42)
end)

return suite
