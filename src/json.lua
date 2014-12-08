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
