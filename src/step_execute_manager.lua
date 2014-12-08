--- step_execute_manager.lua

local StepExecuteManager = {
  MODE_STEP_OVER = 0,
  MODE_STEP_IN   = 1,
  MODE_STEP_OUT  = 2,
}

function StepExecuteManager.create()
  local m = {
    mode       = nil,
    call_stack = nil,
    count      = 0,
  }

  --- ステップオーバーを設定する．
  -- call_stack: コールスタック
  -- count: 実行するステップ数
  function m:setStepOver(call_stack, count)
    self.mode       = StepExecuteManager.MODE_STEP_OVER
    self.call_stack = utils:tableCopy(call_stack)
    self.count      = count
  end

  --- ステップインを設定する．
  -- call_stack: コールスタック
  -- count: 実行するステップ数
  function m:setStepIn(call_stack, count)
    self.mode       = StepExecuteManager.MODE_STEP_IN
    self.call_stack = utils:tableCopy(call_stack)
    self.count      = count
  end

  --- ステップアウトを設定する．
  -- call_stack: コールスタック
  -- count: 実行するステップ数
  function m:setStepOut(call_stack, count)
    self.mode       = StepExecuteManager.MODE_STEP_OUT
    self.call_stack = utils:tableCopy(call_stack)
    self.count      = count
  end

  --- ステップ実行をやめる．
  function m:clear()
    self.mode       = nil
    self.call_stack = nil
    self.count      = 0
  end

  --- 停止すべきか取得する．
  -- call_stack: コールスタック
  function m:shouldStop(call_stack)
    if not self.mode then
      return false
    end

    if self.mode == StepExecuteManager.MODE_STEP_OVER then
      return self:shouldStopStepOver(call_stack)
    end

    if self.mode == StepExecuteManager.MODE_STEP_IN then
      return self:shouldStopStepIn(call_stack)
    end

    if self.mode == StepExecuteManager.MODE_STEP_OUT then
      return self:shouldStopStepOut(call_stack)
    end
  end

  --- ステップオーバーで停止すべきか取得する．
  -- call_stack: コールスタック
  function m:shouldStopStepOver(call_stack)
    if #call_stack <= 0 or
       #self.call_stack <= 0 or
       utils:getLevelByFunc(self.call_stack, call_stack[1]) >= 1 then
      self.count = self.count - 1
      return self.count <= 0
    end
    return false
  end

  --- ステップインで停止すべきか取得する．
  -- call_stack: コールスタック
  function m:shouldStopStepIn(call_stack)
    self.count = self.count - 1
    return self.count <= 0
  end

  --- ステップアウトで停止すべきか取得する．
  -- call_stack: コールスタック
  function m:shouldStopStepOut(call_stack)
    if #call_stack <= 0 or
       #self.call_stack <= 0 or
       utils:getLevelByFunc(self.call_stack, call_stack[1]) > 1 then
      self.count = self.count - 1
      return self.count <= 0
    end
    return false
  end

  return m
end
