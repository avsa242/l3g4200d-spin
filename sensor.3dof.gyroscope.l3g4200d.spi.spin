{
    --------------------------------------------
    Filename: sensor.3dof.gyroscope.l3g4200d.spi.spin
    Author:
    Description:
    Copyright (c) 2019
    Started Nov 27, 2019
    Updated Nov 29, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI transaction bits
    R           = 1 << 7                                            ' ORd with reg # to indicate a read transaction
    MS          = 1 << 6                                            ' ORd with reg # to indicate auto address increment (multi-byte transfers)

' High-pass filter modes
    #0, HPF_NORMAL_RES, HPF_REF, HPF_NORMAL, HPF_AUTO_RES

' Operation modes
    #0, POWERDOWN, SLEEP, NORMAL

' Interrupt pin active states
    #0, INTLVL_LOW, INTLVL_HIGH

VAR

    long _gyro_cnts_per_lsb
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
            _CS := CS_PIN
            _MOSI := MOSI_PIN
            _MISO := MISO_PIN
            _SCK := SCK_PIN

            io.High (_CS)
            io.Output (_CS)
            time.MSleep (10)

            if DeviceID == $D3                                  'Is this actually an L3G4200D?
                return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    spi.stop

PUB Defaults

    GyroScale(250)

PUB DataOverflowed
' Indicates previously acquired data has been overwritten
'   Returns: TRUE (-1) if data has overflowed/been overwritten, FALSE otherwise
    result := $00
    readReg(core#STATUS_REG, 1, @result)
    result := (result >> core#FLD_ZYXOR) & %1
    result := result * TRUE

PUB DataReady | tmp
' Indicates data is ready
'   Returns: TRUE (-1) if data ready, FALSE otherwise
    tmp := $00
    readReg(core#STATUS_REG, 1, @tmp)
    tmp := (tmp >> core#FLD_ZYXDA) & %1
    return tmp == 1

PUB DeviceID
' Read Device ID (who am I)
'   Known values: $D3
    result := $00
    readReg(core#WHO_AM_I, 1, @result)

PUB GyroData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read gyroscope data
    bytefill(@tmp, $00, 8)
    readReg(core#OUT_X_L, 6, @tmp)

    long[ptr_x] := ~~tmp.word[0]
    long[ptr_y] := ~~tmp.word[1]
    long[ptr_z] := ~~tmp.word[2]

PUB GyroDPS(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read gyroscope data, calculated
'   Returns: Angular rate in millionths of a degree per second
    bytefill(@tmp, $00, 8)
    readReg(core#OUT_X_L, 6, @tmp)
    long[ptr_x] := (~~tmp.word[0] * _gyro_cnts_per_lsb)
    long[ptr_y] := (~~tmp.word[1] * _gyro_cnts_per_lsb)
    long[ptr_z] := (~~tmp.word[2] * _gyro_cnts_per_lsb)

PUB GyroScale(dps) | tmp
' Set gyro full-scale range, in degrees per second
'   Valid values: 250, 500, 2000
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CTRL_REG4, 1, @tmp)
    case dps
        250, 500, 2000:
            dps := lookdownz(dps: 250, 500, 2000) << core#FLD_FS
            _gyro_cnts_per_lsb := lookupz(dps >> core#FLD_FS: 8_750, 17_500, 70_000)
        OTHER:
            tmp := (tmp >> core#FLD_FS) & core#BITS_FS
            result := lookupz(tmp: 250, 500, 2000)
            return

    tmp &= core#MASK_FS
    tmp := (tmp | dps)
    writeReg(core#CTRL_REG4, 1, @tmp)

PUB HighPassFilterFreq(freq) | tmp
' Set high-pass filter frequency
    tmp := $00
    readReg(core#CTRL_REG2, 1, @tmp)
    case OutputDataRate(-2)
        100:
            case freq
                8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01:
                    freq := lookdownz(freq: 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01) << core#FLD_HPCF
                OTHER:
                    tmp := (tmp >> core#FLD_HPCF) & core#BITS_HPCF
                    result := lookupz(tmp: 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01)
                    return

        200:
            case freq
                15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02:
                    freq := lookdownz(freq: 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02) << core#FLD_HPCF
                OTHER:
                    tmp := (tmp >> core#FLD_HPCF) & core#BITS_HPCF
                    result := lookupz(tmp: 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02)
                    return

        400:
            case freq
                30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05:
                    freq := lookdownz(freq: 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05) << core#FLD_HPCF
                OTHER:
                    tmp := (tmp >> core#FLD_HPCF) & core#BITS_HPCF
                    result := lookupz(tmp: 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05)
                    return

        800:
            case freq
                56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10:
                    freq := lookdownz(freq: 56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10) << core#FLD_HPCF
                OTHER:
                    tmp := (tmp >> core#FLD_HPCF) & core#BITS_HPCF
                    result := lookupz(tmp: 56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10)
                    return

    tmp &= core#MASK_HPCF
    tmp := (tmp | freq)
    writeReg(core#CTRL_REG2, 1, @tmp)

PUB HighPassFilterMode(mode) | tmp
' Set data output high pass filter mode
'   Valid values:
'       HPF_NORMAL_RES (0): Normal mode (reset reading HP_RESET_FILTER) XXX - clarify/expand
'       HPF_REF (1): Reference signal for filtering
'       HPF_NORMAL (2): Normal
'       HPF_AUTO_RES (3): Autoreset on interrupt
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CTRL_REG2, 1, @tmp)
    case mode
        HPF_NORMAL_RES, HPF_REF, HPF_NORMAL, HPF_AUTO_RES:
            mode <<= core#FLD_HPM
        OTHER:
            result := (tmp >> core#FLD_HPM) & core#BITS_HPM
            return

    tmp &= core#MASK_HPM
    tmp := (tmp | mode)
    writeReg(core#CTRL_REG2, 1, @tmp)

PUB Int1Mask(func_mask) | tmp
' Set interrupt/function mask for INT1 pin
'   Valid values:
'       Bit 10   10
'           ||   ||
'    Range %00..%11
'       Bit 1: Interrupt enable (*0: Disable, 1: Enable)
'       Bit 0: Boot status (*0: Disable, 1: Enable)
    tmp := $00
    readReg(core#CTRL_REG3, 1, @tmp)
    case func_mask
        %00..%11:
            func_mask <<= core#FLD_INT1
        OTHER:
            result := (tmp >> core#FLD_INT1) & core#BITS_INT1
            return

    tmp &= core#MASK_INT1
    tmp := (tmp | func_mask)
    writeReg(core#CTRL_REG3, 1, @tmp)

PUB IntActiveState(state) | tmp
' Set active state for interrupts
'   Valid values: INTLVL_LOW (0), INTLVL_HIGH (1)
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CTRL_REG3, 1, @tmp)
    case state
        INTLVL_LOW, INTLVL_HIGH:
            state := ((state ^ 1) & %1) << core#FLD_H_LACTIVE
        OTHER:
            result := (((tmp >> core#FLD_H_LACTIVE) ^ 1) & %1)
            return

    tmp &= core#MASK_H_LACTIVE
    tmp := (tmp | state)
    writeReg(core#CTRL_REG3, 1, @tmp)

PUB OpMode(mode) | tmp
' Set operation mode
'   Valid values:
'       POWERDOWN (0): Power down - lowest power state
'       SLEEP (1): Sleep - sensor enabled, but X, Y, Z outputs disabled
'       NORMAL (2): Normal - active operating state
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CTRL_REG1, 1, @tmp)
    case mode
        POWERDOWN:
            tmp &= core#MASK_PD
        SLEEP:
            mode := (1 << core#FLD_PD)
            tmp &= core#MASK_XYZEN
        NORMAL:
            mode := (1 << core#FLD_PD)
            tmp &= core#MASK_PD
        OTHER:
            result := (tmp >> core#FLD_PD) & %1
            return

    tmp := (tmp | mode)
    writeReg(core#CTRL_REG1, 1, @tmp)

PUB OutputDataRate(Hz) | tmp
' Set rate of data output, in Hz
'   Valid values: 100, 200, 400, 800
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CTRL_REG1, 1, @tmp)
    case Hz
        100, 200, 400, 800:
            Hz := lookdownz(Hz: 100, 200, 400, 800) << core#FLD_DR
        OTHER:
            tmp := (tmp >> core#FLD_DR) & core#BITS_DR
            result := lookupz(tmp: 100, 200, 400, 800)
            return

    tmp &= core#MASK_DR
    tmp := (tmp | Hz)
    writeReg(core#CTRL_REG1, 1, @tmp)

PRI readReg(reg, nr_bytes, buff_addr) | tmp
' Read nr_bytes from register 'reg' to address 'buff_addr'

' Handle quirky registers on a case-by-case basis
    case reg
        $0F, $20..$27, $2E..$38:
        $28..$2D:
            reg |= MS
        OTHER:
            return FALSE
    reg |= R
    io.Low (_CS)
    spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)

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
