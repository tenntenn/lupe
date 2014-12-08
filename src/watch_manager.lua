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
