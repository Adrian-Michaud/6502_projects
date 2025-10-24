/*
 *
 * LAM32 - Lean and mean 32-bit Operating System for 6502 based platforms
 *
 * Designed/Developed/Produced by Adrian Michaud
 *
 * MIT License
 *
 * Copyright (c) 2025 Adrian Michaud
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

/*             FILE_TABLE structure
Bytes 0 -3  (4): (Mode Read)  File Size 
                 (Mode Write) Bytes Written

Bytes 4 -7  (4): (Mode Write) Directory Block (BLOCK)
                 (Mode Read ) Bytes Read

Bytes 8 -9  (2): Offset within Directory Block (SYS_FILE_PTR)
Bytes 10-13 (4): Block where Current Block Allocation Table Resides
Bytes 14-15 (2): Current Index into Block Allocation Table
Bytes 16    (1): File Mode (Read/Write/Append/Available Entry)
Bytes 17-18 (2): Data Block Pointer (SYS_FILE_PTR)
Bytes 19-22 (4): Current Block for Read/Write.
Bytes 23    (1): Reserved
*/

//#define DEBUG_DISK_RW 

//.emulator on
//.emmstart $200

//#define DEBUG

#define PROGRAM_BUFFER   0x200 

//#define TESTBED

#ifdef TESTBED
#define ROM_ADDRESS      0x200
#else
#define ROM_ADDRESS      0x8000
#endif

// 6522 PIA conatants

#define PIA1_DATA_PORT_B 0x4000
#define PIA1_DATA_PORT_A 0x4001

#define PIA1_DATA_DIR_B  0x4002
#define PIA1_DATA_DIR_A  0x4003

#define PIA2_DATA_PORT_B 0x4010
#define PIA2_DATA_PORT_A 0x4011

#define PIA2_DATA_DIR_B  0x4012
#define PIA2_DATA_DIR_A  0x4013

#define PIA3_DATA_PORT_B 0x4020
#define PIA3_DATA_PORT_A 0x4021

#define PIA3_DATA_DIR_B  0x4022
#define PIA3_DATA_DIR_A  0x4023

#define PIA4_DATA_PORT_B 0x4040
#define PIA4_DATA_PORT_A 0x4041
#define PIA4_DATA_DIR_B  0x4042
#define PIA4_DATA_DIR_A  0x4043

#define INPUT_DATA_DIR   0
#define OUTPUT_DATA_DIR  0xff

// 6551 ACIA constants

#define ACIA_DATA        0x4030
#define ACIA_STATUS      0x4031
#define ACIA_COMMAND     0x4032
#define ACIA_CONTROL     0x4033

#define BPS_9600_8N1     30 
#define BPS_19200_8N1    31 

// ISA Bus Constants

#define A16              1
#define A17              2
#define A18              4
#define A19              8
#define IOW              1
#define IOR              2
#define MEMW             4
#define MEMR             8
#define VIDEO_ADDR       A17+A19
#define TXT_ADDR         A16+A17+A19
#define IO_R             IOW+MEMW+MEMR
#define IO_W             IOR+MEMW+MEMR     
#define MEM_R            IOW+IOR+MEMW
#define MEM_W            IOW+IOR+MEMR
#define IO_OFF           IOR+IOW+MEMW+MEMR 

// Misc Constants

#define SAVE_A                 $0  // 1 Byte
#define LOW_BYTE               $3  // 1 Byte
#define HIGH_BYTE              $4  // 1 Byte
#define ADDRESS                $5  // 2 Byte
#define MATH_PARAM0            $7  // 4 Byte
#define MATH_PARAM1            $b  // 4 Byte
#define MATH_PARAM2            $f  // 4 Byte
#define MATH_PARAM3            $13 // 4 Byte
#define CYLINDERS              $20 // 2 Byte
#define HEADS                  $22 // 1 Byte
#define SECTORS                $23 // 1 Byte
#define TOTAL_BLOCKS           $24 // 4 Byte
#define CURRENT_CYLINDER       $28 // 2 Byte 
#define CURRENT_HEAD           $2a // 1 Byte
#define CURRENT_SECTOR         $2b // 1 Byte
#define TEMP32A                $2c // 4 Byte
#define TEMP32B                $30 // 4 Byte
#define TEMP32C                $34 // 4 Byte
#define TEMP32D                $38 // 4 Byte
#define BLOCK                  $3c // 4 Byte
#define FORMAT_BLOCKS          $40 // 4 Byte 
#define FORMAT_FS_BLOCKS       $44 // 2 Byte   (100++ Gig of Free Block space)
#define FORMAT_MAPBLOCK        $46 // 2 Byte 
                              
#define SETBITS_PTR            $4a // 2 Byte
                              
#define ROOT_DIRECTORY         $4c // 4 Byte
#define FREE_BLOCK             $50 // 4 Byte
#define BLOCK_TEMP             $56 // 4 Byte
#define USER32A                $5a // 4 Byte
#define USER32B                $5e // 4 Byte
#define USER32C                $62 // 4 Byte
#define USER32D                $66 // 4 Byte
                              
#define TEMP_NUM               $6a // 4 Byte

#define FREE_BLOCK_CACHE_INDEX $72 // 1 Byte
#define FREE_FS_BLOCK          $73 // 2 Byte
#define FREE_BITNUMBER         $75 // 1 Byte
#define FREE_BYTENUMBER        $76 // 2 Byte
#define FREE_BLOCKNO           $78 // 4 Byte

#define INPUT_LEN              $7c // 1 Byte
#define DISK_NUMBER            $7d // 1 Byte
                              
#define SYS_CURDIR             $80 // 4 Byte
#define SYS_BLOCKINDEX         $84 // 2 Byte
#define SYS_UPDATEBLOCK        $86 // 4 Byte
#define SYS_TOTALFILES         $8a // 2 Byte
                              
#define DIR_FILE               $8c // 2 Byte
#define DIR_SHOWN              $8e // 2 Byte
#define GET_NEXTBLOCK          $90 // 4 Byte
#define SYS_FILE_PTR           $94 // 2 Byte
#define SYS_FILE_PTR2          $96 // 2 Byte
#define FILE_NEXTBLOCK         $98 // 4 Byte
#define PRINT_Y                $9c // 1 Byte
#define BLOCK_DEBUG            $9d // 1 Byte 
#define TXT_PTR                $9f // 4 Byte 
#define SYS_OLDDIR             $a3 // 4 Byte
#define FREE_Y                 $a7 // 1 Byte
#define TOTAL_MB               $a8 // 4 Byte
#define FORMAT_MODE            $ac // 1 Byte
#define FILE_TABLE_PTR         $ad // 1 Byte (Allocate 2 Bytes for future)
#define DEL_BLOCK              $ae // 4 Byte

#define CURRENT_FILE_CACHE     $b2 // 1 Byte
#define CACHE_BLK              $b3 // 2 Byte

#define FONT_PTR               $b5 // 2 Byte
#define VGA_ADDR               $b7 // 2 Byte

#define X_POS                  $b9 // 1 Byte
#define Y_POS                  $ba // 1 Byte
#define TEMP_X                 $bb // 1 Byte
#define TEMP_Y                 $bc // 1 Byte
#define FILENAME_MODE          $bd // 1 Byte
#define ORIGINAL_DIR           $be // 4 Byte
#define PROGRAM                $c2 // 2 Byte

#define OutChar_VECTOR            $c4 // 2 Byte
#define PrintString_VECTOR        $c6 // 2 Byte
#define Eof_VECTOR                $c8 // 2 Byte
#define CloseFile_VECTOR          $ca // 2 Byte
#define OpenFile_VECTOR           $cc // 2 Byte
#define WriteByte_VECTOR          $ce // 2 Byte
#define SetVGAMode_VECTOR         $d0 // 2 Byte
#define InACIA_VECTOR             $d2 // 2 Byte
#define OutACIA_VECTOR            $d4 // 2 Byte
#define Getch_VECTOR              $d6 // 2 Byte
#define ReadByte_VECTOR           $d8 // 2 Byte
#define CommandInterpreter_VECTOR $da // 2 Byte
#define Reset_VECTOR              $dc // 2 Byte

#define TEMP_1                    $e0 // 1 Byte
#define TEMP_2                    $e1 // 1 Byte
#define TEMP_3                    $e2 // 1 Byte
#define TEMP_4                    $e3 // 1 Byte
#define TEMP_5                    $e4 // 1 Byte
#define TEMP_6                    $e5 // 1 Byte
#define TEMP_7                    $e6 // 1 Byte

// VGA Device Driver Variables

#define DATA_PTR                  $e7 // 2 Byte
#define REG_COUNT                 $e9 // 1 Byte
#define INDEX_BYTE                $ea // 1 Byte
#define DATA_BYTE                 $eb // 1 Byte
#define PAL_INDEX                 $ec // 1 Byte
#define TEMP_A                    $ed // 1 Byte

// Keyboard State Data

#define SHIFT_DOWN                $ee // 1 Byte

#define LF                     0x0a
#define BACKSLASH              92    // '\' Character 

#define NULL                   0

#define DELAY_COUNT            10
#define DELAY_HIGH             0xff
#define DELAY_LOW              0xff

#define MAX_FILENAME_LENGTH    11

// IDE Controller Constants

#define READ_SECTOR_CMD        0x20
#define WRITE_SECTOR_CMD       0x30
#define DRIVE_INFO_CMD         0xEC
#define DATA_REG               0xf0
#define ERROR_REG              0xf1
#define NUMBER_SECTORS         0xf2
#define SECTOR_NUMBER          0xf3
#define CYLINDER_LSB           0xf4
#define CYLINDER_MSB           0xf5
#define DRIVE_HEAD             0xf6
#define STATUS_REG             0xf7
#define COMMAND_REG            0xf7

// VGA Constants

#define DAC_REG        0xc8
#define DAC_VAL        0xc9
#define ATTRCON_ADDR   0xc0
#define MISC_ADDR      0xc2
#define VGAENABLE_ADDR 0xc3
#define SEQ_ADDR       0xc4
#define GRACON_ADDR    0xce
#define CRTC_ADDR      0xd4
#define STATUS_ADDR    0xda

// Sound Blaster Constants

#define DSP_WRITE_DATA_CMD 0x2c
#define DSP_RESET_PORT     0x26
#define DSP_READ_DATA_PORT 0x2a

// Memory Regions

#define INPUT_PARAM_LEN        64
#define INPUT_BUFFER_LENGTH    64
#define CURRENT_PATH_LENGTH    64
#define MAX_OPEN_FILES         10
#define FILE_TABLE_ENTRY_SIZE  24

#define BUFFER                 $3e00 // 512 Bytes  
#define BUFFER2                $3c00 // 512 Bytes 
#define BLOCK_READ_WRITE       $3a00 // 512 Bytes
#define FILE_MAP               $3800 // 512 Bytes
#define FREE_BLOCK_CACHE       $3780 // 128 Bytes 
#define INPUT_BUFFER           $3740 // 64  Bytes 
#define CURRENT_PATH           $3700 // 64  Bytes 
#define INPUT_PARAM            $36C0 // 64  Bytes
#define FILE_TABLE             $35C0 // 256 Bytes (10 Files open max!)
#define CURRENT_FILE           $35A0 // 32  Bytes (Current file Struct)
#define STRING_BUFFER          $34A0 // 256 Bytes

// OS Defines

#define OS_OFFSET              10   // Allocate blocks for the OS

#define MODE_AVAILABLE         0
#define MODE_READ              1
#define MODE_WRITE             2
#define MODE_APPEND            3

#define COMMAND_DIR            0
#define COMMAND_CD             1
#define COMMAND_FORMAT         2
#define COMMAND_MD             3
#define COMMAND_RD             4
#define COMMAND_FREE           5
#define COMMAND_HELP           6
#define COMMAND_CREATE         7
#define COMMAND_TYPE           8
#define COMMAND_UPLOAD         9
#define COMMAND_DEL            10
#define COMMAND_PLAY           11

#define NONE                   0
#define PATH                   1

.org ROM_ADDRESS

.seg CODE
  jmp Main
.endseg

.seg DATA

#include <font.asm>

lineLut:
    .dw 0*160 +0x8000,1*160 +0x8000,2*160 +0x8000,3*160 +0x8000,4*160 +0x8000,5*160 +0x8000,6*160 +0x8000,7*160 +0x8000,8*160 +0x8000
    .dw 9*160 +0x8000,10*160+0x8000,11*160+0x8000,12*160+0x8000,13*160+0x8000,14*160+0x8000,15*160+0x8000,16*160+0x8000,17*160+0x8000
    .dw 18*160+0x8000,19*160+0x8000,20*160+0x8000,21*160+0x8000,22*160+0x8000,23*160+0x8000,24*160+0x8000

cursorLut:
    .dw 0*80 ,1*80 ,2*80 ,3*80 ,4*80 ,5*80 ,6*80 ,7*80 ,8*80
    .dw 9*80 ,10*80,11*80,12*80,13*80,14*80,15*80,16*80,17*80
    .dw 18*80,19*80,20*80,21*80,22*80,23*80,24*80

mode12:
    .db 108
    .db 0xc2, 0x0,  0xe3
    .db 0xd4, 0x0,  0x5f
    .db 0xd4, 0x1,  0x4f
    .db 0xd4, 0x2,  0x50
    .db 0xd4, 0x3,  0x82
    .db 0xd4, 0x4,  0x54
    .db 0xd4, 0x5,  0x80
    .db 0xd4, 0x6,  0xb
    .db 0xd4, 0x7,  0x3e
    .db 0xd4, 0x8,  0x0
    .db 0xd4, 0x9,  0x40
    .db 0xd4, 0x10, 0xea
    .db 0xd4, 0x11, 0x8c
    .db 0xd4, 0x12, 0xdf
    .db 0xd4, 0x13, 0x28
    .db 0xd4, 0x14, 0x0
    .db 0xd4, 0x15, 0xe7
    .db 0xd4, 0x16, 0x4
    .db 0xd4, 0x17, 0xe3
    .db 0xc4, 0x1,  0x1
    .db 0xc4, 0x2,  0xf
    .db 0xc4, 0x3,  0x0
    .db 0xc4, 0x4,  0x6
    .db 0xce, 0x0,  0x0
    .db 0xce, 0x1,  0x0
    .db 0xce, 0x2,  0x0
    .db 0xce, 0x3,  0x0
    .db 0xce, 0x5,  0x0
    .db 0xce, 0x6,  0x5
    .db 0xce, 0x7,  0xf
    .db 0xce, 0x8,  0xff
    .db 0xc0, 0x10, 0x1
    .db 0xc0, 0x11, 0x0
    .db 0xc0, 0x12, 0xf
    .db 0xc0, 0x13, 0x0
    .db 0xc0, 0x14, 0x0


mode13:
    .db  180
// CRT Registers
    .db  0xd4 , 0x0  , 0x5f
    .db  0xd4 , 0x1  , 0x4f
    .db  0xd4 , 0x2  , 0x50
    .db  0xd4 , 0x3  , 0x82
    .db  0xd4 , 0x4  , 0x54
    .db  0xd4 , 0x5  , 0x80
    .db  0xd4 , 0x6  , 0xbf
    .db  0xd4 , 0x7  , 0x1f
    .db  0xd4 , 0x8  , 0x0
    .db  0xd4 , 0x9  , 0x41
    .db  0xd4 , 0xa  , 0x0
    .db  0xd4 , 0xb  , 0x0
    .db  0xd4 , 0xc  , 0x0
    .db  0xd4 , 0xd  , 0x0
    .db  0xd4 , 0xe  , 0x0
    .db  0xd4 , 0xf  , 0x31
    .db  0xd4 , 0x10 , 0x9c
    .db  0xd4 , 0x11 , 0x8e
    .db  0xd4 , 0x12 , 0x8f
    .db  0xd4 , 0x13 , 0x28
    .db  0xd4 , 0x14 , 0x40
    .db  0xd4 , 0x15 , 0x96
    .db  0xd4 , 0x16 , 0xb9
    .db  0xd4 , 0x17 , 0xa3
    .db  0xd4 , 0x18 , 0xff

// Sequence Registers
    .db  0xc4 , 0x0  , 0x3
    .db  0xc4 , 0x1  , 0x1
    .db  0xc4 , 0x2  , 0xf
    .db  0xc4 , 0x3  , 0x0
    .db  0xc4 , 0x4  , 0xe

// Graphic Control Registers
    .db  0xce , 0x0  , 0x0
    .db  0xce , 0x1  , 0x0
    .db  0xce , 0x2  , 0x0
    .db  0xce , 0x3  , 0x0
    .db  0xce , 0x4  , 0x0
    .db  0xce , 0x5  , 0x40
    .db  0xce , 0x6  , 0x5
    .db  0xce , 0x7  , 0xf
    .db  0xce , 0x8  , 0xff

// Attribute Control Registers
    .db  0xc0 , 0x0 , 0x0
    .db  0xc0 , 0x1 , 0x1
    .db  0xc0 , 0x2 , 0x2
    .db  0xc0 , 0x3 , 0x3
    .db  0xc0 , 0x4 , 0x4
    .db  0xc0 , 0x5 , 0x5
    .db  0xc0 , 0x6 , 0x6
    .db  0xc0 , 0x7 , 0x7
    .db  0xc0 , 0x8 , 0x8
    .db  0xc0 , 0x9 , 0x9
    .db  0xc0 , 0xA , 0xA
    .db  0xc0 , 0xB , 0xB
    .db  0xc0 , 0xC , 0xC
    .db  0xc0 , 0xD , 0xD
    .db  0xc0 , 0xE , 0xE
    .db  0xc0 , 0xF , 0xF
    .db  0xc0 , 0x10 , 0x41
    .db  0xc0 , 0x11 , 0x0
    .db  0xc0 , 0x12 , 0xf
    .db  0xc0 , 0x13 , 0x0
    .db  0xc0 , 0x14 , 0x0

mode3:
    .db  120
    .db  0xc2 , 0x0  , 0x67
    .db  0xd4 , 0x0  , 0x5f
    .db  0xd4 , 0x1  , 0x4f
    .db  0xd4 , 0x2  , 0x50
    .db  0xd4 , 0x3  , 0x82
    .db  0xd4 , 0x4  , 0x55
    .db  0xd4 , 0x5  , 0x81
    .db  0xd4 , 0x6  , 0xbf
    .db  0xd4 , 0x7  , 0x1f
    .db  0xd4 , 0x8  , 0x0
    .db  0xd4 , 0x9  , 0x4f

    .db  0xd4 , 0xa  , 0
    .db  0xd4 , 0xb  , 15

    .db  0xd4 , 0xe  , 0        // Cursor X pos
    .db  0xd4 , 0xf  , 0        // Cursor Y pos

    .db  0xd4 , 0x10 , 0x9c
    .db  0xd4 , 0x11 , 0x8e
    .db  0xd4 , 0x12 , 0x8f
    .db  0xd4 , 0x13 , 0x28
    .db  0xd4 , 0x14 , 0x1f
    .db  0xd4 , 0x15 , 0x96
    .db  0xd4 , 0x16 , 0xb9
    .db  0xd4 , 0x17 , 0xa3
    .db  0xc4 , 0x1  , 0x0
    .db  0xc4 , 0x2  , 0x3
    .db  0xc4 , 0x3  , 0x0
    .db  0xc4 , 0x4  , 0x2
    .db  0xce , 0x0  , 0x0
    .db  0xce , 0x1  , 0x0
    .db  0xce , 0x2  , 0x0
    .db  0xce , 0x3  , 0x0
    .db  0xce , 0x5  , 0x10
    .db  0xce , 0x6  , 0xe
    .db  0xce , 0x7  , 0x0
    .db  0xce , 0x8  , 0xff
    .db  0xc0 , 0x10 , 0xc
    .db  0xc0 , 0x11 , 0x0
    .db  0xc0 , 0x12 , 0xf
    .db  0xc0 , 0x13 , 0x8
    .db  0xc0 , 0x14 , 0x0

pal:
    .db 0 ,0 ,0
    .db 63,63,63
    .db 30,0 ,0 
    .db 35,0 ,0 
    .db 40,0 ,0 
    .db 45,0 ,0 
    .db 50,0 ,0 
    .db 55,55,55
    .db 60,0 ,0 
    .db 63,0 ,0 
    .db 0 ,30,0
    .db 0 ,35,0
    .db 0 ,40,0
    .db 0 ,45,0
    .db 0 ,50,0
    .db 0 ,55,0
    .db 0 ,60,0
    .db 0 ,63,0
    .db 30,0 ,0
    .db 35,0 ,0
    .db 40,0 ,0
    .db 45,0 ,0
    .db 50,0 ,0
    .db 55,0 ,0
    .db 60,0 ,0
    .db 63,0 ,0
    .db 30,0 ,30
    .db 35,0 ,35
    .db 40,0 ,40
    .db 45,0 ,45
    .db 50,0 ,50
    .db 55,0 ,55
    .db 60,0 ,60
    .db 63,0 ,63

#define NUMBER_PAL 34

#define      ESC       27
#define      BS        8
#define      TAB       9
#define      CR        13
#define      SPACE     32

#define      COMMA     44
#define      SEMIC     59
#define      COLEN     58
#define      SQUOTE    39
#define      QUOTE     34
#define      BACKSLASH 92

#define      F1          128
#define      F2          129
#define      F3          130
#define      F4          131
#define      F5          132
#define      F6          133
#define      F7          134
#define      F8          135
#define      F9          136
#define      F10         137
#define      F11         138
#define      F12         139
#define      ALT         140
#define      CTRL        141
#define      SHIFT       142
#define      CAPS_LOCK   143
#define      NUM_LOCK    144
#define      SCROLL_LOCK 145
#define      PAUSE_KEY   146

/* Special Extended Keys */

#define      UP          180
#define      DOWN        181
#define      LEFT        182
#define      RIGHT       183
#define      INSERT      184
#define      DELETE      185
#define      HOME        186
#define      END         187
#define      PGUP        188
#define      PGDN        189
#define      PRINT_SCR   190

SPECIAL_SCAN_CODE_LUT:
    .db 0x70,INSERT
    .db 0x6C,HOME
    .db 0x7D,PGUP
    .db 0x71,DELETE
    .db 0x69,END
    .db 0x7A,PGDN
    .db 0x75,UP
    .db 0x6B,LEFT
    .db 0x72,DOWN
    .db 0x74,RIGHT
    .db 0x4A,'/'
    .db 0x5A,CR
    .db 0x11,ALT
    .db 0x14,CTRL
    .db 0x12,PRINT_SCR
SPECIAL_SCAN_CODE_LUT_END:

SCAN_CODE_LUT:
    .db 0x76,ESC
    .db 0x05,F1
    .db 0x06,F2 
    .db 0x04,F3 
    .db 0x0C,F4 
    .db 0x03,F5 
    .db 0x0B,F6 
    .db 0x83,F7 
    .db 0x0A,F8 
    .db 0x01,F9 
    .db 0x09,F10 
    .db 0x78,F11 
    .db 0x07,F12 

    .db 0x0E,'`'
    .db 0x16,'1'
    .db 0x1E,'2'
    .db 0x26,'3'
    .db 0x25,'4'
    .db 0x2E,'5'
    .db 0x36,'6'
    .db 0x3D,'7'
    .db 0x3E,'8'
    .db 0x46,'9'
    .db 0x45,'0'
    .db 0x4E,'-'
    .db 0x55,'='
    .db 0x66,BS

    .db 0x0D, TAB
    .db 0x54, '['
    .db 0x5B, ']'
    .db 0x5D, BACKSLASH
    .db 0x58, CAPS_LOCK
    .db 0x4C, SEMIC
    .db 0x52, SQUOTE
    .db 0x5A, CR
    .db 0x12, SHIFT
    .db 0x41, COMMA
    .db 0x49, '.'
    .db 0x4A, '/'
    .db 0x59, SHIFT
    .db 0x14, CTRL
    .db 0x11, ALT
    .db 0x29, SPACE

    .db 0x1C,'a'
    .db 0x32,'b'
    .db 0x21,'c'
    .db 0x23,'d'
    .db 0x24,'e'
    .db 0x2B,'f'
    .db 0x34,'g'
    .db 0x33,'h'
    .db 0x43,'i'
    .db 0x3B,'j'
    .db 0x42,'k'
    .db 0x4B,'l'
    .db 0x3A,'m'
    .db 0x31,'n'
    .db 0x44,'o'
    .db 0x4D,'p'
    .db 0x15,'q'
    .db 0x2D,'r'
    .db 0x1B,'s'
    .db 0x2C,'t'
    .db 0x3C,'u'
    .db 0x2A,'v'
    .db 0x1D,'w'
    .db 0x22,'x'
    .db 0x35,'y'
    .db 0x1A,'z'

    .db 0x70,'0'
    .db 0x69,'1'
    .db 0x72,'2'
    .db 0x7A,'3'
    .db 0x6B,'4'
    .db 0x73,'5'
    .db 0x74,'6'
    .db 0x6C,'7'
    .db 0x75,'8'
    .db 0x7D,'9'
    .db 0x71,'.'
    .db 0x77,NUM_LOCK
    .db 0x7C,'*'
    .db 0x7B,'-'
    .db 0x79,'+'

    .db 0x7E,SCROLL_LOCK
SCAN_CODE_LUT_END:

ASCII_SHIFT_TABLE:
    .db 'a','A'
    .db 'b','B'
    .db 'c','C'
    .db 'd','D'
    .db 'e','E'
    .db 'f','F'
    .db 'g','G'
    .db 'h','H'
    .db 'i','I'
    .db 'j','J'
    .db 'k','K'
    .db 'l','L'
    .db 'm','M'
    .db 'n','N'
    .db 'o','O'
    .db 'p','P'
    .db 'q','Q'
    .db 'r','R'
    .db 's','S'
    .db 't','T'
    .db 'u','U'
    .db 'v','V'
    .db 'w','W'
    .db 'x','X'
    .db 'y','Y'
    .db 'z','Z'
    .db '`','~'
    .db '1','!'
    .db '2','@'
    .db '3','#'
    .db '4','$'
    .db '5','%'
    .db '6','^'
    .db '7','&'
    .db '8','*'
    .db '9','('
    .db '0',')'
    .db '-','_'
    .db '=','+'
    .db '[','{'
    .db ']','}'
    .db BACKSLASH,'|'
    .db SEMIC,':'
    .db SQUOTE,'"'
    .db COMMA,'<'
    .db '.','>'
    .db '/','?'
ASCII_SHIFT_TABLE_END:



bitLut:
    .db 128,128+64,128+64+32,128+64+32+16,128+64+32+16+8,128+64+32+16+8+4
    .db 128+64+32+16+8+4+2,128+64+32+16+8+4+2+1

info0:
    .db "HD Model: ",0
info1:                    
    .db "Cyls    : ",0
info2:                       
    .db "Hds     : ",0
info3:                      
    .db "Sec     : ",0
text1:                    
    .db "Max Blks: ",0
text1b:                   
    .db "Total MB: ",0
text2:                         
    .db "FS Blks : ",0
text3:                         
    .db "OS Blks : ",0
text3b:                      
    .db "Root    : ",0

text5:
    .db CR,LF,"Disk Full",CR,LF,0
text6:
    .db "Bad Dir",CR,LF,0
text7:
    .db "Dir Empty",CR,LF,0
text8:
    .db "Expected Arg",CR,LF,0
text9:
    .db "Already exists",CR,LF,0
text11:
    .db "Doesn't exist",CR,LF,0
text12:
    .db "Not a dir",CR,LF,0
text15:
    .db "Dir not empty",CR,LF,0
text16:
    .db "Disk error",CR,LF,0
text17:
    .db "Div/0",CR,LF,0
text18:
    .db "Already Exists",CR,LF,0
text19:
    .db "Too many files open",CR,LF,0
text20:
    .db "Bad FH",CR,LF,0
text21:
    .db "File Not Found",CR,LF,0
text22:
    .db "Filetype mismatch",CR,LF,0
ideErr:
    .db CR,LF,"Disk Err: 0x",0
blockNo:
    .db CR,LF,"On Block: ",0

dirInfo:
    .db CR,LF,"Filename    Attr  Size"
    .db CR,LF,"컴컴컴컴컴컴컴컴컴컴컴컴컴컴",CR,LF,0

HELP:
    .db CR,LF
    .db "DIR,CD,FORMAT,MD,RD,FREE,TYPE,UPLOAD,DEL",CR,LF,CR,LF,0

BIN_DIR:
    .db "BIN         "

cmd1:
    .db "DIR",0,NONE
cmd2:    
    .db "CD",0,PATH
cmd3:
    .db "FORMAT",0,NONE
cmd4:
    .db "MD",0,PATH
cmd5:
    .db "RD",0,PATH
cmd6:
    .db "FREE",0,NONE
cmd7:
    .db "?",0,NONE
cmd8:
    .db "CREATE",0,PATH
cmd9:
    .db "TYPE",0,PATH
cmd10:
    .db "UPLOAD",0,PATH
cmd11:
    .db "DEL",0,PATH
cmd12:
    .db "PLAY",0,PATH

commands:
    .dw cmd1,cmd2,cmd3,cmd4,cmd5,cmd6,cmd7,cmd8,cmd9,cmd10,cmd11,cmd12,0

#define NUMBER_COMMANDS 12

OS_TITLE:
    .db CR,LF,CR,LF
    .db "LAM 32-BIT DOS v1.0",CR,LF,0

hexLut:
    .db "0123456789ABCDEF"

bitLut2:
    .db 128, 64, 32, 16, 8, 4, 2, 1

bitLut3:
    .db (~128)&0xff, (~64)&0xff, (~32)&0xff, (~16)&0xff, (~8)&0xff
    .db (~4)&0xff, (~2)&0xff, (~1)&0xff

#define DIR_SIG1        0
#define DIR_SIG2        1
#define DIR_FILES_LSB   2
#define DIR_FILES_MSB   3
#define DIR_NEXT_LSB_8  4
#define DIR_NEXT_MSB_16 5
#define DIR_NEXT_LSB_24 6
#define DIR_NEXT_MSB_32 7
#define DIR_PREV_LSB_8  8
#define DIR_PREV_MSB_16 9
#define DIR_PREV_LSB_24 10
#define DIR_PREV_MSB_32 11

#define ATTRIB_DEVICE   0
#define ATTRIB_DATAFILE 1
#define ATTRIB_EXE      2
#define ATTRIB_DIR      3

attrib0:
    .db "<DEV> ",0
attrib1:           
    .db "<BIN> ",0
attrib2:           
    .db "<EXE> ",0
attrib3:           
    .db "<DIR> ",0

attribs:
    .dw attrib0,attrib1,attrib2,attrib3

CommandPrompt:
    .db "HD"
DiskNumber:
    .db "0[",0

.endseg

.seg CODE

/************************************************************************/
/************************************************************************/
/************************************************************************/

Main:
  sei 
Main2:     
  jsr Delay 
  jsr Delay 
  jsr Delay 
  jsr ClearMemory 
  jsr InitPIAS
  jsr InitACIA
  jsr SetupVectors
  jsr SetTextMode
  jsr SetVGAPalette
  ldx #<OS_TITLE
  ldy #>OS_TITLE
  jsr PrintString
  jsr InitDiskParams
  jmp CommandInterpreter

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
ClearMemory:
  ldy #0
  lda #0
ClearMemory2:
  sta 0,y             // Clear Zero-Page
  sta FILE_TABLE,y    // Clear File Table
  iny
  bne ClearMemory2

  lda #$ff             // Init Current File Pointer Cache Index
  sta CURRENT_FILE_CACHE 
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
InitDiskParams:
  jsr GetDriveInfo
  jsr SetupFileBlock 
  ldy #2
  lda (ADDRESS),y
  sta CYLINDERS
  iny
  lda (ADDRESS),y
  sta CYLINDERS+1
  ldy #6
  lda (ADDRESS),y   
  sta HEADS
  ldy #12
  lda (ADDRESS),y       
  sta SECTORS
  jsr SetupDriveParams 
  jsr CRLF
  ldx #<info0
  ldy #>info0
  jsr PrintString
  ldy #54
InitDiskParams2:
  iny
  lda (ADDRESS),y
  jsr OutChar
  dey
  lda (ADDRESS),y
  jsr OutChar
  iny
  iny
  cpy #94
  bne InitDiskParams2
  stz FORMAT_MODE 
  jsr Format
  stz DISK_NUMBER
  jsr InitPath
  jsr CRLF
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
InitPath:
  lda #BACKSLASH
  sta CURRENT_PATH
  stz CURRENT_PATH+1
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
CommandInterpreter:
  jsr PrintPrompt
  jsr Input
  cpx #0
  beq CommandInterpreter
  stx INPUT_LEN 
  jsr FindString
  bne ProcessCommand
  jmp TryAndFindCommand

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
ProcessCommand:
  cpy #COMMAND_DIR
  bne ProcessCommand2
  jsr Dir
  jmp CommandInterpreter

ProcessCommand2:
  cpy #COMMAND_CD
  bne ProcessCommand3
  ldy #2
  jsr SetupParam
  beq BadArgument
  jsr CdDir
  jmp CommandInterpreter

ProcessCommand3:               
  cpy #COMMAND_FORMAT                           
  bne ProcessCommand4              
  lda #1
  sta FORMAT_MODE 
  jsr Format
  jmp CommandInterpreter

ProcessCommand4:                 
  cpy #COMMAND_MD
  bne ProcessCommand5
  ldy #2
  jsr SetupParam
  beq BadArgument
  jsr MkDir
  jmp CommandInterpreter

ProcessCommand5:
  cpy #COMMAND_RD
  bne ProcessCommand6
  ldy #2
  jsr SetupParam
  beq BadArgument
  jsr RmDir
  jmp CommandInterpreter

ProcessCommand6:
  cpy #COMMAND_FREE
  bne ProcessCommand7
  jsr DisplayFreeMap
  jmp CommandInterpreter

ProcessCommand7:
  cpy #COMMAND_HELP
  bne ProcessCommand8
  ldx #<HELP
  ldy #>HELP
  jsr PrintString
  jmp CommandInterpreter

BadArgument:
  ldx #<text8
  ldy #>text8
  jsr PrintString
  jmp CommandInterpreter

ProcessCommand8:
  cpy #COMMAND_CREATE
  bne ProcessCommand9
  ldy #6
  jsr SetupParam
  beq BadArgument
  jsr CreateFile
  jmp CommandInterpreter

ProcessCommand9:
  cpy #COMMAND_TYPE
  bne ProcessCommand10
  ldy #4
  jsr SetupParam
  beq BadArgument
  jsr TypeFile
  jmp CommandInterpreter

ProcessCommand10:
  cpy #COMMAND_UPLOAD
  bne ProcessCommand11
  ldy #6
  jsr SetupParam
  beq BadArgument
  jsr UploadFile
  jmp CommandInterpreter

ProcessCommand11:
  cpy #COMMAND_DEL
  bne ProcessCommand12
  ldy #3
  jsr SetupParam
  beq BadArgument
  jsr Del
  jmp CommandInterpreter

ProcessCommand12:
  cpy #COMMAND_PLAY
  bne ProcessCommand13
  ldy #4
  jsr SetupParam
  beq BadArgument
  jsr PlayFile
  jmp CommandInterpreter

ProcessCommand13:

ProcessCommandEnd:
  jmp CommandInterpreter

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
SetupParam:
  cpy INPUT_LEN
  beq BadParam
  ldx #0
  lda #SPACE
SetupParam2:
  sta INPUT_PARAM,x
  inx
  cpx #INPUT_PARAM_LEN
  bne SetupParam2
  ldx #0
SetupParam3:
  lda INPUT_BUFFER,y
  cmp #32
  bne SetupParam4
  iny
  cpy INPUT_LEN
  bne SetupParam3
  bra SetupParam5
SetupParam4:
  sta INPUT_PARAM,x
  inx
  iny
  cpy INPUT_LEN
  bne SetupParam3
SetupParam5:
  cpx #0
  beq BadParam
  lda #SPACE
  sta INPUT_PARAM,x
  inx
  cpx #INPUT_PARAM_LEN
  bne SetupParam5
  lda #1
  rts   
BadParam:
  lda #0
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
PrintPrompt:
  lda #'0'
  clc
  adc DISK_NUMBER
  sta DiskNumber
  ldx #<CommandPrompt
  ldy #>CommandPrompt
  jsr PrintString
  ldx #<CURRENT_PATH
  ldy #>CURRENT_PATH
  jsr PrintString
  lda #']'
  jsr OutChar
  lda #':'
  jsr OutChar
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
FindString:
  ldx #0    
FindString2:
  lda commands,x
  sta ADDRESS
  inx
  lda commands,x
  sta ADDRESS+1
  inx
  ldy #0
SearchSingle:
  lda (ADDRESS),y
  beq FoundCommand
  cmp INPUT_BUFFER,y
  bne NextCommand
  cpy INPUT_LEN
  beq NextCommand 
  iny
  bra SearchSingle  
NextCommand:
  cpx #NUMBER_COMMANDS*2
  bne FindString2 
  lda #0
  rts
FoundCommand:
  dex
  dex
  txa
  lsr A
  tay
  lda #1
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
Input:
  ldx #0
InputLoop:
  jsr SetCursorPos
  jsr Getch  
  bmi InputLoop       // Filter out HIGH bit
  cmp #TAB            // Filter out TAB
  beq InputLoop
  cmp #ESC            // Filter out ESC
  beq InputLoop
  cmp #CR
  bne Input2        
  stz INPUT_BUFFER,x
  bra EndInput
Input2:
  cmp #BS
  bne Input3
  cpx #0
  beq InputLoop
  dex
  jsr OutChar
  lda #32
  jsr OutChar
  lda #BS
  jsr OutChar
  bra InputLoop
Input3:
  cpx #INPUT_BUFFER_LENGTH
  beq InputLoop
  jsr OutChar
  cmp #'a'
  blt InputLoop2
  cmp #'z'+1
  bge InputLoop2
  sec
  sbc #32
InputLoop2:
  sta INPUT_BUFFER,x
  inx
  bra InputLoop
EndInput:
  jsr CRLF
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
CRLF:
  lda #CR
  jsr OutChar
  lda #LF
  jsr OutChar
  jsr SetCursorPos  
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
UploadFile:
   jsr CreateFile
   sta TEMP_1
   jsr CRLF
   lda #'G'
   jsr OutChar
   lda #'O'
   jsr OutChar
   jsr CRLF
   jsr InACIA
   sta TEMP_2
   jsr InACIA
   sta TEMP_3
   jsr InACIA
   sta TEMP_4
   stz TEMP_5
   stz TEMP_6
   stz TEMP_7
Up0:
   ldy #0
Upload1:
   jsr InACIA
   sta STRING_BUFFER,y
   inc TEMP_5
   bne Upload2
   inc TEMP_6
   bne Upload2
   inc TEMP_7
Upload2: 
   iny  
   lda TEMP_2
   cmp TEMP_5
   bne Upload4
   lda TEMP_3
   cmp TEMP_6
   bne Upload4
   lda TEMP_4
   cmp TEMP_7
   beq Upload4b
Upload4:
   cpy #0
   bne Upload1
   jsr UpData
   lda #'.'
   jsr OutACIA
   bra Up0
UpData:
   sty PRINT_Y
   ldx #0
Up3:
   lda STRING_BUFFER,x
   ldy TEMP_1  
   jsr WriteByte
   inx
   cpx PRINT_Y
   bne Up3
   rts
Upload4b:
   jsr UpData
   lda TEMP_1
   jsr CloseFile
   rts

/************************************************************************/
/************************************************************************/
/************************************************************************/
SetVGAPalette:
  lda #3
  jsr SetHighAddress
  ldy #0
  sty PAL_INDEX
SetVGAPalette2:
  ldx #DAC_REG 
  lda PAL_INDEX
  jsr WriteISA
  inc PAL_INDEX
  ldx #DAC_VAL
  lda pal,y
  jsr WriteISA
  iny
  lda pal,y
  jsr WriteISA
  iny
  lda pal,y
  jsr WriteISA
  iny
  cpy #NUMBER_PAL*3
  bne SetVGAPalette2
  rts

/************************************************************************/
/************************************************************************/
/************************************************************************/
SetVGAMode: // Set Mode  ACC=VGA Mode Number
  cmp #$13
  beq mode_13
  cmp #$3
  beq mode_3   
  cmp #$12
  beq mode_12
  rts
mode_12:
  lda #<mode12
  sta DATA_PTR
  lda #>mode12
  sta DATA_PTR+1
  bra SetVGAMode2
mode_13:
  lda #<mode13
  sta DATA_PTR
  lda #>mode13
  sta DATA_PTR+1
  bra SetVGAMode2
mode_3:
  lda #<mode3
  sta DATA_PTR
  lda #>mode3
  sta DATA_PTR+1
SetVGAMode2:
  jsr EnableVGARegs
  ldy #0
  lda (DATA_PTR),y    // Get Register Count
  sta REG_COUNT      // Save Register Count
SetModeLoop: 
  iny
  lda (DATA_PTR),y    // Get Register Address
  tax                // Place register address in X
  iny            
  lda (DATA_PTR),y    // Get Index Register
  sta INDEX_BYTE        
  iny            
  lda (DATA_PTR),y    // Get Data
  sta DATA_BYTE        
  jsr SetVGARegister
  cpy REG_COUNT 
  bne SetModeLoop
  rts

/************************************************************************/
/************************************************************************/
/************************************************************************/

EnableVGARegs:
  jsr UnprotectVGARegs
  lda #3
  jsr SetHighAddress
  ldx #CRTC_ADDR
  lda #0x11
  jsr WriteISA
  ldx #0xd5
  jsr ReadISA
  and #$7f
  pha
  ldx #CRTC_ADDR   
  lda #0x11
  jsr WriteISA
  ldx #0xd5 
  pla
  jsr WriteISA
  rts

/************************************************************************/
/************************************************************************/
/************************************************************************/
UnprotectVGARegs:
  lda #0x46           
  jsr SetHighAddress
  ldx #0xe8
  lda #0x1e
  jsr WriteISA        // Outp(0x46e8,0x1e)
  lda #0x1            
  jsr SetHighAddress
  ldx #0x02
  lda #0x1
  jsr WriteISA        // Outp(0x102,0x1)
  lda #0x46           
  jsr SetHighAddress
  ldx #0xe8
  lda #0x0
  jsr WriteISA        // Outp(0x46e8,0x0) 
  lda #0x1            
  jsr SetHighAddress
  ldx #0x03
  lda #0x0
  jsr WriteISA        // Outp(0x103,0x0) 
  lda #0x3            
  jsr SetHighAddress
  ldx #0xc2
  lda #1
  jsr WriteISA        // Outp(0x3c2,0x1) 
  ldx #0xb8
  lda #1
  jsr WriteISA        // Outp(0x3b8,0x1)  
  lda #0x1            
  jsr SetHighAddress
  ldx #0x02
  lda #0x1
  jsr WriteISA        // Outp(0x102,0x1) 
  lda #0x46           
  jsr SetHighAddress
  ldx #0xe8
  lda #0xe
  jsr WriteISA        // Outp(0x46e8,0xe) 
  lda #0x3            
  jsr SetHighAddress
  ldx #0xd8
  lda #255
  jsr WriteISA        // Outp(0x38d,255) 
  ldx #0xc2
  lda #99
  jsr WriteISA        // Outp(0x3c2,99)  
  ldx #0xda
  lda #0
  jsr WriteISA        // Outp(0x3da,0x0)  
  rts

/************************************************************************/
/************************************************************************/
/************************************************************************/

SetVGARegister:
  lda #3
  jsr SetHighAddress
  cpx #MISC_ADDR
  beq StraightMode
  cpx #VGAENABLE_ADDR
  beq StraightMode
  cpx #SEQ_ADDR
  beq IndexMode
  cpx #GRACON_ADDR
  beq IndexMode
  cpx #CRTC_ADDR
  beq IndexMode
  cpx #ATTRCON_ADDR
  beq AttrMode
  rts
StraightMode:
  lda DATA_BYTE
  jsr WriteISA
  rts
IndexMode:
  lda INDEX_BYTE
  jsr WriteISA
  inx
  lda DATA_BYTE
  jsr WriteISA
  rts
AttrMode:
  ldx #STATUS_ADDR 
  jsr ReadISA
  ldx #ATTRCON_ADDR
  lda INDEX_BYTE 
  cmp #$10
  blt AttrMode2
  ora #$20
AttrMode2:
  jsr WriteISA
  lda DATA_BYTE
  jsr WriteISA
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
WriteVideo:              // Write $A0000+X+Y*256
    pha            
    lda #VIDEO_ADDR
    sta PIA3_DATA_PORT_A 
    stx PIA1_DATA_PORT_A // Set low-Address
    sty PIA1_DATA_PORT_B // Set hi-Address
    lda #OUTPUT_DATA_DIR
    sta PIA2_DATA_DIR_A  // Set Data bus for Output!
    pla
    sta PIA2_DATA_PORT_A // Set data on data-bus
    lda #MEM_W
    sta PIA3_DATA_PORT_B // Turn on IOW
    lda #IO_OFF
    sta PIA3_DATA_PORT_B // Turn off IOW
    rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
WriteVideoText:              // Write $b8000+X+Y*256
    sty PIA1_DATA_PORT_B // Set hi-Address
    stx PIA1_DATA_PORT_A // Set low-Address
    ldx #OUTPUT_DATA_DIR
    stx PIA2_DATA_DIR_A  // Set Data bus for Output!
    sta PIA2_DATA_PORT_A // Set data on data-bus
    lda #TXT_ADDR
    sta PIA3_DATA_PORT_A
    lda #MEM_W
    sta PIA3_DATA_PORT_B // Turn on IOW
    lda #IO_OFF 
    sta PIA3_DATA_PORT_B // Turn off IOW
    rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
SetHighAddress:
    pha
    lda #OUTPUT_DATA_DIR
    sta PIA1_DATA_DIR_B  // Set Data bus for input!
    pla
    sta PIA1_DATA_PORT_B // Set hi-Address
    rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
SetTextMode:
  lda #$13
  jsr SetVGAMode
  lda #$12
  jsr SetVGAMode
  lda #<font
  sta FONT_PTR
  lda #>font
  sta FONT_PTR+1
  stz VGA_ADDR
  stz VGA_ADDR+1
  ldx #0
TextModeLoop:
  ldy #0
SetTextMode2:
  lda (FONT_PTR),y
  phy
  phx
  ldx VGA_ADDR
  ldy VGA_ADDR+1
  jsr WriteVideo
  inc VGA_ADDR
  lda VGA_ADDR
  bne NoInc
  inc VGA_ADDR+1
NoInc:
  plx
  ply
  iny
  cpy #16
  bne SetTextMode2
  lda FONT_PTR
  clc
  adc #16
  bcc NoInc1
  inc FONT_PTR+1
NoInc1:
  sta FONT_PTR
  lda VGA_ADDR
  clc
  adc #16
  bcc NoInc2
  inc VGA_ADDR+1
NoInc2:
  sta VGA_ADDR
  inx
  bne TextModeLoop
DoneText:   
  lda #$3
  jsr SetVGAMode
  jsr ClsTxt
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
ClsTxt:
  lda #OUTPUT_DATA_DIR
  sta PIA2_DATA_DIR_A  // Set Data bus for Output!
  lda #$80
  sta PIA1_DATA_PORT_B  // High-address
  stz PIA1_DATA_PORT_A  // Low Address
ClsTxt2:
  lda #32
  sta PIA2_DATA_PORT_A // Set data on data-bus
  lda #TXT_ADDR
  sta PIA3_DATA_PORT_A // Set Text Address
  lda #MEM_W
  sta PIA3_DATA_PORT_B // Turn on IOW

//  jsr WaitBus

  lda #IO_OFF 
  sta PIA3_DATA_PORT_B // Turn off IOW

  nop
  nop
  nop
  nop
  nop
  nop

  stz PIA3_DATA_PORT_A // Set Text Address

  inc PIA1_DATA_PORT_A
  lda PIA1_DATA_PORT_A 
  bne NoHighInc
  inc PIA1_DATA_PORT_B
NoHighInc:
  lda #7
  sta PIA2_DATA_PORT_A // Set data on data-bus

  lda #TXT_ADDR
  sta PIA3_DATA_PORT_A // Set Text Address
  lda #MEM_W
  sta PIA3_DATA_PORT_B // Turn on IOW

//  jsr WaitBus

  lda #IO_OFF 
  sta PIA3_DATA_PORT_B // Turn off IOW

  nop
  nop
  nop
  nop
  nop
  nop

  stz PIA3_DATA_PORT_A // Set Text Address

  inc PIA1_DATA_PORT_A
  lda PIA1_DATA_PORT_A 
  bne NoHighInc2
  inc PIA1_DATA_PORT_B
NoHighInc2:
  lda PIA1_DATA_PORT_B
  cmp #$8f
  bne ClsTxt2
  lda PIA1_DATA_PORT_A
  cmp #$a0
  bne ClsTxt2
  stz X_POS
  stz Y_POS
  jsr SetCursorPos
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
SetCursorPos:
  phx
  phy
  lda Y_POS
  asl A
  tay
  iny
  lda cursorLut,y
  sta HIGH_BYTE
  dey
  lda cursorLut,y
  clc
  adc X_POS
  bcc NoCursorInc
  inc HIGH_BYTE
NoCursorInc:
  sta LOW_BYTE
  ldx #$d4
  lda HIGH_BYTE
  sta DATA_BYTE
  lda #$e
  sta INDEX_BYTE
  jsr SetVGARegister
  ldx #$d4
  lda LOW_BYTE
  sta DATA_BYTE
  lda #$f
  sta INDEX_BYTE
  jsr SetVGARegister
  ply
  plx
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
OutChar:
  pha
  phx  
  phy
  cmp #CR
  beq OutCR
  cmp #LF
  beq Incy
  cmp #BS
  beq OutBS
  pha 
  lda X_POS
  asl A
  sta SAVE_A
WriteChar2:
  lda Y_POS
  asl A
  tay
  iny
  lda lineLut,y
  sta TEMP_A
  dey
  lda lineLut,y
  clc
  adc SAVE_A
  bcc NoIncHigh
  inc TEMP_A
NoIncHigh:
  tax
  ldy TEMP_A
  pla
  jsr WriteVideoText

  inc X_POS
  lda X_POS
  cmp #80
  bne OutText2
  stz X_POS
Incy:
  inc Y_POS
  lda Y_POS
  cmp #25
  bne OutText2
  dec Y_POS
  jsr ScrollScreen
OutText2:
  ply
  plx
  pla
  rts
OutCR:
  stz X_POS 
  ply
  plx
  pla
  rts
OutBS:
  lda X_POS
  beq OutText2
  dec X_POS
  bra OutText2

/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
ScrollScreen:
  ldy #1
  lda #TXT_ADDR
  sta PIA3_DATA_PORT_A
Scroll0: 
  lda #INPUT_DATA_DIR
  sta PIA2_DATA_DIR_A  // Set Data bus for Input!
  tya
  asl A
  tax
  lda lineLut,x
  sta PIA1_DATA_PORT_A
  inx
  lda lineLut,x
  sta PIA1_DATA_PORT_B
  ldx #0
Scroll2:  
  lda #MEM_R
  sta PIA3_DATA_PORT_B // Turn on IOR
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  lda PIA2_DATA_PORT_A
  sta STRING_BUFFER,x
  lda #IO_OFF 
  sta PIA3_DATA_PORT_B // Turn off IOR
  inc PIA1_DATA_PORT_A
  bne Add2_b
  inc PIA1_DATA_PORT_B
  inc PIA1_DATA_PORT_A 
  bra Add2_c
Add2_b:
  inc PIA1_DATA_PORT_A
  bne Add2_c
  inc PIA1_DATA_PORT_B
Add2_c:
  inx
  cpx #80
  bne Scroll2
  dey
  lda #OUTPUT_DATA_DIR
  sta PIA2_DATA_DIR_A  // Set Data bus for Output!
  tya
  asl A
  tax
  lda lineLut,x
  sta PIA1_DATA_PORT_A
  inx
  lda lineLut,x
  sta PIA1_DATA_PORT_B
  ldx #0
Scroll3:
  lda STRING_BUFFER,x
  sta PIA2_DATA_PORT_A
  lda #MEM_W
  sta PIA3_DATA_PORT_B // Turn on IOW
  lda #IO_OFF 
  sta PIA3_DATA_PORT_B // Turn off IOR
  inc PIA1_DATA_PORT_A
  bne Add2_b2
  inc PIA1_DATA_PORT_B
  inc PIA1_DATA_PORT_A 
  bra Add2_c2
Add2_b2:
  inc PIA1_DATA_PORT_A
  bne Add2_c2
  inc PIA1_DATA_PORT_B
Add2_c2:
  inx
  cpx #80
  bne Scroll3
  iny
  iny
  cpy #25
  bge DoneScroll
  jmp Scroll0
DoneScroll:
  ldy #24
  tya
  asl A
  tax
  lda lineLut,x
  sta PIA1_DATA_PORT_A
  inx
  lda lineLut,x
  sta PIA1_DATA_PORT_B
  ldx #0
Scroll4:
  lda #32
  sta PIA2_DATA_PORT_A
  lda #MEM_W
  sta PIA3_DATA_PORT_B // Turn on IOW
  lda #IO_OFF 
  sta PIA3_DATA_PORT_B // Turn off IOR
  inc PIA1_DATA_PORT_A
  bne Add2_b3
  inc PIA1_DATA_PORT_B
  inc PIA1_DATA_PORT_A 
  bra Add2_c3
Add2_b3:
  inc PIA1_DATA_PORT_A
  bne Add2_c3
  inc PIA1_DATA_PORT_B
Add2_c3:
  inx
  cpx #80
  bne Scroll4
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
ReadISA:                 // Read ISA Bus I/O Port (ADDLOW=X, ADDHIGH=Y, Data=ACC)
    stx PIA1_DATA_PORT_A // Set low-Address
    lda #INPUT_DATA_DIR
    sta PIA2_DATA_DIR_A  // Set Data bus for input!
    lda #IO_R
    sta PIA3_DATA_PORT_B // Turn on I/O Read
    nop
    nop
    nop
    lda PIA2_DATA_PORT_A // Acquire Data from data-bus
    pha
    lda #IO_OFF 
    sta PIA3_DATA_PORT_B // Turn off I/O Read
    pla
    rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
WriteISA:                // Write ISA Bus I/O Port (ADDLOW=X, ADDHIGH=Y, Data=ACC) 
    pha            
    stx PIA1_DATA_PORT_A // Set low-Address
    lda #OUTPUT_DATA_DIR
    sta PIA2_DATA_DIR_A  // Set Data bus for Output!
    pla
    sta PIA2_DATA_PORT_A // Set data on data-bus
    lda #IO_W
    sta PIA3_DATA_PORT_B // Turn on IOW
    lda #IO_OFF 
    sta PIA3_DATA_PORT_B // Turn off IOW
    rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
InitACIA:
     stz ACIA_STATUS     
     lda ACIA_DATA       // Init 6551 ACIA Hardware 
     lda ACIA_DATA       // Programmed Reset        
     lda ACIA_DATA       // Clear Data              
     lda ACIA_DATA      
                        
     lda #11             // Set DTR, Disable IRQ
     sta ACIA_COMMAND    // Command Register
     lda #BPS_19200_8N1  // Set Baud, 8-n-1, Use Crystal
     sta ACIA_CONTROL    // Control Register
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
InACIA:                 // Wait for data from ACIA Serial Port in ACC
     lda ACIA_STATUS
     and #8
     cmp #8
     bne InACIA
     lda ACIA_DATA
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
OutACIA:               // Send ACC to the ACIA Serial Port
     pha
OutACIA2:
     lda ACIA_STATUS
     and #16
     cmp #16
     bne OutACIA2
     pla
     sta ACIA_DATA
     rts

/************************************************************************/
/************************************************************************/
/************************************************************************/
PrintString:
  stx TXT_PTR
  sty TXT_PTR+1
  ldy #0
PrintString2:
  lda (TXT_PTR),y
  beq PrintString3
  jsr OutChar     
  iny
  bra PrintString2
PrintString3:
  jsr SetCursorPos 
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
InitPIAS:                 // Init PIA 6522 Hardware
     lda #$ff
     sta PIA1_DATA_DIR_B // Set 6522#1 Port B as output
     sta PIA1_DATA_DIR_A // Set 6522#1 Port A as output 
     sta PIA2_DATA_DIR_B // Set 6522#2 Port B as output 
     sta PIA2_DATA_DIR_A // Set 6522#2 Port A as output 
     sta PIA3_DATA_DIR_A // Set 6522#2 Port A as output 
     
     lda #$0f            // Low 4 bits are outputs, High 4 bits are inputs
     sta PIA3_DATA_DIR_B // Set 6522#2 Port A as output 


     stz PIA1_DATA_PORT_B
     stz PIA1_DATA_PORT_A
     stz PIA2_DATA_PORT_B
     stz PIA2_DATA_PORT_A
     stz PIA3_DATA_PORT_A  // High 4 bits of ISA address
     lda #IO_OFF
     sta PIA3_DATA_PORT_B  // Turn IO Off
        
     /* Setup Keyboard PIA */

     stz PIA4_DATA_DIR_B // Set 6522#4 Port B as Input
     stz PIA4_DATA_DIR_A // Set 6522#4 Port A as Input
     stz PIA4_DATA_PORT_B
     stz PIA4_DATA_PORT_A

     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
ReadJoystick:
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
Delay:
     phx
     phy
     ldx #DELAY_HIGH
Delay1:
     ldy #DELAY_LOW
Delay2:
     dey
     bne Delay2
     dex
     bne Delay1
     ply
     plx
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
GetDriveInfo:
     lda #1
     jsr SetHighAddress    /* Hard Disk Registers $1xx */
     jsr WaitBusy
     lda #160               /* Drive 0, Head (8 Bit)    */
     ldx #DRIVE_HEAD
     jsr WriteISA       
     lda #DRIVE_INFO_CMD  /* Issue READ command       */
     ldx #COMMAND_REG
     jsr WriteISA
     jsr WaitTransferReady
     jsr SetupFileBlock
     jsr ReadSector
     jsr WaitBusy
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
ReadBlock:
     phx
     phy
     lda #1
     jsr SetHighAddress    /* Hard Disk Registers $1xx */
     jsr SetDriveCommands
     lda #READ_SECTOR_CMD  /* Issue READ command       */
     ldx #COMMAND_REG
     jsr WriteISA
     jsr WaitTransferReady
     jsr ReadSector
     jsr WaitBusy
     ply
     plx
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
WriteBlock:
     phx
     phy
     lda #1
     jsr SetHighAddress    /* Hard Disk Registers $1xx */
     jsr SetDriveCommands
     lda #WRITE_SECTOR_CMD /* Issue WRITE command      */
     ldx #COMMAND_REG
     jsr WriteISA
     jsr WaitTransferReady
     jsr WriteSector
     jsr WaitBusy
     ply
     plx
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
SetDriveCommands:
     jsr SetLBA  
     jsr WaitBusy
     lda #1                 /* One Sector               */
     ldx #NUMBER_SECTORS
     jsr WriteISA       
     lda CURRENT_SECTOR     /* Sector Number (8 Bit)    */
     ldx #SECTOR_NUMBER
     jsr WriteISA       
     lda CURRENT_CYLINDER   /* Cylinder (LSB)           */
     ldx #CYLINDER_LSB
     jsr WriteISA       
     lda CURRENT_CYLINDER+1 /* Cylinder (MSB)           */
     ldx #CYLINDER_MSB
     jsr WriteISA       
     lda #160               /* Drive 0, Head (8 Bit)    */
     clc
     adc CURRENT_HEAD
     ldx #DRIVE_HEAD
     jsr WriteISA       
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
WaitTransferReady:
     ldx #STATUS_REG
     jsr ReadISA
     and #$88
     cmp #$8
     bne WaitTransferReady
     jsr CheckIDEErr
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
WaitBusy:
     ldx #STATUS_REG
     jsr ReadISA
     and #$80
     cmp #$80
     beq WaitBusy
     jsr CheckIDEErr
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
CheckIDEErr:
     ldx #STATUS_REG
     jsr ReadISA
     and #$1
     cmp #$1
     beq IDEErr
NoErr:
     rts
IDEErr:
     ldx #ERROR_REG
     jsr ReadISA
     beq NoErr
     pha
     ldx #<ideErr
     ldy #>ideErr
     jsr PrintString
     pla
     jsr PrintByte
     ldx #<blockNo
     ldy #>blockNo
     jsr PrintString
     lda BLOCK
     sta TEMP_NUM
     lda BLOCK+1
     sta TEMP_NUM+1
     lda BLOCK+2
     sta TEMP_NUM+2
     lda BLOCK+3
     sta TEMP_NUM+3
     jsr Print32BitNumber
     jsr CRLF
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
DumpBlock:
     ldy #0
     ldx #0   
     lda BLOCK
     sta TEMP_NUM
     lda BLOCK+1
     sta TEMP_NUM+1
     lda BLOCK+2
     sta TEMP_NUM+2
     lda BLOCK+3
     sta TEMP_NUM+3
     jsr Print32BitNumber
     jsr CRLF 
DumpBuffer2:
     lda (ADDRESS),y
     jsr PrintByte
     lda #SPACE
     jsr OutChar
     iny
     lda (ADDRESS),y
     iny
     jsr PrintByte
     lda #SPACE
     jsr OutChar
     cpy #0
     bne DumpBuffer2 
     inc ADDRESS+1
     inx
     cpx #2
     bne DumpBuffer2
DumpBuffer3:
     jsr CRLF
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
ReadSector:
     ldx #DATA_REG  
     stx PIA1_DATA_PORT_A // Set low-Address 
     lda #INPUT_DATA_DIR
     sta PIA2_DATA_DIR_A  // Set Data bus for input (8 LSB)!
     sta PIA2_DATA_DIR_B  // Set Data bus for input (8 MSB)!

     ldy #0
     ldx #0
ReadSector2:

     lda #IO_R
     sta PIA3_DATA_PORT_B // Turn on I/O Read
     lda PIA2_DATA_PORT_A // Acquire Data from data-bus (8 LSB)!
     sta (ADDRESS),y 
     iny
     lda PIA2_DATA_PORT_B // Acquire Data from data-bus (8 LSB)!
     sta (ADDRESS),y 
     iny 
     lda #IO_OFF 
     sta PIA3_DATA_PORT_B // Turn off I/O Read

     cpy #0
     bne ReadSector2 
     inc ADDRESS+1
     inx
     cpx #2
     bne ReadSector2
ReadSector3:
     dec ADDRESS+1
     dec ADDRESS+1
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
WriteSector:
     ldx #DATA_REG 
     stx PIA1_DATA_PORT_A // Set low-Address
     lda #OUTPUT_DATA_DIR
     sta PIA2_DATA_DIR_A  // Set Data bus for Output!
     sta PIA2_DATA_DIR_B  // Set Data bus for input (8 MSB)!

     ldy #0
     ldx #0
WriteSector2:

     lda (ADDRESS),y
     sta PIA2_DATA_PORT_A // Set Data on data-bus (8 LSB)!  
     iny
     lda (ADDRESS),y
     sta PIA2_DATA_PORT_B // Set Data on data-bus (8 LSB)!  
     iny
     lda #IO_W
     sta PIA3_DATA_PORT_B // Turn on IOW
     lda #IO_OFF 
     sta PIA3_DATA_PORT_B // Turn off IOW

     cpy #0
     bne WriteSector2
     inc ADDRESS+1
     inx       
     cpx #2
     bne WriteSector2
WriteSector3:
     dec ADDRESS+1
     dec ADDRESS+1
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
SetupDriveParams:
     lda CYLINDERS
     sta MATH_PARAM3
     lda CYLINDERS+1
     sta MATH_PARAM3+1
     stz MATH_PARAM3+2
     stz MATH_PARAM3+3
     lda HEADS
     sta MATH_PARAM2
     stz MATH_PARAM2+1
     stz MATH_PARAM2+2
     stz MATH_PARAM2+3
     jsr mult32
     lda MATH_PARAM0
     sta MATH_PARAM3
     lda MATH_PARAM0+1
     sta MATH_PARAM3+1
     lda MATH_PARAM0+2
     sta MATH_PARAM3+2
     lda MATH_PARAM0+3
     sta MATH_PARAM3+3
     lda SECTORS
     sta MATH_PARAM2
     stz MATH_PARAM2+1
     stz MATH_PARAM2+2
     stz MATH_PARAM2+3
     jsr mult32
     lda MATH_PARAM0
     sta TOTAL_BLOCKS
     sta MATH_PARAM2
     lda MATH_PARAM0+1
     sta TOTAL_BLOCKS+1
     sta MATH_PARAM2+1
     lda MATH_PARAM0+2
     sta TOTAL_BLOCKS+2
     sta MATH_PARAM2+2
     lda MATH_PARAM0+3
     sta TOTAL_BLOCKS+3
     sta MATH_PARAM2+3

     lda #8
     sta MATH_PARAM0+1
     stz MATH_PARAM0
     stz MATH_PARAM0+2
     stz MATH_PARAM0+3

     jsr udiv32

     lda MATH_PARAM2
     sta TOTAL_MB
     lda MATH_PARAM2+1
     sta TOTAL_MB+1
     lda MATH_PARAM2+2
     sta TOTAL_MB+2
     lda MATH_PARAM2+3
     sta TOTAL_MB+3
      
     rts
   
/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
SetLBA:
     stz MATH_PARAM3+1
     stz MATH_PARAM3+2
     stz MATH_PARAM3+3
     stz MATH_PARAM2+1
     stz MATH_PARAM2+2
     stz MATH_PARAM2+3
     lda HEADS
     sta MATH_PARAM3
     lda SECTORS
     sta MATH_PARAM2
     jsr mult32
     lda MATH_PARAM0
     sta USER32A
     lda MATH_PARAM0+1
     sta USER32A+1
     lda MATH_PARAM0+2
     sta USER32A+2
     lda MATH_PARAM0+3
     sta USER32A+3          // USER32a = (SECTORS * HEADS)
     lda BLOCK
     sta USER32B
     sta MATH_PARAM2
     lda BLOCK+1
     sta USER32B    +1
     sta MATH_PARAM2+1
     lda BLOCK+2
     sta USER32B    +2
     sta MATH_PARAM2+2
     lda BLOCK+3
     sta USER32B    +3      // USER32b = LBA
     sta MATH_PARAM2+3
     lda USER32A
     sta MATH_PARAM0
     lda USER32A+1
     sta MATH_PARAM0+1
     lda USER32A+2
     sta MATH_PARAM0+2
     lda USER32A+3
     sta MATH_PARAM0+3
     jsr udiv32
     lda MATH_PARAM2
     sta CURRENT_CYLINDER
     lda MATH_PARAM2+1
     sta CURRENT_CYLINDER+1
     lda USER32A
     sta MATH_PARAM3
     lda USER32A+1
     sta MATH_PARAM3+1
     lda USER32A+2
     sta MATH_PARAM3+2
     lda USER32A+3
     sta MATH_PARAM3+3
     jsr mult32
     sec
     lda USER32B
     sbc MATH_PARAM0
     sta MATH_PARAM2
     sta USER32B
     lda USER32B+1
     sbc MATH_PARAM0+1
     sta MATH_PARAM2+1
     sta USER32B+1
     lda USER32B+2
     sbc MATH_PARAM0+2
     sta MATH_PARAM2+2
     sta USER32B+2
     lda USER32B+3
     sbc MATH_PARAM0+3
     sta MATH_PARAM2+3
     sta USER32B+3
     lda SECTORS
     sta MATH_PARAM0
     stz MATH_PARAM0+1
     stz MATH_PARAM0+2
     stz MATH_PARAM0+3
     jsr udiv32
     lda MATH_PARAM2
     sta CURRENT_HEAD
     sta MATH_PARAM3
     stz MATH_PARAM3+1
     stz MATH_PARAM3+2
     stz MATH_PARAM3+3
     lda SECTORS
     sta MATH_PARAM2
     stz MATH_PARAM2+1
     stz MATH_PARAM2+2
     stz MATH_PARAM2+3
     jsr mult32
     sec
     lda USER32B
     sbc MATH_PARAM0
     clc
     adc #1
     sta CURRENT_SECTOR
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
Format:

// fs_map   =  0
// mapBlock =  0
   stz FORMAT_FS_BLOCKS
   stz FORMAT_FS_BLOCKS+1
   stz FORMAT_MAPBLOCK
   stz FORMAT_MAPBLOCK+1

// blocks-=OS_OFFSET
   sec
   lda TOTAL_BLOCKS
   sbc #OS_OFFSET
   sta FORMAT_BLOCKS
   lda TOTAL_BLOCKS+1
   sbc #0
   sta FORMAT_BLOCKS+1
   lda TOTAL_BLOCKS+2
   sbc #0
   sta FORMAT_BLOCKS+2
   lda TOTAL_BLOCKS+3
   sbc #0
   sta FORMAT_BLOCKS+3

FormatLoop:
   inc FORMAT_FS_BLOCKS
   bne FormatLoop2
   inc FORMAT_FS_BLOCKS+1
FormatLoop2:

   // blocks -=4096   
   sec
   lda FORMAT_BLOCKS
   sbc #0
   sta FORMAT_BLOCKS
   lda FORMAT_BLOCKS+1
   sbc #$10
   sta FORMAT_BLOCKS+1
   lda FORMAT_BLOCKS+2
   sbc #0
   sta FORMAT_BLOCKS+2
   lda FORMAT_BLOCKS+3
   sbc #0
   sta FORMAT_BLOCKS+3

//  if (fs_map >= blocks)  
   lda FORMAT_BLOCKS+3
   and #$80
   cmp #$80
   beq FormatInside
   lda FORMAT_BLOCKS+3
   bne FormatLoop3
   lda FORMAT_BLOCKS+2
   bne FormatLoop3

   lda FORMAT_FS_BLOCKS+1
   cmp FORMAT_BLOCKS+1
   blt FormatLoop3
   lda FORMAT_FS_BLOCKS+1
   cmp FORMAT_BLOCKS+1
   beq CheckLow
   bra FormatInside
CheckLow:
   lda FORMAT_FS_BLOCKS
   cmp FORMAT_BLOCKS
   blt FormatLoop3
FormatInside:

   // 1-2=3
   // fs_map-blocks 

   sec
   lda FORMAT_FS_BLOCKS
   sbc FORMAT_BLOCKS
   sta MATH_PARAM2
   lda FORMAT_FS_BLOCKS+1
   sbc FORMAT_BLOCKS+1
   sta MATH_PARAM2+1
   lda #0
   sbc FORMAT_BLOCKS+2
   sta MATH_PARAM2+2
   lda #0
   sbc FORMAT_BLOCKS+3
   sta MATH_PARAM2+3

   sec
   lda #0
   sbc MATH_PARAM2
   sta MATH_PARAM3
   lda #$10
   sbc MATH_PARAM2+1
   sta MATH_PARAM3+1
   lda #$0
   sbc MATH_PARAM2+2
   sta MATH_PARAM3+2
   lda #$0
   sbc MATH_PARAM2+3
   sta MATH_PARAM3+3
   
   lda FORMAT_MODE
   beq FormatMode0
   jsr SetBits    // Number of BITS in MATH_PARAM3
   jsr WriteFSMap
FormatMode0:
   bra FormatDone1

FormatLoop3:
   lda FORMAT_MODE 
   beq FormatMode1 
   jsr SetupFileBlock2
   lda #255
   jsr SetBlock
   jsr WriteFSMap
FormatMode1: 

   // mapBlock++   
   inc FORMAT_MAPBLOCK
   bne FormatLoop4
   inc FORMAT_MAPBLOCK+1
FormatLoop4:
   jmp FormatLoop

FormatDone1:

   jsr CRLF
   jsr PrintDriveInfo
   ldx #<text2
   ldy #>text2
   jsr PrintString
   lda FORMAT_FS_BLOCKS
   sta TEMP_NUM
   lda FORMAT_FS_BLOCKS+1
   sta TEMP_NUM+1
   stz TEMP_NUM+2
   stz TEMP_NUM+3
   jsr Print32BitNumber
   jsr CRLF

   ldx #<text3
   ldy #>text3
   jsr PrintString
   lda #OS_OFFSET
   sta TEMP_NUM
   stz TEMP_NUM+1
   stz TEMP_NUM+2
   stz TEMP_NUM+3
   jsr Print32BitNumber
   jsr CRLF

   lda FORMAT_MODE
   bne FormatMode2  

   clc
   lda #OS_OFFSET
   adc FORMAT_FS_BLOCKS
   sta ROOT_DIRECTORY
   lda #0
   adc FORMAT_FS_BLOCKS+1
   sta ROOT_DIRECTORY+1
   lda #0
   adc #0
   sta ROOT_DIRECTORY+2
   lda #0
   adc #0
   sta ROOT_DIRECTORY+3

   bra FormatMode3

FormatMode2:
// root_directory = GetFreeBlock() 

   jsr GetFreeBlock


   lda FREE_BLOCK
   sta ROOT_DIRECTORY
   lda FREE_BLOCK+1
   sta ROOT_DIRECTORY+1
   lda FREE_BLOCK+2
   sta ROOT_DIRECTORY+2
   lda FREE_BLOCK+3
   sta ROOT_DIRECTORY+3
FormatMode3:

   ldx #<text3b
   ldy #>text3b
   jsr PrintString
   lda ROOT_DIRECTORY
   sta TEMP_NUM
   lda ROOT_DIRECTORY+1
   sta TEMP_NUM+1
   lda ROOT_DIRECTORY+2
   sta TEMP_NUM+2
   lda ROOT_DIRECTORY+3
   sta TEMP_NUM+3
   jsr Print32BitNumber
   jsr CRLF

   lda FORMAT_MODE
   bne FormatMode4
   bra SetDir
FormatMode4:

// memset(block,0,512) 
   jsr SetupFileBlock
   lda #0
   jsr SetBlock

   ldy #DIR_SIG1
   lda #$AA
   sta (ADDRESS),y
   ldy #DIR_SIG2
   lda #$55
   sta (ADDRESS),y


   ldy #DIR_PREV_LSB_8
   lda ROOT_DIRECTORY
   sta (ADDRESS),y
   ldy #DIR_PREV_MSB_16
   lda ROOT_DIRECTORY+1
   sta (ADDRESS),y
   ldy #DIR_PREV_LSB_24
   lda ROOT_DIRECTORY+2
   sta (ADDRESS),y
   ldy #DIR_PREV_MSB_32
   lda ROOT_DIRECTORY+3
   sta (ADDRESS),y

   lda ROOT_DIRECTORY
   sta BLOCK
   lda ROOT_DIRECTORY+1
   sta BLOCK+1
   lda ROOT_DIRECTORY+2
   sta BLOCK+2
   lda ROOT_DIRECTORY+3
   sta BLOCK+3

   jsr WriteBlock

   lda #0
   jsr SetBlock

SetDir:
   lda ROOT_DIRECTORY
   sta SYS_CURDIR
   lda ROOT_DIRECTORY+1
   sta SYS_CURDIR+1
   lda ROOT_DIRECTORY+2
   sta SYS_CURDIR+2
   lda ROOT_DIRECTORY+3
   sta SYS_CURDIR+3
   jsr CRLF
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
PrintDriveInfo:
   ldx #<info1
   ldy #>info1
   jsr PrintString
   lda CYLINDERS
   sta TEMP_NUM
   lda CYLINDERS+1
   sta TEMP_NUM+1
   stz TEMP_NUM+2
   stz TEMP_NUM+3
   jsr Print32BitNumber
   jsr CRLF
   ldx #<info2
   ldy #>info2
   jsr PrintString
   lda HEADS
   sta TEMP_NUM
   stz TEMP_NUM+1
   stz TEMP_NUM+2
   stz TEMP_NUM+3
   jsr Print32BitNumber
   jsr CRLF
   ldx #<info3
   ldy #>info3
   jsr PrintString
   lda SECTORS
   sta TEMP_NUM
   stz TEMP_NUM+1
   stz TEMP_NUM+2
   stz TEMP_NUM+3
   jsr Print32BitNumber
   jsr CRLF
   ldx #<text1
   ldy #>text1
   jsr PrintString
   lda TOTAL_BLOCKS
   sta TEMP_NUM
   lda TOTAL_BLOCKS+1
   sta TEMP_NUM+1
   lda TOTAL_BLOCKS+2
   sta TEMP_NUM+2
   lda TOTAL_BLOCKS+3
   sta TEMP_NUM+3
   jsr Print32BitNumber
   jsr CRLF
   ldx #<text1b
   ldy #>text1b
   jsr PrintString
   lda TOTAL_MB
   sta TEMP_NUM
   lda TOTAL_MB+1
   sta TEMP_NUM+1
   lda TOTAL_MB+2
   sta TEMP_NUM+2
   lda TOTAL_MB+3
   sta TEMP_NUM+3
   jsr Print32BitNumber
   jsr CRLF
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
PrintByte:
   phy
   pha
   and #$f0
   lsr A
   lsr A
   lsr A
   lsr A
   tay
   lda hexLut,y
   jsr OutChar
   pla
   and #$f
   tay
   lda hexLut,y
   jsr OutChar
   ply
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
LoadDir:
   lda SYS_CURDIR
   sta SYS_UPDATEBLOCK
   sta BLOCK
   lda SYS_CURDIR     +1
   sta SYS_UPDATEBLOCK+1
   sta BLOCK          +1
   lda SYS_CURDIR     +2
   sta SYS_UPDATEBLOCK+2
   sta BLOCK          +2
   lda SYS_CURDIR     +3
   sta SYS_UPDATEBLOCK+3
   sta BLOCK          +3
   
   jsr SetupFileBlock
   jsr ReadBlock

   ldy #DIR_SIG1
   lda (ADDRESS),y
   cmp #$aa
   bne BadDir

   ldy #DIR_SIG2
   lda (ADDRESS),y
   cmp #$55
   bne BadDir

   lda #12
   sta SYS_BLOCKINDEX
   stz SYS_BLOCKINDEX+1

   ldy #DIR_FILES_LSB
   lda (ADDRESS),y   
   sta SYS_TOTALFILES
   iny
   lda (ADDRESS),y   
   sta SYS_TOTALFILES+1
   lda #1
   rts
BadDir:
   ldx #<text6
   ldy #>text6 
   jsr PrintString
   stz SYS_TOTALFILES
   stz SYS_TOTALFILES+1
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
FindFile:
   jsr LoadDir
   beq EndFindFileLoop
   stz DIR_FILE
   stz DIR_FILE+1
FindFileLoop:
   lda DIR_FILE+1
   cmp SYS_TOTALFILES+1
   bne FindFileLoop2
   lda DIR_FILE
   cmp SYS_TOTALFILES 
   beq EndFindFileLoop
FindFileLoop2:
   jsr GetFile
   beq FindFileLoopBottom
   jsr TestFilename
   beq FindFileLoopBottom 
   lda #1
   rts

FindFileLoopBottom:
   inc DIR_FILE
   bne SkipGetFreeInc2
   inc DIR_FILE+1
SkipGetFreeInc2:
   bra FindFileLoop

EndFindFileLoop:
   lda #0
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
TryAndFindCommand: 
   lda SYS_CURDIR       // Save original Directory
   sta ORIGINAL_DIR
   lda SYS_CURDIR  +1
   sta ORIGINAL_DIR+1
   lda SYS_CURDIR  +2
   sta ORIGINAL_DIR+2
   lda SYS_CURDIR  +3
   sta ORIGINAL_DIR+3
   lda ROOT_DIRECTORY
   sta SYS_CURDIR
   lda ROOT_DIRECTORY+1
   sta SYS_CURDIR    +1
   lda ROOT_DIRECTORY+2
   sta SYS_CURDIR    +2
   lda ROOT_DIRECTORY+3
   sta SYS_CURDIR    +3
   lda #1
   sta FILENAME_MODE
   jsr FindFile 
   bne TryAndFindCommand2
TryAndFindCommand1:
   lda ORIGINAL_DIR
   sta SYS_CURDIR       // Save original Directory
   lda ORIGINAL_DIR+1
   sta SYS_CURDIR  +1
   lda ORIGINAL_DIR+2
   sta SYS_CURDIR  +2
   lda ORIGINAL_DIR+3
   sta SYS_CURDIR  +3
   jmp CommandInterpreter

TryAndFindCommand2:
   jsr CdDir4
   ldy #0
Tryb:
   lda INPUT_BUFFER,y
   beq Tryc
   sta INPUT_PARAM,y
   iny
   cpy #14
   bne Tryb
Tryc:
   lda #SPACE
   sta INPUT_PARAM,y 
   cpy #14
   beq Tryd
   iny
   bra Tryc
Tryd:
   jsr OpenFile
   cmp #$ff
   beq TryAndFindCommand1
   sta TEMP_1
   lda #<PROGRAM_BUFFER
   sta PROGRAM
   lda #>PROGRAM_BUFFER
   sta PROGRAM+1
   ldy #0
Try0:
   sty TEMP_2
   lda TEMP_1
   jsr Eof
   beq TryEnd2
   lda TEMP_1
   jsr ReadByte
   ldy TEMP_2 
   sta (PROGRAM),y
   iny
   bne Try0
   inc PROGRAM+1
   bra Try0
TryEnd2:
   lda TEMP_1
   jsr CloseFile
   lda ORIGINAL_DIR
   sta SYS_CURDIR       // Save original Directory
   lda ORIGINAL_DIR+1
   sta SYS_CURDIR  +1
   lda ORIGINAL_DIR+2
   sta SYS_CURDIR  +2
   lda ORIGINAL_DIR+3
   sta SYS_CURDIR  +3
   jmp PROGRAM_BUFFER

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
CdDir:
   lda INPUT_PARAM
   cmp #BACKSLASH
   bne CdDir2
   lda INPUT_PARAM+1
   cmp #SPACE
   bne CdDir2
   lda ROOT_DIRECTORY
   sta SYS_CURDIR
   lda ROOT_DIRECTORY+1
   sta SYS_CURDIR+1
   lda ROOT_DIRECTORY+2
   sta SYS_CURDIR+2
   lda ROOT_DIRECTORY+3
   sta SYS_CURDIR+3
   jsr InitPath
   rts
CdDir2:
   lda INPUT_PARAM
   cmp #'.'
   bne CdDir3
   lda INPUT_PARAM+1
   cmp #'.'
   bne CdDir3
   lda INPUT_PARAM+2
   cmp #SPACE
   bne CdDir3
   jsr LoadDir
   ldy #DIR_PREV_LSB_8
   lda (ADDRESS),y
   sta SYS_CURDIR
   iny
   lda (ADDRESS),y
   sta SYS_CURDIR+1
   iny
   lda (ADDRESS),y
   sta SYS_CURDIR+2
   iny
   lda (ADDRESS),y
   sta SYS_CURDIR+3
   jsr CutPath
   rts
CdDir3:
   stz FILENAME_MODE
   jsr SetNewDir
   beq ChDir3b
   jsr AddPath
ChDir3b:
   rts
SetNewDir: 
   jsr FindFile
   bne CdDir4
   ldx #<text11
   ldy #>text11
   jsr PrintString
   lda #0
   rts
CdDir4:
   jsr RelativeFilePtr
   ldy #11
   lda (ADDRESS),y
   cmp #ATTRIB_DIR
   beq CdDir5
   ldx #<text12
   ldy #>text12
   jsr PrintString
   lda #0
   rts
CdDir5:
   ldy #16
   lda (ADDRESS),y
   sta SYS_CURDIR
   iny
   lda (ADDRESS),y
   sta SYS_CURDIR+1
   iny
   lda (ADDRESS),y
   sta SYS_CURDIR+2
   iny
   lda (ADDRESS),y
   sta SYS_CURDIR+3
   lda #1
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
CutPath:
   ldx #CURRENT_PATH_LENGTH
   dex    
CurPath1:
   lda CURRENT_PATH,x
   cmp #BACKSLASH
   beq CurPath2
   cpx #0
   beq CurPath3
   dex
   bra CurPath1
CurPath3:
   rts   
CurPath2:
   cpx #0
   bne CurPath4
   inx
CurPath4: 
   stz CURRENT_PATH,x
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
AddPath:
   ldx #0
AddPath1:
   lda CURRENT_PATH,x
   beq AddPath2
   inx
   bra AddPath1
AddPath2:
   cpx #1
   beq AddPath3
   lda #BACKSLASH
   sta CURRENT_PATH,x
   inx
AddPath3:
   ldy #0       
AddPath3b:
   lda INPUT_PARAM,y
   cmp #SPACE
   beq AddPath4
   sta CURRENT_PATH,x
   inx
   iny
   bra AddPath3b
AddPath4:
   stz CURRENT_PATH,x
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
Del:           
   stz FILENAME_MODE
   jsr FindFile
   bne Del2
   ldx #<text21
   ldy #>text21
   jsr PrintString
   rts
Del2:
   jsr RelativeFilePtr
   ldy #11
   lda (ADDRESS),y
   cmp #ATTRIB_DATAFILE
   beq Del3
   ldx #<text22
   ldy #>text22
   jsr PrintString
   rts
Del3:
   ldy #16
   lda (ADDRESS),y
   sta DEL_BLOCK
   iny
   lda (ADDRESS),y
   sta DEL_BLOCK+1
   iny
   lda (ADDRESS),y
   sta DEL_BLOCK+2
   iny
   lda (ADDRESS),y
   sta DEL_BLOCK+3
   
   jsr EraseEntry 

   lda DEL_BLOCK
   sta BLOCK
   lda DEL_BLOCK+1
   sta BLOCK+1
   lda DEL_BLOCK+2
   sta BLOCK+2
   lda DEL_BLOCK+3
   sta BLOCK+3

   jsr InitFreeList
   jsr AddFreeList
   jsr SetupFileBlock
   jsr ReadBlock
   
DelLoop0:
   stz SYS_FILE_PTR
   stz SYS_FILE_PTR+1

DelLoop:
   jsr RelativeFilePtr

   ldy #0
   lda (ADDRESS),y
   sta BLOCK
   iny
   lda (ADDRESS),y
   sta BLOCK+1
   iny
   lda (ADDRESS),y
   sta BLOCK+2
   iny
   lda (ADDRESS),y
   sta BLOCK+3

   lda SYS_FILE_PTR
   cmp #<508
   bne DelLoop1
   lda SYS_FILE_PTR+1
   cmp #>508
   bne DelLoop1

   jsr SetupFileBlock
   jsr ReadBlock
   jsr AddFreeList
   bra DelLoop0

DelLoop1:
   lda BLOCK
   ora BLOCK+1
   ora BLOCK+2
   ora BLOCK+3
   beq EndDelLoop

   jsr AddFreeList

   lda SYS_FILE_PTR
   clc
   adc #4
   sta SYS_FILE_PTR 
   bcc DelLoop2
   inc SYS_FILE_PTR+1
DelLoop2:
   bra DelLoop

   
EndDelLoop:
   jsr RemoveFreeList
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
RmDir:
   lda SYS_CURDIR
   sta SYS_OLDDIR
   lda SYS_CURDIR+1
   sta SYS_OLDDIR+1
   lda SYS_CURDIR+2
   sta SYS_OLDDIR+2
   lda SYS_CURDIR+3
   sta SYS_OLDDIR+3
   stz FILENAME_MODE
   jsr FindFile
   bne RmDir2
   ldx #<text11
   ldy #>text11
   jsr PrintString
   rts
RmDir2:
   jsr RelativeFilePtr
   ldy #11
   lda (ADDRESS),y
   cmp #ATTRIB_DIR
   beq RmDir3
   ldx #<text12
   ldy #>text12
   jsr PrintString
   rts
RmDir3:
   ldy #16
   lda (ADDRESS),y
   sta SYS_CURDIR
   iny
   lda (ADDRESS),y
   sta SYS_CURDIR+1
   iny
   lda (ADDRESS),y
   sta SYS_CURDIR+2
   iny
   lda (ADDRESS),y
   sta SYS_CURDIR+3
   jsr LoadDir   

   jsr InitFreeList

   lda SYS_CURDIR
   sta BLOCK
   lda SYS_CURDIR+1
   sta BLOCK+1
   lda SYS_CURDIR+2
   sta BLOCK+2
   lda SYS_CURDIR+3
   sta BLOCK+3

   jsr AddFreeList

   stz SYS_UPDATEBLOCK
   stz SYS_UPDATEBLOCK+1
   stz SYS_UPDATEBLOCK+2
   stz SYS_UPDATEBLOCK+3
   stz DIR_FILE
   stz DIR_FILE+1

RmDirLoop:
   lda DIR_FILE+1
   cmp SYS_TOTALFILES+1
   bne RmDirLoop2
   lda DIR_FILE
   cmp SYS_TOTALFILES 
   beq EndRmDirLoop
RmDirLoop2:
   jsr GetFile
   beq RmDirLoop3
   ldx #<text15
   ldy #>text15
   jsr PrintString
   lda SYS_OLDDIR
   sta SYS_CURDIR
   lda SYS_OLDDIR+1
   sta SYS_CURDIR+1
   lda SYS_OLDDIR+2
   sta SYS_CURDIR+2
   lda SYS_OLDDIR+3
   sta SYS_CURDIR+3
   rts

RmDirLoop3:
   lda SYS_UPDATEBLOCK
   ora SYS_UPDATEBLOCK+1
   ora SYS_UPDATEBLOCK+2
   ora SYS_UPDATEBLOCK+3
   beq RmDirLoop5

   lda SYS_UPDATEBLOCK
   sta BLOCK
   lda SYS_UPDATEBLOCK+1
   sta BLOCK+1
   lda SYS_UPDATEBLOCK+2
   sta BLOCK+2
   lda SYS_UPDATEBLOCK+3
   sta BLOCK+3
   jsr AddFreeList
   stz SYS_UPDATEBLOCK
   stz SYS_UPDATEBLOCK+1
   stz SYS_UPDATEBLOCK+2
   stz SYS_UPDATEBLOCK+3

RmDirLoop5:   
   inc DIR_FILE
   bne SkipRmDirInc
   inc DIR_FILE+1
SkipRmDirInc:
   bra RmDirLoop

EndRmDirLoop:
   jsr RemoveFreeList

   lda SYS_OLDDIR
   sta SYS_CURDIR
   lda SYS_OLDDIR+1
   sta SYS_CURDIR+1
   lda SYS_OLDDIR+2
   sta SYS_CURDIR+2
   lda SYS_OLDDIR+3
   sta SYS_CURDIR+3
   stz FILENAME_MODE
   jsr FindFile
   bne EraseEntry
   ldx #<text16
   ldy #>text16
   jsr PrintString
   rts
EraseEntry:
   jsr RelativeFilePtr
   ldy #0
   lda #0
   sta (ADDRESS),y
   lda SYS_UPDATEBLOCK
   sta BLOCK
   lda SYS_UPDATEBLOCK+1
   sta BLOCK+1
   lda SYS_UPDATEBLOCK+2
   sta BLOCK+2
   lda SYS_UPDATEBLOCK+3
   sta BLOCK+3
   jsr SetupFileBlock
   jsr WriteBlock
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
CreateFile:       // File Handle in ACC , $ff = Error
   stz FILENAME_MODE
   jsr FindFile
   beq Create2
   ldx #<text18
   ldy #>text18
   jsr PrintString
   bra Create4
Create2:  
   jsr GetFreeFileIndex
   beq Create4
   lda #ATTRIB_DATAFILE
   jsr SetupFileName
   jsr SetupIOBlock
   lda #0
   jsr SetBlock
   jsr SetupBLKBlock
   lda #0
   jsr SetBlock
   jsr GetFreeBlock
   lda FREE_BLOCK
   sta CURRENT_FILE+19
   sta FILE_MAP
   lda FREE_BLOCK+1
   sta CURRENT_FILE+20
   sta FILE_MAP+1
   lda FREE_BLOCK+2
   sta CURRENT_FILE+21
   sta FILE_MAP+2
   lda FREE_BLOCK+3
   sta CURRENT_FILE+22
   sta FILE_MAP+3
   lda #4
   sta CURRENT_FILE+14
   lda #MODE_WRITE
   sta CURRENT_FILE+16
   jsr CopyCurrentToTable
   lda FILE_TABLE_PTR
   rts
Create4:  
   lda #$ff
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
CopyCurrentToTable:
   ldy FILE_TABLE_PTR
   sty CURRENT_FILE_CACHE   
   ldx #0
CopyCurrentToTable2:
   lda CURRENT_FILE,x
   sta FILE_TABLE,y
   inx
   iny
   cpx #FILE_TABLE_ENTRY_SIZE
   bne CopyCurrentToTable2
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
CopyTableToCurrent:
   ldy FILE_TABLE_PTR
   sty CURRENT_FILE_CACHE  
   ldx #0
CopyTableToCurrent2:
   lda FILE_TABLE,y
   sta CURRENT_FILE,x
   inx
   iny
   cpx #FILE_TABLE_ENTRY_SIZE
   bne CopyTableToCurrent2
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
Save_IO_BLK:
   lda CURRENT_FILE+16
   cmp #MODE_READ
   beq Save_IO_BLK2
   lda CURRENT_FILE+19
   sta BLOCK
   lda CURRENT_FILE+20
   sta BLOCK+1
   lda CURRENT_FILE+21
   sta BLOCK+2
   lda CURRENT_FILE+22
   sta BLOCK+3
   jsr SetupIOBlock
   jsr WriteBlock
   lda CURRENT_FILE+10
   sta BLOCK
   lda CURRENT_FILE+11
   sta BLOCK+1
   lda CURRENT_FILE+12
   sta BLOCK+2
   lda CURRENT_FILE+13
   sta BLOCK+3
   jsr SetupBLKBlock
   jsr WriteBlock
Save_IO_BLK2:
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
CacheData:
   cmp CURRENT_FILE_CACHE
   beq CacheData2
   pha
   jsr Save_IO_BLK
   jsr CopyCurrentToTable
   pla
   sta FILE_TABLE_PTR
   jsr CopyTableToCurrent
   lda CURRENT_FILE+19
   sta BLOCK
   lda CURRENT_FILE+20
   sta BLOCK+1
   lda CURRENT_FILE+21
   sta BLOCK+2
   lda CURRENT_FILE+22
   sta BLOCK+3
   jsr SetupIOBlock
   jsr ReadBlock
   lda CURRENT_FILE+10
   sta BLOCK
   lda CURRENT_FILE+11
   sta BLOCK+1
   lda CURRENT_FILE+12
   sta BLOCK+2
   lda CURRENT_FILE+13
   sta BLOCK+3
   jsr SetupBLKBlock
   jsr ReadBlock
   rts
CacheData2:
   sta FILE_TABLE_PTR
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
GetFreeFileIndex:
   ldy #0 
GetFreeFileIndex2:   
   tya
   clc
   adc #16
   tax
   lda FILE_TABLE,x
   beq GetFreeFileIndex4
   tya
   clc 
   adc #24
   cmp #FILE_TABLE_ENTRY_SIZE*MAX_OPEN_FILES
   bge TooManyFiles
   tay
   bra GetFreeFileIndex2
TooManyFiles:
   ldx #<text19
   ldy #>text19
   jsr PrintString
   lda #0
   rts
GetFreeFileIndex4:
   sty FILE_TABLE_PTR
   ldx #0
GetFreeFileIndex5:
   stz CURRENT_FILE,x   // Clear file-table entry
   inx
   cpx #FILE_TABLE_ENTRY_SIZE
   bne GetFreeFileIndex5
   lda #1
   rts
   
/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
CloseFile:     // File Handle in ACC
   pha
   clc
   adc #16
   tay
   lda FILE_TABLE,y
   bne CloseFile2 
CloseFile1a:
   pla
   ldx #<text20
   ldy #>text20
   jsr PrintString
   rts
CloseFile2:
   pla
   jsr CacheData
   lda CURRENT_FILE+16
   cmp #MODE_READ
   beq CloseFile4
   jsr Save_IO_BLK   
   lda CURRENT_FILE+4
   sta BLOCK+0
   lda CURRENT_FILE+5
   sta BLOCK+1
   lda CURRENT_FILE+6
   sta BLOCK+2
   lda CURRENT_FILE+7
   sta BLOCK+3
   jsr SetupFileBlock
   jsr ReadBlock
   lda CURRENT_FILE+8
   sta SYS_FILE_PTR+0
   lda CURRENT_FILE+9
   sta SYS_FILE_PTR+1
   jsr RelativeFilePtr 
   ldy #MAX_FILENAME_LENGTH+1
   lda CURRENT_FILE+0
   sta (ADDRESS),y
   iny
   lda CURRENT_FILE+1
   sta (ADDRESS),y
   iny
   lda CURRENT_FILE+2
   sta (ADDRESS),y
   iny
   lda CURRENT_FILE+3
   sta (ADDRESS),y
   jsr SetupFileBlock
   jsr WriteBlock
CloseFile4:
   lda #MODE_AVAILABLE
   sta CURRENT_FILE+16
   jsr CopyCurrentToTable
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
TypeFile:
   jsr OpenFile
   cmp #$ff
   beq TypeEnd
   sta TEMP_1
Type0:
   lda TEMP_1
   jsr ReadByte
   pha
   lda TEMP_1
   jsr Eof
   bne Type2
   pla
   jmp TypeEnd2
Type2:
   pla
   jsr OutChar
   bra Type0
TypeEnd2:
   lda TEMP_1
   jsr CloseFile
TypeEnd:
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
_PlayFile:
   jsr OpenFile
   cmp #$ff
   beq _PlayEnd
   sta TEMP_1
   jsr InitDSP
   beq _PlayEnd
_Play0:
   lda TEMP_1
   jsr ReadByte
   jsr DataToDSP
   lda TEMP_1
   jsr Eof
   bne _Play0

   lda TEMP_1
   jsr CloseFile
   jsr DSPClose
_PlayEnd:
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
PlayFile:
   jsr OpenFile
   cmp #$ff
   beq PlayEnd
   sta TEMP_1
   jsr InitDSP
   beq PlayEnd
Play0:
   lda TEMP_1
   jsr Eof
   beq Play3
   lda TEMP_1 
   jsr Read512
   jsr SetupIOBlock
   ldy #0
Play1:
   lda (ADDRESS),y
   jsr DataToDSP  
   iny
   cpy #0
   bne Play1
   inc ADDRESS+1
Play2:
   lda (ADDRESS),y
   jsr DataToDSP  
   iny
   cpy #0
   bne Play2
   bra Play0
Play3:
   lda TEMP_1
   jsr CloseFile
   jsr DSPClose
PlayEnd:
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
OpenFile:      
   stz FILENAME_MODE
   jsr FindFile
   bne OpenFile2
   ldx #<text21
   ldy #>text21
   jsr PrintString
OpenFile1a:
   lda #$ff
   rts
OpenFile2:  
   jsr GetFreeFileIndex
   beq OpenFile1a

   jsr RelativeFilePtr 

   ldy #MAX_FILENAME_LENGTH
   lda (ADDRESS),y
   cmp #ATTRIB_DATAFILE
   beq OpenFile3
   ldx #<text22
   ldy #>text22
   jsr PrintString
   bra OpenFile1a
OpenFile3:
   iny

   lda (ADDRESS),y
   sta CURRENT_FILE+0
   iny
   lda (ADDRESS),y
   sta CURRENT_FILE+1
   iny
   lda (ADDRESS),y
   sta CURRENT_FILE+2
   iny
   lda (ADDRESS),y
   sta CURRENT_FILE+3

   lda SYS_FILE_PTR+0
   sta CURRENT_FILE+8

   lda SYS_FILE_PTR+1
   sta CURRENT_FILE+9

   ldy #16 
   lda (ADDRESS),y
   sta CURRENT_FILE+10  // Bytes 10-13 (4): Block where Current Block Allocation Table Resides 
   sta BLOCK
   iny
   lda (ADDRESS),y
   sta CURRENT_FILE+11
   sta BLOCK+1
   iny
   lda (ADDRESS),y
   sta CURRENT_FILE+12
   sta BLOCK+2
   iny
   lda (ADDRESS),y
   sta CURRENT_FILE+13
   sta BLOCK+3

   jsr SetupBLKBlock
   jsr ReadBlock

   lda FILE_MAP
   sta CURRENT_FILE+19
   sta BLOCK
   lda FILE_MAP+1
   sta CURRENT_FILE+20
   sta BLOCK+1
   lda FILE_MAP+2
   sta CURRENT_FILE+21
   sta BLOCK+2
   lda FILE_MAP+3
   sta CURRENT_FILE+22
   sta BLOCK+3

   jsr SetupIOBlock
   jsr ReadBlock

   lda #MODE_READ
   sta CURRENT_FILE+16

   lda #4
   sta CURRENT_FILE+14

   jsr CopyCurrentToTable

   lda FILE_TABLE_PTR
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
WriteByte:  // Y-Reg file number, ACC=Data
   phx
   pha
   tya
   jsr CacheData
  
   inc CURRENT_FILE      // Increase Bytes Written
   bne WriteByte2
   inc CURRENT_FILE+1
   bne WriteByte2
   inc CURRENT_FILE+2
   bne WriteByte2
   inc CURRENT_FILE+3
WriteByte2:

   jsr SetupIOBlock 
   lda CURRENT_FILE+18
   beq WriteByte2b
   inc ADDRESS+1
WriteByte2b:
   ldy CURRENT_FILE+17

   pla
   sta (ADDRESS),y       // Write Data into Block 

   
   inc CURRENT_FILE+17
   bne WriteByte3
   inc CURRENT_FILE+18
   lda CURRENT_FILE+18  
   cmp #2
   bne WriteByte3
   
   lda CURRENT_FILE+19
   sta BLOCK
   lda CURRENT_FILE+20
   sta BLOCK+1
   lda CURRENT_FILE+21
   sta BLOCK+2
   lda CURRENT_FILE+22
   sta BLOCK+3

   jsr SetupIOBlock
   jsr WriteBlock
   jsr AllocNewBlock

WriteByte3:
   plx
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
Eof:    // ACC = file Number
   jsr CacheData
   lda CURRENT_FILE+16
   cmp #MODE_READ
   bne Eof1
   
   lda CURRENT_FILE+0
   cmp CURRENT_FILE+4  
   lda CURRENT_FILE+1
   sbc CURRENT_FILE+5
   lda CURRENT_FILE+2
   sbc CURRENT_FILE+6
   lda CURRENT_FILE+3
   sbc CURRENT_FILE+7
   bcc Eof2
Eof1:
   lda #1
   rts
Eof2:
   lda #0
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
JumpNextBlock:
   lda CURRENT_FILE+14
   cmp #<508
   bne JumpNextBlock2
   lda CURRENT_FILE+15
   cmp #>508
   bne JumpNextBlock2

   lda CURRENT_FILE+14
   sta SYS_FILE_PTR
   lda CURRENT_FILE+15
   sta SYS_FILE_PTR+1
                     
   jsr RelativeFilePtrBLK 
   ldy #0
   lda (ADDRESS),y
   sta BLOCK
   sta CURRENT_FILE+10
   iny
   lda (ADDRESS),y
   sta BLOCK+1
   sta CURRENT_FILE+11
   iny
   lda (ADDRESS),y
   sta BLOCK+2
   sta CURRENT_FILE+12
   iny
   lda (ADDRESS),y
   sta BLOCK+3
   sta CURRENT_FILE+13
   jsr SetupBLKBlock
   jsr ReadBlock

   stz CURRENT_FILE+14
   stz CURRENT_FILE+15

JumpNextBlock2:
   stz CURRENT_FILE+17 
   stz CURRENT_FILE+18 

   lda CURRENT_FILE+14
   sta SYS_FILE_PTR
   lda CURRENT_FILE+15
   sta SYS_FILE_PTR+1
                     
   jsr RelativeFilePtrBLK 
   ldy #0
   lda (ADDRESS),y
   sta CURRENT_FILE+19
   sta BLOCK
   iny
   lda (ADDRESS),y
   sta CURRENT_FILE+20
   sta BLOCK+1
   iny
   lda (ADDRESS),y
   sta CURRENT_FILE+21
   sta BLOCK+2
   iny
   lda (ADDRESS),y
   sta CURRENT_FILE+22
   sta BLOCK+3

   jsr SetupIOBlock
   jsr ReadBlock

   lda CURRENT_FILE+14
   clc
   adc #4
   sta CURRENT_FILE+14
   bcc JumpNextBlock3
   inc CURRENT_FILE+15
JumpNextBlock3:
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
AllocNewBlock:
   jsr GetFreeBlock
   lda CURRENT_FILE+14
   cmp #<508
   bne AllocNewBlock2
   lda CURRENT_FILE+15
   cmp #>508
   bne AllocNewBlock2
   jsr StoreNewBlock
   lda CURRENT_FILE+10
   sta BLOCK
   lda CURRENT_FILE+11
   sta BLOCK+1
   lda CURRENT_FILE+12
   sta BLOCK+2
   lda CURRENT_FILE+13
   sta BLOCK+3

   lda FREE_BLOCK
   sta CURRENT_FILE+10 
   lda FREE_BLOCK+1
   sta CURRENT_FILE+11
   lda FREE_BLOCK+2
   sta CURRENT_FILE+12
   lda FREE_BLOCK+3
   sta CURRENT_FILE+13 

   jsr SetupBLKBlock
   jsr WriteBlock
   stz CURRENT_FILE+14
   stz CURRENT_FILE+15
   lda #0
   jsr SetBlock
   jsr GetFreeBlock    

AllocNewBlock2:
   stz CURRENT_FILE+17 
   stz CURRENT_FILE+18 

   lda FREE_BLOCK         // Set Read/Write Block
   sta CURRENT_FILE+19
   lda FREE_BLOCK+1
   sta CURRENT_FILE+20
   lda FREE_BLOCK+2
   sta CURRENT_FILE+21
   lda FREE_BLOCK+3
   sta CURRENT_FILE+22

   jsr StoreNewBlock

   lda CURRENT_FILE+14
   clc
   adc #4
   sta CURRENT_FILE+14
   bcc AllocNewBlock3
   inc CURRENT_FILE+15
AllocNewBlock3:
   rts

StoreNewBlock:
   lda CURRENT_FILE+14
   sta SYS_FILE_PTR
   lda CURRENT_FILE+15
   sta SYS_FILE_PTR+1
                     
   jsr RelativeFilePtrBLK 
   ldy #0
   lda FREE_BLOCK
   sta (ADDRESS),y
   lda FREE_BLOCK+1
   iny
   sta (ADDRESS),y
   lda FREE_BLOCK+2
   iny
   sta (ADDRESS),y
   lda FREE_BLOCK+3
   iny
   sta (ADDRESS),y
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
Read512: // ACC file number
   jsr CacheData
   lda CURRENT_FILE+5
   ora CURRENT_FILE+6
   ora CURRENT_FILE+7
   beq Add512
   jsr Add512
   jmp JumpNextBlock

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
Add512:
   clc
   lda CURRENT_FILE+5       // Add 512 to Bytes Read
   adc #2
   sta CURRENT_FILE+5 
   lda CURRENT_FILE+6
   adc #0
   sta CURRENT_FILE+6 
   lda CURRENT_FILE+7
   adc #0
   sta CURRENT_FILE+7 
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
ReadByte:  // ACC = file number, Retrun ACC=Data
   jsr CacheData
  
   inc CURRENT_FILE+4      // Increase Bytes Read
   bne ReadByte2
   inc CURRENT_FILE+5
   bne ReadByte2
   inc CURRENT_FILE+6
   bne ReadByte2
   inc CURRENT_FILE+7
ReadByte2:

   jsr SetupIOBlock 
   lda CURRENT_FILE+18
   beq ReadByte2b
   inc ADDRESS+1
ReadByte2b:
   ldy CURRENT_FILE+17

   lda (ADDRESS),y       // Read Data From Block
   pha

   inc CURRENT_FILE+17
   bne ReadByte3
   inc CURRENT_FILE+18
   lda CURRENT_FILE+18  
   cmp #2
   bne ReadByte3
   jsr JumpNextBlock

ReadByte3:
   pla 
   rts


/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
MkDir:         
   stz FILENAME_MODE
   jsr FindFile
   beq MkDir2
   ldx #<text9
   ldy #>text9
   jsr PrintString
   rts

MkDir2:
   lda #$ff
   sta FILE_TABLE_PTR
   lda #ATTRIB_DIR   
   jsr SetupFileName
   jmp MkDir3

SetupFileName:
   pha
   jsr GetFreeFileSlot
   jsr RelativeFilePtr 
   ldy #0
SetupFileName3:
   lda INPUT_PARAM,y
   sta (ADDRESS),y
   iny
   cpy #MAX_FILENAME_LENGTH
   bne SetupFileName3
   pla

   sta (ADDRESS),y
   iny
   lda #0
   sta (ADDRESS),y
   iny
   sta (ADDRESS),y
   iny
   sta (ADDRESS),y
   iny
   sta (ADDRESS),y

   jsr GetFreeBlock
   jsr RelativeFilePtr  

   ldy #16
   lda FREE_BLOCK
   sta (ADDRESS),y
   iny
   lda FREE_BLOCK+1
   sta (ADDRESS),y
   iny
   lda FREE_BLOCK+2
   sta (ADDRESS),y
   iny
   lda FREE_BLOCK+3
   sta (ADDRESS),y

   ldy FILE_TABLE_PTR
   cpy #$ff
   beq SetupFileName4

   lda SYS_UPDATEBLOCK
   sta CURRENT_FILE+4
   lda SYS_UPDATEBLOCK+1
   sta CURRENT_FILE+5
   lda SYS_UPDATEBLOCK+2
   sta CURRENT_FILE+6
   lda SYS_UPDATEBLOCK+3
   sta CURRENT_FILE+7

   lda SYS_FILE_PTR+0 // Bytes 8 -9  (2): Offset within Directory Block (SYS_FILE_PTR) 
   sta CURRENT_FILE+8
   lda SYS_FILE_PTR+1
   sta CURRENT_FILE+9


   lda FREE_BLOCK+0    // Bytes 10-13 (4): Block where Current Block Allocation Table Resides 
   sta CURRENT_FILE+10

   lda FREE_BLOCK+1
   sta CURRENT_FILE+11

   lda FREE_BLOCK+2
   sta CURRENT_FILE+12

   lda FREE_BLOCK+3
   sta CURRENT_FILE+13

SetupFileName4:
   lda SYS_UPDATEBLOCK
   sta BLOCK
   lda SYS_UPDATEBLOCK+1
   sta BLOCK+1
   lda SYS_UPDATEBLOCK+2
   sta BLOCK+2
   lda SYS_UPDATEBLOCK+3
   sta BLOCK+3

   jsr SetupFileBlock
   jsr WriteBlock

   lda FREE_BLOCK
   sta BLOCK
   lda FREE_BLOCK+1
   sta BLOCK+1
   lda FREE_BLOCK+2
   sta BLOCK+2
   lda FREE_BLOCK+3
   sta BLOCK+3

   jsr SetupFileBlock
   jsr ReadBlock
   lda #0
   jsr SetBlock
   rts

MkDir3:
   ldy #DIR_SIG1
   lda #$aa
   sta (ADDRESS),y
   ldy #DIR_SIG2
   lda #$55
   sta (ADDRESS),y

   ldy #DIR_PREV_LSB_8
   lda SYS_CURDIR
   sta (ADDRESS),y
   iny
   lda SYS_CURDIR+1
   sta (ADDRESS),y
   iny
   lda SYS_CURDIR+2
   sta (ADDRESS),y
   iny
   lda SYS_CURDIR+3
   sta (ADDRESS),y
   jsr WriteBlock
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
GetFreeFileSlot:
   jsr LoadDir
   stz DIR_FILE
   stz DIR_FILE+1

GetFreeLoop:
   lda DIR_FILE+1
   cmp SYS_TOTALFILES+1
   bne GetFreeLoop2
   lda DIR_FILE
   cmp SYS_TOTALFILES 
   beq EndGetFreeLoop
GetFreeLoop2:
   jsr GetFile
   bne GetFreeLoop3
   lda #1
   rts

GetFreeLoop3:
   inc DIR_FILE
   bne SkipGetFreeInc
   inc DIR_FILE+1
SkipGetFreeInc:
   bra GetFreeLoop
  
EndGetFreeLoop:
   
   lda SYS_BLOCKINDEX+1
   cmp #2
   blt GetFreeSlot2

   jsr GetFreeBlock
   jsr SetupFileBlock 

   ldy #DIR_NEXT_LSB_8
   lda FREE_BLOCK
   sta (ADDRESS),y
   iny
   lda FREE_BLOCK+1
   sta (ADDRESS),y
   iny
   lda FREE_BLOCK+2
   sta (ADDRESS),y
   iny
   lda FREE_BLOCK+3
   sta (ADDRESS),y

   lda SYS_UPDATEBLOCK
   sta BLOCK
   lda SYS_UPDATEBLOCK+1
   sta BLOCK+1
   lda SYS_UPDATEBLOCK+2
   sta BLOCK+2
   lda SYS_UPDATEBLOCK+3
   sta BLOCK+3

   jsr WriteBlock

   jsr IncFileCount

   lda FREE_BLOCK
   sta BLOCK
   sta SYS_UPDATEBLOCK
   lda FREE_BLOCK+1
   sta SYS_UPDATEBLOCK+1
   sta BLOCK+1
   lda FREE_BLOCK+2
   sta SYS_UPDATEBLOCK+2
   sta BLOCK+2
   lda FREE_BLOCK+3
   sta SYS_UPDATEBLOCK+3
   sta BLOCK+3
   jsr SetupFileBlock 
   jsr ReadBlock
   lda #0
   jsr SetBlock

   ldy #DIR_SIG1
   lda #$aa
   sta (ADDRESS),y
   ldy #DIR_SIG2
   lda #$55
   sta (ADDRESS),y
   lda #12
   sta SYS_FILE_PTR
   stz SYS_FILE_PTR+1
   rts

GetFreeSlot2:
   jsr IncFileCount
   jsr SetupFileBlock
   lda SYS_BLOCKINDEX
   sta SYS_FILE_PTR
   lda SYS_BLOCKINDEX+1
   sta SYS_FILE_PTR+1
   lda SYS_UPDATEBLOCK
   sta BLOCK
   lda SYS_UPDATEBLOCK+1
   sta BLOCK+1
   lda SYS_UPDATEBLOCK+2
   sta BLOCK+2
   lda SYS_UPDATEBLOCK+3
   sta BLOCK+3
   jsr ReadBlock
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
IncFileCount:
   lda SYS_CURDIR
   sta BLOCK
   lda SYS_CURDIR+1
   sta BLOCK+1
   lda SYS_CURDIR+2
   sta BLOCK+2
   lda SYS_CURDIR+3
   sta BLOCK+3
   jsr SetupFileBlock
   jsr ReadBlock
   ldy #2
   lda (ADDRESS),y 
   clc
   adc #1
   sta (ADDRESS),y
   bcc NoIncFileCount
   iny
   lda (ADDRESS),y 
   clc
   adc #1
   sta (ADDRESS),y  
NoIncFileCount:   
   jsr WriteBlock
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
Dir:
   ldx #<dirInfo
   ldy #>dirInfo
   jsr PrintString
   jsr LoadDir
   beq DirEnd2
   stz DIR_FILE
   stz DIR_FILE+1
   stz DIR_SHOWN
   stz DIR_SHOWN+1
DirLoop:
   lda DIR_FILE+1
   cmp SYS_TOTALFILES+1
   bne DirLoop2
   lda DIR_FILE
   cmp SYS_TOTALFILES 
   beq EndDirLoop
DirLoop2:
   jsr GetFile
   beq DirLoop4
DirLoop3:
   inc DIR_SHOWN
   bne NoIncDirShown
   inc DIR_SHOWN+1
NoIncDirShown:
   jsr PrintFileInfo
DirLoop4:
   inc DIR_FILE
   bne NoDirInc
   inc DIR_FILE+1
NoDirInc:
   bra DirLoop
EndDirLoop:
   lda DIR_SHOWN
   ora DIR_SHOWN+1
   bne DirEnd2
   ldx #<text7
   ldy #>text7
   jsr PrintString
DirEnd2:
   jsr CRLF
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
RelativeFilePtr:
   jsr SetupFileBlock
   lda SYS_FILE_PTR+1
   beq Relative2
   inc ADDRESS+1
Relative2:
   lda SYS_FILE_PTR
   clc
   adc ADDRESS
   sta ADDRESS
   bcc Relative3
   inc ADDRESS+1
Relative3:
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
RelativeFilePtrIO:
   jsr SetupIOBlock
   lda SYS_FILE_PTR+1
   beq Relative20
   inc ADDRESS+1
Relative20:
   lda SYS_FILE_PTR
   clc
   adc ADDRESS
   sta ADDRESS
   bcc Relative30
   inc ADDRESS+1
Relative30:
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
RelativeFilePtrBLK:
   jsr SetupBLKBlock
   lda SYS_FILE_PTR+1
   beq Relative201
   inc ADDRESS+1
Relative201:
   lda SYS_FILE_PTR
   clc
   adc ADDRESS
   sta ADDRESS
   bcc Relative301
   inc ADDRESS+1
Relative301:
   rts


/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
RelativeFilePtr2:
   jsr SetupFileBlock2
   lda SYS_FILE_PTR2+1
   beq Relative6
   inc ADDRESS+1
Relative6:
   lda SYS_FILE_PTR2
   clc
   adc ADDRESS
   sta ADDRESS
   bcc Relative7
   inc ADDRESS+1
Relative7:
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
RelativeBlockPtr:
   jsr SetupFileBlock
   lda SYS_BLOCKINDEX+1
   beq Relative4
   inc ADDRESS+1
Relative4:
   lda SYS_BLOCKINDEX
   clc
   adc ADDRESS
   sta ADDRESS
   bcc Relative5
   inc ADDRESS+1
Relative5:
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
TestFilename:
   phx
   jsr RelativeFilePtr
   ldy #0
TestFilename3: 
   ldx FILENAME_MODE
   bne TestFilename4
   lda (ADDRESS),y
   cmp INPUT_PARAM,y
   bra TestFilename5
TestFilename4:
   lda (ADDRESS),y
   cmp BIN_DIR,y
TestFilename5:
   bne NoGood
   iny
   cpy #MAX_FILENAME_LENGTH
   bne TestFilename3
   plx 
   lda #1
   rts
NoGood:
   plx 
   lda #0
   rts
 
/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
PrintFileInfo:
   jsr RelativeFilePtr 
   ldy #0
PrintFile3: 
   lda (ADDRESS),y
   jsr OutChar
   iny
   cpy #MAX_FILENAME_LENGTH
   bne PrintFile3
   lda #SPACE
   jsr OutChar
   ldy #MAX_FILENAME_LENGTH
   lda (ADDRESS),y
   pha
   asl A
   tay
   lda attribs,y
   pha
   iny
   lda attribs,y
   tay
   pla
   tax
   jsr PrintString
   pla
   cmp #ATTRIB_DIR
   beq PrintFile4
   ldy #12
   lda (ADDRESS),y
   sta TEMP_NUM
   iny
   lda (ADDRESS),y
   sta TEMP_NUM+1
   iny
   lda (ADDRESS),y
   sta TEMP_NUM+2
   iny
   lda (ADDRESS),y
   sta TEMP_NUM+3
   jsr Print32BitNumber
PrintFile3b:
   jsr CRLF
   rts
PrintFile4:
   lda #'N'
   jsr OutChar
   lda #'/'
   jsr OutChar
   lda #'A'
   jsr OutChar
   bra PrintFile3b

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
SetupFileBlock:
   lda #<BUFFER
   sta ADDRESS
   lda #>BUFFER
   sta ADDRESS+1
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
SetupIOBlock:
   lda #<BLOCK_READ_WRITE
   sta ADDRESS
   lda #>BLOCK_READ_WRITE
   sta ADDRESS+1
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
SetupBLKBlock:
   lda #<FILE_MAP
   sta ADDRESS
   lda #>FILE_MAP
   sta ADDRESS+1
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
SetupFileBlock2:
   lda #<BUFFER2
   sta ADDRESS
   lda #>BUFFER2
   sta ADDRESS+1
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
GetFile:
// returns Index into current Block at SYS_FILE_PTR(16 bit)

   jsr SetupFileBlock
   lda SYS_BLOCKINDEX+1
   cmp #2
   bne GetFile2

   ldy #DIR_NEXT_LSB_8
   lda (ADDRESS),y
   sta FILE_NEXTBLOCK
   sta SYS_UPDATEBLOCK
   sta BLOCK
   iny
   lda (ADDRESS),y
   sta FILE_NEXTBLOCK+1
   sta SYS_UPDATEBLOCK+1
   sta BLOCK+1
   iny
   lda (ADDRESS),y
   sta FILE_NEXTBLOCK+2
   sta SYS_UPDATEBLOCK+2
   sta BLOCK+2
   iny
   lda (ADDRESS),y
   sta FILE_NEXTBLOCK+3
   sta SYS_UPDATEBLOCK+3
   sta BLOCK+3
   jsr SetupFileBlock   
   jsr ReadBlock

   ldy #DIR_SIG1
   lda (ADDRESS),y
   cmp #$aa
   bne BadDir2

   ldy #DIR_SIG2
   lda (ADDRESS),y
   cmp #$55
   bne BadDir2

   lda #12
   sta SYS_BLOCKINDEX
   stz SYS_BLOCKINDEX+1

GetFile2:
   jsr RelativeBlockPtr
   ldy #0
   lda (ADDRESS),y
   cmp #32
   beq DeletedFile
   cmp #0
   beq DeletedFile
   bra GetFile4
DeletedFile:
   lda SYS_BLOCKINDEX+1
   sta SYS_FILE_PTR+1
   clc
   lda SYS_BLOCKINDEX
   sta SYS_FILE_PTR
   adc #20
   sta SYS_BLOCKINDEX 
   bcc NoDelInc
   inc SYS_BLOCKINDEX+1
NoDelInc:
   bra NoFile
GetFile4:
   lda SYS_BLOCKINDEX+1
   sta SYS_FILE_PTR+1
   lda SYS_BLOCKINDEX
   sta SYS_FILE_PTR
   clc
   adc #20
   sta SYS_BLOCKINDEX 
   bcc NoDelInc2
   inc SYS_BLOCKINDEX+1
NoDelInc2:
   lda #1
   rts
BadDir2:
   ldx #<text6
   ldy #>text6
   jsr PrintString
NoFile:
   lda #0
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
GetFreeBlock:
   stz TEMP32A
   stz TEMP32A+1
   bra GetFreeBlock2

GetFreeEndLoop:
   ldx #<text5
   ldy #>text5
   jsr PrintString
   stz FREE_BLOCK
   stz FREE_BLOCK+1
   stz FREE_BLOCK+2
   stz FREE_BLOCK+3
   rts

// For (TEMP32A=0; TEMP32A<FS_MAP )
GetFreeBlock2:
   lda TEMP32A+1
   cmp FORMAT_FS_BLOCKS+1
   bne GetFreeInside
   lda TEMP32A 
   cmp FORMAT_FS_BLOCKS
   beq GetFreeEndLoop
GetFreeInside:

   jsr SetupFSBlock
   jsr ReadBlock

   stz SYS_FILE_PTR2
   stz SYS_FILE_PTR2+1

//   for (SYS_FILE_PTR2=0;  SYS_FILE_PTR2 <512 )  
InsideLoop2:
   lda SYS_FILE_PTR2+1
   cmp #2
   bge EndInsideLoop2

   jsr RelativeFilePtr2
   ldy #0
   lda (ADDRESS),y
   beq EndLoop2
//      if (block2[j] == 0) continue

   stz TEMP32C

// for (TEMP32C=0; TEMP32C < 8)
StartLoop0:   
   lda TEMP32C
   cmp #8
   bge EndLoop2

   ldy TEMP32C
   lda bitLut2,y
   sta SAVE_A 
   ldy #0
   lda (ADDRESS),y
   and SAVE_A
   beq EndLoop0

   ldy TEMP32C 
   lda bitLut3,y
   sta SAVE_A
   ldy #0
   lda (ADDRESS),y
   and SAVE_A
   sta (ADDRESS),y
   jsr SetupFSBlock   
   jsr WriteBlock
   jsr CalcFreeBlock
   rts

EndLoop0:    
   inc TEMP32C
   bra StartLoop0

EndLoop2:
   inc SYS_FILE_PTR2
   bne DontIncByte
   inc SYS_FILE_PTR2+1
DontIncByte:
   bra InsideLoop2

EndInsideLoop2:
   inc TEMP32A
   bne DontInc32A
   inc TEMP32A+1
DontInc32A:
   bra GetFreeBlock2


/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
CalcFreeBlock:
    lda #$10
    sta MATH_PARAM3+1
    stz MATH_PARAM3
    stz MATH_PARAM3+2
    stz MATH_PARAM3+3

    lda TEMP32A
    sta MATH_PARAM2
    lda TEMP32A+1
    sta MATH_PARAM2+1
    stz MATH_PARAM2+2 
    stz MATH_PARAM2+3 
    jsr mult32

    clc
    lda MATH_PARAM0
    adc FORMAT_FS_BLOCKS
    sta MATH_PARAM0
    lda MATH_PARAM0+1
    adc FORMAT_FS_BLOCKS+1
    sta MATH_PARAM0+1
    lda MATH_PARAM0+2
    adc #0
    sta MATH_PARAM0+2
    lda MATH_PARAM0+3
    adc #0
    sta MATH_PARAM0+3

    clc
    lda MATH_PARAM0
    adc #OS_OFFSET
    sta MATH_PARAM0
    lda MATH_PARAM0+1
    adc #0
    sta MATH_PARAM0+1
    lda MATH_PARAM0+2
    adc #0
    sta MATH_PARAM0+2
    lda MATH_PARAM0+3
    adc #0
    sta MATH_PARAM0+3

    clc
    lda MATH_PARAM0
    adc TEMP32C
    sta FREE_BLOCK
    lda MATH_PARAM0+1
    adc #0
    sta FREE_BLOCK+1
    lda MATH_PARAM0+2
    adc #0
    sta FREE_BLOCK+2
    lda MATH_PARAM0+3
    adc #0
    sta FREE_BLOCK+3

    lda #8
    sta MATH_PARAM3
    stz MATH_PARAM3+1
    stz MATH_PARAM3+2
    stz MATH_PARAM3+3

    lda SYS_FILE_PTR2
    sta MATH_PARAM2
    lda SYS_FILE_PTR2+1
    sta MATH_PARAM2+1
    stz MATH_PARAM2+2
    stz MATH_PARAM2+3
                     
    jsr mult32

    clc
    lda FREE_BLOCK
    adc MATH_PARAM0
    sta FREE_BLOCK
    lda FREE_BLOCK+1
    adc MATH_PARAM0+1
    sta FREE_BLOCK+1
    lda FREE_BLOCK+2
    adc MATH_PARAM0+2
    sta FREE_BLOCK+2
    lda FREE_BLOCK+3
    adc MATH_PARAM0+3
    sta FREE_BLOCK+3
    rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
DisplayFreeMap:
    stz TEMP32A
    stz TEMP32A+1
DisplayFreeMap2:
    jsr SetupFSBlock
    jsr ReadBlock
    jsr DumpBlock
    inc TEMP32A
    bne SkipFreeMapInc
    inc TEMP32A+1
SkipFreeMapInc:
    jsr Getch
    cmp #CR
    beq DisplayFreeMap3
    lda TEMP32A+1
    cmp FORMAT_FS_BLOCKS+1
    bne DisplayFreeMap2
    lda TEMP32A
    cmp FORMAT_FS_BLOCKS
    bne DisplayFreeMap2 
DisplayFreeMap3: 
    rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
SetupFSBlock:
 clc
 lda TEMP32A
 adc #OS_OFFSET
 sta BLOCK
 lda TEMP32A+1
 adc #0
 sta BLOCK+1
 lda #0
 adc #0
 sta BLOCK+2
 stz BLOCK+3
 jsr SetupFileBlock2
 rts

/***********************************************************************/
/***********************************************************************/
SetBits:
   // int pointer=0
   stz SETBITS_PTR
   stz SETBITS_PTR+1

   // memset(block, 0, 512)
   jsr SetupFileBlock2
   lda #0
   jsr SetBlock
   ldy #0

SetBitLoop:
   // if (pointer>=512) break 
   lda SETBITS_PTR+1
   cmp #2
   bge EndBitLoop
   // if (numberBits > 8) 
   lda MATH_PARAM3+1
   bne SetBitInside
   lda MATH_PARAM3
   cmp #9
   blt SkipBitLoop
SetBitInside:

   lda #255
   sta (ADDRESS),y

   iny

   cpy #0
   bne SkipIncY
   inc ADDRESS+1
SkipIncY:
   inc SETBITS_PTR
   bne SkipIncPtr
   inc SETBITS_PTR+1
SkipIncPtr:      
//  numberBits-=8 
  
   sec
   lda MATH_PARAM3
   sbc #8
   sta MATH_PARAM3
   lda MATH_PARAM3+1
   sbc #0
   sta MATH_PARAM3+1
   lda MATH_PARAM3+2
   sbc #0
   sta MATH_PARAM3+2
   lda MATH_PARAM3+3
   sbc #0
   sta MATH_PARAM3+3

   bra SetBitLoop

SkipBitLoop:
   ldx MATH_PARAM3 
   dex
   lda bitLut,x
   sta (ADDRESS),y

EndBitLoop:
   rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
WriteFSMap:
//     WriteBlock(OS_OFFSET+mapBlock) 
     clc
     lda #OS_OFFSET
     adc FORMAT_MAPBLOCK
     sta BLOCK
     lda #0
     adc FORMAT_MAPBLOCK+1
     sta BLOCK+1
     lda #0
     adc #0
     sta BLOCK+2
     stz BLOCK+3
     jsr SetupFileBlock2
     jsr WriteBlock
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
SetBlock:
     ldy #0
     ldx #0
SetBlock2:
     sta (ADDRESS),y
     iny
     sta (ADDRESS),y
     iny
     cpy #0
     bne SetBlock2 
     inc ADDRESS+1
     inx
     cpx #2
     bne SetBlock2
     dec ADDRESS+1
     dec ADDRESS+1
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
Print32BitNumber:
   // number in TEMP_NUM
   // number in TEMP_NUM+1
   // number in TEMP_NUM+2
   // number in TEMP_NUM+3
   // MATH_PARAM1=MATH_PARAM2%MATH_PARAM0 (32-bit signed)
   phy
   phx
   ldy #0
Print32:
   lda TEMP_NUM
   sta MATH_PARAM2
   lda TEMP_NUM+1
   sta MATH_PARAM2+1
   lda TEMP_NUM+2
   sta MATH_PARAM2+2
   lda TEMP_NUM+3
   sta MATH_PARAM2+3
   lda #10
   sta MATH_PARAM0
   stz MATH_PARAM0+1
   stz MATH_PARAM0+2
   stz MATH_PARAM0+3
   jsr mod32

   lda MATH_PARAM1
   clc
   adc #'0'
   sta STRING_BUFFER,y
   iny
      
   lda TEMP_NUM
   sta MATH_PARAM2
   lda TEMP_NUM+1
   sta MATH_PARAM2+1
   lda TEMP_NUM+2
   sta MATH_PARAM2+2
   lda TEMP_NUM+3
   sta MATH_PARAM2+3
   lda #10
   sta MATH_PARAM0
   stz MATH_PARAM0+1
   stz MATH_PARAM0+2
   stz MATH_PARAM0+3
   jsr udiv32

   lda MATH_PARAM2
   sta TEMP_NUM
   lda MATH_PARAM2+1
   sta TEMP_NUM+1
   lda MATH_PARAM2+2
   sta TEMP_NUM+2
   lda MATH_PARAM2+3
   sta TEMP_NUM+3

   lda TEMP_NUM
   bne Print32
   lda TEMP_NUM+1
   bne Print32
   lda TEMP_NUM+2
   bne Print32
   lda TEMP_NUM+3
   bne Print32
PrintLoop:
   dey
   lda STRING_BUFFER,y
   jsr OutChar
   cpy #0
   bne PrintLoop
   plx
   ply
   rts


/***********************************************************/
/* 32bit multply math_param3 x math_param2 -> math_param0  */
/***********************************************************/
mult32:   
 ldy #32
mult1:
 asl MATH_PARAM0
 rol MATH_PARAM0+1
 rol MATH_PARAM0+2
 rol MATH_PARAM0+3
 rol MATH_PARAM3
 rol MATH_PARAM3+1
 rol MATH_PARAM3+2
 rol MATH_PARAM3+3
 bcc mult2
 clc
 lda MATH_PARAM2
 adc MATH_PARAM0
 sta MATH_PARAM0
 lda MATH_PARAM2+1
 adc MATH_PARAM0+1
 sta MATH_PARAM0+1
 lda MATH_PARAM2+2
 adc MATH_PARAM0+2
 sta MATH_PARAM0+2
 lda MATH_PARAM2+3
 adc MATH_PARAM0+3
 sta MATH_PARAM0+3
 lda #0
 adc MATH_PARAM3
 sta MATH_PARAM3
mult2:
 dey
 bne mult1
 rts

/*********************************************************/
/* MATH_PARAM2=MATH_PARAM2/MATH_PARAM0 (32-bit unsigned) */
/*********************************************************/
udiv32:
 lda MATH_PARAM0
 ora MATH_PARAM0+1
 ora MATH_PARAM0+2
 ora MATH_PARAM0+3
 beq zerodiv
 stz MATH_PARAM1
 stz MATH_PARAM1+1
 stz MATH_PARAM1+2
 stz MATH_PARAM1+3
 ldx #32
 asl MATH_PARAM2
 rol MATH_PARAM2+1
 rol MATH_PARAM2+2
 rol MATH_PARAM2+3
udiv2:
 rol MATH_PARAM1
 rol MATH_PARAM1+1
 rol MATH_PARAM1+2
 rol MATH_PARAM1+3
 sec
 lda MATH_PARAM1
 sbc MATH_PARAM0
 sta MATH_PARAM3
 lda MATH_PARAM1+1
 sbc MATH_PARAM0+1
 sta MATH_PARAM3+1
 lda MATH_PARAM1+2
 sbc MATH_PARAM0+2
 sta MATH_PARAM3+2
 lda MATH_PARAM1+3
 sbc MATH_PARAM0+3
 bcc udiv3
 sta MATH_PARAM1+3
 lda MATH_PARAM3+2
 sta MATH_PARAM1+2
 lda MATH_PARAM3+1
 sta MATH_PARAM1+1
 lda MATH_PARAM3
 sta MATH_PARAM1
udiv3:
 rol MATH_PARAM2
 rol MATH_PARAM2+1
 rol MATH_PARAM2+2
 rol MATH_PARAM2+3
 dex
 bne udiv2
 rts
zerodiv:
 ldx #<text17
 ldy #>text17
 jsr PrintString
 brk

/*******************************************************/
/* MATH_PARAM1=MATH_PARAM2%MATH_PARAM0 (32-bit signed) */
/*******************************************************/
// NOTE: Destroys MATH_PARAM1

mod32:
 lda MATH_PARAM0+3 // dividend sign
 eor MATH_PARAM2+3
 pha               // sign of quotient
 lda MATH_PARAM0+3 // test sign of xy
 bpl mod1
 sec
 lda #0
 sbc MATH_PARAM0
 sta MATH_PARAM0
 lda #0
 sbc MATH_PARAM0+1
 sta MATH_PARAM0+1
 lda #0
 sbc MATH_PARAM0+2
 sta MATH_PARAM0+2
 lda #0
 sbc MATH_PARAM0+3
 sta MATH_PARAM0+3
mod1:
 lda MATH_PARAM2+3 // test sign of xy
 bpl mod2
 sec
 lda #0
 sbc MATH_PARAM2
 sta MATH_PARAM2
 lda #0
 sbc MATH_PARAM2+1
 sta MATH_PARAM2+1
 lda #0
 sbc MATH_PARAM2+2
 sta MATH_PARAM2+2
 lda #0
 sbc MATH_PARAM2+3
 sta MATH_PARAM2+3
mod2:
 jsr udiv32        // unsigned divide
 pla               // sign of quotient
 bpl mod3
 sec
 lda #0
 sbc MATH_PARAM1
 sta MATH_PARAM1
 lda #0
 sbc MATH_PARAM1+1
 sta MATH_PARAM1+1
 lda #0
 sbc MATH_PARAM1+2
 sta MATH_PARAM1+2
 lda #0
 sbc MATH_PARAM1+3
 sta MATH_PARAM1+3
mod3:
 rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
InitFreeList:
  stz FREE_BLOCK_CACHE_INDEX
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
AddFreeList:
  ldy FREE_BLOCK_CACHE_INDEX
  lda BLOCK
  sta FREE_BLOCK_CACHE,y
  iny
  lda BLOCK+1
  sta FREE_BLOCK_CACHE,y
  iny
  lda BLOCK+2
  sta FREE_BLOCK_CACHE,y
  iny
  lda BLOCK+3
  sta FREE_BLOCK_CACHE,y
  iny
  sty FREE_BLOCK_CACHE_INDEX
  cpy #128
  bge AddFreeList2
  rts
AddFreeList2:
  jsr RemoveFreeList
  jsr InitFreeList
  rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
RemoveFreeList:
  ldy #0      
  sty FREE_Y
  lda #$ff
  sta CACHE_BLK
  sta CACHE_BLK+1
  bra RemoveFreeList2
RemoveFreeList3:

  jsr SetupFSBlock
  jsr WriteBlock
  rts

RemoveFreeList2:
  ldy FREE_Y
  cpy FREE_BLOCK_CACHE_INDEX
  bge RemoveFreeList3

  sec
  lda FREE_BLOCK_CACHE,y  
  iny
  sbc #OS_OFFSET
  sta MATH_PARAM1
  lda FREE_BLOCK_CACHE,y  
  iny
  sbc #0
  sta MATH_PARAM1+1
  lda FREE_BLOCK_CACHE,y  
  iny
  sbc #0
  sta MATH_PARAM1+2
  lda FREE_BLOCK_CACHE,y  
  iny
  sbc #0
  sta MATH_PARAM1+3

  sty FREE_Y    

  sec
  lda MATH_PARAM1
  sbc FORMAT_FS_BLOCKS
  sta FREE_BLOCKNO
  sta MATH_PARAM2
  lda MATH_PARAM1+1
  sbc FORMAT_FS_BLOCKS+1
  sta FREE_BLOCKNO+1
  sta MATH_PARAM2+1
  lda MATH_PARAM1+2
  sbc #0
  sta FREE_BLOCKNO+2
  sta MATH_PARAM2+2
  lda MATH_PARAM1+3
  sbc #0
  sta FREE_BLOCKNO+3
  sta MATH_PARAM2+3

  stz MATH_PARAM0
  stz MATH_PARAM0+2
  stz MATH_PARAM0+3
  lda #$10
  sta MATH_PARAM0+1

  jsr udiv32

  lda MATH_PARAM2
  sta TEMP32A 
  lda MATH_PARAM2+1
  sta TEMP32A+1 

  cmp CACHE_BLK+1
  bne RemoveFreeList2c
  lda TEMP32A
  cmp CACHE_BLK
  beq RemoveFreeList2d
  
RemoveFreeList2c:
  lda CACHE_BLK
  and CACHE_BLK+1
  cmp #$ff
  beq RemoveFreeList2e

  jsr SetupFSBlock
  jsr WriteBlock

RemoveFreeList2e:
  lda TEMP32A
  sta CACHE_BLK
  lda TEMP32A+1
  sta CACHE_BLK+1

  jsr SetupFSBlock
  jsr ReadBlock

RemoveFreeList2d:
  stz MATH_PARAM3
  stz MATH_PARAM3+2
  stz MATH_PARAM3+3
  lda #$10
  sta MATH_PARAM3+1

  lda TEMP32A
  sta MATH_PARAM2
  lda TEMP32A+1
  sta MATH_PARAM2+1
  stz MATH_PARAM2+2
  stz MATH_PARAM2+3

  jsr mult32

  sec
  lda FREE_BLOCKNO
  sbc MATH_PARAM0
  sta FREE_BITNUMBER
  sta MATH_PARAM2
  lda FREE_BLOCKNO+1
  sbc MATH_PARAM0+1
  sta FREE_BITNUMBER+1
  sta MATH_PARAM2+1
  lda FREE_BLOCKNO+2
  sbc MATH_PARAM0+2
  sta FREE_BITNUMBER+2
  sta MATH_PARAM2+2
  lda FREE_BLOCKNO+3
  sbc MATH_PARAM0+3
  sta FREE_BITNUMBER+3
  sta MATH_PARAM2+3

  lda #8
  sta MATH_PARAM0
  stz MATH_PARAM0+1
  stz MATH_PARAM0+2
  stz MATH_PARAM0+3

  jsr udiv32

  lda MATH_PARAM2
  sta FREE_BYTENUMBER
  lda MATH_PARAM2+1
  sta FREE_BYTENUMBER+1
  lda MATH_PARAM2+2
  sta FREE_BYTENUMBER+2
  lda MATH_PARAM2+3
  sta FREE_BYTENUMBER+3

  lda #8
  sta MATH_PARAM3
  stz MATH_PARAM3+1
  stz MATH_PARAM3+2
  stz MATH_PARAM3+3

  jsr mult32

  sec
  lda FREE_BITNUMBER
  sbc MATH_PARAM0
  sta FREE_BITNUMBER

  jsr SetupFileBlock2

  lda FREE_BYTENUMBER+1

  beq NoInc256
  inc ADDRESS+1
NoInc256:
  ldy FREE_BYTENUMBER
  lda (ADDRESS),y
  ldx FREE_BITNUMBER
  ora bitLut2,x
  sta (ADDRESS),y

  jmp RemoveFreeList2


/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
/*  SOUND BLASTER DSP ROUTINES                                            */
/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
InitDSP:
     lda #2
     jsr SetHighAddress   /* DSP Base $2xx */
     ldx #DSP_RESET_PORT
     lda #$1
     jsr WriteISA
     jsr DSPDelay
     ldx #DSP_RESET_PORT
     lda #$0
     jsr WriteISA
     ldy #0
FindDSP:
     ldx #DSP_READ_DATA_PORT
     jsr ReadISA
     cmp #$aa
     beq FoundDSP
     iny
     cpy #100
     bne FindDSP
     lda #'n'
     jsr OutChar
     lda #'o'
     jsr OutChar
     lda #0
     rts
FoundDSP:
     lda #$D1
     ldx #DSP_WRITE_DATA_CMD
     jsr WriteISA
     jsr DSPDelay
     lda #1
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
DSPDelay:
     tya
     pha
     ldy #5
DSPDelay2:
     dey
     bne DSPDelay2
     pla
     tay
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
DataToDSP:
     pha
     lda #2
     sta PIA1_DATA_PORT_B // Set hi-Address 
     lda #$10
     ldx #DSP_WRITE_DATA_CMD
     jsr WriteISA      
     jsr DSPDelay
     ldx #DSP_WRITE_DATA_CMD
     pla
     jsr WriteISA
     jsr DSPDelay
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
DSPClose:
     lda #2
     sta PIA1_DATA_PORT_B // Set hi-Address 
     lda #$D3
     ldx #DSP_WRITE_DATA_CMD
     jsr WriteISA
     jsr DSPDelay
     rts

/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
/*  KEYBOARD DEVICE DRIVER                                                */
/**************************************************************************/
/**************************************************************************/
/**************************************************************************/

#define TEMP_GETCH $ff

/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
PauseCheck:
     jsr get_kbd_packet
     jsr process_kbd_packet 
     beq PauseErr
     cmp #$14
     bne PauseErr
     jsr get_kbd_packet
     jsr process_kbd_packet 
     beq PauseErr
     cmp #$77
     bne PauseErr
     jsr get_kbd_packet
     jsr process_kbd_packet 
     beq PauseErr
     cmp #$e1
     bne PauseErr
     lda #PAUSE_KEY
     rts
PauseErr:
     jmp err

/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
Getch:
     phx
     phy
     jsr GetKey
     ply
     plx
     rts

/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
GetKey:
     jsr get_kbd_packet
     jsr process_kbd_packet 
     beq GetKey
     cmp #$12
     beq ShiftDown
     cmp #$59
     beq ShiftDown
     cmp #$F0
     beq KeyUp
     cmp #$FF
     beq GetKey
     cmp #$AA
     beq GetKey
     cmp #$FA
     beq GetKey
     cmp #$E0
     beq MFIIKey
     cmp #$E1
     beq PauseCheck
     ldy #0    
Getch1:
     cmp SCAN_CODE_LUT,y
     beq Getch2
     iny
     iny
     cpy #SCAN_CODE_LUT_END-SCAN_CODE_LUT
     bne Getch1
     jmp err
Getch2:
     iny
     lda SCAN_CODE_LUT,y
     pha
     lda SHIFT_DOWN
     beq Getch3
     pla
     ldx #0     
Getch2a:
     cmp ASCII_SHIFT_TABLE,x
     beq Getch2b
     inx
     inx
     cpx #ASCII_SHIFT_TABLE_END-ASCII_SHIFT_TABLE
     bne Getch2a
     lda SCAN_CODE_LUT,y
     rts
Getch2b:
     inx
     lda ASCII_SHIFT_TABLE,x 
     rts
Getch3:
     pla
     rts

/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
ShiftDown:
     lda #1
     sta SHIFT_DOWN
     jmp GetKey

/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
ShiftUp:
     stz SHIFT_DOWN
     jmp GetKey

/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
KeyUp:
     jsr get_kbd_packet
     jsr process_kbd_packet 
     cmp #$12
     beq ShiftUp
     cmp #$59
     beq ShiftUp
     jmp GetKey

/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
MFIIKey:
     jsr get_kbd_packet
     jsr process_kbd_packet 
     ldy #0    
MFIIKey1:
     cmp SPECIAL_SCAN_CODE_LUT,y
     beq MFIIKey2
     iny
     iny
     cpy #SPECIAL_SCAN_CODE_LUT_END-SPECIAL_SCAN_CODE_LUT
     bne MFIIKey1
     jmp err
MFIIKey2:
     iny
     lda SPECIAL_SCAN_CODE_LUT,y
     pha
     jsr get_kbd_packet
     jsr process_kbd_packet 
     cmp #$E0
     beq MFIIKey3 
     pla    
     jmp err
MFIIKey3: 
     pla
     cmp #PRINT_SCR
     beq PrintScreen
     rts

/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
PrintScreen:
     jsr get_kbd_packet
     jsr get_kbd_packet
     jsr get_kbd_packet
     jsr get_kbd_packet
     jsr get_kbd_packet
     jsr process_kbd_packet  
     cmp #$E0
     beq PrintScreen2
     jmp err
PrintScreen2:
     lda #PRINT_SCR
     rts

/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
process_kbd_packet:
     lda STRING_BUFFER       // Check Start Bit
     bne err2
     lda STRING_BUFFER+10    // Check Stop Bit
     beq err2
     ldy #0
     ldx #1
process1:
     lda STRING_BUFFER,x
     beq process2
     iny
process2:
     lsr A
     ror TEMP_GETCH
     inx
     cpx #9
     bne process1
     tya
     and #1
     cmp STRING_BUFFER+9
     beq err2
     lda TEMP_GETCH
     rts
err2:
     jsr CRLF
     lda #'E'
     jsr OutACIA
     lda #'R'
     jsr OutACIA
     lda #'R'
     jsr OutACIA
     jsr CRLF
     lda #0
     rts

/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
err:        
     lda #'K'
     jsr OutChar
     lda #'B'
     jsr OutACIA
     lda #'E'
     jsr OutACIA
     lda #'R'
     jsr OutACIA
     lda #'R'
     jsr OutACIA
     jmp GetKey 
     
/**************************************************************************/
/**************************************************************************/
/**************************************************************************/
get_kbd_packet:
     lda #0
     sta PIA4_DATA_DIR_A
     ldx #0
get_bit:
     lda #$02  
wait_for_low:
     bit PIA4_DATA_PORT_A
     bne wait_for_low
     lda PIA4_DATA_PORT_A
     and #1
     sta STRING_BUFFER,x
     lda #$02 
wait_for_high:
     bit PIA4_DATA_PORT_A
     beq wait_for_high
     inx
     cpx #11    
     bne get_bit
     lda #$2
     sta PIA4_DATA_DIR_A
     stz PIA4_DATA_PORT_A
     rts

/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
SetupVectors:
     lda #<OutChar
     sta OutChar_VECTOR
     lda #>OutChar
     sta OutChar_VECTOR+1

     lda #<PrintString
     sta PrintString_VECTOR
     lda #>PrintString
     sta PrintString_VECTOR+1

     lda #<Getch
     sta Getch_VECTOR
     lda #>Getch
     sta Getch_VECTOR+1

     lda #<Eof
     sta Eof_VECTOR
     lda #>Eof
     sta Eof_VECTOR+1

     lda #<CloseFile
     sta CloseFile_VECTOR
     lda #>CloseFile
     sta CloseFile_VECTOR+1

     lda #<OpenFile
     sta OpenFile_VECTOR
     lda #>OpenFile
     sta OpenFile_VECTOR+1

     lda #<ReadByte
     sta ReadByte_VECTOR
     lda #>ReadByte
     sta ReadByte_VECTOR+1

     lda #<WriteByte
     sta WriteByte_VECTOR
     lda #>WriteByte
     sta WriteByte_VECTOR+1

     lda #<SetVGAMode
     sta SetVGAMode_VECTOR
     lda #>SetVGAMode
     sta SetVGAMode_VECTOR+1
     
     lda #<InACIA
     sta InACIA_VECTOR
     lda #>InACIA
     sta InACIA_VECTOR+1

     lda #<OutACIA
     sta OutACIA_VECTOR
     lda #>OutACIA
     sta OutACIA_VECTOR+1

     lda #<CommandInterpreter
     sta CommandInterpreter_VECTOR
     lda #>CommandInterpreter
     sta CommandInterpreter_VECTOR+1

     lda #<Main
     sta Reset_VECTOR
     lda #>Main
     sta Reset_VECTOR+1

     rts

.endseg

#ifndef TESTBED

     .org $fffa

.seg  DATA

    .db #<Main,#>Main
    .db #<Main,#>Main
    .db #<Main,#>Main

.endseg

#endif
