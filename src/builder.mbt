///|
fn build_option_to_flag(opt : OptionDef) -> @argparse.FlagArg {
  match opt.short {
    Some(c) => @argparse.FlagArg(opt.name, short=c, about=opt.description)
    None => @argparse.FlagArg(opt.name, about=opt.description)
  }
}

///|
fn build_option_to_option_arg(opt : OptionDef) -> @argparse.OptionArg {
  match (opt.short, opt.default_value, opt.required) {
    (Some(c), Some(dv), _) =>
      @argparse.OptionArg(
        opt.name, short=c, about=opt.description, default_values=[dv],
      )
    (Some(c), None, true) =>
      @argparse.OptionArg(
        opt.name, short=c, about=opt.description, required=true,
      )
    (Some(c), None, false) =>
      @argparse.OptionArg(opt.name, short=c, about=opt.description)
    (None, Some(dv), _) =>
      @argparse.OptionArg(
        opt.name, about=opt.description, default_values=[dv],
      )
    (None, None, true) =>
      @argparse.OptionArg(opt.name, about=opt.description, required=true)
    (None, None, false) =>
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
