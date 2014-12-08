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
