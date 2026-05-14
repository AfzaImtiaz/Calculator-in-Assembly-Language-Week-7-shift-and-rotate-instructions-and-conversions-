; ============================================================
;   COAL SEMESTER PROJECT  –  MODIFIED VERSION
;   Title  : Multi-Base Calculator & Number Converter
;   Author : (Write Your Name Here)
;   Roll # : (Write Your Roll Number Here)
;   Course : Computer Organization & Assembly Language
;   Tool   : emu8086
;
;   MODIFICATIONS ADDED:
;   [MOD 1] Week 4  – Flag Inspector: prints CF,ZF,SF,OF after
;                     every calculator result
;   [MOD 2] Week 4  – Overflow detection warning on ADD/SUB
;   [MOD 3] Week 6  – TEST instruction: even/odd check on input
;   [MOD 4] Week 6  – XOR bit-toggle sub-option in calculator
;   [MOD 5] Week 1  – Signed/2's complement display when result
;                     of subtraction is negative (CF=1)
;   [MOD 6] Polish  – MUL loop guarded properly + comment added
; ============================================================

.MODEL SMALL
.STACK 100h

; ============================================================
;  DATA SEGMENT
; ============================================================
.DATA

    ; -- Screen / Menu ----------------------------------------
    banner      DB  13,10
                DB  '  ============================================',13,10
                DB  '   COAL PROJECT - BASE CONVERTER & CALCULATOR',13,10
                DB  '  ============================================',13,10,'$'

    menu        DB  13,10
                DB  '  [1]  Decimal  -->  Binary  &  Hex',13,10
                DB  '  [2]  Binary   -->  Decimal &  Hex',13,10
                DB  '  [3]  Hex      -->  Decimal &  Binary',13,10
                DB  '  [4]  Calculator  ( + - * / ^ )',13,10
                DB  '  [5]  Exit',13,10
                DB  13,10
                DB  '  Enter choice: ','$'

    ; -- Prompts ----------------------------------------------
    prompt_dec  DB  13,10,'  Enter Decimal number (0-9999): ','$'
    prompt_bin  DB  13,10,'  Enter Binary  number (up to 16 bits): ','$'
    prompt_hex  DB  13,10,'  Enter Hex     number (up to 4 digits): ','$'
    prompt_num1 DB  13,10,'  Enter first  number: ','$'
    prompt_num2 DB  13,10,'  Enter second number: ','$'
    prompt_op   DB  13,10,'  Operator ( + - * / ^ ): ','$'
    prompt_mask DB  13,10,'  Enter XOR mask (hex, e.g. FF): ','$'

    ; -- Result Labels ----------------------------------------
    lbl_bin     DB  13,10,'  Binary  : ','$'
    lbl_hex     DB  13,10,'  Hex     : 0x','$'
    lbl_dec     DB  13,10,'  Decimal : ','$'
    lbl_result  DB  13,10,'  Result  : ','$'
    lbl_quot    DB  13,10,'  Quotient  : ','$'
    lbl_rem     DB  13,10,'  Remainder : ','$'

    ; -- [MOD 1] Flag labels ----------------------------------
    lbl_flags   DB  13,10,'  Flags    : ','$'
    lbl_cf      DB  'CF=','$'
    lbl_zf      DB  ' ZF=','$'
    lbl_sf      DB  ' SF=','$'
    lbl_of      DB  ' OF=','$'

    ; -- [MOD 3] Even/Odd labels ------------------------------
    lbl_even    DB  13,10,'  Parity   : EVEN (bit0=0, TEST AX,1 -> ZF=1)','$'
    lbl_odd     DB  13,10,'  Parity   : ODD  (bit0=1, TEST AX,1 -> ZF=0)','$'

    ; -- [MOD 2] Overflow warning -----------------------------
    msg_ovflow  DB  13,10,'  WARNING  : Overflow detected! (OF=1)','$'

    ; -- [MOD 5] Negative / 2s complement label ---------------
    msg_neg     DB  13,10,'  Note     : Result is NEGATIVE (CF=1 after SUB)','$'
    lbl_twos    DB  13,10,'  2s comp  : ','$'

    ; -- Messages ---------------------------------------------
    msg_again   DB  13,10,13,10,'  Press any key to return to menu...','$'
    msg_bye     DB  13,10,'  Thank you! Goodbye.',13,10,'$'
    msg_diverr  DB  13,10,'  ERROR: Cannot divide by zero!','$'
    msg_invalid DB  13,10,'  Invalid choice. Please try again.','$'
    newline     DB  13,10,'$'
    separator   DB  13,10,'  --------------------------------------------','$'

    ; -- Variables --------------------------------------------
    numA        DW  0
    numB        DW  0
    opr         DB  0
    savedFlags  DW  0           ; [MOD 1] stores PUSHF result

; ============================================================
;  CODE SEGMENT
; ============================================================
.CODE

; ============================================================
;  MAIN – entry point, menu loop
; ============================================================
MAIN PROC
    MOV  AX, @DATA
    MOV  DS, AX

MenuLoop:
    CALL ClearScreen
    LEA  DX, banner
    CALL PrintStr
    LEA  DX, menu
    CALL PrintStr

    MOV  AH, 1
    INT  21h                    ; read choice into AL

    CMP  AL, '1'
    JE   Opt1
    CMP  AL, '2'
    JE   Opt2
    CMP  AL, '3'
    JE   Opt3
    CMP  AL, '4'
    JE   Opt4
    CMP  AL, '5'
    JE   Opt5

    LEA  DX, msg_invalid
    CALL PrintStr
    CALL WaitKey
    JMP  MenuLoop

Opt1:   CALL DecConverter
        JMP  MenuLoop
Opt2:   CALL BinConverter
        JMP  MenuLoop
Opt3:   CALL HexConverter
        JMP  MenuLoop
Opt4:   CALL Calculator
        JMP  MenuLoop
Opt5:
    LEA  DX, msg_bye
    CALL PrintStr
    MOV  AH, 4Ch
    INT  21h
MAIN ENDP

; ============================================================
;  OPTION 1 – Decimal ? Binary & Hex
;  [MOD 3] Added TEST-based even/odd check after input
; ============================================================
DecConverter PROC
    CALL ClearScreen

    LEA  DX, prompt_dec
    CALL PrintStr
    CALL ReadDecimal            ; result in AX
    MOV  numA, AX

    ; [MOD 3] TEST instruction: Week 6
    ; TEST does a non-destructive AND — does not change AX
    ; If bit 0 is 0 -> ZF=1 -> number is EVEN
    ; If bit 0 is 1 -> ZF=0 -> number is ODD
    TEST AX, 1
    JNZ  DC_Odd
    LEA  DX, lbl_even
    CALL PrintStr
    JMP  DC_Conv
DC_Odd:
    LEA  DX, lbl_odd
    CALL PrintStr
DC_Conv:
    LEA  DX, separator
    CALL PrintStr

    LEA  DX, lbl_bin
    CALL PrintStr
    MOV  AX, numA
    CALL PrintBinary

    LEA  DX, lbl_hex
    CALL PrintStr
    MOV  AX, numA
    CALL PrintHex

    CALL WaitKey
    RET
DecConverter ENDP

; ============================================================
;  OPTION 2 – Binary ? Decimal & Hex
;  [MOD 3] TEST even/odd check added
; ============================================================
BinConverter PROC
    CALL ClearScreen

    LEA  DX, prompt_bin
    CALL PrintStr
    CALL ReadBinary             ; result in AX
    MOV  numA, AX

    ; [MOD 3] TEST for even/odd
    TEST AX, 1
    JNZ  BC_Odd
    LEA  DX, lbl_even
    CALL PrintStr
    JMP  BC_Conv
BC_Odd:
    LEA  DX, lbl_odd
    CALL PrintStr
BC_Conv:
    LEA  DX, separator
    CALL PrintStr

    LEA  DX, lbl_dec
    CALL PrintStr
    MOV  AX, numA
    CALL PrintDecimal

    LEA  DX, lbl_hex
    CALL PrintStr
    MOV  AX, numA
    CALL PrintHex

    CALL WaitKey
    RET
BinConverter ENDP

; ============================================================
;  OPTION 3 – Hex ? Decimal & Binary
;  [MOD 3] TEST even/odd check added
; ============================================================
HexConverter PROC
    CALL ClearScreen

    LEA  DX, prompt_hex
    CALL PrintStr
    CALL ReadHex                ; result in AX
    MOV  numA, AX

    ; [MOD 3] TEST for even/odd
    TEST AX, 1
    JNZ  HC_Odd
    LEA  DX, lbl_even
    CALL PrintStr
    JMP  HC_Conv
HC_Odd:
    LEA  DX, lbl_odd
    CALL PrintStr
HC_Conv:
    LEA  DX, separator
    CALL PrintStr

    LEA  DX, lbl_dec
    CALL PrintStr
    MOV  AX, numA
    CALL PrintDecimal

    LEA  DX, lbl_bin
    CALL PrintStr
    MOV  AX, numA
    CALL PrintBinary

    CALL WaitKey
    RET
HexConverter ENDP

; ============================================================
;  OPTION 4 – Calculator  ( + - * / ^ )
;  [MOD 4] Added ^ for XOR bit-toggle operation
; ============================================================
Calculator PROC
    CALL ClearScreen

    ; read first number
    LEA  DX, prompt_num1
    CALL PrintStr
    CALL ReadDecimal
    MOV  numA, AX

    ; read operator
    LEA  DX, prompt_op
    CALL PrintStr
    MOV  AH, 1
    INT  21h
    MOV  opr, AL

    ; read second number (or mask for XOR)
    MOV  BL, opr
    CMP  BL, '^'
    JE   ReadMask
    LEA  DX, prompt_num2
    CALL PrintStr
    CALL ReadDecimal
    MOV  numB, AX
    JMP  Dispatch
ReadMask:
    ; [MOD 4] For XOR, read second value as hex mask
    LEA  DX, prompt_mask
    CALL PrintStr
    CALL ReadHex
    MOV  numB, AX

Dispatch:
    LEA  DX, separator
    CALL PrintStr

    MOV  BL, opr
    CMP  BL, '+'
    JE   DoAdd
    CMP  BL, '-'
    JE   DoSub
    CMP  BL, '*'
    JE   DoMul
    CMP  BL, '/'
    JE   DoDiv
    CMP  BL, '^'
    JE   DoXor
    JMP  CalcDone

; -- Addition ----------------------------------------------
; [MOD 2] After ADD, capture flags and check OF for overflow
DoAdd:
    MOV  AX, numA
    ADD  AX, numB
    PUSHF                       ; [MOD 1] save flags immediately after ADD
    POP  savedFlags
    JNO  Add_NoOvf              ; [MOD 2] jump if OF=0 (no overflow)
    LEA  DX, msg_ovflow
    CALL PrintStr
Add_NoOvf:
    CALL ShowAllBases
    PUSH savedFlags
    POPF
    CALL PrintFlags             ; [MOD 1] display CF ZF SF OF
    JMP  CalcDone

; -- Subtraction -------------------------------------------
; [MOD 2] Check OF for overflow
; [MOD 5] Check CF for negative result -> show 2's complement
DoSub:
    MOV  AX, numA
    SUB  AX, numB
    PUSHF                       ; [MOD 1] save flags after SUB
    POP  savedFlags
    JNO  Sub_NoOvf              ; [MOD 2] check overflow
    LEA  DX, msg_ovflow
    CALL PrintStr
Sub_NoOvf:
    ; [MOD 5] If CF=1, subtraction borrowed -> result negative
    ; CF is bit 0 of the flags register word
    TEST savedFlags, 0001h
    JZ   Sub_Positive
    LEA  DX, msg_neg
    CALL PrintStr
    ; AX still holds the wrapped result; its bit pattern IS the 2's complement
    LEA  DX, lbl_twos
    CALL PrintStr
    CALL PrintBinary
    JMP  Sub_FlagsOnly
Sub_Positive:
    CALL ShowAllBases
Sub_FlagsOnly:
    PUSH savedFlags
    POPF
    CALL PrintFlags             ; [MOD 1]
    JMP  CalcDone

; -- Multiplication (repeated addition) --------------------
; [MOD 6] Comment clarifies pedagogical intent; 0 guarded
DoMul:
    ; Week 5 concept: LOOP-based repeated addition
    ; Using repeated ADD instead of MUL instruction to show
    ; that multiplication IS repeated addition (teaching point)
    MOV  CX, numB               ; loop numB times
    XOR  AX, AX                 ; AX = 0 (accumulator)
    CMP  CX, 0
    JE   MulDone                ; [MOD 6] 0 * anything = 0
MulLoop:
    ADD  AX, numA               ; AX += numA
    LOOP MulLoop
MulDone:
    PUSHF
    POP  savedFlags
    CALL ShowAllBases
    PUSH savedFlags
    POPF
    CALL PrintFlags             ; [MOD 1]
    JMP  CalcDone

; -- Division (repeated subtraction) -----------------------
DoDiv:
    MOV  AX, numB
    CMP  AX, 0
    JE   DivZeroErr

    MOV  AX, numA
    MOV  BX, numB
    XOR  CX, CX                 ; CX = quotient counter
DivLoop:
    CMP  AX, BX
    JB   DivDone
    SUB  AX, BX
    INC  CX
    JMP  DivLoop
DivDone:
    ; CX = quotient,  AX = remainder
    PUSHF
    POP  savedFlags
    LEA  DX, lbl_quot
    CALL PrintStr
    PUSH AX
    MOV  AX, CX
    CALL PrintDecimal

    POP  AX
    LEA  DX, lbl_rem
    CALL PrintStr
    CALL PrintDecimal

    PUSH savedFlags
    POPF
    CALL PrintFlags             ; [MOD 1]
    JMP  CalcDone

DivZeroErr:
    LEA  DX, msg_diverr
    CALL PrintStr
    JMP  CalcDone

; -- [MOD 4] XOR bit-toggle --------------------------------
; Week 6 concept: XOR flips bits where mask=1, keeps where mask=0
; Example: 1010 XOR 1100 = 0110 (middle two bits toggled)
DoXor:
    MOV  AX, numA
    XOR  AX, numB               ; toggle bits specified by mask
    PUSHF
    POP  savedFlags
    LEA  DX, lbl_result
    CALL PrintStr

    LEA  DX, lbl_bin
    CALL PrintStr
    CALL PrintBinary

    LEA  DX, lbl_hex
    CALL PrintStr
    CALL PrintHex

    PUSH savedFlags
    POPF
    CALL PrintFlags             ; [MOD 1]

CalcDone:
    CALL WaitKey
    RET
Calculator ENDP

; ============================================================
;  ShowAllBases – prints AX as Decimal, Binary, and Hex
; ============================================================
ShowAllBases PROC
    PUSH AX

    LEA  DX, lbl_result
    CALL PrintStr
    POP  AX
    PUSH AX
    CALL PrintDecimal

    LEA  DX, lbl_bin
    CALL PrintStr
    POP  AX
    PUSH AX
    CALL PrintBinary

    LEA  DX, lbl_hex
    CALL PrintStr
    POP  AX
    CALL PrintHex

    RET
ShowAllBases ENDP

; ============================================================
;  [MOD 1] PrintFlags – displays CF, ZF, SF, OF
;  Week 4 concept: reads the Flag Register directly
;
;  Flag register bit positions:
;    bit  0  = CF (Carry Flag)    – set if unsigned overflow / borrow
;    bit  6  = ZF (Zero Flag)     – set if result is zero
;    bit  7  = SF (Sign Flag)     – set if result is negative (MSB=1)
;    bit 11  = OF (Overflow Flag) – set if signed overflow
;
;  How it works:
;    PUSHF pushes the 16-bit flag register onto the stack.
;    We pop it into savedFlags (a memory variable).
;    Then TEST isolates each bit — if bit=1, ZF=0 (JNZ fires).
; ============================================================
PrintFlags PROC
    LEA  DX, lbl_flags
    CALL PrintStr

    MOV  AX, savedFlags

    ; CF – bit 0
    LEA  DX, lbl_cf
    CALL PrintStr
    TEST AX, 0001h
    JZ   PF_CF0
    MOV  DL, '1'
    JMP  PF_CF_Print
PF_CF0:
    MOV  DL, '0'
PF_CF_Print:
    MOV  AH, 2
    INT  21h

    ; ZF – bit 6
    LEA  DX, lbl_zf
    CALL PrintStr
    TEST AX, 0040h
    JZ   PF_ZF0
    MOV  DL, '1'
    JMP  PF_ZF_Print
PF_ZF0:
    MOV  DL, '0'
PF_ZF_Print:
    MOV  AH, 2
    INT  21h

    ; SF – bit 7
    LEA  DX, lbl_sf
    CALL PrintStr
    TEST AX, 0080h
    JZ   PF_SF0
    MOV  DL, '1'
    JMP  PF_SF_Print
PF_SF0:
    MOV  DL, '0'
PF_SF_Print:
    MOV  AH, 2
    INT  21h

    ; OF – bit 11
    LEA  DX, lbl_of
    CALL PrintStr
    TEST AX, 0800h
    JZ   PF_OF0
    MOV  DL, '1'
    JMP  PF_OF_Print
PF_OF0:
    MOV  DL, '0'
PF_OF_Print:
    MOV  AH, 2
    INT  21h

    RET
PrintFlags ENDP

; ============================================================
;  PrintBinary – prints AX as 16-bit binary  (uses ROL+CF)
;  Week 7 concept: ROL shifts MSB into Carry Flag each time
; ============================================================
PrintBinary PROC
    MOV  BX, AX
    MOV  CX, 16
PB_Loop:
    ROL  BX, 1                  ; MSB -> Carry Flag
    JC   PB_One
    MOV  DL, '0'
    JMP  PB_Print
PB_One:
    MOV  DL, '1'
PB_Print:
    MOV  AH, 2
    INT  21h
    MOV  AX, CX
    DEC  AX
    AND  AX, 0003h
    CMP  AX, 0000h
    JNE  PB_Next
    CMP  CX, 1
    JE   PB_Next
    MOV  DL, ' '
    MOV  AH, 2
    INT  21h
PB_Next:
    LOOP PB_Loop
    RET
PrintBinary ENDP

; ============================================================
;  PrintHex – prints AX as 4-digit hex  (uses SHR 4)
;  Week 7 concept: SHR 4 isolates each nibble
; ============================================================
PrintHex PROC
    MOV  BX, AX

    MOV  DL, BH
    SHR  DL, 4
    CALL NibbleToASCII

    MOV  DL, BH
    AND  DL, 0Fh
    CALL NibbleToASCII

    MOV  DL, BL
    SHR  DL, 4
    CALL NibbleToASCII

    MOV  DL, BL
    AND  DL, 0Fh
    CALL NibbleToASCII

    MOV  DL, 'h'
    MOV  AH, 2
    INT  21h
    RET
PrintHex ENDP

NibbleToASCII PROC
    CMP  DL, 9
    JLE  NA_Digit
    ADD  DL, 7
NA_Digit:
    ADD  DL, '0'
    MOV  AH, 2
    INT  21h
    RET
NibbleToASCII ENDP

; ============================================================
;  PrintDecimal – prints AX as unsigned decimal
; ============================================================
PrintDecimal PROC
    MOV  BX, 10
    XOR  CX, CX
PD_Divide:
    XOR  DX, DX
    DIV  BX
    PUSH DX
    INC  CX
    CMP  AX, 0
    JNE  PD_Divide
PD_Print:
    POP  DX
    ADD  DL, '0'
    MOV  AH, 2
    INT  21h
    LOOP PD_Print
    RET
PrintDecimal ENDP

; ============================================================
;  ReadDecimal – keyboard input -> AX
; ============================================================
ReadDecimal PROC
    XOR  BX, BX
    MOV  CX, 10
RD_Loop:
    MOV  AH, 1
    INT  21h
    CMP  AL, 13
    JE   RD_Done
    CMP  AL, '0'
    JB   RD_Loop
    CMP  AL, '9'
    JA   RD_Loop
    SUB  AL, '0'
    MOV  AH, 0
    PUSH AX
    MOV  AX, BX
    MUL  CX
    MOV  BX, AX
    POP  AX
    ADD  BX, AX
    JMP  RD_Loop
RD_Done:
    MOV  AX, BX
    RET
ReadDecimal ENDP

; ============================================================
;  ReadBinary – reads '0'/'1' chars -> AX
;  Week 7 concept: SHL shifts existing bits left each time
; ============================================================
ReadBinary PROC
    XOR  BX, BX
RB_Loop:
    MOV  AH, 1
    INT  21h
    CMP  AL, 13
    JE   RB_Done
    CMP  AL, '0'
    JE   RB_Zero
    CMP  AL, '1'
    JNE  RB_Loop
    SHL  BX, 1
    OR   BX, 1
    JMP  RB_Loop
RB_Zero:
    SHL  BX, 1
    JMP  RB_Loop
RB_Done:
    MOV  AX, BX
    RET
ReadBinary ENDP

; ============================================================
;  ReadHex – reads hex string -> AX
;  Week 7 concept: SHL 4 shifts 1 nibble left each time
; ============================================================
ReadHex PROC
    XOR  BX, BX
RH_Loop:
    MOV  AH, 1
    INT  21h
    CMP  AL, 13
    JE   RH_Done
    CMP  AL, '0'
    JB   RH_Loop
    CMP  AL, '9'
    JLE  RH_IsDigit
    CMP  AL, 'A'
    JB   RH_Loop
    CMP  AL, 'F'
    JLE  RH_IsUpper
    CMP  AL, 'a'
    JB   RH_Loop
    CMP  AL, 'f'
    JA   RH_Loop
    SUB  AL, 20h
RH_IsUpper:
    SUB  AL, 7
RH_IsDigit:
    SUB  AL, '0'
    MOV  AH, 0
    SHL  BX, 4
    ADD  BX, AX
    JMP  RH_Loop
RH_Done:
    MOV  AX, BX
    RET
ReadHex ENDP

; ============================================================
;  UTILITY PROCEDURES
; ============================================================

PrintStr PROC
    MOV  AH, 9
    INT  21h
    RET
PrintStr ENDP

ClearScreen PROC
    MOV  AH, 2
    MOV  DL, 0Ch
    INT  21h
    RET
ClearScreen ENDP

WaitKey PROC
    LEA  DX, msg_again
    MOV  AH, 9
    INT  21h
    MOV  AH, 1
    INT  21h
    RET
WaitKey ENDP

END MAIN