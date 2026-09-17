///|
test "positional() creates PositionalDef" {
  let p = @admiral.positional("file", description="Input file", required=true)
  inspect(p.name, content="file")
  inspect(p.description, content="Input file")
  inspect(p.required, content="true")
}

///|
test "positional default not required" {
  let p = @admiral.positional("output", description="Output file")
  inspect(p.required, content="false")
}

///|
test "command with positionals builds correctly" {
  let cmd = @admiral.command(name="compile", description="Compile source", positionals=[
    @admiral.positional("input", description="Input file", required=true),
    @admiral.positional("output", description="Output file"),
  ])
  let argparse_cmd = @admiral.build_command(cmd)
  let help = argparse_cmd.render_help()
  inspect(help.contains("input"), content="true")
  inspect(help.contains("output"), content="true")
}

///|
test "positionals accessible via context get_strings" {
  let captured = Ref([])
  let app = @admiral.cli(name="test", version="0.1.0", description="Test", commands=[
    @admiral.command(
      name="cat",
      description="Cat files",
      positionals=[@admiral.positional("files", description="Files to cat")],
      run=Some(fn(ctx) { captured.val = ctx.get_strings("files") }),
    ),
  ])
  app.run(argv=Some(["cat", "a.txt", "b.txt"]))
  inspect(captured.val.length(), content="2")
  inspect(captured.val[0], content="a.txt")
  inspect(captured.val[1], content="b.txt")
}

///|
test "render_schema includes positionals" {
  let app = @admiral.cli(name="test", version="0.1.0", description="Test", commands=[
    @admiral.command(name="compile", description="Compile source", positionals=[
      @admiral.positional("input", description="Input file", required=true),
      @admiral.positional("output", description="Output file"),
    ]),
  ])
  let schema = app.render_schema()
  inspect(schema.contains("\"positionals\""), content="true")
  inspect(schema.contains("\"input\""), content="true")
  inspect(schema.contains("\"required\":true"), content="true")
}

///|
test "render_schema includes examples" {
  let app = @admiral.cli(name="test", version="0.1.0", description="Test", commands=[
    @admiral.command(
      name="greet",
      description="Greet",
      options=[@admiral.string("name", description="Name", required=true)],
      examples=["test greet --name Alice", "test greet --name Bob"],
    ),
  ])
  let schema = app.render_schema()
  inspect(schema.contains("\"examples\""), content="true")
  inspect(schema.contains("test greet --name Alice"), content="true")
  inspect(schema.contains("test greet --name Bob"), content="true")
}
