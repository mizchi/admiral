///|
pub(all) enum OptionType {
  StringOpt
  BoolOpt
  IntOpt
} derive(Show, Eq)

///|
pub(all) struct OptionDef {
  name : String
  type_ : OptionType
  short : Char?
  description : String
  required : Bool
  default_value : String?
} derive(Show)

///|
pub(all) struct PositionalDef {
  name : String
  description : String
  required : Bool
}

///|
pub(all) struct CommandDef {
  name : String
  description : String
  options : Array[OptionDef]
  positionals : Array[PositionalDef]
  examples : Array[String]
  subcommands : Array[CommandDef]
  run : ((Context) -> Unit)?
}

///|
pub(all) struct Context {
  flags : Map[String, Bool]
  values : Map[String, Array[String]]
  subcommand : (String, Context)?
}

///|
pub(all) struct CliApp {
  name : String
  version : String
  description : String
  root_options : Array[OptionDef]
  commands : Array[CommandDef]
}
