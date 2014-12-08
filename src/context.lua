--- context.lua

--- デバッグコンテキスト
local Context = {
  global_defined_lines = {}
}

for k, v in pairs(_G) do
  Context.global_defined_lines[k] = {
    source = 'Unknown',
    line   = -1,
  }
end

--- Contextを作る．
-- debug_info: デバッグ情報
-- var_infoes: 変数情報
function Context.create(debug_info, var_infoes)

  local var_defined_lines = {}

  -- ローカル変数の宣言箇所を記録
  -- とりあえず，この行にする
  for _, var_info in ipairs(var_infoes) do
    if not var_info.is_upvalue then
      var_defined_lines[var_info.name] = {
        source = utils:withoutPrefixSource(debug_info.source),
        line   = debug_info.currentline,
      }
    end
  end

  local m = {
    var_infoes        = var_infoes,
    var_defined_lines = var_defined_lines,
    name              = (debug_info.name or ''),
    namewhat          = debug_info.namewhat,
    what              = debug_info.what,
    source            = debug_info.source,
    currentline       = debug_info.currentline,
    linedefined       = debug_info.linedefined,
    lastlinedefined   = debug_info.lastlinedefined,
    nups              = debug_info.nups,
    nparams           = debug_info.nparams,
    isvararg          = debug_info.isvararg,
    istailcall        = debug_info.istailcall,
    short_src         = debug_info.short_src,
    func              = debug_info.func,
    start_time_ms     = os.clock() * 1000,
    start_memory_kB   = collectgarbage('count')
  }

  --- コンテキストが作られた時からの経過時間と使用メモリを取得する．
  -- 経過時間[ms]
  -- 使用メモリ[kB]
  function m:record()
    local end_time_ms = os.clock() * 1000
    local duration_ms = end_time_ms - self.start_time_ms
    local use_memory_kB = collectgarbage('count') - self.start_memory_kB
    return duration_ms, use_memory_kB
  end

  --- 新しい情報に更新する．
  -- context: 更新する情報を持つコンテキスト
  function m:update(context)

    local warnings = {}

    -- グローバル変数の宣言箇所を記録
    for k, v in pairs(_G) do
      if not Context.global_defined_lines[k] then
        Context.global_defined_lines[k] = {
          source = utils:withoutPrefixSource(self.source),
          line   = self.currentline,
        }
      end
    end

    -- 新しい変数の場合は宣言された場所を記録
    for name, var_defined_line in pairs(context.var_defined_lines) do
      if not self.var_defined_lines[name] then
        self.var_defined_lines[name] = {
          source = utils:withoutPrefixSource(self.source),
          line   = self.currentline,
        }

        -- グローバル変数を上書いているか？
        if _G[name] then
          table.insert(warnings, string.format('local variable %s overwrites global variable', name))
        end
      end
    end

    self.var_infoes      = context.var_infoes
    self.name            = context.name
    self.namewhat        = context.namewhat
    self.what            = context.what
    self.source          = context.source
    self.currentline     = context.currentline
    self.linedefined     = context.linedefined
    self.lastlinedefined = context.lastlinedefined
    self.nups            = context.nups
    self.nparams         = context.nparams
    self.isvararg        = context.isvararg
    self.istailcall      = context.istailcall
    self.short_src       = context.short_src
    self.func            = context.func

    return warnings
  end

  --- JSONに変換する．
  function m:toJSON()
    local t = {
      var_infoes        = self.var_infoes,
      var_defined_lines = self.var_defined_lines,
      name              = self.name,
      namewhat          = self.namewhat,
      what              = self.what,
      source            = utils:withoutPrefixSource(self.source),
      currentline       = self.currentline,
      linedefined       = self.linedefined,
      lastlinedefined   = self.lastlinedefined,
      nups              = self.nups,
      nparams           = self.nparams,
      isvararg          = self.isvararg,
      istailcall        = self.istailcall or false,
      short_src         = self.short_src,
      start_time_ms     = self.start_time_ms,
      start_memory_kB   = self.start_memory_kB,
    }

    -- グローバル変数も反映させておく
    for name, global_defined_line in pairs(Context.global_defined_lines) do
      if not self.var_defined_lines[name] and global_defined_line.line ~= -1 then
        self.var_defined_lines[name] = global_defined_line
      end
    end

    -- ない場合はnilにしておく
    if not next(t.var_defined_lines) then
      t.var_defined_lines = nil
    end

    return JSON.stringify(t)
  end

  return m
end
