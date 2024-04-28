select .namespace

TXT5  .text "Choose a start configuration manually"
TXT6  .text "Press x to return to main menu"
TXT7  .text "Press F7 to start calculation in fast mode"
TXT8  .text "Press F5 to start calculation in normal mode"
TXT9  .text "Press F1 to toggle between draw and erase pixel mode"
MODE_DRAW  .text "DRAW "
MODE_ERASE .text "ERASE"
MODE_TEXT  .text "Mode"
MODE_ULINE .text "===="
TXT_X .text "X: $"
TXT_Y .text "Y: $"

VAL_MODE_ERASE = 0
VAL_MODE_DRAW = 1

TXT4  .text "The start configuration was chosen by you"

printMessage
    #printString TXT4, len(TXT4)
    rts


STATE_DRAW_MODE .byte ?

doSelect
    #setCol (TXT_BLUE << 4) | (TXT_WHITE)
    jsr txtio.clear
    jsr txtio.home
    jsr world.init
    jsr mouseInit
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
    #load16BitImmediate world.setCell, MODIFY_VEC
    lda #VAL_MODE_DRAW
    sta STATE_DRAW_MODE

    #locate 15, 35
    #printString HEADER, len(HEADER)
    #locate 15, 36
    #printString HEADER_U, len(HEADER_U)
    #locate 0, 40
    #printString TXT5, len(TXT5)
    #locate 0, 44 
    #printString TXT8, len(TXT8)
    #locate 0, 46 
    #printString TXT7, len(TXT7)
    #locate 0, 48 
    #printString TXT6, len(TXT6)
    #locate 0, 50
    #printString TXT9, len(TXT9)
    #locate 68,4
    #printString MODE_DRAW, len(MODE_DRAW)

    #locate 68,6
    #printString TXT_X, len(TXT_X)
    #locate 68,7
    #printString TXT_Y, len(TXT_Y)

    #locate 68,3
    #printString MODE_ULINE, len(MODE_ULINE)
    #locate 68,2
    #printString MODE_TEXT, len(MODE_TEXT)
    jsr drawMousePos

    jsr eventLoop
    
    jsr hires.off
    jsr mouseOff
    sec
    rts


mouseInit
    lda THRESHOLD_MOVE_X
    sta BRAKE.xplus
    sta BRAKE.xminus
    lda THRESHOLD_MOVE_Y    
    sta BRAKE.yplus
    sta BRAKE.yminus
    rts


mouseOn
    #saveIo
    #setIo 0
    lda #1
    sta $D6E0
    ; X position = 4 * (128/2) =  256
    stz $D6E2
    lda #1
    sta $D6E3
    ; y position = 4 * (64/2) = 128
    lda #128
    sta $D6E4
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
    cmp #$81
    bne _checkStart4x4
    lda STATE_DRAW_MODE
    eor #1
    sta STATE_DRAW_MODE
    cmp #VAL_MODE_ERASE
    beq _setErase
    #load16BitImmediate world.setCell, MODIFY_VEC
    #locate 68,4
    #printString MODE_DRAW, len(MODE_DRAW)
    bra _endModeSelect
_setErase
    #load16BitImmediate world.resetCell, MODIFY_VEC
    #locate 68,4
    #printString MODE_ERASE, len(MODE_ERASE)
_endModeSelect
    clc
    rts
_checkStart4x4
    cmp #$85
    bne _checkStart1x1
    jsr mouseOff
    #load16BitImmediate world.drawPic4x4, world.DRAW_VEC
    jsr hires.Off
    jsr performCalculation
    bra _exit
_checkStart1x1
    cmp #$87
    bne _exitTest
    jsr mouseOff
    #load16BitImmediate world.drawPic, world.DRAW_VEC
    jsr hires.Off
    jsr performCalculation
    bra _exit
_exitTest
    cmp #120
    bne _doneNotStop
_exit
    sec
    rts
_doneNotStop
    clc
    rts


procMouseEvent
    #saveIo
    #setIo 0
    jsr mouseClick
    jsr mouseLeftRight
    jsr mouseUpDown
    #restoreIo
    jsr drawMousePos
    rts


drawMousePos
    #move16Bit $D6E2, POS_TEMP
    #halve16Bit POS_TEMP
    #halve16Bit POS_TEMP    
    #locate 72, 6
    lda POS_TEMP
    jsr txtio.printByte


    #move16Bit $D6E4, POS_TEMP
    #halve16Bit POS_TEMP
    #halve16Bit POS_TEMP
    #locate 72, 7
    lda POS_TEMP
    jsr txtio.printByte
    rts


X_MAX = 512
Y_MAX = 256

DIR_LEFT = 0
DIR_RIGHT = 1
DIR_UP = 0
DIR_DOWN = 1

SPEED_SLOW = 0
SPEED_MEDIUM = 1
SPEED_FAST = 2

LEFT_BUTTON = 1
RIGHT_BUTTON = 2

BUTTON_IS_PRESSED = 1
BUTTON_IS_NOT_PRESSED = 0

DIRECTION      .byte 0                                    ; determined direction of delta sent by mouse
SIGN           .byte 0                                    ; raw sign of delta sent by the mouse (1 = negative, 0 = positive)
SPEED          .byte 0                                    ; determined speed (slow, medium or fast)
OFFSET         .byte 0, 0                                 ; calculated number of pixels to move the mouse pointer
PRIMARY_BUTTON .byte LEFT_BUTTON                          ; select left or right handedness 
BUTTON_STATE   .byte 0                                    ; state of the primary button


THRESHOLD_MOVE_X .byte 5                                  ; You need THRESHOLD_MOVE_X kernel messages in x direction to move the pointer at all when in slow mode
THRESHOLD_MEDIUM_X .byte 6                                ; Absolute delta in X direction that signifies a medium speed
THRESHOLD_FAST_X .byte 12                                 ; Absolute delta in X direction that signifies a fast speed

OFFSET_SLOW_X .byte 4                                     ; pixels to move in x direction when speed is slow
OFFSET_MEDIUM_X .byte 4                                   ; pixels to move in x direction when speed is medium
OFFSET_FAST_X .byte 16                                    ; pixels to move in x direction when speed is fast

THRESHOLD_MOVE_Y .byte 5                                  ; You need THRESHOLD_MOVE_Y kernel messages in Y direction to move the pointer at all when in slow mode
THRESHOLD_MEDIUM_Y .byte 6                                ; Absolute delta in Y direction which is considered to be medium speed
THRESHOLD_FAST_Y .byte 12                                 ; Absolute delta in Y direction which is considered to be fast speed

OFFSET_SLOW_Y .byte 4                                     ; pixels to move in y direction when speed is slow
OFFSET_MEDIUM_Y .byte 4                                   ; pixels to move in x direction when speed is medium
OFFSET_FAST_Y .byte 16                                    ; pixels to move in y direction when speed is fast

Brake_t .struct 
    xplus .byte 0
    yplus .byte 0
    xminus .byte 0
    yminus .byte 0
.endstruct

BRAKE .dstruct Brake_t


calcDirection .macro dirPlus, dirMinus, deltaAddr
    stz SIGN
    ; determine direction using the sign of the offset and
    ; calculate the absolute value of the delta sent by the
    ; mouse.
    lda \deltaAddr
    bmi _minus
    lda #\dirPlus
    sta DIRECTION
    lda \deltaAddr
    bra _speedCheck
_minus
    inc SIGN
    lda #\dirMinus
    sta DIRECTION
    ; reverse two's complement
    lda \deltaAddr
    eor #$FF
    clc
    adc #1
_speedCheck
.endmacro


calcSpeed .macro thresholdMediumAddr, thresholdFastAddr
    ; determine whether speed is slow, medium or fast
    cmp \thresholdFastAddr
    bcs _speedFast
    cmp \thresholdMediumAddr
    bcs _speedMedium
    bra _speedSlow
_speedFast
    lda #SPEED_FAST
    sta SPEED
    bra _finished
_speedMedium
    lda #SPEED_MEDIUM
    sta SPEED
    bra _finished
_speedSlow
    lda #SPEED_SLOW
    sta SPEED
_finished
.endmacro


calcOffset .macro offsetSlowAddr, offsetMediumAddr, offsetFastAddr, brakePlusAddr, brakeMinusAddr, moveThreshold
    ; determine how many pixels the mouse pointer is to be moved
    lda SPEED
    cmp #SPEED_SLOW
    beq _slow
    cmp #SPEED_MEDIUM
    bne _fast
_medium
    lda \offsetMediumAddr
    sta OFFSET
    bra _offsetDone
_fast
    lda \offsetFastAddr
    sta OFFSET
    bra _offsetDone
_slow
    ; In slow mode we have to receive \moveThreshold messages pointing in same direction before
    ; we begin to move the mouse. This is essential for control and accuracy.
    stz OFFSET
    lda SIGN
    bne _signMinus
_signPlus
    lda \moveThreshold
    sta \brakeMinusAddr
    dec \brakePlusAddr
    bne _offsetDone
    lda \moveThreshold
    sta \brakePlusAddr
    bra _setOffset
_signMinus
    lda \moveThreshold
    sta \brakePlusAddr
    dec \brakeMinusAddr
    bne _offsetDone
    lda \moveThreshold
    sta \brakeMinusAddr
_setOffset
    lda \offsetSlowAddr
    sta OFFSET
_offsetDone
.endmacro


evalMouseOffset .macro dirPlus, dirMinus, deltaAddr, theresholdMediumAddr, theresholdFastAddr, offsetSlowAddr, offsetMediumAddr, offsetFastAddr, brakePlusAddr, brakeMinusAddr, moveThreshold
    #calcDirection \dirPlus, \dirMinus, \deltaAddr
    #calcSpeed \theresholdMediumAddr, \theresholdFastAddr
    #calcOffset \offsetSlowAddr, \offsetMediumAddr, \offsetFastAddr, \brakePlusAddr, \brakeMinusAddr, \moveThreshold
.endmacro


POS_TEMP       .word 0
PIXEL_COLS     .byte GFX_GREEN, GFX_BLUE

MODIFY_VEC .word world.setCell
modifyCell
    jmp (MODIFY_VEC)

; draw a chunky 4x4 pixel at the current position of the mouse pointer
drawPixel
    #move16Bit $D6E2, POS_TEMP
    #halve16Bit POS_TEMP
    #halve16Bit POS_TEMP
    lda POS_TEMP
    cmp #128
    bne _valid
    lda #127
_valid
    sta world.COORD.x

    #move16Bit $D6E4, POS_TEMP
    #halve16Bit POS_TEMP
    #halve16Bit POS_TEMP
    lda POS_TEMP
    cmp #64
    bne _valid2
    lda #63
_valid2
    sta world.COORD.y
    
    jsr modifyCell
    tax
    lda PIXEL_COLS, x
    sta hires.setPixelArgs.col
    
    lda world.COORD.x
    sta POS_TEMP
    stz POS_TEMP+1
    #double16Bit POS_TEMP
    #move16Bit POS_TEMP, hires.setPixelArgs.x

    lda world.COORD.y
    sta POS_TEMP
    stz POS_TEMP+1
    #double16Bit POS_TEMP
    lda POS_TEMP
    sta hires.setPixelArgs.y
    
    jsr hires.setPixel
    
    inc hires.setPixelArgs.x
    jsr hires.setPixel
    
    inc hires.SetPixelArgs.y
    jsr hires.setPixel

    dec hires.setPixelArgs.x
    jsr hires.setPixel

    rts


; move mouse pointer in x direction
mouseLeftRight
    lda myEvent.mouse.delta.x
    bne _doEval
    jmp _done
_doEval
    #evalMouseOffset DIR_RIGHT, DIR_LEFT, myEvent.mouse.delta.x, THRESHOLD_MEDIUM_X, THRESHOLD_FAST_X, OFFSET_SLOW_X, OFFSET_MEDIUM_X, OFFSET_FAST_X, BRAKE.xplus, BRAKE.xminus, THRESHOLD_MOVE_X
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
    #cmp16BitImmediate X_MAX, POS_TEMP
    bcc _setXPosMax
    #move16Bit POS_TEMP, $D6E2
    bra _done
_setXPosMax
    #load16BitImmediate X_MAX, $D6E2
_done
    lda BUTTON_STATE
    cmp #BUTTON_IS_NOT_PRESSED
    beq _return
    jsr drawPixel
_return
    rts


; move mouse pointer in y direction
mouseUpDown 
    lda myEvent.mouse.delta.y
    bne _doEval
    jmp _done
_doEval
    #evalMouseOffset DIR_DOWN, DIR_UP, myEvent.mouse.delta.y, THRESHOLD_MEDIUM_Y, THRESHOLD_FAST_Y, OFFSET_SLOW_Y, OFFSET_MEDIUM_Y, OFFSET_FAST_Y, BRAKE.yplus, BRAKE.yminus,THRESHOLD_MOVE_Y
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
    #cmp16BitImmediate Y_MAX, POS_TEMP
    bcc _setYPosMax
    #move16Bit POS_TEMP, $D6E4
    bra _done
_setYPosMax
    #load16BitImmediate Y_MAX, $D6E4
_done
    lda BUTTON_STATE
    cmp #BUTTON_IS_NOT_PRESSED
    beq _return
    jsr drawPixel
_return
    rts


; record mouse clicks made with the primary button
mouseClick
    lda myEvent.mouse.delta.buttons
    and PRIMARY_BUTTON
    beq _notPressed
    lda #BUTTON_IS_PRESSED
    sta BUTTON_STATE
    jsr drawPixel
    bra _done
_notPressed
    lda #BUTTON_IS_NOT_PRESSED
    sta BUTTON_STATE
_done
    rts

.endnamespace