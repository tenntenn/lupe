--- info_command_factory.lua

local InfoCommandFactory = {}

function InfoCommandFactory.create()
  local m = {}

  --- infoコマンドを作る．
  -- line: 入力された文字列
  -- 入力された文字列が info コマンドに当てはまらなかった場合はnil
  -- そうでない場合 info コマンド
  function m:createCommand(line)
    local cmd = utils:splitWords(line)
    if not cmd and #cmd <= 0 then
      return nil
    end

    if cmd[1] == 'info' or cmd[1] == 'i' then
      local cmd_index = 2

      -- コールスタック情報を表示する
      local call_stack_cmd = function(debugger)
        debugger.writer:writeln('call stack:')
        if tonumber(cmd[cmd_index+1]) then
          local call_stack = utils:slice(debugger.call_stack, tonumber(cmd[cmd_index+1]))
          debugger.writer:writeln(JSON.stringify(call_stack), Writer.TAG.CALL_STACK)
          cmd_index = cmd_index + 1
        else
          debugger.writer:writeln(JSON.stringify(debugger.call_stack), Writer.TAG.CALL_STACK)
        end
        debugger.writer:writeln()
      end

      -- ブレークポイント情報を表示する
      local break_points_cmd = function(debugger)
        debugger.writer:writeln('break points:')
        local break_points = debugger.break_point_manager.break_points
        if next(break_points) then
          debugger.writer:writeln(JSON.stringify(break_points), Writer.TAG.BREAK_POINTS)
        else
          debugger.writer:writeln('{}', Writer.TAG.BREAK_POINTS)
        end
        debugger.writer:writeln()
      end

      -- ウォッチ情報を表示する
      local watches_cmd = function(debugger)
        debugger.writer:writeln('watches:')
        debugger.writer:writeln(JSON.stringify(debugger.watch_manager.watches), Writer.TAG.WATCHES)
        debugger.writer:writeln()
      end

      return function(debugger)
        -- 指定がない場合はすべて
        if not cmd[cmd_index] then
          call_stack_cmd(debugger)
          break_points_cmd(debugger)
          watches_cmd(debugger)
          return true
        end

        while cmd[cmd_index] do
          if cmd[cmd_index] == 'call_stack' then
            call_stack_cmd(debugger)
          elseif cmd[cmd_index] == 'break_points' then
            break_points_cmd(debugger)
          elseif cmd[cmd_index] == 'watches' then
            watches_cmd(debugger)
          end
          cmd_index = cmd_index + 1
        end

        return true
      end
    end
    return nil
  end

  return m 
end
