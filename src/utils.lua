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
