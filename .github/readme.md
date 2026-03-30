# warp.wz

[![Tests](https://img.shields.io/github/actions/workflow/status/sravioli/warp.wz/tests.yaml?label=Tests&logo=Lua)](https://github.com/sravioli/warp.wz/actions?workflow=tests)
[![Lint](https://img.shields.io/github/actions/workflow/status/sravioli/warp.wz/lint.yaml?label=Lint&logo=Lua)](https://github.com/sravioli/warp.wz/actions?workflow=lint)
[![Coverage](https://img.shields.io/coverallsCoverage/github/sravioli/warp.wz?label=Coverage&logo=coveralls)](https://coveralls.io/github/sravioli/warp.wz)

General-purpose utility library for
[WezTerm](https://wezfurlong.org/wezterm/) plugins and configuration code.

- String utilities: padding, trimming, splitting, ANSI stripping, visible-width
  truncation
- Table utilities: type checks, shallow/deep copy, map/filter, merge, sorted
  iteration
- List utilities: contains, slice, unique, binary search, reverse, Cartesian
  product
- Math helpers: IEEE 754 half-to-even rounding, round-to-multiple, clamping
- Filesystem helpers: platform detection, home directory, git root, pane CWD/hostname
- Path helpers: component shortening, column-budget truncation, joining

## Installation

```lua
local wezterm = require "wezterm"

-- from git
local warp = wezterm.plugin.require "https://github.com/sravioli/warp.wz"

-- from a local checkout
local warp = wezterm.plugin.require("file:///" .. wezterm.config_dir .. "/plugins/warp.wz")
```

## Usage

```lua
-- require individual modules
local str = require "warp.string"
local tbl = require "warp.table"
local maths = require "warp.maths"
local list = require "warp.list"
local fs = require "warp.filesystem"
local path = require "warp.path"

-- or use the aggregated API (list, maths, table only)
local warp = require "warp"
warp.list.reverse { 3, 2, 1 }              -- { 1, 2, 3 }
warp.maths.clamp(15, 0, 10)                -- 10
warp.table.deep_equal({ a = 1 }, { a = 1 }) -- true
```

## Modules

The plugin provides six sub-modules. Three are also accessible via the
public API:

```lua
local warp = require "warp"
warp.list   -- list (sequence) utilities
warp.maths  -- math helpers
warp.table  -- general table utilities
```

The remaining modules are loaded individually:

```lua
local str  = require "warp.string"     -- string utilities
local fs   = require "warp.filesystem" -- OS / pane helpers
local path = require "warp.path"       -- path manipulation
```

## String

String utilities for padding, trimming, splitting, and column-aware
truncation. All truncation functions are ANSI-safe and operate on visible
column widths via WezTerm's `column_width()`.

### Constants

| Name        | Type     | Description                          |
| ----------- | -------- | ------------------------------------ |
| `empty`     | string   | Empty string (`""`).                 |
| `space`     | string   | Single space (`" "`).                |
| `col_width` | function | WezTerm's `column_width()` function. |

### Functions

| Function                     | Description                                       |
| ---------------------------- | ------------------------------------------------- |
| `strip_ansi(s)`              | Strip ANSI/VT escape sequences.                   |
| `width(s)`                   | Visible column width (ANSI-safe).                 |
| `pad(s, padding?, ch?)`      | Pad both sides.                                   |
| `padl(s, padding?, ch?)`     | Pad left side.                                    |
| `padr(s, padding?, ch?)`     | Pad right side.                                   |
| `trim(s)`                    | Remove leading/trailing whitespace.               |
| `gsplit(s, sep, opts?)`      | Iterator over substrings split by pattern.        |
| `split(s, sep, opts?)`       | Split string into a list.                         |
| `fits(s, budget)`            | Check whether string fits within column budget.   |
| `truncate_right(s, budget)`  | Truncate from right with ellipsis.                |
| `truncate_left(s, budget)`   | Truncate from left with ellipsis.                 |
| `truncate_middle(s, budget)` | Truncate from middle with ellipsis.               |
| `truncate(mode, s, budget)`  | Truncate using strategy: `left`/`middle`/`right`. |

## Table

General-purpose table utilities: type introspection, copying, transforming,
merging, and sorted iteration.

### Functions

| Function                      | Description                                 |
| ----------------------------- | ------------------------------------------- |
| `isempty(tbl)`                | `true` when list portion is empty.          |
| `isblank(tbl)`                | `true` when table has no entries at all.    |
| `islist(tbl)`                 | `true` for contiguous 1-based sequences.    |
| `isarray(tbl)`                | `true` when all keys are integers.          |
| `copy(obj)`                   | Shallow copy.                               |
| `deepcopy(obj, noref?)`       | Deep copy (handles circular refs).          |
| `keys(tbl)`                   | All keys as a list.                         |
| `values(tbl)`                 | All values as a list.                       |
| `map(tbl, fn)`                | Apply `fn` to every value, preserving keys. |
| `filter(tbl, fn)`             | Keep values matching predicate.             |
| `contains(tbl, value, opts?)` | Check table for value or predicate match.   |
| `count(tbl)`                  | Total number of key-value pairs.            |
| `deep_equal(a, b)`            | Recursive equality comparison.              |
| `get(tbl, ...)`               | Index into nested tables by key chain.      |
| `extend(behavior, ...)`       | Merge tables (`error`/`keep`/`force`).      |
| `deep_extend(behavior, ...)`  | Recursive merge of hash-like sub-tables.    |
| `spairs(tbl)`                 | Sorted key-value iterator.                  |

## Maths

IEEE 754 rounding and clamping helpers.

### Functions

| Function                          | Description                               |
| --------------------------------- | ----------------------------------------- |
| `round(number)`                   | Round to nearest integer (half-to-even).  |
| `round_to(number, multiple)`      | Round to nearest multiple (half-to-even). |
| `clamp(number, minimum, maximum)` | Clamp to `[minimum, maximum]`.            |

## List

Sequence-oriented utilities operating on the array portion of tables.

### Functions

| Function                         | Description                                     |
| -------------------------------- | ----------------------------------------------- |
| `contains(list, value)`          | Check if list contains a value.                 |
| `extend(dst, src, start?, fin?)` | Append range of `src` into `dst` in-place.      |
| `slice(list, start?, finish?)`   | Create a sub-list copy.                         |
| `unique(list, key?)`             | Remove duplicates in-place.                     |
| `bisect(list, val, opts?)`       | Binary search for insertion point.              |
| `reverse(list)`                  | Reverse in-place.                               |
| `cartesian_iter(sets)`           | Iterator over Cartesian product (shared table). |
| `cartesian_iter_copy(sets)`      | Iterator over Cartesian product (copied table). |
| `cartesian(sets)`                | All Cartesian product combinations.             |

## Filesystem

Platform detection, home directory resolution, git root discovery, and
pane URI parsing for WezTerm.

### Constants

| Name            | Type    | Description                       |
| --------------- | ------- | --------------------------------- |
| `target_triple` | string  | Platform target triple.           |
| `is_win`        | boolean | `true` on Windows.                |
| `home`          | string  | User home directory (normalized). |

### Functions

| Function                            | Description                                           |
| ----------------------------------- | ----------------------------------------------------- |
| `platform()`                        | Get platform info (OS name + boolean flags).          |
| `basename(path)`                    | Extract final component of a path.                    |
| `find_git_dir(directory)`           | Traverse up to find `.git/HEAD`.                      |
| `get_hostname(pane)`                | Hostname from pane URI (title-cased, domain removed). |
| `get_cwd(pane, search_git_root?)`   | CWD from pane URI, optionally resolved to git root.   |
| `get_cwd_hostname(pane, git_root?)` | _(Deprecated)_ Returns both CWD and hostname.         |

## Path

Path abbreviation and column-budget-aware truncation.

### Constants

| Name        | Type    | Description                        |
| ----------- | ------- | ---------------------------------- |
| `is_win`    | boolean | `true` on Windows.                 |
| `separator` | string  | Platform path separator (`/`/`\`). |

### Functions

| Function                    | Description                                        |
| --------------------------- | -------------------------------------------------- |
| `shorten(path, len)`        | Abbreviate intermediate components to `len` chars. |
| `shorten_to(path, max_len)` | Shorten path to fit within column budget.          |
| `concat(...)`               | Join components with platform separator.           |

## Examples

Truncate a path to fit the tab bar:

```lua
local path = require "warp.path"
local short = path.shorten_to("~/projects/my-app/src/components", 25)
-- "~/p/m/s/components"
```

Binary search in a sorted list:

```lua
local list = require "warp.list"
local t = { 1, 3, 5, 7, 9 }
local idx = list.bisect(t, 6) -- 4 (insert before 7)
```

Deep merge configuration tables:

```lua
local tbl = require "warp.table"
local defaults = { ui = { theme = "dark", font_size = 14 } }
local overrides = { ui = { font_size = 16 } }
local config = tbl.deep_extend("force", defaults, overrides)
-- { ui = { theme = "dark", font_size = 16 } }
```

Column-aware string truncation:

```lua
local str = require "warp.string"
str.truncate_middle("plasma-csd-generator.rebupk", 18)
-- "plasma-c…rebupk"
```

Get CWD and hostname from a WezTerm pane:

```lua
local fs = require "warp.filesystem"
local cwd = fs.get_cwd(pane, false)  -- "~/projects/warp.wz"
local host = fs.get_hostname(pane)    -- "Mybox"
```

## License

Code is licensed under the [GNU General Public License v2](../LICENSE). Documentation
is licensed under [Creative Commons Attribution-NonCommercial 4.0 International](../LICENSE-DOCS).
