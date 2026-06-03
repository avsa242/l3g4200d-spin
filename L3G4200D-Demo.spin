{
----------------------------------------------------------------------------------------------------
    Filename:       L3G4200D-Demo.spin
    Description:    Demo of the L3G4200D driver
        * 3DoF data output
    Author:         Jesse Burt
    Started:        Nov 27, 2019
    Updated:        Jun 3, 2026
    Copyright (c) 2026 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}
' Uncomment one of the pairs of lines below for alternate connectivity options.
' The default if nothing is specified, is a PASM-based I2C engine
' NOTE: If using I2C, the SDA and SDO pins must be connected together, and CS should be tied high.

' Uncomment the two lines below to use SPI
'#define L3G4200D_SPI
'#pragma exportdef(L3G4200D_SPI)

' Uncomment the two lines below to use SPI (bytecode-based engine)
'#define L3G4200D_SPI_BC
'#pragma exportdef(L3G4200D_SPI_BC)

' Uncomment the two lines below to use I2C (bytecode-based engine)
'#define L3G4200D_I2C_BC
'#pragma exportdef(L3G4200D_I2C_BC)


CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.gyroscope.3dof.l3g4200d" | {I2C} SCL=28, SDA=29, I2C_FREQ=400_000, ...
                                            {SPI} CS=0, SCK=1, MOSI=2, MISO=3
    time:   "time"


PUB main() | axis, g[3], sign

    setup()
    sensor.preset_active()

    repeat
        ser.pos_xy(0, 3)
        repeat
        until sensor.gyro_data_rdy()
        sensor.gyro_dps(@g[sensor.X_AXIS], @g[sensor.Y_AXIS], @g[sensor.Z_AXIS])
        ser.str(@"Gyro (dps): ")
        repeat axis from sensor.X_AXIS to sensor.Z_AXIS
            if ( g[axis] < 0 )
                sign := "-"
            else
                sign := " "
            ser.printf(@"%c%d.%06.6d     ", sign, ...
                                            abs(g[axis] / 1_000_000), ...
                                            abs(g[axis] // 1_000_000) )
        if ( ser.getchar_noblock() == "c" )
            cal_gyro()


PUB cal_gyro()
' Calibrate the gyroscope
    ser.pos_xy(0, 3)
    ser.str(@"Calibrating gyroscope...")
    ser.clear_line()
    sensor.calibrate_gyro()
    ser.pos_xy(0, 3)
    ser.clear_line()


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"L3G4200D driver started")
    else
        ser.strln(@"L3G4200D driver failed to start - halting")
        repeat



DAT
{
Copyright 2026 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

