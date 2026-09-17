///|
test "build_command converts simple command" {
  let cmd : @admiral.CommandDef = {
    name: "greet",
    description: "Greet someone",
    options: [
      @admiral.string(
        "name",
        short='n',
        description="Name to greet",
        required=true,
      ),
      @admiral.bool("verbose", short='v', description="Verbose output"),
      @admiral.int(
        "count",
        short='c',
        description="Repeat count",
        default=Some(1),
      ),
    ],
    positionals: [],
    examples: [],
    subcommands: [],
    run: Some(fn(_ctx) { () }),
  }
  let argparse_cmd = @admiral.build_command(cmd)
  let help = argparse_cmd.render_help()
  inspect(help.contains("greet"), content="true")
  inspect(help.contains("--name"), content="true")
  inspect(help.contains("--verbose"), content="true")
  inspect(help.contains("--count"), content="true")
}

///|
test "build_command converts nested subcommands" {
  let sub : @admiral.CommandDef = {
    name: "serve",
    description: "Start server",
    options: [@admiral.int("port", short='p', description="Port")],
    positionals: [],
    examples: [],
    subcommands: [],
    run: Some(fn(_ctx) { () }),
  }
  let root : @admiral.CommandDef = {
    name: "app",
    description: "My app",
    options: [],
    positionals: [],
    examples: [],
    subcommands: [sub],
    run: None,
  }
  let argparse_cmd = @admiral.build_command(root)
  let help = argparse_cmd.render_help()
  inspect(help.contains("serve"), content="true")
}
