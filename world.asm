world .namespace 

WORLD_0_ADDR = $10000
WORLD_1_ADDR = WORLD_0_ADDR + 8192

WORLD_WINDOW = $8000
WORLD_8K_BLOCK = WORLD_WINDOW / 8192
WORLD_MMU_ADDR = WORLD_8K_BLOCK + 8

WORLD_0_BLOCK = WORLD_0_ADDR / 8192
WORLD_1_BLOCK = WORLD_0_BLOCK + 1


init
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
    pla
    rts


setWorld1
    pha
    lda #WORLD_1_BLOCK
    sta WORLD_MMU_ADDR
    pla
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


calcOneRound
    rts


draw
    rts


.endnamespace