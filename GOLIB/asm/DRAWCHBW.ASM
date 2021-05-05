; by ERNESTO CIANCIOTTA (c) 1995

; /*********************************************************************
; \
; / Procedura di per il disegno di un carattere bitmapped formato Windows(TM).
; \ Questa procedura disegna direttamente sul Frame-Buffer.
; /
; \ Questa Š una versione che discende da DRAWCHVD.ASM ed Š modellata per i
; / casi in cui si debba scrivere i caratteri con un colore bianco su nero o
; \ nero su bianco.
; /
; \ VERSIONE DEFINITIVA  1.0.
; /
; \ N.B.: Solo per Intel 80386 e successivi.
; /
; \*********************************************************************

;------------------------ Definizione Dati ---------------------------------



DATA         SEGMENT WORD PUBLIC
             ASSUME ds:DATA

             EXTRN MaxXResolution:WORD

DATA         ENDS



;------------------------ Definizione Codice -------------------------------



CODE         SEGMENT BYTE PUBLIC
             ASSUME cs:CODE


DrawCharBW   PROC NEAR
             PUBLIC DrawCharBW
             ARG    index:DWORD, color:BYTE, adjustShift:BYTE, adjustFBPos:BYTE, validDown:WORD, outUp:WORD, validRight:WORD, outLeft:WORD, _Height_:WORD, _Width_:WORD, y:WORD, x:WORD= RetBytes

             LOCAL     OpCodeLogic,ClipSup,ColProc,PrecSI,PrecDI,SaltoDI,ShortJumpDI,a_pos_x2,a_pos_x1,__cx,colonne:BYTE,colLeft:BYTE,rightMask:BYTE,leftMask:BYTE=VariabiliLocali
.386
             enter     VariabiliLocali,0
             push      ds


; DETERMINAZIONE DEL PUNTATORE ALLA PROCEDURA DEL COLORE

; Selezione
;-------------------
             mov       al,color
ColorProc1:
             cmp       al,0
             jne       ColorProc15
       ;AND
             mov       WORD PTR cs:Mov1_Par,0521h
             mov       WORD PTR cs:Mov2_Par,2520h
             mov       WORD PTR cs:Mov3_Par,2520h
             mov       WORD PTR cs:Mov4_Par,0521h
             mov       WORD PTR cs:Not_OpCode,0D0F7h
             jmp       ColorProcOK
ColorProc15:
       ;OR
             mov       WORD PTR cs:Mov1_Par,0509h
             mov       WORD PTR cs:Mov2_Par,2508h
             mov       WORD PTR cs:Mov3_Par,2508h
             mov       WORD PTR cs:Mov4_Par,0509h
             mov       WORD PTR cs:Not_OpCode,9090h
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
             db        0C7h,46h,0FEh   ;MOV OpCodeLogic,<dw>   ;Normale
Mov1_Par:
             dw        ?
Controllo1:
             cmp       ax,0FFFEh
             jne       Controllo2
             db        0C7h,46h,0FEh   ;MOV OpCodeLogic,<dw>   ;Speciale
Mov2_Par:
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
             db        0C7h,46h,0FEh   ;MOV OpCodeLogic,<dw>   ;Speciale
Mov3_Par:
             dw        ?
             mov       di,0
IndirizzoOK:

             mov       dx,3C4h
             mov       al,2
             out       dx,al           ; seleziona il registro delle pagine attive
             inc       dx
             mov       al,15
             out       dx,al

             inc       SaltoDI
             cmp       bh,0
             je        Copia
             inc       SaltoDI

; **************************                       **************************
; ************************** Disegno del carattere **************************
; **************************                       **************************

Copia:
             mov       BYTE PTR cs:Ror_Par,bh

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

             mov       ax,OpCodeLogic
             mov       WORD PTR cs:Logic_Par,ax

             push      cx
             push      di

             mov       si,PrecSI       ; Posiziona SI
CopiaLinea:
             lodsb                     ; Legge la linea del font in AL

             and       al,leftMask     ; Clipping del margine sinistro
             cmp       al,0
             je        Salto_Linea
             and       al,rightMask    ; Clipping del margine destro

             xor       ah,ah           ; Azzera AH

             db        0C1h,0C8h       ; opcode:  ROR AX,<n>; Effettua lo shifting
Ror_Par:
             db        ?

;----------------------------------------------------------------------------
Not_Opcode:
             not       ax

             db        26h             ; opcode:  AND o OR
Logic_Par:
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

Salto_Linea:
             dec       cx
             cmp       cx,validDown
             jne       SaltoNormale
             add       si,cx
             jmp       SHORT FineLinea
SaltoNormale:
             jcxz      FineLinea
             add       di,SaltoDI
             jmp       CopiaLinea

FineLinea:
             db        0C7h,46h,0FEh   ;MOV OpCodeLogic,<dw>   ;Normale
Mov4_Par:
             dw        ?

             pop       di
             pop       cx

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
DrawCharBW   ENDP



CODE         ENDS
             END