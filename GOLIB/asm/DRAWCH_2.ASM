; by ERNESTO CIANCIOTTA (c) 1995

; /*********************************************************************
; \
; / Procedura di per il disegno di un carattere bitmapped formato Windows(TM).
; \ Questa procedura disegna direttamente sul Frame-Buffer.
; /
; \ VERSIONE 2.0 (Ultima revisione 1/4/96)
; /
; \ Solo per la modalit… grafica a 16 colori.
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

; Prototipi in PASCAL:
;
;   procedure DrawCharVideoDC(x,             y:integer;
;                             Width,         Height:word;
;                             outLeft,       validRight,
;                             outUp,         validDown:word;
;                             adjustFBPos,   adjustShift:byte;
;                             index:pointer);
;
;   procedure Imposta_Registri(WriteMode,color:byte);
;
;   procedure Ripristina_Registri;


             PUBLIC DrawCharVideoDC
             PUBLIC Imposta_Registri
             PUBLIC Ripristina_Registri



DrawCharVideoDC     PROC NEAR
             ARG    index:DWORD, adjustShift:BYTE, adjustFBPos:BYTE, validDown:WORD, outUp:WORD, validRight:WORD, outLeft:WORD, _Height_:WORD, _Width_:WORD, y:WORD, x:WORD= RetBytes

             LOCAL     word_mode:BYTE, ClipSup,PrecDI,SaltoDI,a_pos_x2,a_pos_x1,__cx,colonne:BYTE,colLeft:BYTE,rightMask:BYTE,leftMask:BYTE=VariabiliLocali
.386
             enter     VariabiliLocali,0
             push      ds

; PRIMA FASE DI INIZIALIZZAZIONE

;_Width_ = ((_Width_+7) div 8)*8
;             add       _Width_,7        ; approssima per eccesso a
;             and       _Width_,0FFF8h   ; un mulptiplo di 8

; a_pos_x1 = ( x div 8)+(MaxXResolution div 8)*y
             mov       ax,x
             shr       ax,3              ; ax <- ax div 8
             push      ax
             mov       cx,MaxXResolution ; Carica in AX la larghezza del DC
             shr       cx,3              ; CX <- MaxXResolution div 8
             mov       ax,y
             xor       dx,dx
             mul       cx                ; AX <- (y*bx)
             mov       bx,ax             ; BX <- (MaxXResolution div 8)*y
             pop       ax
             add       ax,bx
             mov       a_pos_x1,ax

; a_pos_x2 = [(x+7) div 8]+(MaxXResolution div 8)*y
             mov       ax,x
             add       ax,7
             shr       ax,3              ; ax <- ax div 8
             add       ax,bx             ; bx = (MaxXResolution div 8)*y
             mov       a_pos_x2,ax

; __cx = a_pos_x2 - a_pos_x1 - 1
             mov       ax,a_pos_x2
             sub       ax,a_pos_x1
             dec       ax
             mov       __cx,ax

; SaltoDI = (MaxXResolution div 8)-2-__cx
             mov       bx,MaxXResolution
             shr       bx,3               ; AX <- AX div 8
             sub       bx,ax              ; BX <- BX - __cx
             dec       bx
             dec       bx
             mov       SaltoDI,bx


; SECONDA FASE DI INIZIALIZZAZIONE

; preparazione shifts verso destra da applicare al font
             mov       ax,x
             mov       cl,8
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
             push      0A000h
             pop       es
             mov       ax,a_pos_x1
             mov       di,ax
             mov       PrecDI,di
             mov       word_mode,1
Controllo1:
             cmp       ax,0FFFEh
             jne       Controllo2
             mov       word_mode,0
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
             mov       word_mode,0
             mov       di,0
IndirizzoOK:
             mov       dx,03CFh       ; Imposta DX in modo da poter puntare
                                      ; sulla porta dati GDC data

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

;----------------------------------------------------------------------------
; TRACCIA COLONNA

             mov       BYTE PTR cs:Ror_Par,bh


             mov       al,leftmask
             mov       al,rightmask

CopiaLinea:
             lodsb                     ; Legge la linea del font in AL

             and       al,leftMask     ; Clipping del margine sinistro
             or        al,al
             jz        Salto_Linea
             and       al,rightMask    ; Clipping del margine destro

             xor       ah,ah           ; Azzera AH

             db        0C1h,0C8h       ; opcode:  ROR AX,<n>; Effettua lo shifting
Ror_Par:
             db        ?

             ; premesso che il GDC index punti al Bit Mask Register
             ; e che DX sia uguale a 03CFh

             out       dx,al
             mov       al,es:[di]      ; dummy instruction per aggiornare il
                                       ; registro chiave a 32 bit della VGA
             mov       es:[di],al

             cmp       word_mode,0
             jz        Salto_Linea
             inc       di
             mov       al,es:[di]      ; dummy instruction per aggiornare il
                                       ; registro chiave a 32 bit della VGA
             mov       al,ah
             out       dx,al

             mov       es:[di],al
             dec       di

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

FineProc:
             pop       ds

             leave
             ret       RetBytes
DrawCharVideoDC ENDP




Imposta_Registri     PROC NEAR
             ARG    color:BYTE, WriteMode:BYTE = RetBytes_2
             enter     0,0

             mov       dx,03C4h
             mov       al,0Fh
             out       dx,al                ; attiva tutte le pagine

             mov       dx,03CEh
             xor       al,al
             out       dx,al                ; seleziona il Set/Reset Reg.

             inc       dx
             mov       al,color
             out       dx,al                ; imposta il Set/Reset Reg.

             dec       dx
             mov       al,1
             out       dx,al                ; seleziona l'Enable Set/Reset Reg.

             inc       dx
             mov       al,0Fh
             out       dx,al                ; imposta l'Enable Set/Reset Reg.

             dec       dx
             mov       al,3
             out       dx,al                ; seleziona il Data Rotate Reg.

             inc       dx
             mov       al,WriteMode
             and       al,18h
             out       dx,al                ; imposta la modalit… logica di scrittura
                                            ; nel Data Rotate Reg.
             dec       dx
             mov       al,8
             out       dx,al                ; seleziona il Bit Mask Reg.

             leave
             ret       RetBytes_2
Imposta_Registri     ENDP



Ripristina_Registri     PROC NEAR
             mov       dx,03CEh
             mov       al,1
             out       dx,al                ; seleziona l'Enable Set/Reset Reg.

             inc       dx
             xor       al,al
             out       dx,al                ; disattiva il Set/Reset Reg. azzerando
                                            ; l'Enable Set/Reset Reg.
             dec       dx
             mov       al,8
             out       dx,al                ; seleziona il Bit Mask Reg.

             inc       dx
             mov       al,0FFh
             out       dx,al                ; imposta il Bit Mask Reg.

             dec       dx
             mov       al,3
             out       dx,al                ; seleziona il Data Rotate Reg.

             inc       dx
             xor       al,al
             out       dx,al                ; imposta la modalit… logica di scrittura
                                            ; a normale.
             ret
Ripristina_Registri     ENDP

CODE         ENDS
             END