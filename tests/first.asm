*=$0800
.cpu "w65c02"

jmp test

.include "tests/mmu_setup.asm"
.include "arith16.asm"
.include "zeropage.asm"
.include "world.asm"

test
    jsr mmuSetup

    jsr world.init
    brk