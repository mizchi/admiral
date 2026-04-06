# admiral

Declarative CLI builder for MoonBit, inspired by [gunshi](https://github.com/kazupon/gunshi).

A thin wrapper around `moonbitlang/core/argparse` that provides typed option helpers and a gunshi-like command definition API.

## Install

Add to `moon.mod.json`:

```json
{
  "deps": {
    "mizchi/admiral": "0.1.0"
  }
}
```

## Usage

```moonbit
fn main {
  let app = @admiral.cli(
    name="myapp",
    version="1.0.0",
    description="My CLI tool",
    commands=[
      @admiral.command(
        name="greet",
        description="Greet someone",
        options=[
          @admiral.string("name", short=Some('n'), description="Name", required=true),
          @admiral.bool("verbose", short=Some('v'), description="Verbose output"),
          @admiral.int("count", short=Some('c'), description="Repeat count", default=Some(1)),
        ],
        run=Some(fn(ctx) {
          let name = try { ctx.get_string_required!("name") } catch { _ => return }
          let verbose = ctx.get_bool("verbose")
          let count = match ctx.get_int("count") { Some(n) => n; None => 1 }
          for i = 0; i < count; i = i + 1 {
            if verbose {
              println("Hello, " + name + "! (" + (i + 1).to_string() + ")")
            } else {
              println("Hello, " + name + "!")
            }
          }
        }),
      ),
    ],
  )
  try { app.run!(@env.args()) } catch { err => println(err) }
}
```

### Nested Subcommands

```moonbit
let app = @admiral.cli(
  name="db",
  commands=[
    @admiral.command(
      name="migrate",
      description="Database migrations",
      subcommands=[
        @admiral.command(
          name="up",
          description="Run pending migrations",
          options=[@admiral.bool("dry-run", description="Preview only")],
          run=Some(fn(ctx) {
            if ctx.get_bool("dry-run") {
              println("Dry run mode")
            }
          }),
        ),
      ],
    ),
  ],
)
```

## API

### Option Helpers

- `string(name, short?, description?, required?, default?)` — String option (`--name value`)
- `bool(name, short?, description?)` — Boolean flag (`--verbose`)
- `int(name, short?, description?, required?, default?)` — Integer option (`--port 8080`)

### Command Definition

- `command(name, description?, options?, subcommands?, run?)` — Define a command or subcommand
- `cli(name, version?, description?, options?, commands?)` — Create a CLI app

### Context Methods

| Method | Return | Description |
|--------|--------|-------------|
| `get_bool(name)` | `Bool` | Flag value (default: `false`) |
| `get_string(name)` | `String?` | First string value |
| `get_string_required(name)` | `String raise` | First string value, raises if missing |
| `get_int(name)` | `Int?` | Parsed integer value |
| `get_int_required(name)` | `Int raise` | Parsed integer, raises if missing/invalid |
| `get_strings(name)` | `Array[String]` | All values for an option |
| `get_subcommand()` | `(String, Context)?` | Selected subcommand name and context |

### Running

```moonbit
app.run!(argv)  // raises on parse error or missing command
```

`--help` and `--version` are automatically handled by argparse.

## Targets

Supports all MoonBit targets: native, js, wasm-gc.

## License

MIT
