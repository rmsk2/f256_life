require (test_dir.."trap")
require (test_dir.."life")


function arrange()

end

function assert()
    addr = de_ref(0xAA)
    if addr ~= 0x6000 then
        return false, string.format("Wrong MMU value: %x", addr) 
    end

    mmu_byte = read_byte(8+3)
    res = (mmu_byte == 54)
    if not res then
        return false, string.format("Wrong address value: %d", mmu_byte)
    end

    return true, ""
end