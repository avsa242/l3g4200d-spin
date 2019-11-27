{
    --------------------------------------------
    Filename: L3G4200D-Test.spin
    Author: Jesse Burt
    Description: Test app for the L3G4200D driver
    Copyright (c) 2019
    Started Nov 27, 2019
    Updated Nov 27, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1
    CS_PIN      = 3
    SCL_PIN     = 2
    SDA_PIN     = 1
    SDO_PIN     = 0

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    io      : "io"
    gyro    : "sensor.3dof.gyroscope.l3g4200d.spi"

VAR

    byte _ser_cog

PUB Main

    Setup
    ser.Str (string("Device ID: "))
    ser.Hex (gyro.DeviceID, 8)

    FlashLED (LED, 100)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if gyro.Start (CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
        ser.Str(string("L3G4200D driver started", ser#NL))
    else
        ser.Str(string("L3G4200D driver failed to start - halting", ser#NL))
        gyro.Stop
        time.MSleep (500)
        FlashLED (LED, 500)

PUB FlashLED(led_pin, delay_ms)

    io.Output (led_pin)
    repeat
        io.Toggle (led_pin)
        time.MSleep (delay_ms)

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
