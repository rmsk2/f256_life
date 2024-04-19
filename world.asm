world .namespace 

WORLD_0_ADDR = $10000
WORLD_1_ADDR = WORLD_0_ADDR + 8192

WORLD_WINDOW = $8000
WORLD_8K_BLOCK = WORLD_WINDOW / 8192
WORLD_MMU_ADDR = WORLD_8K_BLOCK + 8

UPPER_WINDOW = WORLD_WINDOW + 8192 - 128
LOWER_WINDOW = WORLD_WINDOW + 128

WORLD_0_BLOCK = WORLD_0_ADDR / 8192
WORLD_1_BLOCK = WORLD_0_BLOCK + 1


init
    stz HIRES_LAYER
    jsr setWorld0
    jsr clear
    jsr setWorld1
    jsr clear
    jsr setWorld0
    rts

setWorld0
    pha
    lda #WORLD_0_BLOCK
    sta WORLD_MMU_ADDR
    sta ACT_WORLD_BLOCK
    lda #WORLD_1_BLOCK
    sta ALT_WORLD_BLOCK    
    pla
    rts


setWorld1
    pha
    lda #WORLD_1_BLOCK
    sta WORLD_MMU_ADDR
    sta ACT_WORLD_BLOCK
    lda #WORLD_0_BLOCK
    sta ALT_WORLD_BLOCK
    pla
    rts


mmuAct .macro
    lda ACT_WORLD_BLOCK
    sta WORLD_MMU_ADDR
.endmacro


mmuAlt .macro
    lda ALT_WORLD_BLOCK
    sta WORLD_MMU_ADDR
.endmacro


switchBlocks
    ldx ACT_WORLD_BLOCK
    lda ALT_WORLD_BLOCK
    stx ALT_WORLD_BLOCK
    sta ACT_WORLD_BLOCK
    rts


clearByte
    lda #0
    sta (WORLD_PTR),y
    rts

clear
    #load16BitImmediate clearByte, PROC_VECTOR
    jmp iterateOverWorld


PROC_VECTOR .word ?
procCall
    jmp (PROC_VECTOR)

iterateOverWorld
    #load16BitImmediate WORLD_WINDOW, WORLD_PTR
    ldx #0
_nextBlock
    ldy #0
_loopBlock
    jsr procCall
    iny
    bne _loopBlock
    inc WORLD_PTR+1
    inx
    cpx #32
    bne _nextBlock
    rts

RAND_TEMP .word ?

fillCell
    phx
    phy
    jsr random.get
    stx RAND_TEMP
    sta RAND_TEMP+1
    #cmp16BitImmediate 20497, RAND_TEMP
    bcc _notSet
    lda #1
    bra _done
_notSet
    lda #0
_done
    ply
    plx
    sta (WORLD_PTR), y
    rts

fill
    #load16BitImmediate fillCell, PROC_VECTOR
    jmp iterateOverWorld


CANCEL_VECTOR .word checkKey

testInterrupt
    jmp (CANCEL_VECTOR)

dummyCancel
    clc
    rts


checkKey
    lda kernel.args.events.pending ; Negated count
    bpl _done
    jsr kernel.NextEvent
    bcs _done
    lda myEvent.type    
    cmp #kernel.event.key.PRESSED
    bne _done
    sec
    rts
_done
    clc
    rts


setLinePtrs
    #load16BitImmediate WORLD_WINDOW, LINE_PTR
    #load16BitImmediate UPPER_WINDOW, UPPER_PTR
    #load16BitImmediate LOWER_WINDOW, LOWER_PTR

    ldy #$7F
    lda #0
    clc
    adc (UPPER_PTR), y
    adc (LOWER_PTR), y
    adc (LINE_PTR), y
    sta LEFT_COUNT
    rts


updateLinePtrs
    #add16BitImmediate 128, UPPER_PTR
    lda UPPER_PTR+1
    cmp #$A0
    bne _checkLower
    ; wrap around of UPPER_PTR
    #load16BitImmediate WORLD_WINDOW, UPPER_PTR
_checkLower
    #add16BitImmediate 128, LOWER_PTR
    lda LOWER_PTR+1
    cmp #$A0
    bne _updateMain
    ; wrap around of LOWER
    #load16BitImmediate WORLD_WINDOW, LOWER_PTR
_updateMain
    #add16BitImmediate 128, LINE_PTR
    rts

TAB_ALIVE .byte 0, 0, 1, 1, 0, 0, 0, 0, 0
TAB_DEAD  .byte 0, 0, 0, 1, 0, 0, 0, 0, 0

mcalcOneCell .macro
    lda CTR_colCount
    ina
    and #$7F
    sta CTR_x_plus_1

    ; count living neighbours
    clc
    lda #0
    ldy CTR_colCount
    adc (UPPER_PTR), y
    adc (LOWER_PTR), y
    pha
    adc LEFT_COUNT
    ldy CTR_x_plus_1
    adc (UPPER_PTR), y
    adc (LOWER_PTR), y
    adc (LINE_PTR), y
    tax

    ldy CTR_colCount
    lda (LINE_PTR), y
    beq _currentlyDead
    pla
    ina
    sta LEFT_COUNT    
    #mmuAlt
    lda TAB_ALIVE, x
    sta (LINE_PTR), y
    #mmuAct
    bra _endCalcOne
_currentlyDead
    pla
    sta LEFT_COUNT
    #mmuAlt
    lda TAB_DEAD, x
    sta (LINE_PTR), y
    #mmuAct
_endCalcOne
.endmacro

calcOneCell
    #mcalcOneCell
    rts


calcOneRound
    stz CTR_lineCount
    stz CTR_colCount
    jsr setLinePtrs
_nextIteration
    lda CTR_lineCount
    cmp #64
    beq _done
_nextCol
    lda CTR_colCount
    cmp #128
    beq _nextLine
    #mcalcOneCell
    inc CTR_colCount
    bra _nextCol
_nextLine
    jsr testInterrupt
    bcs _done2
    stz CTR_colCount
    inc CTR_lineCount
    jsr updateLinePtrs
    jmp _nextIteration
_done
    jsr switchBlocks
    #mmuAct
    clc
_done2
    rts

HIRES_LAYER .byte 0


savePlotParams .macro ptr, bank
    #move16Bit ZP_PLOT_PTR, \ptr
    lda hires.WINDOW_MMU_ADDR
    sta \bank
.endmacro


calcPtrs
    stz hires.setPixelArgs.y
    jsr hires.setAddress
    #move16Bit ZP_PLOT_PTR, ZP_PLOT_PTR1

    #load16BitImmediate hires.ALT_BITMAP_WINDOW, ZP_PLOT_PTR3
    jsr hires.newLineAddr4x4_6000

    rts


update4x4Pointers    
    jsr hires.newLineAddrPartial4x4_A000
    jsr hires.newLineAddrPartial4x4_6000

    rts


drawPic4x4   
    stz CTR_lineCount
    #load16BitImmediate WORLD_WINDOW, LINE_PTR
    stz hires.setPixelArgs.x 
    stz hires.setPixelArgs.x+1   
    jsr calcPtrs
    ldy #0
_nextIteration
    lda CTR_lineCount
    cmp #64
    bne _nextCol
    jmp _doneDraw
_nextCol
    cpy #128
    bne _doDraw
    jmp _nextLine
_doDraw
    lda (LINE_PTR), y
    eor #3
    sta hires.setPixelArgs.col

    #mplot1
    #mplot1
    #mplot3
    #mplot3

    iny
    jmp _nextCol
_nextLine
    inc CTR_lineCount
    jsr update4x4Pointers
    ldy #0
    #add16BitImmediate 128, LINE_PTR
    jmp _nextIteration
_doneDraw
    rts


drawOnly
    jmp (DRAW_VEC)
DRAW_VEC .word drawPic4x4


drawPic    
    stz CTR_lineCount
    #load16BitImmediate WORLD_WINDOW, LINE_PTR    
    stz hires.setPixelArgs.x
    stz hires.setPixelArgs.x+1
    stz hires.setPixelArgs.y
    jsr hires.setAddress
    ldy #0
_nextIteration
    lda CTR_lineCount
    cmp #64
    beq _doneDraw
_nextCol
    cpy #128
    beq _nextLine

    lda (LINE_PTR), y
    eor #3
    #mplot_A000 ZP_PLOT_PTR
    iny
    bra _nextCol
_nextLine
    inc CTR_lineCount
    jsr hires.newLineAddrPartial
    ldy #0
    #add16BitImmediate 128, LINE_PTR
    jmp _nextIteration
_doneDraw
    rts


draw
    lda HIRES_LAYER
    eor #1
    sta HIRES_LAYER
    beq _l0
    jsr hires.setLayer1Addr
    bra _goon
_l0
    jsr hires.setLayer0Addr
_goon
    jsr drawOnly

    lda HIRES_LAYER
    beq _l0_2
    jsr hires.setLayer1
    rts
_l0_2
    jsr hires.setLayer0
    rts


.endnamespace