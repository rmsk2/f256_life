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
    jsr world.init
    jsr world.fill
    ; print world 0
    #TRAP 1
    brk