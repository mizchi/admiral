///|
fn has_short(opt : OptionDef) -> Bool {
  opt.short != no_short
}

///|
fn build_option_to_flag(opt : OptionDef) -> @argparse.FlagArg {
  if has_short(opt) {
    @argparse.FlagArg(opt.name, short=opt.short, about=opt.description)
  } else {
    @argparse.FlagArg(opt.name, about=opt.description)
  }
}

///|
fn build_option_to_option_arg(opt : OptionDef) -> @argparse.OptionArg {
  match (has_short(opt), opt.default_value, opt.required) {
    (true, Some(dv), _) =>
      @argparse.OptionArg(
        opt.name, short=opt.short, about=opt.description, default_values=[dv],
      )
    (true, None, true) =>
      @argparse.OptionArg(
        opt.name, short=opt.short, about=opt.description, required=true,
      )
    (true, None, false) =>
      @argparse.OptionArg(opt.name, short=opt.short, about=opt.description)
    (false, Some(dv), _) =>
      @argparse.OptionArg(
        opt.name, about=opt.description, default_values=[dv],
      )
    (false, None, true) =>
      @argparse.OptionArg(opt.name, about=opt.description, required=true)
    (false, None, false) =>
      @argparse.OptionArg(opt.name, about=opt.description)
  }
}

///|
fn build_positional(pos : PositionalDef) -> @argparse.PositionArg {
  if pos.required {
    @argparse.PositionArg(
      pos.name,
      about=pos.description,
      num_args=@argparse.ValueRange(lower=1),
    )
  } else {
    @argparse.PositionArg(
      pos.name,
      about=pos.description,
      num_args=@argparse.ValueRange(lower=0),
    )
  }
}

///|
pub fn build_command(cmd : CommandDef) -> @argparse.Command {
  let flags : Array[@argparse.FlagArg] = []
  let options : Array[@argparse.OptionArg] = []
  for opt in cmd.options {
    match opt.type_ {
      BoolOpt => flags.push(build_option_to_flag(opt))
      StringOpt | IntOpt => options.push(build_option_to_option_arg(opt))
    }
  }
  let positionals = cmd.positionals.map(fn(p) { build_positional(p) })
  let subcommands = cmd.subcommands.map(fn(sub) { build_command(sub) })
  @argparse.Command(
    cmd.name,
    about=cmd.description,
    flags=flags,
    options=options,
    positionals=positionals,
    subcommands=subcommands,
  )
}
