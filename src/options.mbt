///|
pub fn string(
  name : String,
  short~ : Char? = None,
  description~ : String = "",
  required~ : Bool = false,
  default~ : String? = None
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
pub fn bool(
  name : String,
  short~ : Char? = None,
  description~ : String = ""
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
pub fn int(
  name : String,
  short~ : Char? = None,
  description~ : String = "",
  required~ : Bool = false,
  default~ : Int? = None
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
