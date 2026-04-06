test "bash completion contains commands and options" {
  let app = cli(
    name="myapp",
    version="0.1.0",
    description="Test",
    commands=[
      command(
        name="greet",
        description="Greet someone",
        options=[
          string("name", short='n', description="Name", required=true),
          bool("verbose", short='v', description="Verbose"),
        ],
      ),
      command(name="db", description="Database",
        subcommands=[
          command(name="migrate", description="Migrations"),
        ],
      ),
    ],
  )
  let bash = app.render_bash_completion()
  inspect(bash.contains("_myapp"), content="true")
  inspect(bash.contains("greet"), content="true")
  inspect(bash.contains("db"), content="true")
  inspect(bash.contains("--name"), content="true")
  inspect(bash.contains("--verbose"), content="true")
  inspect(bash.contains("migrate"), content="true")
  inspect(bash.contains("complete -F _myapp myapp"), content="true")
}

test "zsh completion contains commands and options" {
  let app = cli(
    name="myapp",
    version="0.1.0",
    description="Test",
    commands=[
      command(
        name="greet",
        description="Greet someone",
        options=[
          string("name", short='n', description="Name", required=true),
        ],
      ),
    ],
  )
  let zsh = app.render_zsh_completion()
  inspect(zsh.contains("#compdef myapp"), content="true")
  inspect(zsh.contains("greet"), content="true")
  inspect(zsh.contains("--name"), content="true")
}

test "fish completion contains commands and options" {
  let app = cli(
    name="myapp",
    version="0.1.0",
    description="Test",
    commands=[
      command(
        name="greet",
        description="Greet someone",
        options=[
          string("name", short='n', description="Name", required=true),
          bool("verbose", short='v', description="Verbose"),
        ],
      ),
      command(name="db", description="Database",
        subcommands=[
          command(name="migrate", description="Migrations",
            options=[bool("dry-run", description="Dry run")],
          ),
        ],
      ),
    ],
  )
  let fish = app.render_fish_completion()
  inspect(fish.contains("complete -c myapp"), content="true")
  inspect(fish.contains("greet"), content="true")
  inspect(fish.contains("-l name"), content="true")
  inspect(fish.contains("-s n"), content="true")
  inspect(fish.contains("-l verbose"), content="true")
  inspect(fish.contains("db"), content="true")
  inspect(fish.contains("migrate"), content="true")
  inspect(fish.contains("-l dry-run"), content="true")
}
