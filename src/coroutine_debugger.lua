--- coroutine_debugger.lua

--- コルーチンをデバッグするための機能を提供するクラス．
local CoroutineDebugger = {}

--- CoroutineDebuggerを作る．
-- debugger: デバッガ本体
function CoroutineDebugger.create(debugger)

  local m = {
    debugger = debugger,
    threads  = {},
  }

  --- Lua5.1用にsethookする．
  -- mode: hookのモード
  function m.sethook51(mode)
    local hook = debug.gethook()
    if not hook and m.debugger.is_started then
      debug.sethook(m.debugger.stop_callback, mode)
    end
  end

  --- Lua5.2用にsethookする．
  -- mode: hookのモード
  function m.sethook52(mode)
    local th = coroutine.running()
    local hook = debug.gethook(th)
    if not hook and m.debugger.is_started then
      debug.sethook(th, m.debugger.stop_callback, mode)
      table.insert(m.threads, th)
    end
  end

  -- Luaのバージョンによって，sethookの方法を分ける
  function m.sethook(mode)
    if _VERSION == 'Lua 5.2' then
      m.sethook52(mode)
    else
      m.sethook51(mode)
    end
  end

  --- コルーチンのデバッグを開始する．
  --- coroutine.createとcoroutine.wrapを上書いているため注意する．
  function m:start()
    self.cocreate = coroutine.create
    coroutine.create = function(func)
      return self.cocreate(function(...)
        m.sethook('crl')
        return func(...)
      end)
    end

    self.cowrap = coroutine.wrap
    coroutine.wrap = function(func)
      return self.cowrap(function(...)
        m.sethook('crl')
        return func(...)
      end)
    end
  end

  --- コルーチンのデバッグを停止する．
  --- Lua 5.1では，debug.sethookにthreadを渡せないため，うまく動作しない．
  function m:stop()
    coroutine.create = self.cocreate or coroutine.create
    coroutine.wrap   = self.cowrap or coroutine.wrap
    for _, th in ipairs(self.threads) do
      debug.sethook(th)
    end
  end

  return m
end
