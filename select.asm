select .namespace

doSelect
    #setCol (TXT_BLUE << 4) | (TXT_WHITE)
    jsr txtio.clear
    jsr txtio.home
    jsr world.init
    jsr hires.setLayer0
    lda #GFX_WHITE
    sta hires.backgroundColor
    jsr hires.clearBitmap
    #load16BitImmediate world.drawPic4x4, world.DRAW_VEC    
    jsr world.drawOnly
    jsr hires.checkVBlank
    jsr hires.on
    jsr mouseOn
    lda BUTTON_IS_NOT_PRESSED
    sta BUTTON_STATE

    jsr eventLoop
    
    jsr hires.off
    jsr mouseOff
    sec
    rts

mouseOn
    #saveIo
    #setIo 0
    lda #1
    sta $D6E0
    stz $D6E2
    stz $D6E3
    stz $D6E4
    stz $D6E5
    #restoreIo
    rts

mouseOff
    #saveIo
    #setIo 0
    lda #0
    sta $D6E0
    #restoreIo
    rts


eventLoop
    ; Peek at the queue to see if anything is pending
    lda kernel.args.events.pending ; Negated count
    bpl eventLoop
    ; Get the next event.
    jsr kernel.NextEvent
    bcs eventLoop
    ; Handle the event
    lda myEvent.type    
    cmp #kernel.event.key.PRESSED
    bne _checkMouseEvent
    jsr procKeyPressed
    bcc eventLoop
    rts
_checkMouseEvent
    cmp #kernel.event.mouse.DELTA
    bne _nextEventCheck    
    jsr procMouseEvent
    bra eventLoop
_nextEventCheck
    bra eventLoop


procKeyPressed
    lda myEvent.key.flags 
    and #myEvent.key.META
    beq _isAscii
    lda myEvent.key.raw                                     ; retrieve raw key code
    jsr testForFKey
    bcs _procPress                                           ; a meta key but not an F-Key was pressed => we are not done
    rts
_isAscii
    lda myEvent.key.ascii
_procPress
    sec
_done
    rts


procMouseEvent
    #saveIo
    #setIo 0
    jsr mouseClick
    jsr mouseLeftRight
    jsr mouseUpDown
    #restoreIo
    rts


X_MAX = 512
Y_MAX = 256

DIR_LEFT = 0
DIR_RIGHT = 1
DIR_UP = 0
DIR_DOWN = 1

SPEED_SLOW = 0
SPEED_FAST = 1

LEFT_BUTTON = 1
RIGHT_BUTTON = 2

BUTTON_IS_PRESSED = 1
BUTTON_IS_NOT_PRESSED = 0

DIRECTION      .byte 0
SPEED          .byte 0
OFFSET         .byte 0, 0
PRIMARY_BUTTON .byte LEFT_BUTTON
BUTTON_STATE   .byte 0

THRESHOLD_X .byte 5
OFFSET_SLOW_X .byte 1
OFFSET_FAST_X .byte 10

THRESHOLD_Y .byte 4
OFFSET_SLOW_Y .byte 1
OFFSET_FAST_Y .byte 10


evalMouseOffset .macro dirPlus, dirMinus, deltaAddr, theresholdAddr, offsetSlowAddr, offsetFastAddr
    lda \deltaAddr
    bmi _minus
    lda #\dirPlus
    sta DIRECTION
    lda \deltaAddr
    bra _speedCheck
_minus
    lda #\dirMinus
    sta DIRECTION
    ; reverse two's complement
    lda \deltaAddr
    eor #$FF
    clc
    adc #1
_speedCheck
    cmp \theresholdAddr
    bcc _speedSlow
    lda #SPEED_FAST
    sta SPEED
    bra _finished
_speedSlow
    lda #SPEED_SLOW
    sta SPEED
_finished
    lda \offsetSlowAddr
    sta OFFSET    
    lda SPEED
    cmp #SPEED_SLOW
    beq _offsetDone
    lda \offsetFastAddr
    sta OFFSET
_offsetDone

.endmacro

POS_TEMP       .word 0
PIXEL_COLS     .byte GFX_GREEN, GFX_BLUE

drawPixel
    #move16Bit $D6E2, POS_TEMP
    #halve16Bit POS_TEMP
    #halve16Bit POS_TEMP
    lda POS_TEMP
    sta world.COORD.x

    #move16Bit $D6E4, POS_TEMP
    #halve16Bit POS_TEMP
    #halve16Bit POS_TEMP
    lda POS_TEMP
    sta world.COORD.y
    
    jsr world.flipCell
    tax
    lda PIXEL_COLS, x
    sta hires.setPixelArgs.col
    
    #move16Bit $D6E2, POS_TEMP
    #halve16Bit POS_TEMP
    #move16Bit POS_TEMP, hires.setPixelArgs.x
    #move16Bit $D6E4, POS_TEMP
    #halve16Bit POS_TEMP
    lda POS_TEMP
    sta hires.setPixelArgs.y
    jsr drawPixel
    
    inc hires.setPixelArgs.x
    jsr drawPixel
    
    inc hires.SetPixelArgs.y
    jsr drawPixel

    dec hires.setPixelArgs.x
    jsr drawPixel

    rts


mouseLeftRight
    lda myEvent.mouse.delta.x
    bne _doEval
    jmp _done
_doEval
    #evalMouseOffset DIR_RIGHT, DIR_LEFT, myEvent.mouse.delta.x, THRESHOLD_X, OFFSET_SLOW_X, OFFSET_FAST_X
    lda DIRECTION
    cmp #DIR_RIGHT
    beq _right
_left
    #move16Bit $D6E2, POS_TEMP
    #sub16Bit OFFSET, POS_TEMP
    lda POS_TEMP+1
    bmi _setXPos0
    #move16Bit POS_TEMP, $D6E2
    bra _done
_setXPos0
    #load16BitImmediate 0, $D6E2
    bra _done
_right
    #move16Bit $D6E2, POS_TEMP
    #add16Bit OFFSET, POS_TEMP
    #cmp16BitImmediate X_MAX-1, POS_TEMP
    bcc _setXPosMax
    #move16Bit POS_TEMP, $D6E2
    bra _done
_setXPosMax
    #load16BitImmediate X_MAX-1, $D6E2
_done
    lda BUTTON_STATE
    cmp #BUTTON_IS_NOT_PRESSED
    beq _return
    jsr drawPixel
_return
    rts


mouseUpDown 
    lda myEvent.mouse.delta.y
    bne _doEval
    jmp _done
_doEval
    #evalMouseOffset DIR_DOWN, DIR_UP, myEvent.mouse.delta.y, THRESHOLD_Y, OFFSET_SLOW_Y, OFFSET_FAST_Y
    lda DIRECTION
    cmp #DIR_DOWN
    beq _down
_left
    #move16Bit $D6E4, POS_TEMP
    #sub16Bit OFFSET, POS_TEMP
    lda POS_TEMP+1
    bmi _setYPos0
    #move16Bit POS_TEMP, $D6E4
    bra _done
_setYPos0
    #load16BitImmediate 0, $D6E4
    bra _done
_down
    #move16Bit $D6E4, POS_TEMP
    #add16Bit OFFSET, POS_TEMP
    #cmp16BitImmediate Y_MAX-1, POS_TEMP
    bcc _setYPosMax
    #move16Bit POS_TEMP, $D6E4
    bra _done
_setYPosMax
    #load16BitImmediate Y_MAX-1, $D6E4
_done
    lda BUTTON_STATE
    cmp #BUTTON_IS_NOT_PRESSED
    beq _return
    jsr drawPixel
_return
    rts


mouseClick
    lda myEvent.mouse.delta.buttons
    and PRIMARY_BUTTON
    beq _notPressed
    lda #BUTTON_IS_PRESSED
    sta BUTTON_STATE
    bra _done
_notPressed
    lda #BUTTON_IS_NOT_PRESSED
    sta BUTTON_STATE
_done
    rts

.endnamespace