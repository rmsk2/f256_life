require (test_dir.."trap")
require (test_dir.."life")

iterations = -1
line_table = {}

function num_iterations()
    return 64
end

function arrange()
    iterations = iterations + 1
    set_pc(load_address)
end

function assert()
    local u, c, l 
    u = de_ref(0x9D)
    c = de_ref(0x9F)
    l = de_ref(0xA1)

    res = line_table[iterations][1] == u
    res = res and line_table[iterations][2] == c
    res = res and line_table[iterations][3] == l

    return res, "Line pointer does not match"
end

function init_torus()
    local upper = 0x8000 + 8192 -128
    local line = 0x8000
    local lower = 0x8000 + 128

    for i = 0, 63, 1 do
        line_table[i] = {upper, line, lower}
        upper = upper + 128
        if upper >= 0xA000 then
            upper = 0x8000
        end

        lower = lower + 128
        if lower >= 0xA000 then
            lower = 0x8000
        end

        line = line + 128
    end
end

init_torus()