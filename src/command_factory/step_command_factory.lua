-- step_command_factory.lua

--- ステップ実行に関するコマンドを作るファクトリクラス．
local StepCommandFactory = {}

--- StepCommandFactoryを作る．
function StepCommandFactory.create()
  local m = {}

  --- ステップ実行に関するコマンドを作る．
  -- line: 入力された文字列
  -- 入力された文字列から
  --  ・ステップオーバー
  --  ・ステップイン
  --  ・ステップアウト
  -- のいずれかのコマンドを返す．
  -- 上記のどれにも当てはまらなかったら，nil を返す．
  function m:createCommand(line)
    local cmd = utils:splitWords(line)
    if not cmd and #cmd <= 0 then
      return nil
    end

    -- ステップオーバー
    if cmd[1] == 'step' or cmd[1] == 's' then
      return function(debugger)
        debugger.step_execute_manager:setStepOver(debugger.call_stack, tonumber(cmd[2] or '1'))
        return false
      end
    end

    -- ステップイン
    if cmd[1] == 'stepIn' or cmd[1] == 'si' then
      return function(debugger)
        debugger.step_execute_manager:setStepIn(debugger.call_stack, tonumber(cmd[2] or '1'))
        return false
      end
    end

    -- ステップアウト
    if cmd[1] == 'stepOut' or cmd[1] == 'so' then
      return function(debugger)
        debugger.step_execute_manager:setStepOut(debugger.call_stack, tonumber(cmd[2] or '1'))
        return false
      end
    end

    return nil
  end

  return m
end
