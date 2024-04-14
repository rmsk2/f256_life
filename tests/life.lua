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