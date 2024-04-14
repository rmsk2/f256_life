
function arrange()
    for i = 0x10000, 0x13fff, 1 do
        write_byte_long(i, 42)
    end
end

function assert()
    local sum = 0

    for i = 0x10000, 0x13fff, 1 do
        sum = sum + read_byte_long(i)
    end
    
    return sum == 0, string.format("Not cleared: %d", sum)
end