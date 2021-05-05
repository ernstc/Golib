; by ERNESTO CIANCIOTTA (c) 1995

; /*********************************************************************
; \
; / Procedura BAR per la libreria GOLIB 10.
; \
; /
; \ N.B.: Solo per Intel 80386 e successivi.
; /
; \*********************************************************************

DATA         SEGMENT WORD PUBLIC
             ASSUME ds:DATA

             EXTRN MaxXResolution:WORD

DATA         ENDS




CODE         SEGMENT BYTE PUBLIC
             ASSUME cs:CODE

BarGoLIB_old PROC   FAR
             PUBLIC BarGoLIB_old
             ARG    colore, DimY, DimX, n1, m1:WORD= RetBytes
             LOCAL  XResB:WORD,p1_1:BYTE,p2_1:BYTE,p3_1:BYTE,p4_1:BYTE,p1_2:BYTE,p2_2:BYTE,p3_2:BYTE,p4_2:BYTE, _di,_si, a_pos_x2, a_pos_x1, __cx, SaltoLinea:WORD, mask1:BYTE,_mask1:BYTE,mask2:BYTE,_mask2:BYTE,__bh:BYTE,__bl:BYTE= VariabiliLocali
             .386
             cli
             enter     VariabiliLocali,0

; PRIMA FASE DI INIZIALIZZAZIONE


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

; XResB = MaxXResolution div 8
             mov       ax,MaxXResolution
             shr       ax,3
             mov       XResB,ax

; a_pos_x1 = ( m1 div 8)+XResB*n1
             mov       ax,m1
             shr       ax,3
             mov       bx,ax
             mov       ax,n1
             mul       XResB           ; bx = XResB*n1
             xchg      ax,bx
             add       ax,bx
             mov       a_pos_x1,ax

; a_pos_x2 = [(m1+DimX-1) div 8]+XResB*n1
             mov       ax,m1
             add       ax,DimX
             dec       ax              ; ax = m1+DimX-1
             shr       ax,3
             add       ax,bx           ; bx = XResB*n1
             mov       a_pos_x2,ax

; __cx = a_pos_x2 - a_pos_x1 - 1
             mov       ax,a_pos_x2
             sub       ax,a_pos_x1
             dec       ax
             mov       __cx,ax

; SaltoLinea = XResB-2-__cx
             mov       bx,XResB
             dec       bx
             dec       bx
             sub       bx,ax           ; ax = __cx
             mov       SaltoLinea,bx

; SECONDA FASE DI INIZIALIZZAZIONE

             mov       cx,8

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
             mov       _mask1,bl
             mov       mask2,0

; scomposizione del colore

Scomposizione:
             mov       ax,colore
; 1ø Piano
             shr       al,1
             jnc       _1_Vuoto
             mov       p1_1,bh
             mov       p1_2,bl
             jmp       SHORT _1_Pieno
_1_Vuoto:
             mov       p1_1,0
             mov       p1_2,0
_1_Pieno:

; 2ø Piano
             shr       al,1
             jnc       _2_Vuoto
             mov       p2_1,bh
             mov       p2_2,bl
             jmp       SHORT _2_Pieno
_2_Vuoto:
             mov       p2_1,0
             mov       p2_2,0
_2_Pieno:

; 3ø Piano
             shr       al,1
             jnc       _3_Vuoto
             mov       p3_1,bh
             mov       p3_2,bl
             jmp       SHORT _3_Pieno
_3_Vuoto:
             mov       p3_1,0
             mov       p3_2,0
_3_Pieno:

; 4ø Piano
             shr       al,1
             jnc       _4_Vuoto
             mov       p4_1,bh
             mov       p4_2,bl
             jmp       SHORT _4_Pieno
_4_Vuoto:
             mov       p4_1,0
             mov       p4_2,0
_4_Pieno:


             cmp       mask1,0
             jne       _Controllo2_
             inc       __cx
             dec       SaltoLinea
_Controllo2_:
             cmp       mask2,0
             jne       CopiaPagina
             inc       __cx


CopiaPagina:

; PROCESSO DI COPIA DELLE PAGINE VIDEO
             cld
             push      ds

             mov       dx,0A000h
             mov       es,dx
             mov       di,a_pos_x1
             mov       cx,DimY         ; cx = Numero di linee

             mov       dx,3C4h
             mov       al,2
             out       dx,al           ; seleziona il registro delle pagine attive
             mov       dx,3CEh
             mov       al,4
             out       dx,al           ; seleziona il GDC index a 4


; Auto-parametrizzazione del codice
             mov       al,_mask2
             mov       BYTE PTR cs:__1_Not_mask2,al
             mov       BYTE PTR cs:__2_Not_mask2,al
             mov       BYTE PTR cs:__3_Not_mask2,al
             mov       BYTE PTR cs:__4_Not_mask2,al

             mov       al,_mask1
             mov       BYTE PTR cs:__1_Not_mask1,al
             mov       BYTE PTR cs:__2_Not_mask1,al
             mov       BYTE PTR cs:__3_Not_mask1,al
             mov       BYTE PTR cs:__4_Not_mask1,al


__InizioLinea:
             push      cx

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

             cmp       mask1,0
             je        SHORT RestoLinea

; Selezione Prima Pagina
             mov       dx,3C5h
             mov       al,1            ; seleziona la pagina 1
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 0
             mov       al,0
             out       dx,al

; Sistemazione del primo elemento

             mov       al,p1_1
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__1_Not_mask1:
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

             mov       al,p2_1
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__2_Not_mask1:
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

             mov       al,p3_1
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__3_Not_mask1:
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

             mov       al,p4_1
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__4_Not_mask1:
             db        0
             or        BYTE PTR es:[di],al

             inc       di

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

RestoLinea:

; Sistemazione degli elementi del centro della linea
             mov       cx,__cx
             jcxz      __UltimoElemento

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
             mov       al,2
             out       dx,al           ; seleziona la modalit… 2

             mov       ax,colore
             rep       stosb

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
__UltimoElemento:
             cmp       mask2,0
             je        _SaltoLinea_


; Selezione Prima Pagina
             mov       dx,3C5h
             mov       al,1            ; seleziona la pagina 1
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 0
             mov       al,0
             out       dx,al

; Sistemazione dell'ultimo elemento
             mov       al,p1_2
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__1_Not_mask2:
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
             mov       al,p2_2
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__2_Not_mask2:
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
             mov       al,p3_2
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__3_Not_mask2:
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
             mov       al,p4_2
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__4_Not_mask2:
             db        0
             or        BYTE PTR es:[di],al   ; sistema l'elemento

             inc       di


;----------------------------------------------------------------------------
; SALTO LINEA

_SaltoLinea_:

             add       di,SaltoLinea
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
             sti
             ret RetBytes
BarGoLIB_old ENDP


CODE         ENDS
             END