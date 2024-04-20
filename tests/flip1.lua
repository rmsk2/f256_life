require (test_dir.."trap")
require (test_dir.."life")


function arrange()

end

function assert()
    addr = de_ref(0x9f)
    if addr ~= 0x8000 + 17 * 128 + 83 then
        return false, string.format("Wrong address: %x", addr) 
    end

    if get_accu() ~= 1 then
        return false, string.format("Wrong cell state: %d", get_accu())
    end

    return true, ""
end