--- list_command_factory.lua

--- 現在の行の周辺の行を表示するコマンドを作るファクトリクラス．
local ListCommandFactory = {
  -- デフォルトの表示する行数(現在の行の他に表示する上下の行数)
  DEFAULT_NUM_LINES = 3,
}

--- ListCommandFactoryを作る
function ListCommandFactory.create()
  local m = {}

  --- listコマンドを作る．
  -- line: 入力された文字列
  -- 入力された文字列が list コマンドに当てはまらなかった場合はnil
  -- そうでない場合 list コマンド
  function m:createCommand(line)
    local cmd = utils:splitWords(line)
    if not cmd and #cmd <= 0 then
      return nil
    end

    if cmd[1] == 'list' or cmd[1] == 'l' then
      return function(debugger)
        local context = debugger.call_stack[1]
        local num_lines = tonumber(cmd[2] or ListCommandFactory.DEFAULT_NUM_LINES)
        local reader = Reader.create(utils:getSource(context))
        local lines = reader:lines()

        for i = math.max(context.currentline - num_lines, 1), math.min(context.currentline + num_lines, #lines) do

          -- 現在の行の場合は>を出す
          if i == context.currentline then
            debugger.writer:write('>')
          else
            debugger.writer:write(' ')
          end

          -- ブレークポイントの場合は*を出す
          if debugger.break_point_manager:isBreakPoint(context.source, i) then
            debugger.writer:write('*')
          else
            debugger.writer:write(' ')
          end

          local fmt = '%' .. tostring(utils:numDigits(#lines)) .. 'd: %s'
          print(string.format(fmt, i, lines[i]))
        end

        return true
      end
    end
    return nil
  end

  return m 

end
