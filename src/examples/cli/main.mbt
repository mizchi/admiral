fn main {
  let app = @admiral.cli(
    name="myapp",
    version="0.1.0",
    description="Example CLI with nested subcommands",
    commands=[
      @admiral.command(
        name="greet",
        description="Greet someone",
        options=[
          @admiral.string("name", short='n', description="Name to greet", required=true),
          @admiral.bool("loud", short='l', description="Shout the greeting"),
          @admiral.int("count", short='c', description="Repeat count", default=Some(1)),
        ],
        examples=[
          "myapp greet --name Alice",
          "myapp greet --name Bob --loud --count 3",
        ],
        run=Some(fn(ctx) {
          let name = try { ctx.get_string_required("name") } catch { _ => return }
          let loud = ctx.get_bool("loud")
          let count = match ctx.get_int("count") { Some(n) => n; None => 1 }
          for i = 0; i < count; i = i + 1 {
            let msg = "Hello, " + name + "!"
            if loud {
              println(msg.to_upper())
            } else {
              println(msg)
            }
          }
        }),
      ),
      @admiral.command(
        name="db",
        description="Database commands",
        subcommands=[
          @admiral.command(
            name="migrate",
            description="Run database migrations",
            subcommands=[
              @admiral.command(
                name="up",
                description="Apply pending migrations",
                options=[
                  @admiral.bool("dry-run", description="Preview without applying"),
                  @admiral.int("steps", short='s', description="Number of migrations to apply"),
                ],
                examples=[
                  "myapp db migrate up",
                  "myapp db migrate up --dry-run",
                  "myapp db migrate up --steps 5",
                ],
                run=Some(fn(ctx) {
                  let dry = ctx.get_bool("dry-run")
                  let steps = ctx.get_int("steps")
                  if dry {
                    println("[DRY RUN] Would apply migrations")
                  } else {
                    match steps {
                      Some(n) => println("Applying " + n.to_string() + " migrations...")
                      None => println("Applying all pending migrations...")
                    }
                  }
                  println("Done.")
                }),
              ),
              @admiral.command(
                name="down",
                description="Rollback migrations",
                options=[
                  @admiral.int("steps", short='s', description="Number of migrations to rollback", default=Some(1)),
                ],
                run=Some(fn(ctx) {
                  let steps = match ctx.get_int("steps") { Some(n) => n; None => 1 }
                  println("Rolling back " + steps.to_string() + " migration(s)...")
                  println("Done.")
                }),
              ),
            ],
          ),
          @admiral.command(
            name="seed",
            description="Seed the database",
            options=[
              @admiral.string("file", short='f', description="Seed file path", default=Some("seeds/default.sql")),
            ],
            run=Some(fn(ctx) {
              let file = match ctx.get_string("file") { Some(f) => f; None => "seeds/default.sql" }
              println("Seeding from: " + file)
            }),
          ),
        ],
      ),
    ],
  )
  // --schema flag: output structured JSON and exit
  let args = @env.args()
  if args.length() > 0 && args[args.length() - 1] == "--schema" {
    println(app.render_schema())
    return
  }
  try {
    app.run()
  } catch {
    err => println(err)
  }
}
