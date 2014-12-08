--- eval_command_factory.lua

--- Luaコードを実行するコマンドを作るファクトリクラス．
local EvalCommandFactory = {}

--- EvalCommandFactoryを作る．
function EvalCommandFactory.create()
  local m = {}
 
  --- evalコマンドを作る．
  -- line: 入力された文字列
  -- evalコマンド
  function m:createCommand(line)
    return function(debugger)
      local context = debugger.call_stack[1]
      local evaluator = Evaluator.create(context)
      local _, err = evaluator:eval(line)

      if err then
        debugger.writer:writeln("Command not found or given Lua chunk has error.")
        debugger.writer:writeln('Eval ERROR: ' .. err)
      end

      -- ウォッチ式の更新
      debugger.watch_manager:update(context)

      return true
    end
  end

  return m
end
