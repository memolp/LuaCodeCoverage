# LuaCodeCoverage
Lua 代码覆盖率运行时统计工具

### 使用方法
1. 导入模块
```lua
require "CodeCoverage" 
```
2. 执行Hook
```lua
-- Jeff_CodeCoverage.LINE_COVERAGE_MODE 行覆盖率统计
-- Jeff_CodeCoverage.FUNC_COVERAGE_MODE 函数覆盖率统计
-- StartHook 第二个参数设置为true将实时输出行或函数覆盖的执行流数据
Jeff_CodeCoverage.StartHook(Jeff_CodeCoverage.FUNC_COVERAGE_MODE)
```
3. 必要的时候调用停止结束统计
```lua
Jeff_CodeCoverage.StopHook()
```
4. 这样就会生成一个`xxx.luacoverage.txt`的统计文件。注意此文件仅记录了执行过的代码。
5. 通过写一个脚本工具获取总代码行数或者函数总数，然后通过已执行/总数得到覆盖率。
