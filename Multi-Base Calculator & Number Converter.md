# **Technical Documentation**

## **Multi-Base Calculator & Number Converter**

### **COAL Semester Project — 8086 Assembly Language**

---

**Course:** CS-530 — Computer Organization & Assembly Language  
 **Tool:** emu8086 Microprocessor Emulator  
 **Architecture:** Intel 8086 (16-bit, Real Mode)  
**Members:** 

* *Afza Imtiaz \[24-Arid-1007\]*  
* *Laraib Afzal \[24-Arid-1032\]*  
* *Muskan Bibi \[24-Arid-1060\]*  
* *Rahat Jabeen \[24-Arid-1070\]*  
* *Tehreem Shahbaz \[25-Arid-3644\]*

 **Instructor:** Sir Muhammad Azhar  
 **University:** UIIT, PMAS Arid Agriculture University, Rawalpindi

---

## **1\. Project Overview**

This program is a menu-driven, interactive application written in 8086 assembly language. It provides two main categories of functionality:

1. **Number Base Conversion** — converts user input between Decimal, Binary, and Hexadecimal representations  
2. **Arithmetic Calculator** — performs addition, subtraction, multiplication, division, and XOR operations with full CPU flag reporting

The project was built incrementally over the semester, with six documented modifications (MOD 1–6) that layer new assembly concepts onto the base program. Each modification maps directly to a concept taught in a specific week of the course.

---

## **2\. Memory Model and Segment Layout**

Memory Model : SMALL  
Stack Size   : 100h (256 bytes)  
Segments     : DATA (variables \+ strings) | CODE (all procedures)

The `.MODEL SMALL` directive places the data segment and code segment each within one 64KB segment. The `@DATA` constant is loaded into `DS` at program start:

MOV AX, @DATA  
MOV DS, AX

This is the standard 8086 program initialization pattern required before any data segment access.

---

## **3\. Data Segment**

### **3.1 String Variables (DB — Define Byte)**

All strings are terminated with `'$'` as required by `INT 21h` service `AH=9` (print string to stdout).

| Variable | Purpose |
| ----- | ----- |
| `banner` | Title screen printed at program start |
| `menu` | Main menu with options 1–5 |
| `prompt_dec/bin/hex` | Input prompts for each converter |
| `prompt_num1/num2` | Calculator operand prompts |
| `prompt_op` | Operator input prompt |
| `prompt_mask` | XOR mask input prompt (hex) |
| `lbl_bin/hex/dec/result` | Output labels for conversion results |
| `lbl_quot/rem` | Division output labels |
| `lbl_flags/cf/zf/sf/of` | Flag display labels (MOD 1\) |
| `lbl_even/lbl_odd` | Parity result labels (MOD 3\) |
| `msg_ovflow` | Overflow warning message (MOD 2\) |
| `msg_neg/lbl_twos` | Negative result and 2's complement label (MOD 5\) |
| `msg_again/msg_bye` | Navigation and exit messages |
| `msg_diverr` | Division by zero error message |

### **3.2 Numeric Variables**

| Variable | Type | Purpose |
| ----- | ----- | ----- |
| `numA` | `DW` (word, 16-bit) | First operand |
| `numB` | `DW` (word, 16-bit) | Second operand or XOR mask |
| `opr` | `DB` (byte) | Operator character ('+', '-', '\*', '/', '^') |
| `savedFlags` | `DW` (word, 16-bit) | Stores CPU flag register via `PUSHF` (MOD 1\) |

---

## **4\. Program Flow**

MAIN  
 │  
 ├── ClearScreen  
 ├── Print banner \+ menu  
 ├── Read choice (INT 21h, AH=1)  
 │  
 ├── '1' → DecConverter  
 ├── '2' → BinConverter  
 ├── '3' → HexConverter  
 ├── '4' → Calculator  
 ├── '5' → Exit (INT 21h, AH=4Ch)  
 └── other → Print "Invalid", loop back

Each option procedure returns to `MenuLoop` after completion via `JMP MenuLoop`.

---

## **5\. Procedure Reference**

### **5.1 MAIN**

**Entry point.** Initializes `DS`, then enters the infinite menu loop. Reads a single character from keyboard, dispatches to the appropriate procedure via `CMP` \+ `JE` chains.

**INT 21h services used:**

* `AH=1` — Read character from keyboard into `AL`  
* `AH=4Ch` — Terminate program

---

### **5.2 DecConverter (Option 1\)**

Converts a decimal number to Binary and Hexadecimal.

**Register flow:**

ReadDecimal → AX → numA  
TEST AX, 1         ; even/odd check (MOD 3\)  
PrintBinary(numA)  
PrintHex(numA)

**MOD 3 logic:** `TEST AX, 1` performs a non-destructive AND between `AX` and `1`. If bit 0 is zero (even), `ZF=1` and `JNZ` does not fire. If bit 0 is one (odd), `ZF=0` and `JNZ` fires to the odd label.

---

### **5.3 BinConverter (Option 2\)**

Reads a binary string (up to 16 bits), converts to Decimal and Hexadecimal.

**Register flow:**

ReadBinary → AX → numA  
TEST AX, 1         ; even/odd check (MOD 3\)  
PrintDecimal(numA)  
PrintHex(numA)

---

### **5.4 HexConverter (Option 3\)**

Reads a hexadecimal string (up to 4 digits), converts to Decimal and Binary.

**Register flow:**

ReadHex → AX → numA  
TEST AX, 1         ; even/odd check (MOD 3\)  
PrintDecimal(numA)  
PrintBinary(numA)

---

### **5.5 Calculator (Option 4\)**

Core arithmetic engine. Reads `numA`, operator (`opr`), and either `numB` (decimal) or a hex mask (for XOR). Dispatches to one of five sub-routines.

**Dispatch chain:**

CMP BL, '+'  →  DoAdd  
CMP BL, '-'  →  DoSub  
CMP BL, '\*'  →  DoMul  
CMP BL, '/'  →  DoDiv  
CMP BL, '^'  →  DoXor

#### **DoAdd**

MOV AX, numA  
ADD AX, numB  
PUSHF              ; save flags before any other instruction changes them  
POP savedFlags  
JNO Add\_NoOvf      ; if OF=0, skip overflow warning

Displays result via `ShowAllBases`, then flag state via `PrintFlags`.

#### **DoSub**

MOV AX, numA  
SUB AX, numB  
PUSHF  
POP savedFlags  
JNO Sub\_NoOvf      ; overflow check (MOD 2\)  
TEST savedFlags, 0001h  ; CF check for negative result (MOD 5\)

If `CF=1` after SUB, the result wrapped around (borrow occurred). The raw bit pattern in `AX` is the 2's complement representation of the negative value and is displayed in binary.

#### **DoMul**

Uses repeated addition via the `LOOP` instruction instead of the `MUL` opcode, to pedagogically show that multiplication is repeated addition:

MOV CX, numB       ; loop counter  
XOR AX, AX         ; accumulator \= 0  
CMP CX, 0  
JE  MulDone        ; guard against 0 (MOD 6\)  
MulLoop:  
    ADD AX, numA  
    LOOP MulLoop

#### **DoDiv**

Uses repeated subtraction. Each successful subtraction increments the quotient counter. The remainder is whatever is left in `AX` when `AX < BX`:

XOR CX, CX         ; quotient \= 0  
DivLoop:  
    CMP AX, BX  
    JB  DivDone    ; if AX \< BX, stop  
    SUB AX, BX  
    INC CX  
    JMP DivLoop  
; CX \= quotient, AX \= remainder

Checks for divide-by-zero before starting.

#### **DoXor (MOD 4\)**

Reads second operand as a **hex mask** rather than decimal, then applies `XOR`:

MOV AX, numA  
XOR AX, numB       ; flip bits where mask=1, keep where mask=0

Result displayed in Binary and Hex to show bit-level effect.

---

### **5.6 ShowAllBases**

Helper procedure. Prints `AX` as Decimal, Binary, and Hexadecimal with labels. Uses `PUSH`/`POP` to preserve `AX` across multiple print calls.

---

### **5.7 PrintFlags (MOD 1\)**

Reads `savedFlags` (which was populated by `PUSHF` \+ `POP savedFlags`) and displays the state of four CPU flags.

**Flag bit positions in the 16-bit flag register:**

| Flag | Bit | Mask | Meaning |
| ----- | ----- | ----- | ----- |
| CF | 0 | `0001h` | Carry — unsigned overflow or borrow |
| ZF | 6 | `0040h` | Zero — result was zero |
| SF | 7 | `0080h` | Sign — result MSB is 1 (negative) |
| OF | 11 | `0800h` | Overflow — signed overflow occurred |

**Technique:** Each flag is tested with `TEST AX, mask`. If the bit is set, `ZF=0` and `JNZ` fires (print '1'). If the bit is clear, `ZF=1` and falls through to print '0'.

---

### **5.8 PrintBinary**

Prints `AX` as a 16-bit binary string with nibble spacing.

**Algorithm:**

MOV CX, 16  
PB\_Loop:  
    ROL BX, 1       ; rotate MSB into Carry Flag  
    JC  PB\_One      ; if CF=1, current bit is 1  
    ; else print '0'  
    ; spacing: every 4 bits, print a space  
    LOOP PB\_Loop

`ROL` (Rotate Left) shifts all bits left by 1, and the outgoing MSB wraps into the Carry Flag. This extracts each bit from high to low, one at a time.

---

### **5.9 PrintHex**

Prints `AX` as a 4-digit hexadecimal string (e.g., `001Fh`).

**Algorithm:** Manually extracts each of the 4 nibbles using `SHR 4` (shift right 4 \= divide by 16\) and `AND 0Fh` (mask lower nibble):

High byte → high nibble (BH \>\> 4\)  
High byte → low  nibble (BH & 0Fh)  
Low  byte → high nibble (BL \>\> 4\)  
Low  byte → low  nibble (BL & 0Fh)

Each nibble is passed to `NibbleToASCII` which converts 0–9 to `'0'–'9'` and 10–15 to `'A'–'F'`.

---

### **5.10 PrintDecimal**

Prints `AX` as unsigned decimal using a divide-by-10 loop with a stack to reverse digit order:

PD\_Divide:  
    XOR DX, DX  
    DIV BX          ; AX=quotient, DX=remainder (one digit)  
    PUSH DX         ; push digit onto stack  
    INC CX  
    CMP AX, 0  
    JNE PD\_Divide  
PD\_Print:  
    POP DX  
    ADD DL, '0'     ; convert to ASCII  
    INT 21h (AH=2)  
    LOOP PD\_Print

---

### **5.11 ReadDecimal**

Reads decimal digits from keyboard until Enter (`0Dh`). Each new digit: multiply running total by 10, add the new digit.

; per digit:  
MOV AX, BX       ; load running total  
MUL CX            ; AX \= BX \* 10  
MOV BX, AX  
ADD BX, new\_digit

Input validation: ignores any character outside `'0'–'9'`.

---

### **5.12 ReadBinary**

Reads '0' and '1' characters. Builds the value by shifting left on each valid bit:

SHL BX, 1         ; make room for next bit  
OR  BX, 1         ; set bit 0 (only for '1')

---

### **5.13 ReadHex**

Reads hex characters (0–9, A–F, a–f). Normalizes lowercase to uppercase (`SUB AL, 20h`), then converts to 0–15 nibble value. Builds result by shifting left 4 bits per character:

SHL BX, 4         ; shift existing value left by one nibble  
ADD BX, AX        ; add new nibble

---

### **5.14 Utility Procedures**

| Procedure | Description |
| ----- | ----- |
| `PrintStr` | `INT 21h AH=9` — prints `'$'`\-terminated string from `DX` |
| `ClearScreen` | `INT 21h AH=2, DL=0Ch` — sends form-feed character to clear screen |
| `WaitKey` | Prints "Press any key" message, then waits for one keypress |
| `NibbleToASCII` | Converts 0–15 in `DL` to corresponding ASCII hex character |

---

## **6\. INT 21h Services Summary**

| AH Value | Service | Usage in This Program |
| ----- | ----- | ----- |
| `01h` | Read character (echo) | Menu input, operator input, wait key |
| `02h` | Write character | Printing individual digits and characters |
| `09h` | Print string (`$`\-terminated) | All string/label output |
| `4Ch` | Terminate program | Option 5 (Exit) |

---

## **7\. Modifications Detail**

### **MOD 1 — Flag Inspector (Week 4\)**

**What:** After every arithmetic operation, `PUSHF` saves the CPU flag register into `savedFlags`. `PrintFlags` then reads this value and displays CF, ZF, SF, OF.  
 **Why:** The flag register cannot be read directly like a normal register; `PUSHF` is required to transfer it to memory/stack first.

### **MOD 2 — Overflow Warning (Week 4\)**

**What:** After ADD and SUB, `JNO` (Jump if No Overflow) checks `OF`. If `OF=1`, the result exceeded the signed 16-bit range (−32768 to 32767).  
 **Why:** Distinguishes signed overflow (wrong result for signed arithmetic) from carry (unsigned overflow). Important for detecting silent correctness bugs.

### **MOD 3 — Even/Odd Parity Check (Week 6\)**

**What:** `TEST AX, 1` is used in all three converter options immediately after reading input.  
 **Why:** `TEST` is non-destructive — it sets flags based on `AX AND 1` but does not change `AX`. Bit 0 of any integer determines parity: 0 \= even, 1 \= odd.

### **MOD 4 — XOR Bit-Toggle (Week 6\)**

**What:** Adds `^` as a fifth operator. Second operand is read as a hex mask. `XOR AX, numB` toggles the specific bits indicated by the mask.  
 **Why:** Demonstrates practical use of XOR — bits where mask=1 are flipped, bits where mask=0 are unchanged.

### **MOD 5 — 2's Complement Display (Week 1 concept, applied late)**

**What:** In subtraction, if `CF=1` (borrow occurred, meaning result is negative), the program prints the result's binary pattern with a 2's complement label.  
 **Why:** The 8086 stores negative results in 2's complement form. The wrapped bit pattern in `AX` is already the 2's complement; displaying it reinforces this concept.

### **MOD 6 — Multiplication Zero Guard (Polish)**

**What:** Added `CMP CX, 0 / JE MulDone` before the `MulLoop` in repeated-addition multiplication.  
 **Why:** Without the guard, `LOOP` with `CX=0` would execute 65536 times (CX wraps from 0 to FFFFh). The guard prevents this incorrect behavior.

---

## **8\. Limitations and Scope**

| Constraint | Detail |
| ----- | ----- |
| Input range | Decimal input: 0–9999; Hex input: 0000–FFFF; Binary: up to 16 bits |
| Integer only | No floating-point arithmetic |
| Unsigned division | Division uses unsigned repeated subtraction; negative dividends not supported |
| Multiplication speed | Repeated addition is O(numB) — slower than the `MUL` instruction for large values |
| Screen clearing | Uses form-feed (`0Ch`) via `INT 21h AH=2`; behavior may vary by emulator |

---

## **9\. Build & Run Instructions**

**Requirements:** emu8086 v4.x (Windows)

1. Open emu8086  
2. **File → Open** → select `calculator.asm`  
3. Press **F5** or click **Compile**  
4. Press **F9** or click **Run**  
5. Enter choices via keyboard in the emulator console

To step through for debugging: use **Step** (F8) or **Step Over** to observe register and flag changes after each instruction.

---

*Documentation generated for CS-530 COAL Semester Project.*

