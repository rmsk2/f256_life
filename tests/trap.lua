require("io")
require("math")

TRAP_TABLE = {}

function de_ref(ptr_addr)
    local hi_addr = read_byte(ptr_addr + 1)
    local lo_addr = read_byte(ptr_addr)
    
    return hi_addr * 256 + lo_addr
end


function trap(trap_code)
    trap_func = TRAP_TABLE[trap_code]

    if trap_func ~= nil then
        trap_func(trap_code)
    else
        error("Unknown trap")
    end
end


function cleanup()
end


function get_random()
    set_accu(math.random(0, 255))
    set_xreg(math.random(0, 255))
end


function print_world_0()
    print_world(0x10000, 0x11fff)
end


function print_world_1()
    print_world(0x12000, 0x13fff)
end


function print_world(start, end_addr)
    local col_count = 0
    local cells_alive = 0
    print()

    for i = start, end_addr, 1 do

        if col_count >= 128 then
            print()
            col_count = 0
        end

        data = read_byte_long(i)

        if data == 0 then
            io.write(".")
        else
            cells_alive = cells_alive + 1
            io.write("#")
        end

        col_count = col_count + 1
    end

    print()
    print(string.format("Cells alive: %d", cells_alive))
end


function count_non_zero(start, end_addr)
    local cells_alive = 0
    
    for i = start, end_addr, 1 do

        data = read_byte_long(i)

        if data ~= 0 then
            cells_alive = cells_alive + 1
        end
    end 
end


TRAP_TABLE[0] = get_random
TRAP_TABLE[1] = print_world_0
TRAP_TABLE[2] = print_world_1
