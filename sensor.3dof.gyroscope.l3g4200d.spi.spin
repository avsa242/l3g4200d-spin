{
    --------------------------------------------
    Filename: sensor.3dof.gyroscope.l3g4200d.spi.spin
    Author:
    Description:
    Copyright (c) 2019
    Started Nov 27, 2019
    Updated Nov 27, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI transaction bits
    R           = 1 << 7                                            ' ORd with reg # to indicate a read transaction
    MS          = 1 << 6                                            ' ORd with reg # to indicate auto address increment (multi-byte transfers)

VAR

    byte _CS, _MOSI, _MISO, _SCK

OBJ

    spi : "com.spi.4w"
    core: "core.con.l3g4200d"
    time: "time"
    io  : "io"

PUB Null
''This is not a top-level object

PUB Start(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN) : okay

    okay := Startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, core#CLK_DELAY, core#CPOL)

PUB Startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, SCK_DELAY, SCK_CPOL): okay
    if SCK_DELAY => 1 and lookdown(SCK_CPOL: 0, 1)
        if okay := spi.start (SCK_DELAY, SCK_CPOL)              'SPI Object Started?
            time.MSleep (5)
            _CS := CS_PIN
            _MOSI := MOSI_PIN
            _MISO := MISO_PIN
            _SCK := SCK_PIN

            io.High (_CS)
            io.Output (_CS)

            return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    spi.stop

PUB DeviceID

    result := $00
    readReg(core#WHO_AM_I, 1, @result)

PRI readReg(reg, nr_bytes, buff_addr) | tmp
' Read nr_bytes from register 'reg' to address 'buff_addr'

' Handle quirky registers on a case-by-case basis
    case reg
        $0F, $20..$38:
        OTHER:
            return FALSE
    io.Low (_CS)
    spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg | R)

    repeat tmp from 0 to nr_bytes-1
        byte[buff_addr][tmp] := spi.SHIFTIN(_MISO, _SCK, core#MISO_BITORDER, 8)
    io.High (_CS)

PRI writeReg(reg, nr_bytes, buff_addr) | tmp
' Write nr_bytes to register 'reg' stored at buff_addr

    io.Low (_CS)
    spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)

    repeat tmp from 0 to nr_bytes-1
        spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buff_addr][tmp])

    io.High (_CS)

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
