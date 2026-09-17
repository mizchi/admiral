///|
test "render_schema outputs JSON for simple command" {
  let app = @admiral.cli(
    name="myapp",
    version="1.0.0",
    description="Test app",
    commands=[
      @admiral.command(name="greet", description="Greet someone", options=[
        @admiral.string(
          "name",
          short='n',
          description="Name to greet",
          required=true,
        ),
        @admiral.bool("verbose", short='v', description="Verbose output"),
        @admiral.int("count", description="Repeat count", default=Some(3)),
      ]),
    ],
  )
  let schema = app.render_schema()
  // Verify key parts exist in JSON output
  inspect(schema.contains("\"name\":\"myapp\""), content="true")
  inspect(schema.contains("\"version\":\"1.0.0\""), content="true")
  inspect(schema.contains("\"description\":\"Test app\""), content="true")
  inspect(schema.contains("\"greet\""), content="true")
  inspect(schema.contains("\"type\":\"string\""), content="true")
  inspect(schema.contains("\"required\":true"), content="true")
  inspect(schema.contains("\"type\":\"bool\""), content="true")
  inspect(schema.contains("\"style\":\"flag\""), content="true")
  inspect(schema.contains("\"type\":\"int\""), content="true")
  inspect(schema.contains("\"default\":\"3\""), content="true")
  inspect(schema.contains("\"short\":\"n\""), content="true")
}

///|
test "render_schema outputs nested subcommands" {
  let app = @admiral.cli(
    name="db-tool",
    version="0.1.0",
    description="DB tool",
    commands=[
      @admiral.command(name="db", description="Database commands", subcommands=[
        @admiral.command(name="migrate", description="Migrations", subcommands=[
          @admiral.command(name="up", description="Apply migrations", options=[
            @admiral.bool("dry-run", description="Dry run"),
          ]),
        ]),
      ]),
    ],
  )
  let schema = app.render_schema()
  inspect(schema.contains("\"db\""), content="true")
  inspect(schema.contains("\"migrate\""), content="true")
  inspect(schema.contains("\"up\""), content="true")
  inspect(schema.contains("\"dry-run\""), content="true")
  inspect(schema.contains("\"Dry run\""), content="true")
}

///|
test "render_schema auto-generates examples when not provided" {
  let app = @admiral.cli(name="myapp", version="0.1.0", description="Test", commands=[
    @admiral.command(
      name="greet",
      description="Greet someone",
      options=[
        @admiral.string("name", short='n', description="Name", required=true),
        @admiral.bool("loud", short='l', description="Loud"),
        @admiral.int("count", short='c', description="Count", default=Some(1)),
      ],
      // no examples provided
    ),
  ])
  let schema = app.render_schema()
  // Should auto-generate an example
  inspect(schema.contains("\"examples\""), content="true")
  inspect(schema.contains("myapp greet --name"), content="true")
}

///|
test "render_schema does not override provided examples" {
  let app = @admiral.cli(name="myapp", version="0.1.0", description="Test", commands=[
    @admiral.command(
      name="greet",
      description="Greet someone",
      options=[@admiral.string("name", description="Name", required=true)],
      examples=["myapp greet --name Alice"],
    ),
  ])
  let schema = app.render_schema()
  inspect(schema.contains("myapp greet --name Alice"), content="true")
}

///|
test "render_schema auto-generates examples for nested commands" {
  let app = @admiral.cli(name="myapp", version="0.1.0", description="Test", commands=[
    @admiral.command(name="db", description="DB", subcommands=[
      @admiral.command(
        name="migrate",
        description="Migrate",
        options=[@admiral.bool("dry-run", description="Dry")],
        // no examples
      ),
    ]),
  ])
  let schema = app.render_schema()
  inspect(schema.contains("myapp db migrate"), content="true")
}

///|
test "render_schema_json returns Json value" {
  let app = @admiral.cli(name="test", version="0.1.0", description="Test", commands=[
    @admiral.command(name="hello", description="Say hello", options=[
      @admiral.string("name", description="Name", required=true),
    ]),
  ])
  let json = app.render_schema_json()
  // Json can be converted back to string
  let s = json.stringify()
  inspect(s.contains("\"hello\""), content="true")
  inspect(s.contains("\"name\""), content="true")
}
