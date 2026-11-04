///|
test "descendant default takes precedence over ancestor value" {
  let captured = Ref("")
  let app = @cmder.cli(name="app", options=[@cmder.string("mode")], commands=[
    @cmder.command(
      name="go",
      options=[@cmder.string("mode", default=Some("child"))],
      run=Some(fn(ctx) { captured.val = ctx.get_string("mode").unwrap_or("") }),
    ),
  ])
  app.run(argv=Some(["--mode", "root", "go"]))
  inspect(captured.val, content="child")
}

///|
test "cli creates CliApp and run executes command" {
  let called = Ref(false)
  let captured_name = Ref("")
  let app = @cmder.cli(
    name="test-app",
    version="1.0.0",
    description="Test application",
    commands=[
      @cmder.command(
        name="greet",
        description="Greet someone",
        options=[
          @cmder.string("name", short='n', description="Name", required=true),
        ],
        run=Some(fn(ctx) {
          called.val = true
          captured_name.val = ctx.get_string_required("name") catch {
            _ => "error"
          }
        }),
      ),
    ],
  )
  app.run(argv=Some(["greet", "--name", "alice"]))
  inspect(called.val, content="true")
  inspect(captured_name.val, content="alice")
}

///|
test "cli run with bool flag" {
  let was_verbose = Ref(false)
  let app = @cmder.cli(name="test-app", version="0.1.0", description="Test", commands=[
    @cmder.command(
      name="build",
      description="Build project",
      options=[@cmder.bool("verbose", short='v', description="Verbose")],
      run=Some(fn(ctx) { was_verbose.val = ctx.get_bool("verbose") }),
    ),
  ])
  app.run(argv=Some(["build", "--verbose"]))
  inspect(was_verbose.val, content="true")
}

///|
test "cli run with int option" {
  let port_val = Ref(0)
  let app = @cmder.cli(name="test-app", version="0.1.0", description="Test", commands=[
    @cmder.command(
      name="serve",
      description="Start server",
      options=[
        @cmder.int("port", short='p', description="Port", default=Some(3000)),
      ],
      run=Some(fn(ctx) {
        port_val.val = match ctx.get_int("port") {
          Some(p) => p
          None => 0
        }
      }),
    ),
  ])
  app.run(argv=Some(["serve", "--port", "8080"]))
  inspect(port_val.val, content="8080")
}

///|
test "cli run with nested subcommand" {
  let result = Ref("")
  let app = @cmder.cli(name="test-app", version="0.1.0", description="Test", commands=[
    @cmder.command(name="db", description="Database commands", subcommands=[
      @cmder.command(
        name="migrate",
        description="Run migrations",
        options=[@cmder.bool("dry-run", description="Dry run")],
        run=Some(fn(ctx) {
          result.val = if ctx.get_bool("dry-run") { "dry" } else { "real" }
        }),
      ),
    ]),
  ])
  app.run(argv=Some(["db", "migrate", "--dry-run"]))
  inspect(result.val, content="dry")
}

///|
test "callbacks receive ancestor options and closest values win" {
  let verbose = Ref(false)
  let region = Ref("")
  let mode = Ref("")
  let app = @cmder.cli(
    name="app",
    options=[@cmder.bool("verbose"), @cmder.string("mode")],
    commands=[
      @cmder.command(name="db", options=[@cmder.string("region")], subcommands=[
        @cmder.command(
          name="up",
          options=[@cmder.string("mode")],
          run=Some(fn(ctx) {
            verbose.val = ctx.get_bool("verbose")
            region.val = ctx.get_string("region").unwrap_or("")
            mode.val = ctx.get_string("mode").unwrap_or("")
          }),
        ),
      ]),
    ],
  )
  app.run(
    argv=Some([
      "--verbose", "--mode", "root", "db", "--region", "west", "up", "--mode", "child",
    ]),
  )
  inspect(verbose.val, content="true")
  inspect(region.val, content="west")
  inspect(mode.val, content="child")
  app.run(argv=Some(["--mode", "root", "db", "up"]))
  inspect(verbose.val, content="false")
  inspect(mode.val, content="root")
}
