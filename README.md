# l3g4200d-spin 
---------------

This is a P8X32A/Propeller driver object for the STMicroelectronics L3G4200D 3DoF Gyroscope

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at ~30kHz, SPI connection at up to 1MHz
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
* P1/SPIN1: 1 extra core/cog for the PASM SPI driver

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FlexSpin (tested with 5.3.3-beta)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Due to issues with the PASM I2C engine, only a bytecode SPIN PASM engine is currently
implemented for I2C support (*P1 only - P2 I2C is fully functional*)

## TODO
- [x] Add bias/offset support
- [x] Add calibration support
- [ ] High-pass filter mode operation needs clarification on function/purpose
- [x] Add I2C support
- [x] Port to P2/SPIN2

