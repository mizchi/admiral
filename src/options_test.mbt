test "string() creates StringOpt OptionDef" {
  let opt = string("name", short='n', description="User name", required=true)
  inspect(opt.name, content="name")
  inspect(opt.type_, content="StringOpt")
  inspect(opt.short, content=(
    #|n
  ))
  inspect(opt.required, content="true")
  inspect(opt.default_value, content="None")
}

test "string() with default value" {
  let opt = string("output", description="Output path", default=Some("stdout"))
  inspect(opt.default_value, content="Some(\"stdout\")")
  inspect(opt.required, content="false")
}

test "bool() creates BoolOpt OptionDef" {
  let opt = bool("verbose", short='v', description="Verbose output")
  inspect(opt.type_, content="BoolOpt")
  inspect(opt.required, content="false")
}

test "int() creates IntOpt OptionDef" {
  let opt = int("count", short='c', description="Repeat count", default=Some(3))
  inspect(opt.type_, content="IntOpt")
  inspect(opt.default_value, content="Some(\"3\")")
}

test "int() required" {
  let opt = int("port", short='p', description="Port number", required=true)
  inspect(opt.required, content="true")
  inspect(opt.default_value, content="None")
}
