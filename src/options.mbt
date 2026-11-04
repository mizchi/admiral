///|
/// sentinel value for "no short flag"
let no_short : Char = '\u0000'

///|
/// Defines a string-valued option.
///
/// ```mbt check
/// test {
///   let option = @cmder.string("name", short='n', required=true)
///   assert_true(option.required)
/// }
/// ```
pub fn string(
  name : String,
  short~ : Char = '\u0000',
  description~ : String = "",
  required~ : Bool = false,
  default~ : String? = None,
) -> OptionDef {
  {
    name,
    type_: StringOpt,
    short,
    description,
    required: match default {
      Some(_) => false
      None => required
    },
    default_value: default,
  }
}

///|
/// Defines a Boolean flag, which defaults to false.
///
/// ```mbt check
/// test {
///   let option = @cmder.bool("verbose", short='v')
///   inspect(option.name, content="verbose")
/// }
/// ```
pub fn bool(
  name : String,
  short~ : Char = '\u0000',
  description~ : String = "",
) -> OptionDef {
  {
    name,
    type_: BoolOpt,
    short,
    description,
    required: false,
    default_value: None,
  }
}

///|
/// Defines an integer-valued option.
///
/// ```mbt check
/// test {
///   let option = @cmder.int("count", default=Some(3))
///   inspect(option.required, content="false")
/// }
/// ```
pub fn int(
  name : String,
  short~ : Char = '\u0000',
  description~ : String = "",
  required~ : Bool = false,
  default~ : Int32? = None,
) -> OptionDef {
  {
    name,
    type_: IntOpt,
    short,
    description,
    required: match default {
      Some(_) => false
      None => required
    },
    default_value: match default {
      Some(v) => Some(v.to_string())
      None => None
    },
  }
}
