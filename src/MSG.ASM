
        dosseg
        .model  tpascal
        .8086

        .data

MessTable       LABEL   BYTE

                DW      Mess1
                DW      Mess2
                DW      Mess3
                DW      Mess4
                DW      Mess5
                DW      Mess6
                DW      Mess7
                DW      Mess8
                DW      Mess9
                DW      Mess10
                DW      Mess11
                DW      Mess12
                DW      Mess13
                DW      Mess14
                DW      Mess15
                DW      Mess16
                DW      Mess17
                DW      Mess18
                DW      Mess19
                DW      Mess20
                DW      Mess21
                DW      Mess22
                DW      Mess23
                DW      Mess24
                DW      Mess25
                DW      Mess26
                DW      Mess27
                DW      Mess28
                DW      Mess29
                DW      Mess30
                DW      Mess31
                DW      Mess32
                DW      Mess33
                DW      Mess34
                DW      Mess35
                DW      Mess36
                DW      Mess37
                DW      Mess38
                DW      Mess39
                DW      Mess40
                DW      Mess41
                DW      Mess42
                DW      Mess43
                DW      Mess44
                DW      Mess45
                DW      Mess46
                DW      Mess47
                DW      Mess48
                DW      Mess49
                DW      Mess50
                DW      Mess51
                DW      Mess52
                DW      Mess53
                DW      Mess54
                DW      Mess55
                DW      Mess56
                DW      Mess57
                DW      Mess58
                DW      Mess59
                DW      Mess60
                DW      Mess61
                DW      Mess62
                DW      Mess63
                DW      Mess64
                DW      Mess65
                DW      Mess66
                DW      Mess67
                DW      Mess68
                DW      Mess69
                DW      Mess70
                DW      Mess71
                DW      Mess72
                DW      Mess73
                DW      Mess74
                DW      Mess75
                DW      Mess76
                DW      Mess77
                DW      Mess78
                DW      Mess79
                DW      Mess80
                DW      Mess81
                DW      Mess82
                DW      Mess83
                DW      Mess84
                DW      Mess85
                DW      Mess86
                DW      Mess87
                DW      Mess88
                DW      Mess89
                DW      Mess90

Mess1   DB      23, 'Invalid function number'
Mess2   DB      14, 'File not found'
Mess3   DB      14, 'Path not found'
Mess4   DB      20, 'No handles available'
Mess5   DB      13, 'Access denied'
Mess6   DB      14, 'Invalid handle'
Mess7   DB      26, 'Memory control blocks lost'
Mess8   DB      19, 'Insufficient memory'
Mess9   DB      22, 'Invalid memory address'
Mess10  DB      19, 'Invalid environment'
Mess11  DB      14, 'Invalid format'
Mess12  DB      19, 'Invalid access code'
Mess13  DB      12, 'Invalid data'
Mess14  DB      0
Mess15  DB      13, 'Invalid drive'
Mess16  DB      35, 'Attempt to remove current directory'
Mess17  DB      19, 'Not the same device'
Mess18  DB      13, 'No more files'
Mess19  DB      20, 'Disk write-protected'
Mess20  DB      12, 'Unknown unit'
Mess21  DB      15, 'Drive not ready'
Mess22  DB      15, 'Unknown command'
Mess23  DB      16, 'Data error (CRC)'
Mess24  DB      28, 'Bad request structure length'
Mess25  DB      10, 'Seek error'
Mess26  DB      18, 'Unknown media type'
Mess27  DB      16, 'Sector not found'
Mess28  DB      20, 'Printer out of paper'
Mess29  DB      11, 'Write fault'
Mess30  DB      10, 'Read fault'
Mess31  DB      15, 'General failure'
Mess32  DB      22, 'File sharing violation'
Mess33  DB      14, 'Lock violation'
Mess34  DB      19, 'Invalid disk change'
Mess35  DB      15, 'FCB unavaliable'
Mess36  DB      23, 'Sharing buffer overflow'
Mess37  DB      0
Mess38  DB      33, 'Unable to complete file operation'
Mess39  DB      0
Mess40  DB      0
Mess41  DB      0
Mess42  DB      0
Mess43  DB      0
Mess44  DB      0
Mess45  DB      0
Mess46  DB      0
Mess47  DB      0
Mess48  DB      0
Mess49  DB      0
Mess50  DB      27, 'Unsupported network request'
Mess51  DB      29, 'Remote computer not listening'
Mess52  DB      25, 'Duplicate name on network'
Mess53  DB      22, 'Network name not found'
Mess54  DB      12, 'Network busy'
Mess55  DB      34, 'Device no longer exists on network'
Mess56  DB      30, 'NetBIOS command limit exceeded'
Mess57  DB      24, 'Error in network adapter'
Mess58  DB      31, 'Incorrect response from network'
Mess59  DB      24, 'Unexpected network error'
Mess60  DB      27, 'Remote adapter incompatible'
Mess61  DB      16, 'Print queue full'
Mess62  DB      14, 'Queue not full'
Mess63  DB      30, 'Not enough room for print file'
Mess64  DB      20, 'Network name deleted'
Mess65  DB      13, 'Access denied'
Mess66  DB      29, 'Incorrect network device type'
Mess67  DB      22, 'Network name not found'
Mess68  DB      27, 'Network name limit exceeded'
Mess69  DB      30, 'NETBIOS session limit exceeded'
Mess70  DB      15, 'Temporary pause'
Mess71  DB      28, 'Network request not accepted'
Mess72  DB      32, 'Print or disk redirection paused'
Mess73  DB      0
Mess74  DB      0
Mess75  DB      0
Mess76  DB      0
Mess77  DB      0
Mess78  DB      0
Mess79  DB      0
Mess80  DB      19, 'File already exists'
Mess81  DB      0
Mess82  DB      21, 'Cannot make directory'
Mess83  DB      14, 'Fail on Int 24'
Mess84  DB      21, 'Too many redirections'
Mess85  DB      21, 'Duplicate redirection'
Mess86  DB      16, 'Invalid password'
Mess87  DB      17, 'Invalid parameter'
Mess88  DB      19, 'Network write fault'
Mess89  DB      28, 'Unsupported network function'
Mess90  DB      24, 'Missing system component'

        .code

ErrString       PROC    FAR ErrNum: BYTE RETURNS ErrStr: DWORD
                PUBLIC  ErrString
        PUSH    DS
        CLD
        MOV     AX, ErrNum
        SHL     AX, 1
        LDS     SI, MessTable
        LES     DI, ErrStr
        ADD     SI, AX
        LODSB
        STOSB
        MOV     CX, AX
        XOR     CH, CH
        JCXZ    ESDone
        REP     MOVSB
ESDone: POP     DS
        RET
ErrString       ENP

        END

