{
----------------------------------------------------------------------------------------------------
    Filename:       sensor.gyroscope.3dof.l3g4200d.spin
    Description:    Driver for the ST L3G4200D 3-axis gyroscope
    Author:         Jesse Burt
    Started:        Nov 27, 2019
    Updated:        Jan 14, 2025
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

#include "sensor.gyroscope.common.spinh"        ' use code common to all gyroscope drivers

' if the bytecode-based SPI engine is requested, make sure SPI-related code in the driver
'    is enabled
#ifdef L3G4200D_SPI_BC
# ifndef L3G4200D_SPI
#  define L3G4200D_SPI
# endif
#endif

CON

    { default I/O configuration - these can be overridden by the parent object }
    ' I2C
    SCL             = 28
    SDA             = 29
    I2C_FREQ        = 1_000_000
    I2C_ADDR        = 0

    ' SPI
    CS              = 0
    SCK             = 1
    MOSI            = 2
    MISO            = 3
    SPI_FREQ        = 1_000_000

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

    { I2C settings }
    SLAVE_WR            = core.SLAVE_ADDR
    SLAVE_RD            = core.SLAVE_ADDR|1

    DEF_SCL             = 28
    DEF_SDA             = 29
    DEF_HZ              = 100_000
    DEF_ADDR            = 0
    I2C_MAX_FREQ        = core.I2C_MAX_FREQ


VAR

    long _CS
    byte _addr_bits


OBJ

{ SPI? }
#ifdef L3G4200D_SPI
{ decide: Bytecode SPI engine, or PASM? Default is PASM if BC isn't specified }
# ifdef L3G4200D_SPI_BC
    spi:    "com.spi.25khz.nocog"               ' BC SPI engine
# else
    spi:    "com.spi.1mhz"                      ' PASM SPI engine
# endif
#else
{ no, not SPI - default to I2C }
# define L3G4200D_I2C
{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
# ifdef L3G4200D_I2C_BC
    i2c:    "com.i2c.nocog"                     ' BC I2C engine
# else
    i2c:    "com.i2c"                           ' PASM I2C engine
# endif
#endif
    core:   "core.con.l3g4200d"                 ' HW-specific constants
    time:   "time"                              ' timekeeping methods

PUB null()
' This is not a top-level object


#ifdef L3G4200D_SPI

PUB start(): status
' Start using "standard" Propeller I2C pins, and 100kHz bus speed
    return startx(CS, SCK, MOSI, MISO, SPI_FREQ)


PUB startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, SPI_HZ=1_000_000): status
' Start using custom I/O settings
    if (    lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and ...
            lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31) )
        if ( status := spi.init(SCK_PIN, MOSI_PIN, MISO_PIN, core.SPI_MODE) )
            _CS := CS_PIN                       ' copy pins to hub vars
            outa[_CS] := 1
            dira[_CS] := 1
            time.usleep(core.T_POR)             ' wait for device startup
            if ( MOSI_PIN == MISO_PIN )
                spi_mode(3)
            else
                spi_mode(4)
            if ( dev_id() == core.DEVID_RESP )  ' verify communication with device
                return
    { if this point is reached, something above failed }
    { Double check I/O pin assignments, connections, power }
    { Lastly - make sure you have at least one free core/cog }
    return FALSE

#elseifdef L3G4200D_I2C

PUB start(): status
' Start using default I/O configuration
    return startx(SCL, SDA, I2C_FREQ, I2C_ADDR)


PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom I/O settings and bus speed
    if ( lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) )
        if ( status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ) )
            time.usleep(core.T_POR)             ' wait for device startup
            _addr_bits := (ADDR_BITS << 1)
            if ( dev_id() == core.DEVID_RESP )  ' verify communication with device
                return
    { if this point is reached, something above failed }
    { Double check I/O pin assignments, connections, power }
    { Lastly - make sure you have at least one free core/cog }
    return FALSE
#endif


PUB stop()
' Stop the driver
#ifdef L3G4200D_SPI
    spi.deinit()
#elseifdef L3G4200D_I2C
    i2c.deinit()
#endif
    _CS := 0


PUB defaults()
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


PUB preset_active()
' Like defaults(), but place the sensor in active/normal mode
    defaults()
    gyro_opmode(NORMAL)
    blk_updt_ena(TRUE)
    int2_mask(%1000)


PUB blk_updt_ena(st=-2): c
' Enable block updates
'   Valid values:
'      *FALSE (0): Update gyro data outputs continuously
'       TRUE (-1 or 1): Pause further updates until both MSB and LSB of data have been read
'   Any other value polls the chip and returns the current setting
    c := readreg(core.CTRL_REG4)
    case ||(st)
        0, 1:
            st := (||(st) & 1) << core.BDU
            st := ((c & core.BDU_MASK) | st)
            writereg(core.CTRL_REG4, st)
        other:
            return ( ( (c >> core.BDU) & 1) == 1)


PUB data_order(ord=-2): c
' Set byte order of gyro data
'   Valid values:
'      *LSBFIRST (0), MSBFIRST (1)
'   Any other value polls the chip and returns the current setting
'   NOTE: Intended only for use when utilizing raw gyro data from gyro_data() method.
'       gyro_dps() expects the data order to be LSBFIRST
    c := readreg(core.CTRL_REG4)
    case ord
        LSBFIRST, MSBFIRST:
            ord <<= core.BLE
            ord := ((c & core.BLE_MASK) | ord)
            writereg(core.CTRL_REG4, ord)
        other:
            return ( (c >> core.BLE) & 1)


PUB dev_id(): id
' Read Device ID
'   Known values: $D3
    return readreg(core.WHO_AM_I)


PUB fifo_ena(st=-2): c
' Enable FIFO for gyro data
'   Valid values:
'      *FALSE (0): FIFO disabled
'       TRUE (-1 or 1): FIFO state
'   Any other value polls the chip and returns the current setting
    c := readreg(core.CTRL_REG5)
    case ||(st)
        0, 1:
            st := (st & 1) << core.FIFO_EN
            st := ((c & core.FIFO_EN_MASK) | st)
            writereg(core.CTRL_REG5, st)
        other:
            return ( ( (c >> core.FIFO_EN) & 1) == 1)


PUB gyro_axis_ena(m=-2): c
' Enable gyroscope individual axes, by mask
'   Valid values:
'       0: Disable axis, 1: Enable axis
'       Bits %210
'             ZYX (default: %111)
'   Any other value polls the chip and returns the current setting
    c := readreg(core.CTRL_REG1)
    case m
        %000..%111:
            m := ( (c & core.XYZEN_MASK) | m)
            writereg(core.CTRL_REG1, m)
        other:
            return (c & core.XYZEN_BITS)


PUB gyro_bias(x, y, z)
' Read gyroscope calibration offset values
'   x, y, z: pointers to copy offsets to
    longmove(x, @_gbias, 3)


PUB gyro_data(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read gyroscope data
    longfill(@tmp, 0, 2)
#ifdef L3G4200D_SPI
    outa[_CS] := 0
        spi.wr_byte(SPI_R | MS | core.OUT_X_L)
        spi.rdblock_lsbf(@tmp, 6)
    outa[_CS] := 1
#else
    i2c.start()
    i2c.write(SLAVE_WR | _addr_bits)
    i2c.write(MS | core.OUT_X_L)
    i2c.start()
    i2c.write(SLAVE_RD | _addr_bits)
    i2c.rdblock_lsbf(@tmp, 6, i2c.NAK)
    i2c.stop()
#endif

    long[ptr_x] := (~~tmp.word[X_AXIS] - _gbias[X_AXIS])
    long[ptr_y] := (~~tmp.word[Y_AXIS] - _gbias[Y_AXIS])
    long[ptr_z] := (~~tmp.word[Z_AXIS] - _gbias[Z_AXIS])


PUB gyro_data_overrun(): f
' Flag indicating previously acquired data has been overwritten
'   Returns: TRUE (-1) if data has overrun/been overwritten, FALSE otherwise
    return ( ( (readreg(core.STATUS_REG) >> core.ZYXOR) & 1) == 1)


PUB gyro_data_rate(r=-2): c
' Set rate of data output, in Hz
'   Valid values: *100, 200, 400, 800
'   Any other value polls the chip and returns the current setting
    c := readreg(core.CTRL_REG1)
    case r
        100, 200, 400, 800:
            r := lookdownz(r: 100, 200, 400, 800) << core.DR
            r := ((c & core.DR_MASK) | r)
            writereg(core.CTRL_REG1, r)
        other:
            c := (c >> core.DR) & core.DR_BITS
            return lookupz(c: 100, 200, 400, 800)


PUB gyro_data_rdy(): f
' Flag indicates gyroscope data is ready
'   Returns: TRUE (-1) if data ready, FALSE otherwise
    return ( ( (readreg(core.STATUS_REG) >> core.ZYXDA) & 1) == 1)


PUB gyro_hpf_ena(st=-2): c
' Enable high-pass filter for gyro data, to mitigate long-term drift
'   Valid values:
'      *FALSE (0): High-pass filter disabled
'       TRUE (-1 or 1): High-pass filter state
'   Any other value polls the chip and returns the current setting
    c := readreg(core.CTRL_REG5)
    case ||(st)
        0, 1:
            st := (st & 1) << core.HPEN
            st := ((c & core.HPEN_MASK) | st)
            writereg(core.CTRL_REG5, st)
        other:
            return ( ( (c >> core.HPEN) & 1) == 1)


PUB gyro_hpf_freq(f=-2): c
' Set high-pass filter frequency, in centi-Hz
'    Valid values:
'       if gyro_data_rate() == 100:
'           8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01 (default: 8_00)
'       gyro_data_rate() == 200:
'           15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02 (default: 15_00)
'       gyro_data_rate() == 400:
'           30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05 (default: 30_00)
'       gyro_data_rate() == 800:
'           56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10 (default: 56_00)
'       Examples:
'           8_00 = 800 centi-Hz or 8Hz
'           0_50 = 50 centi-Hz or 0.5Hz
'           0_02 = 2 centi-Hz or 0.02Hz
    c := readreg(core.CTRL_REG2)
    case gyro_data_rate()
        100:
            case f
                8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02, 0_01:
                    f := lookdownz(f:   8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, ...
                                        0_02, 0_01) << core.HPCF
                other:
                    c := (c >> core.HPCF) & core.HPCF_BITS
                    return lookupz(c:   8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, ...
                                        0_02, 0_01)
        200:
            case f
                15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05, 0_02:
                    f := lookdownz(f:   15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, ...
                                        0_05, 0_02) << core.HPCF
                other:
                    c := (c >> core.HPCF) & core.HPCF_BITS
                    return lookupz(c:   15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, ...
                                        0_05, 0_02)
        400:
            case f
                30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10, 0_05:
                    f := lookdownz(f:   30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, ...
                                        0_10, 0_05) << core.HPCF
                other:
                    c := (c >> core.HPCF) & core.HPCF_BITS
                    return lookupz(c:   30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, ...
                                        0_10, 0_05)
        800:
            case f
                56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, 0_20, 0_10:
                    f := lookdownz(f:   56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, 0_50, ...
                                        0_20, 0_10) << core.HPCF
                other:
                    c := (c >> core.HPCF) & core.HPCF_BITS
                    return lookupz(c:   56_00, 30_00, 15_00, 8_00, 4_00, 2_00, 1_00, ...
                                        0_50, 0_20, 0_10)

    writereg(core.CTRL_REG2, ( (c & core.HPCF_MASK) | f) )


PUB gyro_hpf_mode(m=-2): c
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
    c := readreg(core.CTRL_REG2)
    case m
        HPF_NORMAL_RES, HPF_REF, HPF_NORMAL, HPF_AUTO_RES:
            m <<= core.HPM
            m := ( (c & core.HPM_MASK) | m)
            writereg(core.CTRL_REG2, m)
        other:
            return ( (c >> core.HPM) & core.HPM_BITS)


PUB gyro_lpf_freq(f=-2): c
' Set gyroscope low-pass filter frequency, in Hz
'   Valid values:
'   When gyro_data_rate() == ...:
'       100: 12 (12.5), 25
'       200: 12 (12.5), 25, 50, 70
'       400: 20, 25, 50, 110
'       800: 30, 35, 50, 110
'   NOTE: Available values depend on current gyro_data_rate()
'   Any other value polls the chip and returns the current setting
    c := readreg(core.CTRL_REG1)
    case f
        12{.5}, 20, 25, 30, 35, 50, 70, 110:
            case gyro_data_rate()               ' effective LPF depends on ODR
                100:
                    f := lookdownz(f: 12, 25)
                200:
                    f := lookdownz(f: 12, 25, 50, 70)
                400:
                    f := lookdownz(f: 20, 25, 50, 110)
                800:
                    f := lookdownz(f: 30, 35, 50, 110)
            f <<= core.BW
            f := ( (c & core.BW_MASK) | f) & core.CTRL_REG1_MASK
            writereg(core.CTRL_REG1, f)
        other:
            c := (c >> core.BW) & core.BW_BITS
            case gyro_data_rate()
                100:
                    return lookupz(c: 12, 25, 25, 25)
                200:
                    return lookupz(c: 12, 25, 50, 70)
                400:
                    return lookupz(c: 20, 25, 50, 110)
                800:
                    return lookupz(c: 30, 35, 50, 110)


PUB gyro_opmode(m=-2): c
' Set operation mode
'   Valid values:
'      *POWERDOWN (0): Power down - lowest power state
'       SLEEP (1): Sleep - sensor enabled, but X, Y, Z outputs disabled
'       NORMAL (2): Normal - active operating state
'   Any other value polls the chip and returns the current setting
    c := readreg(core.CTRL_REG1)
    case m
        POWERDOWN:
            c &= core.PD_MASK
        SLEEP:
            m := (1 << core.PD)
            c &= core.XYZEN_MASK
        NORMAL:
            m := (1 << core.PD)
            c &= core.PD_MASK
        other:
            c := (c >> core.PD) & 1
            if ( c & core.XYZEN_BITS )
                c += 1
            return

    writereg(core.CTRL_REG1, (c | m) )


PUB gyro_scale(s=-2): c
' Set gyro full-scale range, in degrees per second
'   Valid values: *250, 500, 2000
'   Any other value polls the chip and returns the current setting
    c := readreg(core.CTRL_REG4)
    case s
        250, 500, 2000:
            s := lookdownz(s: 250, 500, 2000) << core.FS
            _gres := lookupz(s >> core.FS: 8_750, 17_500, 70_000)
            s := ((c & core.FS_MASK) | s)
            writereg(core.CTRL_REG4, s)
        other:
            c := (c >> core.FS) & core.FS_BITS
            return lookupz(c: 250, 500, 2000)


PUB gyro_set_bias(x, y, z)
' Read or write/manually set Gyroscope calibration offset values
'   Valid values:
'       -32768..32767 (clamped to range)
    x := -32768 #> x <# 32767
    y := -32768 #> y <# 32767
    z := -32768 #> z <# 32767

    longmove(@_gbias, @x, 3)


PUB int1_mask(m=-2): c
' Set interrupt/function mask for INT1 pin
'   Valid values:
'       Bits: 1..0
'       1: Interrupt enable (*0: Disable, 1: Enable)
'       0: Boot status (*0: Disable, 1: Enable)
    c := readreg(core.CTRL_REG3)
    case m
        %00..%11:
            m <<= core.INT1
            m := ( (c & core.INT1_MASK) | m)
            writereg(core.CTRL_REG3, m)
        other:
            return ( (c >> core.INT1) & core.INT1_BITS)


PUB int2_mask(m=-2): c
' Set interrupt/function mask for INT2 pin
'   Valid values:
'       Bits: 3..0
'       3: Data ready (default: 0)
'       2: FIFO watermark (default: 0)
'       1: FIFO overrun (default: 0)
'       0: FIFO empty (default: 0)
    c := readreg(core.CTRL_REG3)
    case m
        %0000..%1111:
            m := ((c & core.INT2_MASK) | m)
            writereg(core.CTRL_REG3, m)
        other:
            return (c & core.INT2_BITS)


PUB int_polarity(p=-2): c
' Set active state for interrupts
'   Valid values: *INTLVL_HIGH (0), INTLVL_LOW (1)
'   Any other value polls the chip and returns the current setting
    c := readreg(core.CTRL_REG3)
    case p
        INTLVL_HIGH, INTLVL_LOW:
            p <<= core.H_LACTIVE
            p := ((c & core.H_LACTIVE_MASK) | p)
            writereg(core.CTRL_REG3, p)
        other:
            return ( (c >> core.H_LACTIVE) & 1)


PUB int_outp_type(t=-2): c
' Set interrupt pin output type
'   Valid values:
'      *INT_PP (0): Push-pull
'       INT_OD (1): Open-drain
'   Any other value polls the chip and returns the current setting
    c := readreg(core.CTRL_REG3)
    case t
        INT_PP, INT_OD:
            t := t << core.PP_OD
            t := ( (c & core.PP_OD_MASK) | t)
            writereg(core.CTRL_REG3, t)
        other:
            return ( (c >> core.PP_OD) & 1)


PUB temp_data(): t
' Read device temperature
'   Returns: s8
'   NOTE: This temperature reading is the gyroscope die temperature,
'       not an ambient temperature reading. It is meant to be used as
'       a relative change in temperature, not an absolute temperature
'       reading
    t := readreg(core.OUT_TEMP)
    return ~t


PRI readreg(reg_nr, nr_bytes=1): v | cmd_pkt
' Read nr_bytes from device into ptr_buff
    case reg_nr
        $0F, $20..$27, $2E..$38:
        other:
            return

#ifdef L3G4200D_SPI
    reg_nr |= SPI_R                             ' indicate read xfer
    outa[_CS] := 0
        spi.wr_byte(reg_nr)
        spi.rdblock_lsbf(@v, nr_bytes)
    outa[_CS] := 1
#elseifdef L3G4200D_I2C
    cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
    cmd_pkt.byte[1] := reg_nr
    v := 0
    i2c.start()
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.stop()

    i2c.start()
    i2c.write(SLAVE_RD | _addr_bits)
    i2c.rdblock_lsbf(@v, nr_bytes, i2c.NAK)
    i2c.stop()
#endif


PRI spi_mode(m) | tmp
' Set SPI mode
'   m:  3 (3-wire mode), 4 (4-wire mode)
    tmp := readreg(core.CTRL_REG4)

    if ( m == 3 )
        tmp := (tmp | core.SPI_3W)
    elseif ( m == 4 )
        tmp &= core.SIM_MASK

    writereg(core.CTRL_REG4, tmp)


PRI writereg(reg_nr, val) | cmd_pkt
' Write nr_bytes to device from ptr_buff
    case reg_nr
        $20..$25, $2E, $30, $32..$38:
        other:
            return

#ifdef L3G4200D_SPI
    outa[_CS] := 0
        spi.wr_byte(reg_nr)
        spi.wrblock_lsbf(@val, 1)
    outa[_CS] := 1
#elseifdef L3G4200D_I2C
    cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
    cmd_pkt.byte[1] := reg_nr
    cmd_pkt.byte[2] := val
    i2c.start()
    i2c.wrblock_lsbf(@cmd_pkt, 3)
    i2c.stop()
#endif


DAT
{
Copyright 2025 Jesse Burt

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

