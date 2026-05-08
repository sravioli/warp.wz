# warp.wz

[![Awesome](https://awesome.re/mentioned-badge.svg)](https://github.com/michaelbrusegard/awesome-wezterm)
[![Tests](https://img.shields.io/github/actions/workflow/status/sravioli/warp.wz/tests.yaml?label=Tests&logo=Lua)](https://github.com/sravioli/warp.wz/actions?workflow=tests)
[![Lint](https://img.shields.io/github/actions/workflow/status/sravioli/warp.wz/lint.yaml?label=Lint&logo=Lua)](https://github.com/sravioli/warp.wz/actions?workflow=lint)
[![Coverage](https://img.shields.io/coverallsCoverage/github/sravioli/warp.wz?label=Coverage&logo=coveralls)](https://coveralls.io/github/sravioli/warp.wz)

Utility library for [WezTerm](https://wezfurlong.org/wezterm/) plugins and
configuration code.

- String utilities: padding, trimming, splitting, ANSI stripping, visible-width
  truncation
- Table utilities: type checks, shallow/deep copy, map/filter, merge, sorted
  iteration
- List utilities: contains, slice, unique, binary search, reverse, Cartesian
  product
- Math helpers: IEEE 754 half-to-even rounding, round-to-multiple, clamping
- Filesystem helpers: platform detection, home directory, git root, pane CWD,
  hostname
- Path helpers: component shortening, column-budget truncation, joining

## Installation

```lua
local wezterm = require "wezterm"

-- from git
local warp = wezterm.plugin.require "https://github.com/sravioli/warp.wz"

-- from a local checkout
local warp = wezterm.plugin.require("file:///" .. wezterm.config_dir .. "/plugins/warp.wz")
```

### Type annotations

The modules include LuaCATS annotations. After installing
[wezterm-types](https://github.com/DrKJeff16/wezterm-types), annotate the import
to get autocompletion and type checking:

```lua
---@type Warp
local warp = wezterm.plugin.require "https://github.com/sravioli/warp.wz"
```

## Usage

```lua
local warp = wezterm.plugin.require "https://github.com/sravioli/warp.wz"

warp.list.reverse { 3, 2, 1 }              -- { 1, 2, 3 }
warp.maths.clamp(15, 0, 10)                -- 10
warp.table.deep_equal({ a = 1 }, { a = 1 }) -- true
warp.string.truncate_middle("long-name", 8) -- "lon…ame"
warp.path.shorten_to("~/projects/app", 12)  -- "~/p/app"
warp.filesystem.platform().os               -- "windows"
```

## Modules

The public API exposes six modules:

```lua
local warp = wezterm.plugin.require "https://github.com/sravioli/warp.wz"

warp.list       -- list (sequence) utilities
warp.maths      -- math helpers
warp.table      -- general table utilities
warp.string     -- string utilities
warp.filesystem -- OS / pane helpers
warp.path       -- path manipulation
```

## String

String helpers cover padding, trimming, splitting, and column-aware truncation.
The truncation functions are ANSI-safe and use WezTerm's `column_width()` for
visible widths.

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
| `starts_with(s, prefix)`     | Check if string starts with prefix.               |
| `ends_with(s, suffix)`       | Check if string ends with suffix.                 |
| `ljust(s, width, ch?)`       | Left-justify to total column width.               |
| `rjust(s, width, ch?)`       | Right-justify to total column width.              |

## Table

Table helpers cover type checks, copying, transforms, merging, and sorted
iteration.

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
| `merge(opts, tbl, ...)`       | In-place deep merge with `combine` support. |
| `spairs(tbl)`                 | Sorted key-value iterator.                  |
| `invert(tbl)`                 | Swap keys ↔ values.                         |
| `reduce(tbl, fn, init)`       | Fold table into a single value.             |

## Maths

IEEE 754 rounding and clamping helpers.

### Functions

| Function                          | Description                               |
| --------------------------------- | ----------------------------------------- |
| `round(number)`                   | Round to nearest integer (half-to-even).  |
| `round_to(number, multiple)`      | Round to nearest multiple (half-to-even). |
| `clamp(number, minimum, maximum)` | Clamp to `[minimum, maximum]`.            |

## List

List helpers operate on the array portion of tables.

### Functions

| Function                         | Description                                     |
| -------------------------------- | ----------------------------------------------- |
| `contains(list, value)`          | Check if list contains a value.                 |
| `extend(dst, src, start?, fin?)` | Append range of `src` into `dst` in-place.      |
| `extend_unique(dst, src)`        | Append items from `src` skipping duplicates.    |
| `slice(list, start?, finish?)`   | Create a sub-list copy.                         |
| `unique(list, key?)`             | Remove duplicates in-place.                     |
| `bisect(list, val, opts?)`       | Binary search for insertion point.              |
| `reverse(list)`                  | Reverse in-place.                               |
| `cartesian_iter(sets)`           | Iterator over Cartesian product (shared table). |
| `cartesian_iter_copy(sets)`      | Iterator over Cartesian product (copied table). |
| `cartesian(sets)`                | All Cartesian product combinations.             |
| `find(list, fn)`                 | First element matching predicate.               |
| `flatten(list, depth?)`          | Flatten nested lists.                           |
| `zip(...)`                       | Combine parallel lists into tuples.             |

## Filesystem

Filesystem helpers cover platform detection, home directory resolution, git
root discovery, and WezTerm pane URI parsing.

### Constants

| Name     | Type    | Description                       |
| -------- | ------- | --------------------------------- |
| `is_win` | boolean | `true` on Windows.                |
| `home`   | string  | User home directory (normalized). |

### Functions

| Function                            | Description                                           |
| ----------------------------------- | ----------------------------------------------------- |
| `platform()`                        | Get platform info (OS name + boolean flags).          |
| `basename(path)`                    | Extract final component of a path.                    |
| `find_git_dir(directory)`           | Traverse up to find `.git/HEAD`.                      |
| `get_hostname(pane)`                | Hostname from pane URI (title-cased, domain removed). |
| `get_cwd(pane, search_git_root?)`   | CWD from pane URI, optionally resolved to git root.   |
| `get_cwd_hostname(pane, git_root?)` | _(Deprecated)_ Returns both CWD and hostname.         |
| `is_dir(path)`                      | Check whether path is a directory.                    |
| `read_file(path)`                   | Read entire contents of a small file.                 |

## Path

Path helpers cover normalization, joining, and compact display paths.

### Constants

| Name        | Type    | Description                                               |
| ----------- | ------- | --------------------------------------------------------- |
| `is_win`    | boolean | Reexported from `filesystem.is_win`.                      |
| `separator` | string  | Platform path separator (`/`/`\`), derived from `is_win`. |

### Functions

| Function                    | Description                                                                                             |
| --------------------------- | ------------------------------------------------------------------------------------------------------- |
| `shorten(path, len)`        | Truncate each intermediate component to `len` chars, keeping the last component intact.                 |
| `shorten_to(path, max_len)` | Fit a path within `max_len` visible columns by auto-shortening dirs and middle-truncating if necessary. |
| `concat(...)`               | Join components with platform separator.                                                                |
| `normalize(path)`           | Collapse `.`, `..`, repeated separators.                                                                |
| `dirname(path)`             | Parent directory of a path.                                                                             |
| `extension(path)`           | File extension including leading dot.                                                                   |
| `is_absolute(path)`         | Check whether path is absolute.                                                                         |
| `expand(path)`              | Expand `~` to home directory.                                                                           |

## Examples

Shorten intermediate path components to a fixed length:

```lua
warp.path.shorten("~/projects/my-app/src/components", 1)
-- "~/p/m/s/components"

warp.path.shorten("~/projects/my-app/src/components", 3)
-- "~/pro/my-/src/components"
```

Fit a path within a column budget. `shorten_to` picks the component length and
middle-truncates the last component when needed:

```lua
warp.path.shorten_to("~/projects/my-app/src/components", 25)
-- "~/p/m/s/components"

warp.path.shorten_to("~/projects/my-app/src/components", 14)
-- "~/p/m/s/comp…nts"
```

Binary search in a sorted list:

```lua
local t = { 1, 3, 5, 7, 9 }
local idx = warp.list.bisect(t, 6) -- 4 (insert before 7)
```

Deep merge configuration tables:

```lua
local defaults = { ui = { theme = "dark", font_size = 14 } }
local overrides = { ui = { font_size = 16 } }
local config = warp.table.deep_extend("force", defaults, overrides)
-- { ui = { theme = "dark", font_size = 16 } }
```

In-place merge with list combining:

```lua
local base = { ui = { theme = "dark" }, plugins = { "a", "b" } }
local extra = { ui = { font_size = 16 }, plugins = { "b", "c" } }
warp.table.merge({ behavior = "force", combine = true }, base, extra)
-- base is now { ui = { theme = "dark", font_size = 16 }, plugins = { "a", "b", "c" } }
```

Column-aware string truncation:

```lua
warp.string.truncate_middle("plasma-csd-generator.rebupk", 18)
-- "plasma-c…rebupk"
```

Get CWD and hostname from a WezTerm pane:

```lua
local cwd = warp.filesystem.get_cwd(pane, false)  -- "~/projects/warp.wz"
local host = warp.filesystem.get_hostname(pane)    -- "Mybox"
```

## License

Code is licensed under the [GNU General Public License v2](../LICENSE). Documentation
is licensed under [Creative Commons Attribution-NonCommercial 4.0 International](../LICENSE-DOCS).
