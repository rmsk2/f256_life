.include "api.asm"

; target address is $4000
* = $4000
.cpu "w65c02"

OUT_LINE = 29

.include "macros.asm"

; --------------------------------------------------
; This routine is the entry point of the program
;--------------------------------------------------
main
    jsr initEvents

    #kprint 0, OUT_LINE + 6, clearDone, len(clearDone), dataColor
    #kprint 0, OUT_LINE-1, intro, len(intro), introColor
    #kprint 0, OUT_LINE + 1, txtDeltaX, len(txtDeltaX), dataColor
    #kprint 0, OUT_LINE + 2, txtDeltaY, len(txtDeltaY), dataColor
    #kprint 0, OUT_LINE + 3, txtDeltaZ, len(txtDeltaZ), dataColor
    #kprint 0, OUT_LINE + 4, txtButton, len(txtButton), dataColor

    jsr clearState
    jsr trackMouseEvents

    jsr restoreEvents
    rts

.include "khelp.asm"

; --------------------------------------------------
; This routine polls the kernel event queue. It listens for MOUSE and key.PRESSED
; events. If a key press is received, the routine returns.
;--------------------------------------------------
trackMouseEvents
    ; Peek at the queue to see if anything is pending
    lda kernel.args.events.pending ; Negated count
    bpl trackMouseEvents
    ; Get the next event.
    jsr kernel.NextEvent
    bcs trackMouseEvents
    ; Handle the event
    lda myEvent.type    
    
    cmp #kernel.event.mouse.DELTA
    beq _found

    cmp #kernel.event.key.PRESSED
    beq _done

    bra trackMouseEvents
_found
    jsr printState
    bra trackMouseEvents
_done
    #kprint 0, OUT_LINE + 6, msgDone, len(msgDone), dataColor
    rts    


; --------------------------------------------------
; This routine processes mouse events received by the kernel. The event data 
; consists of four bytes describing the delta in X direction (left right),
; in Y direction (up, down) in Z direction (scroll wheel) and currently pressed
; buttons (left, right, scroll wheel).
;--------------------------------------------------
printState
    lda myEvent.mouse.delta.x
    #toHex deltaX
    lda myEvent.mouse.delta.Y
    #toHex deltaY
    lda myEvent.mouse.delta.Z
    #toHex deltaZ
    lda myEvent.mouse.delta.buttons
    #toHex button
    #kprint len(txtDeltaX), OUT_LINE + 1, deltaX, len(deltaX), dataColor
    #kprint len(txtDeltaY), OUT_LINE + 2, deltaY, len(deltaX), dataColor
    #kprint len(txtDeltaY), OUT_LINE + 3, deltaZ, len(deltaX), dataColor
    #kprint len(txtButton), OUT_LINE + 4, button, len(deltaX), dataColor
    rts

clearState
    lda #$30
    ldy #7
_clearLoop
    sta deltaX, y
    dey
    bpl _clearLoop
    #kprint len(txtDeltaX), OUT_LINE + 1, deltaX, len(deltaX), dataColor
    #kprint len(txtDeltaY), OUT_LINE + 2, deltaY, len(deltaX), dataColor
    #kprint len(txtDeltaY), OUT_LINE + 3, deltaZ, len(deltaX), dataColor
    #kprint len(txtButton), OUT_LINE + 4, button, len(deltaX), dataColor
    rts

HEX_CHARS .text "0123456789ABCDEF"
HELP_CONV .byte 0
toHex .macro addr
    sta HELP_CONV
    and #$F0
    lsr
    lsr
    lsr
    lsr
    tax
    lda HEX_CHARS, x
    sta \addr
    lda HELP_CONV
    and #$0F
    tax
    lda HEX_CHARS, x
    sta \addr+1
    .endmacro

deltaX .text "  "
deltaY .text "  "
deltaZ .text "  "
button .text "  "

txtDeltaX .text "Delta X: "
txtDeltaY .text "Delta Y: "
txtDeltaZ .text "Delta Z: "
txtButton .text "Button : "

msgDone .text   "Done"
clearDone .text "    "
dataColor .text x"62" x len(txtDeltaX)

intro .text "Move mouse. Press any key to stop."
introColor .text x"26" x len(intro)