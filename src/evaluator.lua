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
