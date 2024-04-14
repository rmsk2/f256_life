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
    jsr setWorld0
    jsr clear
    jsr setWorld1
    jsr clear
    jsr setWorld0
    stz WORLD_NUMBER
    rts


setWorld0
    pha
    lda #WORLD_0_BLOCK
    sta WORLD_MMU_ADDR
    pla
    rts


setWorld1
    pha
    lda #WORLD_1_BLOCK
    sta WORLD_MMU_ADDR
    pla
    rts

WORLD_NUMBER .byte 0
WORLD_TABLE
.word setWorld0
.word setWorld1

worldFunc
    jmp (WORLD_TABLE, x)

setWorld
    pha
    phx
    lda WORLD_NUMBER
    asl
    tax
    jsr worldFunc
    plx
    pla
    rts


flipWorld
    pha
    lda WORLD_NUMBER
    eor #1
    sta WORLD_NUMBER
    pla
    jsr setWorld
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


setLinePtrs
    #load16BitImmediate WORLD_WINDOW, LINE_PTR
    #load16BitImmediate UPPER_WINDOW, UPPER_PTR
    #load16BitImmediate LOWER_WINDOW, LOWER_PTR
    rts


Counters_t .struct 
    lineCount .byte 0
    colCount  .byte 0
    sum       .byte 0
    x_minus_1 .byte 0
    x_plus_1  .byte 0
.endstruct

COUNTERS .dstruct Counters_t
CANCEL_VECTOR .word dummyCancel

testInterrupt
    jmp (CANCEL_VECTOR)

dummyCancel
    clc
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


calcOneCell
    stz COUNTERS.sum
    lda COUNTERS.colCount
    ina
    and #$7F
    sta COUNTERS.x_plus_1

    lda COUNTERS.colCount
    dea
    and #$7F
    sta COUNTERS.x_minus_1

    ; count living neighbours
    lda #0
    clc
    ldy COUNTERS.colCount
    adc (UPPER_PTR), y
    adc (LOWER_PTR), y
    ldy COUNTERS.x_minus_1
    adc (UPPER_PTR), y
    adc (LOWER_PTR), y
    adc (LINE_PTR), y
    ldy COUNTERS.x_plus_1
    adc (UPPER_PTR), y
    adc (LOWER_PTR), y
    adc (LINE_PTR), y
    sta COUNTERS.sum

    ldy COUNTERS.colCount
    lda (LINE_PTR), y
    beq _currentlyDead
    lda COUNTERS.sum
    cmp #2
    bcc _cellDies
    cmp #4
    bcc _cellLives
_cellDies
    lda #0
    jsr flipWorld
    sta (LINE_PTR), y
    bra _end
_currentlyDead
    lda COUNTERS.sum
    cmp #3
    beq _cellLives
    bra _cellDies
_cellLives
    lda #1
    jsr flipWorld
    sta (LINE_PTR), y
_end
    jsr flipWorld
    rts


calcOneRound
    stz COUNTERS.lineCount
    stz COUNTERS.colCount
    jsr setLinePtrs
_nextIteration
    lda COUNTERS.lineCount
    cmp #64
    beq _done
    lda COUNTERS.colCount
    cmp #128
    beq _nextLine
    jsr calcOneCell
    inc COUNTERS.colCount
    jmp _nextIteration
_nextLine
    jsr testInterrupt
    bcs _done
    stz COUNTERS.colCount
    inc COUNTERS.lineCount
    jsr updateLinePtrs
    jmp _nextIteration
_done
    jsr flipWorld
    rts


draw
    rts


.endnamespace