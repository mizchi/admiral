test "cli creates CliApp and run executes command" {
  let called = Ref::new(false)
  let captured_name = Ref::new("")
  let app = cli(
    name="test-app",
    version="1.0.0",
    description="Test application",
    commands=[
      command(
        name="greet",
        description="Greet someone",
        options=[string("name", short=Some('n'), description="Name", required=true)],
        run=Some(fn(ctx) {
          called.val = true
          captured_name.val = try {
            ctx.get_string_required("name")
          } catch {
            _ => "error"
          }
        }),
      ),
    ],
  )
  app.run(["greet", "--name", "alice"])
  inspect(called.val, content="true")
  inspect(captured_name.val, content="alice")
}

test "cli run with bool flag" {
  let was_verbose = Ref::new(false)
  let app = cli(
    name="test-app",
    version="0.1.0",
    description="Test",
    commands=[
      command(
        name="build",
        description="Build project",
        options=[bool("verbose", short=Some('v'), description="Verbose")],
        run=Some(fn(ctx) { was_verbose.val = ctx.get_bool("verbose") }),
      ),
    ],
  )
  app.run(["build", "--verbose"])
  inspect(was_verbose.val, content="true")
}

test "cli run with int option" {
  let port_val = Ref::new(0)
  let app = cli(
    name="test-app",
    version="0.1.0",
    description="Test",
    commands=[
      command(
        name="serve",
        description="Start server",
        options=[int("port", short=Some('p'), description="Port", default=Some(3000))],
        run=Some(fn(ctx) {
          port_val.val = match ctx.get_int("port") {
            Some(p) => p
            None => 0
          }
        }),
      ),
    ],
  )
  app.run(["serve", "--port", "8080"])
  inspect(port_val.val, content="8080")
}

test "cli run with nested subcommand" {
  let result = Ref::new("")
  let app = cli(
    name="test-app",
    version="0.1.0",
    description="Test",
    commands=[
      command(
        name="db",
        description="Database commands",
        subcommands=[
          command(
            name="migrate",
            description="Run migrations",
            options=[bool("dry-run", description="Dry run")],
            run=Some(fn(ctx) {
              result.val = if ctx.get_bool("dry-run") { "dry" } else { "real" }
            }),
          ),
        ],
      ),
    ],
  )
  app.run(["db", "migrate", "--dry-run"])
  inspect(result.val, content="dry")
}
