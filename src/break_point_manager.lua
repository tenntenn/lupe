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
