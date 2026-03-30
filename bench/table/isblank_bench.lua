local chrono = require "chrono"
local tbl = require "plugin.warp.table"

local isblank = tbl.isblank

local ITERATIONS = 1e6

local suite = chrono.suite("tbl.isblank", { iterations = ITERATIONS, warmup = 100 })

local empty_tbl = {}
local small_list = { 1, 2, 3, 4, 5 }
local hash_only = { a = 1, b = 2, c = 3 }

suite:add("isblank nil", function()
  local _ = isblank(nil)
end)

suite:add("isblank empty table", function()
  local _ = isblank(empty_tbl)
end)

suite:add("isblank non-empty list", function()
  local _ = isblank(small_list)
end)

suite:add("isblank hash-only table", function()
  local _ = isblank(hash_only)
end)

return suite
