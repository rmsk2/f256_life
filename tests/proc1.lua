require (test_dir.."trap")
require (test_dir.."life")


function arrange()
    clear(base_0)
    clear(base_1)
    set_cell(base_0, 0, 0, 0)
    set_cell(base_0, 1, 0, 0)
    set_cell(base_0, 2, 0, 0)
    set_cell(base_0, 0, 1, 1)
    set_cell(base_0, 1, 1, 0)
    set_cell(base_0, 2, 1, 0)
    set_cell(base_0, 0, 2, 0)
    set_cell(base_0, 1, 2, 1)
    set_cell(base_0, 2, 2, 1)
end

function assert()
    res = (get_cell(base_1, 1, 1) == 1) and (get_cell(base_1, 1, 2) == 1)
    res = res and (count_non_zero(base_1, base_1 + 8191) == 2)
    return res, "Not expected pattern"
end