# Async-FIFO
# Asynchronous FIFO – Functional Verification using SystemVerilog

## Overview
This project implements and verifies a **dual-clock Asynchronous FIFO** using **SystemVerilog**.  
The FIFO is designed using **Gray-code pointer synchronization** to safely transfer data between
independent write and read clock domains.  

A **class-based, transaction-level verification environment** is developed from scratch to validate
FIFO functionality, boundary conditions, and protocol correctness using constrained-random stimulus,
functional coverage, and assertions.

---

## Asynchronous FIFO Architecture

### Motivation
In multi-clock SoC designs, data often needs to be transferred between unrelated clock domains.
An asynchronous FIFO is a common solution, but incorrect pointer synchronization can lead to:
- Data corruption
- Overflow / underflow
- Metastability-related failures

This FIFO follows the widely adopted **Cliff Cummings asynchronous FIFO architecture**.
<img width="1024" height="578" alt="image" src="https://github.com/user-attachments/assets/a739e963-852e-47db-8da5-f66fca6a8f5a" />

---

### FIFO Design Details

- **Depth**: \(2^{ADDR\_WIDTH}\)
- **Data Width**: Parameterized
- **Write Clock Domain**: `wr_clk`
- **Read Clock Domain**: `rd_clk`
- **Memory**: Dual-port RAM (modeled behaviorally)

#### Pointer Management
- Binary read and write pointers with **extra MSB** to distinguish full vs empty
- Binary pointers converted to **Gray code**
- Gray-code pointers synchronized across clock domains using **2-flop synchronizers**

#### Flag Generation
- **Empty** asserted when synchronized write pointer equals read pointer
- **Full** asserted when write pointer equals read pointer with inverted MSBs

This ensures safe operation without assuming any phase or frequency relationship
between the two clocks.

---

---

## Signal Definitions

The FIFO interface and DUT signals are defined as follows, based directly on the implementation.

### Clock & Reset Signals

| Signal     | Direction | Description |
|-----------|-----------|-------------|
| `wr_clk`  | Input     | Write clock for FIFO write domain |
| `rd_clk`  | Input     | Read clock for FIFO read domain |
| `wr_rst_n`| Input     | Active-low reset for write domain logic |
| `rd_rst_n`| Input     | Active-low reset for read domain logic |

Each clock domain has an independent reset, consistent with asynchronous FIFO design practices.

---

### Data & Control Signals

| Signal | Width | Direction | Description |
|------|-------|-----------|-------------|
| `din`  | 8-bit | Input  | Data input written into FIFO |
| `dout` | 8-bit | Output | Data output read from FIFO |
| `wr_en`| 1-bit | Input  | Write enable signal |
| `rd_en`| 1-bit | Input  | Read enable signal |

Writes occur on the rising edge of `wr_clk` when `wr_en` is asserted and FIFO is not full.  
Reads occur on the rising edge of `rd_clk` when `rd_en` is asserted and FIFO is not empty.

---

### Status Flags

| Signal | Direction | Description |
|-------|-----------|-------------|
| `full`  | Output | Indicates FIFO is full; further writes are blocked |
| `empty` | Output | Indicates FIFO is empty; further reads are blocked |

- `full` is generated in the write clock domain using synchronized read pointer comparison  
- `empty` is generated in the read clock domain using synchronized write pointer comparison  

---

### Internal Pointer Signals (Design-Level)

| Signal | Description |
|------|-------------|
| `wptr_bin`, `rptr_bin` | Binary write/read pointers with extra MSB |
| `wptr_gray`, `rptr_gray` | Gray-coded pointers for CDC |
| `wq1_rptr`, `wq2_rptr` | Read pointer synchronized into write domain |
| `rq1_wptr`, `rq2_wptr` | Write pointer synchronized into read domain |

These internal signals are not exposed externally but are critical to safe clock-domain crossing and correct full/empty flag generation.

---

## Constrained Random Verification

- Randomized write and read enables
- Distribution constraints favor back-to-back bursts
- Exercises:
  - Simultaneous read/write operations
  - FIFO full and empty transitions
  - Burst and idle scenarios

This approach increases coverage of corner cases compared to directed testing.

---

## Functional Coverage

Functional coverage is used to **measure verification completeness**, not just simulation activity.

### Coverage Model Includes:
- FIFO `full` assertion
- FIFO `empty` assertion
- Read enable activity
- Write enable activity
- Cross coverage:
  - Write attempts when FIFO is full
  - Read attempts when FIFO is empty
  - Simultaneous read/write operations

Coverage is sampled from the monitor and reported at the end of simulation.

---

## Assertion-Based Verification (SVA)

Concurrent assertions are implemented to validate protocol correctness in each clock domain:

- **No write when FIFO is full**
- **No read when FIFO is empty**

Assertions are clocked independently for write and read domains and disabled during reset,
making them safe for asynchronous operation.


---
<img width="1879" height="527" alt="image" src="https://github.com/user-attachments/assets/49b76a04-4ea8-4f77-aafa-d88804551971" />


---

## Author
Verification project developed for learning and portfolio demonstration purposes.
