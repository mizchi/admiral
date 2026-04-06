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
  let m : Map[String, Json] = {}
  m["type"] = option_type_to_string(opt.type_).to_json()
  m["description"] = opt.description.to_json()
  m["required"] = opt.required.to_json()
  match opt.short {
    Some(c) => m["short"] = c.to_string().to_json()
    None => ()
  }
  match opt.default_value {
    Some(v) => m["default"] = v.to_json()
    None => ()
  }
  Json::object(m)
}

///|
fn command_def_to_json(cmd : CommandDef) -> Json {
  let m : Map[String, Json] = {}
  m["description"] = cmd.description.to_json()
  if cmd.options.length() > 0 {
    let opts : Map[String, Json] = {}
    for opt in cmd.options {
      opts[opt.name] = option_def_to_json(opt)
    }
    m["options"] = Json::object(opts)
  }
  if cmd.subcommands.length() > 0 {
    let subs : Map[String, Json] = {}
    for sub in cmd.subcommands {
      subs[sub.name] = command_def_to_json(sub)
    }
    m["commands"] = Json::object(subs)
  }
  Json::object(m)
}

///|
pub fn CliApp::render_schema_json(self : CliApp) -> Json {
  let m : Map[String, Json] = {}
  m["name"] = self.name.to_json()
  m["version"] = self.version.to_json()
  m["description"] = self.description.to_json()
  if self.root_options.length() > 0 {
    let opts : Map[String, Json] = {}
    for opt in self.root_options {
      opts[opt.name] = option_def_to_json(opt)
    }
    m["options"] = Json::object(opts)
  }
  if self.commands.length() > 0 {
    let cmds : Map[String, Json] = {}
    for cmd in self.commands {
      cmds[cmd.name] = command_def_to_json(cmd)
    }
    m["commands"] = Json::object(cmds)
  }
  Json::object(m)
}

///|
pub fn CliApp::render_schema(self : CliApp) -> String {
  self.render_schema_json().stringify()
}
