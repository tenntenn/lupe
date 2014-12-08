-- LUPE
-- built at 2014-12-09 01:45:35
-- Author: Takuya Ueda

--- utils.lua

local Utils = {}

function Utils.create()
  local m = {
    debugger_source = debug.getinfo(1, 'S').source,
    source_prefix   = string.gsub(debug.getinfo(1, 'S').source, '@?.*/(.*)', '%1'),
  }

  --- debug_infoがLupeのものか調べる．
  -- debug_info: デバッグ情報
  function m:isLupe(debug_info)
    return debug_info.source == self.debugger_source
  end

  --- ソースコードを取得する．
  -- debug_info: デバッグ情報
  -- @がある場合はそれを取り除いたinfo.source
  function m:getSource(debug_info)
    local source, _ = string.gsub(debug_info.source, '@?(.+)', '%1')
    return source
  end

  --- 相対パスでのソースファイルパスを取得する．
  -- source: ソースファイル
  function m:withoutPrefixSource(source)
    local without_prefix, _ = string.gsub(source, self.source_prefix .. '/(.*)', '%1')
    local without_atto, _ = string.gsub(without_prefix, '@?(.+)', '%1')
    return without_atto
  end

  --- 絶対パスでのソースファイルパスを取得する．
  -- source: ソースファイル
  -- hoge.lua -> file://install/hoge.lua
  function m:withPrefixSource(source)
    return self.source_prefix .. '/' .. self:withoutPrefixSource(source)
  end

  --- コールスタックの中で，指定したコンテキストの関数が一致する階層を取得する．
  -- call_stack: コールスタック
  -- context: コンテキスト
  -- 見つからない場合は0
  function m:getLevelByFunc(call_stack, context)
    for i, c in ipairs(call_stack) do
      if c.func == context.func then
        return i
      end
    end

    return 0
  end

  --- 文字列を単語に分ける．
  -- str: 文字列
  -- 単語毎に分けた文字列の配列
  function m:splitWords(str)
    local words = {}
    for word in string.gmatch(str, '[^%s]+') do
      table.insert(words, word)
    end
    return words
  end

  --- テーブルをコピーする
  function m:tableCopy(tbl)
    local t = {}
    for k, v in pairs(tbl) do
      t[k] = v
    end
    return t
  end

  --- 10進数で何桁か返す．
  -- num: 桁数を数える数値
  function m:numDigits(num)
    local num_digits = 0
    num = math.floor(math.abs(num))
    while true do
      if num <= 0 then
        return num_digits
      end

      num = math.floor(num / 10)
      num_digits = num_digits + 1
    end
  end

  --- テーブルが空の場合に，ダミーデータを入れます．
  -- tbl: テーブル
  function m:dummy(tbl)
    if not next(tbl) then
      tbl['__dummy'] = 'dummy'
    end
    return tbl
  end

  --- 配列のスライスを取得する．
  --- 第3引数を省略すると，終了インデクスは配列の長さと同じになる．
  -- array: 配列
  -- start_index: 開始インデックス
  -- end_index: 終了インデックス
  function m:slice(array, start_index, end_index)
    if not array or #array <= 0 then
      return {}
    end

    start_index = math.max(start_index, 1)
    end_index   = math.min(end_index or #array, #array)

    local a = {}
    for i = start_index, end_index do
      table.insert(a, array[i])
    end

    return a
  end

  --- 配列の中の指定した値のインデックスを取得する．
  -- array: 配列
  -- value: 検索する値
  -- ある場合はインデックス，ない場合は-1
  function m:indexOf(array, value)
    for i, v in ipairs(array) do
      if v == value then
        return i
      end
    end
    return -1
  end

  --- inspectのヘルパー関数．
  -- value: 文字列にする値
  -- max_level: 表示する階層の最大値
  -- level: 現在の階層
  local function _inspect(value, max_level, level)
    
    local str = ''

    local t = type(value)
    if t == 'table' then
      if level >= max_level then
        return '...'
      end

      local indent = '' 
      for i = 1, level do
        indent = indent .. ' '
      end

      str = str .. '{\n'
      for k, v in pairs(value) do
        str = str .. indent .. string.format(' %s(%s): %s\n', tostring(k), type(v), _inspect(v, max_level, level + 1))
      end
      str = str .. indent .. '}'
    else
      str = str .. tostring(value)
    end

    return str
  end

  --- 文字列にする.
  -- value: 文字列にする値
  -- max_level: 表示する階層の最大値
  function m:inspect(value, max_level)
    max_level = max_level or 5
    return _inspect(value, max_level, 0)
  end

  --- 文字列の配列を結合する．
  -- array: 文字列の配列
  -- delimiter: デリミタ
  function m:join(array, delimiter)
    if not array or #array <= 0 then
      return ''
    end

    delimiter = tostring(delimiter or ' ')

    local s = ''
    for _, v in ipairs(array) do
      s = s .. tostring(v) .. delimiter
    end

    return string.sub(s, 1, string.len(s) - string.len(delimiter))
  end

  return m
end

local utils = Utils.create()
-- json.lua
-- JSONのエンコーダを提供する．

local JSON = {}

local escapeTable = {}
escapeTable['"'] = '\\"'
escapeTable['\\'] = '\\\\'
escapeTable['\b'] = '\\b'
escapeTable['\f'] = '\\f'
escapeTable['\n'] = '\\n'
escapeTable['\r'] = '\\r'
escapeTable['\t'] = '\\t'

--- 文字列をエスケープする．
-- str: エスケープする文字列
function JSON.escape(str)
  local s = ''

  string.gsub(str, '.', function(c)
    if escapeTable[c] then
      s = s .. escapeTable[c]
    else
      s = s .. c
    end
  end)

  return s
end

--- 配列をJSONエンコードする．
-- arry: 配列
function JSON.stringifyArray(arry)
  local s = ''
  for i = 1, #arry do
    s = s .. JSON.stringify(arry[i]) .. ','
  end
  s = string.sub(s, 1, string.len(s) - 1)

  return string.format('[%s]', s)
end

--- テーブルをJSONエンコードする．
--- toJSONをメソッドとして持つ場合はそれを呼ぶ．
-- tbl: テーブル
function JSON.stringifyTable(tbl)
  if tbl.toJSON and type(tbl.toJSON) == 'function' then
    return tbl:toJSON()
  end

  local isArray = true
  local s = ''
  for k, v in pairs(tbl) do
    if type(k) ~= 'number' then
      isArray = false
    end

    s = s .. string.format('"%s":%s,', tostring(k), JSON.stringify(v))
  end
  s = string.sub(s, 1, string.len(s) - 1)

  if isArray then
    return JSON.stringifyArray(tbl)
  end

  return string.format('{%s}', s)
end

--- JSONエンコードする．
-- v: エンコードする値
function JSON.stringify(v)
  local t = type(v)

  if t == 'table' then
    return JSON.stringifyTable(v)
  elseif t == 'string' then
    return '"' .. JSON.escape(v) .. '"'
  elseif t == 'function' or t == 'thread' or t == 'userdata' then
    return '"' .. tostring(v) .. '"'
  elseif t == 'nil' then
    return 'null'
  end

  return tostring(v)
end
--- reader.lua

--- io.linesを使ってソースコードの各行をテーブルに格納して返す．
-- source: ソースコード
-- ソースコードを格納したテーブル
local function _lines(source)
  local lines = {}
  for l in io.lines(source) do
    table.insert(lines, l)
  end
  return lines
end

local Reader = {
  -- 同じファイルを何度も開いても良いようにキャッシュする
  cache = {},
}

function Reader.create(source)
  local m = {
    source = source,
  }

  function m:lines()
    if Reader.cache[self.source] then
      return Reader.cache[self.source]
    end

    return _lines(self.source)
  end

  return m
end
--- writer.lua

local Writer = {}

Writer.TAG = {
  CALL_STACK   = 'CALL_STACK',
  WATCHES      = 'WATCHES',
  BREAK_POINTS = 'BREAK_POINTS',
  WARNING      = 'WARNING',
}

function Writer.create()
  local m = {}

  function m:write(msg, tag)
    io.write(msg)
  end

  function m:writeln(msg, tag)
    msg = msg or ''
    self:write(msg .. '\n', tag)
  end

  return m
end
--- var_info.lua

--- 変数情報を表すクラス．
local VarInfo = {}

--- VarInfoを作成する．
-- name: 変数名
-- value: 値
-- index: 変数のインデックス
-- is_upvalue: 上位値かどうか
function VarInfo.create(name, value, index, is_upvalue)
  local m = {
    name        = name,
    value_type  = type(value),
    value       = value,
    is_nil      = (value == nil),
    index       = index,
    new_value   = value,
    is_upvalue  = is_upvalue,
  }

  --- 指定したレベルで変数を更新する．
  -- level: レベル
  function m:update(level)
    self.value = self.new_value
    if is_upvalue then
      local func = debug.getinfo(level + 1, 'f').func
      debug.setupvalue(func, self.index, self.value)
    else
      debug.setlocal(level + 1, self.index, self.value)
    end
  end

  --- JSONに変換する．
  function m:toJSON()
    local t = {
      name       = self.name,
      value_type = self.value_type,
      value      = self.new_value,
      is_nil     = self.is_nil,
      is_upvalue = is_upvalue,
    }
    return JSON.stringify(t)
  end

  return m
end

--- 指定したレベルのローカル変数をすべて取得する．
-- level: レベル
-- 指定したレベルで取得できる変数のVarInfoの配列
function VarInfo.getlocal(level)

  local var_infoes   = {}
  local defined_name = {}

  -- ローカル変数を取得する
  local local_index = 1
  while true do
    local name, value = debug.getlocal(level + 1, local_index)
    if not name then
      break
    end
    if name ~= '(*temporary)' then
      table.insert(var_infoes, VarInfo.create(name, value, local_index, false))
      defined_name[name] = true
    end
    local_index = local_index + 1
  end

  -- 上位値を取得する
  local func = debug.getinfo(level + 1, 'f').func
  local up_index = 1
  while true do
    local name, value = debug.getupvalue(func, up_index)
    if not name then
      break
    end
    if _ENV == nil or value ~= _ENV then
      table.insert(var_infoes, VarInfo.create(name, value, up_index, true))
    end
    up_index = up_index + 1
  end

  return var_infoes
end
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
--- profiler.lua

--- プロファイルを行うクラス．
local Profiler = {}

--- Profilerを作る．
-- callback: 記録されるたびに呼ばれるコールバック
function Profiler.create(callback)

  local m = {
    profiles = {},
    callback = callback or function() end,
  }

  --- 関数ごとのIDを生成する．
  -- context: 元にするコンテキスト
  function m:id(context)
    local name   = context.name or 'NO_NAME'
    local source = utils:withoutPrefixSource(context.source)
    local line   = context.linedefined
    return string.format('%s(%s:%d)<%s>', name, source, line, tostring(context.func))
  end

  --- プロファイルを記録する．
  -- context: 記録する情報
  function m:record(context)
    local duration_ms, use_memory_kB = context:record()
    local id = self:id(context)
    if not self.profiles[id] then
      self.profiles[id] = {}
    end
    local profile = {
      duration_ms   = duration_ms,
      use_memory_kB = use_memory_kB,
    }
    table.insert(self.profiles[id], profile)
    self.callback(profile, self.profiles)
  end

  --- 集計を行う．
  -- 各関数ごと経過時間（平均と合計），使用メモリ（平均と合計），呼び出し回数
  function m:summary()
    local summary = {}

    for id, func_profiles in pairs(self.profiles) do
      local sum = {
        duration_ms   = 0,
        use_memory_kB = 0.0
      }
      for _, profile in ipairs(func_profiles) do
        sum.duration_ms   = sum.duration_ms + profile.duration_ms
        sum.use_memory_kB = sum.use_memory_kB + profile.use_memory_kB
      end

      local average = {
        duration_ms   = sum.duration_ms / math.max(#func_profiles, 1),
        use_memory_kB = sum.use_memory_kB / math.max(#func_profiles, 1),
      }
      summary[id] = {
        sum     = sum,
        average = average,
        count   = #func_profiles,
      }
    end

    return summary
  end

  return m
end
-- evaluator.lua

--- Lua 5.1用のeval関数．
-- chunk: 実行するLuaコード
-- lenv: 実行する環境
local function eval51(chunk, lenv)
  setfenv(0, lenv)
  local fnc, err = loadstring(chunk)
  if err then
    return err
  end
  ok, err = pcall(fnc)
  setfenv(0, _G)
  if not ok then
    return err
  end
  return nil
end

--- Lua 5.2用のeval関数．
-- chunk: 実行するLuaコード
-- lenv: 実行する環境
local function eval52(chunk, lenv)
  local fnc, err = load(chunk, 'eval', 't', lenv)
  if err then
    return err
  end
  local ok, err = pcall(fnc)
  if not ok then
    return err
  end
  return nil
end

--- 評価を行うクラス．
local Evaluator = {}

-- Luaのバージョンでチャンクを実行する関数が違う
if _VERSION == 'Lua 5.2' then
  Evaluator.EVAL_FUNC = eval52
else
  Evaluator.EVAL_FUNC = eval51
end

--- Evaluatorを作る．
-- context: 評価に使用するコンテキスト
function Evaluator.create(context)

  local m = {
    context = context,
  }

  --- 環境を作る．
  -- 環境
  -- 戻り値用の変数名
  function m:createLocalEnv()
    local lenv = utils:tableCopy(_G)
    for _, var_info in ipairs(self.context.var_infoes) do
      lenv[var_info.name] = var_info.new_value
    end

    -- 戻り値用の変数を用意
    local ret_key = '_ret'
    while lenv[ret_key] do
      ret_key = '_' .. ret_key
    end

    return lenv, ret_key
  end

  --- 指定したチャンクを評価する．
  --- is_ret_value を trueにした場合，指定できるチャンクは，
  --- 代入分の右辺値だけとなる．
  -- chunk: チャンク（Luaのコード）
  -- is_ret_value: 戻り値を必要とするか
  function m:eval(chunk, is_ret_value)
    local lenv, ret_key = self:createLocalEnv()

    -- 戻り値を戻り値用の変数に入れて取得できるようにする
    if is_ret_value then
      chunk = string.format('%s = (%s)', ret_key, chunk)
    end

    -- 実行
    local err = Evaluator.EVAL_FUNC(chunk, lenv)
    if err ~= nil then
      return nil, err
    end

    -- 変数の変更の反映
    for k, v in pairs(lenv) do

      -- ローカル変数に変更を反映
      local is_updated = false
      for _, var_info in ipairs(self.context.var_infoes) do
        if var_info.name == k then
          var_info.new_value = v
          is_updated = true
          break
        end
      end

      -- ローカル変数にない場合グローバル変数を更新
      if not is_updated and _G[k] then
        rawset(_G, k, v)
      end
    end

    -- 戻り値を取得
    local ret_val
    if is_ret_value then
      ret_val = lenv[ret_key]
    end

    return ret_val, nil
  end

  return m
end
--- break_point.lua

--- ブレークポイントを表すクラス．
local BreakPoint = {}

function BreakPoint.create(source, line)

  local m = {
    source = source,
    line   = line,
  }

  --- JSONにする．
  --- ソースを相対パスにする．
  function m:toJSON()
    local t = {
      source = utils:withoutPrefixSource(self.source),
      line   = line,
    }

    return JSON.stringify(t)
  end

  return m
end
--- break_point_manager.lua

--- ブレークポイントを管理するクラス．
local BreakPointManager = {}

--- BreakPointManagerを作る．
function BreakPointManager.create()
  local m = {
    break_points = {},
  }

  --- IDを取得する．
  -- source: ソースファイル
  -- line: 行番号
  function m:id(source, line)
    return string.format('%s:%d', source, line)
  end

  --- ブレークポイントを追加する．
  -- source: ソースファイル
  -- line: 行番号
  function m:add(source, line)
    local id = self:id(source, line)
    if self.break_points[id] then
      return
    end

    local break_point = BreakPoint.create(source, line)
    self.break_points[id] = break_point
  end

  --- 指定したブレークポイントを消す．
  -- source: ソースファイル
  -- line: 行番号
  function m:remove(source, line)
    local id = self:id(source, line)
    self.break_points[id] = nil
  end

  --- 設定されているブレークポイントをすべて消す．
  function m:clear()
    self.break_points = {}
  end

  --- 設定されているブレークポイントを取得する．
  -- すべてのブレークポイント．
  function m:getAll()
    local all_break_points = {}
    for _, break_point in pairs(self.break_points) do
      table.insert(all_break_points, break_point)
    end
    return all_break_points
  end

  --- 指定した箇所がブレークポイントかどうか取得する．
  -- source: ソースファイル
  -- line: 行番号
  function m:isBreakPoint(source, line)
    local id = self:id(source, line)
    return self.break_points[id]
  end

  --- ブレークポイントで止まるべきか取得する．
  -- call_stack: 現在のコールスタック
  function m:shouldStop(call_stack)
    local source      = call_stack[1].source
    local currentline = call_stack[1].currentline
    return self:isBreakPoint(source, currentline)
  end

  return m
end
--- step_execute_manager.lua

local StepExecuteManager = {
  MODE_STEP_OVER = 0,
  MODE_STEP_IN   = 1,
  MODE_STEP_OUT  = 2,
}

function StepExecuteManager.create()
  local m = {
    mode       = nil,
    call_stack = nil,
    count      = 0,
  }

  --- ステップオーバーを設定する．
  -- call_stack: コールスタック
  -- count: 実行するステップ数
  function m:setStepOver(call_stack, count)
    self.mode       = StepExecuteManager.MODE_STEP_OVER
    self.call_stack = utils:tableCopy(call_stack)
    self.count      = count
  end

  --- ステップインを設定する．
  -- call_stack: コールスタック
  -- count: 実行するステップ数
  function m:setStepIn(call_stack, count)
    self.mode       = StepExecuteManager.MODE_STEP_IN
    self.call_stack = utils:tableCopy(call_stack)
    self.count      = count
  end

  --- ステップアウトを設定する．
  -- call_stack: コールスタック
  -- count: 実行するステップ数
  function m:setStepOut(call_stack, count)
    self.mode       = StepExecuteManager.MODE_STEP_OUT
    self.call_stack = utils:tableCopy(call_stack)
    self.count      = count
  end

  --- ステップ実行をやめる．
  function m:clear()
    self.mode       = nil
    self.call_stack = nil
    self.count      = 0
  end

  --- 停止すべきか取得する．
  -- call_stack: コールスタック
  function m:shouldStop(call_stack)
    if not self.mode then
      return false
    end

    if self.mode == StepExecuteManager.MODE_STEP_OVER then
      return self:shouldStopStepOver(call_stack)
    end

    if self.mode == StepExecuteManager.MODE_STEP_IN then
      return self:shouldStopStepIn(call_stack)
    end

    if self.mode == StepExecuteManager.MODE_STEP_OUT then
      return self:shouldStopStepOut(call_stack)
    end
  end

  --- ステップオーバーで停止すべきか取得する．
  -- call_stack: コールスタック
  function m:shouldStopStepOver(call_stack)
    if #call_stack <= 0 or
       #self.call_stack <= 0 or
       utils:getLevelByFunc(self.call_stack, call_stack[1]) >= 1 then
      self.count = self.count - 1
      return self.count <= 0
    end
    return false
  end

  --- ステップインで停止すべきか取得する．
  -- call_stack: コールスタック
  function m:shouldStopStepIn(call_stack)
    self.count = self.count - 1
    return self.count <= 0
  end

  --- ステップアウトで停止すべきか取得する．
  -- call_stack: コールスタック
  function m:shouldStopStepOut(call_stack)
    if #call_stack <= 0 or
       #self.call_stack <= 0 or
       utils:getLevelByFunc(self.call_stack, call_stack[1]) > 1 then
      self.count = self.count - 1
      return self.count <= 0
    end
    return false
  end

  return m
end
--- watch_manager.lua

--- ウォッチを管理するクラス．
local WatchManager = {}

--- WatchManagerを作る．
function WatchManager.create()
  local m = {
    watches = {},
  }

  --- ウォッチを追加する．
  --- ウォッチに指定できるチャンクは，
  --- 代入文の右辺値にできるものに限る．
  -- context: 現在のコンテキスト
  -- chunk: チャンク
  -- 不正なチャンクを指定した場合にエラーを返す．
  function m:add(context, chunk)

    if type(chunk) ~= 'string' then
      return 'chunk must be string'
    end

    local evaluator = Evaluator.create(context)
    local ret_val, err = evaluator:eval(chunk, true)

    if err ~= nil then
      return err
    end

    local watch = {
      chunk = chunk,
      value = ret_val,
    }

    table.insert(self.watches, watch)

    return nil
  end

  --- 指定したインデックスのウォッチ式を変更する．
  -- index: インデックス
  -- context: 現在のコンテキスト
  -- chunk: チャンク
  -- 不正なチャンクまたはインデックスを指定した場合にエラーを返す．
  function m:set(index, context, chunk)
    if type(chunk) ~= 'string' then
      return 'chunk must be string'
    end

    if index <= 0 or #self.watches < index then
      return 'index is out of bounds'
    end

    local evaluator = Evaluator.create(context)
    local ret_val, err = evaluator:eval(chunk, true)

    if err ~= nil then
      return err
    end

    local watch = {
      chunk = chunk,
      value = ret_val,
    }
    table.insert(self.watches, index, watch)

    return nil
  end

  --- 指定したインデックスのウォッチ式を削除する．
  -- index: インデックス
  function m:remove(index)
    if self.watches[index] then
      return table.remove(self.watches, index)
    end
    return nil
  end

  --- 指定したコンテキストでウォッチ式の評価値を更新する．
  -- context: コンテキスト
  function m:update(context)
    local evaluator = Evaluator.create(context)
    for i, watch in ipairs(self.watches) do
      local ret_val, err = evaluator:eval(watch.chunk, true)
      if err ~= nil then
        self.watches[i].value = tostring(err)
      else
        self.watches[i].value = ret_val
      end
    end
  end

  return m
end
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
--- eval_command_factory.lua

--- Luaコードを実行するコマンドを作るファクトリクラス．
local EvalCommandFactory = {}

--- EvalCommandFactoryを作る．
function EvalCommandFactory.create()
  local m = {}
 
  --- evalコマンドを作る．
  -- line: 入力された文字列
  -- evalコマンド
  function m:createCommand(line)
    return function(debugger)
      local context = debugger.call_stack[1]
      local evaluator = Evaluator.create(context)
      local _, err = evaluator:eval(line)

      if err then
        debugger.writer:writeln("Command not found or given Lua chunk has error.")
        debugger.writer:writeln('Eval ERROR: ' .. err)
      end

      -- ウォッチ式の更新
      debugger.watch_manager:update(context)

      return true
    end
  end

  return m
end
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
--- run_command_factory.lua

--- runコマンドを作成するファクトリクラス．
local RunCommandFactory = {}

--- RunCommandFactoryを作る．
function RunCommandFactory.create()
  local m = {}

  --- runコマンドを作る．
  -- line: 入力された文字列
  -- 入力された文字列が run コマンドに当てはまらなかった場合はnil
  -- そうでない場合 run コマンド
  function m:createCommand(line)
    if line == 'run' or line == 'r' then
      return function(debugger)
        return false
      end
    end
    return nil
  end

  return m
end
-- step_command_factory.lua

--- ステップ実行に関するコマンドを作るファクトリクラス．
local StepCommandFactory = {}

--- StepCommandFactoryを作る．
function StepCommandFactory.create()
  local m = {}

  --- ステップ実行に関するコマンドを作る．
  -- line: 入力された文字列
  -- 入力された文字列から
  --  ・ステップオーバー
  --  ・ステップイン
  --  ・ステップアウト
  -- のいずれかのコマンドを返す．
  -- 上記のどれにも当てはまらなかったら，nil を返す．
  function m:createCommand(line)
    local cmd = utils:splitWords(line)
    if not cmd and #cmd <= 0 then
      return nil
    end

    -- ステップオーバー
    if cmd[1] == 'step' or cmd[1] == 's' then
      return function(debugger)
        debugger.step_execute_manager:setStepOver(debugger.call_stack, tonumber(cmd[2] or '1'))
        return false
      end
    end

    -- ステップイン
    if cmd[1] == 'stepIn' or cmd[1] == 'si' then
      return function(debugger)
        debugger.step_execute_manager:setStepIn(debugger.call_stack, tonumber(cmd[2] or '1'))
        return false
      end
    end

    -- ステップアウト
    if cmd[1] == 'stepOut' or cmd[1] == 'so' then
      return function(debugger)
        debugger.step_execute_manager:setStepOut(debugger.call_stack, tonumber(cmd[2] or '1'))
        return false
      end
    end

    return nil
  end

  return m
end
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
--- watch_command_factory.lua

local WatchCommandFactory = {}

function WatchCommandFactory.create()
  local m = {}

  --- ウォッチに関するコマンドを作る．
  -- line: 入力された文字列
  -- 入力された文字列から
  --  ・ウォッチの追加
  --  ・ウォッチの削除
  --  ・ウォッチの一覧
  -- のいずれかのコマンドを返す．
  -- 上記のどれにも当てはまらなかったら，nil を返す．
  function m:createCommand(line)
    local cmd = utils:splitWords(line)
    if not cmd and #cmd <= 0 then
      return nil
    end

    -- ウォッチ式の一覧
    if cmd[1] == 'watch' or cmd[1] == 'w' then
      return function(debugger)
        local watches = debugger.watch_manager.watches
        local fmt = '%' .. tostring(utils:numDigits(#watches)) .. 'd: %s = %s'
        for i, watch in ipairs(watches) do
          local str_value = utils:inspect(watch.value)
          debugger.writer:writeln(string.format(fmt, i, watch.chunk, str_value))
        end
        return true
      end
    end

    -- ウォッチ式の追加・更新
    if cmd[1] == 'setWatch' or cmd[1] == 'sw' then
      return function(debugger)
        local context = debugger.call_stack[1]
        local chunk, err
        local index = tonumber(cmd[2])
        if not index then
          chunk = utils:join(utils:slice(cmd, 2), " ")
          err   = debugger.watch_manager:add(context, chunk)
        else
          chunk = utils:join(utils:slice(cmd, 3), " ")
          err   = debugger.watch_manager:set(index, context, chunk)
        end

        if err then
          debugger.writer:writeln('ERROR: ' .. tostring(err))
          return true
        end

        debugger.writer:writeln('add watch ' .. chunk)
        return true
      end
    end

    -- ウォッチ式の削除
    if cmd[1] == 'removeWatch' or cmd[1] == 'rw' then
      local index = tonumber(cmd[2])
      if not index then
        return nil
      end

      return function(debugger)
        local watch = debugger.watch_manager:remove(index)
        if watch then
          debugger.writer:writeln('remove watch ' .. watch.chunk)
        end
        return true
      end
    end

    return nil
  end

  return m
end
--- prompt.lua

--- プロンプトを扱うクラス．
local Prompt = {}

--- Promptを作る．
function Prompt.create()

  local m = {
    command_factories = {
      StepCommandFactory.create(),        -- ステップ実行
      RunCommandFactory.create(),         -- Run
      BreakPointCommandFactory.create(),  -- ブレークポイント
      InfoCommandFactory.create(),        -- デバッグ情報の出力
      ListCommandFactory.create(),        -- ソースコードの出力
      VarsCommandFactory.create(),        -- 変数の出力
      DefinedLineCommandFactory.create(), -- 変数の宣言位置の出力
      WatchCommandFactory.create(),       -- ウォッチ式
      ProfileCommandFactory.create(),     -- プロファイラ
      EvalCommandFactory.create(),        -- 式の評価（最後にしないとダメ）
    },
  }

  --- 処理を再開するコマンドを受け付けるまで，
  --- コマンドの受付をループする．
  -- debugger: デバッガ
  function m:loop(debugger)
    while true do
      local is_loop = self:doCommand(debugger)
      if not is_loop then
        break
      end

      -- ループする場合はコールバックを呼んでおく
      debugger.callback(debugger)
    end
  end

  --- コマンドを受け付けて実行する．
  -- debugger: デバッガ
  function m:doCommand(debugger)
    debugger.writer:write('LUPE>')
    local line = io.read()
    for _, command_factory in pairs(self.command_factories) do
      local cmd = command_factory:createCommand(line)
      if cmd then
        return cmd(debugger)
      end
    end

    return true
  end

  return m
end
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
--- wrapper.lua

--- assertが呼ばれたら停止する
local _assert = assert
assert = function(...)
  local args = {...}
  if not args[1] then
    local debugger = rawget(_G, 'Lupe')
    debugger.writer:writeln('====== STOP BY ASSERT ======')
    debugger:traceback(args[2])
    local debug_info = debug.getinfo(2)
    local var_infoes = VarInfo.getlocal(2)
    local context = Context.create(debug_info, var_infoes)
    if not debugger.call_stack[1] then
      debugger.call_stack[1] = context
    else
      debugger.call_stack[1]:update(context)
    end
    debugger:showPrompt(debugger.call_stack[1])
    _assert(...)
  end
end
