--- prompt.lua

--- プロンプトを扱うクラス．
local Prompt = {}

--- Promptを作る．
function Prompt.create()

  local m = {
    command_factories = {
      StepCommandFactory.create(),        -- ステップ実行
      RunCommandFactory.create(),         -- Run
      BreakPointCommandFactory.create(),  -- ブレークポイント
      InfoCommandFactory.create(),        -- デバッグ情報の出力
      ListCommandFactory.create(),        -- ソースコードの出力
      VarsCommandFactory.create(),        -- 変数の出力
      DefinedLineCommandFactory.create(), -- 変数の宣言位置の出力
      WatchCommandFactory.create(),       -- ウォッチ式
      ProfileCommandFactory.create(),     -- プロファイラ
      EvalCommandFactory.create(),        -- 式の評価（最後にしないとダメ）
    },
  }

  --- 処理を再開するコマンドを受け付けるまで，
  --- コマンドの受付をループする．
  -- debugger: デバッガ
  function m:loop(debugger)
    while true do
      local is_loop = self:doCommand(debugger)
      if not is_loop then
        break
      end

      -- ループする場合はコールバックを呼んでおく
      debugger.callback(debugger)
    end
  end

  --- コマンドを受け付けて実行する．
  -- debugger: デバッガ
  function m:doCommand(debugger)
    debugger.writer:write('LUPE>')
    local line = io.read()
    for _, command_factory in pairs(self.command_factories) do
      local cmd = command_factory:createCommand(line)
      if cmd then
        return cmd(debugger)
      end
    end

    return true
  end

  return m
end
