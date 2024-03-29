{
    --------------------------------------------
    Filename: sensor.gyroscope.3dof.l3g4200d.spin
    Author: Jesse Burt
    Description: Driver for the ST L3G4200D 3-axis gyroscope
    Copyright (c) 2022
    Started Nov 27, 2019
    Updated Oct 1, 2022
    See end of file for terms of use.
    --------------------------------------------
}
#include "sensor.gyroscope.common.spinh"

CON

{ I2C settings }
    SLAVE_WR            = core#SLAVE_ADDR
    SLAVE_RD            = core#SLAVE_ADDR|1

    DEF_SCL             = 28
    DEF_SDA             = 29
    DEF_HZ              = 100_000
    DEF_ADDR            = 0
    I2C_MAX_FREQ        = core#I2C_MAX_FREQ

{ Indicate to user apps how many Degrees of Freedom each sub-sensor has }
{   (also imply whether or not it has a particular sensor) }
    ACCEL_DOF           = 0
    GYRO_DOF            = 3
    MAG_DOF             = 0
    BARO_DOF            = 0
    DOF                 = ACCEL_DOF + GYRO_DOF + MAG_DOF + BARO_DOF

' Scales and data rates used during calibration/bias/offset process
    CAL_XL_SCL          = 0
    CAL_G_SCL           = 250
    CAL_M_SCL           = 0
    CAL_XL_DR           = 0
    CAL_G_DR            = 200
    CAL_M_DR            = 0

{ SPI transaction bits }
    SPI_R               = 1 << 7                ' read transaction

#ifdef L3G4200D_SPI
    MS                  = 1 << 6                ' auto address increment
#else
#define L3G4200D_I2C
    MS                  = 1 << 7                ' auto address increment
#endif

{ High-pass filter modes }
    #0, HPF_NORMAL_RES, HPF_REF, HPF_NORMAL, HPF_AUTO_RES

{ Operation modes }
    #0, POWERDOWN, SLEEP, NORMAL

{ Interrupt pin active states }
    #0, INTLVL_HIGH, INTLVL_LOW

{ Interrupt pin output type }
    #0, INT_PP, INT_OD

{ Gyro data byte order }
    #0, LSBFIRST, MSBFIRST

{ Axis-specific symbols }
    #0, X_AXIS, Y_AXIS, Z_AXIS

{ Read/write }
    #0, R, W

VAR

    long _CS
    byte _addr_bits

OBJ

{ SPI? }
#ifdef L3G4200D_SPI
{ decide: Bytecode SPI engine, or PASM? Default is PASM if BC isn't specified }
#ifdef L3G4200D_SPI_BC
    spi : "com.spi.25khz.nocog"                       ' BC SPI engine
#else
    spi : "com.spi.1mhz"                          ' PASM SPI engine
#endif
#else
{ no, not SPI - default to I2C }
#define L3G4200D_I2C
{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef L3G4200D_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif

#endif
    core: "core.con.l3g4200d"                   ' HW-specific constants
    time: "time"                                ' timekeeping methods

PUB null{}
' This is not a top-level object

#ifdef L3G4200D_SPI
PUB startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): status
' Start using custom I/O settings
    if (lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and {
}   lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31))
        if (status := spi.init(SCK_PIN, MOSI_PIN, MISO_PIN, core#SPI_MODE))
            _CS := CS_PIN
            outa[_CS] := 1
            dira[_CS] := 1
            time.usleep(core#T_POR)             ' wait for device startup

            if (dev_id{} == core#DEVID_RESP)    ' validate device
                return
    { if this point is reached, something above failed }
    { Double check I/O pin assignments, connections, power }
    { Lastly - make sure you have at least one free core/cog }
    return FALSE

#elseifdef L3G4200D_I2C
PUB start{}: status
' Start using "standard" Propeller I2C pins, and 100kHz bus speed
    return startx(DEF_SCL, DEF_SDA, DEF_HZ, DEF_ADDR)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom I/O settings and bus speed
    if (lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   (I2C_HZ =< core#I2C_MAX_FREQ))
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)             ' wait for device startup
            _addr_bits := (ADDR_BITS << 1)
            if (dev_id{} == core#DEVID_RESP)    ' validate device
                return
    { if this point is reached, something above failed }
    { Double check I/O pin assignments, connections, power }
    { Lastly - make sure you have at least one free core/cog }
    return FALSE
#endif

PUB stop{}
' Stop the driver
#ifdef L3G4200D_SPI
    spi.deinit{}
#elseifdef L3G4200D_I2C
    i2c.deinit{}
#endif
    _CS := 0

PUB defaults{}
' Factory default settings
    blk_updt_ena(FALSE)
    data_order(LSBFIRST)
    fifo_ena(FALSE)
    gyro_axis_ena(%111)
    gyro_data_rate(100)
    gyro_opmode(POWERDOWN)
    gyro_scale(250)
    gyro_hpf_ena(FALSE)
    gyro_hpf_freq(8_00)
    gyro_hpf_mode(HPF_NORMAL_RES)
    int1_mask(%00)
    int2_mask(%0000)
    int_polarity(INTLVL_LOW)
    int_outp_type(INT_PP)

PUB preset_active{}
' Like defaults(), but place the sensor in active/normal mode
    defaults{}
    gyro_opmode(NORMAL)
    blk_updt_ena(TRUE)
    int2_mask(%1000)

PUB blk_updt_ena(state): curr_state
' Enable block updates
'   Valid values:
'      *FALSE (0): Update gyro data outputs continuously
'       TRUE (-1 or 1): Pause further updates until both MSB and LSB of data have been read
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CTRL_REG4, 1, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state) & 1) << core#BDU
        other:
            return (((curr_state >> core#BDU) & 1) == 1)

    state := ((curr_state & core#BDU_MASK) | state)
    writereg(core#CTRL_REG4, 1, @state)

PUB data_order(order): curr_ord
' Set byte order of gyro data
'   Valid values:
'      *LSBFIRST (0), MSBFIRST (1)
'   Any other value polls the chip and returns the current setting
'   NOTE: Intended only for use when utilizing raw gyro data from GyroData method.
'       GyroDPS expects the data order to be LSBFIRST
    curr_ord := 0
    readreg(core#CTRL_REG4, 1, @curr_ord)
    case order
        LSBFIRST, MSBFIRST:
            order <<= core#BLE
        other:
            return ((curr_ord >> core#BLE) & 1)

    order := ((curr_ord & core#BLE_MASK) | order)
    writereg(core#CTRL_REG4, 1, @order)

PUB dev_id{}: id
' Read Device ID
'   Known values: $D3
    id := 0
    readreg(core#WHO_AM_I, 1, @id)

PUB fifo_ena(state): curr_state
' Enable FIFO for gyro data
'   Valid values:
'      *FALSE (0): FIFO disabled
'       TRUE (-1 or 1): FIFO state
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CTRL_REG5, 1, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state) & 1) << core#FIFO_EN
        other:
            return (((curr_state >> core#FIFO_EN) & 1) == 1)

    state := ((curr_state & core#FIFO_EN_MASK) | state)
    writereg(core#CTRL_REG5, 1, @state)

PUB gyro_axis_ena(mask): curr_mask
' Enable gyroscope individual axes, by mask
'   Valid values:
'       0: Disable axis, 1: Enable axis
'       Bits %210
'             ZYX (default: %111)
'   Any other value polls the chip and returns the current setting
    curr_mask := 0
    readreg(core#CTRL_REG1, 1, @curr_mask)
    case mask
        %000..%111:
        other:
            return (curr_mask & core#XYZEN_BITS)

    mask := ((curr_mask & core#XYZEN_MASK) | mask) & core#CTRL_REG1_MASK
    writereg(core#CTRL_REG1, 1, @mask)

PUB gyro_bias(x, y, z)
' Read gyroscope calibration offset values
'   x, y, z: pointers to copy offsets to
    longmove(x, @_gbias, 3)

PUB gyro_set_bias(x, y, z)
' Read or write/manually set Gyroscope calibration offset values
'   Valid values:
'       -32768..32767 (clamped to range)
    x := -32768 #> x <# 32767
    y := -32768 #> y <# 32767
    z := -32768 #> z <# 32767

    longmove(@_gbias, @x, 3)

PUB gyro_data(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read gyroscope data
    bytefill(@tmp, 0, 8)
    readreg(core#OUT_X_L, 6, @tmp)

    long[ptr_x] := (~~tmp.word[X_AXIS] - _gbias[X_AXIS])
    long[ptr_y] := (~~tmp.word[Y_AXIS] - _gbias[Y_AXIS])
    long[ptr_z] := (~~tmp.word[Z_AXIS] - _gbias[Z_AXIS])

PUB gyro_data_overrun{}: flag
' Flag indicating previously acquired data has been overwritten
'   Returns: TRUE (-1) if data has overrun/been overwritten, FALSE otherwise
    flag := 0
    readreg(core#STATUS_REG, 1, @flag)
    return (((flag >> core#ZYXOR) & 1) == 1)

PUB gyro_data_rate(rate): curr_rate
' Set rate of data output, in Hz
'   Valid values: *100, 200, 400, 800
'   Any other value polls the chip and returns the current setting
    curr_rate := 0
    readreg(core#CTRL_REG1, 1, @curr_rate)
    case rate
        100, 200, 400, 800:
            rate := lookdownz(rate: 100, 200, 400, 800) << core#DR
        other:
            curr_rate := (curr_rate >> core#DR) & core#DR_BITS
            return lookupz(curr_rate: 100, 200, 400, 800)

    rate := ((curr_rate & core#DR_MASK) | rate)
    writereg(core#CTRL_REG1, 1, @rate)

PUB gyro_data_rdy{}: flag
' Flag indicates gyroscope data is ready
'   Returns: TRUE (-1) if data ready, FALSE otherwise
    flag := 0
    readreg(core#STATUS_REG, 1, @flag)
    return (((flag >> core#ZYXDA) & 1) == 1)

PUB gyro_lpf_freq(freq): curr_freq
' Set gyroscope low-pass filter frequency, in Hz
'   Valid values:
'   When gyro_data_rate() == ...:
'       100: 12 (12.5), 25
'       200: 12 (12.5), 25, 50, 70
'       400: 20, 25, 50, 110
'       800: 30, 35, 50, 110
'   NOTE: Available values depend on current gyro_data_rate()
'   Any other value polls the chip and returns the current setting
    curr_freq := 0
    readreg(core#CTRL_REG1, 1, @curr_freq)
    case freq
        12{.5}, 20, 25, 30, 35, 50, 70, 110:
            case gyro_data_rate(-2)             ' effective LPF depends on ODR
                100:
                    freq := lookdownz(freq: 12, 25)
                200:
                    freq := lookdownz(freq: 12, 25, 50, 70)
                400:
                    freq := lookdownz(freq: 20, 25, 50, 110)
                800:
                    freq := lookdownz(freq: 30, 35, 50, 110)
            freq <<= core#BW
        other:
            curr_freq := (curr_freq >> core#BW) & core#BW_BITS
            case gyro_data_rate(-2)
                100:
                    return lookupz(curr_freq: 12, 25, 25, 25)
                200:
                    return lookupz(curr_freq: 12, 25, 50, 70)
                400:
                    return lookupz(curr_freq: 20, 25, 50, 110)
                800:
                    return lookupz(curr_freq: 30, 35, 50, 110)

    freq := ((curr_freq & core#BW_MASK) | freq) & core#CTRL_REG1_MASK
    writereg(core#CTRL_REG1, 1, @freq)

PUB gyro_opmode(mode): curr_mode
' Set operation mode
'   Valid values:
'      *POWERDOWN (0): Power down - lowest power state
'       SLEEP (1): Sleep - sensor enabled, but X, Y, Z outputs disabled
'       NORMAL (2): Normal - active operating state
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#CTRL_REG1, 1, @curr_mode)
    case mode
        POWERDOWN:
            curr_mode &= core#PD_MASK
        SLEEP:
            mode := (1 << core#PD)
            curr_mode &= core#XYZEN_MASK
        NORMAL:
            mode := (1 << core#PD)
            curr_mode &= core#PD_MASK
        other:
            curr_mode := (curr_mode >> core#PD) & 1
            if (curr_mode & core#XYZEN_BITS)
                curr_mode += 1
            return

    mode := (curr_mode | mode)
    writereg(core#CTRL_REG1, 1, @mode)

PUB gyro_scale(dps): curr_dps
' Set gyro full-scale range, in degrees per second
'   Valid values: *250, 500, 2000
'   Any other value polls the chip and returns the current setting
    curr_dps := 0
    readreg(core#CTRL_REG4, 1, @curr_dps)
    case dps
        250, 500, 2000:
            dps := lookdownz(dps: 250, 500, 2000) << core#FS
            _gres := lookupz(dps >> core#FS: 8_750, 17_500, 70_000)
        other:
            curr_dps := (curr_dps >> core#FS) & core#FS_BITS
            return lookupz(curr_dps: 250, 500, 2000)

    dps := ((curr_dps & core#FS_MASK) | dps)
    writereg(core#CTRL_REG4, 1, @dps)

PUB gyro_hpf_ena(state): curr_state
' Enable high-pass filter for gyro data, to mitigate long-term drift
'   Valid values:
'      *FALSE (0): High-pass filter disabled
'       TRUE (-1 or 1): High-pass filter state
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CTRL_REG5, 1, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state) & 1) << core#HPEN
        other:
            return (((curr_state >> core#HPEN) & 1) == 1)

    state := ((curr_state & core#HPEN_MASK) | state)
    writereg(core#CTRL_REG5, 1, @state)

PUB gyro_hpf_freq(freq): curr_freq
' Set high-pass filter frequency, in Hz
'    Valid values:
'       if gyro_data_rate() == 100:
'           *8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01
'       gyro_data_rate() == 200:
'           *15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02
'       gyro_data_rate() == 400:
'           *30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05
'       gyro_data_rate() == 800:
'           *56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10
'       NOTE: Values are fractional values expressed as whole numbers. The '_' should be interpreted as a decimal point.
'           Examples: 8_00 = 8Hz, 0_50 = 0.5Hz, 0_02 = 0.02Hz
    curr_freq := 0
    readreg(core#CTRL_REG2, 1, @curr_freq)
    case gyro_data_rate(-2)
        100:
            case freq
                8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01:
                    freq := lookdownz(freq: 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01) << core#HPCF
                other:
                    curr_freq := (curr_freq >> core#HPCF) & core#HPCF_BITS
                    return lookupz(curr_freq: 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01)

        200:
            case freq
                15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02:
                    freq := lookdownz(freq: 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02) << core#HPCF
                other:
                    curr_freq := (curr_freq >> core#HPCF) & core#HPCF_BITS
                    return lookupz(curr_freq: 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02)

        400:
            case freq
                30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05:
                    freq := lookdownz(freq: 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05) << core#HPCF
                other:
                    curr_freq := (curr_freq >> core#HPCF) & core#HPCF_BITS
                    return lookupz(curr_freq: 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05)

        800:
            case freq
                56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10:
                    freq := lookdownz(freq: 56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10) << core#HPCF
                other:
                    curr_freq := (curr_freq >> core#HPCF) & core#HPCF_BITS
                    return lookupz(curr_freq: 56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10)

    freq := ((curr_freq & core#HPCF_MASK) | freq)
    writereg(core#CTRL_REG2, 1, @freq)

PUB gyro_hpf_mode(mode): curr_mode
' Set data output high pass filter mode
'   Valid values:
'      *HPF_NORMAL_RES (0): Normal mode (HPF is reset by reading the
'           REFERENCE register) - XXX to be implemented
'       HPF_REF (1): Output data calculated as the difference between measured
'           angular rate and contents of the REFERENCE register
'       HPF_NORMAL (2): Normal mode - same as mode 0
'       HPF_AUTO_RES (3): Automatically reset when a configured interrupt
'           occurs
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#CTRL_REG2, 1, @curr_mode)
    case mode
        HPF_NORMAL_RES, HPF_REF, HPF_NORMAL, HPF_AUTO_RES:
            mode <<= core#HPM
        other:
            return ((curr_mode >> core#HPM) & core#HPM_BITS)

    mode := ((curr_mode & core#HPM_MASK) | mode)
    writereg(core#CTRL_REG2, 1, @mode)

PUB int1_mask(mask): curr_mask
' Set interrupt/function mask for INT1 pin
'   Valid values:
'       Bits: 1..0
'       1: Interrupt enable (*0: Disable, 1: Enable)
'       0: Boot status (*0: Disable, 1: Enable)
    curr_mask := 0
    readreg(core#CTRL_REG3, 1, @curr_mask)
    case mask
        %00..%11:
            mask <<= core#INT1
        other:
            return ((curr_mask >> core#INT1) & core#INT1_BITS)

    mask := ((curr_mask & core#INT1_MASK) | mask)
    writereg(core#CTRL_REG3, 1, @mask)

PUB int2_mask(mask): curr_mask
' Set interrupt/function mask for INT2 pin
'   Valid values:
'       Bits: 3..0
'       3: Data ready (default: 0)
'       2: FIFO watermark (default: 0)
'       1: FIFO overrun (default: 0)
'       0: FIFO empty (default: 0)
    curr_mask := 0
    readreg(core#CTRL_REG3, 1, @curr_mask)
    case mask
        %0000..%1111:
        other:
            return (curr_mask & core#INT2_BITS)

    mask := ((curr_mask & core#INT2_MASK) | mask)
    writereg(core#CTRL_REG3, 1, @mask)

PUB int_polarity(state): curr_state
' Set active state for interrupts
'   Valid values: *INTLVL_HIGH (0), INTLVL_LOW (1)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CTRL_REG3, 1, @curr_state)
    case state
        INTLVL_HIGH, INTLVL_LOW:
            state <<= core#H_LACTIVE
        other:
            return ((curr_state >> core#H_LACTIVE) & 1)

    state := ((curr_state & core#H_LACTIVE_MASK) | state)
    writereg(core#CTRL_REG3, 1, @state)

PUB int_outp_type(type): curr_type
' Set interrupt pin output type
'   Valid values:
'      *INT_PP (0): Push-pull
'       INT_OD (1): Open-drain
'   Any other value polls the chip and returns the current setting
    curr_type := 0
    readreg(core#CTRL_REG3, 1, @curr_type)
    case type
        INT_PP, INT_OD:
            type := type << core#PP_OD
        other:
            return ((curr_type >> core#PP_OD) & 1)

    type := ((curr_type & core#PP_OD_MASK) | type)
    writereg(core#CTRL_REG3, 1, @type)

PUB temp_data{}: temp
' Read device temperature
'   Returns: s8
'   NOTE: This temperature reading is the gyroscope die temperature,
'       not an ambient temperature reading. It is meant to be used as
'       a relative change in temperature, not an absolute temperature
'       reading
    readreg(core#OUT_TEMP, 1, @temp)
    return ~temp

PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from device into ptr_buff
    case reg_nr
        $28..$2D:                               ' prioritize output data regs
            reg_nr |= MS                        ' indicate multi-byte xfer
        $0F, $20..$27, $2E..$38:
        other:
            return

#ifdef L3G4200D_SPI
    reg_nr |= SPI_R                             ' indicate read xfer
    outa[_CS] := 0
    spi.wr_byte(reg_nr)
    spi.rdblock_lsbf(ptr_buff, nr_bytes)
    outa[_CS] := 1
#elseifdef L3G4200D_I2C
    cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
    cmd_pkt.byte[1] := reg_nr
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.stop{}

    i2c.start{}
    i2c.write(SLAVE_RD | _addr_bits)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop{}
#endif

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes to device from ptr_buff
    case reg_nr
        $20..$25, $2E, $30, $32..$38:
        other:
            return

#ifdef L3G4200D_SPI
    outa[_CS] := 0
    spi.wr_byte(reg_nr)
    spi.wrblock_lsbf(ptr_buff, nr_bytes)
    outa[_CS] := 1
#elseifdef L3G4200D_I2C
    cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
    cmd_pkt.byte[1] := reg_nr
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.wrblock_lsbf(ptr_buff, nr_bytes)
    i2c.stop{}
#endif

DAT
{
Copyright 2022 Jesse Burt

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

