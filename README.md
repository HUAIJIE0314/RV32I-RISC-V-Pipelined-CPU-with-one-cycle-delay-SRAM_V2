# RISC-V 5-stage Pipelined CPU (IM/DM are one cycle delay output SRAM, improved by v1)
## Instruction set : RV32I(41 instructions)
---
- Branch calculation is at ID Stage
### Simulation ALL Pass
|  prog#  | cycles |
|:-------:|:------:|
|  prog0  |  6179  |
|  prog4  |  6010  |

- Improvement
  - share computation resource (Adder)
  - Optimize the Controller
