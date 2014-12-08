--- profile_command_factory.lua

--- プロファイルを行うためのコマンド
local ProfileCommandFactory = {}

--- ProfileCommandFactoryを作る．
function ProfileCommandFactory.create()
  local m = {
    last_profiler = nil
  }

  --- プロファイリングに関するコマンドを作る．
  -- line: 入力された文字列
  -- 入力された文字列から
  --  ・プロファイラの開始
  --  ・プロファイル結果の出力
  --  ・プロファイラの終了
  -- のいずれかのコマンドを返す．
  -- 上記のどれにも当てはまらなかったら，nil を返す．
  function m:createCommand(line)
    local cmd = utils:splitWords(line)
    if not cmd and #cmd <= 0 then
      return nil
    end

    if cmd[1] == 'startProfile' or cmd[1] == 'sp' then
      return function(debugger)
        debugger:startProfile()
        debugger.writer:writeln('start profiler')
        return true
      end
    end

    if cmd[1] == 'profile' or cmd[1] == 'p' then
      return function(debugger)
        if not m.last_profiler then
          debugger.writer:writeln('ERROR: profiler is running or does not start', 'ERROR')
          return true
        end

        local summary = m.last_profiler:summary()
        if not next(summary) then
          return true
        end

        debugger.writer:writeln(JSON.stringify(summary))
        return true
      end
    end

    if cmd[1] == 'endProfile' or cmd[1] == 'ep' then
      return function(debugger)
        m.last_profiler = debugger.profiler
        debugger:endProfile()
        debugger.writer:writeln('stop profiler')
        return true
      end
    end
    
    return nil
  end

  return m

end
