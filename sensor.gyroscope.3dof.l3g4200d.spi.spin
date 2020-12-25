{
    --------------------------------------------
    Filename: sensor.gyroscope.3dof.l3g4200d.spi.spin
    Author: Jesse Burt
    Description: Driver for the ST L3G4200D 3-axis gyroscope
    Copyright (c) 2020
    Started Nov 27, 2019
    Updated Dec 24, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Indicate to user apps how many Degrees of Freedom each sub-sensor has
'   (also imply whether or not it has a particular sensor)
    ACCEL_DOF           = 0
    GYRO_DOF            = 3
    MAG_DOF             = 0
    BARO_DOF            = 0
    DOF                 = ACCEL_DOF + GYRO_DOF + MAG_DOF + BARO_DOF

' SPI transaction bits
    R                   = 1 << 7                ' read transaction
    MS                  = 1 << 6                ' auto address increment

' High-pass filter modes
    #0, HPF_NORMAL_RES, HPF_REF, HPF_NORMAL, HPF_AUTO_RES

' Operation modes
    #0, POWERDOWN, SLEEP, NORMAL

' Interrupt pin active states
    #0, INTLVL_LOW, INTLVL_HIGH

' Interrupt pin output type
    #0, INT_PP, INT_OD

' Gyro data byte order
    #0, LSBFIRST, MSBFIRST

VAR

    long _gyro_cnts_per_lsb
    long _CS, _SCK, _MOSI, _MISO

OBJ

    spi : "com.spi.4w"
    core: "core.con.l3g4200d"
    time: "time"
    io  : "io"

PUB Null{}
' This is not a top-level object

PUB Start(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, SCK_DELAY): okay

    if SCK_DELAY => 1
        if okay := spi.start(SCK_DELAY, core#CPOL)
            longmove(@_CS, @CS_PIN, 4)          ' copy pins to hub vars
            io.high(_CS)
            io.output(_CS)
            time.msleep(10)

            if deviceid{} == core#DEVID_RESP
                return okay

    return FALSE                                ' something above failed

PUB Stop{}

    spi.stop{}

PUB Defaults{}

    blockupdateenabled(FALSE)
    databyteorder(LSBFIRST)
    fifoenabled(FALSE)
    gyroaxisenabled(%111)
    gyrodatarate(100)
    gyroopmode(POWERDOWN)
    gyroscale(250)
    highpassfilterenabled(FALSE)
    highpassfilterfreq(8_00)
    highpassfiltermode(HPF_NORMAL_RES)
    int1mask(%00)
    int2mask(%0000)
    intactivestate(INTLVL_LOW)
    intoutputtype(INT_PP)

PUB BlockUpdateEnabled(enabled) | tmp
' Enable block updates
'   Valid values:
'      *FALSE (0): Update gyro data outputs continuously
'       TRUE (-1 or 1): Pause further updates until both MSB and LSB of data have been read
'   Any other value polls the chip and returns the current setting
    tmp := 0
    readreg(core#CTRL_REG4, 1, @tmp)
    case ||(enabled)
        0, 1:
            enabled := (||(enabled) & 1) << core#BDU
        other:
            return ((tmp >> core#BDU) & 1) == 1

    tmp &= core#BDU_MASK
    tmp := (tmp | enabled)
    writereg(core#CTRL_REG4, 1, @tmp)

PUB DataByteOrder(lsb_msb_first) | tmp
' Set byte order of gyro data
'   Valid values:
'      *LSBFIRST (0), MSBFIRST (1)
'   Any other value polls the chip and returns the current setting
'   NOTE: Intended only for use when utilizing raw gyro data from GyroData method.
'       GyroDPS expects the data order to be LSBFIRST
    tmp := 0
    readreg(core#CTRL_REG4, 1, @tmp)
    case lsb_msb_first
        LSBFIRST, MSBFIRST:
            lsb_msb_first <<= core#BLE
        other:
            return (tmp >> core#BLE) & 1

    tmp &= core#BLE_MASK
    tmp := (tmp | lsb_msb_first)
    writereg(core#CTRL_REG4, 1, @tmp)

PUB DeviceID{}: id
' Read Device ID (who am I)
'   Known values: $D3
    id := 0
    readreg(core#WHO_AM_I, 1, @id)

PUB FIFOEnabled(enabled) | tmp
' Enable FIFO for gyro data
'   Valid values:
'      *FALSE (0): FIFO disabled
'       TRUE (-1 or 1): FIFO enabled
'   Any other value polls the chip and returns the current setting
    tmp := 0
    readreg(core#CTRL_REG5, 1, @tmp)
    case ||(enabled)
        0, 1:
            enabled := (||(enabled) & 1) << core#FIFO_EN
        other:
            return ((tmp >> core#FIFO_EN) & 1) == 1

    tmp &= core#FIFO_EN_MASK
    tmp := (tmp | enabled)
    writereg(core#CTRL_REG5, 1, @tmp)

PUB GyroAxisEnabled(mask) | tmp
' Enable gyroscope individual axes, by mask
'   Valid values:
'       0: Disable axis, 1: Enable axis
'       Bits %210
'             ZYX (default: %111)
'   Any other value polls the chip and returns the current setting
    tmp := 0
    readreg(core#CTRL_REG1, 1, @tmp)
    case mask
        %000..%111:
        other:
            return tmp & core#XYZEN_BITS

    tmp &= core#XYZEN_MASK
    tmp := (tmp | mask) & core#CTRL_REG1_MASK
    writereg(core#CTRL_REG1, 1, @tmp)

PUB GyroData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read gyroscope data
    bytefill(@tmp, 0, 8)
    readreg(core#OUT_X_L, 6, @tmp)

    long[ptr_x] := ~~tmp.word[0]
    long[ptr_y] := ~~tmp.word[1]
    long[ptr_z] := ~~tmp.word[2]

PUB GyroDataOverrun{}: flag
' Flag indicating previously acquired data has been overwritten
'   Returns: TRUE (-1) if data has overrun/been overwritten, FALSE otherwise
    flag := 0
    readreg(core#STATUS_REG, 1, @flag)
    return ((flag >> core#ZYXOR) & 1) == 1

PUB GyroDataRate(Hz) | tmp
' Set rate of data output, in Hz
'   Valid values: *100, 200, 400, 800
'   Any other value polls the chip and returns the current setting
    tmp := 0
    readreg(core#CTRL_REG1, 1, @tmp)
    case Hz
        100, 200, 400, 800:
            Hz := lookdownz(Hz: 100, 200, 400, 800) << core#DR
        other:
            tmp := (tmp >> core#DR) & core#DR_BITS
            return lookupz(tmp: 100, 200, 400, 800)

    tmp &= core#DR_MASK
    tmp := (tmp | Hz)
    writereg(core#CTRL_REG1, 1, @tmp)

PUB GyroDataReady{}: flag
' Flag indicates gyroscope data is ready
'   Returns: TRUE (-1) if data ready, FALSE otherwise
    flag := 0
    readreg(core#STATUS_REG, 1, @flag)
    return ((flag >> core#ZYXDA) & 1) == 1

PUB GyroDPS(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read gyroscope data, calculated
'   Returns: Angular rate in millionths of a degree per second
    bytefill(@tmp, 0, 8)
    readreg(core#OUT_X_L, 6, @tmp)
    long[ptr_x] := (~~tmp.word[0] * _gyro_cnts_per_lsb)
    long[ptr_y] := (~~tmp.word[1] * _gyro_cnts_per_lsb)
    long[ptr_z] := (~~tmp.word[2] * _gyro_cnts_per_lsb)

PUB GyroOpMode(mode) | tmp
' Set operation mode
'   Valid values:
'      *POWERDOWN (0): Power down - lowest power state
'       SLEEP (1): Sleep - sensor enabled, but X, Y, Z outputs disabled
'       NORMAL (2): Normal - active operating state
'   Any other value polls the chip and returns the current setting
    tmp := 0
    readreg(core#CTRL_REG1, 1, @tmp)
    case mode
        POWERDOWN:
            tmp &= core#PD_MASK
        SLEEP:
            mode := (1 << core#PD)
            tmp &= core#XYZEN_MASK
        NORMAL:
            mode := (1 << core#PD)
            tmp &= core#PD_MASK
        other:
            result := (tmp >> core#PD) & 1
            if tmp & core#XYZEN_BITS
                result += 1
            return

    tmp := (tmp | mode)
    writereg(core#CTRL_REG1, 1, @tmp)

PUB GyroScale(dps) | tmp
' Set gyro full-scale range, in degrees per second
'   Valid values: *250, 500, 2000
'   Any other value polls the chip and returns the current setting
    tmp := 0
    readreg(core#CTRL_REG4, 1, @tmp)
    case dps
        250, 500, 2000:
            dps := lookdownz(dps: 250, 500, 2000) << core#FS
            _gyro_cnts_per_lsb := lookupz(dps >> core#FS: 8_750, 17_500, 70_000)
        other:
            tmp := (tmp >> core#FS) & core#FS_BITS
            return lookupz(tmp: 250, 500, 2000)

    tmp &= core#FS_MASK
    tmp := (tmp | dps)
    writereg(core#CTRL_REG4, 1, @tmp)

PUB HighPassFilterEnabled(enabled) | tmp
' Enable high-pass filter for gyro data
'   Valid values:
'      *FALSE (0): High-pass filter disabled
'       TRUE (-1 or 1): High-pass filter enabled
'   Any other value polls the chip and returns the current setting
    tmp := 0
    readreg(core#CTRL_REG5, 1, @tmp)
    case ||(enabled)
        0, 1:
            enabled := (||(enabled) & 1) << core#HPEN
        other:
            return ((tmp >> core#HPEN) & 1) == 1

    tmp &= core#HPEN_MASK
    tmp := (tmp | enabled)
    writereg(core#CTRL_REG5, 1, @tmp)

PUB HighPassFilterFreq(freq) | tmp
' Set high-pass filter frequency, in Hz
'    Valid values:
'       If ODR=100Hz: *8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01
'       If ODR=200Hz: *15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02
'       If ODR=400Hz: *30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05
'       If ODR=800Hz: *56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10
'       NOTE: Values are fractional values expressed as whole numbers. The '_' should be interpreted as a decimal point.
'           Examples: 8_00 = 8Hz, 0_50 = 0.5Hz, 0_02 = 0.02Hz
    tmp := 0
    readreg(core#CTRL_REG2, 1, @tmp)
    case GyroDataRate(-2)
        100:
            case freq
                8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01:
                    freq := lookdownz(freq: 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01) << core#HPCF
                other:
                    tmp := (tmp >> core#HPCF) & core#HPCF_BITS
                    return lookupz(tmp: 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01)

        200:
            case freq
                15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02:
                    freq := lookdownz(freq: 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02) << core#HPCF
                other:
                    tmp := (tmp >> core#HPCF) & core#HPCF_BITS
                    return lookupz(tmp: 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02)

        400:
            case freq
                30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05:
                    freq := lookdownz(freq: 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05) << core#HPCF
                other:
                    tmp := (tmp >> core#HPCF) & core#HPCF_BITS
                    return lookupz(tmp: 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05)

        800:
            case freq
                56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10:
                    freq := lookdownz(freq: 56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10) << core#HPCF
                other:
                    tmp := (tmp >> core#HPCF) & core#HPCF_BITS
                    return lookupz(tmp: 56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10)

    tmp &= core#HPCF_MASK
    tmp := (tmp | freq)
    writereg(core#CTRL_REG2, 1, @tmp)

PUB HighPassFilterMode(mode) | tmp
' Set data output high pass filter mode
'   Valid values:
'      *HPF_NORMAL_RES (0): Normal mode (reset reading HP_RESET_FILTER) XXX - clarify/expand
'       HPF_REF (1): Reference signal for filtering
'       HPF_NORMAL (2): Normal
'       HPF_AUTO_RES (3): Autoreset on interrupt
'   Any other value polls the chip and returns the current setting
    tmp := 0
    readreg(core#CTRL_REG2, 1, @tmp)
    case mode
        HPF_NORMAL_RES, HPF_REF, HPF_NORMAL, HPF_AUTO_RES:
            mode <<= core#HPM
        other:
            return (tmp >> core#HPM) & core#HPM_BITS

    tmp &= core#HPM_MASK
    tmp := (tmp | mode)
    writereg(core#CTRL_REG2, 1, @tmp)

PUB Int1Mask(func_mask) | tmp
' Set interrupt/function mask for INT1 pin
'   Valid values:
'       Bit 10   10
'           ||   ||
'    Range %00..%11
'       Bit 1: Interrupt enable (*0: Disable, 1: Enable)
'       Bit 0: Boot status (*0: Disable, 1: Enable)
    tmp := 0
    readreg(core#CTRL_REG3, 1, @tmp)
    case func_mask
        %00..%11:
            func_mask <<= core#INT1
        other:
            return (tmp >> core#INT1) & core#INT1_BITS

    tmp &= core#INT1_MASK
    tmp := (tmp | func_mask)
    writereg(core#CTRL_REG3, 1, @tmp)

PUB Int2Mask(func_mask) | tmp
' Set interrupt/function mask for INT2 pin
'   Valid values:
'       Bit 3210   3210
'           ||||   ||||
'    Range %0000..%1111 (default value: %0000)
'       Bit 3: Data ready
'       Bit 2: FIFO watermark
'       Bit 1: FIFO overrun
'       Bit 0: FIFO empty
    tmp := 0
    readreg(core#CTRL_REG3, 1, @tmp)
    case func_mask
        %0000..%1111:
        other:
            return tmp & core#INT2_BITS

    tmp &= core#INT2_MASK
    tmp := (tmp | func_mask)
    writereg(core#CTRL_REG3, 1, @tmp)

PUB IntActiveState(state) | tmp
' Set active state for interrupts
'   Valid values: *INTLVL_LOW (0), INTLVL_HIGH (1)
'   Any other value polls the chip and returns the current setting
    tmp := 0
    readreg(core#CTRL_REG3, 1, @tmp)
    case state
        INTLVL_LOW, INTLVL_HIGH:
            state := ((state ^ 1) & 1) << core#H_LACTIVE
        other:
            return (((tmp >> core#H_LACTIVE) ^ 1) & 1)

    tmp &= core#H_LACTIVE_MASK
    tmp := (tmp | state)
    writereg(core#CTRL_REG3, 1, @tmp)

PUB IntOutputType(pp_od) | tmp
' Set interrupt pin output type
'   Valid values:
'      *INT_PP (0): Push-pull
'       INT_OD (1): Open-drain
'   Any other value polls the chip and returns the current setting
    tmp := 0
    readreg(core#CTRL_REG3, 1, @tmp)
    case pp_od
        INT_PP, INT_OD:
            pp_od := pp_od << core#PP_OD
        other:
            return (tmp >> core#PP_OD) & 1

    tmp &= core#PP_OD_MASK
    tmp := (tmp | pp_od)
    writereg(core#CTRL_REG3, 1, @tmp)

PUB Temperature{}: temp
' Read device temperature
    readreg(core#OUT_TEMP, 1, @temp)

PRI readReg(reg, nr_bytes, ptr_buff) | tmp
' Read nr_bytes from device into ptr_buff
    case reg
        $0F, $20..$27, $2E..$38:
        $28..$2D:
            reg |= MS
        other:
            return FALSE

    reg |= R
    io.low(_CS)
    spi.shiftout(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)

    repeat tmp from 0 to nr_bytes-1
        byte[ptr_buff][tmp] := spi.shiftin(_MISO, _SCK, core#MISO_BITORDER, 8)
    io.high(_CS)

PRI writeReg(reg, nr_bytes, ptr_buff) | tmp
' Write nr_bytes to device from ptr_buff
    case reg
        $20..$25, $2E, $30, $32..$38:
        other:
            return FALSE

    io.low(_CS)
    spi.shiftout(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)

    repeat tmp from 0 to nr_bytes-1
        spi.shiftout(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[ptr_buff][tmp])

    io.high(_CS)

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
