local chrono = require "chrono"
local tbl = require "plugin.warp.table"

local islist = tbl.islist

local ITERATIONS = 1e6

local suite = chrono.suite("tbl.islist", { iterations = ITERATIONS, warmup = 100 })

local empty_tbl = {}
local small_list = { 1, 2, 3, 4, 5 }
local medium_list = {}
for i = 1, 100 do
  medium_list[i] = i
end
local hash_only = { a = 1, b = 2, c = 3 }
local mixed_tbl = { 1, 2, 3, a = "x", b = "y" }

suite:add("islist empty table", function()
  local _ = islist(empty_tbl)
end)

suite:add("islist small (5)", function()
  local _ = islist(small_list)
end)

suite:add("islist medium (100)", function()
  local _ = islist(medium_list)
end)

suite:add("islist hash-only", function()
  local _ = islist(hash_only)
end)

suite:add("islist mixed", function()
  local _ = islist(mixed_tbl)
end)

suite:add("islist non-table", function()
  local _ = islist "string"
end)

return suite
