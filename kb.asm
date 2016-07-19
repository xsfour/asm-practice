code SEGMENT
    ASSUME CS:code

start:
    JMP init
    NOP
    old_int9 DD ?
    old_int1c DD ?
    cnt DW 1

;-----------------------------------
;             INT 09H
;-----------------------------------
int9:
    PUSH AX
    PUSH BX
    PUSH DS
    PUSH ES
    PUSH SI
    PUSH DI

    MOV AX, 40H
    MOV ES, AX
    MOV DI, WORD PTR ES:[1CH]       ; tail point

    PUSHF
    CALL DWORD PTR CS:old_int9      ; call original INT

    MOV AH, 01H
    INT 16H         
    JZ return          
    
    MOV BX, WORD PTR CS:cnt         ; 
    CMP BX, 183                     ;   
    JNG not_dirty_click             ;   
    MOV WORD PTR ES:[DI], 0000H     ; TO IGNORE KEYBOARD INPUTS   
    JMP return                      ;   
                                    
not_dirty_click:
    MOV SI, 200H
    XOR BX, BX
    MOV DS, BX
check:
    CMP AH, BYTE PTR DS:[SI+BX]
    JE change_buffer
    CMP BX, 25
    JE int9_ret
    INC BX
    JMP check

change_buffer:
    MOV AH, DS:[SI+BX+1]
    CMP AH, 1EH
    JNE inc_ascii
    SUB AL, 26
inc_ascii:
    INC AL
    MOV ES:[DI], AX                 ; change KBBuffer

int9_ret:
    CMP AH, 3EH                     ; press F4 to restore
    JNE return
restore:
    MOV AX, 0
    MOV ES, AX
                                        
    CLI
                                    ;RESTORE INT 09H
    MOV AX, WORD PTR CS:old_int9
    MOV ES:[9*4], AX
    MOV AX, WORD PTR CS:old_int9+2
    MOV ES:[9*4+2], AX
                                        
    ;JMP RETURN
                                    ;RESTORE INT 1CH
    MOV AX, WORD PTR CS:old_int1c
    MOV ES:[112], AX
    MOV AX, WORD PTR CS:old_int1c+2
    MOV ES:[114], AX

    STI
                                    ;RESTORE COLOR
    MOV BX, 0B800H
    MOV ES, BX
    MOV BX, 1
sl: 
    MOV BYTE PTR ES:[BX], 00000111B
    ADD BX, 2
    CMP BX, 8001
    JNZ sl

return:
    POP DI
    POP SI
    POP ES
    POP DS
    POP BX
    POP AX
    IRET

;------------------------------------
;            INT 1CH
;------------------------------------
int1c:
    PUSH AX
    PUSH BX
    PUSH ES

    MOV AX, WORD PTR CS:cnt
    CMP AX, 183
    JE kb_disable
    CMP AX, 2
    JE kb_enable
    JMP count

kb_enable:
    MOV AH, 00100100B
    JMP set_color

kb_disable:
    MOV AH, 01000010B

set_color:
    MOV BX, 0B800H
    MOV ES, BX
    MOV BX, 1
s:
    MOV BYTE PTR ES:[BX], AH
    ADD BX, 2
    CMP BX, 8001
    JNZ s

count:
    MOV AX, WORD PTR CS:cnt
    CMP AX, 364
    JNE inc_cnt
    MOV AX, 0
inc_cnt:
    INC AX
    MOV WORD PTR CS:cnt, AX

int1c_ret:
    POP ES
    POP BX
    POP AX
    IRET

;------------------------------------
;              INIT
;------------------------------------
init:
    JMP init_start
             ;  A    B    C    D    E    F    G    H    I    J
    kb_code DB 1EH, 30H, 2EH, 20H, 12H, 21H, 22H, 23H, 17H, 24H
             ;  K    L    M    N    O    P    Q    R    S    T
            DB 25H, 26H, 32H, 31H, 18H, 19H, 10H, 13H, 1FH, 14H
             ;  U    V    W    X    Y    Z    A
            DB 16H, 2FH, 11H, 2DH, 15H, 2CH, 1EH
init_start:
    XOR BX, BX                      ;
    LEA SI, CS:kb_code             
    MOV ES, BX
sm: 
    MOV AH, BYTE PTR CS:[SI+BX]
    MOV BYTE PTR ES:[200H+BX], AH
    INC BX
    CMP BX, 26
    JBE sm
        

    CLI
    
    MOV AX, 0
    MOV ES, AX

                                    ;INSTALL INT 9H
    MOV AX, WORD PTR ES:[4*9]
    MOV WORD PTR CS:old_int9, AX
    MOV AX, WORD PTR ES:[4*9+2]
    MOV WORD PTR CS:old_int9+2, AX

    LEA AX, int9
    MOV WORD PTR ES:[4*9], AX
    MOV WORD PTR ES:[4*9+2], CS

    ;JMP SKIP_INS_ICH
                                    ;INSTALL INT 1CH
    MOV AX, WORD PTR ES:[112]
    MOV WORD PTR CS:old_int1c, AX
    MOV AX, WORD PTR ES:[114]
    MOV WORD PTR CS:old_int1c+2, AX

    LEA AX, int1c
    MOV WORD PTR ES:[112], AX
    MOV WORD PTR ES:[114], CS
SKIP_INS_ICH:
    STI

    MOV AH, 0
    MOV AL, 3
    INT 10H                         ; CLS

    JMP show_msg
    msg DB '====================================================================='
        DB 13, 10
        DB '|                          It works!                                |' 
        DB 13, 10
        DB '|                                                                   |'
        DB 13, 10
        DB '| First 10 seconds:                                                 |' 
        DB 13, 10 
        DB '|   The background color is GREEN.                                  |' 
        DB 13, 10
        DB '|   You can type in or press <F4 to RESTORE> the keyboard           |' 
        DB 13, 10 
        DB '|                                                                   |'
        DB 13, 10
        DB '| Next 10 seconds:                                                  |' 
        DB 13, 10 
        DB '|   The backgroung color turn to RED, and the keyboard is forbidden |'                             
        DB 13, 10
        DB '|                                                                   |'
        DB 13, 10
        DB '| Notes:                                                            |'      
        DB 13, 10
        DB '|   "INT 9H" and "INT 1CH" are used.                                |'
        DB 13, 10
        DB '|                                                                   |'
        DB 13, 10
        DB '====================================================================='
        DB 13, 10 
        DB '$'
show_msg:
    MOV DX, SEG msg
    MOV DS, DX
    MOV DX, OFFSET msg
    MOV Ax, 0900H
    INT 21H

    LEA DX, init
    INT 27H

code ENDS
END start
