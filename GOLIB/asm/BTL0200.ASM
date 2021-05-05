; by ERNESTO CIANCIOTTA (c) 1995

; /*********************************************************************
; \
; / Procedura di Bit Block Transfer.
; \
; / Tipo di trasferimento:
; \                       FRAME-BUFFER  ->  FRAME-BUFFER
; /                       SYSTEM        ->  FRAME-BUFFER
; \
; /  con utilizzo del buffer XZone
; \
; /
; \ VERSIONE PROTOTIPO   2.0.
; /
; \ N.B.: Solo per Intel 80386 e successivi.
; /
; \*********************************************************************

;---- INCLUSIONE FILES ------------------------------------------------------


INCLUDE .\register.inc


;------------------------ Definizione Macro --------------------------------


COPIA_LINEA_SHIFT MACRO pagina,SequData,GDC

             SetSequData  SequData
             SetGraphData GDC

             cmp       shift_left,0
             jz        _&pagina&_Destra

             lodsd
             xchg      ah,al
             rol       eax,16
             xchg      ah,al
             mov       edx,eax
             jmp       SHORT _&pagina&Continua

_&pagina&_Destra:
             add       si,4

_&pagina&Continua:

             mov       cx,steps
_&pagina&ContinuaCentro:
             lodsd

             xchg      ah,al
             rol       eax,16
             xchg      ah,al

             db        66h,0C1h,0E2h            ; shl       edx,<n1>
_&pagina&_par_004:
             db        ?

             db        66h,0C1h,0E8h            ; shr       eax,<n2>
_&pagina&_par_005:
             db        ?

             or        eax,edx
             mov       edx,ds:[si-4]

             xchg      ah,al
             rol       eax,16
             xchg      ah,al

             stosd
             loopw     _&pagina&ContinuaCentro

             ENDM       ; Fine Macro COPIA_LINEA_SHIFT




CAPI_LINEA_NON_SHIFT MACRO pagina,SequData,GDC

             SetSequData  SequData
             SetGraphData GDC

             push      si
             push      di

             mov       cx,BackSteps

             dec       cx

             jnz       _&pagina&Continua1

             mov       bl,mask_left
             and       bl,mask_right

             SetGraphReg 8,bl            ; Setta il Bit Mask Register

             jmp       SHORT _&pagina&Continua3

_&pagina&Continua1:
             SetGraphReg 8,mask_left     ; Setta il Bit Mask Register
             lodsb                       ; carica AL
             mov       ah,es:[di]        ; dummy instruction
             stosb                       ; scrittura elemento

             dec       cx

             add       si,cx             ; posiziona sull'ultimo a destra
             add       di,cx             ; posiziona sull'ultimo a destra

             mov       al,mask_right
             out       dx,al             ; Setta il Bit Mask Register

_&pagina&Continua3:
             lodsb                       ; carica AL
             mov       ah,es:[di]        ; dummy instruction
             stosb                       ; scrittura elemento

             pop       di
             pop       si

             ENDM       ; Fine Macro CAPI_LINEA_NON_SHIFT

;------------------------ Definizione Strutture ----------------------------



HCA       STRUC
  piano1  DD  ?
  piano2  DD  ?
  piano3  DD  ?
  piano4  DD  ?
  _DimX_  DW  ?
  _DimY_  DW  ?
  tipo    DB  ?
HCA       ENDS

;------------------------ Definizione Dati ---------------------------------



DATA         SEGMENT WORD PUBLIC
             ASSUME ds:DATA

             EXTRN Video_DC_2  : HCA
             EXTRN XZone : DWORD

DATA         ENDS



;------------------------ Definizione Codice -------------------------------



CODE         SEGMENT BYTE PUBLIC
             ASSUME cs:CODE

BitBtl_0200  PROC FAR
             PUBLIC BitBtl_0200

             ARG    DimY, DimX, a_y1_, a_x1_, da_y1_, da_x1_:WORD,ToDC:DWORD,FromDC:DWORD= RetBytes

; ToDC   = To Device Context
; FromDC = From Device Context

             LOCAL     Tp1:DWORD,Tp2:DWORD,Tp3:DWORD,Tp4:DWORD,Fp1:DWORD,Fp2:DWORD,Fp3:DWORD,Fp4:DWORD,XZonePTR:DWORD,SaltoDI,SaltoSI,sorg_OFS_x2,dest_OFS_x2,sorg_OFS_x1,dest_OFS_x1,steps,BackSteps,mask_left:BYTE,mask_right:BYTE,shift_left:BYTE=VariabiliLocali

             LOCAL     S_Tp1,O_Tp1,S_Tp2,O_Tp2,S_Tp3,O_Tp3,S_Tp4,O_Tp4,S_Fp1,O_Fp1,S_Fp2,O_Fp2,S_Fp3,O_Fp3,S_Fp4,O_Fp4:WORD
.386
             enter     VariabiliLocali,0
             push      ds

; INIZIALIZZAZIONE DEI PUNATTORI NELLO STACK
             mov       ebx,XZone
             mov       XZonePTR,ebx

             lds       si,FromDC                      ; DS:SI <- FromDC
             mov       ebx,DWORD PTR ds:[si.piano1]
             mov       Fp1,ebx
             mov       ebx,DWORD PTR ds:[si.piano2]
             mov       Fp2,ebx
             mov       ebx,DWORD PTR ds:[si.piano3]
             mov       Fp3,ebx
             mov       ebx,DWORD PTR ds:[si.piano4]
             mov       Fp4,ebx

             les       di,ToDC
             mov       ebx,DWORD PTR es:[di.piano1]
             mov       Tp1,ebx
             mov       ebx,DWORD PTR es:[di.piano2]
             mov       Tp2,ebx
             mov       ebx,DWORD PTR es:[di.piano3]
             mov       Tp3,ebx
             mov       ebx,DWORD PTR es:[di.piano4]
             mov       Tp4,ebx


; PRIMA FASE DI INIZIALIZZAZIONE

; dest_OFS_x1 = ( a_x1_ div 8)+(_DimX_ div 8)*a_y1_
             mov       bx,a_x1_
             shr       bx,3            ; BX <- a_x1_ div 8
             mov       cx,es:[di._DimX_] ; Carica in AX la larghezza del DC
             shr       cx,3            ; CX <- _DimX_ div 8
             mov       ax,a_y1_
             xor       dx,dx
             mul       cx              ; AX <- (_DimX_ div 8)*a_y1_
             mov       dx,ax           ; DX <- (_DimX_ div 8)*a_y1_
             add       ax,bx
             mov       dest_OFS_x1,ax


; dest_OFS_x2 = [(a_x1_+DimX-1) div 8]+(_DimX_ div 8)*a_y1_
             mov       ax,a_x1_
             add       ax,DimX
             dec       ax              ; ax = a_x1_+DimX-1
             shr       ax,3
             add       ax,dx           ; dx = (_DimX_ div 8)*a_y1_
             mov       dest_OFS_x2,ax


; sorg_OFS_x1 = ( da_x1_ div 8)+(_DimX_ div 8)*da_y1_
             mov       bx,da_x1_
             shr       bx,3            ; BX <- ( da_x1_ div 8)
             mov       cx,ds:[si._DimX_] ; Carica in AX la larghezza del DC
             shr       cx,3            ; CX <- _DimX_ div 8
             mov       ax,da_y1_
             xor       dx,dx
             mul       cx              ; AX <- (_DimX_ div 8)*da_y1_
             mov       dx,ax           ; DX <- (_DimX_ div 8)*da_y1_
             add       ax,bx
             mov       sorg_OFS_x1,ax


; sorg_OFS_x2 = [(da_x1_+DimX-1) div 8]+(_DimX_ div 8)*da_y1_
             mov       ax,da_x1_
             add       ax,DimX
             dec       ax              ; ax = a_x1_+DimX-1
             shr       ax,3
             add       ax,dx           ; dx = (_DimX_ div 8)*da_y1_
             mov       sorg_OFS_x2,ax


; steps = (dest_OFS_x2 - dest_OFS_x1 + 1 + 4 - 1) div 4
             mov       ax,dest_OFS_x2
             sub       ax,dest_OFS_x1
             add       ax,4
             shr       ax,2
             mov       steps,ax

; BackSteps = dest_OFS_x2 - dest_OFS_x1 + 1
             mov       ax,dest_OFS_x2
             sub       ax,dest_OFS_x1
             inc       ax
             mov       BackSteps,ax

; SaltoSI = (FromDC._DimX_ div 8)
             mov       ax,ds:[si._DimX_]
             shr       ax,3
             ;dec       ax
             mov       SaltoSI,ax

; SaltoDI = (ToDC._DimX_ div 8)
             mov       ax,es:[di._DimX_]
             shr       ax,3
             ;dec       ax
             mov       SaltoDI,ax


; preparazione shifts per la parte centrale della linea
             mov       ax,da_x1_
             and       ax,001Fh
             mov       bh,al              ; bh = da_x1_ mod 32

             mov       ax,a_x1_
             and       ax,001Fh
             sub       bh,al              ; bh = bh - (a_x1_ mod 32)

             mov       shift_left,1       ; shift_left = TRUE
             jns       _EndIF_
             mov       shift_left,0       ; shift_left = FALSE
             xor       bh,0FEh            ; bh = - bh
_EndIF_:
             mov       bl,32
             sub       bl,bh              ; bl = 32 - bh

             ; bh = shifts verso sinistra
             ; bl = shifts verso destra

; preparazione delle maschere

             mov       cx,a_x1_
             and       cx,0007h           ; cl = a_x1_ mod 8
             mov       al,0FFh
             shr       al,cl
             mov       mask_left,al

             mov       ax,a_x1_
             add       ax,DimX
             and       ax,0007h           ; al = (a_x1_ + DimX) mod 8
             mov       cl,8
             sub       cl,al              ; cl = 8 - (a_x1_ + DimX) mod 8
             mov       al,0FFh
             shl       al,cl
             mov       mask_right,al

; PROCESSO DI COPIA DELLE PAGINE VIDEO
             cld                       ; direzione diretta

; Posizionamento degli OFFSETS dei puntatori alle pagine
             mov       ax,sorg_OFS_x1
             add       O_Fp1,ax
             add       O_Fp2,ax
             add       O_Fp3,ax
             add       O_Fp4,ax

             mov       ax,dest_OFS_x1
             add       O_Tp1,ax

             mov       cx,DimY


; Impostazione registri video

             cmp       bh,0
             jne       ConShifting

             ;jmp       SenzaShifting
             jmp       FuoriLoop

; ***********************                      ******************************
; *********************** COPIA  CON  SHIFTING ******************************
; ***********************                      ******************************


ConShifting:

; Auto-parametrizzazione del codice
             mov       BYTE PTR cs:_1_par_004,bh
             mov       BYTE PTR cs:_1_par_005,bl
             mov       BYTE PTR cs:_2_par_004,bh
             mov       BYTE PTR cs:_2_par_005,bl
             mov       BYTE PTR cs:_3_par_004,bh
             mov       BYTE PTR cs:_3_par_005,bl
             mov       BYTE PTR cs:_4_par_004,bh
             mov       BYTE PTR cs:_4_par_005,bl

InizioLinea:
             SetSequAddress  2
             SetGraphAddress 4

             push      cx

;========================
; SPOSTAMENTO VERSO XZone

;----------------------------------------------------------------------------
; Prima Pagina
             lds       si,Fp1
             les       di,XZonePTR

             COPIA_LINEA_SHIFT 1,1,0

             ;mov       O_Fp1,si
;----------------------------------------------------------------------------
; Seconda Pagina
             lds       si,Fp2
             les       di,XZonePTR

             COPIA_LINEA_SHIFT 2,2,1

             ;mov       O_Fp2,si
;----------------------------------------------------------------------------
; Terza Pagina
             lds       si,Fp3
             les       di,XZonePTR

             COPIA_LINEA_SHIFT 3,4,2

             ;mov       O_Fp3,si
;----------------------------------------------------------------------------
; Quarta Pagina
             lds       si,Fp4
             les       di,XZonePTR

             COPIA_LINEA_SHIFT 4,8,3

             ;mov       O_Fp4,si


;=====================================
; SPOSTAMENTO DA XZone AL FRAME-BUFFER

             lds       si,XZonePTR
             les       di,Tp1

;----------------------------------------------------------------------------
; Prima Pagina

             CAPI_LINEA_NON_SHIFT 1,1,0

;----------------------------------------------------------------------------
; Seconda Pagina

             CAPI_LINEA_NON_SHIFT 2,2,1

;----------------------------------------------------------------------------
; Terza Pagina

             CAPI_LINEA_NON_SHIFT 3,4,2

;----------------------------------------------------------------------------
; Quarta Pagina

             CAPI_LINEA_NON_SHIFT 4,8,3

;----------------------------------------------------------------------------
             SetGraphReg  8,0FFh         ; Setta il Bit Mask Register
             SetSequData  0Fh            ; seleziona tutte le pagine

             mov       cx,BackSteps

             dec       cx
             jz        FineLineaNS

             dec       cx
             jz        FineLineaNS

             inc       si
             inc       di

             SetGraphReg 5,1             ; Setta la modalit… di scrittura

             rep       movsb             ; copia parte centrale

FineLineaNS:

             ;inc       di

             ;mov       O_Tp1,di

;----------------------------------------------------------------------------
; SALTO LINEA
             mov       ax,SaltoDI
             add       O_Tp1,ax

             mov       ax,SaltoSI
             add       O_Fp1,ax
             add       O_Fp2,ax
             add       O_Fp3,ax
             add       O_Fp4,ax

             pop       cx
             dec       cx
             jcxz      FuoriLoop
             jmp       InizioLinea


FuoriLoop:


             leave
             ret       RetBytes
BitBtl_0200  ENDP


CODE         ENDS
             END