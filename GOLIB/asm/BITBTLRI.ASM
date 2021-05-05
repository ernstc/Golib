; by ERNESTO CIANCIOTTA (c) 1995

; /*********************************************************************
; \
; / Procedura di Bit Block Transfer con copia orizzontale inversa
; \ degli elementi delle linee (da destra a sinistra).
; /
; \ La copia delle linee avviene dal basso verso l'alto. ("I"ndiretta)
; /
; \ VERSIONE DEFINITIVA   1.0.
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



COPIA_LINEA_SHIFT MACRO pagina,SequData,GDC

; Sistemazione Registri
             PAGINE_VIDEO SequData,GDC

; Sistemazione dell'ultimo elemento
             cmp       discost,1
             je        _&pagina&Metodo_2
             cmp       discost,2
             je        _&pagina&Metodo_2
             cmp       discost,6
             je        _&pagina&Metodo_2
_&pagina&Metodo_1:
             lodsb                     ; al = BYTE PTR ds:[si] /-/ si = si-1
             mov       dh,al
             lodsb                     ; al = BYTE PTR ds:[si] /-/ si = si-1
             mov       dl,al
             mov       cl,bh
             shr       dh,cl
             mov       cl,bl
             shl       al,cl
             or        dh,al
             and       dh,mask2        ; prepara dl
             mov       cl,_mask2
             and       BYTE PTR es:[di],cl   ; prepara BYTE PTR es:[di]
             or        BYTE PTR es:[di],dh   ; sistema l'elemento
             cmp       discost,3
             je        _FinePagina&pagina&
             jmp       _&pagina&RestoLinea
_&pagina&Metodo_2:
             lodsb
             mov       dl,al
             mov       cl,bl
             shl       al,cl
             and       al,mask2
             mov       cl,_mask2
             and       BYTE PTR es:[di],cl   ; prepara BYTE PTR es:[di]
             or        BYTE PTR es:[di],al
             cmp       discost,6
             je        _FinePagina&pagina&
_&pagina&RestoLinea:
             dec       di

; Sistemazione degli elementi del centro della linea
             mov       cx,__cx
             jcxz      _&pagina&PrimoElemento
_&pagina&ContinuaCentro:
             lodsb
             mov       dh,al
             db        192,234         ; opcode di SHR DL,<n> che sar…
_&pagina&_par_004:
             db        0               ; uguale a bh
             db        192,224         ; opcode di SHL AL,<n> che sar…
_&pagina&_par_005:
             db        0               ; uguale a bl
             or        al,dl
             mov       dl,dh
             stosb                     ; BYTE PTR es:[di] = al
             loopw     _&pagina&ContinuaCentro

; Sistemazione del primo elemento

_&pagina&PrimoElemento:
             cmp       discost,0FFFFh  ; 0FFFFh = -1
             je        _&pagina&_Metodo_2
             cmp       discost,2
             je        _&pagina&_Metodo_2
_&pagina&_Metodo_1:
             mov       cl,bh
             shr       dl,cl
             jmp       SHORT _&pagina&_Dopo_Shift
_&pagina&_Metodo_2:
             lodsb
             mov       cl,bh
             shr       dl,cl
             mov       cl,bl
             shl       al,cl
             or        dl,al
_&pagina&_Dopo_Shift:
             and       dl,mask1
             mov       cl,_mask1
             and       BYTE PTR es:[di],cl
             or        BYTE PTR es:[di],dl

_FinePagina&pagina&:

            ENDM       ; Fine Macro COPIA_LINEA




COPIA_LINEA_NSHIFT MACRO pagina,SequData,GDC

; Sistemazione Registri
             PAGINE_VIDEO SequData,GDC

; Sistemazione dell'ultimo elemento
             lodsb
             db        36              ; opcode di AND AL,<n>
___&pagina&_par_001:
             db        0
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
___&pagina&_par_002:
             db        0
             or        BYTE PTR es:[di],al   ; sistema l'elemento
             cmp       discost,3
             je        __&pagina&_FineLinea
             dec       di

; Sistemazione degli elementi del centro della linea
             mov       cx,__cx
             jcxz      __&pagina&_PrimoElemento
             rep       movsb

__&pagina&_PrimoElemento:

; Sistemazione del primo elemento
             lodsb
             db        36              ; opcode di AND AL,<n>
___&pagina&_par_003:
             db        0
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
___&pagina&_par_004:
             db        0
             or        BYTE PTR es:[di],al

__&pagina&_FineLinea:

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

BitBtl_RI    PROC NEAR
             PUBLIC BitBtl_RI
             ARG    DimY, DimX, a_y1_, a_x1_, da_y1_, da_x1_:WORD,ToDC:DWORD,FromDC:DWORD= RetBytes
; ToDC   = To Device Context
; FromDC = From Device Context

             LOCAL     Tp1:DWORD,Tp2:DWORD,Tp3:DWORD,Tp4:DWORD,Fp1:DWORD,Fp2:DWORD,Fp3:DWORD,Fp4:DWORD,SaltoDI,SaltoSI,discost,da_pos_x2,a_pos_x2,da_pos_x1,a_pos_x1,__cx,mask1:BYTE,_mask1:BYTE,mask2:BYTE,_mask2:BYTE,__bh:BYTE,__bl:BYTE=VariabiliLocali
             LOCAL     S_Tp1,O_Tp1,S_Tp2,O_Tp2,S_Tp3,O_Tp3,S_Tp4,O_Tp4,S_Fp1,O_Fp1,S_Fp2,O_Fp2,S_Fp3,O_Fp3,S_Fp4,O_Fp4:WORD
.386
             enter     VariabiliLocali,0
             push      ds

; INIZIALIZZAZIONE DEI PUNATTORI NELLO STACK
             lds       si,FromDC                      ; DS:SI <- FromDC
             mov       ebx,DWORD PTR ds:[si.piano1]
             mov       Fp1,ebx
             mov       ebx,DWORD PTR ds:[si.piano2]
             mov       Fp2,ebx
             mov       ebx,DWORD PTR ds:[si.piano3]
             mov       Fp3,ebx
             mov       ebx,DWORD PTR ds:[si.piano4]
             mov       Fp4,ebx

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

; a_pos_x1 = ( a_x1_ div 8)+DimXCA*a_y1_
             mov       ax,a_x1_
             xor       dx,dx           ; dx = 0000h
             mov       cx,8
             div       cx              ; cx = 8
             push      ax
             mov       ax,es:[di.DimXCA] ; Carica in AX la larghezza del DC
             xor       dx,dx
             div       cx
             mov       cx,ax           ; CX <- HCA.DimXCA div 8
             mov       ax,a_y1_
             xor       dx,dx
             mul       cx              ; AX <- (a_y1_*bx)
             mov       bx,ax           ; BX <- (DimXCA div 8)*a_y1_
             pop       ax
             add       ax,bx
             mov       a_pos_x1,ax

; a_pos_x2 = [(a_x1_+DimX-1) div 8]+DimXCA*a_y1_
             mov       ax,a_x1_
             add       ax,DimX
             dec       ax              ; ax = a_x1_+DimX-1
             xor       dx,dx           ; dx = 0000h
             mov       cx,8
             div       cx              ; cx = 8
             add       ax,bx           ; bx = (DimXCA div 8)*a_y1_
             mov       a_pos_x2,ax


; da_pos_x1 = ( da_x1_ div 8)+DimXCA*da_y1_
             mov       ax,da_x1_
             xor       dx,dx           ; dx = 0000h
             mov       cx,8
             div       cx              ; cx = 8
             push      ax
             mov       ax,ds:[si.DimXCA] ; Carica in AX la larghezza del DC
             xor       dx,dx
             div       cx
             mov       cx,ax           ; CX <- HCA.DimXCA div 8
             mov       ax,da_y1_
             xor       dx,dx
             mul       cx              ; AX <- (da_y1_*bx)
             mov       bx,ax           ; BX <- (DimXCA div 8)*da_y1_
             pop       ax
             add       ax,bx
             mov       da_pos_x1,ax

; da_pos_x2 = [(da_x1_+DimX-1) div 8]+DimXCA*da_y1_
             mov       ax,da_x1_
             add       ax,DimX
             dec       ax              ; ax = da_x1_+DimX-1
             xor       dx,dx           ; dx = 0000h
             mov       cx,8
             div       cx              ; cx = 8
             add       ax,bx           ; bx = (DimXCA div 8)*da_y1_
             mov       da_pos_x2,ax


; discost = (a_pos_x2-a_pos_x1) - (da_pos_x2-da_pos_x1)
             mov       ax,a_pos_x2
             sub       ax,a_pos_x1
             add       ax,da_pos_x1
             sub       ax,da_pos_x2
             mov       discost,ax

; __cx = da_pos_x2 - da_pos_x1 - 1
             mov       ax,da_pos_x2
             sub       ax,da_pos_x1
             dec       ax
             cmp       discost,1
             jne       _Dopo__
             inc       ax
_Dopo__:     cmp       discost,0FFFFh  ; 0FFFFh = -1
             jne       _Dopo___
             dec       ax
_Dopo___:    mov       __cx,ax


; SaltoSI = (FromDC.DimXCA div 8)-2-__cx
             mov       ax,ds:[si.DimXCA]  ; In DS:SI c'Š FromDC
             shr       ax,3               ; AX <- AX div 8
             sub       ax,__cx
             dec       ax
             dec       ax
             mov       SaltoSI,ax

; SaltoDI = (ToDC.DimXCA div 8)-2-__cx
             mov       ax,es:[di.DimXCA]  ; In ES:DI c'Š ToDC
             shr       ax,3               ; AX <- AX div 8
             sub       ax,__cx
             dec       ax
             dec       ax
             mov       SaltoDI,ax


; da_pos_x2 = da_pos_x2 + (DimY - 1)*FromDC.DimXCA
             mov       bx,DimY         ; con DimY > 0
             dec       bx
             mov       ax,ds:[si.DimXCA]  ; In DS:SI c'Š FromDC
             shr       ax,3               ; AX <- AX div 8
             mul       bx                 ; ax = (DimY - 1)*DimXCA
             add       da_pos_x2,ax

; a_pos_x2 = a_pos_x2 + (DimY - 1)*ToDC.DimXCA
             mov       ax,es:[di.DimXCA]  ; In ES:DI c'Š ToDC
             shr       ax,3               ; AX <- AX div 8
             mul       bx                 ; ax = (DimY - 1)*DimXCA
             add       a_pos_x2,ax        ; ax = (DimY - 1)*DimXCA

; a_pos_x1 = a_pos_x1 + (DimY - 1)*ToDC.DimXCA
             add       a_pos_x1,ax        ; ax = (DimY - 1)*DimXCA


; SECONDA FASE DI INIZIALIZZAZIONE

; preparazione shifts per la parte centrale della linea
             mov       ax,a_x1_
             sub       ax,da_x1_
             mov       cl,8
             div       cl
             mov       bh,ah           ; bh contiene gli shift da sinistra
             mov       bl,8
             sub       bl,bh           ; bl contiene gli shift da destra
             mov       ax,da_x1_
             div       cl              ; cl = 8
             mov       __bl,ah
; preparazione degli shifts per l'elemento pi— a sinistra
             mov       ax,a_x1_
             div       cl              ; cl = 8
             mov       __bh,ah
             cmp       discost,0
             jne       Normale
             cmp       __bl,ah
             jna       Normale
             mov       discost,2
Normale:
; preparazione degli shifts per l'elemento pi— a destra
             mov       ax,a_x1_
             add       ax,DimX
             div       cl              ; cl = 8
             mov       __bl,8
             sub       __bl,ah
; preparazione delle maschere per le estremit… della linea
             mov       al,0FFh
             mov       cl,__bh
             shr       al,cl
             mov       mask1,al        ; assegnamento di mask1
             not       al
             mov       _mask1,al       ; assegnamento di _mask1

             mov       al,0FFh
             mov       cl,__bl
             shl       al,cl
             mov       mask2,al        ; assegnamento di mask2
             not       al
             mov       _mask2,al       ; assegnamento di _mask2

             cmp       discost,0FFFFh  ; -1
             jne       _Oppure_
             jmp       SHORT Rettifica
_Oppure_:
             cmp       discost,0
             jne       _If2_
Rettifica:
             cmp       mask2,0
             jne       _If2_
             mov       mask2,0FFh
             mov       _mask2,0


_If2_:
             mov       ax,a_pos_x1
             cmp       a_pos_x2,ax     ; confronta a_pos_x1 e a_pos_x2
             jne       _SistemaSalti_
             mov       al,mask2
             and       al,mask1
             mov       mask2,al
             not       al
             mov       _mask2,al
             add       discost,4
             cmp       discost,6
             je        _SistemaSalti_
             dec       SaltoDI
             dec       SaltoSI

_SistemaSalti_:
             inc       SaltoDI

             cmp       discost,4
             jne       CopiaPagina
             mov       discost,3

CopiaPagina:

; PROCESSO DI COPIA DELLE PAGINE VIDEO
             std                       ; direzione inversa

; Posizionamento degli OFFSETS dei puntatori alle pagine
             mov       ax,a_pos_x2
             add       O_Tp1,ax
             add       O_Tp2,ax
             add       O_Tp3,ax
             add       O_Tp4,ax

             mov       ax,da_pos_x2
             add       O_Fp1,ax
             add       O_Fp2,ax
             add       O_Fp3,ax
             add       O_Fp4,ax


             mov       cx,DimY         ; cx = Numero di linee

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

; Auto-parametrizzazione del codice
             mov       BYTE PTR cs:_1_par_004,bh
             mov       BYTE PTR cs:_1_par_005,bl
             mov       BYTE PTR cs:_2_par_004,bh
             mov       BYTE PTR cs:_2_par_005,bl
             mov       BYTE PTR cs:_3_par_004,bh
             mov       BYTE PTR cs:_3_par_005,bl
             mov       BYTE PTR cs:_4_par_004,bh
             mov       BYTE PTR cs:_4_par_005,bl


; Taratura di SaltoDI e SaltoSI
             cmp       discost,0FFFFh
             jne       _If3_
             dec       SaltoSI
             jmp       SHORT InizioLinea
_If3_:
             cmp       discost,1
             jne       _If4_
             inc       SaltoSI
             jmp       SHORT InizioLinea
_If4_:
             cmp       discost,3
             jne       InizioLinea
             inc       SaltoDI

InizioLinea:
             push      cx

;----------------------------------------------------------------------------
; Prima Pagina
             lds       si,Fp1
             les       di,Tp1

             COPIA_LINEA_SHIFT 1,1,0

             mov       O_Fp1,si
             mov       O_Tp1,di
;----------------------------------------------------------------------------
; Seconda Pagina
             lds       si,Fp2
             les       di,Tp2

             COPIA_LINEA_SHIFT 2,2,1

             mov       O_Fp2,si
             mov       O_Tp2,di
;----------------------------------------------------------------------------
; Selezione Terza Pagina
             lds       si,Fp3
             les       di,Tp3

             COPIA_LINEA_SHIFT 3,4,2

             mov       O_Fp3,si
             mov       O_Tp3,di
;----------------------------------------------------------------------------
; QuartaPagina
             lds       si,Fp4
             les       di,Tp4

             COPIA_LINEA_SHIFT 4,8,3

             mov       O_Fp4,si
             mov       O_Tp4,di
;----------------------------------------------------------------------------
; SALTO LINEA

             mov       ax,SaltoDI
             sub       O_Tp1,ax
             sub       O_Tp2,ax
             sub       O_Tp3,ax
             sub       O_Tp4,ax

             mov       ax,SaltoSI
             sub       O_Fp1,ax
             sub       O_Fp2,ax
             sub       O_Fp3,ax
             sub       O_Fp4,ax

             pop       cx
             dec       cx
             jcxz      __FuoriLoop
             jmp       InizioLinea

__FuoriLoop:
             jmp       FuoriLoop

; ***********************                      ******************************
; *********************** COPIA SENZA SHIFTING ******************************
; ***********************                      ******************************

; DISCOST = 0

SenzaShifting:
             lea       si,VideoDC
             mov       dx,ds

             les       di,FromDC
             mov       bx,es
             cmp       bx,dx
             jne       SenzaShiftingNormale
             cmp       si,di
             jne       SenzaShiftingNormale

             les       di,ToDC
             mov       bx,es
             cmp       bx,dx
             jne       SenzaShiftingNormale
             cmp       si,di
             jne       SenzaShiftingNormale

             jmp       SenzaShiftingFB_FB



SenzaShiftingNormale:

; Auto-parametrizzazione del codice
             mov       al,mask2
             mov       BYTE PTR cs:___1_par_001,al
             mov       BYTE PTR cs:___2_par_001,al
             mov       BYTE PTR cs:___3_par_001,al
             mov       BYTE PTR cs:___4_par_001,al

             mov       al,_mask2
             mov       BYTE PTR cs:___1_par_002,al
             mov       BYTE PTR cs:___2_par_002,al
             mov       BYTE PTR cs:___3_par_002,al
             mov       BYTE PTR cs:___4_par_002,al

             mov       al,mask1
             mov       BYTE PTR cs:___1_par_003,al
             mov       BYTE PTR cs:___2_par_003,al
             mov       BYTE PTR cs:___3_par_003,al
             mov       BYTE PTR cs:___4_par_003,al

             mov       al,_mask1
             mov       BYTE PTR cs:___1_par_004,al
             mov       BYTE PTR cs:___2_par_004,al
             mov       BYTE PTR cs:___3_par_004,al
             mov       BYTE PTR cs:___4_par_004,al

             cmp       discost,3
             jne       ___InizioLinea
             inc       SaltoDI
             inc       SaltoSI

___InizioLinea:
             push      cx

; COPIA LINEA

;----------------------------------------------------------------------------
; Prima Pagina
             lds       si,Fp1
             les       di,Tp1

             COPIA_LINEA_NSHIFT 1,1,0

             mov       O_Fp1,si
             mov       O_Tp1,di
;----------------------------------------------------------------------------
; Seconda Pagina
             lds       si,Fp2
             les       di,Tp2

             COPIA_LINEA_NSHIFT 2,2,1

             mov       O_Fp2,si
             mov       O_Tp2,di
;----------------------------------------------------------------------------
; Selezione Terza Pagina
             lds       si,Fp3
             les       di,Tp3

             COPIA_LINEA_NSHIFT 3,4,2

             mov       O_Fp3,si
             mov       O_Tp3,di
;----------------------------------------------------------------------------
; QuartaPagina
             lds       si,Fp4
             les       di,Tp4

             COPIA_LINEA_NSHIFT 4,8,3

             mov       O_Fp4,si
             mov       O_Tp4,di
;----------------------------------------------------------------------------
; SALTO LINEA

             mov       ax,SaltoDI
             sub       O_Tp1,ax
             sub       O_Tp2,ax
             sub       O_Tp3,ax
             sub       O_Tp4,ax

             mov       ax,SaltoSI
             sub       O_Fp1,ax
             sub       O_Fp2,ax
             sub       O_Fp3,ax
             sub       O_Fp4,ax

             pop       cx
             dec       cx
             jcxz      ___FuoriLoop
             jmp       ___InizioLinea

___FuoriLoop:
             jmp       FuoriLoop

; ***********************                      ******************************
; ****************        COPIA SENZA SHIFTING        ***********************
; **************** (Da FRAME-BUFFER  a  FRAME-BUFFER) ***********************
; ***********************                      ******************************

; DISCOST = 0

SenzaShiftingFB_FB:
             mov       ax,0A000h
             mov       ds,ax
             mov       es,ax
             mov       si,da_pos_x2
             mov       di,a_pos_x2


; Auto-parametrizzazione del codice
             mov       al,mask2
             mov       BYTE PTR cs:__1_par_001,al
             mov       BYTE PTR cs:__2_par_001,al
             mov       BYTE PTR cs:__3_par_001,al
             mov       BYTE PTR cs:__4_par_001,al

             mov       al,_mask2
             mov       BYTE PTR cs:__1_par_002,al
             mov       BYTE PTR cs:__2_par_002,al
             mov       BYTE PTR cs:__3_par_002,al
             mov       BYTE PTR cs:__4_par_002,al

             mov       al,mask1
             mov       BYTE PTR cs:__1_par_003,al
             mov       BYTE PTR cs:__2_par_003,al
             mov       BYTE PTR cs:__3_par_003,al
             mov       BYTE PTR cs:__4_par_003,al

             mov       al,_mask1
             mov       BYTE PTR cs:__1_par_004,al
             mov       BYTE PTR cs:__2_par_004,al
             mov       BYTE PTR cs:__3_par_004,al
             mov       BYTE PTR cs:__4_par_004,al

             cmp       discost,3
             jne       __InizioLinea
             inc       SaltoDI
             inc       SaltoSI

__InizioLinea:
             push      cx

; COPIA LINEA

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; Selezione Prima Pagina
             mov       dx,3C5h
             mov       al,1            ; seleziona la pagina 1
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 0
             mov       al,0
             out       dx,al

; Sistemazione dell'ultimo elemento
             mov       al,BYTE PTR ds:[si]
             db        36              ; opcode di AND AL,<n>
__1_par_001:
             db        0
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__1_par_002:
             db        0
             or        BYTE PTR es:[di],al   ; sistema l'elemento

;----------------------------------------------------------------------------
; Selezione Seconda Pagina
             mov       dx,3C5h
             mov       al,2            ; seleziona la pagina 2
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 1
             mov       al,1
             out       dx,al

; Sistemazione dell'ultimo elemento
             mov       al,BYTE PTR ds:[si]
             db        36              ; opcode di AND AL,<n>
__2_par_001:
             db        0
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__2_par_002:
             db        0
             or        BYTE PTR es:[di],al   ; sistema l'elemento

;----------------------------------------------------------------------------
; Selezione Terza Pagina
             mov       dx,3C5h
             mov       al,4            ; seleziona la pagina 4
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 2
             mov       al,2
             out       dx,al

; Sistemazione dell'ultimo elemento
             mov       al,BYTE PTR ds:[si]
             db        36              ; opcode di AND AL,<n>
__3_par_001:
             db        0
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__3_par_002:
             db        0
             or        BYTE PTR es:[di],al   ; sistema l'elemento

;----------------------------------------------------------------------------
; Selezione Quarta Pagina
             mov       dx,3C5h
             mov       al,8            ; seleziona la pagina 8
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 3
             mov       al,3
             out       dx,al

; Sistemazione dell'ultimo elemento
             lodsb                     ; al = BYTE PTR ds:[si]
             db        36              ; opcode di AND AL,<n>
__4_par_001:
             db        0
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__4_par_002:
             db        0
             or        BYTE PTR es:[di],al   ; sistema l'elemento

             cmp       discost,3
             je        _FineLinea
             dec       di

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; Sistemazione degli elementi del centro della linea
             mov       cx,__cx
             jcxz      __PrimoElemento

             mov       dx,3C4h
             mov       al,2
             out       dx,al           ; seleziona il registro delle pagine attive
             mov       dx,3C5h
             mov       al,15           ; seleziona tutte le pagine
             out       dx,al

             mov       dx,3CEh
             mov       al,5
             out       dx,al           ; seleziona il GDC index a 5
             mov       dx,3cfh
             mov       al,1
             out       dx,al           ; seleziona la modalit… 1

             rep       movsb

             mov       dx,3cfh
             mov       al,0
             out       dx,al           ; seleziona la modalit… 0

             mov       dx,3C4h
             mov       al,2
             out       dx,al           ; seleziona il registro delle pagine attive
             mov       dx,3CEh
             mov       al,4
             out       dx,al           ; seleziona il GDC index a 4

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
__PrimoElemento:


; Selezione Prima Pagina
             mov       dx,3C5h
             mov       al,1            ; seleziona la pagina 1
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 0
             mov       al,0
             out       dx,al

; Sistemazione del primo elemento

             mov       al,ds:[si]
             db        36              ; opcode di AND AL,<n>
__1_par_003:
             db        0
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__1_par_004:
             db        0
             or        BYTE PTR es:[di],al

;----------------------------------------------------------------------------
; Selezione Seconda Pagina
             mov       dx,3C5h
             mov       al,2            ; seleziona la pagina 2
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 1
             mov       al,1
             out       dx,al

; Sistemazione del primo elemento

             mov       al,ds:[si]
             db        36              ; opcode di AND AL,<n>
__2_par_003:
             db        0
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__2_par_004:
             db        0
             or        BYTE PTR es:[di],al

;----------------------------------------------------------------------------
; Selezione Terza Pagina
             mov       dx,3C5h
             mov       al,4            ; seleziona la pagina 4
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 2
             mov       al,2
             out       dx,al

; Sistemazione del primo elemento

             mov       al,ds:[si]
             db        36              ; opcode di AND AL,<n>
__3_par_003:
             db        0
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__3_par_004:
             db        0
             or        BYTE PTR es:[di],al

;----------------------------------------------------------------------------
; Selezione Quarta Pagina
             mov       dx,3C5h
             mov       al,8            ; seleziona la pagina 8
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 3
             mov       al,3
             out       dx,al

; Sistemazione del primo elemento

             lodsb
             db        36              ; opcode di AND AL,<n>
__4_par_003:
             db        0
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__4_par_004:
             db        0
             or        BYTE PTR es:[di],al

_FineLinea:


;----------------------------------------------------------------------------
; SALTO LINEA

             sub       di,SaltoDI
             sub       si,SaltoSI
             pop       cx
             dec       cx
             jcxz      FuoriLoop
             jmp       __InizioLinea


;----------------------------------------------------------------------------
FuoriLoop:
             pop       ds

             mov       dx,3C5h
             mov       al,15           ; seleziona la pagina 1
             out       dx,al

             leave
             ret RetBytes
BitBtl_RI    ENDP


CODE         ENDS
             END