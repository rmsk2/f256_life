random .namespace

RNG_LO = $D6A4
RNG_HI = $D6A5
RNG_CTRL = $D6A6

RAND_NIBBLES .fill 4
SEED_VAL_LO .byte 0
SEED_VAL_HI .byte 0

RTC_BUFFER .dstruct kernel.time_t

kGetTimeStamp
    #load16BitImmediate RTC_BUFFER, kernel.args.buf
    lda #size(kernel.time_t)
    sta kernel.args.buflen
    jsr kernel.Clock.GetTime
    rts


init
    jsr kGetTimeStamp
    lda RTC_BUFFER.centis
    sta SEED_VAL_LO
    lda RTC_BUFFER.seconds
    sta SEED_VAL_HI

    lda $D651
    eor SEED_VAL_LO
    sta SEED_VAL_LO

    lda $D659
    eor SEED_VAL_HI
    sta SEED_VAL_HI

    clc
    lda $D01A
    adc SEED_VAL_LO
    sta SEED_VAL_LO

    clc
    lda $D018
    adc SEED_VAL_HI
    sta SEED_VAL_HI

    lda SEED_VAL_LO
    sta RNG_LO
    lda SEED_VAL_HI
    sta RNG_HI
    lda #2
    sta RNG_CTRL

    rts

; get random 16 bit number in accu and x register
get
    lda #1
    sta RNG_CTRL
_wait
    lda RNG_CTRL
    beq _wait
    lda RNG_LO
    ldx RNG_HI
    rts

.endnamespace