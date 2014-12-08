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
