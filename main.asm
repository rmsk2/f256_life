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
.include "select.asm"
.include "glider_gun.asm"


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
    bra _restart


mainMenu
    #locate 12, 5
    #printString HEADER, len(HEADER)
    #locate 12, 6
    #printString HEADER_U, len(HEADER_U)
    #locate 10, 10
    #printString MENU1, len(MENU1)
    #locate 10, 14
    #printString MENU2, len(MENU2)
    #locate 10, 18
    #printString MENU3, len(MENU3)

    #locate 10, 22
    #printString MENU4, len(MENU4)
    #locate 10, 26
    #printString MENU5, len(MENU5)


    #locate 10, 30
    #printString END, len(END)

    #locate 4, 43
    #printString TXT_WIKI, len(TXT_WIKI)

    #locate 7, 45
    #printString TXT3, len(TXT3)

_wait
    jsr waitForKey
    cmp #$31
    bne _checkBig
    #load16BitImmediate world.drawPic, world.DRAW_VEC
    lda #1
    sta DO_RANDOM_FILL
    jsr performCalculation
    clc
    rts
_checkBig
    cmp #$32
    bne _checkManual
    #load16BitImmediate world.drawPic4x4, world.DRAW_VEC
    lda #1
    sta DO_RANDOM_FILL
    jsr performCalculation
    clc
    rts
_checkManual
    cmp #$33
    bne _checkDemoFast
    stz DO_RANDOM_FILL
    #load16BitImmediate select.printMessage, PRINT_TYPE_VEC
    jsr select.doSelect
    rts
_checkDemoFast
    cmp #$35
    bne _checkDemo
    stz DO_RANDOM_FILL
    #load16BitImmediate world.drawPic, world.DRAW_VEC
    #load16BitImmediate glidergun.printMessage, PRINT_TYPE_VEC
    jsr glidergun.init
    jsr performCalculation
    clc
    rts    
_checkDemo
    cmp #$34
    bne _checkStop
    stz DO_RANDOM_FILL
    #load16BitImmediate world.drawPic4x4, world.DRAW_VEC
    #load16BitImmediate glidergun.printMessage, PRINT_TYPE_VEC
    jsr glidergun.init
    jsr performCalculation
    clc
    rts
_checkStop
    cmp #3
    beq _doReset
    jmp _wait
_doReset
    jmp returnToBASIC
    rts


DO_RANDOM_FILL .byte 0


PRINT_TYPE_VEC .word 0
printCustomMessge
    jmp (PRINT_TYPE_VEC)


performCalculation
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
    lda DO_RANDOM_FILL
    bne _randText
    jsr printCustomMessge
    bra _continue
_randText
    #printString TXT1, len(TXT1)
_continue
    #locate 0, 44 
    #printString TXT2, len(TXT2)

    #locate 68,3
    #printString GEN_TXT, len(GEN_TXT)
    #locate 68,4
    #printString GENU_TXT, len(GENU_TXT)
    #locate 68, 5
    lda #36
    jsr txtio.charOut

    lda DO_RANDOM_FILL
    beq _noFill
    jsr world.fill
_noFill
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
    rts


GEN_TXT  .text "Generation"
GENU_TXT .text "=========="
HEADER   .text "Conway's game of life: A cellular automaton (1.7.2)"
HEADER_U .text "==================================================="
MENU1 .text "      1 : Random start configuration in fast mode"
MENU2 .text "      2 : Random start configuration in normal mode"
MENU3 .text "      3 : Select start configuration using the mouse"
MENU4 .text "      4 : Demo: Gosper's glider gun in normal mode"
MENU5 .text "      5 : Demo: Gosper's glider gun in fast mode"
END   .text "RUN/STOP: Reset to BASIC"
TXT1  .text "The start configuration was chosen at random with about 31% of living cells"
TXT2  .text "Press any key to return to main menu"
TXT3  .text "Find the source code at: https://github.com/rmsk2/f256_life"
TXT_WIKI  .text "Find more info at: https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life"

returnToBASIC    
    jsr sys64738

    ; we never get here I guess ....
    rts

