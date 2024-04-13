* = $0800
.cpu "w65c02"

jmp main

.include "api.asm"
.include "clut.asm"
.include "zeropage.asm"
.include "arith16.asm"
.include "khelp.asm"
.include "hires_base.asm"
.include "random.asm"
.include "txtio.asm"


main
    ; setup MMU, this seems to be neccessary when running as a PGX
    lda #%10110011                         ; set active and edit LUT to three and allow editing
    sta 0
    lda #%00000000                         ; enable io pages and set active page to 0
    sta 1

    ; map BASIC ROM out and RAM in
    lda #4
    sta 8+4
    lda #5
    sta 8+5

    ; make sure whe receive kernel events
    jsr initEvents

    jsr hires.init
    jsr random.init
    jsr clut.init
    jsr txtio.init

    #setCol $10
    jsr txtio.clear
    jsr txtio.home

    lda #GFX_BLUE
    sta hires.backgroundColor    
    jsr hires.setLayer0
    
    #printString MSG1, len(MSG1)
    jsr waitForKey

    jsr hires.clearBitmap

    #printString MSG2, len(MSG2)
    jsr waitForKey

    lda #GFX_GREEN
    sta hires.backgroundColor
    jsr hires.setLayer1

    #printString MSG3, len(MSG3)
    jsr waitForKey

    jsr hires.clearBitmap

    #printString MSG4, len(MSG4)
    jsr waitForKey

    jsr hires.Off
    
    jsr sys64738

    ; we never get here I guess ....
    rts


MSG1 .text "Layer 0: Press any key to clear", $0d
MSG2 .text "Layer 0: Press any key to switch to layer 1", $0d
MSG3 .text "Layer 1: Press any key to clear", $0d
MSG4 .text "Layer 1: Press any key to end", $0d
