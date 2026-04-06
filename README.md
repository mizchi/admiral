# admiral

Declarative CLI builder for MoonBit, inspired by [gunshi](https://github.com/kazupon/gunshi).

A thin wrapper around `moonbitlang/core/argparse` that provides:

- Typed option helpers (`string`, `bool`, `int`, `positional`)
- Nested subcommand definitions with `run` callbacks
- Structured JSON schema output for AI agent integration
- Shell completion generation (bash, zsh, fish)
- Auto-generated `--help` / `--version`

## Install

Add to `moon.mod.json`:

```json
{
  "deps": {
    "mizchi/admiral": "0.1.0"
  }
}
```

Add to `moon.pkg.json`:

```json
{
  "import": ["mizchi/admiral"]
}
```

## Quick Start

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
          @admiral.string("name", short='n', description="Name to greet", required=true),
          @admiral.bool("verbose", short='v', description="Verbose output"),
          @admiral.int("count", short='c', description="Repeat count", default=Some(1)),
        ],
        examples=["myapp greet --name Alice", "myapp greet -n Bob -v -c 3"],
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

```
$ myapp greet --name Alice
Hello, Alice!

$ myapp greet -n Bob -v -c 3
Hello, Bob! (1)
Hello, Bob! (2)
Hello, Bob! (3)

$ myapp --help
Usage: myapp [command]

My CLI tool

Commands:
  greet  Greet someone

Options:
  -h, --help     Show help information.
  -V, --version  Show version information.
```

## Guide

### Defining Options

Three types of options, plus positional arguments:

```moonbit
// String option: --name value or -n value
@admiral.string("name", short='n', description="User name", required=true)

// Bool flag: --verbose or -v
@admiral.bool("verbose", short='v', description="Verbose output")

// Int option: --port 8080 or -p 8080
@admiral.int("port", short='p', description="Port number", default=Some(3000))

// Positional argument
@admiral.positional("file", description="Input file", required=true)
```

`short` is optional — omit it to only allow the long form (`--name`).

### Reading Values from Context

Inside a `run` callback, use `Context` methods to read parsed values:

```moonbit
run=Some(fn(ctx) {
  // Bool — returns false if not specified
  let verbose = ctx.get_bool("verbose")

  // String — returns None if not specified
  let name = ctx.get_string("name")       // String?

  // String (required) — raises if missing
  let name = try { ctx.get_string_required("name") } catch { _ => return }

  // Int — parses string value to Int, returns None if missing or invalid
  let port = ctx.get_int("port")           // Int?

  // Int (required) — raises if missing or not a valid integer
  let port = try { ctx.get_int_required("port") } catch { _ => return }

  // Multiple values (e.g., positional args that accept multiple values)
  let files = ctx.get_strings("files")     // Array[String]
})
```

### Nested Subcommands

Commands can nest arbitrarily deep:

```moonbit
let app = @admiral.cli(
  name="myapp",
  commands=[
    @admiral.command(
      name="db",
      description="Database commands",
      subcommands=[
        @admiral.command(
          name="migrate",
          description="Run migrations",
          subcommands=[
            @admiral.command(
              name="up",
              description="Apply pending migrations",
              options=[
                @admiral.bool("dry-run", description="Preview without applying"),
                @admiral.int("steps", short='s', description="Number of steps"),
              ],
              examples=[
                "myapp db migrate up",
                "myapp db migrate up --dry-run",
                "myapp db migrate up --steps 5",
              ],
              run=Some(fn(ctx) {
                if ctx.get_bool("dry-run") {
                  println("[DRY RUN] Would apply migrations")
                } else {
                  match ctx.get_int("steps") {
                    Some(n) => println("Applying " + n.to_string() + " migrations...")
                    None => println("Applying all pending migrations...")
                  }
                }
              }),
            ),
            @admiral.command(
              name="down",
              description="Rollback migrations",
              options=[
                @admiral.int("steps", short='s', description="Steps to rollback", default=Some(1)),
              ],
              run=Some(fn(ctx) {
                let steps = match ctx.get_int("steps") { Some(n) => n; None => 1 }
                println("Rolling back " + steps.to_string() + " migration(s)...")
              }),
            ),
          ],
        ),
        @admiral.command(
          name="seed",
          description="Seed the database",
          options=[
            @admiral.string("file", short='f', description="Seed file", default=Some("seeds/default.sql")),
          ],
          run=Some(fn(ctx) {
            let file = match ctx.get_string("file") { Some(f) => f; None => "seeds/default.sql" }
            println("Seeding from: " + file)
          }),
        ),
      ],
    ),
  ],
)
```

```
$ myapp db migrate up --dry-run
[DRY RUN] Would apply migrations

$ myapp db migrate down --steps 3
Rolling back 3 migration(s)...

$ myapp db seed --file custom.sql
Seeding from: custom.sql
```

### Positional Arguments

```moonbit
@admiral.command(
  name="cat",
  description="Concatenate files",
  positionals=[
    @admiral.positional("files", description="Files to concatenate"),
  ],
  run=Some(fn(ctx) {
    let files = ctx.get_strings("files")
    for file in files {
      println("Reading: " + file)
    }
  }),
)
```

```
$ myapp cat a.txt b.txt c.txt
Reading: a.txt
Reading: b.txt
Reading: c.txt
```

### Testing with Explicit argv

```moonbit
// In tests, pass argv explicitly:
app.run(argv=Some(["greet", "--name", "alice"]))

// In production, omit argv to use process args:
app.run()
```

### Structured Schema Output

admiral can output the full CLI definition as JSON — useful for AI agents, documentation generators, and tooling:

```moonbit
println(app.render_schema())         // -> JSON string
let json = app.render_schema_json()  // -> Json value
```

Example output:

```json
{
  "name": "myapp",
  "version": "1.0.0",
  "description": "My CLI tool",
  "commands": {
    "greet": {
      "description": "Greet someone",
      "options": {
        "name": { "type": "string", "description": "Name to greet", "required": true, "short": "n" },
        "verbose": { "type": "bool", "description": "Verbose output", "required": false, "short": "v" },
        "count": { "type": "int", "description": "Repeat count", "required": false, "short": "c", "default": "1" }
      },
      "examples": ["myapp greet --name Alice", "myapp greet -n Bob -v -c 3"]
    },
    "db": {
      "description": "Database commands",
      "commands": {
        "migrate": {
          "description": "Run migrations",
          "commands": {
            "up": {
              "description": "Apply pending migrations",
              "options": {
                "dry-run": { "type": "bool", "description": "Preview without applying", "required": false },
                "steps": { "type": "int", "description": "Number of steps", "required": false, "short": "s" }
              },
              "examples": ["myapp db migrate up", "myapp db migrate up --dry-run"]
            }
          }
        }
      }
    }
  }
}
```

This enables AI agents to understand CLI interfaces without parsing `--help` text — types, required/optional, defaults, and examples are all machine-readable.

### Shell Completion

Generate completion scripts for bash, zsh, and fish:

```moonbit
// Bash
println(app.render_bash_completion())

// Zsh
println(app.render_zsh_completion())

// Fish
println(app.render_fish_completion())
```

Typical usage — add a `completion` subcommand:

```moonbit
@admiral.command(
  name="completion",
  description="Generate shell completion script",
  options=[@admiral.string("shell", short='s', description="Shell type (bash, zsh, fish)", required=true)],
  run=Some(fn(ctx) {
    match ctx.get_string("shell") {
      Some("bash") => println(app.render_bash_completion())
      Some("zsh") => println(app.render_zsh_completion())
      Some("fish") => println(app.render_fish_completion())
      _ => println("Unsupported shell. Use: bash, zsh, fish")
    }
  }),
)
```

```bash
# Bash: add to ~/.bashrc
eval "$(myapp completion --shell bash)"

# Zsh: add to ~/.zshrc
eval "$(myapp completion --shell zsh)"

# Fish: save to completions dir
myapp completion --shell fish > ~/.config/fish/completions/myapp.fish
```

## API Reference

### Option Helpers

| Function | Description |
|----------|-------------|
| `string(name, short?, description?, required?, default?)` | String option (`--name value`) |
| `bool(name, short?, description?)` | Boolean flag (`--verbose`) |
| `int(name, short?, description?, required?, default?)` | Integer option (`--port 8080`) |
| `positional(name, description?, required?)` | Positional argument |

### Command Definition

| Function | Description |
|----------|-------------|
| `command(name, description?, options?, positionals?, examples?, subcommands?, run?)` | Define a command or subcommand |
| `cli(name, version?, description?, options?, commands?)` | Create a CLI app |

### Context Methods

| Method | Return | Description |
|--------|--------|-------------|
| `get_bool(name)` | `Bool` | Flag value (default: `false`) |
| `get_string(name)` | `String?` | First string value |
| `get_string_required(name)` | `String raise` | First value, raises if missing |
| `get_int(name)` | `Int?` | Parsed integer value |
| `get_int_required(name)` | `Int raise` | Parsed integer, raises if missing/invalid |
| `get_strings(name)` | `Array[String]` | All values for an option |
| `get_subcommand()` | `(String, Context)?` | Selected subcommand name and context |

### Schema & Completion

| Method | Return | Description |
|--------|--------|-------------|
| `render_schema()` | `String` | Full CLI definition as JSON string |
| `render_schema_json()` | `Json` | Full CLI definition as Json value |
| `render_bash_completion()` | `String` | Bash completion script |
| `render_zsh_completion()` | `String` | Zsh completion script |
| `render_fish_completion()` | `String` | Fish completion script |

### Running

```moonbit
app.run()                                    // use process args
app.run(argv=Some(["greet", "--name", "x"])) // explicit args (for testing)
```

`--help` and `--version` are automatically handled by argparse.

## Targets

Supports all MoonBit targets: native, js, wasm-gc.

## License

MIT
