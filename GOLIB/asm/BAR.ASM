; by ERNESTO CIANCIOTTA (c) 1995

; /*********************************************************************
; \
; / Procedura BAR per la libreria GOLIB 1.0.
; \ Ver 2.0
; /
; \ N.B.: Solo per Intel 80386 e successivi.
; /
; \*********************************************************************


;---- INCLUSIONE FILES ------------------------------------------------------


INCLUDE .\register.inc


;----------------------------------------------------------------------------


DATA         SEGMENT WORD PUBLIC
             ASSUME ds:DATA

             EXTRN MaxXResolution:WORD

DATA         ENDS




wmNormal = 00h
wmAND    = 08h
wmOR     = 10h
wmXOR    = 18h





CODE         SEGMENT BYTE PUBLIC
             ASSUME cs:CODE

BarGoLIB     PROC   FAR
             PUBLIC BarGoLIB
             ARG    WriteMode:BYTE, colore, DimY, DimX, n1, m1:WORD= RetBytes
             LOCAL  XResB:WORD, a_pos_x1, __cx, SaltoLinea:WORD, mask1:BYTE,_mask1:BYTE,mask2:BYTE,_mask2:BYTE,__bh:BYTE,__bl:BYTE= VariabiliLocali
             .386
             cli
             enter     VariabiliLocali,0

; PRIMA FASE DI INIZIALIZZAZIONE


; XResB = MaxXResolution div 8
             mov       ax,MaxXResolution
             shr       ax,3
             mov       XResB,ax

; a_pos_x1 = ( m1 div 8)+XResB*n1
             mov       ax,m1
             shr       ax,3
             mov       bx,ax          ; bx = m1 div 8
             mov       ax,n1
             mul       XResB
             add       ax,bx          ; bx = m1 div 8
             mov       a_pos_x1,ax

; __cx = [(m1+DimX-1) div 8] - (m1 div 8) - 1
             mov       ax,m1
             add       ax,DimX
             dec       ax
             shr       ax,3
             sub       ax,bx          ; bx = m1 div 8
             dec       ax
             mov       __cx,ax

; SaltoLinea = XResB-2-__cx
             mov       bx,XResB
             dec       bx
             dec       bx
             sub       bx,ax           ; ax = __cx
             mov       SaltoLinea,bx

; SECONDA FASE DI INIZIALIZZAZIONE

             mov       cl,8

; preparazione degli shifts per l'elemento pi� a sinistra
             mov       ax,m1
             div       cl              ; cl = 8
             mov       bh,ah

; preparazione degli shifts per l'elemento pi� a destra
             mov       ax,m1
             add       ax,DimX
             div       cl              ; cl = 8
             mov       bl,8
             sub       bl,ah

; preparazione delle maschere per le estremit� della linea
             mov       al,0FFh
             mov       cl,bh
             shr       al,cl
             mov       bh,al           ; assegnamento di mask1

             mov       al,0FFh
             mov       cl,bl
             shl       al,cl
             mov       bl,al           ; assegnamento di mask2

             or        bl,bl           ; Controlla se mask2 = 0
             jnz       _Dopo__
             mov       al,0FFh

_Dopo__:
             cmp       __cx,0FFFFh     ; Controlla se __cx = -1, ossia se a_pos_x1 = a_pos_x2
             jne       _EndIF_
             and       bh,al           ; Maschera mask1 con mask2
             xor       bl,bl

_EndIF_:

; A questo punto BH = mask1 e BL = mask2

             or        bh,bh
             jnz       _Controllo2_
             inc       __cx
             dec       SaltoLinea
_Controllo2_:
             or        bl,bl
             jnz       DisegnoBarra
             inc       __cx


DisegnoBarra:

; PROCESSO DI DISEGNO DELLA BARRA
             cld
             push      0A000h
             pop       es
             mov       di,a_pos_x1
             mov       cx,DimY

; Selezione di tutti piani di colore: Map Mask Reg = 0Fh

             SetSequReg  2,0Fh

; Impostazione della modalit� di scrittura: Write Mode Reg = 0

             SetGraphReg 5,0

; Attivazione della funzione Set/Reset

             SetGraphReg 1,0Fh

; Impostazione del Set/Reset Register
             __ResetAddress
             inc       dx
             mov       ax,colore
             out       dx,al

; Impostazione della modalit� logica di scrittura : Normal, AND, OR, XOR
; L'impostazione avviene andando a modificare il Data Rotate Reg.
             __SetAddress 3

             inc       dx
             mov       al,WriteMode
             and       al,18h
             out       dx,al

; Imposta l'indirizzo del Bit Mask Reg
             __SetAddress 8
             inc       dx               ; Indirizzo della porta Dati

; DISEGNO DELLA BARRA

__InizioLinea:
             push      cx
             or        bh,bh            ; Controlla se mask1 = 0
             jz        __RestoLinea

; Bit Mask per il primo elemento
             mov       al,bh
             out       dx,al
             mov       al,BYTE PTR es:[di]
             stosb

__RestoLinea:
             mov       cx,__cx
             jcxz      __UltimoElemento

; Bit Mask = 0FFh
             mov       al,0FFh
             out       dx,al
             cmp       WriteMode,wmNormal
             jne       _001_
             rep       stosb
             jmp       SHORT __UltimoElemento
   _001_:
             mov       al,BYTE PTR es:[di]
             stosb
             loop      _001_

__UltimoElemento:
             or        bl,bl            ; Controlla se mask2 = 0
             jz        __SaltoLinea

; Bit Mask per l'ultimo elemento
             mov       al,bl
             out       dx,al
             mov       al,BYTE PTR es:[di]
             stosb

__SaltoLinea:
             add       di,SaltoLinea
             pop       cx
             loop      __InizioLinea

; Ripristina il Bit Mask Reg a 0FFh
             mov       al,0FFh
             out       dx,al

; Disabilitazione della funzione Set/Reset
             __SetAddress 1
             __ResetData

; Impostazione della modalit� logica di scrittura a Normal
             __SetAddress 3
             __ResetData

             leave
             sti
             ret       RetBytes

BarGoLIB     ENDP


CODE         ENDS
             END