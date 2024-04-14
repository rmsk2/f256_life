* = $0800
.cpu "w65c02"

jmp main

.include "setup.asm"
.include "api.asm"
.include "clut.asm"
.include "zeropage.asm"
.include "arith16.asm"
.include "khelp.asm"
.include "hires_base.asm"
.include "random.asm"
.include "txtio.asm"
.include "world.asm"


main
    jsr mmuSetup
    ; make sure whe receive kernel events
    jsr initEvents

    jsr hires.init
    jsr random.init
    jsr clut.init
    jsr txtio.init
    jsr world.init

    #setCol (TXT_BLACK << 4) | (TXT_BLACK)
    jsr txtio.clear
    jsr txtio.home

    lda #GFX_WHITE
    sta hires.backgroundColor    
    jsr hires.setLayer0
    jsr hires.clearBitmap
    jsr hires.setLayer1
    jsr hires.clearBitmap    

    #printString MSG4, len(MSG4)
    jsr waitForKey

    jsr hires.Off
    
    jsr sys64738

    ; we never get here I guess ....
    rts


MSG4 .text "Press any key to end", $0d
