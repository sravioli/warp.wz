# warp.ribbon

Build formatted text with chainable segments. Compose status bars and tab
titles from colored text, named attributes, and raw `wezterm.format` items.
You can still inspect and edit the underlying format-item list.

This module was ribbon.wz. The old URL still works and returns this module.

```lua
local wezterm = require "wezterm"
local ribbon = wezterm.plugin.require("https://github.com/sravioli/warp.wz").ribbon

wezterm.on("update-status", function(window)
  local status = ribbon.new "Status"
  status:append("Blue", "White", " ready ", "Bold")
  window:set_right_status(status:format())
end)
```

Option validation loads [warden.wz](https://github.com/sravioli/warden.wz) the
first time you call `ribbon.setup`. Set `validate = false` to never load it.

## Usage

### Compose several segments

Inside a renderer:

```lua
local status = ribbon.new("Status", true)
status
  :append("Blue", "White", " workspace ", "b")
  :append("Black", "Silver", " shell ", "i")
local rendered = status:format()
```

The second constructor argument enables atomic mode for this instance:
appended segments end with `ResetAttributes`, so bold or italic does not
leak into the next segment. Pass `rendered` to a WezTerm status setter.

### Mix raw items with processed text

```lua
local title = ribbon.new "Title"
title:append_items {
  { Foreground = { Color = "#57A143" } },
  { Text = "nvim " },
  "ResetAttributes",
}
title:append("Black", "White", "init.lua")
```

Raw items bypass text processing, attribute validation, color conversion,
and atomic resets. You can also pass arrays returned by
[sigil.items](https://github.com/sravioli/sigil.wz).
Use `prepend_items` when an ordered styled block must appear before existing
content. See the [prepend limitation](#prepended-text-has-unexpected-styling).

## Configuration

### Example

Setup is optional. Call it after importing Ribbon and before building
segments. This example adds a named attribute and changes text handling:

```lua
ribbon.setup {
  atomic = true,
  attribute_aliases = { strong = { "Bold", "Single" } },
  text = { strip = true, max_length = 24 },
}
```

The example overrides the defaults. Use `ribbon.config.defaults()` to inspect
the built-in attribute and color maps.

### Options

| Option                            | Type                                        | Default                    | Description                                                                                                              |
| --------------------------------- | ------------------------------------------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `log.enabled`                     | `boolean`                                   | `true`                     | Enable Ribbon's internal logger.                                                                                         |
| `log.threshold`                   | `"DEBUG"\|"INFO"\|"WARN"\|"ERROR"\|integer` | `"WARN"`                   | Minimum log level. Names are case-insensitive.                                                                           |
| `log.sinks.default_enabled`       | `boolean`                                   | `true`                     | Legacy compatibility setting. The internal logger does not use it.                                                       |
| `defaults.foreground`             | `string?`                                   | `nil`                      | Fallback foreground for segments. Absent values ultimately use `"none"`.                                                 |
| `defaults.background`             | `string?`                                   | `nil`                      | Fallback background for segments. Absent values ultimately use `"none"`.                                                 |
| `defaults.attributes.None`        | `string`                                    | `"ResetAttributes"`        | Reset marker, not an attribute table.                                                                                    |
| `defaults.attributes.NoUnderline` | `table`                                     | `{ Underline = "None" }`   | Clear underline.                                                                                                         |
| `defaults.attributes.Single`      | `table`                                     | `{ Underline = "Single" }` | Single underline.                                                                                                        |
| `defaults.attributes.Double`      | `table`                                     | `{ Underline = "Double" }` | Double underline.                                                                                                        |
| `defaults.attributes.Curly`       | `table`                                     | `{ Underline = "Curly" }`  | Curly underline.                                                                                                         |
| `defaults.attributes.Dotted`      | `table`                                     | `{ Underline = "Dotted" }` | Dotted underline.                                                                                                        |
| `defaults.attributes.Dashed`      | `table`                                     | `{ Underline = "Dashed" }` | Dashed underline.                                                                                                        |
| `defaults.attributes.Normal`      | `table`                                     | `{ Intensity = "Normal" }` | Normal intensity.                                                                                                        |
| `defaults.attributes.Bold`        | `table`                                     | `{ Intensity = "Bold" }`   | Bold intensity.                                                                                                          |
| `defaults.attributes.Half`        | `table`                                     | `{ Intensity = "Half" }`   | Half intensity.                                                                                                          |
| `defaults.attributes.Italic`      | `table`                                     | `{ Italic = true }`        | Enable italic.                                                                                                           |
| `defaults.attributes.NoItalic`    | `table`                                     | `{ Italic = false }`       | Clear italic.                                                                                                            |
| `defaults.colors.Black`           | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.Maroon`          | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.Green`           | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.Olive`           | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.Navy`            | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.Purple`          | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.Teal`            | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.Silver`          | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.Grey`            | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.Red`             | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.Lime`            | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.Yellow`          | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.Blue`            | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.Fuchsia`         | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.Aqua`            | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `defaults.colors.White`           | `boolean`                                   | `true`                     | Recognize as an ANSI color name.                                                                                         |
| `validate`                        | `boolean`                                   | `true`                     | Check options with [warden.wz](https://github.com/sravioli/warden.wz). Set `false` to skip checks and never load warden. |
| `attribute_aliases.b`             | `string`                                    | `"Bold"`                   | Short attribute alias.                                                                                                   |
| `attribute_aliases.i`             | `string`                                    | `"Italic"`                 | Short attribute alias.                                                                                                   |
| `attribute_aliases.u`             | `string`                                    | `"Single"`                 | Single underline.                                                                                                        |
| `attribute_aliases.dim`           | `string`                                    | `"Half"`                   | Half intensity.                                                                                                          |
| `attribute_aliases.reset`         | `string`                                    | `"None"`                   | Reset all attributes.                                                                                                    |
| `attribute_aliases.highlight`     | `string[]`                                  | `{ "Bold", "Single" }`     | Ordered attribute group.                                                                                                 |
| `attribute_aliases.emph`          | `string[]`                                  | `{ "Bold", "Italic" }`     | Ordered attribute group.                                                                                                 |
| `attribute_aliases.subtle`        | `string[]`                                  | `{ "Half", "Italic" }`     | Ordered attribute group.                                                                                                 |
| `validate_attributes`             | `boolean`                                   | `true`                     | Warn for unknown attribute names.                                                                                        |
| `strict_mode`                     | `boolean`                                   | `false`                    | Raise for unknown names when validation is enabled.                                                                      |
| `text.strip`                      | `boolean`                                   | `false`                    | Trim surrounding Lua whitespace first.                                                                                   |
| `text.transform`                  | `fun(text: string): string`                 | `nil`                      | Optional callback transforming the trimmed string. Must return a string.                                                 |
| `text.max_length`                 | `integer?`                                  | `nil`                      | Byte limit before appending `"..."`. Not a limit in columns or Unicode characters.                                       |
| `atomic`                          | `boolean`                                   | `false`                    | Reset attributes after each appended text segment. A constructor argument overrides it.                                  |

The attribute map is a registry, not a set applied to every segment.
Truthy entries in the color-name map emit `AnsiColor`. Other strings emit
literal `Color`. Extend these maps through setup as needed.

#### Option validation

Options are checked against a schema when you call setup. Invalid fields are logged and ignored, and the rest still apply. Unknown keys in fixed sections log a warning.
Set `validate = false` once your configuration is stable. Ribbon then never
downloads or loads warden, and uses the options exactly as written. Typos and
wrong types then go unnoticed.

```lua
ribbon.setup { validate = false }
```

### Behavior and precedence

Each setup call merges your options with fresh defaults using Warp's `"force"`
merge. Nested maps merge and lists replace. Omitted options reset to their
defaults. Previous setup values do not carry over. Ribbon does not reject
unknown keys. Settings live in Lua state and do not survive config reloads.

Segment creation reads current color, attribute, and text settings. Existing
items do not change when setup changes. An instance captures its atomic
setting and logger settings when constructed.

Ribbon runs `tostring` on text (so `nil` becomes `"nil"`), then applies trimming,
transformation, and truncation in that order. The ellipsis adds three bytes beyond
`max_length`. Transforms run synchronously and their errors propagate.
Avoid cyclic attribute aliases.

Disabling validation suppresses the initial unknown-name warning, not the
later undefined-attribute error log. WezTerm checks colors and raw format
items when formatting.

## API reference

See [warp.ribbon](api.md#warpribbon) and the `Ribbon` types in the
[API reference](api.md). `?` marks optional arguments or nullable results.
`Ribbon` is an instance. Methods returning the instance can chain.

`background` comes before `foreground`. Known ANSI names use the current
terminal palette. Hex strings use literal colors. Attributes use names in
the registry or aliases, not raw WezTerm attribute tables. Use `append_items`
for raw tables.

## Troubleshooting

### A segment changes the next segment

Use atomic mode or add an explicit reset. Raw item insertion never adds a
reset, even when the instance is atomic.

### Prepended text has unexpected styling

`prepend` inserts each generated item at index 1. The resulting text precedes
its generated style items, and an atomic reset also moves to the front.
For a styled prefix, use `prepend_items` with an ordered format-item array.
Do not assume prepending uses the same item order as appending.

### A Unicode label is cut in the middle

`text.max_length` counts bytes and can split a UTF-8 sequence. Pre-truncate
Unicode text using a suitable helper, or leave this option unset.

Update with `wezterm.plugin.update_all()` from the debug overlay and reload.
For [issues](https://github.com/sravioli/warp.wz/issues), include the raw
`r:items()` output, plugin revision, and WezTerm version.
