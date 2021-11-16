--[[
 作者：覃贵锋
 日期：2021/11/16
 用于统计项目Lua代码执行覆盖的情况
 函数覆盖率
 条件覆盖率
 行覆盖率
 工具将分为两块:
    第一部分就是此文件，引入到被测项目代码中，并通过接口调用。  
       1. require 此文件
       2. 执行Jeff_CodeCoverage.StartHook开启统计
       3. 执行Jeff_CodeCoverage.StopHook结束统计，并输出行模式和函数模式下的数据到文件中。
    第二部分则是将此文件输出的文本内容与项目代码进行计算，最终获得覆盖率。
       1. 将项目代码扫描进入内存，并统计出函数或行的总数
       2. 分析第一部分输出的文件中的内容，统计出覆盖的数据 
            -- 这里不能简单统计，还需要对代码的逻辑有一定的处理，否则数据会有很大的误差。
       3. 通过已覆盖数据和总数据得到覆盖率
TODO 扩展部分（将整个代码执行的逻辑流记录下来，通过工具分析其执行情况）
--]]

-- 存在全局表中。
_G.Jeff_CodeCoverage = _G.Jeff_CodeCoverage or {}
-- 记录执行的情况
-- 一级key为文件路径
-- 二级key为行 即 [xxx.lua][line] = 1  初步计算了以下1000万行代码记录占用内存在几百兆，勉强可以接受，就简单这样搞。
Jeff_CodeCoverage.code = Jeff_CodeCoverage.code or {}
-- 行数覆盖记录
Jeff_CodeCoverage.LINE_COVERAGE_MODE = 1
-- 函数覆盖记录
Jeff_CodeCoverage.FUNC_COVERAGE_MODE = 2

--[[统计代码行覆盖情况]]
Jeff_CodeCoverage.line_hook_func = function()
    local info = debug.getinfo(2, "nlS")
    if not info then
        print("[ERROR] line_hook_func debug.getinfo get nil")
        return
    end
    local filename = info.short_src
    local linenum = info.currentline
    -- 过滤掉C层调用 -1 还有 require 0调用
    if linenum <= 0 then return end
    -- 非执行流情况下将数据记录到全局表中，最后统一输出
    if not Jeff_CodeCoverage.isFlow then
        -- 文本行记录表
        local file_line_tb = Jeff_CodeCoverage.code[filename]
        if not file_line_tb then
            file_line_tb = {}
            Jeff_CodeCoverage.code[filename] = file_line_tb
        end
        -- 当前行执行的次数
        file_line_tb[linenum] =  (file_line_tb[linenum] or 0) + 1
        file_line_tb[info.linedefined] = 1
        file_line_tb[info.lastlinedefined] = 1
    else
        -- 否则按照小时将数据写入日志
        local save_file = string.format("%s.luacoverage.txt", os.date("%Y_%m_%d_%H", os.time()))
        if not Jeff_CodeCoverage.lastFpName or Jeff_CodeCoverage.lastFpName ~= save_file then
            if Jeff_CodeCoverage.saveFp then
                Jeff_CodeCoverage.saveFp:close()
            end
            Jeff_CodeCoverage.saveFp = io.open(save_file, "w")
            Jeff_CodeCoverage.lastFpName = save_file
        end
        local info = string.format("%s:%s\n", filename, linenum)
        Jeff_CodeCoverage.saveFp:write(info)
    end
end

--[[统计覆盖的函数情况]]
Jeff_CodeCoverage.call_hook_func = function()
    local info = debug.getinfo(2, "nlS")
    if not info then
        print("[ERROR] call_hook_func debug.getinfo get nil")
        return
    end
    local filename = info.short_src
    local linenum = info.currentline
    local func = info.name   -- 函数名
    -- 过滤掉C层调用
    if linenum <= 0 then return end
    -- 非函数流情况
    if not Jeff_CodeCoverage.isFlow then
        -- 文本函数记录表
        local file_line_tb = Jeff_CodeCoverage.code[filename]
        if not file_line_tb then
            file_line_tb = {}
            Jeff_CodeCoverage.code[filename] = file_line_tb
        end
        local func_info = file_line_tb[linenum]
        if not func_info then
            func_info = {[0]=0, [1]=func}
            file_line_tb[linenum] = func_info
        end
        func_info[0] = (func_info[0] or 0) + 1
    else
        local save_file = string.format("%s.luacoverage.txt", os.date("%Y_%m_%d_%H", os.time()))
        if not Jeff_CodeCoverage.lastFpName or Jeff_CodeCoverage.lastFpName ~= save_file then
            if Jeff_CodeCoverage.saveFp then
                Jeff_CodeCoverage.saveFp:close()
            end
            Jeff_CodeCoverage.saveFp = io.open(save_file, "w")
            Jeff_CodeCoverage.lastFpName = save_file
        end
        local info = string.format("%s:%s:%s\n", filename, linenum, func)
        Jeff_CodeCoverage.saveFp:write(info)
    end
end

--[[ 输出覆盖的代码日志 ]]
Jeff_CodeCoverage.output_data = function()
    local save_file = string.format("%s.luacoverage.txt", os.date("%Y_%m_%d_%H_%M_%S", os.time()))
    local fp = io.open(save_file, "w")
    for k, v in pairs(Jeff_CodeCoverage.code) do
        for line, n in pairs(v) do
            if Jeff_CodeCoverage.runMode == Jeff_CodeCoverage.LINE_COVERAGE_MODE then
                fp:write(string.format("%s:%s:%s\n", k, line, n))
            elseif Jeff_CodeCoverage.runMode == Jeff_CodeCoverage.FUNC_COVERAGE_MODE then
                fp:write(string.format("%s:%s:%s:%s\n", k, line, n[0], n[1]))
            end
        end
    end
    fp:close()
    Jeff_CodeCoverage.code = {}
end

--[[ 设置hook模式 ]]
function Jeff_CodeCoverage.StartHook(mode, flow)
    if Jeff_CodeCoverage.isRunning then return end
    Jeff_CodeCoverage.isRunning = true  -- 防止重复设置
    Jeff_CodeCoverage.runMode = mode    -- hook的模式（行或者函数）
    Jeff_CodeCoverage.isFlow = flow     -- 是否开启执行流记录,执行流会实时将数据写入日志，并按小时存放
    if mode == Jeff_CodeCoverage.LINE_COVERAGE_MODE then
        print("[DEBUG] debug.sethook line")
        debug.sethook(Jeff_CodeCoverage.line_hook_func, "l")
    elseif mode == Jeff_CodeCoverage.FUNC_COVERAGE_MODE then
        print("[DEBUG] debug.sethook call")
        debug.sethook(Jeff_CodeCoverage.call_hook_func, "c")
    else
        return
    end
end

--[[ 停止hook ]]
function Jeff_CodeCoverage.StopHook()
    Jeff_CodeCoverage.isRunning = nil
    debug.sethook()
    -- 统计执行流的情况下不需要输出日志，因为已经实时输出。
    if not Jeff_CodeCoverage.isFlow then
        Jeff_CodeCoverage.output_data()
    else
        if Jeff_CodeCoverage.saveFp then
            Jeff_CodeCoverage.saveFp:close()
        end
    end
end