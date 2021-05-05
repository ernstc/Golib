; by ERNESTO CIANCIOTTA (c) 1995

; /*********************************************************************
; \
; / Procedura di shifting di 8bits o multipli di 8 verso destra con copia
; \ orizzontale inversa degli elementi delle linee (da destra a sinistra).
; /
; \ La copia delle linee avviene dal basso verso l'alto. ("I"ndiretta)
; /
; \ VERSIONE DEFINITIVA   1.0.
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

BitBtlMoveRI8  PROC NEAR
             PUBLIC BitBtlMoveRI8
             ARG    DimY, DimX, a_y1_, a_x1_, da_y1_, da_x1_:WORD= RetBytes
             LOCAL  XResB:WORD,da_pos_x2, a_pos_x2, da_pos_x1, a_pos_x1, __cx, SaltoLinea:WORD, mask2:BYTE,_mask2:BYTE,__bl:BYTE,caso__cx:BYTE= VariabiliLocali
             .386
             enter     VariabiliLocali,0

; PRIMA FASE DI INIZIALIZZAZIONE

; XResB = MaxXResolution div 8
             mov       ax,MaxXResolution
             xor       dx,dx
             mov       cx,8
             div       cx
             mov       XResB,ax

; a_pos_x1 = ( a_x1_ div 8)+XResB*a_y1_
             mov       ax,a_x1_
             xor       dx,dx           ; dx = 0000h
             div       cx              ; cx = 8
             mov       bx,ax
             mov       ax,a_y1_
             mul       XResB           ; bx = XResB*a_y1_
             xchg      ax,bx
             add       ax,bx
             mov       a_pos_x1,ax

; a_pos_x2 = [(a_x1_+DimX-1) div 8]+XResB*a_y1_
             mov       ax,a_x1_
             add       ax,DimX
             dec       ax              ; ax = a_x1_+DimX-1
             xor       dx,dx           ; dx = 0000h
             div       cx              ; cx = 8
             add       ax,bx           ; bx = XResB*a_y1_
             mov       a_pos_x2,ax

; da_pos_x1 = ( da_x1_ div 8)+XResB*da_y1_
             mov       ax,da_x1_
             xor       dx,dx           ; dx = 0000h
             div       cx              ; cx = 8
             mov       bx,ax
             mov       ax,da_y1_
             mul       XResB           ; bx = XResB*da_y1_
             xchg      ax,bx
             add       ax,bx
             mov       da_pos_x1,ax

; da_pos_x2 = [(da_x1_+DimX-1) div 8]+XResB*da_y1_
             mov       ax,da_x1_
             add       ax,DimX
             dec       ax              ; ax = da_x1_+DimX-1
             xor       dx,dx           ; dx = 0000h
             div       cx              ; cx = 8
             add       ax,bx           ; bx = XResB*da_y1_
             mov       da_pos_x2,ax

; SECONDA FASE DI INIZIALIZZAZIONE

; preparazione degli shifts per l'elemento pi— a destra
             mov       ax,a_x1_
             add       ax,DimX
             div       cl              ; cl = 8
             mov       bl,8
             sub       bl,ah
; preparazione delle maschere per le estremit… della linea
             mov       al,0FFh
             mov       cl,bl
             shl       al,cl
             mov       mask2,al        ; assegnamento di mask2
             not       al
             mov       _mask2,al       ; assegnamento di _mask2


; __cx = da_pos_x2 - da_pos_x1
             mov       ax,da_pos_x2
             sub       ax,da_pos_x1
             cmp       mask2,0
             jne       _Dopo___
             inc       ax
_Dopo___:
             mov       __cx,ax

; SaltoLinea = XResB-1-__cx
             mov       bx,XResB
             dec       bx
             sub       bx,__cx         ; ax = __cx (originale)
             cmp       mask2,0
             jne       _Dopo____
             inc       bx
_Dopo____:
             mov       SaltoLinea,bx

; da_pos_x2 = da_pos_x2 + (DimY - 1)*XResB
             mov       ax,DimY         ; con DimY > 0
             dec       ax
             mul       XResB           ; ax = (DimY - 1)*XResB
             add       da_pos_x2,ax

; a_pos_x2 = a_pos_x2 + (DimY - 1)*XResB
             add       a_pos_x2,ax     ; ax = (DimY - 1)*XResB


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

CopiaPagina:

; PROCESSO DI COPIA DELLE PAGINE VIDEO
             std                       ; direzione inversa
             push      ds

             mov       dx,0A000h
             mov       es,dx
             mov       ds,dx
             mov       di,a_pos_x2
             mov       si,da_pos_x2
             mov       cx,DimY         ; cx = Numero di linee

InizioLinea:
             push      cx

             cmp       mask2,0
             je        RestoLinea

             mov       dx,3C4h
             mov       al,2
             out       dx,al           ; seleziona il registro delle pagine attive
             mov       dx,3CEh
             mov       al,4
             out       dx,al           ; seleziona il GDC index a 4

;----------------------------------------------------------------------------
; Selezione Prima Pagina
             mov       dx,3C5h
             mov       al,1            ; seleziona la pagina 1
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 0
             mov       al,0
             out       dx,al

; COPIA LINEA
; Sistemazione dell'ultimo elemento
             mov       al,BYTE PTR ds:[si]   ; al = BYTE PTR ds:[si]
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

; COPIA LINEA
; Sistemazione dell'ultimo elemento
             mov       al,BYTE PTR ds:[si]   ; al = BYTE PTR ds:[si]
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
             mov       al,4            ; seleziona la pagina 3
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 2
             mov       al,2
             out       dx,al

; COPIA LINEA
; Sistemazione dell'ultimo elemento
             mov       al,BYTE PTR ds:[si]   ; al = BYTE PTR ds:[si]
             db        36              ; opcode di AND AL,<n>
__3_par_001:
             db        0
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__3_par_002:
             db        0
             or        BYTE PTR es:[di],al   ; sistema l'elemento

;----------------------------------------------------------------------------
; QuartaPagina
             mov       dx,3C5h
             mov       al,8            ; seleziona la pagina 4
             out       dx,al
             mov       dx,3cfh         ; setta il GDC data a 3
             mov       al,3
             out       dx,al

; COPIA LINEA
; Sistemazione dell'ultimo elemento
             lodsb                     ; al = BYTE PTR ds:[si]
             db        36              ; opcode di AND AL,<n>
__4_par_001:
             db        0
             db        38,128,37       ; opcode di AND BYTE PTR ES:[DI],<n>
__4_par_002:
             db        0
             or        BYTE PTR es:[di],al   ; sistema l'elemento

             dec       di

;----------------------------------------------------------------------------

; Sistemazione del resto della linea
RestoLinea:
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
             out       dx,al           ; setta il GDC data a 1

             mov       cx,__cx
             rep       movsb

             mov       dx,3cfh
             mov       al,0
             out       dx,al           ; setta il GDC data a 1

;----------------------------------------------------------------------------
; SALTO LINEA

             sub       di,SaltoLinea
             sub       si,SaltoLinea
             pop       cx
             dec       cx
             jcxz      FuoriLoop
             jmp       InizioLinea


;----------------------------------------------------------------------------
FuoriLoop:
             pop       ds

             leave
             ret RetBytes
BitBtlMoveRI8    ENDP


CODE         ENDS
             END
