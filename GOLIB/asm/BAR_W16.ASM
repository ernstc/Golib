; by ERNESTO CIANCIOTTA (c) 1995

; /*********************************************************************
; \
; / Procedura BARGolibW per la libreria GOLIB 1.0.
; \
; / Questa procedura Š la versione estesa (anche se pi— lenta) della
; \ procedura BarGolib contenuta nel file BAR.ASM, infatti opera
: / con un Pattern (GBLPattern) definito nel modulo GrafTool.TPU
; \ e pu• anche operare in pi— modalit… di scrittura.
; /
; \ N.B.: Solo per Intel 80186 e successivi.
; /
; \*********************************************************************

DATA         SEGMENT WORD PUBLIC
             ASSUME ds:DATA

             EXTRN GLBPattern:BYTE     ; Primo byte del Pattern

DATA         ENDS


CODE         SEGMENT BYTE PUBLIC
             ASSUME cs:CODE

BarGolibW    PROC   FAR
             PUBLIC BarGolibW
             ARG    WriteMode:BYTE, colore, DimY, DimX, n1, m1:WORD= RetBytes

; WriteMode pu• assumere i seguenti valori:
; 0. Normal  Draw Mode
; 1. XOR     Draw Mode
; 2. ORLogic Draw Mode
; 3. ORFisic Draw Mode
; 4. AND     Draw Mode
; 5. NOT     Draw Mode

             LOCAL  Limite, _di, p1_1:BYTE,p2_1:BYTE,p3_1:BYTE,p4_1:BYTE, p1_2:BYTE,p2_2:BYTE,p3_2:BYTE,p4_2:BYTE, p1_3:BYTE,p2_3:BYTE,p3_3:BYTE,p4_3:BYTE, a_pos_x2, a_pos_x1, __cx, SaltoLinea:WORD, mask1:BYTE,_mask1:BYTE,mask2:BYTE,_mask2:BYTE,__bh:BYTE,__bl:BYTE= VariabiliLocali
             .386
       ;      cli
             enter     VariabiliLocali,0

; PRIMA FASE DI INIZIALIZZAZIONE


             mov       al,WriteMode
             cmp       al,5
             jna       _If2_
             mov       WriteMode,0
_If2_:
             cmp       al,5
             jne       Prosegui
             not       colore
             mov       WriteMode,0
Prosegui:



; DimX = m2-n1+1
;             mov       ax,m2
;             sub       ax,m1
;             inc       ax
;             mov       DimX,ax

; DimY = n2-n1+1
;             mov       ax,n2
;             sub       ax,n1
;             inc       ax
;             mov       DimY,ax

; a_pos_x1 = ( m1 div 8)+80*n1
             mov       ax,m1
             xor       dx,dx           ; dx = 0000h
             mov       cx,8
             div       cx              ; cx = 8
             imul      bx,n1,80        ; bx = 80*n1
             add       ax,bx
             mov       a_pos_x1,ax

; a_pos_x2 = [(m1+DimX-1) div 8]+80*n1
             mov       ax,m1
             add       ax,DimX
             dec       ax              ; ax = m1+DimX-1
             xor       dx,dx           ; dx = 0000h
             div       cx              ; cx = 8
             add       ax,bx           ; bx = 80*n1
             mov       a_pos_x2,ax

; __cx = a_pos_x2 - a_pos_x1 - 1
             mov       ax,a_pos_x2
             sub       ax,a_pos_x1
             dec       ax
             mov       __cx,ax

; SaltoLinea = 80-2-__cx
             mov       bx,79
             sub       bx,ax           ; ax = __cx
             mov       SaltoLinea,bx

; SECONDA FASE DI INIZIALIZZAZIONE


; preparazione degli shifts per l'elemento pi— a sinistra
             mov       ax,m1
             div       cl              ; cl = 8
             mov       bh,ah

; preparazione degli shifts per l'elemento pi— a destra
             mov       ax,m1
             add       ax,DimX
             div       cl              ; cl = 8
             mov       bl,8
             sub       bl,ah

; preparazione delle maschere per le estremit… della linea
             mov       al,0FFh
             mov       cl,bh
             shr       al,cl
             mov       mask1,al        ; assegnamento di mask1
             not       al
             mov       _mask1,al       ; assegnamento di _mask1

             mov       al,0FFh
             mov       cl,bl
             shl       al,cl
             mov       mask2,al        ; assegnamento di mask2
             not       al
             mov       _mask2,al       ; assegnamento di _mask2

             mov       dl,mask2
             cmp       dl,0
             jne       _Dopo__
             mov       dl,0FFh
_Dopo__:

             mov       bx,0FFFFh
             and       bh,mask1
             and       bl,mask2

             mov       ax,a_pos_x2
             cmp       a_pos_x1,ax
             jne       Scomposizione
             and       bh,dl
             mov       bl,bh
             not       bl
             mov       mask1,bh
             mov       _mask1,bl
             mov       mask2,0

; Scomposizione del colore nei suoi quattro piani

Scomposizione:
             mov       ax,colore
; 1ø Piano
             shr       al,1
             jnc       _1_Vuoto
             mov       p1_1,bh
             mov       p1_2,bl
             mov       p1_3,0FFh
             jmp       SHORT _1_Pieno
_1_Vuoto:
             mov       p1_1,0
             mov       p1_2,0
             mov       p1_3,0
_1_Pieno:

; 2ø Piano
             shr       al,1
             jnc       _2_Vuoto
             mov       p2_1,bh
             mov       p2_2,bl
             mov       p2_3,0FFh
             jmp       SHORT _2_Pieno
_2_Vuoto:
             mov       p2_1,0
             mov       p2_2,0
             mov       p2_3,0
_2_Pieno:

; 3ø Piano
             shr       al,1
             jnc       _3_Vuoto
             mov       p3_1,bh
             mov       p3_2,bl
             mov       p3_3,0FFh
             jmp       SHORT _3_Pieno
_3_Vuoto:
             mov       p3_1,0
             mov       p3_2,0
             mov       p3_3,0
_3_Pieno:

; 4ø Piano
             shr       al,1
             jnc       _4_Vuoto
             mov       p4_1,bh
             mov       p4_2,bl
             mov       p4_3,0FFh
             jmp       SHORT _4_Pieno
_4_Vuoto:
             mov       p4_1,0
             mov       p4_2,0
             mov       p4_3,0
_4_Pieno:


             cmp       mask1,0FFh
             jne       _Controllo2_
             inc       __cx
             ;dec       SaltoLinea
_Controllo2_:
             cmp       mask2,0
             jne       CopiaPagina
             inc       __cx
             dec       SaltoLinea


CopiaPagina:

; PROCESSO DI COPIA DELLE PAGINE VIDEO
             cld
             push      ds

             mov       dx,0A000h
             mov       es,dx
             lea       si,GLBPattern
             mov       di,a_pos_x1

             lea       si,GLBPattern
             mov       bx,0            ; bx funge da PatternIndex

             mov       cx,DimY         ; cx = Numero di linee

             mov       dx,3C4h
             mov       al,2
             out       dx,al           ; seleziona il registro delle pagine attive
             mov       dx,3CEh
             mov       al,4
             out       dx,al           ; seleziona il GDC index a 4


             mov       bx,si
             add       bx,8            ; BX Š il massimo valore che SI pu•
                                       ; assumere
             cmp       WriteMode,1
             je        XORMode
             cmp       WriteMode,2
             je        ORLogicMode
             cmp       WriteMode,3
             je        ORFisicMode
             cmp       WriteMode,4
             je        ANDMode


;****************************************************************************
;***************************** Normal Mode *************************************
;****************************************************************************
NormalMode:

; Auto-parametrizzazione del codice
             mov       al,_mask2
             mov       BYTE PTR cs:_N_1_Not_mask2,al
             mov       BYTE PTR cs:_N_2_Not_mask2,al
             mov       BYTE PTR cs:_N_3_Not_mask2,al
             mov       BYTE PTR cs:_N_4_Not_mask2,al

             mov       al,_mask1
             mov       BYTE PTR cs:_N_1_Not_mask1,al
             mov       BYTE PTR cs:_N_2_Not_mask1,al
             mov       BYTE PTR cs:_N_3_Not_mask1,al
             mov       BYTE PTR cs:_N_4_Not_mask1,al

_N_InizioLinea:
             push      cx

             mov       _di,di

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
_N_Prima_Pagina:

             mov       dx,3C5h
             mov       al,1            ; seleziona la pagina 1
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 0
             mov       al,0
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _N_1_CentroLinea

; Primo elemento
             mov       al,p1_1
             and       al,ds:[si]
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
_N_1_Not_mask1:
             db        0
             or        BYTE PTR es:[di],al
             inc       di


_N_1_CentroLinea:
             mov       cx,__cx
             jcxz      _N_1_UltimoElemento
             mov       al,p1_3
             and       al,ds:[si]
             rep       stosb


_N_1_UltimoElemento:
             cmp       mask2,0
             je        _N_Seconda_Pagina
             mov       al,p1_2
             and       al,ds:[si]
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
_N_1_Not_mask2:
             db        0
             or        BYTE PTR es:[di],al

;----------------------------------------------------------------------------

_N_Seconda_Pagina:

             mov       di,_di

             mov       dx,3C5h
             mov       al,2            ; seleziona la pagina 2
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 1
             mov       al,1
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _N_2_CentroLinea

; Primo elemento
             mov       al,p2_1
             and       al,ds:[si]
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
_N_2_Not_mask1:
             db        0
             or        BYTE PTR es:[di],al
             inc       di


_N_2_CentroLinea:
             mov       cx,__cx
             jcxz      _N_2_UltimoElemento
             mov       al,p2_3
             and       al,ds:[si]
             rep       stosb


_N_2_UltimoElemento:
             cmp       mask2,0
             je        _N_Terza_Pagina
             mov       al,p2_2
             and       al,ds:[si]
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
_N_2_Not_mask2:
             db        0
             or        BYTE PTR es:[di],al

;----------------------------------------------------------------------------

_N_Terza_Pagina:

             mov       di,_di

             mov       dx,3C5h
             mov       al,4            ; seleziona la pagina 4
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 2
             mov       al,2
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _N_3_CentroLinea

; Primo elemento
             mov       al,p3_1
             and       al,ds:[si]
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
_N_3_Not_mask1:
             db        0
             or        BYTE PTR es:[di],al
             inc       di


_N_3_CentroLinea:
             mov       cx,__cx
             jcxz      _N_3_UltimoElemento
             mov       al,p3_3
             and       al,ds:[si]
             rep       stosb


_N_3_UltimoElemento:
             cmp       mask2,0
             je        _N_Quarta_Pagina
             mov       al,p3_2
             and       al,ds:[si]
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
_N_3_Not_mask2:
             db        0
             or        BYTE PTR es:[di],al

;----------------------------------------------------------------------------

_N_Quarta_Pagina:

             mov       di,_di

             mov       dx,3C5h
             mov       al,8            ; seleziona la pagina 8
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 3
             mov       al,3
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _N_4_CentroLinea

; Primo elemento
             mov       al,p4_1
             and       al,ds:[si]
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
_N_4_Not_mask1:
             db        0
             or        BYTE PTR es:[di],al
             inc       di


_N_4_CentroLinea:
             mov       cx,__cx
             jcxz      _N_4_UltimoElemento
             mov       al,p4_3
             and       al,ds:[si]
             rep       stosb


_N_4_UltimoElemento:
             cmp       mask2,0
             je        _N_SaltoLinea_
             mov       al,p4_2
             and       al,ds:[si]
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
_N_4_Not_mask2:
             db        0
             or        BYTE PTR es:[di],al

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; SALTO LINEA

_N_SaltoLinea_:

             pop       cx
             dec       cx
             jcxz      _N_FuoriLoop

             add       di,SaltoLinea   ; Punta sulla nuova linea
             inc       si              ; Seleziona la linea successiva del Pattern
             cmp       si,bx
             jne       _N_Salta
             sub       si,8
_N_Salta:
             jmp       _N_InizioLinea



;----------------------------------------------------------------------------
_N_FuoriLoop:
             pop       ds

             mov       dx,3C5h
             mov       al,15           ; seleziona tutte le pagine del Sequencer
             out       dx,al

             leave
             sti
             ret RetBytes





;****************************************************************************
;***************************** XOR Mode *************************************
;****************************************************************************
XORMode:

_XOR_InizioLinea:
             push      cx

             mov       _di,di

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
_XOR_Prima_Pagina:

             mov       dx,3C5h
             mov       al,1            ; seleziona la pagina 1
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 0
             mov       al,0
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _XOR_1_CentroLinea

; Primo elemento
             mov       al,p1_1
             and       al,ds:[si]
             xor       BYTE PTR es:[di],al
             inc       di


_XOR_1_CentroLinea:
             mov       cx,__cx
             jcxz      _XOR_1_UltimoElemento
             mov       al,p1_3
             and       al,ds:[si]
_XOR_Loop1:
             xor       es:[di],al
             inc       di
             loop      _XOR_Loop1


_XOR_1_UltimoElemento:
             cmp       mask2,0
             je        _XOR_Seconda_Pagina
             mov       al,p1_2
             and       al,ds:[si]
             xor        BYTE PTR es:[di],al

;----------------------------------------------------------------------------

_XOR_Seconda_Pagina:

             mov       di,_di

             mov       dx,3C5h
             mov       al,2            ; seleziona la pagina 2
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 1
             mov       al,1
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _XOR_2_CentroLinea

; Primo elemento
             mov       al,p2_1
             and       al,ds:[si]
             xor       BYTE PTR es:[di],al
             inc       di


_XOR_2_CentroLinea:
             mov       cx,__cx
             jcxz      _XOR_2_UltimoElemento
             mov       al,p2_3
             and       al,ds:[si]
_XOR_Loop2:
             xor       es:[di],al
             inc       di
             loop      _XOR_Loop2


_XOR_2_UltimoElemento:
             cmp       mask2,0
             je        _XOR_Terza_Pagina
             mov       al,p2_2
             and       al,ds:[si]
             xor        BYTE PTR es:[di],al

;----------------------------------------------------------------------------

_XOR_Terza_Pagina:

             mov       di,_di

             mov       dx,3C5h
             mov       al,4            ; seleziona la pagina 4
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 2
             mov       al,2
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _XOR_3_CentroLinea

; Primo elemento
             mov       al,p3_1
             and       al,ds:[si]
             xor       BYTE PTR es:[di],al
             inc       di


_XOR_3_CentroLinea:
             mov       cx,__cx
             jcxz      _XOR_3_UltimoElemento
             mov       al,p3_3
             and       al,ds:[si]
_XOR_Loop3:
             xor       es:[di],al
             inc       di
             loop      _XOR_Loop3


_XOR_3_UltimoElemento:
             cmp       mask2,0
             je        _XOR_Quarta_Pagina
             mov       al,p3_2
             and       al,ds:[si]
             xor        BYTE PTR es:[di],al

;----------------------------------------------------------------------------

_XOR_Quarta_Pagina:

             mov       di,_di

             mov       dx,3C5h
             mov       al,8            ; seleziona la pagina 8
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 3
             mov       al,3
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _XOR_4_CentroLinea

; Primo elemento
             mov       al,p4_1
             and       al,ds:[si]
             xor       BYTE PTR es:[di],al
             inc       di


_XOR_4_CentroLinea:
             mov       cx,__cx
             jcxz      _XOR_4_UltimoElemento
             mov       al,p4_3
             and       al,ds:[si]
_XOR_Loop4:
             xor       es:[di],al
             inc       di
             loop      _XOR_Loop4


_XOR_4_UltimoElemento:
             cmp       mask2,0
             je        _XOR_SaltoLinea_
             mov       al,p4_2
             and       al,ds:[si]
             xor        BYTE PTR es:[di],al

            ; inc       di

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; SALTO LINEA

_XOR_SaltoLinea_:

             pop       cx
             dec       cx
             jcxz      _XOR_FuoriLoop

             add       di,SaltoLinea   ; Punta sulla nuova linea
             inc       si              ; Seleziona la linea successiva del Pattern
             cmp       si,bx
             jne       _XOR_Salta
             sub       si,8
_XOR_Salta:
             jmp       _XOR_InizioLinea



;----------------------------------------------------------------------------
_XOR_FuoriLoop:
             pop       ds

             mov       dx,3C5h
             mov       al,15           ; seleziona tutte le pagine del Sequencer
             out       dx,al

             leave
             sti
             ret RetBytes





;****************************************************************************
;****************************** OR Logic Mode *******************************
;****************************************************************************
ORLogicMode:

_OR_Lg_InizioLinea:
             push      cx

             mov       _di,di

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
_OR_Lg_Prima_Pagina:
             cmp       p1_3,0
             je        _OR_Lg_Seconda_Pagina

             mov       dx,3C5h
             mov       al,1            ; seleziona la pagina 1
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 0
             mov       al,0
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _OR_Lg_1_CentroLinea

; Primo elemento
             mov       al,p1_1
             and       al,ds:[si]
             or        BYTE PTR es:[di],al
             inc       di


_OR_Lg_1_CentroLinea:
             mov       cx,__cx
             jcxz      _OR_Lg_1_UltimoElemento
             mov       al,p1_3
             and       al,ds:[si]
_OR_Lg_Loop1:
             or        es:[di],al
             inc       di
             loop      _OR_Lg_Loop1


_OR_Lg_1_UltimoElemento:
             cmp       mask2,0
             je        _OR_Lg_Seconda_Pagina
             mov       al,p1_2
             and       al,ds:[si]
             or        BYTE PTR es:[di],al

;----------------------------------------------------------------------------

_OR_Lg_Seconda_Pagina:
             cmp       p2_3,0
             je        _OR_Lg_Terza_Pagina

             mov       di,_di

             mov       dx,3C5h
             mov       al,2            ; seleziona la pagina 2
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 1
             mov       al,1
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _OR_Lg_2_CentroLinea

; Primo elemento
             mov       al,p2_1
             and       al,ds:[si]
             or        BYTE PTR es:[di],al
             inc       di


_OR_Lg_2_CentroLinea:
             mov       cx,__cx
             jcxz      _OR_Lg_2_UltimoElemento
             mov       al,p2_3
             and       al,ds:[si]
_OR_Lg_Loop2:
             or        es:[di],al
             inc       di
             loop      _OR_Lg_Loop2


_OR_Lg_2_UltimoElemento:
             cmp       mask2,0
             je        _OR_Lg_Terza_Pagina
             mov       al,p2_2
             and       al,ds:[si]
             or        BYTE PTR es:[di],al

;----------------------------------------------------------------------------

_OR_Lg_Terza_Pagina:
             cmp       p3_3,0
             je        _OR_Lg_Quarta_Pagina

             mov       di,_di

             mov       dx,3C5h
             mov       al,4            ; seleziona la pagina 4
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 2
             mov       al,2
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _OR_Lg_3_CentroLinea

; Primo elemento
             mov       al,p3_1
             and       al,ds:[si]
             or        BYTE PTR es:[di],al
             inc       di


_OR_Lg_3_CentroLinea:
             mov       cx,__cx
             jcxz      _OR_Lg_3_UltimoElemento
             mov       al,p3_3
             and       al,ds:[si]
_OR_Lg_Loop3:
             or        es:[di],al
             inc       di
             loop      _OR_Lg_Loop3


_OR_Lg_3_UltimoElemento:
             cmp       mask2,0
             je        _OR_Lg_Quarta_Pagina
             mov       al,p3_2
             and       al,ds:[si]
             or        BYTE PTR es:[di],al

;----------------------------------------------------------------------------

_OR_Lg_Quarta_Pagina:
             cmp       p4_3,0
             je        _OR_Lg_SaltoLinea_

             mov       di,_di

             mov       dx,3C5h
             mov       al,8            ; seleziona la pagina 8
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 3
             mov       al,3
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _OR_Lg_4_CentroLinea

; Primo elemento
             mov       al,p4_1
             and       al,ds:[si]
             or        BYTE PTR es:[di],al
             inc       di


_OR_Lg_4_CentroLinea:
             mov       cx,__cx
             jcxz      _OR_Lg_4_UltimoElemento
             mov       al,p4_3
             and       al,ds:[si]
_OR_Lg_Loop4:
             or        es:[di],al
             inc       di
             loop      _OR_Lg_Loop4


_OR_Lg_4_UltimoElemento:
             cmp       mask2,0
             je        _OR_Lg_SaltoLinea_
             mov       al,p4_2
             and       al,ds:[si]
             or        BYTE PTR es:[di],al

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; SALTO LINEA

_OR_Lg_SaltoLinea_:

             pop       cx
             dec       cx
             jcxz      _OR_Lg_FuoriLoop

             add       di,SaltoLinea   ; Punta sulla nuova linea
             inc       si              ; Seleziona la linea successiva del Pattern
             cmp       si,bx
             jne       _OR_Lg_Salta
             sub       si,8
_OR_Lg_Salta:
             jmp       _OR_Lg_InizioLinea



;----------------------------------------------------------------------------
_OR_Lg_FuoriLoop:
             pop       ds

             mov       dx,3C5h
             mov       al,15           ; seleziona tutte le pagine del Sequencer
             out       dx,al

             leave
             sti
             ret RetBytes




;****************************************************************************
;****************************** OR Fisic Mode *******************************
;****************************************************************************
ORFisicMode:

_OR_Fs_InizioLinea:
             push      cx

             mov       _di,di

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
_OR_Fs_Prima_Pagina:

             mov       dx,3C5h
             mov       al,1            ; seleziona la pagina 1
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 0
             mov       al,0
             out       dx,al

; Primo elemento
             cmp       mask1,0FFh
             je        SHORT _OR_Fs_1_CentroLinea
             mov       al,p1_1
             cmp       al,0
             je        _OR_Fs_1_ZP
             and       al,ds:[si]
             or        BYTE PTR es:[di],al
             jmp       SHORT _OR_Fs_1_FP
_OR_Fs_1_ZP:
             mov       al,ds:[si]
             not       al
             or        al,_mask1
             and       BYTE PTR es:[di],al
_OR_Fs_1_FP:
             inc       di



_OR_Fs_1_CentroLinea:
             mov       cx,__cx
             jcxz      _OR_Fs_1_UltimoElemento
             mov       al,p1_3
             cmp       al,0
             je        _OR_Fs_1_Z

_OR_Fs_1_NZ:
             and       al,ds:[si]
             mov       ah,al
             not       ah
_OR_Fs_Loop1:
             or        es:[di],al
             inc       di
             loop      _OR_Fs_Loop1
             jmp       SHORT _OR_Fs_1_UltimoElemento

_OR_Fs_1_Z:
             mov       al,ds:[si]
             not       al
_OR_Fs_Loop1_2:
             and       es:[di],al
             inc       di
             loop      _OR_Fs_Loop1_2



_OR_Fs_1_UltimoElemento:
             cmp       mask2,0
             je        _OR_Fs_Seconda_Pagina
             mov       al,p1_2
             cmp       al,0
             je        _OR_Fs_1_ZU
             and       al,ds:[si]
             or        BYTE PTR es:[di],al
             jmp       SHORT _OR_Fs_1_FU
_OR_Fs_1_ZU:
             mov       al,ds:[si]
             not       al
             or        al,_mask2
             and       BYTE PTR es:[di],al
_OR_Fs_1_FU:

;----------------------------------------------------------------------------

_OR_Fs_Seconda_Pagina:

             mov       di,_di

             mov       dx,3C5h
             mov       al,2            ; seleziona la pagina 2
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 1
             mov       al,1
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _OR_Fs_2_CentroLinea

; Primo elemento
             mov       al,p2_1
             cmp       al,0
             je        _OR_Fs_2_ZP
             and       al,ds:[si]
             or        BYTE PTR es:[di],al
             jmp       SHORT _OR_Fs_2_FP
_OR_Fs_2_ZP:
             mov       al,ds:[si]
             not       al
             or        al,_mask1
             and       BYTE PTR es:[di],al
_OR_Fs_2_FP:
             inc       di



_OR_Fs_2_CentroLinea:
             mov       cx,__cx
             jcxz      _OR_Fs_2_UltimoElemento
             mov       al,p2_3
             cmp       al,0
             je        _OR_Fs_2_Z

_OR_Fs_2_NZ:
             and       al,ds:[si]
             mov       ah,al
             not       ah
_OR_Fs_Loop2:
             or        es:[di],al
             inc       di
             loop      _OR_Fs_Loop2
             jmp       SHORT _OR_Fs_2_UltimoElemento

_OR_Fs_2_Z:
             mov       al,ds:[si]
             not       al
_OR_Fs_Loop2_2:
             and       es:[di],al
             inc       di
             loop      _OR_Fs_Loop2_2



_OR_Fs_2_UltimoElemento:
             cmp       mask2,0
             je        _OR_Fs_Terza_Pagina
             mov       al,p2_2
             cmp       al,0
             je        _OR_Fs_2_ZU
             and       al,ds:[si]
             or        BYTE PTR es:[di],al
             jmp       SHORT _OR_Fs_2_FU
_OR_Fs_2_ZU:
             mov       al,ds:[si]
             not       al
             or        al,_mask2
             and       BYTE PTR es:[di],al
_OR_Fs_2_FU:

;----------------------------------------------------------------------------

_OR_Fs_Terza_Pagina:

             mov       di,_di

             mov       dx,3C5h
             mov       al,4            ; seleziona la pagina 4
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 2
             mov       al,2
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _OR_Fs_3_CentroLinea

; Primo elemento
             mov       al,p3_1
             cmp       al,0
             je        _OR_Fs_3_ZP
             and       al,ds:[si]
             or        BYTE PTR es:[di],al
             jmp       SHORT _OR_Fs_3_FP
_OR_Fs_3_ZP:
             mov       al,ds:[si]
             not       al
             or        al,_mask1
             and       BYTE PTR es:[di],al
_OR_Fs_3_FP:
             inc       di



_OR_Fs_3_CentroLinea:
             mov       cx,__cx
             jcxz      _OR_Fs_3_UltimoElemento
             mov       al,p3_3
             cmp       al,0
             je        _OR_Fs_3_Z

_OR_Fs_3_NZ:
             and       al,ds:[si]
             mov       ah,al
             not       ah
_OR_Fs_Loop3:
             or        es:[di],al
             inc       di
             loop      _OR_Fs_Loop3
             jmp       SHORT _OR_Fs_3_UltimoElemento

_OR_Fs_3_Z:
             mov       al,ds:[si]
             not       al
_OR_Fs_Loop3_2:
             and       es:[di],al
             inc       di
             loop      _OR_Fs_Loop3_2



_OR_Fs_3_UltimoElemento:
             cmp       mask2,0
             je        _OR_Fs_Quarta_Pagina
             mov       al,p3_2
             cmp       al,0
             je        _OR_Fs_3_ZU
             and       al,ds:[si]
             or        BYTE PTR es:[di],al
             jmp       SHORT _OR_Fs_3_FU
_OR_Fs_3_ZU:
             mov       al,ds:[si]
             not       al
             or        al,_mask2
             and       BYTE PTR es:[di],al
_OR_Fs_3_FU:

;----------------------------------------------------------------------------

_OR_Fs_Quarta_Pagina:

             mov       di,_di

             mov       dx,3C5h
             mov       al,8            ; seleziona la pagina 8
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 3
             mov       al,3
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _OR_Fs_4_CentroLinea

; Primo elemento
             mov       al,p4_1
             cmp       al,0
             je        _OR_Fs_4_ZP
             and       al,ds:[si]
             or        BYTE PTR es:[di],al
             jmp       SHORT _OR_Fs_4_FP
_OR_Fs_4_ZP:
             mov       al,ds:[si]
             not       al
             or        al,_mask1
             and       BYTE PTR es:[di],al
_OR_Fs_4_FP:
             inc       di



_OR_Fs_4_CentroLinea:
             mov       cx,__cx
             jcxz      _OR_Fs_4_UltimoElemento
             mov       al,p4_3
             cmp       al,0
             je        _OR_Fs_4_Z

_OR_Fs_4_NZ:
             and       al,ds:[si]
             mov       ah,al
             not       ah
_OR_Fs_Loop4:
             or        es:[di],al
             inc       di
             loop      _OR_Fs_Loop4
             jmp       SHORT _OR_Fs_4_UltimoElemento

_OR_Fs_4_Z:
             mov       al,ds:[si]
             not       al
_OR_Fs_Loop4_2:
             and       es:[di],al
             inc       di
             loop      _OR_Fs_Loop4_2



_OR_Fs_4_UltimoElemento:
             cmp       mask2,0
             je        _OR_Fs_SaltoLinea_
             mov       al,p4_2
             cmp       al,0
             je        _OR_Fs_4_ZU
             and       al,ds:[si]
             or        BYTE PTR es:[di],al
             jmp       SHORT _OR_Fs_4_FU
_OR_Fs_4_ZU:
             mov       al,ds:[si]
             not       al
             or        al,_mask2
             and       BYTE PTR es:[di],al
_OR_Fs_4_FU:

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; SALTO LINEA

_OR_Fs_SaltoLinea_:

             pop       cx
             dec       cx
             jcxz      _OR_Fs_FuoriLoop

             add       di,SaltoLinea   ; Punta sulla nuova linea
             inc       si              ; Seleziona la linea successiva del Pattern
             cmp       si,bx
             jne       _OR_Fs_Salta
             sub       si,8
_OR_Fs_Salta:
             jmp       _OR_Fs_InizioLinea



;----------------------------------------------------------------------------
_OR_Fs_FuoriLoop:
             pop       ds

             mov       dx,3C5h
             mov       al,15           ; seleziona tutte le pagine del Sequencer
             out       dx,al

             leave
             sti
             ret RetBytes





;****************************************************************************
;******************************* AND Mode ***********************************
;****************************************************************************
ANDMode:

_AND_InizioLinea:
             push      cx

             mov       _di,di

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
_AND_Prima_Pagina:

             mov       dx,3C5h
             mov       al,1            ; seleziona la pagina 1
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 0
             mov       al,0
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _AND_1_CentroLinea

; Primo elemento
             mov       al,p1_1
             and       al,ds:[si]
             or        al,_mask1
             and       BYTE PTR es:[di],al
             inc       di


_AND_1_CentroLinea:
             mov       cx,__cx
             jcxz      _AND_1_UltimoElemento
             mov       al,p1_3
             and       al,ds:[si]
_AND_Loop1:
             and       es:[di],al
             inc       di
             loop      _AND_Loop1


_AND_1_UltimoElemento:
             cmp       mask2,0
             je        _AND_Seconda_Pagina
             mov       al,p1_2
             and       al,ds:[si]
             or        al,_mask2
             and       BYTE PTR es:[di],al

;----------------------------------------------------------------------------

_AND_Seconda_Pagina:

             mov       di,_di

             mov       dx,3C5h
             mov       al,2            ; seleziona la pagina 2
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 1
             mov       al,1
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _AND_2_CentroLinea

; Primo elemento
             mov       al,p2_1
             and       al,ds:[si]
             or        al,_mask1
             and       BYTE PTR es:[di],al
             inc       di


_AND_2_CentroLinea:
             mov       cx,__cx
             jcxz      _AND_2_UltimoElemento
             mov       al,p2_3
             and       al,ds:[si]
_AND_Loop2:
             and       es:[di],al
             inc       di
             loop      _AND_Loop2


_AND_2_UltimoElemento:
             cmp       mask2,0
             je        _AND_Terza_Pagina
             mov       al,p2_2
             and       al,ds:[si]
             or        al,_mask2
             and       BYTE PTR es:[di],al

;----------------------------------------------------------------------------

_AND_Terza_Pagina:

             mov       di,_di

             mov       dx,3C5h
             mov       al,4            ; seleziona la pagina 4
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 2
             mov       al,2
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _AND_3_CentroLinea

; Primo elemento
             mov       al,p3_1
             and       al,ds:[si]
             or        al,_mask1
             and       BYTE PTR es:[di],al
             inc       di


_AND_3_CentroLinea:
             mov       cx,__cx
             jcxz      _AND_3_UltimoElemento
             mov       al,p3_3
             and       al,ds:[si]
_AND_Loop3:
             and       es:[di],al
             inc       di
             loop      _AND_Loop3


_AND_3_UltimoElemento:
             cmp       mask2,0
             je        _AND_Quarta_Pagina
             mov       al,p3_2
             and       al,ds:[si]
             or        al,_mask2
             and       BYTE PTR es:[di],al

;----------------------------------------------------------------------------

_AND_Quarta_Pagina:

             mov       di,_di

             mov       dx,3C5h
             mov       al,8            ; seleziona la pagina 8
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 3
             mov       al,3
             out       dx,al

             cmp       mask1,0FFh
             je        SHORT _AND_4_CentroLinea

; Primo elemento
             mov       al,p4_1
             and       al,ds:[si]
             or        al,_mask1
             and       BYTE PTR es:[di],al
             inc       di


_AND_4_CentroLinea:
             mov       cx,__cx
             jcxz      _AND_4_UltimoElemento
             mov       al,p4_3
             and       al,ds:[si]
_AND_Loop4:
             and       es:[di],al
             inc       di
             loop      _AND_Loop4


_AND_4_UltimoElemento:
             cmp       mask2,0
             je        _AND_SaltoLinea_
             mov       al,p4_2
             and       al,ds:[si]
             or        al,_mask2
             and       BYTE PTR es:[di],al

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; SALTO LINEA

_AND_SaltoLinea_:

             pop       cx
             dec       cx
             jcxz      _AND_FuoriLoop

             add       di,SaltoLinea   ; Punta sulla nuova linea
             inc       si              ; Seleziona la linea successiva del Pattern
             cmp       si,bx
             jne       _AND_Salta
             sub       si,8
_AND_Salta:
             jmp       _AND_InizioLinea



;----------------------------------------------------------------------------
_AND_FuoriLoop:
             pop       ds

             mov       dx,3C5h
             mov       al,15           ; seleziona tutte le pagine del Sequencer
             out       dx,al

             leave
             sti
             ret RetBytes


BarGolibW    ENDP


CODE         ENDS
             END