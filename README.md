# LUPE - Lua Debugger

LUPEはピュアLuaで書かれたデバッガです。
Lua 5.1とLua 5.2で動くように実装されています。

# 機能

* ブレークポイント（追加，削除，一覧表示）
* ステップイン
* ステップアウト
* ステップオーバー
* コードの出力
* ローカル変数一覧の出力
* 式の評価
* ローカル変数とグローバル変数の宣言位置の取得
* ウォッチ式
* 簡易プロファイラ

# ビルド方法

`lupe.lua`を生成するには，`concat.sh`を実行する必要があります．

```
$ ./concat.sh
```

# 使い方
## デバッガの読み込み

LUPEをコマンドラインから使うには，`lupe.lua`を読み込んで`Lupe`オブジェクト使えるようにする必要があります．
`lupe.lua`はリポジトリ直下にあるため，それをデバッグしたいLuaコードのあるプロジェクトにコピーしておきます．

```
$ cp lupe.lua myproject/
```

次に`lupe.lua`読み込みを行います．ピュアLuaの場合は`require`を使います．読み込みはデバッガを使用したいLuaファイルの先頭で行うと良いでしょう．

そして，読み込んだ後はデバッガをスタートするために`Lupe:start()`を呼び出します．
なお，デバッガを停止させたい場合は`Lupe:stop()`を呼び出すとブレークポイントなどが無効になります．

```main.lua
-- ピュアLua
require('lupe')
Lupe:start()
...
```

## ブレークポイントの追加・削除・一覧の表示

### ブレークポイントの追加：`addBreakPoint`, `ab`
`addBreakPoint`または`ab`を使用するとブレークポイントを追加できます．

```
LUPE>ab [source] line
```

ソースファイル(source)を省略すると，現在のファイルの指定した行にブレークポイントを追加します．

### ブレークポイントの削除：`removeBreakPoint `, `rb`
`removeBreakPoint `または`rb`を使用するとブレークポイントを削除できます．

```
LUPE>rb [source] line
```

引数は`addBreakPoint`と同様です．

### ブレークポイントの一覧：`breakPointList`, `bl`
`breakPointList`または`bl`を使用するとブレークポイントの一覧を表示できます．

```
LUPE>bl
@start.lua:63
```

## ステップ実行と継続

### ステップオーバー：`step`, `s`
`step`または`s`を使用するとステップオーバーでステップ実行できます．

```
LUPE>s [num_step]
```

`num_step`で実行するステップ数を指定することができます．
省略した場合は，`1`ステップだけ実行する．

### ステップイン：`stepIn`, `si`
`stepIn`または`si`を使用するとステップインでステップ実行できます．

```
LUPE>si [num_step]
```
引数については`step`と同様です．

### ステップアウト：`stepOut`, `so`
`stepOut`または`so`を使用するとステップインでステップ実行できます．

```
LUPE>so [num_step]
```

引数については`step`と同様です．

### 継続：`run`
`run`を使用すると処理再開することができます．
次のブレークポイント等でとまるまで実行されます．

```
LUPE>run
```

## ソースコードの表示：`list`, `l`
`list`または`l`を使用すると現在の行の周辺のソースコードが表示されます．

```
LUPE>l [num_lines]
```

`num_lines`で現在の行の前後何行を表示するかを指定できます．
省略すると前後`3`行を出力します．

```
LUPE>l
  60:     local f = function()
  61:       print(b)
  62:     end
>*63:     f()
  64:     fuga()
  65:     fuga()
  66:     hoge()
```

現在の行には`>`がつきます．また，ブレークポイントがある行には`*`がつきます．
つまり，上記の例では，現在の行は63行目で，ブレークポイントで停止していることがわかります．

## チャンクの評価（式の評価）
ここで上げているデバッグ用のコマンドに当てはまらない場合はLuaのコード（チャンク）として評価を行います．
このとき，現在の行の環境（変数や関数）を参照することができ，式の評価による環境の変更（変数の変更）の反映も行います．

```
LUPE>l
  49:     Lupe()
  50:     -- comment
  51:     local b = 300
> 52:     local c = {
  53:       c1 = 100,
  54:       c2 = 200,
  55:       c3 = {
LUPE>b=200
LUPE>print(b)
200
```

## ローカル変数の表示：`vars`, `v`
`vars`または`v`を使用するとローカル変数（上位値も含む）を表示することができます．

```
$ v [level] [shwo_level]
```

`level`でどの階層のローカル変数を表示することができるか指定することができます．現在の関数が`1`で，その呼び出し元は`2`となります．`level`を省略すると`1`となります．

```
LUPE>l
  58:       }
  59:     }
  60:     local f = function()
>*61:       print(b)
  62:     end
  63:     f()
  64:     fuga()
LUPE>v
b: 300
LUPE>v 2
a: 200
b: 300
c: {
 c1: 100
 c3: {
  c32: {
   1: 2
   2: 4
   3: 6
   4: 8
   5: 10
  }
  c31: 100
 }
 c2: 200
}
f: function: 0x7fc270606ae0
```

`show_level`で変数がテーブルの場合にどの深さまで表示するか指定することができます．
省略すると，`5`となります．指定した深さより深いものは，`...`で省略されます．

```
LUPE>v 1 2
a: 200
b: 300
c: {
 c1: 100
 c3: {
  c32: ...
  c31: 100
 }
 c2: 200
}
```

## 変数の宣言位置の表示： `definedLine`, `d`
`definedLine`または`d`を使用するとローカル変数またはグローバル変数の宣言位置を表示することができます．

```
LUPE>d var_name
```

`var_name`にはその行までに宣言されているローカル変数およびグローバル変数の名前を指定できます．
なお，同じ変数名が複数存在する場合は現在の行の階層に最も近い階層の変数の宣言位置が表示されます．

```
LUPE>d a
@start.lua:47
LUPE>d HOGE
@start.lua:4
```

## ウォッチ式

### ウォッチ式の設定：`setWatch`, `sw`
`setWatch`または`sw`を使用するとウォッチ式を設定することができます．

```
LUPE>sw a+1
add watch a+1
```

設定できる式は代入の右辺に使用できるものに限ります．

### ウォッチ式の削除：`removeWatch`, `rw`
`removeWatch`または`rw`を使用するとウォッチ式を削除することができます．

```
LUPE>rw [index]
```

`index`はウォッチ式の番号です．`watch`で確認することができます．

```
LUPE>rw [index]
remove watch a+1
```

### ウォッチ式の表示：`watch`, `w`
`watch`または`w`を使用すると設定されているウォッチ式を表示することができます．

```
LUPE>w
1: a+1 = 201
```

ここで表示されている番号は，`removeWatch`の際に使用します．


## Lupeの関数

### `Lupe:start()`

`Lupe:start()`を呼び出すことでデバッガを開始します．
デバッガが開始されると，各行を実行時にさまざまなデバッグ情報が集められます．
また，デバッグの起動中にブレークポイントや`assert`によって処理が一時停止することができます．
処理が停止中に，上記のデバッグコマンドを駆使してデバッグを行うことができます．

### `Lupe:stop()`

`Lupe:stop()`を呼び出すことでデバッガを停止することができます．
一度停止するとデバッガはデバッグ情報を集めなく成るため，再度`Lupe:start()`を呼び出しても整合性が取れなくなります．
しかし，デバッガを停止するとデバッグ情報を集めるための処理を行わなく成るため，デバッグ対象のプログラムに影響を与えなくなります．

### `Lupe:clear()`

コールスタックを消します．

### `Lupe:dump()`

`Lupe:dump()`は引数で渡した値を見やすい形で出力します．

```
LUPE>Lupe:dump({a = 100, b = 200})
{
 a: 100
 b: 200
}
```

#### `Lupe:traceback()`

コールスタックを表示させます．

```
LUPE>Lupe:traceback()
 @start.lua:39 hoge
  @start.lua:66 setup
```

### `Lupe:startProfile()`, `Lupe:endProfile()`

`Lupe:startProfile()`呼び出すと，簡易プロファイラが起動します．
プロファイリングの結果はテーブルとして`Lupe.profiler:summary()`から取得することができます．
また，`Lupe:endProfile()`を呼び出すとプロファイリングの結果を表示し，プロファイラを停止することができます．
プロファイラが取得するのは各関数の実行時間と使用メモリサイズです．

```
LUPE>Lupe:startProfile()
...
LUPE>Lupe:endProfile()
{
 (=[C]:-1)<function: 0x7fd4e8c05250>: {
  count: 1
  sum: {
   duration_ms: 0.024
   use_memory_kB: 2.66796875
  }
  average: {
   duration_ms: 0.024
   use_memory_kB: 2.66796875
  }
 }
 print(=[C]:-1)<function: 0x7fd4e8c05390>: {
  count: 1
  sum: {
   duration_ms: 0.090999999999999
   use_memory_kB: 8.0654296875
  }
  average: {
   duration_ms: 0.090999999999999
   use_memory_kB: 8.0654296875
  }
 }
 f(@start.lua:60)<function: 0x7fd4e8c28820>: {
  count: 1
  sum: {
   duration_ms: 0.244
   use_memory_kB: 21.884765625
  }
  average: {
   duration_ms: 0.244
   use_memory_kB: 21.884765625
  }
 }
}
```
