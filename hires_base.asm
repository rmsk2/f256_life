hires .namespace

MMU_IO_CTRL = $0001
VKY_MSTR_CTRL_0 = $D000
VKY_MSTR_CTRL_1 = $D001

LAYER_REG1 = $D002
LAYER_REG2 = $D003

BITMAP_0_ENABLE = $D100
BITMAP_0_ADDR_LOW = $D101
BITMAP_0_ADDR_MDL = $D102
BITMAP_0_ADDR_HI = $D103

BITMAP_1_ENABLE = $D108
BITMAP_1_ADDR_LOW = $D109
BITMAP_1_ADDR_MDL = $D10A
BITMAP_1_ADDR_HI = $D10B

BITMAP_2_ENABLE = $D110

BITMAP_0_MEM = $40000
BITMAP_1_MEM = $20000
BITMAP_WINDOW = $A000

WINDOW_8K_BLOCK = BITMAP_WINDOW / 8192
WINDOW_MMU_ADDR = WINDOW_8K_BLOCK + 8

; Change to $DE04 when building for a F256 Jr. Rev B using factory settings
MUL_RES_CO_PROC = $DE10

BIT_TEXT = 1
BIT_OVERLY = 2
BIT_GRAPH = 4
BIT_BITMAP = 8
BIT_TILE = 16
BIT_SPRITE = 32
BIT_GAMMA = 64
BIT_X = 128

BIT_CLK_70 = 1
BIT_DBL_X = 2
BIT_DBL_Y = 4
BIT_MON_SLP = 8 
BIT_FON_OVLY = 16
BIT_FON_SET = 32

LAYER_0_BITMAP_0 = %00000000
LAYER_1_BITMAP_1 = %00010000

init
    #saveIo
    #setIo 0

    ; setup layers, we want bitmap 0 in layer 0 and bitmap 1 in layer 1
    lda #LAYER_0_BITMAP_0 | LAYER_1_BITMAP_1
    sta LAYER_REG1  

    ; Explicitly disable all bitmaps for the moment
    stz BITMAP_0_ENABLE
    stz BITMAP_1_ENABLE
    stz BITMAP_2_ENABLE

    ; set address of bitmap 0 memory, i.e $40000
    lda #<BITMAP_0_MEM
    sta BITMAP_0_ADDR_LOW
    lda #>BITMAP_0_MEM
    sta BITMAP_0_ADDR_MDL
    lda #`BITMAP_0_MEM
    sta BITMAP_0_ADDR_HI

    ; set address of bitmap 0 memory, i.e $20000
    lda #<BITMAP_1_MEM
    sta BITMAP_1_ADDR_LOW
    lda #>BITMAP_1_MEM
    sta BITMAP_1_ADDR_MDL
    lda #`BITMAP_1_MEM
    sta BITMAP_1_ADDR_HI

    ; turn on graphics mode on and allow for displaying bitmap layers
    lda # BIT_BITMAP | BIT_GRAPH | BIT_OVERLY | BIT_TEXT
    sta VKY_MSTR_CTRL_0
    stz VKY_MSTR_CTRL_1
    #restoreIo

    rts


LINE_NO = 261*2  ; 240+21

checkVBlank
    lda #<LINE_NO
    ldx #>LINE_NO
_wait1
    cpx $D01B
    beq _wait1
_wait2
    cmp $D01A
    beq _wait2
_wait3
    cpx $D01B
    bne _wait3
_wait4
    cmp $D01A
    bne _wait4
    rts


setLayer0
    #saveIo
    #setIo 0

    jsr checkVBlank

    lda #0
    sta BITMAP_1_ENABLE
    lda #1
    sta BITMAP_0_ENABLE

    lda #BITMAP_0_MEM/8192
    sta HIRES_BASE_PAGE

    #restoreIo
    rts


setLayer0Addr
    lda #BITMAP_0_MEM/8192
    sta HIRES_BASE_PAGE
    rts


setLayer1Addr
    lda #BITMAP_1_MEM/8192
    sta HIRES_BASE_PAGE
    rts


setLayer1
    #saveIo
    #setIo 0

    jsr checkVBlank

    lda #0
    sta BITMAP_0_ENABLE
    lda #1
    sta BITMAP_1_ENABLE

    lda #BITMAP_1_MEM/8192
    sta HIRES_BASE_PAGE

    #restoreIo
    rts

; --------------------------------------------------
; This routine turns the bitmap mode off again.
;--------------------------------------------------
Off
    lda #1
    sta VKY_MSTR_CTRL_0
    stz VKY_MSTR_CTRL_1
    rts


clearBitmap
    stz COUNT_WINDOWS
    lda COUNT_WINDOWS
_nextWindow
    jsr setBitmapWindow
    lda #32
    sta MAX_256_BYTE_BLOCK
    jsr clearBitmapWindow
    inc COUNT_WINDOWS
    lda COUNT_WINDOWS
    cmp #9
    bne _nextWindow

    jsr setBitmapWindow

    lda #12
    sta MAX_256_BYTE_BLOCK
    jsr clearBitmapWindow

    jsr setCodeWindow

    rts


strSetPixelArgs .struct 
    x               .word 0
    y               .byte 0
    col             .byte 0
.endstruct


backgroundColor .byte 0
setPixelArgs .dstruct strSetPixelArgs


inc2 .macro memAddr2 
    clc
    ; add lo bytes
    lda #2
    adc \memAddr2
    sta \memAddr2
    lda \memAddr2+1
    adc #0
    sta \memAddr2+1
.endmacro


plot
    lda setPixelArgs.col
    sta (ZP_PLOT_PTR)

    #inc16bit ZP_PLOT_PTR
    lda ZP_PLOT_PTR+1
    and #%11011111                                                     ; overflow wrt to the window occurred, this only works in bank $A000
    bne _done
    lda ZP_PLOT_PTR+1
    ora #%00100000
    and #%10111111
    sta ZP_PLOT_PTR+1
    inc WINDOW_MMU_ADDR
_done
    rts


plot2
    lda setPixelArgs.col
    sta (ZP_PLOT_PTR)

    #inc2 ZP_PLOT_PTR
    lda ZP_PLOT_PTR+1
    and #%11011111                                                     ; overflow wrt to the window occurred, this only works in bank $A000
    bne _done
    lda ZP_PLOT_PTR+1
    ora #%00100000
    and #%10111111
    sta ZP_PLOT_PTR+1
    inc WINDOW_MMU_ADDR
_done
    rts


setAddress
    ; multiply 320 and y position
    ; multiplication result is stored at $DE04-$DE07
    lda setPixelArgs.y
    sta $DE00
    stz $DE01
    #load16BitImmediate 320, $DE02

    ; calculate (320 * YPOS) + XPOS    
    ; 24 bit result is in ZP_GRAPHIC_PTR GRAPHIC_ADDRESS GRAPHIC_ADDRESS+1
    clc
    lda MUL_RES_CO_PROC
    adc setPixelArgs.x
    sta ZP_PLOT_PTR
    lda MUL_RES_CO_PROC+1
    adc setPixelArgs.x+1
    sta GRAPHIC_ADDRESS
    lda #0
    adc MUL_RES_CO_PROC+2
    sta GRAPHIC_ADDRESS+1

    ; get address in 8K window => look at lower 13 bits
    ; caclulate ((320 * YPOS + XPOS) MOD 8192) + BITMAP_WINDOW
    lda GRAPHIC_ADDRESS
    and #%00011111
    clc 
    adc #>BITMAP_WINDOW
    sta ZP_PLOT_PTR+1

    ; determine 8K window to write to
    ; calculate (320 * YPOS + XPOS) DIV 8192
    ; get lower three bits 
    lda GRAPHIC_ADDRESS
    lsr
    lsr 
    lsr 
    lsr
    lsr 
    ; get most significant bit for bitmap window 
    ; GRAPHIC_ADDRESS+1 can either be zero or one
    ldy GRAPHIC_ADDRESS+1
    beq _writeColor
    ora #8
_writeColor    
    #setWindow
    rts


; --------------------------------------------------
; This routine sets a pixel in the bitmap using XPOS, YPOS and
; COLOR from above
;--------------------------------------------------
setPixel
    ; multiply 320 and y position
    ; multiplication result is stored at $DE04-$DE07
    lda setPixelArgs.y
    sta $DE00
    stz $DE01
    #load16BitImmediate 320, $DE02

    ; calculate (320 * YPOS) + XPOS    
    ; 24 bit result is in ZP_GRAPHIC_PTR GRAPHIC_ADDRESS GRAPHIC_ADDRESS+1
    clc
    lda MUL_RES_CO_PROC
    adc setPixelArgs.x
    sta ZP_GRAPHIC_PTR
    lda MUL_RES_CO_PROC+1
    adc setPixelArgs.x+1
    sta GRAPHIC_ADDRESS
    lda #0
    adc MUL_RES_CO_PROC+2
    sta GRAPHIC_ADDRESS+1

    ; get address in 8K window => look at lower 13 bits
    ; caclulate ((320 * YPOS + XPOS) MOD 8192) + BITMAP_WINDOW
    lda GRAPHIC_ADDRESS
    and #%00011111
    clc 
    adc #>BITMAP_WINDOW
    sta ZP_GRAPHIC_PTR+1

    ; determine 8K window to write to
    ; calculate (320 * YPOS + XPOS) DIV 8192
    ; get lower three bits 
    lda GRAPHIC_ADDRESS
    lsr
    lsr 
    lsr 
    lsr
    lsr 
    ; get most significant bit for bitmap window 
    ; GRAPHIC_ADDRESS+1 can either be zero or one
    ldy GRAPHIC_ADDRESS+1
    beq _writeColor
    ora #8
_writeColor    
    #setWindow
    ; set pixel
    lda setPixelArgs.col
    sta (ZP_GRAPHIC_PTR)

    rts


;------------------------------------------------------------------

setWindow .macro
    clc
    adc HIRES_BASE_PAGE
    sta WINDOW_MMU_ADDR
.endmacro


setCodeWindow
    lda #WINDOW_8K_BLOCK
    sta WINDOW_MMU_ADDR
    rts


setBitmapWindow
    #setWindow
    rts


clearBitmapWindow
    #load16BitImmediate BITMAP_WINDOW, ZP_GRAPHIC_PTR
    ldx #0
_nextBlock
    ldy #0
    lda backgroundColor
_loopBlock
    sta (ZP_GRAPHIC_PTR), Y
    iny
    bne _loopBlock
    inc ZP_GRAPHIC_PTR+1
    inx
    cpx MAX_256_BYTE_BLOCK
    bne _nextBlock
    rts


COUNT_WINDOWS .byte 0
MAX_256_BYTE_BLOCK .byte 0
BMP_WIN .byte 0
GRAPHIC_ADDRESS .byte 0,0

.endnamespace