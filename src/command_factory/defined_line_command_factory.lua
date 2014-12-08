--- defined_line_command_factory.lua

local DefinedLineCommandFactory = {}

function DefinedLineCommandFactory.create()
  local m = {}

  --- listコマンドを作る．
  -- line: 入力された文字列
  -- 入力された文字列が definedLine コマンドに当てはまらなかった場合はnil
  -- そうでない場合 definedLine コマンド
  function m:createCommand(line)
    local cmd = utils:splitWords(line)
    if not cmd and #cmd <= 0 then
      return nil
    end

    if (cmd[1] == 'definedLine' or cmd[1] == 'd') and type(cmd[2]) == 'string' then
      return function(debugger)
        local var_name = cmd[2]
        local defined_line

        for level = 1, #debugger.call_stack do
          if debugger.call_stack[level].var_defined_lines[var_name] then
            defined_line = debugger.call_stack[level].var_defined_lines[var_name]
            break
          end
        end

        defined_line = defined_line or Context.global_defined_lines[var_name]
        if defined_line then
          local source = defined_line.source or '-'
          local line   = defined_line.line   or -1
          debugger.writer:writeln(string.format('%s:%d ', source, line))
        end 
        
        return true
      end
    end

    return nil
  end

  return m
end
