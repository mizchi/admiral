test "render_schema outputs JSON for simple command" {
  let app = cli(
    name="myapp",
    version="1.0.0",
    description="Test app",
    commands=[
      command(
        name="greet",
        description="Greet someone",
        options=[
          string("name", short=Some('n'), description="Name to greet", required=true),
          bool("verbose", short=Some('v'), description="Verbose output"),
          int("count", description="Repeat count", default=Some(3)),
        ],
      ),
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
  inspect(schema.contains("\"type\":\"int\""), content="true")
  inspect(schema.contains("\"default\":\"3\""), content="true")
  inspect(schema.contains("\"short\":\"n\""), content="true")
}

test "render_schema outputs nested subcommands" {
  let app = cli(
    name="db-tool",
    version="0.1.0",
    description="DB tool",
    commands=[
      command(
        name="db",
        description="Database commands",
        subcommands=[
          command(
            name="migrate",
            description="Migrations",
            subcommands=[
              command(
                name="up",
                description="Apply migrations",
                options=[bool("dry-run", description="Dry run")],
              ),
            ],
          ),
        ],
      ),
    ],
  )
  let schema = app.render_schema()
  inspect(schema.contains("\"db\""), content="true")
  inspect(schema.contains("\"migrate\""), content="true")
  inspect(schema.contains("\"up\""), content="true")
  inspect(schema.contains("\"dry-run\""), content="true")
  inspect(schema.contains("\"Dry run\""), content="true")
}

test "render_schema_json returns Json value" {
  let app = cli(
    name="test",
    version="0.1.0",
    description="Test",
    commands=[
      command(
        name="hello",
        description="Say hello",
        options=[string("name", description="Name", required=true)],
      ),
    ],
  )
  let json = app.render_schema_json()
  // Json can be converted back to string
  let s = json.stringify()
  inspect(s.contains("\"hello\""), content="true")
  inspect(s.contains("\"name\""), content="true")
}
