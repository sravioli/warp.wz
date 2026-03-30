---@module "warp.api"

---Public API surface for the Warp plugin.
---
---@class Warp.Api
---@field list       Warp.List       List (sequence) utilities.
---@field maths      Warp.Maths      Math helpers.
---@field table      Warp.Table      General table utilities.
---@field filesystem Warp.FileSystem Filesystem helpers.
---@field path       Warp.Path       Path manipulation helpers.
---@field string     Warp.String     String utilities.
return {
  list = require "warp.list",
  maths = require "warp.maths",
  table = require "warp.table",
  filesystem = require "warp.filesystem",
  path = require "warp.path",
  string = require "warp.string",
}
