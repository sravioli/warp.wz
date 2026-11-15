# warp.wz

[![Awesome](https://awesome.re/mentioned-badge.svg)](https://github.com/michaelbrusegard/awesome-wezterm)
[![Tests](https://img.shields.io/github/actions/workflow/status/sravioli/warp.wz/tests.yaml?style=flat-square&label=tests)](https://github.com/sravioli/warp.wz/actions/workflows/tests.yaml)
[![Lint](https://img.shields.io/github/actions/workflow/status/sravioli/warp.wz/lint.yaml?style=flat-square&label=lint)](https://github.com/sravioli/warp.wz/actions/workflows/lint.yaml)
[![Coverage](https://img.shields.io/coverallsCoverage/github/sravioli/warp.wz?label=Coverage&logo=coveralls)](https://coveralls.io/github/sravioli/warp.wz)
[![Code license](https://img.shields.io/badge/code-GPL--2.0-blue?style=flat-square)](../LICENSE)
[![Docs license](https://img.shields.io/badge/docs-CC_BY--NC_4.0-blue?style=flat-square)](../LICENSE-DOCS)

String, table, list, path, and process utilities for [WezTerm](https://wezterm.org/).

Merge config, size status labels, read pane directories, or run child
processes from argument lists. All seven modules share one import; importing
them does not start child processes.

[Quick start](#quick-start) · [Usage](#usage) · [Configuration](#configuration) · [API reference](#api-reference) · [Troubleshooting](#troubleshooting) · [Development](#development) · [License](#license)

## Quick start

### Requirements

Requires **WezTerm [`20230320-124340-559cb7b0`](https://wezterm.org/config/lua/wezterm.plugin/require.html)
or newer** and Git. No plugin dependencies or special fonts are required.

Process helpers need their target executable; directory creation uses `mkdir`
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

Reload to apply opacity `0.9`; **Ctrl+Shift+L** shows `Warp loaded`.
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
Quoting helpers prepare trusted text for a shell; they do not make untrusted
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

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `split.plain` | `boolean?` | `nil` | `split`/`gsplit`: treat the separator literally when true; otherwise use a Lua pattern. |
| `split.trimempty` | `boolean?` | `nil` | Trim empty edge segments when true. |
| `contains.predicate` | `boolean?` | `nil` | `table.contains`: treat the value argument as a predicate when true. |
| `merge.behavior` | `"error"\|"keep"\|"force"` | `"keep"` | Reject conflicts, keep earlier values, or use later values. |
| `merge.combine` | `boolean?` | `nil` | Append unique incoming list values instead of replacing them. |
| `bisect.lo` | `integer` | `1` | Inclusive lower search bound. |
| `bisect.hi` | `integer` | `#list + 1` | Computed exclusive upper bound. |
| `bisect.key` | `fun(value: any): any` | `nil` | Project both target and list elements before comparison. |
| `bisect.bound` | `"lower"\|"upper"` | `"lower"` | First or last valid insertion point in a sorted list. |

#### Executable lookup and execution

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `which.path` | `string?` | `nil` | Override the program name/path being searched. |
| `which.dirs` | `string[]?` | `nil` | Extra directories searched before `PATH` and built-in locations. |
| `which.cache` | `boolean` | `true` | Cache both successes and misses for the current Lua context. |
| `run.resolve` | `boolean` | `true` | Resolve argv's first element through `which`; otherwise use it unchanged. |
| `run.which` | `Warp.Process.WhichOpts?` | `nil` | Forward lookup options; nested paths are `run.which.path`, `.dirs`, `.cache` as above. |

### Behavior and precedence

Per-call options do not persist. Executable lookup is the exception: it caches
both successes and misses in Lua state until `clear_cache` or a config reload.
Search order is explicit path/name, extra directories, `PATH`, then common
install locations. A name containing a separator is checked directly.
Lookup tests whether a file is readable, not whether it has executable permission.

`extend`/`deep_extend` return new outer tables; `merge` changes its destination.
Recursive merges combine map-like tables, while lists replace according to
the conflict policy unless `combine` is enabled. An empty table can replace
a list but merges into a map. Assigned subtrees may still reference inputs.
Warp does not schema-validate options or general utility inputs.

List operations use the dense `1..#list` portion. Cartesian iterators can
produce very large outputs: `cartesian_iter` reuses one tuple table,
`cartesian_iter_copy` copies each, and `cartesian` materializes all tuples.

## API reference

All names are fully qualified below; calls use `.`. `?` marks optional
arguments or nullable results. `Iterator` means a Lua generic-for iterator;
`T` denotes an element type, not a runtime class.

### Strings

| Signature → Return type | Description |
| --- | --- |
| `warp.string.strip_ansi(text) → string` | Remove CSI escape sequences; does not strip every OSC/VT sequence. |
| `warp.string.width(text) → number` | Strip CSI sequences, then measure visible columns. |
| `warp.string.col_width(text) → integer` | Direct alias of `wezterm.column_width`; no extra stripping. |
| `warp.string.pad(value, padding?, character?) → string` | Pad both sides; default one space each. Padding may be `{ left, right }`; missing sides then mean zero. |
| `warp.string.padl(value, padding?, character?) → string` | Pad left; default one space. |
| `warp.string.padr(value, padding?, character?) → string` | Pad right; default one space. |
| `warp.string.trim(text) → string` | Trim surrounding Lua whitespace. |
| `warp.string.gsplit(text, separator, options?) → Iterator` | Iterate pieces; empty separator splits bytes. Zero-width non-empty patterns can raise. |
| `warp.string.split(text, separator, options?) → string[]` | Collect `gsplit`; options are [above](#string-splitting-table-operations-and-binary-search). |
| `warp.string.fits(text, budget) → boolean` | Test visible width against a column budget. |
| `warp.string.truncate_right(text, budget) → string` | Retain the left portion and append an ellipsis. |
| `warp.string.truncate_left(text, budget) → string` | Retain the right portion and prepend an ellipsis. |
| `warp.string.truncate_middle(text, budget) → string` | Keep both ends, favoring the left for an odd remaining budget. |
| `warp.string.truncate(mode, text, budget) → string` | Dispatch `"left"`, `"middle"`, or `"right"`; invalid modes raise. |
| `warp.string.starts_with(text, prefix) → boolean` | Literal prefix comparison. |
| `warp.string.ends_with(text, suffix) → boolean` | Literal suffix comparison; empty suffix succeeds. |
| `warp.string.ljust(text, width, character?) → string` | Pad on the right to at least this column width; default character is a space. |
| `warp.string.rjust(text, width, character?) → string` | Pad on the left; does not truncate a wider value. |

Truncation iterates UTF-8 codepoints, not grapheme clusters. When a non-fitting
string's budget is no wider than the ellipsis, the result is still `…`,
including a zero budget. Padding repeats the supplied string by count, so use
a one-column character when the final width must match.

### Tables

| Signature → Return type | Description |
| --- | --- |
| `warp.table.isempty(value) → boolean` | True for `nil` or zero array length; ignores hash-only entries. |
| `warp.table.isblank(value) → boolean` | True for `nil` or a table with no keys. |
| `warp.table.islist(value) → boolean` | Test dense 1-based sequence shape; `{}` is a list. |
| `warp.table.isarray(value) → boolean` | Test integer-only keys, including sparse/zero/negative keys; `{}` qualifies. |
| `warp.table.copy(value) → any` | Shallow-copy a table without its metatable; scalars pass through. |
| `warp.table.deepcopy(value, noref?) → any` | Copy nested values and preserve metatables; default tracks shared/cyclic references. `noref = true` is unsafe on cycles. |
| `warp.table.keys(table) → any[]` | Collect keys in unspecified order. |
| `warp.table.values(table) → any[]` | Collect values in unspecified order. |
| `warp.table.map(table, fn) → table` | Map `fn(value)`, preserving keys. |
| `warp.table.filter(table, fn) → any[]` | Keep matching values as a new list, discarding keys. |
| `warp.table.contains(table, value, options?) → boolean` | Raw equality or predicate mode over all values. |
| `warp.table.count(table) → integer` | Count all key/value pairs. |
| `warp.table.deep_equal(a, b) → boolean` | Recursive equality; respects equality metamethods, with no cycle guard for distinct cyclic tables. |
| `warp.table.get(table, ...) → any?` | Traverse a key chain; return `nil` for missing/intermediate non-table values or no keys. |
| `warp.table.extend(behavior, ...) → table` | New shallow merged table; behavior is `"error"`, `"keep"`, or `"force"`. |
| `warp.table.deep_extend(behavior, ...) → table` | New recursively merged maps; list values are atomic. |
| `warp.table.merge(options, destination, ...) → table` | In-place deep merge; options may be a behavior string or a settings table. |
| `warp.table.spairs(table) → Iterator` | Yield `(key, value)` in ascending key order; keys must be mutually comparable. |
| `warp.table.invert(table) → table` | Swap keys/values; duplicate values choose a winner in unspecified traversal order. |
| `warp.table.reduce(table, fn, initial) → any` | Fold with `fn(accumulator, value, key)` in `pairs` order. |

### Lists and maths

| Signature → Return type | Description |
| --- | --- |
| `warp.list.contains(list, value) → boolean` | Raw-equality scan of sequence values. |
| `warp.list.extend(destination, source, start?, finish?) → table` | Append an inclusive source range in place; defaults `1..#source`. |
| `warp.list.extend_unique(destination, source) → table` | Append values not already equal to a destination item; mutate destination. |
| `warp.list.slice(list, start?, finish?) → table` | Copy an inclusive range; defaults `1..#list`. |
| `warp.list.unique(list, key?) → table` | Deduplicate in place, optionally projecting comparison keys. |
| `warp.list.bisect(list, value, options?) → integer` | Find a sorted insertion point; [search options](#string-splitting-table-operations-and-binary-search). |
| `warp.list.reverse(list) → table` | Reverse sequence elements in place; preserve hash keys. |
| `warp.list.cartesian_iter(sets) → Iterator` | Yield `(index, tuple)` using one reused tuple. |
| `warp.list.cartesian_iter_copy(sets) → Iterator` | Yield independent tuple copies. |
| `warp.list.cartesian(sets) → table[]` | Materialize all combinations as independent tuples. |
| `warp.list.find(list, fn) → T?, integer?` | Return the first matching value and index. |
| `warp.list.flatten(list, depth?) → table` | New flattened sequence; default depth is unlimited. |
| `warp.list.zip(...) → table[]` | Tuple parallel lists, stopping at the shortest. |
| `warp.maths.round(number) → number` | IEEE-754 half-to-even rounding; only accurate for magnitudes below `2^51`. |
| `warp.maths.round_to(number, multiple) → number` | Half-to-even rounding to a nonzero multiple, within the quotient's supported magnitude. |
| `warp.maths.clamp(number, minimum, maximum) → number` | Clamp to inclusive ordered bounds. |

### Filesystem and paths

| Signature → Return type | Description |
| --- | --- |
| `warp.filesystem.platform() → Warp.FileSystem.Platform` | Return `{ os, is_win, is_linux, is_mac }` from WezTerm's target triple. |
| `warp.filesystem.basename(path) → string` | Last component after trimming trailing slash/backslash separators. |
| `warp.filesystem.find_git_dir(directory) → string?` | Walk upward looking for `.git/HEAD`; return a home-abbreviated root. Does not resolve Git worktree `.git` files. |
| `warp.filesystem.get_hostname(pane) → string` | Short, initially capitalized URI hostname; may be `""` without a CWD URI. |
| `warp.filesystem.get_cwd(pane, git_root?) → string` | Decode pane CWD, abbreviate home, and optionally seek a Git root; missing CWD yields `""`. |
| `warp.filesystem.get_cwd_hostname(pane, git_root?) → string, string` | Deprecated: call the focused CWD/hostname operations instead. |
| `warp.filesystem.is_dir(path) → boolean` | Probe a directory, falling back to protected `wezterm.read_dir`. |
| `warp.filesystem.mkdir(path) → boolean, string?` | Create parents or return an error; Windows invokes `cmd.exe` and rejects its metacharacters in the path. |
| `warp.filesystem.read_file(path) → string?` | Read a whole small file; return `nil` if it cannot open. |
| `warp.path.normalize(path) → string` | Collapse separators, `.` and `..`; output forward slashes, retaining supported drive/UNC roots and removing verbatim prefixes. |
| `warp.path.dirname(path) → string` | Parent directory; `"."` when there is no directory component. |
| `warp.path.extension(path) → string` | Last extension including its dot; `""` for none or a lone dotfile name. |
| `warp.path.is_absolute(path) → boolean` | Test forward-slash roots and drive-letter paths; normalize raw UNC paths first. |
| `warp.path.shorten(path, length) → string` | Byte-shorten intermediate components split on the platform separator; retain the last component. |
| `warp.path.shorten_to(path, budget) → string` | Best-effort compact display path; not a strict width cap for tiny budgets or mixed separators. |
| `warp.path.concat(...) → string` | Join with the platform separator; does not normalize or reset at absolute arguments. |
| `warp.path.expand(path) → string` | Expand a leading `~`, not `~otheruser` or environment variables. |
| `warp.path.tilde(path) → string` | Replace a whole leading home component with `~`; case-insensitive on Windows. |

Path helpers only manipulate text. They do not resolve actual filesystem
locations or guard against directory traversal.
`shorten` uses native separators; `shorten_to` also parses forward slashes, so
take care with mixed separators and Windows paths. Check the resulting width
before placing a path in a hard column budget.

### Processes

| Signature → Return type | Description |
| --- | --- |
| `warp.process.which(name, options?) → string?` | Find a readable candidate; Windows also tries `.exe`, `.cmd`, `.bat` for extensionless names. |
| `warp.process.default_dirs() → string[]` | Return platform-specific common install directories. |
| `warp.process.clear_cache() → nil` | Clear successful and failed executable lookups. |
| `warp.process.run(argv, options?) → boolean, string, string` | Return success, stdout, stderr; catch spawn exceptions and strip carriage returns. |
| `warp.process.lines(text?) → string[]` | Split output into non-empty CRLF-safe lines. |
| `warp.process.quote(argument, style?) → string` | Quote trusted shell text for `"posix"` (default), `"powershell"`, or `"cmd"`; not a general untrusted-input sanitizer. |
| `warp.process.join(argv, style?) → string` | Quote/join shell text; prepend PowerShell `&` when the program is quoted. |
| `warp.process.style_for(shell?) → string` | Infer quoting style; omitted shell defaults to PowerShell on Windows, POSIX otherwise. |

### Constants

| Constant | Value | Meaning |
| --- | --- | --- |
| `warp.string.empty` | `""` | Empty text. |
| `warp.string.space` | `" "` | One space. |
| `warp.filesystem.is_win` | Computed `boolean` | Windows target detection. |
| `warp.filesystem.home` | Computed `string` | `USERPROFILE`, then `HOME`, then WezTerm's `home` field; forward slashes. |
| `warp.path.is_win` | `warp.filesystem.is_win` | Shared platform flag. |
| `warp.path.separator` | `"\\"` or `"/"` | Native join/shorten separator. |

## Troubleshooting

### A newly installed executable is not found

Call `warp.process.clear_cache()` or reload; failed lookups are cached too.
Use an explicit path or `which.dirs` when a GUI-launched WezTerm lacks your
login shell's `PATH`. `run` returns failures rather than logging them for you.

### A shortened label is too wide

Do not assume `path.shorten_to` fits every budget. Use a final plain-string
truncation and check `string.width`; handle budgets below the ellipsis width
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
The source module is `Warp.Api`; use its
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
`bench` with `.chrono` configuration; they are not correctness tests.
See the [contribution guide](contributing.md) and use Conventional Commits.

## License

Code: [GNU GPL v2](../LICENSE). Documentation:
[CC BY-NC 4.0](../LICENSE-DOCS). Preserve existing attribution.
