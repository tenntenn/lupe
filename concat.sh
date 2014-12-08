#!/bin/sh

pushd `dirname $0` > /dev/null

echo "-- LUPE" > HEADER
echo "-- built at `date '+%Y-%m-%d %H:%M:%S'`" >> HEADER
echo "-- Author: Takuya Ueda" >> HEADER
echo >> HEADER

cat \
    HEADER\
    src/utils.lua\
    src/json.lua\
    src/reader.lua\
    src/writer.lua\
    src/var_info.lua\
    src/context.lua\
    src/profiler.lua\
    src/evaluator.lua\
    src/break_point.lua\
    src/break_point_manager.lua\
    src/step_execute_manager.lua\
    src/watch_manager.lua\
    src/command_factory/*.lua\
    src/prompt.lua\
    src/coroutine_debugger.lua\
    src/lupe.lua\
    src/wrapper.lua\
> lupe.lua

popd > /dev/null
