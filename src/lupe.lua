--- lupe.lua

--- デバッガの機能を提供するクラス．
local Lupe = {}

--- Lupeを作る．
function Lupe.create()
  local m = {
    callback             = function()end,
    call_stack           = {},
    top_level_context    = nil,
    prompt               = Prompt.create(),
    break_point_manager  = BreakPointManager.create(),
    step_execute_manager = StepExecuteManager.create(),
    watch_manager        = WatchManager.create(),
    profiler             = nil,
    writer               = Writer.create(),
    is_called            = false,
    is_started           = false,
--
    JSON                 = JSON,
  }

  m.coroutine_debugger   = CoroutineDebugger.create(m)

  --- sethookで呼ばれるコードバック
  function m.stop_callback(t)

    local debug_info = debug.getinfo(2)
    if not debug_info or utils:isLupe(debug_info) then
      return
    end

    local var_infoes = VarInfo.getlocal(2)
    local context = Context.create(debug_info, var_infoes)

    -- 各行
    if t == 'line' then
      m:lineStop(context)

      -- 変数の変更があったら反映
      for _, var_info in pairs(context.var_infoes) do
        var_info:update(2)
      end

      -- ウォッチ式の更新
      m.watch_manager:update(context)
      return
    end

    -- 関数呼び出し
    if t == 'call' or t == 'tail call' then
      m:callStop(context)
      return
    end

    -- return
    if t == 'return' or t == 'tail return' then
      m:returnStop(context)
      return
    end
  end

  local function __call()
    m.is_called = true
  end

  --- デバッグを開始する．
  function m:start()
    debug.sethook(self.stop_callback, 'crl')
    self.coroutine_debugger:start()
    self.is_started = true
  end

  --- デバッガを停止する．
  function m:stop()
    debug.sethook()
    self.coroutine_debugger:stop()
    self.call_stack = {}
    self.is_started = false
    self.break_point_manager:clear()
  end

  --- コールスタックを消します．
  function m:clear()
    self.call_stack = {}
  end

  --- プロファイルを開始する．
  function m:startProfile()
    self.profiler = Profiler.create()
  end

  --- プロファイルを停止する．
  function m:endProfile()
    self:dump(self.profiler:summary())
    self.profiler = nil
  end

  --- infoコマンドを実行する．
  -- サブコマンド
  function m:info(sub_cmd)
    local info_cmd_factory = InfoCommandFactory.create()
    local line = 'info'
    if sub_cmd then
      line = line .. ' ' .. sub_cmd
    end
    local info_cmd = info_cmd_factory:createCommand(line)
    info_cmd(self)
  end

  --- 行ごとに呼ばれる．
  --- この行で止まるべきか判断し，止まる場合はコマンドを受け付けるプロンプトを表示させる．
  -- context: コンテキスト
  function m:lineStop(context)
    local is_top_level = false
    if #self.call_stack <= 0 then
      self.top_level_context = self.top_level_context or context
      self.call_stack[1] = self.top_level_context
      is_top_level = true
    end

    -- コンテキストのアップデート
    local warnings = self.call_stack[1]:update(context)
    if warnings and #warnings > 0 then
      self.writer:writeln('====== WARNING ======')
      for _, warning in pairs(warnings) do
        self.writer:writeln(tostring(warning), Writer.TAG.WARNING)
      end
      self.writer:writeln('====== WARNING ======')
    end

    -- デバッグモードに入ったか，ブレークポイントか，ステップ実行で停止するか？
    if self.is_called or
       self.break_point_manager:shouldStop(self.call_stack) or
       self.step_execute_manager:shouldStop(self.call_stack) then

      -- コールバックを呼ぶ
      self.callback(self)

      self:showPrompt(context)
    end

    if is_top_level then
      table.remove(self.call_stack, 1)
    end
  end

  --- プロンプトを表示させる
  -- context: コンテキスト
  function m:showPrompt(context)
    self.is_called = false
    self.step_execute_manager:clear()
    self.writer:writeln(string.format('stop at %s:%d', context.source, context.currentline))
    self.prompt:loop(self)
  end

  --- スタックトレースを表示させる
  -- msg: 一緒に表示するメッセージ
  function m:traceback(msg)
    if msg then
      self.writer:writeln(tostring(msg))
    end
    local count = 0
    for _, context in ipairs(self.call_stack) do
      if context.source ~= '=[C]' then
        count = count + 1
        for i = 1, count do
          self.writer:write(' ')
        end
        self.writer:writeln(string.format('%s:%d %s', context.source, context.currentline, context.name))
      end
    end
  end

  --- 関数の呼び出し時に呼ばれる．
  --- コールスタックをプッシュする．
  -- context: コンテキスト
  function m:callStop(context)
    table.insert(self.call_stack, 1, context)
  end

  --- 関数のreturn時に呼ばれる．
  --- コールスタックをポップする．
  -- context: コンテキスト
  function m:returnStop(context)
    -- Lua 5.2 では，tail call は return イベントが呼ばれない．
    -- そのため， istailcall が true の間は pop し続ける．
    while true do
      local _context = table.remove(self.call_stack, 1)

      -- プロファイルを行う
      if self.profiler then
        self.profiler:record(_context)
      end

      if not _context or not _context.istailcall then
        break
      end
    end
  end

  --- 値をダンプする．
  -- value: ダンプする値
  function m:dump(value, max_level)
    self.writer:writeln(utils:inspect(value, max_level))
  end

  return setmetatable(m, {__call = __call})
end

--- export
rawset(_G, 'Lupe', Lupe.create())
