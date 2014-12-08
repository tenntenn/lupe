--- break_point_command_factory.lua

local BreakPointCommandFactory = {}

function BreakPointCommandFactory.create()
  local m = {}

  --- ブレークポイントに関するコマンドを作る．
  -- line: 入力された文字列
  -- 入力された文字列から
  --  ・ブレークポイントの追加
  --  ・ブレークポイントの削除
  --  ・ブレークポイントの一覧
  -- のいずれかのコマンドを返す．
  -- 上記のどれにも当てはまらなかったら，nil を返す．
  function m:createCommand(line)
    local cmd = utils:splitWords(line)
    if not cmd and #cmd <= 0 then
      return nil
    end

    -- ブレークポイントの追加
    if cmd[1] == 'addBreakPoint' or cmd[1] == 'ab' then
      return function(debugger)
        if cmd[3] then
          debugger.break_point_manager:add(utils:withPrefixSource(cmd[2]), tonumber(cmd[3]))
        else
          debugger.break_point_manager:add(debugger.call_stack[1].source, tonumber(cmd[2]))
        end
        return true
      end
    end

    -- ブレークポイントの削除
    if cmd[1] == 'removeBreakPoint' or cmd[1] == 'rb' then
      return function(debugger)
        if cmd[3] then
          debugger.break_point_manager:remove(utils:withPrefixSource(cmd[2]), tonumber(cmd[3]))
        else
          debugger.break_point_manager:remove(debugger.call_stack[1].source, tonumber(cmd[2]))
        end
        return true
      end
    end

    -- ブレークポイントの一覧
    if line == 'breakPointList' or line == 'bl' then
      return function(debugger)
        for id, _ in pairs(debugger.break_point_manager.break_points) do
          debugger.writer:writeln(id)
        end
        return true
      end
    end

    return nil
  end

  return m
end
