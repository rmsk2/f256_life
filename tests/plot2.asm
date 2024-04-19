*=$0800
.cpu "w65c02"

jmp test

.include "api.asm"
.include "khelp.asm"
.include "tests/test_global.asm"
.include "setup.asm"
.include "arith16.asm"
.include "zeropage.asm"
.include "tests/rand_test.asm"
.include "hires_base.asm"
.include "clut.asm"
.include "world.asm"

test
    jsr mmuSetup
    jsr hires.init
    jsr world.setWorld0
    lda #53
    sta 8+3
    #load16BitImmediate $7FFF, ZP_PLOT_PTR
    jsr hires.plot_6000
    brk