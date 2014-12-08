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
