///|
fn collect_option_words(options : Array[OptionDef]) -> String {
  let words : Array[String] = []
  for opt in options {
    words.push("--" + opt.name)
    if has_short(opt) {
      words.push("-" + opt.short.to_string())
    }
  }
  words.join(" ")
}

///|
fn collect_command_names(commands : Array[CommandDef]) -> String {
  commands.map(fn(c) { c.name }).join(" ")
}

///|
fn escape_single_quote(s : String) -> String {
  s.replace(old="'", new="'\\''")
}

///|
/// dollar sign as variable to avoid JS template literal collision
let dollar : String = "$"

// === Bash ===

///|
fn render_shell_scan(
  sb : StringBuilder,
  options : Array[OptionDef],
  commands : Array[CommandDef],
  fn_name : String,
  limit : String,
) -> Unit {
  sb.write_string("  while (( pos < " + limit + " )); do\n")
  sb.write_string("    case \"" + dollar + "{words[pos]}\" in\n")
  for opt in options {
    let long = "'--" + escape_single_quote(opt.name) + "'"
    let short = if has_short(opt) {
      "|'-" + escape_single_quote(opt.short.to_string()) + "'"
    } else {
      ""
    }
    let increment = if opt.type_ == BoolOpt { 1 } else { 2 }
    sb.write_string(
      "      " +
      long +
      short +
      ") ((pos += " +
      increment.to_string() +
      ")) ;;\n",
    )
    if opt.type_ != BoolOpt {
      sb.write_string("      " + long + "=*) ((pos += 1)) ;;\n")
    }
  }
  for i, cmd in commands {
    let sub_fn = fn_name + "_c" + i.to_string()
    sb.write_string(
      "      '" +
      escape_single_quote(cmd.name) +
      "') ((pos += 1)); " +
      sub_fn +
      "; return ;;\n",
    )
  }
  let has_short_options = options.any(fn(opt) { has_short(opt) })
  if has_short_options {
    sb.write_string("      -[!-]*)\n")
    sb.write_string(
      "        local rest=\"" + dollar + "{words[pos]#-}\" short\n",
    )
    sb.write_string("        ((pos += 1))\n")
    sb.write_string("        while [[ -n \"" + dollar + "rest\" ]]; do\n")
    sb.write_string(
      "          short=\"" +
      dollar +
      "{rest:0:1}\"; rest=\"" +
      dollar +
      "{rest:1}\"\n",
    )
    sb.write_string("          case \"" + dollar + "short\" in\n")
    for opt in options {
      if has_short(opt) {
        let action = if opt.type_ == BoolOpt {
          ":"
        } else {
          "[[ -z \"" + dollar + "rest\" ]] && ((pos += 1)); break"
        }
        sb.write_string(
          "            '" +
          escape_single_quote(opt.short.to_string()) +
          "') " +
          action +
          " ;;\n",
        )
      }
    }
    sb.write_string(
      "            *) break ;;\n          esac\n        done ;;\n",
    )
  }
  sb.write_string("      *) ((pos += 1)) ;;\n")
  sb.write_string("    esac\n  done\n")
}

///|
fn render_bash_node(
  sb : StringBuilder,
  fn_name : String,
  options : Array[OptionDef],
  commands : Array[CommandDef],
) -> Unit {
  sb.write_string(fn_name + "() {\n")
  render_shell_scan(sb, options, commands, fn_name, "cword")
  sb.write_string("  (( pos > cword )) && return\n")
  let candidates = collect_command_names(commands) +
    " " +
    collect_option_words(options)
  sb.write_string(
    "  COMPREPLY=($(compgen -W \"" +
    candidates +
    "\" -- \"" +
    dollar +
    "cur\"))\n",
  )
  sb.write_string("}\n\n")
  for i, cmd in commands {
    render_bash_node(
      sb,
      fn_name + "_c" + i.to_string(),
      cmd.options,
      cmd.subcommands,
    )
  }
}

///|
/// Generates a Bash completion script for this application.
///
/// ```mbt check
/// test {
///   assert_true(
///     @cmder.cli(name="demo").render_bash_completion().contains("complete -F"),
///   )
/// }
/// ```
pub fn CliApp::render_bash_completion(self : CliApp) -> String {
  let sb = StringBuilder()
  let fn_name = "_" + self.name.replace(old="-", new="_")
  sb.write_string(fn_name + "() {\n")
  sb.write_string("  local cur prev words cword\n")
  sb.write_string("  _init_completion || return\n")
  sb.write_string("  local pos=1\n")
  sb.write_string("  " + fn_name + "_root\n")
  sb.write_string("}\n\n")
  render_bash_node(sb, fn_name + "_root", self.root_options, self.commands)
  sb.write_string("complete -F " + fn_name + " " + self.name + "\n")
  sb.to_string()
}

// === Zsh ===

///|
fn render_zsh_options(sb : StringBuilder, options : Array[OptionDef]) -> Unit {
  if options.length() == 0 {
    return
  }
  sb.write_string("  _arguments \\\n")
  for i, opt in options {
    let desc = escape_single_quote(opt.description)
    let value_spec = if opt.type_ == BoolOpt { "" } else { ":value:" }
    let flag = if has_short(opt) {
      "'-" +
      opt.short.to_string() +
      "[" +
      desc +
      "]" +
      value_spec +
      "' '--" +
      opt.name +
      "[" +
      desc +
      "]" +
      value_spec +
      "'"
    } else {
      "'--" + opt.name + "[" + desc + "]" + value_spec + "'"
    }
    let end = if i < options.length() - 1 { " \\" } else { "" }
    sb.write_string("    " + flag + end + "\n")
  }
}

///|
fn render_zsh_command(
  sb : StringBuilder,
  cmd : CommandDef,
  fn_name : String,
) -> Unit {
  sb.write_string(fn_name + "() {\n")
  sb.write_string("  local start=" + dollar + "((pos - 1))\n")
  render_shell_scan(sb, cmd.options, cmd.subcommands, fn_name, "CURRENT")
  sb.write_string("  (( pos > CURRENT )) && return\n")
  if cmd.subcommands.length() > 0 {
    sb.write_string("  local -a commands\n")
    sb.write_string("  commands=(\n")
    for sub in cmd.subcommands {
      let desc = escape_single_quote(sub.description)
      sb.write_string("    '" + sub.name + ":" + desc + "'\n")
    }
    sb.write_string("  )\n")
    sb.write_string("  _describe 'command' commands\n")
  }
  if cmd.options.length() > 0 {
    sb.write_string(
      "  local -a words=(\"" +
      dollar +
      "{words[@]:" +
      dollar +
      "((start - 1))}\")\n",
    )
    sb.write_string("  local CURRENT=" + dollar + "((CURRENT - start + 1))\n")
    render_zsh_options(sb, cmd.options)
  }
  sb.write_string("}\n\n")
  for i, sub in cmd.subcommands {
    render_zsh_command(sb, sub, fn_name + "_c" + i.to_string())
  }
}

///|
/// Generates a Zsh completion script for this application.
///
/// ```mbt check
/// test {
///   assert_true(
///     @cmder.cli(name="demo").render_zsh_completion().contains("#compdef demo"),
///   )
/// }
/// ```
pub fn CliApp::render_zsh_completion(self : CliApp) -> String {
  let sb = StringBuilder()
  sb.write_string("#compdef " + self.name + "\n\n")
  let fn_name = "_" + self.name.replace(old="-", new="_")
  sb.write_string(fn_name + "() {\n")
  sb.write_string("  local pos=2\n")
  render_shell_scan(sb, self.root_options, self.commands, fn_name, "CURRENT")
  sb.write_string("  (( pos > CURRENT )) && return\n")
  sb.write_string("  local -a commands\n")
  sb.write_string("  commands=(\n")
  for cmd in self.commands {
    let desc = escape_single_quote(cmd.description)
    sb.write_string("    '" + cmd.name + ":" + desc + "'\n")
  }
  sb.write_string("  )\n")
  sb.write_string("  _describe 'command' commands\n")
  render_zsh_options(sb, self.root_options)
  sb.write_string("}\n\n")
  for i, cmd in self.commands {
    render_zsh_command(sb, cmd, fn_name + "_c" + i.to_string())
  }
  sb.write_string("compdef " + fn_name + " " + self.name + "\n")
  sb.to_string()
}

// === Fish ===

///|
fn render_fish_options(
  sb : StringBuilder,
  app_name : String,
  condition : String,
  options : Array[OptionDef],
) -> Unit {
  for opt in options {
    let mut line = "complete -c " +
      app_name +
      " " +
      condition +
      " -l " +
      opt.name
    if has_short(opt) {
      line = line + " -s " + opt.short.to_string()
    }
    if opt.description.length() > 0 {
      line = line + " -d '" + escape_single_quote(opt.description) + "'"
    }
    if opt.type_ != BoolOpt {
      line = line + " -r"
    }
    sb.write_string(line + "\n")
  }
}

///|
fn render_fish_subcommands(
  sb : StringBuilder,
  app_name : String,
  condition : String,
  commands : Array[CommandDef],
) -> Unit {
  for cmd in commands {
    let desc = escape_single_quote(cmd.description)
    let line = "complete -c " +
      app_name +
      " " +
      condition +
      " -a " +
      cmd.name +
      " -d '" +
      desc +
      "'"
    sb.write_string(line + "\n")
    let sub_cond = "-n '__fish_seen_subcommand_from " + cmd.name + "'"
    render_fish_options(sb, app_name, sub_cond, cmd.options)
    render_fish_subcommands(sb, app_name, sub_cond, cmd.subcommands)
  }
}

///|
/// Generates a Fish completion script for this application.
///
/// ```mbt check
/// test {
///   assert_true(
///     @cmder.cli(name="demo")
///     .render_fish_completion()
///     .contains("Fish completions"),
///   )
/// }
/// ```
pub fn CliApp::render_fish_completion(self : CliApp) -> String {
  let sb = StringBuilder()
  sb.write_string("# Fish completions for " + self.name + "\n")
  let root_cond = "-n '__fish_use_subcommand'"
  for cmd in self.commands {
    let desc = escape_single_quote(cmd.description)
    let line = "complete -c " +
      self.name +
      " " +
      root_cond +
      " -a " +
      cmd.name +
      " -d '" +
      desc +
      "'"
    sb.write_string(line + "\n")
  }
  for cmd in self.commands {
    let cond = "-n '__fish_seen_subcommand_from " + cmd.name + "'"
    render_fish_options(sb, self.name, cond, cmd.options)
    render_fish_subcommands(sb, self.name, cond, cmd.subcommands)
  }
  sb.to_string()
}
