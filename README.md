# l3g4200d-spin 
---------------

This is a P8X32A/Propeller driver object for the STMicroelectronics L3G4200D 3DoF Gyroscope

## Salient Features

* SPI connection at up to 1MHz
* Read device ID (who am i)
* Read Gyroscope data (raw, or calculated in millionths of a degree per second)
* Read flags for data ready or overrun
* Set operation mode (powerdown, sleep, normal/active)
* Set output data rate
* Set high-pass filter freq for ODR, configure high-pass filter mode
* Set interrupt mask (int1 & int2), active pin state, output type
* Enable individual axes

## Requirements

* P1/SPIN1: 1 extra core/cog for the PASM SPI driver

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)

## Limitations

* Very early in development - may malfunction, or outright fail to build

## TODO
- [ ] High-pass filter mode operation needs clarification on function/purpose
