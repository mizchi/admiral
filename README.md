# admiral

Declarative CLI builder for MoonBit, inspired by [gunshi](https://github.com/kazupon/gunshi).

A thin wrapper around `moonbitlang/core/argparse` that provides typed option helpers, structured schema output for AI agents, and a gunshi-like command definition API.

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
          @admiral.string("name", short='n', description="Name", required=true),
          @admiral.bool("verbose", short='v', description="Verbose output"),
          @admiral.int("count", short='c', description="Repeat count", default=Some(1)),
        ],
        examples=["myapp greet --name Alice", "myapp greet --name Bob --verbose"],
        run=Some(fn(ctx) {
          let name = try { ctx.get_string_required("name") } catch { _ => return }
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
  try { app.run() } catch { err => println(err) }
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
          examples=["db migrate up", "db migrate up --dry-run"],
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

### Positional Arguments

```moonbit
@admiral.command(
  name="compile",
  description="Compile source files",
  positionals=[
    @admiral.positional("input", description="Input file", required=true),
    @admiral.positional("output", description="Output file"),
  ],
  run=Some(fn(ctx) {
    let files = ctx.get_strings("input")
    // ...
  }),
)
```

### Structured Schema (for AI agents)

```moonbit
// Output CLI definition as JSON
println(app.render_schema())

// Or as Json value
let json = app.render_schema_json()
```

Output:

```json
{
  "name": "myapp",
  "version": "1.0.0",
  "commands": {
    "greet": {
      "description": "Greet someone",
      "options": {
        "name": { "type": "string", "required": true, "short": "n", "description": "Name" },
        "verbose": { "type": "bool", "required": false, "short": "v" },
        "count": { "type": "int", "required": false, "short": "c", "default": "1" }
      },
      "examples": ["myapp greet --name Alice"]
    }
  }
}
```

This enables AI agents to programmatically understand CLI tool interfaces without parsing `--help` text.

### Explicit argv

```moonbit
// Pass argv explicitly (useful for testing)
app.run(argv=Some(["greet", "--name", "alice"]))

// No argument uses process args (default for CLI apps)
app.run()
```

## API

### Option Helpers

- `string(name, short?, description?, required?, default?)` — String option (`--name value`)
- `bool(name, short?, description?)` — Boolean flag (`--verbose`)
- `int(name, short?, description?, required?, default?)` — Integer option (`--port 8080`)
- `positional(name, description?, required?)` — Positional argument

### Command Definition

- `command(name, description?, options?, positionals?, examples?, subcommands?, run?)` — Define a command
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

### Schema Output

- `app.render_schema() -> String` — JSON string of full CLI definition
- `app.render_schema_json() -> Json` — Same as `Json` value

### Running

```moonbit
app.run()  // uses process args, raises on parse error or missing command
```

`--help` and `--version` are automatically handled by argparse.

## Targets

Supports all MoonBit targets: native, js, wasm-gc.

## License

MIT
