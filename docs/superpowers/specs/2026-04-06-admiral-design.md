# admiral: gunshi-like CLI builder for MoonBit

## Overview

admiral は MoonBit 用の宣言的 CLI ビルダーライブラリ。`moonbitlang/core/argparse` の薄いラッパーとして、型付きオプション定義・サブコマンド・`--help` 自動生成を提供する。

gunshi (TypeScript) の開発体験を MoonBit に持ち込むことが目的。argparse を内部で使っていることはユーザーに透明であり、argparse のエコシステムを活かせる。

## Target Users

- MoonBit で CLI ツールを作る開発者
- 具体例: [pkdx](https://github.com/ushironoko/pkdx)（ポケモン対戦構築支援 CLI）

## Targets

全ターゲット対応: native / js / wasm-gc

純粋な MoonBit コードのみで構成し、ターゲット固有のコードは持たない。

## Scope

### v0.1 (this spec)

- サブコマンド定義（ネスト対応）
- 型付きオプション解析 (String, Bool, Int)
- `--help` / `--version` 自動生成（argparse 委譲）
- ヘルパー関数による宣言的 API

### Roadmap (TODO)

- v0.2: 構造化ヘルプ出力（セクション別データ取得）、バリデーション強化
- v0.3: シェル補完生成（bash/zsh/fish）
- v0.4: プラグインシステム、i18n

## API Design

### User-facing API

```moonbit
// オプション定義ヘルパー
let greet = command(
  name="greet",
  description="Greet someone",
  options=[
    string("name", short='n', description="Name to greet", required=true),
    bool("verbose", short='v', description="Verbose output"),
    int("count", short='c', description="Repeat count", default=1),
  ],
  run=fn(ctx) {
    let name = ctx.get_string!("name") // String (required)
    let verbose = ctx.get_bool("verbose") // Bool (default: false)
    let count = ctx.get_int("count")      // Int (default: 1)
    // ...
  },
)

// サブコマンド付きアプリ
let app = cli(
  name="pkdx",
  version="0.1.0",
  description="Pokédex CLI",
  commands=[cmd_query, cmd_search, cmd_damage],
)

// 実行
app.run!(args)  // args: Array[String]
```

### API Style

ハイブリッド方式: ヘルパー関数 (`string()`, `bool()`, `int()`, `command()`, `cli()`) + 構造体。MoonBit のラベル付き引数と相性が良く、gunshi の `define()` に近い体験を提供する。

## Architecture

### Package Structure

```
admiral/
├── src/
│   ├── types/       # OptionType, OptionDef, CommandDef, Context, CliApp
│   ├── options/     # string(), bool(), int() ヘルパー
│   ├── context/     # Context: Matches ラッパー、型付きアクセス
│   ├── builder/     # CommandDef → argparse.Command 変換
│   ├── runner/      # cli() + run(): パース → コマンドマッチ → 実行
│   └── lib/         # 公開 API の re-export
└── moon.mod.json
```

### Type Definitions

```moonbit
// オプション種別
pub enum OptionType {
  StringOpt
  BoolOpt
  IntOpt
}

// オプション定義
pub struct OptionDef {
  name: String
  type_: OptionType
  short: Char?
  description: String
  required: Bool
  default_value: String?
}

// コマンド定義
pub struct CommandDef {
  name: String
  description: String
  options: Array[OptionDef]
  subcommands: Array[CommandDef]
  run: ((Context) -> Unit)?
}

// パース結果ラッパー
pub struct Context {
  matches: @argparse.Matches
}

// CLI アプリ
pub struct CliApp {
  name: String
  version: String
  description: String
  commands: Array[CommandDef]
}
```

### Context Methods

```moonbit
fn Context::get_string(self, name: String) -> String?
fn Context::get_string!(self, name: String) -> String    // required 用、なければ raise
fn Context::get_bool(self, name: String) -> Bool          // default: false
fn Context::get_int(self, name: String) -> Int?
fn Context::get_int!(self, name: String) -> Int           // required 用
fn Context::get_strings(self, name: String) -> Array[String]
fn Context::get_positionals(self, name: String) -> Array[String]
```

### argparse Mapping

| admiral | argparse |
|---------|----------|
| `OptionDef(type_=StringOpt)` | `argparse.OptionArg` |
| `OptionDef(type_=BoolOpt)` | `argparse.FlagArg` |
| `OptionDef(type_=IntOpt)` | `argparse.OptionArg` (Context で Int 変換) |
| `CommandDef.subcommands` | `argparse.Command.subcommands` |
| `CliApp` | ルート `argparse.Command` + サブコマンド |

### Help Generation

argparse の `Command::render_help() -> String` をそのまま委譲。将来（v0.2+）で構造化ヘルプに拡張可能な設計にしておく。

## Error Handling

- argparse が raise する display-ready エラー文字列をそのまま伝播
- admiral 固有のエラーは Context での型変換失敗のみ（例: `"abc"` を `get_int` で取得）
- `run!()` で呼び出し、エラーは呼び出し元に raise

## Testing Strategy

| Package | What to test |
|---------|-------------|
| options | `string()` / `bool()` / `int()` が正しい `OptionDef` を返すか |
| builder | `CommandDef` → `argparse.Command` 変換の正しさ |
| context | `Matches` からの型付き取得（正常系 + 型変換エラー） |
| runner | E2E: コマンド定義 → パース → run コールバック実行 |

## Dependencies

- `moonbitlang/core` (argparse を含む)

## Reference

- [gunshi](https://github.com/kazupon/gunshi) — TypeScript CLI builder (設計のインスピレーション元)
- [pkdx](https://github.com/ushironoko/pkdx) — 組み込み先の MoonBit CLI ツール
- [moonbitlang/core/argparse](https://github.com/moonbitlang/core) — 内部で使用するパーサー
