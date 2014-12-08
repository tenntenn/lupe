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
