function count_non_zero(start, end_addr)
    local cells_alive = 0
    
    for i = start, end_addr, 1 do

        data = read_byte_long(i)

        if data ~= 0 then
            cells_alive = cells_alive + 1
        end
    end
    
    return cells_alive
end

function clear(base)
    for i = base, base + 8191, 1 do
        write_byte_long(i, 0)
    end
end

function set_cell(base, x, y, value)
    addr = base + 128 * y + x
    write_byte_long(addr, value)
end

function get_cell(base, x, y)
    addr = base + 128 * y + x

    return read_byte_long(addr)
end

base_0 = 0x10000
base_1 = 0x12000