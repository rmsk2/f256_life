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
.include "world.asm"


main
    ; setup MMU, this seems to be neccessary when running as a PGZ
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
