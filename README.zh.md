# cmder

[English](README.md) | [简体中文](README.zh.md)

`hustcer/cmder` 是 MoonBit 的声明式命令行构建库，基于 `moonbitlang/core/argparse`，使用命令定义、选项和回调组织 CLI。

**本项目 fork 自 [mizchi/admiral](https://github.com/mizchi/admiral)，并在其基础上进行修改和维护。** 感谢 mizchi 和上游贡献者提供的设计与实现；上游项目的设计灵感来自 [gunshi](https://github.com/kazupon/gunshi)。

- 字符串、布尔、整数选项，以及位置参数。
- 多层子命令与命令回调，支持读取祖先命令的选项值。
- 由 argparse 生成帮助信息与根命令版本信息。
- 导出 CLI 定义的 JSON，供工具和 AI agent 使用。
- 生成 Bash、Zsh、Fish 补全脚本。

## 安装

在已有 MoonBit 模块的根目录执行：

```sh
moon add hustcer/cmder
```

然后在使用它的包的 `moon.pkg` 中添加：

```text
import {
  "hustcer/cmder",
}
```

代码中使用默认别名 `@cmder`。如果该包是可执行程序，还需在 `moon.pkg` 中声明：

```text
pkgtype(kind: "executable")
```

## 快速开始

将下面的代码放入可执行包的 `main.mbt`：

```moonbit
///|
fn main {
  let app = @cmder.cli(
    name="hello",
    version="1.0.0",
    description="A small greeting CLI",
    commands=[
      @cmder.command(
        name="greet",
        description="Greet someone",
        options=[
          @cmder.string("name", short='n', required=true),
          @cmder.bool("loud", short='l'),
          @cmder.int("count", short='c', default=Some(1)),
        ],
        examples=["hello greet -n Alice", "hello greet -n Bob -l -c 2"],
        run=Some(fn(ctx) {
          let name = ctx.get_string_required("name") catch {
            err => { println(err); return }
          }
          let count = ctx.get_int_required("count") catch {
            err => { println(err); return }
          }
          for _ in 0..<count {
            let message = "Hello, \{name}!"
            println(if ctx.get_bool("loud") { message.to_upper() } else { message })
          }
        }),
      ),
    ],
  )
  app.run() catch { err => println(err) }
}
```

编译成 `hello` 后：

```text
$ hello greet -n Alice
Hello, Alice!

$ hello greet -n Bob -l -c 2
HELLO, BOB!
HELLO, BOB!
```

使用 `hello --help` 查看命令列表，`hello greet --help` 查看命令参数，`hello --version` 查看版本。

以上示例将错误打印到标准输出。应用可以自行决定错误输出方式和退出码；打印错误并返回并不等于以非零状态退出。

## 选项与位置参数

以下是可放入命令定义的选项：

```moonbit
let options = [
  @cmder.string("config", short='f', description="Config file", required=true),
  @cmder.string("host", default=Some("localhost")),
  @cmder.int("port", short='p', default=Some(3000)),
  @cmder.bool("verbose", short='v', description="Verbose output"),
]
```

| 定义         | 用法                         | 默认行为                           |
| ------------ | ---------------------------- | ---------------------------------- |
| `string`     | `--host localhost`           | 未提供时为 `None`，可配置默认值    |
| `int`        | `--port 3000`                | 读取时转换为 `Int32`，可配置默认值 |
| `bool`       | `--verbose` 或 `-v`          | 未提供时为 `false`                 |
| `positional` | `copy source.txt target.txt` | 按声明顺序读取                     |

`short` 可以省略。`string` 和 `int` 支持 `required=true`；配置默认值后，即使同时设置 `required=true`，调用者也可以省略该选项。

整数选项在解析阶段仍按字符串接收。`get_int` 在缺失、格式错误或超出 `Int32` 范围时返回 `None`；需要拒绝无效输入时使用 `get_int_required` 并处理错误。正数、范围等业务约束由应用自行校验。

位置参数放在 `positionals` 中，必填参数应排在可选参数之前。除最后一个外，每个位置参数最多接收一个值；最后一个接收剩余值：

```moonbit
let show = @cmder.command(
  name="show",
  positionals=[
    @cmder.positional("files", description="Input files", required=true),
  ],
  run=Some(fn(ctx) {
    for file in ctx.get_strings("files") {
      println(file)
    }
  }),
)
```

`show a.txt b.txt` 会将两个文件名都放入 `files`。

## 子命令与选项作用域

`cli(commands=...)` 声明顶层命令，`command(subcommands=...)` 声明下一层命令：

```moonbit
let app = @cmder.cli(
  name="myapp",
  options=[@cmder.bool("verbose", short='v')],
  commands=[
    @cmder.command(name="db", subcommands=[
      @cmder.command(
        name="migrate",
        options=[@cmder.bool("dry-run")],
        run=Some(fn(ctx) {
          if ctx.get_bool("verbose") {
            println("Starting migration")
          }
          println(if ctx.get_bool("dry-run") { "Preview" } else { "Apply" })
        }),
      ),
    ]),
  ],
)
```

调用方式为 `myapp -v db migrate --dry-run`：选项应放在声明它的命令层级。回调可以读取祖先层级的值，同名的子级值优先，包含子级默认值。

选中更深的子命令时，只执行对应的命令回调，不会依次执行祖先回调。如果未指定命令，或者选中的命令既没有回调也没有选中子命令，`run` 会报错。根 `cli` 本身不提供 `run` 回调参数。

## 读取参数与处理错误

回调签名为 `(Context) -> Unit`。在回调中调用可能抛错的方法时，需要就地处理错误。

| Context 方法                | 返回类型             | 行为                             |
| --------------------------- | -------------------- | -------------------------------- |
| `get_bool(name)`            | `Bool`               | 缺失时返回 `false`               |
| `get_string(name)`          | `String?`            | 返回第一个值，缺失时为 `None`    |
| `get_string_required(name)` | `String raise`       | 缺失时抛错                       |
| `get_int(name)`             | `Int32?`             | 缺失或整数无效时返回 `None`      |
| `get_int_required(name)`    | `Int32 raise`        | 缺失或整数无效时抛错             |
| `get_strings(name)`         | `Array[String]`      | 返回全部值，缺失时为空数组       |
| `get_subcommand()`          | `(String, Context)?` | 返回选中的下一层子命令及其上下文 |

## 显式传入参数与测试

`app.run()` 使用进程参数；传入 `argv=Some(...)` 可以直接测试命令行为，数组中不包含可执行程序名：

```moonbit
///|
test "dispatch greet" {
  let received = Ref("")
  let app = @cmder.cli(name="hello", commands=[
    @cmder.command(
      name="greet",
      options=[@cmder.string("name", required=true)],
      run=Some(fn(ctx) {
        received.val = ctx.get_string("name").unwrap_or("")
      }),
    ),
  ])
  app.run(argv=Some(["greet", "--name", "Alice"]))
  assert_eq(received.val, "Alice")
}
```

## 导出 CLI 定义

构造 `app` 后可调用：

```moonbit
let schema_text = app.render_schema()       // String
let schema_json = app.render_schema_json()  // Json
```

导出内容描述命令层级、选项类型、必填状态、默认值、位置参数和示例，适合生成文档或供工具读取。这里的 schema 是本库的 CLI 描述格式，不代表标准 JSON Schema；选项默认值以字符串表示，包括整数默认值。

库不会自动注册 `--schema`。仓库中的[示例程序](src/examples/cli/main.mbt) 在调用 `run` 前检查最后一个参数是否为 `--schema`，再输出定义。

## Shell 补全

构造 `app` 后，以下方法分别返回完整补全脚本：

```moonbit
let bash_script = app.render_bash_completion()
let zsh_script = app.render_zsh_completion()
let fish_script = app.render_fish_completion()
```

应用需要自行提供脚本导出入口，或在构建流程中将这些字符串写入文件。库不会自动添加 `completion` 子命令。建议先构造完整的 `app`，再处理导出请求，避免在初始化 `app` 的回调中引用尚未定义的 `app`。

对于名为 `myapp` 的程序，将生成的脚本分别保存后，可在对应 shell 中加载：

```bash
# Bash
source ./myapp.bash
```

```zsh
# Zsh：先初始化补全系统
autoload -Uz compinit
compinit
source ./_myapp
```

```fish
# Fish
source ./myapp.fish
```

## API 与源码

| 入口                                                                                                       | 用途                                                              |
| ---------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| `cli(name=..., version=..., description=..., options=..., commands=...)`                                   | 构建应用                                                          |
| `command(name=..., description=..., options=..., positionals=..., examples=..., subcommands=..., run=...)` | 定义命令                                                          |
| `string`、`int`、`bool`、`positional`                                                                      | 定义参数                                                          |
| `CliApp::run(argv=...)`                                                                                    | 解析参数并执行回调                                                |
| `CliApp::render_schema` / `render_schema_json`                                                             | 导出 CLI 定义                                                     |
| `CliApp::render_bash_completion` / `render_zsh_completion` / `render_fish_completion`                      | 生成补全脚本                                                      |
| `build_command(command)`                                                                                   | 转换为底层 `argparse.Command`，供需要直接使用 argparse 的场景调用 |

完整签名见 [公开 API](src/pkg.generated.mbti)，可运行示例见 [src/examples/cli](src/examples/cli/main.mbt)。

## 本地开发

在仓库根目录运行：

```sh
moon check
moon test
moon run src/examples/cli --target native -- greet -n Alice
moon run src/examples/cli --target native -- db migrate up --dry-run
moon run src/examples/cli --target native -- --schema
```

按目标验证时可使用 `moon test --target native`、`moon test --target js` 和 `moon test --target wasm-gc`。运行 JS 目标需要对应的 JavaScript 运行时。

## 致谢与许可证

感谢 [mizchi/admiral](https://github.com/mizchi/admiral) 的作者和贡献者。本包是该仓库的 fork，基于其实现继续修改；也感谢 [gunshi](https://github.com/kazupon/gunshi) 提供的设计灵感，以及 MoonBit 的 `core/argparse` 提供的解析能力。

许可证：MIT（见 [moon.mod](moon.mod) 中的声明）。
