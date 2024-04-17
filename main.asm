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
    jsr txtio.cursorOff
_restart
    stz GENERATION
    stz GENERATION+1
    jsr world.init

    #setCol (TXT_BLUE << 4) | (TXT_WHITE)
    jsr txtio.clear
    jsr txtio.home

    jsr mainMenu
    jsr txtio.clear

    lda #GFX_WHITE
    sta hires.backgroundColor    
    jsr hires.setLayer0Addr
    jsr hires.clearBitmap
    jsr hires.setLayer1Addr
    jsr hires.clearBitmap    

    jsr txtio.clear

    #locate 15, 35
    #printString HEADER, len(HEADER)
    #locate 15, 36
    #printString HEADER_U, len(HEADER_U)
    #locate 0, 40
    #printString TXT1, len(TXT1)
    #locate 0, 44 
    #printString TXT2, len(TXT2)

    #locate 68,3
    #printString GEN_TXT, len(GEN_TXT)
    #locate 68,4
    #printString GENU_TXT, len(GENU_TXT)
    #locate 68, 5
    lda #36
    jsr txtio.charOut

    jsr world.fill
    jsr hires.setLayer0Addr
    jsr world.drawOnly
    jsr hires.setLayer0
    jsr hires.on
_doCalc
    jsr world.calcOneRound
    bcs _done
    jsr world.draw
    #inc16Bit GENERATION
    #locate 69,5
    lda GENERATION+1
    jsr txtio.printByte
    lda GENERATION
    jsr txtio.printByte
    bra _doCalc
_done
    jsr hires.Off
    jmp _restart


mainMenu
    #locate 15, 5
    #printString HEADER, len(HEADER)
    #locate 15, 6
    #printString HEADER_U, len(HEADER_U)
    #locate 10, 10
    #printString MENU1, len(MENU1)
    #locate 10, 14
    #printString MENU2, len(MENU2)
    #locate 10, 18
    #printString END, len(END)
    #locate 7, 45
    #printString TXT3, len(TXT3)

_wait
    jsr waitForKey
    cmp #$31
    bne _checkBig
    #load16BitImmediate world.drawPic, world.DRAW_VEC
    rts
_checkBig
    cmp #$32
    bne _checkStop
    #load16BitImmediate world.drawPic4x4, world.DRAW_VEC
    rts
_checkStop
    cmp #3
    bne _wait
    jmp returnToBASIC
    rts

GEN_TXT  .text "Generation"
GENU_TXT .text "=========="
HEADER   .text "Conway's game of life: A cellular automaton"
HEADER_U .text "==========================================="
MENU1 .text "      1 : Fast but small visualization"
MENU2 .text "      2 : Not so fast but bigger visualization"
END   .text "RUN/STOP: Reset to BASIC"
TXT1  .text "The start configuration is chosen at random with about 31% of living cells"
TXT2  .text "Press any key to return to main menu"
TXT3  .text "Find the source code at: https://github.com/rmsk2/f256_life"

returnToBASIC    
    jsr sys64738

    ; we never get here I guess ....
    rts

