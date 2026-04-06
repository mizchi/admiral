///|
pub fn positional(
  name : String,
  description~ : String = "",
  required~ : Bool = false
) -> PositionalDef {
  { name, description, required }
}

///|
pub fn command(
  name~ : String,
  description~ : String = "",
  options~ : Array[OptionDef] = [],
  positionals~ : Array[PositionalDef] = [],
  examples~ : Array[String] = [],
  subcommands~ : Array[CommandDef] = [],
  run~ : ((Context) -> Unit)? = None
) -> CommandDef {
  { name, description, options, positionals, examples, subcommands, run }
}

///|
pub fn cli(
  name~ : String,
  version~ : String = "0.0.0",
  description~ : String = "",
  options~ : Array[OptionDef] = [],
  commands~ : Array[CommandDef] = []
) -> CliApp {
  { name, version, description, root_options: options, commands }
}

///|
fn matches_to_context(m : @argparse.Matches) -> Context {
  let sub = match m.subcommand {
    Some((name, sub_matches)) => Some((name, matches_to_context(sub_matches)))
    None => None
  }
  { flags: m.flags, values: m.values, subcommand: sub }
}

///|
fn find_command_def(commands : Array[CommandDef], name : String) -> CommandDef? {
  for cmd in commands {
    if cmd.name == name {
      return Some(cmd)
    }
  }
  None
}

///|
fn execute_command(commands : Array[CommandDef], ctx : Context) -> Unit raise {
  match ctx.subcommand {
    Some((name, sub_ctx)) =>
      match find_command_def(commands, name) {
        Some(cmd) =>
          if cmd.subcommands.length() > 0 && sub_ctx.subcommand is Some(_) {
            execute_command(cmd.subcommands, sub_ctx)
          } else {
            match cmd.run {
              Some(run_fn) => run_fn(sub_ctx)
              None => {
                let subs = cmd.subcommands.map(fn(c) { c.name }).join(", ")
                fail("missing subcommand for '" + name + "'. Available: " + subs)
              }
            }
          }
        None => fail("unknown command: " + name)
      }
    None => fail("no command specified. Use --help for usage.")
  }
}

///|
pub fn CliApp::run(
  self : CliApp,
  argv~ : Array[String]? = None
) -> Unit raise {
  let flags : Array[@argparse.FlagArg] = []
  let options : Array[@argparse.OptionArg] = []
  for opt in self.root_options {
    match opt.type_ {
      BoolOpt => flags.push(build_option_to_flag(opt))
      StringOpt | IntOpt => options.push(build_option_to_option_arg(opt))
    }
  }
  let subcommands = self.commands.map(fn(c) { build_command(c) })
  let argparse_cmd = @argparse.Command(
    self.name,
    about=self.description,
    version=self.version,
    flags=flags,
    options=options,
    subcommands=subcommands,
  )
  let matches = match argv {
    Some(args) => argparse_cmd.parse(argv=args)
    None => argparse_cmd.parse()
  }
  let ctx = matches_to_context(matches)
  execute_command(self.commands, ctx)
}
