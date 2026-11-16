# warp.wz [![Release](https://img.shields.io/github/v/release/sravioli/warp.wz?style=flat&label=Release&logo=github)](https://github.com/sravioli/warp.wz/releases/latest)

[![Awesome](https://awesome.re/mentioned-badge.svg)](https://github.com/michaelbrusegard/awesome-wezterm)
[![Tests](https://img.shields.io/github/actions/workflow/status/sravioli/warp.wz/tests.yaml?style=flat&label=Tests&logo=githubactions)](https://github.com/sravioli/warp.wz/actions/workflows/tests.yaml)
[![Lint](https://img.shields.io/github/actions/workflow/status/sravioli/warp.wz/lint.yaml?style=flat&label=Lint&logo=githubactions)](https://github.com/sravioli/warp.wz/actions/workflows/lint.yaml)
[![Coverage](https://img.shields.io/coverallsCoverage/github/sravioli/warp.wz?style=flat&label=Coverage&logo=coveralls)](https://coveralls.io/github/sravioli/warp.wz)
[![Code license](https://img.shields.io/badge/Code-GPL--2.0-blue?style=flat&logo=gnu)](../LICENSE)
[![Docs license](https://img.shields.io/badge/Docs-CC_BY--NC_4.0-blue?style=flat&logo=creativecommons)](../LICENSE-DOCS)

String, table, list, path, and process utilities for [WezTerm](https://wezterm.org/).

Merge config, size status labels, read pane directories, or run child
processes from argument lists. All seven modules share one import. Importing
them does not start child processes.

[Quick start](#quick-start) · [Usage](#usage) · [Configuration](#configuration) · [API reference](#api-reference) · [Troubleshooting](#troubleshooting) · [Development](#development) · [License](#license)

## Quick start

### Requirements

Requires **WezTerm [`20230320-124340-559cb7b0`](https://wezterm.org/config/lua/wezterm.plugin/require.html)
or newer** and Git. No plugin dependencies or special fonts are required.

Process helpers need their target executable. Directory creation uses `mkdir`
on POSIX or `cmd.exe` on Windows. Run potentially yielding helpers from
callbacks, not during config evaluation.

### Install and run

Put this in `wezterm.lua`:

```lua
local wezterm = require "wezterm"
local warp = wezterm.plugin.require "https://github.com/sravioli/warp.wz"
local config = wezterm.config_builder()

config.window_background_opacity = warp.maths.clamp(0.9, 0, 1)
wezterm.log_info(warp.string.trim "  Warp loaded  ")

return config
```

Reload to apply opacity `0.9`. **Ctrl+Shift+L** shows `Warp loaded`.
In an existing config, reuse its builder and add the import/helper calls
before its final return.

## Usage

### Merge config maps without appending key lists

```lua
local base = { ui = { size = 12 }, names = { "a", "b" } }
local custom = { ui = { size = 14 }, names = { "c" } }
local merged = warp.table.deep_extend("force", base, custom)
```

`merged` has size `14` and names `{ "c" }`. `deep_extend` creates a new outer
table, but nested values may still be shared. Use `deepcopy` for independent
nested data. `merge("force", base, custom)` changes `base` in place.

### Size a plain-text label

```lua
local label = warp.string.truncate_middle("a-long-workspace-name", 12)
local padded = warp.string.ljust(label, 14)
wezterm.log_info(padded)
```

Widths are measured in terminal columns. Truncate plain text before adding
styles. Width measurement strips CSI escapes, but truncation does not
preserve arbitrary ANSI sequences. Tiny budgets can still return an ellipsis.

### Run a program from a key action

Add this binding alongside existing keys:

```lua
config.keys = {
  {
    key = "g",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function()
      local ok, stdout, stderr = warp.process.run { "git", "--version" }
      if ok then
        wezterm.log_info(stdout)
      else
        wezterm.log_error(stderr)
      end
    end),
  },
}
```

Press **Ctrl+Shift+G** and inspect the debug overlay. Pass a dense argv list,
not a shell command string. `run` copies arguments and does not invoke a shell.
Quoting helpers prepare trusted text for a shell. They do not make untrusted
input safe.

## Configuration

### Example

Warp has no global configuration or setup function. Pass options to the
relevant operation. For example, this custom merge appends unique list values:

```lua
local base = { names = { "a", "b" } }
warp.table.merge({ behavior = "force", combine = true }, base, {
  names = { "b", "c" },
})
```

The result in `base.names` is `{ "a", "b", "c" }`.
Other optional scalar arguments and their defaults appear in the API tables.

### Options

#### String splitting, table operations, and binary search

The paths below identify options inside each operation's options argument.

| Option               | Type                       | Default     | Description                                                                             |
| -------------------- | -------------------------- | ----------- | --------------------------------------------------------------------------------------- |
| `split.plain`        | `boolean?`                 | `nil`       | `split`/`gsplit`: treat the separator literally when true. Otherwise use a Lua pattern. |
| `split.trimempty`    | `boolean?`                 | `nil`       | Trim empty edge segments when true.                                                     |
| `contains.predicate` | `boolean?`                 | `nil`       | `table.contains`: treat the value argument as a predicate when true.                    |
| `merge.behavior`     | `"error"\|"keep"\|"force"` | `"keep"`    | Reject conflicts, keep earlier values, or use later values.                             |
| `merge.combine`      | `boolean?`                 | `nil`       | Append unique incoming list values instead of replacing them.                           |
| `bisect.lo`          | `integer`                  | `1`         | Inclusive lower search bound.                                                           |
| `bisect.hi`          | `integer`                  | `#list + 1` | Computed exclusive upper bound.                                                         |
| `bisect.key`         | `fun(value: any): any`     | `nil`       | Project both target and list elements before comparison.                                |
| `bisect.bound`       | `"lower"\|"upper"`         | `"lower"`   | First or last valid insertion point in a sorted list.                                   |

#### Executable lookup and execution

| Option        | Type                      | Default | Description                                                                            |
| ------------- | ------------------------- | ------- | -------------------------------------------------------------------------------------- |
| `which.path`  | `string?`                 | `nil`   | Override the program name/path being searched.                                         |
| `which.dirs`  | `string[]?`               | `nil`   | Extra directories searched before `PATH` and built-in locations.                       |
| `which.cache` | `boolean`                 | `true`  | Cache both successes and misses for the current Lua context.                           |
| `run.resolve` | `boolean`                 | `true`  | Resolve argv's first element through `which`. Otherwise use it unchanged.              |
| `run.which`   | `Warp.Process.WhichOpts?` | `nil`   | Forward lookup options. Nested paths are `run.which.path`, `.dirs`, `.cache` as above. |

### Behavior and precedence

Per-call options do not persist. Executable lookup is the exception: it caches
both successes and misses in Lua state until `clear_cache` or a config reload.
Search order is explicit path/name, extra directories, `PATH`, then common
install locations. A name containing a separator is checked directly.
Lookup tests whether a file is readable, not whether it has executable permission.

`extend`/`deep_extend` return new outer tables. `merge` changes its destination.
Recursive merges combine map-like tables, while lists replace according to
the conflict policy unless `combine` is enabled. An empty table can replace
a list but merges into a map. Assigned subtrees may still reference inputs.
Warp does not check options or general utility inputs against a schema.

List operations use the dense `1..#list` portion. Cartesian iterators can
produce very large outputs: `cartesian_iter` reuses one tuple table,
`cartesian_iter_copy` copies each, and `cartesian` materializes all tuples.

## API reference

The [API reference](../docs/api.md) lists every module, function, and
constant with its parameters and return values. It is generated from the LuaLS
annotations in `plugin/`, so it always matches the code.

Each module is a field of the table that `wezterm.plugin.require` returns:

| Module            | Contents                                                                  |
| ----------------- | ------------------------------------------------------------------------- |
| `warp.string`     | Visible width, ANSI stripping, padding, splitting, truncation, prefixes.  |
| `warp.table`      | Emptiness tests, copies, keys and values, merges, filters, deep equality. |
| `warp.list`       | Slices, deduplication, binary search, flattening, zips, combinations.     |
| `warp.maths`      | Rounding and clamping.                                                    |
| `warp.filesystem` | Platform, home, current directory, hostname, Git root, file reads.        |
| `warp.path`       | Normalization, parts, shortening, joining, and `~` expansion.             |
| `warp.process`    | Executable lookup, argv quoting and joining, and child processes.         |

## Troubleshooting

### A newly installed executable is not found

Call `warp.process.clear_cache()` or reload. Failed lookups are cached too.
Use an explicit path or `which.dirs` when WezTerm starts from a GUI launcher
without your login shell's `PATH`. `run` returns failures rather than logging them for you.

### A shortened label is too wide

Do not assume `path.shorten_to` fits every budget. Use a final plain-string
truncation and check `string.width`. Handle budgets below the ellipsis width
explicitly. Apply color formatting only after choosing the final text.

Update plugins with `wezterm.plugin.update_all()` from the debug overlay and
reload. Report [issues](https://github.com/sravioli/warp.wz/issues) with the
operation, input, platform, plugin revision, and WezTerm build.

## Development

### Local checkout

Load the working tree directly, so edits take effect on the next config
reload without a commit or a plugin update. Adjust the path to your clone:

```lua
local wezterm = require "wezterm"
local root = wezterm.home_dir .. "/path/to/warp.wz/plugin/"
package.path = root .. "?.lua;" .. root .. "?/init.lua;" .. package.path
local warp = require "warp.api"
```

### Editor support

Follow the [wezterm-types setup](https://github.com/DrKJeff16/wezterm-types):

```lua
---@type Warp
local warp = wezterm.plugin.require "https://github.com/sravioli/warp.wz"
```

Its [Warp definitions](https://github.com/DrKJeff16/wezterm-types/blob/main/lua/wezterm/types/plugins/warp.lua)
omit the `process` module, `filesystem.mkdir`, and `path.tilde`.
The source module is `Warp.Api`. Use its
[annotations](../plugin/warp/api.lua) and linked modules for this revision.

### Checks and contributions

From the repository root, with Lua 5.4 and the named tools installed:

```sh
busted --verbose
luacheck plugin spec
selene --display-style=quiet plugin
stylua --check plugin spec
```

Unit/integration specs use WezTerm mocks. Optional microbenchmarks live in
`bench` with `.chrono` configuration. They are not correctness tests.
See the [contribution guide](contributing.md) and use Conventional Commits.

## License

Code: [GNU GPL v2](../LICENSE). Documentation:
[CC BY-NC 4.0](../LICENSE-DOCS). Preserve existing attribution.
