TRAP_ADDRESS = $07FF

TRAP .macro trap_code
    lda #\trap_code
    sta TRAP_ADDRESS
.endmacro 