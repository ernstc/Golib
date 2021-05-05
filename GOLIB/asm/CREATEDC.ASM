; by Ernesto CIANCIOTTA Productions
;
; CreateDC -> CREATE Device Context

; Dichiarazione in Turbo Pascal:
;
;     procedure CreateCompatibleDC(var CA:HCA;dimX,dimY:word);
;
; Se l'operazione riesce la funzione restituisce FFFF:FFFF
; altrimenti restituisce NIL.



;---------------------- Definizione Strutture -----------------------------



HCA     STRUC
  piano1  DD  ?
  piano2  DD  ?
  piano3  DD  ?
  piano4  DD  ?
  DimXCA  DW  ?
  DimX    DW  ?
  DimY    DW  ?
HCA     ENDS



;---------------------- Definizione Costanti ------------------------------



DimMaxImmagine = 524224 ; pixels



;---------------------- Definizione Codice --------------------------------



CODE         SEGMENT BYTE PUBLIC
             ASSUME cs:CODE


             EXTRN   GetMem: NEAR     ; Procedura importata dalla RTL del TP 7


CreateCompatibleDC PROC   FAR
                   PUBLIC CreateCompatibleDC
.386
             ARG        __DimY:WORD, __DimX:WORD, CompatibleArea:DWORD= RetBytes
             LOCAL      DimSeg:WORD= LocalVariables

             enter      LocalVariables,0

             mov        ax,__DimX              ; EAX <- Larghezza immagine
             and        eax,0000FFFFh
             mov        bx,__DimY              ; EBX <- Altezza immagine
             and        ebx,0000FFFFh
             mul        ebx                    ; EDX:EAX <- EAX * Altezza Immagine
_If1_:
             cmp        edx,0                  ; Se EDX:EAX > DimMaxImmagine allora
             jne        _OperazioneFallita_    ; l'immagine Š troppo grande e
_If2_:                                         ; la funzione termina rilasciando
             cmp        eax,DimMaxImmagine     ; come risultato il valore NIL.
             jbe        _Continua1_            ; Salta se minore o uguale

_OperazioneFallita_:
             xor        ax,ax
             xor        dx,dx
             leave                             ; Operazione Fallita
             ret        RetBytes               ; FINE della FUNZIONE
_Continua1_:

; Inizializzazione di DimX e DimY nell'HCA
             les        di,CompatibleArea      ; Legge l'indirizzo dell'HCA
             mov        bx,__DimY              ; BX <- Altezza immagine
             mov        es:[di.DimY],bx        ; HCA.DimY <- BX
             mov        bx,__DimX              ; BX <- Larghezza immagine
             mov        es:[di.DimX],bx        ; HCA.DimX <- BX

             xor        dx,dx
             mov        ax,bx
             mov        cx,8
             div        cx                     ; AX <- DimX div 8
             mov        bx,dx
             mul        cx
             cmp        bx,0                   ; Se il resto della divisione
             je         _EndIF_                ; non Š 0 allora AX viene
             add        ax,8                   ; incrementata di 8 nibble.
_EndIF_:
             mov        WORD PTR es:[di.DimXCA],ax
             shr        ax,1                   ; AX <- AX div 2
             mov        bx,es:[di.DimY]
             mul        bx                     ; DX:AX <- Numero di bytes totali
                                               ; per la descrizione di tutti e
                                               ; quattro i piani.
             mov        cx,4
             div        cx                     ; In AX Š contenuto lo spazio
                                               ; di memoria sufficiente per
                                               ; un singolo piano.
             cmp        ax,0FFF8h
             ja         _OperazioneFallita_
             mov        DimSeg,ax

; Allocazione dei segmenti di memoria per i piani di colore
             REPT       4
             push       es
             push       di
             push       DimSeg                 ; DimSeg contiene la dimensione da
                                               ; allocare.
             call       GetMem
             add        di,4
             ENDM

             mov        ax,0FFFFh
             mov        dx,0FFFFh
	     leave
	     ret        RetBytes
CreateCompatibleDC ENDP

CODE         ENDS
             END