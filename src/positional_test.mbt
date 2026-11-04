///|
test "positional() creates PositionalDef" {
  let p = @cmder.positional("file", description="Input file", required=true)
  inspect(p.name, content="file")
  inspect(p.description, content="Input file")
  inspect(p.required, content="true")
}

///|
test "positional default not required" {
  let p = @cmder.positional("output", description="Output file")
  inspect(p.required, content="false")
}

///|
test "command with positionals builds correctly" {
  let cmd = @cmder.command(name="compile", description="Compile source", positionals=[
    @cmder.positional("input", description="Input file", required=true),
    @cmder.positional("output", description="Output file"),
  ])
  let argparse_cmd = @cmder.build_command(cmd)
  let help = argparse_cmd.render_help()
  inspect(help.contains("input"), content="true")
  inspect(help.contains("output"), content="true")
}

///|
test "positionals accessible via context get_strings" {
  let captured = Ref([])
  let app = @cmder.cli(name="test", version="0.1.0", description="Test", commands=[
    @cmder.command(
      name="cat",
      description="Cat files",
      positionals=[@cmder.positional("files", description="Files to cat")],
      run=Some(fn(ctx) { captured.val = ctx.get_strings("files") }),
    ),
  ])
  app.run(argv=Some(["cat", "a.txt", "b.txt"]))
  inspect(captured.val.length(), content="2")
  inspect(captured.val[0], content="a.txt")
  inspect(captured.val[1], content="b.txt")
}

///|
test "non-final positionals leave values for later arguments" {
  let source = Ref("")
  let destination = Ref([])
  let app = @cmder.cli(name="test", commands=[
    @cmder.command(
      name="copy",
      positionals=[
        @cmder.positional("source", required=true),
        @cmder.positional("destination"),
      ],
      run=Some(fn(ctx) {
        source.val = ctx.get_string("source").unwrap_or("")
        destination.val = ctx.get_strings("destination")
      }),
    ),
  ])
  app.run(argv=Some(["copy", "a", "b", "c"]))
  inspect(source.val, content="a")
  inspect(destination.val.length(), content="2")
  inspect(destination.val[0], content="b")
  inspect(destination.val[1], content="c")
  app.run(argv=Some(["copy", "a"]))
  inspect(destination.val.length(), content="0")
}

///|
test "render_schema includes positionals" {
  let app = @cmder.cli(name="test", version="0.1.0", description="Test", commands=[
    @cmder.command(name="compile", description="Compile source", positionals=[
      @cmder.positional("input", description="Input file", required=true),
      @cmder.positional("output", description="Output file"),
    ]),
  ])
  let schema = app.render_schema()
  inspect(schema.contains("\"positionals\""), content="true")
  inspect(schema.contains("\"input\""), content="true")
  inspect(schema.contains("\"required\":true"), content="true")
}

///|
test "render_schema includes examples" {
  let app = @cmder.cli(name="test", version="0.1.0", description="Test", commands=[
    @cmder.command(
      name="greet",
      description="Greet",
      options=[@cmder.string("name", description="Name", required=true)],
      examples=["test greet --name Alice", "test greet --name Bob"],
    ),
  ])
  let schema = app.render_schema()
  inspect(schema.contains("\"examples\""), content="true")
  inspect(schema.contains("test greet --name Alice"), content="true")
  inspect(schema.contains("test greet --name Bob"), content="true")
}
