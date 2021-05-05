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



TRACCIA_LINEA  MACRO  pagina,SequData,GDC

             les       di,Tp&pagina&

;             mov       cx,di
;             shl       cx,1
;             jc        Prosegui_&pagina&

             cmp       ax,0
             je        Prosegui_&pagina&

             PAGINE_VIDEO SequData,GDC

             mov       ax,fs                 ; Carica in AX la linea del Font
             mov       bl,color
             shr       bl,pagina
             jnc       Not_And_&pagina&
Or_&pagina&:
             or        WORD PTR es:[di],ax   ; Scrive la linea nel DC
             jmp       SHORT Prosegui_&pagina&
Not_And_&pagina&:
             not       ax
             and       WORD PTR es:[di],ax   ; Scrive la linea nel DC
Prosegui_&pagina&:
;             mov       ax,ShortJumpDI
;             add       di,ax
;             mov       O_Tp&pagina&,di

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

             LOCAL     Tp1:DWORD,Tp2:DWORD,Tp3:DWORD,Tp4:DWORD,PrecO_Tp1,PrecO_Tp2,PrecO_Tp3,PrecO_Tp4,SaltoDI,ShortJumpDI,a_pos_x2,a_pos_x1,__cx,colonne:BYTE,colLeft:BYTE,rightMask:BYTE,leftMask:BYTE=VariabiliLocali
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
             mov       ax,a_pos_x1
             add       O_Tp1,ax
             add       O_Tp2,ax
             add       O_Tp3,ax
             add       O_Tp4,ax
             mov       PrecO_Tp1,ax
             mov       PrecO_Tp2,ax
             mov       PrecO_Tp3,ax
             mov       PrecO_Tp4,ax

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
             mov       cl,colonne
             xor       ch,ch

CopiaColonna:

             push      cx
             mov       cx,_Height_     ; cx = Numero di linee

; Clipping del margine superiore
             cmp       outUp,0FFFFh
             je        MargineSup_OK
             mov       ax,outUp
             add       si,ax
             sub       cx,ax
MargineSup_OK:

CopiaLinea:

             push      cx

             xor       ah,ah           ; Azzera AH
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

             TRACCIA_LINEA 1,1,0

;----------------------------------------------------------------------------
; Seconda Pagina

             TRACCIA_LINEA 2,2,1

;----------------------------------------------------------------------------
; Terza Pagina

             TRACCIA_LINEA 3,4,2

;----------------------------------------------------------------------------
; Quarta Pagina

             TRACCIA_LINEA 4,8,3

;----------------------------------------------------------------------------
; SALTO LINEA

             pop       cx
             cmp       validDown,0FFFFh
             je        SaltoNormale
             cmp       cx,validDown
             jne       SaltoNormale
             dec       cx
             add       si,cx
             jmp       SHORT FineLinea
SaltoNormale:
             dec       cx
             jcxz      FineLinea
             mov       ax,SaltoDI
             add       O_Tp1,ax
             add       O_Tp2,ax
             add       O_Tp3,ax
             add       O_Tp4,ax
             jmp       CopiaLinea

FineLinea:

;----------------------------------------------------------------------------
; CAMBIO COLONNA

             pop       cx
             dec       cx
             jcxz      FineColonna
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

             pop       ds

             mov       dx,3C5h
             mov       al,15           ; seleziona la pagina 1
             out       dx,al

             leave
             ret       RetBytes
DrawChar     ENDP


CODE         ENDS
             END