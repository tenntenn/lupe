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
