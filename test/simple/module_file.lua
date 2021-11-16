--module("ModuleTest", package.seeall)
ModuleTest = ModuleTest or {}

function ModuleTest.check(ia)
    return nil
end

function ModuleTest.add(ia , ib)
    local b = ModuleTest.check(ia)
    if ia > ib or b then 
        return ia + ib
    end
    return ib + ia
end

function ModuleTest.powVal(a, b, c)
    return a*a*a + b*b*b + c*c*c
end

function ModuleTest.NarcLNum()
    for i=100, 999 do
        bi = math.floor(i / 100)
	    si = math.floor(i / 10) % 10
        gi = i % 10
        v = ModuleTest.powVal(bi, si, gi)
	    if v == i then
		    print(i)
        end
    end
end