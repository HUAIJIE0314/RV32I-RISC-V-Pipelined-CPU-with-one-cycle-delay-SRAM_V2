# RISC-V 5-stage Pipelined CPU (IM/DM are one cycle delay output SRAM, improved by v1)
## Instruction set : RV32IM(45 instructions)(M-extension instruction only include Multiplication)
---
- Branch calculation is at ID Stage
### Simulation ALL Pass
|  prog#  | cycles |
|:-------:|:------:|
|  prog0  |  6243  |
|  prog4  |  6012  |

### Synthesis result
- Area:5831669
- timing:6.82ns, slack=0.0

- Improvement
  - Share computation resource (Adder)
  - Optimize the Controller
