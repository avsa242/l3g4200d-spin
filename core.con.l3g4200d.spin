{
    --------------------------------------------
    Filename: core.con.l3g4200d.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2019
    Started Nov 27, 2019
    Updated Nov 27, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    CPOL                        = 1
    CLK_DELAY                   = 10
    MOSI_BITORDER               = 5             'MSBFIRST
    MISO_BITORDER               = 2             'MSBPRE

' Register definitions
    WHO_AM_I                    = $0F
    CTRL_REG1                   = $20
    CTRL_REG2                   = $21
    CTRL_REG3                   = $22
    CTRL_REG4                   = $23
    CTRL_REG5                   = $24
    REFERENCE                   = $25
    OUT_TEMP                    = $26
    STATUS_REG                  = $27
    OUT_X_L                     = $28
    OUT_X_H                     = $29
    OUT_Y_L                     = $2A
    OUT_Y_H                     = $2B
    OUT_Z_L                     = $2C
    OUT_Z_H                     = $2D
    FIFO_CTRL_REG               = $2E
    FIFO_SRC_REG                = $2F
    INT1_CFG                    = $30
    INT1_SRC                    = $31
    INT1_TSH_XH                 = $32
    INT1_TSH_XL                 = $32
    INT1_TSH_YH                 = $32
    INT1_TSH_YL                 = $32
    INT1_TSH_ZH                 = $32
    INT1_TSH_ZL                 = $32
    INT1_DURATION               = $32


PUB Null
' This is not a top-level object
