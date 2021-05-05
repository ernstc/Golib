; by ERNESTO CIANCIOTTA (c) 1995

; /*********************************************************************
; \
; / Procedura di per il disegno di un carattere bitmapped formato Windows(TM)
; \ elementi delle linee da sinistra a destra.             ("L")
; /
; \ VERSIONE PROTOTIPO   1.0.
; /
; \ N.B.: Solo per Intel 80386 e successivi.
; /
; \*********************************************************************


;------------------------ Definizione Macro --------------------------------


PAGINE_VIDEO MACRO SequData,GDC

             mov       dx,3C5h
             mov       al,SequData
             out       dx,al
             mov       dx,3cfh
             mov       al,GDC
             out       dx,al

             ENDM



;------------------------ Definizione Strutture ----------------------------



HCA       STRUC
  piano1  DD  ?
  piano2  DD  ?
  piano3  DD  ?
  piano4  DD  ?
  DimXCA  DW  ?
  _DimX_  DW  ?
  _DimY_  DW  ?
HCA       ENDS



;------------------------ Definizione Dati ---------------------------------



DATA         SEGMENT WORD PUBLIC
             ASSUME ds:DATA

             EXTRN VideoDC:DWORD

DATA         ENDS



;------------------------ Definizione Codice -------------------------------



CODE         SEGMENT BYTE PUBLIC
             ASSUME cs:CODE

DrawChar     PROC NEAR
             PUBLIC DrawChar
             ARG    index:DWORD, color:BYTE, adjustShift:BYTE, adjustFBPos:BYTE, validDown:WORD, outUp:WORD, validRight:WORD, outLeft:WORD, _Height_:WORD, _Width_:WORD, y:WORD, x:WORD, ToDC:DWORD= RetBytes

; ToDC   = To Device Context

             LOCAL     Tp1:DWORD,Tp2:DWORD,Tp3:DWORD,Tp4:DWORD,PrecO_Tp1,PrecO_Tp2,PrecO_Tp3,PrecO_Tp4,SaltoDI,a_pos_x2,a_pos_x1,__cx,colonne:BYTE,colLeft:BYTE,rightMask:BYTE,leftMask:BYTE=VariabiliLocali
             LOCAL     S_Tp1,O_Tp1,S_Tp2,O_Tp2,S_Tp3,O_Tp3,S_Tp4,O_Tp4:WORD
.386
             enter     VariabiliLocali,0
             push      ds

; INIZIALIZZAZIONE DEI PUNATTORI NELLO STACK

             les       di,ToDC                        ; ES:DI <- ToDC
             mov       ebx,DWORD PTR es:[di.piano1]
             mov       Tp1,ebx
             mov       ebx,DWORD PTR es:[di.piano2]
             mov       Tp2,ebx
             mov       ebx,DWORD PTR es:[di.piano3]
             mov       Tp3,ebx
             mov       ebx,DWORD PTR es:[di.piano4]
             mov       Tp4,ebx


; PRIMA FASE DI INIZIALIZZAZIONE

;_Width_ = ((_Width_+7) div 8)*8
;             add       _Width_,7         ; approssima per eccesso a
;             and       _Width_,0FFF8h    ; un mulptiplo di 8

; a_pos_x1 = ( x div 8)+DimXCA*y
             mov       ax,x
             xor       dx,dx           ; dx = 0000h
             mov       cx,8
             div       cx              ; cx = 8
             push      ax
             mov       ax,es:[di.DimXCA] ; Carica in AX la larghezza del DC
             xor       dx,dx
             div       cx
             mov       cx,ax           ; CX <- HCA.DimXCA div 8
             mov       ax,y
             xor       dx,dx
             mul       cx              ; AX <- (y*bx)
             mov       bx,ax           ; BX <- (DimXCA div 8)*y
             pop       ax
             add       ax,bx
             mov       a_pos_x1,ax

; a_pos_x2 = [(x+7) div 8]+DimXCA*y
             mov       ax,x
             add       ax,7
             xor       dx,dx           ; dx = 0000h
             mov       cx,8
             div       cx              ; cx = 8
             add       ax,bx           ; bx = (DimXCA div 8)*y
             mov       a_pos_x2,ax

; __cx = a_pos_x2 - a_pos_x1 - 1
             mov       ax,a_pos_x2
             sub       ax,a_pos_x1
             dec       ax
             mov       __cx,ax

; SaltoDI = (ToDC.DimXCA div 8)-2-__cx
             mov       ax,es:[di.DimXCA]  ; In ES:DI c'Š ToDC
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
             add       bh,adjustShift  ; Corregge lo shift nel caso in cui
                                       ; la x fosse originariamente negativa
             dec       SaltoDI
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
             mov       dx,a_pos_x1
             xor       dh,dh
             mov       dl,adjustFBpos
             add       a_pos_x1,ax
             sub       a_pos_x1,dx
             mov       dx,a_pos_x1

             mov       cx,_Height_
             mul       cx              ; ax = (colLeft-1)*_Height_

; SI = SI + (colLeft-1)*_Height_
             add       si,ax

; Posizionamento degli OFFSETS dei puntatori alle pagine
             mov       ax,a_pos_x1
             add       O_Tp1,ax
             add       O_Tp2,ax
             add       O_Tp3,ax
             add       O_Tp4,ax
             mov       dx,O_Tp1
             mov       PrecO_Tp1,dx
             mov       dx,O_Tp2
             mov       PrecO_Tp2,dx
             mov       dx,O_Tp3
             mov       PrecO_Tp3,dx
             mov       dx,O_Tp4
             mov       PrecO_Tp4,dx

             mov       dx,3C4h
             mov       al,2
             out       dx,al           ; seleziona il registro delle pagine attive
             mov       dx,3CEh
             mov       al,4
             out       dx,al           ; seleziona il GDC index a 4

             cmp       bh,0
             jne       ConShifting
             jmp       SenzaShifting

; ***********************                      ******************************
; *********************** COPIA  CON  SHIFTING ******************************
; ***********************                      ******************************

ConShifting:
             mov       cl,colonne
             xor       ch,ch

CopiaColonnaConShift:

             push      cx
             mov       cx,_Height_     ; cx = Numero di linee

; Clipping del margine superiore
             cmp       outUp,0FFFFh
             je        CSMargineSup_OK
             mov       ax,outUp
             add       si,ax
             sub       cx,ax
CSMargineSup_OK:

CopiaLineaConShifting:

             push      cx

             xor       ax,ax           ; Azzera AX
             lodsb                     ; Legge la linea del font in AL
; Clipping del margine sinistro
             and       al,leftMask
; Clipping del margine destro
             and       al,rightMask
             mov       cl,bh           ; Carica in CL gli shifts da effettuare
             ror       ax,cl           ; Effettua lo shifting
             mov       fs,ax           ; Salva in FS la line del Font

;----------------------------------------------------------------------------
; Prima Pagina
             les       di,Tp1

             cmp       ax,0
             je        CSProsegui_1
             ;PAGINE_VIDEO 1,0

             mov       bl,color
             shr       bl,1
             mov       ax,fs                 ; Carica in AX la linea del Font
             jnc       CSNot_And_1
CSOr_1:
             or        WORD PTR es:[di],ax   ; Scrive la linea nel DC
             jmp       SHORT CSProsegui_1
CSNot_And_1:
             not       ax
             and       WORD PTR es:[di],ax   ; Scrive la linea nel DC
CSProsegui_1:
             inc       di
             inc       di
             mov       O_Tp1,di


;----------------------------------------------------------------------------
; SALTO LINEA

             pop       cx
             cmp       validDown,0FFFFh
             je        CSSaltoNormale
             cmp       cx,validDown
             jne       CSSaltoNormale
             dec       cx
             add       si,cx
             jmp       SHORT FineLineaConShift
CSSaltoNormale:
             dec       cx
             jcxz      FineLineaConShift
             mov       ax,SaltoDI
             add       O_Tp1,ax
             add       O_Tp2,ax
             add       O_Tp3,ax
             add       O_Tp4,ax
             jmp       CopiaLineaConShifting

FineLineaConShift:

;----------------------------------------------------------------------------
; CAMBIO COLONNA

             pop       cx
             dec       cx
             jcxz      FineColonnaConShift
             inc       PrecO_Tp1
             mov       ax,PrecO_Tp1
             mov       O_Tp1,ax
             inc       PrecO_Tp2
             mov       ax,PrecO_Tp2
             mov       O_Tp2,ax
             inc       PrecO_Tp3
             mov       ax,PrecO_Tp3
             mov       O_Tp3,ax
             inc       PrecO_Tp4
             mov       ax,PrecO_Tp4
             mov       O_Tp4,ax
             mov       leftMask,0FFh
             cmp       cx,1
             jne       ContinuaColonnaConShift

; Preparazione per il clipping del margine destro
             mov       ax,_Width_
             cmp       validRight,ax
             je        ContinuaColonnaConShift
; rightMask = 0FFh shl (8-(validRight mod 8))
             mov       ax,validRight
             mov       cl,8            ; cl = 8
             div       cl              ; ah = (validRight mod 8)
             cmp       ah,0
             je        CS_MargD_OK
             sub       cl,ah           ; cl = (cl-ah)
             shl       rightMask,cl
CS_MargD_OK:
             mov       cx,1

ContinuaColonnaConShift:
             jmp       CopiaColonnaConShift

FineColonnaConShift:

             jmp       FuoriLoop



; ***********************                      ******************************
; *********************** COPIA SENZA SHIFTING ******************************
; ***********************                      ******************************

SenzaShifting:
             mov       cl,colonne
             xor       ch,ch

CopiaColonnaSenzaShift:

             push      cx
             mov       cx,_Height_     ; cx = Numero di linee

; Clipping del margine superiore
             cmp       outUp,0FFFFh
             je        SSMargineSup_OK
             mov       ax,outUp
             add       si,ax
             sub       cx,ax
SSMargineSup_OK:

CopiaLineaSenzaShifting:

             xor       ax,ax           ; Azzera AX
             lodsb                     ; Legge la linea del font in AL
; Clipping del margine sinistro
             and       al,leftMask
; Clipping del margine destro
             mov       bl,rightMask
             and       al,rightMask
             mov       fs,ax           ; Salva in FS la linea del Font

;----------------------------------------------------------------------------
; Prima Pagina
             les       di,Tp1

             cmp       al,0
             je        SSProsegui_1
             ;PAGINE_VIDEO 1,0

             mov       bl,color
             shr       bl,1
             mov       ax,fs           ; Carica in AX la linea del Font
             jnc       SSNot_And_1
SSOr_1:
             or        BYTE PTR es:[di],al   ; Scrive la linea nel DC
             jmp       SHORT SSProsegui_1
SSNot_And_1:
             not       al
             and       BYTE PTR es:[di],al   ; Scrive la linea nel DC
SSProsegui_1:
             inc       di
             mov       O_Tp1,di

;----------------------------------------------------------------------------
; SALTO LINEA

             cmp       validDown,0FFFFh
             je        SSSaltoNormale
             cmp       cx,validDown
             jne       SSSaltoNormale
             dec       cx
             add       si,cx
             jmp       SHORT FineLineaSenzaShift
SSSaltoNormale:
             dec       cx
             jcxz      FineLineaSenzaShift
             mov       ax,SaltoDI
             add       O_Tp1,ax
             add       O_Tp2,ax
             add       O_Tp3,ax
             add       O_Tp4,ax
             jmp       CopiaLineaSenzaShifting

FineLineaSenzaShift:

;----------------------------------------------------------------------------
; CAMBIO COLONNA

             pop       cx
             dec       cx
             jcxz      FineColonnaSenzaShift
             inc       PrecO_Tp1
             mov       ax,PrecO_Tp1
             mov       O_Tp1,ax
             inc       PrecO_Tp2
             mov       ax,PrecO_Tp2
             mov       O_Tp2,ax
             inc       PrecO_Tp3
             mov       ax,PrecO_Tp3
             mov       O_Tp3,ax
             inc       PrecO_Tp4
             mov       ax,PrecO_Tp4
             mov       O_Tp4,ax
             mov       leftMask,0FFh
             cmp       cx,1
             jne       ContinuaColonnaSenzaShift

; Preparazione per il clipping del margine destro
             mov       ax,_Width_
             cmp       validRight,ax
             je        ContinuaColonnaSenzaShift
; rightMask = 0FFh shl (8-(validRight mod 8))
             mov       ax,validRight
             mov       cl,8            ; cl = 8
             div       cl              ; ah = (validRight mod 8)
             cmp       ah,0
             je        SS_MargD_OK
             sub       cl,ah           ; cl = (cl-ah)
             shl       rightMask,cl
SS_MargD_OK:
             mov       cx,1

ContinuaColonnaSenzaShift:

             jmp       CopiaColonnaSenzaShift

FineColonnaSenzaShift:

             jmp       FuoriLoop


;----------------------------------------------------------------------------
FuoriLoop:
             pop       ds

             mov       dx,3C5h
             mov       al,15           ; seleziona la pagina 1
             out       dx,al

             leave
             ret       RetBytes
DrawChar     ENDP


CODE         ENDS
             END