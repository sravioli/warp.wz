local chrono = require "chrono"
local tbl = require "plugin.warp.table"

local isempty = tbl.isempty

local ITERATIONS = 1e6

local suite = chrono.suite("tbl.isempty", { iterations = ITERATIONS, warmup = 100 })

local empty_tbl = {}
local small_list = { 1, 2, 3, 4, 5 }
local hash_only = { a = 1, b = 2, c = 3 }

suite:add("isempty nil", function()
  local _ = isempty(nil)
end)

suite:add("isempty empty table", function()
  local _ = isempty(empty_tbl)
end)

suite:add("isempty non-empty list", function()
  local _ = isempty(small_list)
end)

suite:add("isempty hash-only table", function()
  local _ = isempty(hash_only)
end)

return suite
