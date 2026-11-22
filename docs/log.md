# warp.log

Tagged logging with configurable output sinks. Give each plugin or config
module its own logger, and filter messages by severity. Send the same event to
the debug overlay, a file, or a buffer in memory. One failing sink does not
stop the others.

This module was log.wz. The old URL still works and returns this module.

```lua
local wezterm = require "wezterm"
local log = wezterm.plugin.require("https://github.com/sravioli/warp.wz").log

local logger = log.new "config"
logger:warn "Configuration loaded"
```

Option validation loads [warden.wz](https://github.com/sravioli/warden.wz) the
first time you call `log.setup` or create a file or memory sink. Set
`validate = false` to never load it.

JSON sinks, including the default file format, need a
[nightly with serde support (2024-02-08) or newer](https://github.com/wezterm/wezterm/commit/8596422abf6257ecfb57b32396c56318c8231886).
Use `format = "text"` for files on stable builds.

## Usage

### Write to a file and the debug overlay

After the imports, configure logging before creating loggers:

```lua
log.setup { threshold = "INFO" }
local logger = log.new("config", true, {
  log.sinks.file { format = "text" },
})
logger:info("Window opacity = %s", 0.95)
```

The native sink remains enabled. Set `sinks.default_enabled = false` before
constructing the logger to write only to your supplied sinks.

The file sink chooses a data directory outside the config directory and creates
it if needed. For an explicit path, you must create the parent directories.
If it detects a path inside `wezterm.config_dir`, it moves the destination
outside and logs a warning to avoid config-reload loops.

### Capture messages for inspection

```lua
log.setup { threshold = "DEBUG" }
local memory = log.sinks.memory { max_entries = 100 }
local logger = log.new("picker", true, { memory })
logger:debug("Selected %s", "wave")
wezterm.log_info(memory:to_string())
```

You can also supply a sink function that receives one
[`Log.Event`](../plugin/warp/log/init.lua). Events contain `timestamp` (epoch
seconds), `datetime` (local time), numeric `level`, `level_name`, `tag`,
formatted `message`, and the original format string as `raw_message`.
Keep sink callbacks short: logging calls them synchronously.

## Configuration

### Example

`log.setup` is optional. Call it after importing the plugin, before creating
loggers. This example changes the threshold and default sink:

```lua
log.setup {
  threshold = "ERROR",
  sinks = { default_enabled = false },
}
```

### Options

| Option                  | Type              | Default  | Description                                                                                                            |
| ----------------------- | ----------------- | -------- | ---------------------------------------------------------------------------------------------------------------------- |
| `enabled`               | `boolean`         | `true`   | Global switch, checked on every message.                                                                               |
| `threshold`             | `string\|integer` | `"WARN"` | Case-insensitive `DEBUG`, `INFO`, `WARN`, `ERROR`, or a numeric threshold. An unrecognized name is logged and ignored. |
| `sinks.default_enabled` | `boolean`         | `true`   | Prepend the native WezTerm sink when constructing a logger.                                                            |
| `validate`              | `boolean`         | `true`   | Check options with warden. `false` skips the check for later `setup` calls and sink constructors too.                  |

#### File sink options

Pass these to `log.sinks.file(opts)`, not `log.setup`.

| Option      | Type                            | Default  | Description                                                                                |
| ----------- | ------------------------------- | -------- | ------------------------------------------------------------------------------------------ |
| `path`      | `string?`                       | `nil`    | Computed destination: `log.wz.log` in the platform data directory when omitted.            |
| `format`    | `"json"\|"text"`                | `"json"` | One JSON object or one formatted text line per event. Other values are logged and ignored. |
| `formatter` | `fun(event: Log.Event): string` | `nil`    | Custom serializer. Takes precedence over `format`.                                         |

On Windows the directory is `%LOCALAPPDATA%\wezterm`, falling back to
`%APPDATA%\wezterm`. On other platforms it is `$XDG_DATA_HOME/wezterm`,
falling back to `$HOME/.local/share/wezterm`. If those environment variables
are unavailable, the file sink uses the current directory.
Check the returned sink's `path` to see where it will write.

#### Memory sink options

| Option        | Type      | Default | Description                                                                                                              |
| ------------- | --------- | ------- | ------------------------------------------------------------------------------------------------------------------------ |
| `max_entries` | `integer` | `10000` | Retained events. Oldest entries are removed at capacity. `0` disables the limit. A negative value is logged and ignored. |

#### Option validation

`log.setup`, `log.sinks.file` and `log.sinks.memory` check their options
against a schema. Invalid fields are logged and ignored, and the rest still
apply. Unknown keys log a warning.
Set `validate = false` once your configuration is stable. Log then never
downloads or loads warden, and uses the options exactly as written. Typos and
wrong types then go unnoticed.

```lua
log.setup { validate = false }
```

### Behavior and precedence

`log.setup(opts)` and `log:setup(opts)` both work. `log.config.setup(opts)`
uses the same configuration. Only known settings are stored. Updates merge
the `sinks` map one level deep and retain omitted values.

Existing loggers retain their threshold and sink list. The global `enabled`
flag takes effect immediately. Each logger also exposes writable `enabled`,
`threshold`, `tag`, and `sinks` fields. A logger shallow-copies the supplied
sink list, but the sink instances remain shared.

Configuration, loggers, and memory buffers live only in Lua state. Reapply
setup after a config reload. Files you wrote remain on disk.

## API reference

See [warp.log](api.md#warplog) and the `Log` types in the
[API reference](api.md). `?` marks an optional argument or nullable return.

Messages use `string.format`. Arguments are stringified before formatting.
Use `%s` for objects. If formatting fails, Log emits the original message
instead of raising. It reports sink exceptions through `wezterm.log_error`.
The timestamp includes milliseconds when WezTerm's clock supports them.
The `os.time` fallback has second precision.

| Constant                  | Value                                                          | Meaning                      |
| ------------------------- | -------------------------------------------------------------- | ---------------------------- |
| `log.levels.levels.DEBUG` | `0`                                                            | Diagnostic messages.         |
| `log.levels.levels.INFO`  | `1`                                                            | Informational messages.      |
| `log.levels.levels.WARN`  | `2`                                                            | Warnings. Default threshold. |
| `log.levels.levels.ERROR` | `3`                                                            | Errors.                      |
| `log.levels.names`        | `{ [0] = "DEBUG", [1] = "INFO", [2] = "WARN", [3] = "ERROR" }` | Reverse lookup.              |

Sink modules load on first access. A sink that fails to load, or an unknown
sink name, raises an error. The memory sink keeps its events in a ring buffer,
so a full sink drops the oldest event in constant time.

## Troubleshooting

### A message is missing

The default threshold is `WARN`. Lower it with `log:setup { threshold = "DEBUG" }`;
loggers follow it unless you set `logger.threshold` yourself. Check both the
global and the instance `enabled` flags. After changing the default sink
setting, recreate the logger.

### File output does not appear

Inspect `file.path` and the debug overlay. For an explicit path, create its
parent directories first. Check the overlay for write and custom-formatter
errors. JSON output also needs WezTerm's serde API.

Update installed plugins with `wezterm.plugin.update_all()` from the debug
overlay, then reload the config. Report reproducible problems in
[issues](https://github.com/sravioli/warp.wz/issues), including your WezTerm
version, plugin revision, sink options, and relevant logs.
