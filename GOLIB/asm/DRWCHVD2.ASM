; by ERNESTO CIANCIOTTA (c) 1995

; /*********************************************************************
; \
; / Procedura di per il disegno di un carattere bitmapped formato Windows(TM).
; \ Questa procedura disegna direttamente sul Frame-Buffer.
; /
; \ VERSIONE PROTOTIPO   1.0.
; /
; \ N.B.: Solo per Intel 80386 e successivi.
; /
; \*********************************************************************

.286

;------------------------ Definizione Macro --------------------------------


PAGINE_VIDEO MACRO SequData,GDC

             mov       dx,3C5h
             mov       al,SequData
             out       dx,al
             mov       dx,3CFh
             mov       al,GDC
             out       dx,al

             ENDM




TRACCIA_COLONNA  MACRO  pagina,StackPos,SequData,GDC

             PAGINE_VIDEO SequData,GDC

             mov       ax,_&pagina&OpCodeLogic
             mov       WORD PTR cs:_&pagina&Logic_Par,ax

             push      cx
             push      di

             mov       si,PrecSI       ; Posiziona SI
_&pagina&CopiaLinea:
             lodsb                     ; Legge la linea del font in AL

             and       al,leftMask     ; Clipping del margine sinistro
             cmp       al,0
             je        _&pagina&Salto_Linea
             and       al,rightMask    ; Clipping del margine destro

             xor       ah,ah           ; Azzera AH

             db        0C1h,0C8h       ; opcode:  ROR AX,<n>; Effettua lo shifting
_&pagina&Ror_Par:
             db        ?

;----------------------------------------------------------------------------
_&pagina&Not_Opcode:
             not       ax

             db        26h             ; opcode:  AND o OR
_&pagina&Logic_Par:
                                  ;      /9h,5h   =>  OR WORD PTR es:[di],ax
                                  ;     <
                                  ;    / \8h,25h  =>  OR BYTE PTR es:[di],ah
                                  ;   /
             dw        ?          ;  <
                                  ;   \
                                  ;    \ /21h,5h  =>  AND WORD PTR es:[di],ax
                                  ;     <
                                  ;      \20h,25h =>  AND BYTE PTR es:[di],ah

;----------------------------------------------------------------------------

_&pagina&Salto_Linea:
             dec       cx
             cmp       cx,validDown
             jne       _&pagina&SaltoNormale
             add       si,cx
             jmp       SHORT _&pagina&FineLinea
_&pagina&SaltoNormale:
             jcxz      _&pagina&FineLinea
             add       di,SaltoDI
             jmp       _&pagina&CopiaLinea

_&pagina&FineLinea:
             db        0C7h,46h,StackPos   ;MOV _&pagina&OpCodeLogic,<dw>   ;Normale
_&pagina&Mov4_Par:
             dw        ?

             pop       di
             pop       cx

             ENDM




;------------------------ Definizione Dati ---------------------------------



DATA         SEGMENT WORD PUBLIC
             ASSUME ds:DATA

             EXTRN MaxXResolution:WORD

DATA         ENDS



;------------------------ Definizione Codice -------------------------------



CODE         SEGMENT BYTE PUBLIC
             ASSUME cs:CODE


ColorProc    PROC NEAR

.386
;----------------------------------------------------------------------------
; Prima Pagina
             TRACCIA_COLONNA  1,0FEh,1,0
;----------------------------------------------------------------------------
; Seconda Pagina
             TRACCIA_COLONNA  2,0FCh,2,1
;----------------------------------------------------------------------------
; Terza Pagina
             TRACCIA_COLONNA  3,0FAh,4,2
;----------------------------------------------------------------------------
; Quarta Pagina
             TRACCIA_COLONNA  4,0F8h,8,3
.286
             ret
             ENDP



OR_Normale   = 0509h
OR_Speciale  = 2508h
Nop_OpCode   = 9090h

_1_          = OR_Normale
_1__         = OR_Speciale
_1___        = Nop_OpCode


AND_Normale  = 0521h
AND_Speciale = 2520h
Not_OpCode   = 0D0F7h

_0_          = AND_Normale
_0__         = AND_Speciale
_0___        = Not_OpCode





DrawCharVideoDC     PROC NEAR
             PUBLIC DrawCharVideoDC
             ARG    index:DWORD, color:BYTE, adjustShift:BYTE, adjustFBPos:BYTE, validDown:WORD, outUp:WORD, validRight:WORD, outLeft:WORD, _Height_:WORD, _Width_:WORD, y:WORD, x:WORD= RetBytes

             LOCAL     _1OpCodeLogic,_2OpCodeLogic,_3OpCodeLogic,_4OpCodeLogic,ClipSup,PrecSI,PrecDI,SaltoDI,ShortJumpDI,a_pos_x2,a_pos_x1,__cx,colonne:BYTE,colLeft:BYTE,rightMask:BYTE,leftMask:BYTE=VariabiliLocali
.386
             enter     VariabiliLocali,0
             push      ds

             ;MOV _1OpCodeLogic,0
             ;MOV _2OpCodeLogic,0
             ;MOV _3OpCodeLogic,0
             ;MOV _4OpCodeLogic,0

; DETERMINAZIONE DEL PUNTATORE ALLA PROCEDURA DEL COLORE


; Macro di selezione
;-------------------
SET_CODE     MACRO pagina,Operation
             mov       WORD PTR cs:_&pagina&Mov1_Par,_&Operation&_
             mov       WORD PTR cs:_&pagina&Mov2_Par,_&Operation&__
             mov       WORD PTR cs:_&pagina&Mov3_Par,_&Operation&__
             mov       WORD PTR cs:_&pagina&Mov4_Par,_&Operation&_
             mov       WORD PTR cs:_&pagina&Not_OpCode,_&Operation&___
             ENDM


SELECT_COLOR_POINTER MACRO actual,succ,p4,p3,p2,p1
ColorProc&Actual&:
             cmp       al,Actual
             jne       ColorProc&succ&

             SET_CODE  1,p1
             SET_CODE  2,p2
             SET_CODE  3,p3
             SET_CODE  4,p4

             jmp       ColorProcOK
ColorProc&succ&:
             ENDM



; Selezione
;-------------------
             mov       al,color
             SELECT_COLOR_POINTER 0,1,   0,0,0,0
             SELECT_COLOR_POINTER 1,2,   0,0,0,1
             SELECT_COLOR_POINTER 2,3,   0,0,1,0
             SELECT_COLOR_POINTER 3,4,   0,0,1,1
             SELECT_COLOR_POINTER 4,5,   0,1,0,0
             SELECT_COLOR_POINTER 5,6,   0,1,0,1
             SELECT_COLOR_POINTER 6,7,   0,1,1,0
             SELECT_COLOR_POINTER 7,8,   0,1,1,1
             SELECT_COLOR_POINTER 8,9,   1,0,0,0
             SELECT_COLOR_POINTER 9,10,  1,0,0,1
             SELECT_COLOR_POINTER 10,11, 1,0,1,0
             SELECT_COLOR_POINTER 11,12, 1,0,1,1
             SELECT_COLOR_POINTER 12,13, 1,1,0,0
             SELECT_COLOR_POINTER 13,14, 1,1,0,1
             SELECT_COLOR_POINTER 14,15, 1,1,1,0
ColorProc15:
             SET_CODE  1,1
             SET_CODE  2,1
             SET_CODE  3,1
             SET_CODE  4,1
ColorProcOK:


; PRIMA FASE DI INIZIALIZZAZIONE

;_Width_ = ((_Width_+7) div 8)*8
;             add       _Width_,7         ; approssima per eccesso a
;             and       _Width_,0FFF8h    ; un mulptiplo di 8

; a_pos_x1 = ( x div 8)+(MaxXResolution div 8)*y
             mov       ax,x
             xor       dx,dx           ; dx = 0000h
             mov       cx,8
             div       cx              ; cx = 8
             push      ax
             mov       ax,MaxXResolution ; Carica in AX la larghezza del DC
             xor       dx,dx
             div       cx
             mov       cx,ax           ; CX <- MaxXResolution div 8
             mov       ax,y
             xor       dx,dx
             mul       cx              ; AX <- (y*bx)
             mov       bx,ax           ; BX <- (MaxXResolution div 8)*y
             pop       ax
             add       ax,bx
             mov       a_pos_x1,ax

; a_pos_x2 = [(x+7) div 8]+(MaxXResolution div 8)*y
             mov       ax,x
             add       ax,7
             xor       dx,dx           ; dx = 0000h
             mov       cx,8
             div       cx              ; cx = 8
             add       ax,bx           ; bx = (MaxXResolution div 8)*y
             mov       a_pos_x2,ax

; __cx = a_pos_x2 - a_pos_x1 - 1
             mov       ax,a_pos_x2
             sub       ax,a_pos_x1
             dec       ax
             mov       __cx,ax

; SaltoDI = (MaxXResolution div 8)-2-__cx
             mov       ax,MaxXResolution
             shr       ax,3               ; AX <- AX div 8
             sub       ax,__cx
             dec       ax
             dec       ax
             mov       SaltoDI,ax


; SECONDA FASE DI INIZIALIZZAZIONE

; preparazione shifts verso destra da applicare al font
             mov       ax,x
                                       ; cl = 8
             div       cl
             mov       bh,ah           ; bh contiene gli shift da destra
             cmp       adjustShift,0
             je        ShiftingNormale
             cmp       adjustShift,8
             jne       Pos_FB_OK
             dec       a_pos_x1
Pos_FB_OK:
             add       bh,adjustShift  ; Corregge lo shift nel caso in cui
                                       ; la x fosse originariamente negativa
             dec       SaltoDI
             dec       a_pos_x1        ; Retrocede a_pos_x1
ShiftingNormale:

; VARIABILI PER IL CLIPPING

; colonne = (validRight+7) div 8
             mov       ax,validRight
             add       ax,7
             shr       ax,3
             mov       colonne,al

             mov       colLeft,1
             mov       leftMask,0FFh
             cmp       outLeft,0FFFFh
             je        MargineS_OK

; colLeft = (outLeft+7) div 8
             mov       ax,outLeft
             add       ax,7
             shr       ax,3            ; ax = ax div 8
             mov       colLeft,al

; leftMask = 0FFh shr (outLeft mod 8)
             mov       ax,outLeft
                                       ; cl = 8
             div       cl
             cmp       ah,0
             jne       NormalLeftMask
             mov       leftMask,0
             jmp       SHORT MargineS_OK
NormalLeftMask:
             mov       ax,outLeft
                                       ; cl = 8
             div       cl              ; ah = (outLeft mod 8)
             mov       cl,ah           ; cl = ah
             shr       leftMask,cl
MargineS_OK:

             mov       rightMask,0FFh
             mov       ax,_Width_
             cmp       validRight,ax
             je        MargineD_OK
             cmp       colonne,1
             jne       MargineD_OK
; rightMask = 0FFh shl (8-(validRight mod 8))
             mov       ax,validRight
             mov       cl,8            ; cl = 8
             div       cl              ; ah = (validRight mod 8)
             cmp       ah,0
             je        MargineD_OK
             sub       cl,ah           ; cl = (cl-ah)
             shl       rightMask,cl
MargineD_OK:

             cmp       validDown,0FFFFh
             je        MargineInf_OK

; validDown = _Height_-validDown
             mov       ax,_Height_
             sub       ax,validDown
             mov       validDown,ax
MargineInf_OK:



; PROCESSO DI DISEGNO DEL CARATTERE
             cld                       ; direzione incrementale

             lds       si,index

; Prima parte del clipping del margine sinistro

             xor       ah,ah
             mov       al,colLeft
             dec       al              ; al = colLeft-1

; colonne = colonne - (colLeft-1)
             sub       colonne,al

; a_pos_x1 = a_pos_x1 + (colLeft-1) - adjustFBpos
             xor       dh,dh
             mov       dl,adjustFBpos
             add       a_pos_x1,ax
             sub       a_pos_x1,dx

             mov       cx,_Height_
             mul       cx              ; ax = (colLeft-1)*_Height_

; SI = SI + (colLeft-1)*_Height_
             add       si,ax

; Posizionamento degli OFFSETS dei puntatori alle pagine
             mov       ax,0A000h
             mov       es,ax
             mov       ax,a_pos_x1
             mov       di,ax
             mov       PrecDI,di
             db        0C7h,46h,0FEh   ;MOV _1OpCodeLogic,<dw>   ;Normale
_1Mov1_Par:
             dw        ?
             db        0C7h,46h,0FCh   ;MOV _2OpCodeLogic,<dw>   ;Normale
_2Mov1_Par:
             dw        ?
             db        0C7h,46h,0FAh   ;MOV _3OpCodeLogic,<dw>   ;Normale
_3Mov1_Par:
             dw        ?
             db        0C7h,46h,0F8h   ;MOV _4OpCodeLogic,<dw>   ;Normale
_4Mov1_Par:
             dw        ?
Controllo1:
             cmp       ax,0FFFEh
             jne       Controllo2
             db        0C7h,46h,0FEh   ;MOV _1OpCodeLogic,<dw>   ;Normale
_1Mov2_Par:
             dw        ?
             db        0C7h,46h,0FCh   ;MOV _2OpCodeLogic,<dw>   ;Normale
_2Mov2_Par:
             dw        ?
             db        0C7h,46h,0FAh   ;MOV _3OpCodeLogic,<dw>   ;Normale
_3Mov2_Par:
             dw        ?
             db        0C7h,46h,0F8h   ;MOV _4OpCodeLogic,<dw>   ;Normale
_4Mov2_Par:
             dw        ?
             mov       di,0
             inc       PrecDI
             mov       leftMask,0FFh
             dec       colonne
             cmp       colonne,0
             jne       ColonneOK
             jmp       FineProc
ColonneOK:
             add       si,_Height_
             jmp       SHORT IndirizzoOK
Controllo2:
             cmp       ax,0FFFFh
             jne       IndirizzoOK
             db        0C7h,46h,0FEh   ;MOV _1OpCodeLogic,<dw>   ;Normale
_1Mov3_Par:
             dw        ?
             db        0C7h,46h,0FCh   ;MOV _2OpCodeLogic,<dw>   ;Normale
_2Mov3_Par:
             dw        ?
             db        0C7h,46h,0FAh   ;MOV _3OpCodeLogic,<dw>   ;Normale
_3Mov3_Par:
             dw        ?
             db        0C7h,46h,0F8h   ;MOV _4OpCodeLogic,<dw>   ;Normale
_4Mov3_Par:
             dw        ?
             mov       di,0
IndirizzoOK:

             mov       dx,3C4h
             mov       al,2
             out       dx,al           ; seleziona il registro delle pagine attive
             mov       dx,3CEh
             mov       al,4
             out       dx,al           ; seleziona il GDC index a 4

             inc       SaltoDI
             cmp       bh,0
             je        Copia
             inc       SaltoDI

; **************************                       **************************
; ************************** Disegno del carattere **************************
; **************************                       **************************

Copia:

; Clipping del margine superiore
             mov       ClipSup,0
             cmp       outUp,0FFFFh
             je        MargineSup_OK
             mov       ax,outUp
             mov       ClipSup,ax
             sub       _Height_,ax

MargineSup_OK:
             mov       cl,colonne
             xor       ch,ch

CopiaColonna:
             push      cx
             mov       cx,_Height_     ; cx = Numero di linee

             add       si,ClipSup

             mov       PrecSI,si

;----------------------------------------------------------------------------

             call      NEAR PTR ColorProc

;----------------------------------------------------------------------------
; CAMBIO COLONNA

             pop       cx
             dec       cx
             jcxz      FineColonna
             inc       PrecDI
             mov       di,PrecDI
             mov       leftMask,0FFh
             cmp       cx,1
             jne       ContinuaColonna

; Preparazione per il clipping del margine destro
             mov       ax,_Width_
             cmp       validRight,ax
             je        ContinuaColonna
; rightMask = 0FFh shl (8-(validRight mod 8))
             mov       ax,validRight
             mov       cl,8            ; cl = 8
             div       cl              ; ah = (validRight mod 8)
             cmp       ah,0
             je        MargD_OK
             sub       cl,ah           ; cl = (cl-ah)
             shl       rightMask,cl
MargD_OK:
             mov       cx,1

ContinuaColonna:
             jmp       CopiaColonna

FineColonna:

; ***************************************************************************
; ***************************************************************************
; ***************************************************************************

             mov       dx,3C5h
             mov       al,15           ; seleziona la pagina 1
             out       dx,al

FineProc:
             pop       ds

             leave
             ret       RetBytes
DrawCharVideoDC ENDP



CODE         ENDS
             END































































































;COLOR_PROC 0, 0,0,0,0

;COLOR_PROC 1, 0,0,0,1

;COLOR_PROC 2, 0,0,1,0

;COLOR_PROC 3, 0,0,1,1

;COLOR_PROC 4, 0,1,0,0

;COLOR_PROC 5, 0,1,0,1

;COLOR_PROC 6, 0,1,1,0

;COLOR_PROC 7, 0,1,1,1

;COLOR_PROC 8, 1,0,0,0

;COLOR_PROC 9, 1,0,0,1

;COLOR_PROC 10, 1,0,1,0

;COLOR_PROC 11, 1,0,1,1

;COLOR_PROC 12, 1,1,0,0

;COLOR_PROC 13, 1,1,0,1

;COLOR_PROC 14, 1,1,1,0

;COLOR_PROC 15, 1,1,1,1









COLOR_PROC   MACRO  colore,c4,c3,c2,c1

Color&colore& PROC NEAR

.386
;----------------------------------------------------------------------------
; Prima Pagina
             push      OpCodeOR
             push      OpCodeAND

             TRACCIA_COLONNA_&c1&   _&colore&_1,1,0

             pop       OpCodeAND
             pop       OpCodeOR
;----------------------------------------------------------------------------
; Seconda Pagina
             push      OpCodeOR
             push      OpCodeAND

             TRACCIA_COLONNA_&c2&   _&colore&_2,2,1

             pop       OpCodeAND
             pop       OpCodeOR
;----------------------------------------------------------------------------
; Terza Pagina
             push      OpCodeOR
             push      OpCodeAND

             TRACCIA_COLONNA_&c3&   _&colore&_3,4,2

             pop       OpCodeAND
             pop       OpCodeOR
;----------------------------------------------------------------------------
; Quarta Pagina
             TRACCIA_COLONNA_&c4&   _&colore&_4,8,3
.286
             ret
             ENDP

             ENDM




TRACCIA_COLONNA_1  MACRO  pagina,SequData,GDC

             mov       BYTE PTR cs:&pagina&Ror_Par,bh
             mov       ax,OpCodeOR
             mov       WORD PTR cs:&pagina&OR_Par,ax

             push      cx
             push      di

             PAGINE_VIDEO SequData,GDC

             mov       si,PrecSI       ; Posiziona SI
&pagina&CopiaLinea:
             lodsb                     ; Legge la linea del font in AL

             and       al,leftMask     ; Clipping del margine sinistro
             cmp       al,0
             je        &pagina&Salto_Linea
             and       al,rightMask    ; Clipping del margine destro

             xor       ah,ah           ; Azzera AH

             db        0C1h,0C8h       ; opcode:  ROR AX,<n>; Effettua lo shifting
&pagina&Ror_Par:
             db        ?

;----------------------------------------------------------------------------
             db        26h             ; opcode:  AND o OR
&pagina&OR_Par:
                                       ; /9h,5h  =>  OR WORD PTR es:[di],ax
             dw        ?               ;<
                                       ; \8h,25h =>  OR BYTE PTR es:[di],ah
;----------------------------------------------------------------------------

&pagina&Salto_Linea:
             dec       cx
             cmp       cx,validDown
             jne       &pagina&SaltoNormale
             add       si,cx
             jmp       SHORT &pagina&FineLinea
&pagina&SaltoNormale:
             jcxz      &pagina&FineLinea
             add       di,SaltoDI
             jmp       &pagina&CopiaLinea

&pagina&FineLinea:
             mov       OpCodeOR,0509h

             pop       di
             pop       cx

             ENDM




TRACCIA_COLONNA_0  MACRO  pagina,SequData,GDC

             mov       BYTE PTR cs:&pagina&Ror_Par,bh
             mov       ax,OpCodeAND
             mov       WORD PTR cs:&pagina&AND_Par,ax

             push      cx
             push      di

             PAGINE_VIDEO SequData,GDC

             mov       si,PrecSI       ; Posiziona SI
&pagina&CopiaLinea:
             lodsb                     ; Legge la linea del font in AL

             and       al,leftMask     ; Clipping del margine sinistro
             cmp       al,0
             je        &pagina&Salto_Linea
             and       al,rightMask    ; Clipping del margine destro

             xor       ah,ah           ; Azzera AH

             db        0C1h,0C8h       ; opcode:  ROR AX,<n>; Effettua lo shifting
&pagina&Ror_Par:
             db        ?

;----------------------------------------------------------------------------
             not       ax
             db        26h             ; opcode:  AND o OR
&pagina&AND_Par:
                                       ; /21h,5h  =>  AND WORD PTR es:[di],ax
             dw        ?               ;<
                                       ; \20h,25h =>  AND BYTE PTR es:[di],ah
;----------------------------------------------------------------------------

&pagina&Salto_Linea:
             dec       cx
             cmp       cx,validDown
             jne       &pagina&SaltoNormale
             add       si,cx
             jmp       SHORT &pagina&FineLinea
&pagina&SaltoNormale:
             jcxz      &pagina&FineLinea
             add       di,SaltoDI
             jmp       &pagina&CopiaLinea

&pagina&FineLinea:
             mov       OpCodeAND,0521h

             pop       di
             pop       cx

             ENDM



