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

  --- Lua5.1用のsethookが呼ばれるラッパーを作る．
  -- func: ラップする関数
  function m:createCoroutineFunc51(func)
    local debugger = self.debugger
    return function()
      local hook, _, _ = debug.gethook()
      if not hook and debugger.is_started then
        debug.sethook(debugger.stop_callback, 'crl')
      end
      return func(coroutine.yield())
    end
  end

  --- Lua5.2用のsethookが呼ばれるラッパーを作る．
  -- func: ラップする関数
  function m:createCoroutineFunc52(func)
    local threads  = self.threads
    local debugger = self.debugger
    return function()
      local th, _ = coroutine.running()
      local hook, _, _ = debug.gethook(th)
      if not hook and debugger.is_started then
        debug.sethook(th, debugger.stop_callback, 'crl')
        table.insert(threads, th)
      end
      return func(coroutine.yield())
    end
  end

  --- sethookが呼ばれるラッパーを作る．
  -- func: ラップする関数
  function m:createCoroutineFunc(func)
    if _VERSION == 'Lua 5.2' then
      return self:createCoroutineFunc52(func)
    else
      return self:createCoroutineFunc51(func)
    end
  end

  --- コルーチンのデバッグを開始する．
  --- coroutine.createとcoroutine.wrapを上書いているため注意する．
  function m:start()
    self.cocreate = coroutine.create
    coroutine.create = function(func)
      local th = self.cocreate(self:createCoroutineFunc(func))
      coroutine.resume(th)
      return th 
    end

    self.cowrap = coroutine.wrap
    coroutine.wrap = function(func)
      local wraped = self.cowrap(self:createCoroutineFunc(func))
      wraped()
      return wraped
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
