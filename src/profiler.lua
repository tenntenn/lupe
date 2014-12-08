--- profiler.lua

--- プロファイルを行うクラス．
local Profiler = {}

--- Profilerを作る．
-- callback: 記録されるたびに呼ばれるコールバック
function Profiler.create(callback)

  local m = {
    profiles = {},
    callback = callback or function() end,
  }

  --- 関数ごとのIDを生成する．
  -- context: 元にするコンテキスト
  function m:id(context)
    local name   = context.name or 'NO_NAME'
    local source = utils:withoutPrefixSource(context.source)
    local line   = context.linedefined
    return string.format('%s(%s:%d)<%s>', name, source, line, tostring(context.func))
  end

  --- プロファイルを記録する．
  -- context: 記録する情報
  function m:record(context)
    local duration_ms, use_memory_kB = context:record()
    local id = self:id(context)
    if not self.profiles[id] then
      self.profiles[id] = {}
    end
    local profile = {
      duration_ms   = duration_ms,
      use_memory_kB = use_memory_kB,
    }
    table.insert(self.profiles[id], profile)
    self.callback(profile, self.profiles)
  end

  --- 集計を行う．
  -- 各関数ごと経過時間（平均と合計），使用メモリ（平均と合計），呼び出し回数
  function m:summary()
    local summary = {}

    for id, func_profiles in pairs(self.profiles) do
      local sum = {
        duration_ms   = 0,
        use_memory_kB = 0.0
      }
      for _, profile in ipairs(func_profiles) do
        sum.duration_ms   = sum.duration_ms + profile.duration_ms
        sum.use_memory_kB = sum.use_memory_kB + profile.use_memory_kB
      end

      local average = {
        duration_ms   = sum.duration_ms / math.max(#func_profiles, 1),
        use_memory_kB = sum.use_memory_kB / math.max(#func_profiles, 1),
      }
      summary[id] = {
        sum     = sum,
        average = average,
        count   = #func_profiles,
      }
    end

    return summary
  end

  return m
end
