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

## Verification Environment Architecture

The verification environment is **class-based** and built without UVM to demonstrate
core verification concepts clearly.

### Components

- **Transaction**
  - Encapsulates FIFO stimulus and observed outputs
- **Generator**
  - Produces constrained-random read/write transactions
- **Driver**
  - Drives write-side and read-side signals on independent clock domains
- **Monitor**
  - Samples DUT signals and collects functional coverage
- **Scoreboard**
  - Uses a reference queue to check data integrity
- **Interface**
  - Encapsulates DUT signals and protocol assertions

All components communicate using **SystemVerilog mailboxes**.

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

## Simulation & Tools

- **Language**: SystemVerilog
- **Verification Style**: OOP, transaction-based
- **Assertions**: SystemVerilog Assertions (SVA)
- **Functional Coverage**: Covergroups and cross coverage
- **Simulator**: Aldec Riviera-PRO (via EDA Playground)

---

## Key Learning Outcomes

- Understanding of asynchronous FIFO design principles
- Practical handling of clock-domain crossings (CDC)
- Building reusable class-based verification environments
- Applying constrained random stimulus effectively
- Using functional coverage to guide verification
- Writing safe, clock-domain-specific assertions

---

## Notes

This project focuses on **functional correctness and verification methodology**.
Full regression management, code coverage, and coverage closure workflows are
typically handled using industrial tools in large-scale environments.

---

## Author
Verification project developed for learning and portfolio demonstration purposes.
