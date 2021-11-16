require "org/jeff/luatools/CodeCoverage"
require "test/simple/module_file"


function main()
    print("adasds")
    ModuleTest.add(3,2)
    ModuleTest.NarcLNum()
end

Jeff_CodeCoverage.StartHook(Jeff_CodeCoverage.FUNC_COVERAGE_MODE, true)
main()
Jeff_CodeCoverage.StopHook()