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
    jsr hires.setLayer0Addr
    jsr hires.clearBitmap
    jsr hires.setLayer1Addr
    jsr hires.clearBitmap    

    jsr world.fill
    jsr hires.setLayer0Addr
    jsr world.drawPic
    jsr hires.setLayer0
    jsr waitForKey

_doCalc
    jsr world.calcOneRound
    bcs _done
    jsr world.draw
    bra _doCalc
_done
    jsr hires.Off
    
    jsr sys64738

    ; we never get here I guess ....
    rts

