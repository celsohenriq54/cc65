;
; Ullrich von Bassewitz, 2003-08-20
; Performance increase (about 20%) by
; Christian Krueger, 2009-09-13
;
; void* __fastcall__ memmove (void* dest, const void* src, size_t size);
;
; NOTE: This function uses entry points from memcpy!
;

        .export         _memmove
        .import         memcpy_getparams, memcpy_upwards, popax
        .importzp       ptr1, ptr2, ptr3, ptr4, tmp1

        .macpack        generic
        .macpack        longbranch

; ----------------------------------------------------------------------
_memmove:
        jsr     memcpy_getparams

; Check for the copy direction. If dest < src, we must copy upwards (start at
; low addresses and increase pointers), otherwise we must copy downwards
; (start at high addresses and decrease pointers).

        sec
        sbc     ptr1
        txa
        sbc     ptr1+1
        jcc     memcpy_upwards  ; Branch if dest < src (upwards copy)

; Copy downwards. Adjust the pointers to the end of the memory regions.

        lda     ptr1+1
        add     ptr3+1
        sta     ptr1+1

        lda     ptr2+1
        add     ptr3+1
        sta     ptr2+1

; handle fractions of a page size first

        ldy     ptr3            ; count, low byte
        bne     @entry          ; something to copy?
        beq     PageSizeCopy    ; here like bra...

@copyByte:
        lda     (ptr1),y
        sta     (ptr2),y
@entry:
        dey
        bne     @copyByte
        lda     (ptr1),y        ; copy remaining byte
        sta     (ptr2),y

PageSizeCopy:                   ; assert Y = 0
        ldx     ptr3+1          ; number of pages
        beq     done            ; none? -> done

@initBase:
        dec     ptr1+1          ; adjust base...
        dec     ptr2+1
        dey                     ; in entry case: 0 -> FF
        lda     (ptr1),y        ; need to copy this 'intro byte'
        sta     (ptr2),y        ; to 'land' later on Y=0! (as a result of the '.repeat'-block!)
        dey                     ; FF ->FE
@copyBytes:
        .repeat 2               ; Unroll this a bit to make it faster...
        lda     (ptr1),y
        sta     (ptr2),y
        dey
        .endrepeat
@copyEntry:                     ; in entry case: 0 -> FF
        bne     @copyBytes
        lda     (ptr1),y        ; Y = 0, copy last byte
        sta     (ptr2),y
        dex                     ; one page to copy less
        bne     @initBase       ; still a page to copy?

; Done, return dest

done:   jmp     popax           ; Pop ptr and return as result
                
