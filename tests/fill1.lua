require (test_dir.."trap")

function arrange()

end

function assert()
    res = (count_non_zero(0x10000, 0x11fff) ~= 0) and (count_non_zero(0x12000, 0x13fff) ~= 0)

    return res, ""
end