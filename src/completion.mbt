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

///| dollar sign as variable to avoid JS template literal collision
let dollar : String = "$"

// === Bash ===

///|
fn render_bash_case(sb : StringBuilder, cmd : CommandDef, depth : Int) -> Unit {
  let indent = "  ".repeat(depth + 1)
  if cmd.subcommands.length() > 0 {
    let word_index = (depth + 2).to_string()
    sb.write_string(indent + "case \"" + dollar + "{words[" + word_index + "]}\" in\n")
    for sub in cmd.subcommands {
      sb.write_string(indent + "  " + sub.name + ")\n")
      if sub.subcommands.length() > 0 {
        render_bash_case(sb, sub, depth + 1)
      } else {
        let w = collect_option_words(sub.options)
        let line = indent + "    COMPREPLY=($(compgen -W \"" + w + "\" -- \"" + dollar + "cur\"))\n"
        sb.write_string(line)
      }
      sb.write_string(indent + "    ;;\n")
    }
    let sub_names = collect_command_names(cmd.subcommands)
    let own_opts = collect_option_words(cmd.options)
    let all = if own_opts.length() > 0 { sub_names + " " + own_opts } else { sub_names }
    sb.write_string(indent + "  *)\n")
    let fallback = indent + "    COMPREPLY=($(compgen -W \"" + all + "\" -- \"" + dollar + "cur\"))\n"
    sb.write_string(fallback)
    sb.write_string(indent + "    ;;\n")
    sb.write_string(indent + "esac\n")
  } else {
    let w = collect_option_words(cmd.options)
    let line = indent + "COMPREPLY=($(compgen -W \"" + w + "\" -- \"" + dollar + "cur\"))\n"
    sb.write_string(line)
  }
}

///|
pub fn CliApp::render_bash_completion(self : CliApp) -> String {
  let sb = StringBuilder::new()
  let fn_name = "_" + self.name.replace(old="-", new="_")
  sb.write_string(fn_name + "() {\n")
  sb.write_string("  local cur prev words cword\n")
  sb.write_string("  _init_completion || return\n\n")
  sb.write_string("  case \"" + dollar + "{words[1]}\" in\n")
  for cmd in self.commands {
    sb.write_string("    " + cmd.name + ")\n")
    if cmd.subcommands.length() > 0 {
      render_bash_case(sb, cmd, 1)
    } else {
      let w = collect_option_words(cmd.options)
      let line = "      COMPREPLY=($(compgen -W \"" + w + "\" -- \"" + dollar + "cur\"))\n"
      sb.write_string(line)
    }
    sb.write_string("      ;;\n")
  }
  let names = collect_command_names(self.commands)
  sb.write_string("    *)\n")
  let fallback = "      COMPREPLY=($(compgen -W \"" + names + "\" -- \"" + dollar + "cur\"))\n"
  sb.write_string(fallback)
  sb.write_string("      ;;\n")
  sb.write_string("  esac\n")
  sb.write_string("}\n")
  sb.write_string("complete -F " + fn_name + " " + self.name + "\n")
  sb.to_string()
}

// === Zsh ===

///|
fn render_zsh_command(sb : StringBuilder, cmd : CommandDef, app_name : String, full : String) -> Unit {
  let safe = full.replace(old="-", new="_")
  let fn_name = "_" + app_name.replace(old="-", new="_") + "_" + safe
  sb.write_string(fn_name + "() {\n")
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
    sb.write_string("  _arguments \\\n")
    for i, opt in cmd.options {
      let desc = escape_single_quote(opt.description)
      let flag = if has_short(opt) {
        "'-" + opt.short.to_string() + "[" + desc + "]' '--" + opt.name + "[" + desc + "]'"
      } else {
        "'--" + opt.name + "[" + desc + "]'"
      }
      let end = if i < cmd.options.length() - 1 { " \\" } else { "" }
      sb.write_string("    " + flag + end + "\n")
    }
  }
  sb.write_string("}\n\n")
  for sub in cmd.subcommands {
    let sub_full = full + "_" + sub.name
    render_zsh_command(sb, sub, app_name, sub_full)
  }
}

///|
pub fn CliApp::render_zsh_completion(self : CliApp) -> String {
  let sb = StringBuilder::new()
  sb.write_string("#compdef " + self.name + "\n\n")
  let fn_name = "_" + self.name.replace(old="-", new="_")
  sb.write_string(fn_name + "() {\n")
  sb.write_string("  local -a commands\n")
  sb.write_string("  commands=(\n")
  for cmd in self.commands {
    let desc = escape_single_quote(cmd.description)
    sb.write_string("    '" + cmd.name + ":" + desc + "'\n")
  }
  sb.write_string("  )\n")
  sb.write_string("  _describe 'command' commands\n")
  sb.write_string("}\n\n")
  for cmd in self.commands {
    render_zsh_command(sb, cmd, self.name, cmd.name)
  }
  sb.write_string("compdef " + fn_name + " " + self.name + "\n")
  sb.to_string()
}

// === Fish ===

///|
fn render_fish_options(sb : StringBuilder, app_name : String, condition : String, options : Array[OptionDef]) -> Unit {
  for opt in options {
    let mut line = "complete -c " + app_name + " " + condition + " -l " + opt.name
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
fn render_fish_subcommands(sb : StringBuilder, app_name : String, condition : String, commands : Array[CommandDef]) -> Unit {
  for cmd in commands {
    let desc = escape_single_quote(cmd.description)
    let line = "complete -c " + app_name + " " + condition + " -a " + cmd.name + " -d '" + desc + "'"
    sb.write_string(line + "\n")
    let sub_cond = "-n '__fish_seen_subcommand_from " + cmd.name + "'"
    render_fish_options(sb, app_name, sub_cond, cmd.options)
    render_fish_subcommands(sb, app_name, sub_cond, cmd.subcommands)
  }
}

///|
pub fn CliApp::render_fish_completion(self : CliApp) -> String {
  let sb = StringBuilder::new()
  sb.write_string("# Fish completions for " + self.name + "\n")
  let root_cond = "-n '__fish_use_subcommand'"
  for cmd in self.commands {
    let desc = escape_single_quote(cmd.description)
    let line = "complete -c " + self.name + " " + root_cond + " -a " + cmd.name + " -d '" + desc + "'"
    sb.write_string(line + "\n")
  }
  for cmd in self.commands {
    let cond = "-n '__fish_seen_subcommand_from " + cmd.name + "'"
    render_fish_options(sb, self.name, cond, cmd.options)
    render_fish_subcommands(sb, self.name, cond, cmd.subcommands)
  }
  sb.to_string()
}
