{
    --------------------------------------------
    Filename: L3G4200D-Demo.spin
    Author: Jesse Burt
    Description: Demo app for the L3G4200D driver
    Copyright (c) 2019
    Started Nov 27, 2019
    Updated Dec 17, 2019
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
    int     : "string.integer"
    gyro    : "sensor.gyroscope.3dof.l3g4200d.spi"

VAR

    long _overruns
    byte _ser_cog

PUB Main

    Setup
    gyro.OpMode (2)
    ser.str(string("opmode: "))
    ser.dec (gyro.opmode(-2))
    ser.newline

    gyro.GyroAxisEnabled(%100)
    ser.str(string("axis enabled: "))
    ser.bin(gyro.gyroaxisenabled(-2), 3)
    ser.newline

    gyro.OutputDataRate (100)
    ser.str(string("output data rate: "))
    ser.dec(gyro.outputdatarate(-2))
    ser.newline

    gyro.GyroScale (2000)
    ser.Str (string("gyro scale "))
    ser.Dec (gyro.gyroscale(-2))

    repeat
        ser.Position (0, 10)
'        GyroRaw
        GyroCalc
'        ser.Dec ( gyro.Temperature)

PUB GyroCalc | x, y, z, divisor
' Display gyroscope data, calculated to degrees per second
    divisor := 1_000_000
    repeat until gyro.DataReady                     ' Wait until there's new data available

    if gyro.DataOverrun                             ' If we're too slow to read/can't keep up,
        _overruns++                                 '   increment this counter

    gyro.GyroDPS (@x, @y, @z)                       ' Read the data into the local variables

    ser.Str (string("X: "))
    Frac(x, divisor)
    ser.NewLine
    
    ser.Str (string("Y: "))
    Frac(y, divisor)
    ser.NewLine

    ser.Str (string("Z: "))
    Frac(z, divisor)
    ser.NewLine

    ser.Str (string("Overruns: "))
    ser.Str (int.DecPadded (_overruns, 5))

PUB GyroRaw | x, y, z
' Display gyroscope raw data
    repeat until gyro.DataReady                     ' Wait until new data is available

    if gyro.DataOverrun                             ' If we're too slow to read/can't keep up,
        _overruns++                                 '   increment this counter

    gyro.GyroData (@x, @y, @z)                      ' Read the data into the local variables

    ser.Str (string("X: "))
    ser.Str (int.DecPadded (x, 6))
    ser.NewLine
    
    ser.Str (string("Y: "))
    ser.Str (int.DecPadded (y, 6))
    ser.NewLine

    ser.Str (string("Z: "))
    ser.Str (int.DecPadded (z, 6))
    ser.NewLine

    ser.NewLine
    ser.Str (string("Overruns: "))
    ser.Str (int.DecPadded (_overruns, 5))

PUB Frac(scaled, divisor) | whole[4], part[4], places, tmp
' Display a scaled up number in its natural form - scale it back down by divisor
    whole := scaled / divisor
    tmp := divisor
    places := 0

    repeat
        tmp /= 10
        places++
    until tmp == 1
    part := int.DecZeroed(||(scaled // divisor), places)

    ser.Dec (whole)
    ser.Char (".")
    ser.Str (part)
    ser.Chars (32, 5)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    time.MSleep(100)
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
