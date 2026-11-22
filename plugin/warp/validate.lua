---@module "warp.validate"

---Option validation through warden, shared by the modules that take config
---(`warp.log`, `warp.ribbon`). warden loads on first use, so a caller that
---skips validation never downloads it.

local tbl = require "warp.table"
local wezterm = require "wezterm"

local M = {}

local warden
local schemas = {}

---@private
---@return Warden
function M.warden()
  if not warden then
    local ok, mod = pcall(require, "warden.api")
    warden = ok and mod or wezterm.plugin.require "https://github.com/sravioli/warden.wz"
  end
  return warden
end

---Check `opts` against the schema that `build` returns; `build` runs once.
---Invalid fields are logged and dropped, so one typo never discards the rest.
---@private
---@param build fun(w: Warden): table Schema builder.
---@param opts table Options to check. Not modified.
---@return table opts The options without the invalid fields.
function M.sanitize(build, opts)
  local schema = schemas[build]
  if not schema then
    schema = build(M.warden())
    schemas[build] = schema
  end
  local work = tbl.deepcopy(opts)
  local result = schema:safe_parse(work, { drop_invalid = true })
  if #(result.dropped or {}) > 0 or #result.issues > 0 or #result.warnings > 0 then
    result:log()
  end
  -- An older warden without drop_invalid returns no `input`.
  return result.input or work
end

return M
