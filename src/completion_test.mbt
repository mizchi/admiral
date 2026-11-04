///|
test "bash completion contains commands and options" {
  let app = @cmder.cli(name="myapp", version="0.1.0", description="Test", commands=[
    @cmder.command(name="greet", description="Greet someone", options=[
      @cmder.string("name", short='n', description="Name", required=true),
      @cmder.bool("verbose", short='v', description="Verbose"),
    ]),
    @cmder.command(name="db", description="Database", subcommands=[
      @cmder.command(name="migrate", description="Migrations"),
    ]),
  ])
  let bash = app.render_bash_completion()
  inspect(bash.contains("_myapp"), content="true")
  inspect(bash.contains("greet"), content="true")
  inspect(bash.contains("db"), content="true")
  inspect(bash.contains("--name"), content="true")
  inspect(bash.contains("--verbose"), content="true")
  inspect(bash.contains("migrate"), content="true")
  inspect(bash.contains("complete -F _myapp myapp"), content="true")
}

///|
test "zsh completion contains commands and options" {
  let app = @cmder.cli(name="myapp", version="0.1.0", description="Test", commands=[
    @cmder.command(name="greet", description="Greet someone", options=[
      @cmder.string("name", short='n', description="Name", required=true),
    ]),
  ])
  let zsh = app.render_zsh_completion()
  inspect(zsh.contains("#compdef myapp"), content="true")
  inspect(zsh.contains("greet"), content="true")
  inspect(zsh.contains("--name"), content="true")
}

///|
test "fish completion contains commands and options" {
  let app = @cmder.cli(name="myapp", version="0.1.0", description="Test", commands=[
    @cmder.command(name="greet", description="Greet someone", options=[
      @cmder.string("name", short='n', description="Name", required=true),
      @cmder.bool("verbose", short='v', description="Verbose"),
    ]),
    @cmder.command(name="db", description="Database", subcommands=[
      @cmder.command(name="migrate", description="Migrations", options=[
        @cmder.bool("dry-run", description="Dry run"),
      ]),
    ]),
  ])
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

///|
test "nested completion dispatches to the selected command" {
  let app = @cmder.cli(name="myapp", commands=[
    @cmder.command(name="db", subcommands=[
      @cmder.command(name="migrate", subcommands=[
        @cmder.command(name="up", options=[@cmder.string("target")]),
      ]),
    ]),
  ])
  let bash = app.render_bash_completion()
  inspect(bash.contains("while (( pos < cword )); do"), content="true")
  inspect(
    bash.contains("'db') ((pos += 1)); _myapp_root_c0; return ;;"),
    content="true",
  )
  let zsh = app.render_zsh_completion()
  inspect(zsh.contains("while (( pos < CURRENT )); do"), content="true")
  inspect(
    zsh.contains("'db') ((pos += 1)); _myapp_c0; return ;;"),
    content="true",
  )
  inspect(
    zsh.contains("'migrate') ((pos += 1)); _myapp_c0_c0; return ;;"),
    content="true",
  )
  inspect(
    zsh.contains("'up') ((pos += 1)); _myapp_c0_c0_c0; return ;;"),
    content="true",
  )
  inspect(zsh.contains("'--target[]:value:'"), content="true")
}

///|
test "completion keeps colliding command names distinct and scans short groups" {
  let app = @cmder.cli(
    name="app",
    options=[
      @cmder.bool("verbose", short='v'),
      @cmder.string("profile", short='p'),
    ],
    commands=[
      @cmder.command(name="foo-bar", options=[@cmder.bool("first")]),
      @cmder.command(name="foo_bar", options=[@cmder.bool("second")]),
    ],
  )
  for script in [app.render_bash_completion(), app.render_zsh_completion()] {
    inspect(script.contains("'foo-bar') ((pos += 1));"), content="true")
    inspect(script.contains("'foo_bar') ((pos += 1));"), content="true")
    inspect(script.contains("_c0() {"), content="true")
    inspect(script.contains("_c1() {"), content="true")
    inspect(script.contains("-[!-]*)"), content="true")
    inspect(
      script.contains("'p') [[ -z \"$rest\" ]] && ((pos += 1)); break ;;"),
      content="true",
    )
  }
}
