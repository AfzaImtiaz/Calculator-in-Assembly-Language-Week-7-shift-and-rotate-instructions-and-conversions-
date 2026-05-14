# 🔢 Multi-Base Calculator & Number Converter
### COAL Semester Project — 8086 Assembly Language (emu8086)

> **Course:** Computer Organization & Assembly Language (CS-530)  
> **Tool:** emu8086 Emulator  
> **Architecture:** Intel 8086 (16-bit)

---

## 📌 Overview

A fully interactive, menu-driven **number base converter and arithmetic calculator** written in 8086 Assembly Language. The program supports conversion between Decimal, Binary, and Hexadecimal, and performs arithmetic operations with real-time CPU flag inspection after every result.

Built as a COAL semester project with **6 incremental modifications** added over the course of the semester to demonstrate progressive mastery of assembly concepts.

---

## ✨ Features

### 🔄 Base Conversion
| Option | Function |
|--------|----------|
| `[1]` | Decimal → Binary & Hex |
| `[2]` | Binary → Decimal & Hex |
| `[3]` | Hex → Decimal & Binary |

### 🧮 Calculator Operations
| Operator | Operation | Method Used |
|----------|-----------|-------------|
| `+` | Addition | `ADD` instruction |
| `-` | Subtraction | `SUB` instruction |
| `*` | Multiplication | Repeated `ADD` via `LOOP` |
| `/` | Division | Repeated `SUB` (quotient + remainder) |
| `^` | XOR Bit-Toggle | `XOR` with hex mask input |

### 🔬 Educational Modifications (Week-by-Week)
| MOD | Week | Feature |
|-----|------|---------|
| MOD 1 | Week 4 | Flag Inspector: displays `CF`, `ZF`, `SF`, `OF` after every result |
| MOD 2 | Week 4 | Overflow detection warning (`OF=1`) on ADD and SUB |
| MOD 3 | Week 6 | `TEST` instruction: even/odd parity check on input |
| MOD 4 | Week 6 | XOR sub-option (`^`) for bitwise bit-toggling |
| MOD 5 | Week 1 | Signed/2's complement display when SUB result is negative (`CF=1`) |
| MOD 6 | Polish | MUL loop properly guarded against `numB = 0` |

---

## 🛠️ How It Works — Key Concepts

### Flag Inspection (MOD 1)
After every operation, `PUSHF` saves the 16-bit flag register to memory (`savedFlags`). The `PrintFlags` procedure then uses `TEST` to isolate individual bits:

```asm
TEST AX, 0001h   ; CF — bit 0
TEST AX, 0040h   ; ZF — bit 6
TEST AX, 0080h   ; SF — bit 7
TEST AX, 0800h   ; OF — bit 11
```

### Binary Printing
Uses `ROL` to shift the MSB into the Carry Flag, then prints `1` or `0` based on `JC`:
```asm
ROL  BX, 1      ; MSB → Carry Flag
JC   PB_One     ; if CF=1, print '1', else print '0'
```

### Hex Printing
Uses `SHR 4` to isolate each nibble, then converts to ASCII via `NibbleToASCII`:
```asm
MOV  DL, BH
SHR  DL, 4       ; isolate high nibble
CALL NibbleToASCII
```

### Even/Odd Check (MOD 3)
Non-destructive `TEST` checks bit 0 without modifying the register:
```asm
TEST AX, 1      ; if bit0=0 → ZF=1 (even), if bit0=1 → ZF=0 (odd)
JNZ  ODD_Label
```

### 2's Complement Display (MOD 5)
When subtraction sets `CF=1` (borrow occurred → result is negative), the raw bit pattern in `AX` is already the 2's complement representation and is displayed directly in binary.

---

## 📂 File Structure

```
📁 coal-calculator/
├── calculator.asm     ← Main source file (all code)
└── README.md          ← This file
```

---

## ▶️ How to Run

### Requirements
- [emu8086](https://emu8086-microprocessor-emulator.en.softonic.com/) (v4.x recommended)

### Steps
1. Open **emu8086**
2. Go to **File → Open** and select `calculator.asm`
3. Click **Compile** (F5) or press the compile button
4. Click **Run** or step through with the emulator
5. Interact via the on-screen menu

> ℹ️ Before running, fill in your **Name** and **Roll Number** in the header comments at the top of the file.

---

## 🔭 Concepts Demonstrated

- `.MODEL SMALL`, `.STACK`, `.DATA`, `.CODE` segment structure
- `INT 21h` services: AH=1 (read char), AH=2 (write char), AH=9 (print string), AH=4Ch (exit)
- `PUSHF` / `POPF` for flag register access
- `ROL`, `SHR`, `SHL` shift/rotate operations
- `TEST` for non-destructive bit checking
- `XOR` for bitwise operations and bit toggling
- `LOOP` for repeated operations (multiply/divide)
- Stack discipline with `PUSH` / `POP`
- Segment:offset addressing with `LEA` + `DX`
- ASCII/number conversion routines

---

## 📋 Limitations

- Decimal input capped at **0–9999** (16-bit unsigned arithmetic)
- Multiplication via repeated addition: accurate but slow for large `numB`
- Division is **unsigned only** (uses repeated subtraction)
- No floating point support

---

## 👤 Author

**Name:** *(Fill in your name)*  
**Roll #:** *(Fill in your roll number)*  
**Course:** CS-530 — Computer Organization & Assembly Language  
**Instructor:** H.M. Faisal  
**University:** UIIT, PMAS Arid Agriculture University Rawalpindi

---

## 📜 License

This project was submitted as academic coursework. Free to reference for educational purposes.
