--- vars_command_factory.lua

local VarsCommandFactory = {}

function VarsCommandFactory.create()
  local m = {
    showDefinedLine = false,
  }

  --- listコマンドを作る．
  -- line: 入力された文字列
  -- 入力された文字列が vars コマンドに当てはまらなかった場合はnil
  -- そうでない場合 vars コマンド
  function m:createCommand(line)
    local cmd = utils:splitWords(line)
    if not cmd and #cmd <= 0 then
      return nil
    end

    if cmd[1] == 'vars' or cmd[1] == 'v' then
      return function(debugger)
        local level = math.min(tonumber(cmd[2] or 1) or 1, #debugger.call_stack)
        local var_infoes = debugger.call_stack[level].var_infoes
        local var_defined_lines = debugger.call_stack[level].var_defined_lines
        local show_level = tonumber(cmd[3]) -- nilの場合はデフォルト値で表示される
        for _, var_info in ipairs(var_infoes) do
          if self.showDefinedLine then
            local source = var_defined_lines[var_info.name].source or '-'
            local line   = var_defined_lines[var_info.name].line or -1
            debugger.writer:write(string.format('%s:%d ', source, line))
          end
          debugger.writer:writeln(string.format('%s(%s): %s', var_info.name, var_info.value_type, utils:inspect(var_info.value, show_level)))
        end

        return true
      end
    end

    return nil
  end

  return m
end
