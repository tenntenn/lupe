--- run_command_factory.lua

--- runコマンドを作成するファクトリクラス．
local RunCommandFactory = {}

--- RunCommandFactoryを作る．
function RunCommandFactory.create()
  local m = {}

  --- runコマンドを作る．
  -- line: 入力された文字列
  -- 入力された文字列が run コマンドに当てはまらなかった場合はnil
  -- そうでない場合 run コマンド
  function m:createCommand(line)
    if line == 'run' or line == 'r' then
      return function(debugger)
        return false
      end
    end
    return nil
  end

  return m
end
