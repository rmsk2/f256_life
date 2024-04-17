saveIo .macro
    lda $01
    pha
.endmacro

setIo .macro page
    lda #\page
    sta $01
.endmacro

restoreIo .macro
    pla
    sta $01
.endmacro

GFX_BLACK = 0
GFX_WHITE = 1
GFX_RED = 4
GFX_GREEN = 3
GFX_BLUE = 2

TXT_BLACK = 0
TXT_WHITE = 1
TXT_BLUE = 2

clut .namespace

TXT_LUT_FORE_GROUND_BASE = $D800
TXT_LUT_BACK_GROUND_BASE = $D840
GFX_LUT_BASE = $D000


setTxtColInt .macro colNum, red, green, blue, alpha
    lda #\blue
    sta TXT_LUT_FORE_GROUND_BASE + ((\colNum & 15) * 4)
    sta TXT_LUT_BACK_GROUND_BASE + ((\colNum & 15) * 4)
    lda #\green
    sta TXT_LUT_FORE_GROUND_BASE + ((\colNum & 15) * 4) + 1
    sta TXT_LUT_BACK_GROUND_BASE + ((\colNum & 15) * 4) + 1
    lda #\red
    sta TXT_LUT_FORE_GROUND_BASE + ((\colNum & 15) * 4) + 2
    sta TXT_LUT_BACK_GROUND_BASE + ((\colNum & 15) * 4) + 2
    lda #\alpha
    sta TXT_LUT_FORE_GROUND_BASE + ((\colNum & 15) * 4) + 3
    sta TXT_LUT_BACK_GROUND_BASE + ((\colNum & 15) * 4) + 3
.endmacro


setTxtCol .macro colNum, red, green, blue, alpha
    #saveIo
    #setIo 0
    #setTxtColInt \colNum, \red, \green, \blue, \alpha
    #restoreIo
.endmacro

setGfxColInt .macro colNum, red, green, blue, alpha
    lda #\blue
    sta GFX_LUT_BASE + (\colNum * 4)
    lda #\green
    sta GFX_LUT_BASE + (\colNum * 4) + 1
    lda #\red
    sta GFX_LUT_BASE + (\colNum * 4) + 2
    lda #\alpha
    sta GFX_LUT_BASE + (\colNum * 4) + 3
.endmacro

setGfxCol .macro colNum, red, green, blue, alpha
    #saveIo
    #setIo 1
    #setGfxColInt \colNum, \red, \green, \blue, \alpha
    #restoreIo
.endmacro

init
    #saveIo

    #setIo 1
    #setGfxColInt GFX_WHITE,  $FF, $FF, $FF, $FF
    #setGfxColInt GFX_BLUE,  $00, $00, $FF, $FF
    #setGfxColInt GFX_RED,  $FF, $00, $00, $FF
    #setGfxColInt GFX_GREEN,  $00, $FF, $00, $FF
    ; #setGfxColInt 5,  $01, $FF, $E4, $FF
    ; #setGfxColInt 6,  $01, $9D, $FF, $FF
    ; #setGfxColInt 7,  $05, $01, $FF, $FF
    ; #setGfxColInt 8,  $8B, $01, $FF, $FF
    ; #setGfxColInt 9,  $FF, $01, $F6, $FF
    ; #setGfxColInt 10, $FF, $01, $79, $FF
    ; #setGfxColInt 11, $FF, $FF, $FF, $FF
    ; #setGfxColInt 12, $ED, $FF, $01, $FF
    ; #setGfxColInt 13, $01, $FF, $C1, $FF
    
    #setIo 0
    #setTxtColInt TXT_BLACK,  $00, $00, $00, $FF
    #setTxtColInt TXT_WHITE,  $FF, $FF, $FF, $FF
    #setTxtColInt TXT_BLUE,  $00, $00, $FF, $FF
    ; #setTxtColInt 3,  $00, $CF, $00, $FF
    ; #setTxtColInt 4,  $00, $BF, $00, $FF
    ; #setTxtColInt 5,  $00, $AF, $00, $FF
    ; #setTxtColInt 6,  $00, $9F, $00, $FF
    ; #setTxtColInt 7,  $00, $8F, $00, $FF
    ; #setTxtColInt 8,  $00, $7F, $00, $FF
    ; #setTxtColInt 9,  $00, $6F, $00, $FF
    ; #setTxtColInt 10, $00, $5F, $00, $FF
    ; #setTxtColInt 11, $00, $4F, $00, $FF
    ; #setTxtColInt 12, $00, $3F, $00, $FF
    ; #setTxtColInt 13, $00, $2F, $00, $FF
    ; #setTxtColInt 14, $00, $1F, $00, $FF
    ; #setTxtColInt 15, $00, $0F, $00, $FF
    
    #restoreIo
    rts

.endnamespace