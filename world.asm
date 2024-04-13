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
    jsr clearWorld
    jsr setWorld1
    jsr clearWorld
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


clearWorld
    #load16BitImmediate WORLD_WINDOW, WORLD_PTR
    ldx #0
_nextBlock
    ldy #0
    lda #0
_loopBlock
    sta (WORLD_PTR), Y
    iny
    bne _loopBlock
    inc WORLD_PTR+1
    inx
    cpx #32
    bne _nextBlock
    rts

.endnamespace