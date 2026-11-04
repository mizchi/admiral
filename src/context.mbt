///|
/// Returns a flag's value, or false when it was not provided.
///
/// ```mbt check
/// test {
///   let ctx : @cmder.Context = {
///     flags: { "verbose": true },
///     values: {},
///     subcommand: None,
///   }
///   assert_true(ctx.get_bool("verbose"))
/// }
/// ```
pub fn Context::get_bool(self : Context, name : String) -> Bool {
  self.flags.get(name).unwrap_or(false)
}

///|
/// Returns the first value, or `None` if the name is absent.
///
/// ```mbt check
/// test {
///   let ctx : @cmder.Context = {
///     flags: {},
///     values: { "name": ["Ada"] },
///     subcommand: None,
///   }
///   assert_true(ctx.get_string("name") == Some("Ada"))
/// }
/// ```
pub fn Context::get_string(self : Context, name : String) -> String? {
  match self.values.get(name) {
    Some(arr) => if arr.length() > 0 { Some(arr[0]) } else { None }
    None => None
  }
}

///|
/// Returns the first value, raising an error if it is absent.
///
/// ```mbt check
/// test {
///   let ctx : @cmder.Context = {
///     flags: {},
///     values: { "name": ["Ada"] },
///     subcommand: None,
///   }
///   inspect(ctx.get_string_required("name"), content="Ada")
/// }
/// ```
pub fn Context::get_string_required(
  self : Context,
  name : String,
) -> String raise {
  match self.get_string(name) {
    Some(v) => v
    None => fail("missing required option: " + name)
  }
}

///|
/// Parses the first value as an `Int32`, returning `None` if missing or invalid.
///
/// ```mbt check
/// test {
///   let ctx : @cmder.Context = {
///     flags: {},
///     values: { "count": ["3"] },
///     subcommand: None,
///   }
///   assert_true(ctx.get_int("count") == Some(3))
/// }
/// ```
pub fn Context::get_int(self : Context, name : String) -> Int32? {
  match self.get_string(name) {
    Some(s) => {
      let chars = s.to_array()
      if chars.length() == 0 {
        return None
      }
      let mut i = 0
      let negative = chars[0] == '-'
      if negative {
        i = 1
      }
      let digits = chars.length() - i
      if digits == 0 || digits > 18 {
        return None
      }
      let mut result : Int64 = 0L
      while i < chars.length() {
        let c = chars[i]
        if c >= '0' && c <= '9' {
          result = result * 10L + (c.to_int() - '0'.to_int()).to_int64()
        } else {
          return None
        }
        i = i + 1
      }
      if negative {
        result = -result
      }
      if result < (-2147483648).to_int64() || result > 2147483647L {
        return None
      }
      Some(result.to_int())
    }
    None => None
  }
}

///|
/// Parses a required integer, raising an error if missing or invalid.
///
/// ```mbt check
/// test {
///   let ctx : @cmder.Context = {
///     flags: {},
///     values: { "count": ["3"] },
///     subcommand: None,
///   }
///   inspect(ctx.get_int_required("count"), content="3")
/// }
/// ```
pub fn Context::get_int_required(self : Context, name : String) -> Int32 raise {
  match self.get_int(name) {
    Some(v) => v
    None => fail("missing or invalid required option: " + name)
  }
}

///|
/// Returns all values associated with a name, or an empty array.
///
/// ```mbt check
/// test {
///   let ctx : @cmder.Context = {
///     flags: {},
///     values: { "files": ["a", "b"] },
///     subcommand: None,
///   }
///   inspect(ctx.get_strings("files").length(), content="2")
/// }
/// ```
pub fn Context::get_strings(self : Context, name : String) -> Array[String] {
  self.values.get(name).unwrap_or([])
}

///|
/// Returns the selected nested command and its context, if present.
///
/// ```mbt check
/// test {
///   let ctx : @cmder.Context = { flags: {}, values: {}, subcommand: None, }
///   assert_true(ctx.get_subcommand() is None)
/// }
/// ```
pub fn Context::get_subcommand(self : Context) -> (String, Context)? {
  self.subcommand
}
