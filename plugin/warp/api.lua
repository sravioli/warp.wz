---@module "warp.api"

---Public API surface for the Warp plugin.
---
---Aggregates all sub-modules into a single table so consumers can
---`require "warp.api"` and access everything through one import.
---
---@class Warp.Api
---@field list  Warp.List  List (sequence) utilities.
---@field maths Warp.Maths Math helpers.
---@field table Warp.Table General table utilities.
return {
  list = require "warp.list",
  maths = require "warp.maths",
  table = require "warp.table",
}
