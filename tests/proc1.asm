*=$0800
.cpu "w65c02"

jmp test

.include "tests/test_global.asm"
.include "setup.asm"
.include "arith16.asm"
.include "zeropage.asm"
.include "tests/rand_test.asm"
.include "world.asm"

test
    jsr mmuSetup
    jsr world.setWorld0
    ;#TRAP TRAP_PRINT_0
    jsr world.calcOneRound
    ;#TRAP TRAP_PRINT_1
    brk