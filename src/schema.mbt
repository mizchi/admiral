///|
fn option_type_to_string(t : OptionType) -> String {
  match t {
    StringOpt => "string"
    BoolOpt => "bool"
    IntOpt => "int"
  }
}

///|
fn option_def_to_json(opt : OptionDef) -> Json {
  let m : Map[String, Json] = Map([])
  m["type"] = ToJson::to_json(option_type_to_string(opt.type_))
  m["description"] = ToJson::to_json(opt.description)
  m["required"] = ToJson::to_json(opt.required)
  if opt.type_ == BoolOpt {
    m["style"] = ToJson::to_json("flag")
  }
  if opt.short != no_short {
    m["short"] = ToJson::to_json(opt.short.to_string())
  }
  match opt.default_value {
    Some(v) => m["default"] = ToJson::to_json(v)
    None => ()
  }
  Json::object(m)
}

///|
fn positional_def_to_json(pos : PositionalDef) -> Json {
  let m : Map[String, Json] = Map([])
  m["description"] = ToJson::to_json(pos.description)
  m["required"] = ToJson::to_json(pos.required)
  Json::object(m)
}

///|
fn generate_example(cmd_path : String, options : Array[OptionDef]) -> String {
  let parts : Array[String] = [cmd_path]
  for opt in options {
    if opt.required {
      parts.push("--" + opt.name + " <" + opt.name + ">")
    }
  }
  parts.join(" ")
}

///|
fn command_def_to_json(cmd : CommandDef, cmd_path : String) -> Json {
  let m : Map[String, Json] = Map([])
  m["description"] = ToJson::to_json(cmd.description)
  if cmd.options.length() > 0 {
    let opts : Map[String, Json] = Map([])
    for opt in cmd.options {
      opts[opt.name] = option_def_to_json(opt)
    }
    m["options"] = Json::object(opts)
  }
  if cmd.positionals.length() > 0 {
    let poss : Map[String, Json] = Map([])
    for pos in cmd.positionals {
      poss[pos.name] = positional_def_to_json(pos)
    }
    m["positionals"] = Json::object(poss)
  }
  if cmd.examples.length() > 0 {
    m["examples"] = Json::array(cmd.examples.map(fn(e) { ToJson::to_json(e) }))
  } else if cmd.options.length() > 0 || cmd.positionals.length() > 0 {
    let ex = generate_example(cmd_path, cmd.options)
    m["examples"] = Json::array([ToJson::to_json(ex)])
  }
  if cmd.subcommands.length() > 0 {
    let subs : Map[String, Json] = Map([])
    for sub in cmd.subcommands {
      let sub_path = cmd_path + " " + sub.name
      subs[sub.name] = command_def_to_json(sub, sub_path)
    }
    m["commands"] = Json::object(subs)
  }
  Json::object(m)
}

///|
pub fn CliApp::render_schema_json(self : CliApp) -> Json {
  let m : Map[String, Json] = Map([])
  m["name"] = ToJson::to_json(self.name)
  m["version"] = ToJson::to_json(self.version)
  m["description"] = ToJson::to_json(self.description)
  if self.root_options.length() > 0 {
    let opts : Map[String, Json] = Map([])
    for opt in self.root_options {
      opts[opt.name] = option_def_to_json(opt)
    }
    m["options"] = Json::object(opts)
  }
  if self.commands.length() > 0 {
    let cmds : Map[String, Json] = Map([])
    for cmd in self.commands {
      let cmd_path = self.name + " " + cmd.name
      cmds[cmd.name] = command_def_to_json(cmd, cmd_path)
    }
    m["commands"] = Json::object(cmds)
  }
  Json::object(m)
}

///|
pub fn CliApp::render_schema(self : CliApp) -> String {
  self.render_schema_json().stringify()
}
