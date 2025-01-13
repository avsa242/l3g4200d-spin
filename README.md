# l3g4200d-spin 
---------------

This is a P8X32A/Propeller driver object for the STMicroelectronics L3G4200D 3DoF Gyroscope

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.


## Salient Features

* I2C connection at ~30kHz (P1: SPIN I2C) 400kHz (P1: PASM I2C, P2)
* SPI connection (3 or 4-wire) at up to 1MHz
* Optional alternate I2C address
* Read Gyroscope data (raw, or calculated in micro-degrees per second)
* Read flags for data ready or overrun
* Set operation mode (powerdown, sleep, normal/active)
* Set output data rate
* Set interrupt mask (int1 & int2), active pin state, output type
* Configure high-pass, low-pass filters
* Enable individual axes
* Manually or automatically set bias offsets/zero rate level


## Requirements

P1/SPIN1:
* spin-standard-library
* P1/SPIN1: 1 extra core/cog for the PASM I2C/SPI engine (none if bytecode engine is used)
* sensor.gyroscope.common.spinh (provided by spin-standard-library)

P2/SPIN2:
* p2-spin-standard-library
* sensor.gyroscope.common.spin2h (provided by p2-spin-standard-library)


## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.9.4)       | Bytecode     | OK                    |
| P1        | SPIN1    | FlexSpin (6.9.4)       | Native/PASM  | OK                    |
| P2        | SPIN2    | FlexSpin (6.9.4)       | NuCode       | Some runtime issues   |
| P2        | SPIN2    | FlexSpin (6.9.4)       | Native/PASM2 | OK                    |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)


## Limitations

* TBD

