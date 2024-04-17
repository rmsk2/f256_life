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

FIRST_CALL .byte 0

test    
    lda FIRST_CALL
    bne _notFirst
    jsr mmuSetup
    jsr world.init
    jsr world.setLinePtrs
    inc FIRST_CALL
    brk
_notFirst    
    jsr world.updateLinePtrs
    brk