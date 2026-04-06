///|
pub fn Context::get_bool(self : Context, name : String) -> Bool {
  self.flags.get(name).unwrap_or(false)
}

///|
pub fn Context::get_string(self : Context, name : String) -> String? {
  match self.values.get(name) {
    Some(arr) => if arr.length() > 0 { Some(arr[0]) } else { None }
    None => None
  }
}

///|
pub fn Context::get_string_required(self : Context, name : String) -> String raise {
  match self.get_string(name) {
    Some(v) => v
    None => fail("missing required option: " + name)
  }
}

///|
pub fn Context::get_int(self : Context, name : String) -> Int? {
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
pub fn Context::get_int_required(self : Context, name : String) -> Int raise {
  match self.get_int(name) {
    Some(v) => v
    None => fail("missing or invalid required option: " + name)
  }
}

///|
pub fn Context::get_strings(self : Context, name : String) -> Array[String] {
  self.values.get(name).unwrap_or([])
}

///|
pub fn Context::get_subcommand(self : Context) -> (String, Context)? {
  self.subcommand
}
