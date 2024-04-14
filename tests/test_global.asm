TRAP_ADDRESS = $07FF

TRAP_RANDOM = 0
TRAP_PRINT_0 = 1
TRAP_PRINT_1 = 2

TRAP .macro trap_code
    lda #\trap_code
    sta TRAP_ADDRESS
.endmacro 