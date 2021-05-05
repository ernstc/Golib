; by Ernesto CIANCIOTTA Productions
;
; CreateCA -> CREATE Compatible Area

; Dichiarazione in Turbo Pascal:
;
;     function CreateCompatibleArea(var CompatibleArea:pointer;
;                                   var BitMap):pointer;
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



;---------------------- Definizione Macro ---------------------------------



TRASFORMA_PAGINA MACRO pagina,bit1,bit2,bit3,bit4,bit5,bit6,bit7,bit8

                 les        di,CompatibleArea      ; Legge l'indirizzo
                                                   ; dell'HCA
                 mov        cx,WORD PTR es:[di.DimY]
                 les        di,es:[di.piano&pagina&]
                                                   ; Carica l'indirizzo della
                                                   ; pagina nello HEAP
                 push       si
LoopEsterno&pagina&:
                 push       cx
                 mov        cx,bx
LoopInterno&pagina&:
                 IRP BitCmp,<bit1,bit2,bit3,bit4,bit5,bit6,bit7,bit8>
                 bt         DWORD PTR [si],BitCmp
	         rcl        al,1
                 ENDM
	         stosb
                 add        si,4
                 loop       LoopInterno&pagina&

                 sub        si,_2BytesL4
	         pop        cx
	         loop       LoopEsterno&pagina&
                 pop        si

                 ENDM



;---------------------- Definizione Codice --------------------------------



CODE         SEGMENT BYTE PUBLIC
             ASSUME cs:CODE


             EXTRN   GetMem: NEAR     ; Procedura importata dalla RTL del TP 7


CreateCompatibleArea PROC   FAR
                     PUBLIC CreateCompatibleArea
.386
             ARG        BitMap:DWORD, CompatibleArea:DWORD= RetBytes
             LOCAL      _ds:WORD,OrigDescr:WORD,_2BytesL4:WORD,BytesL4:WORD,DimSeg:WORD,_si:WORD,__cl:BYTE = LocalVariables

             enter      LocalVariables,0
             push       ds
             mov        _ds,ds
             cld

             lds        si,BitMap              ; Legge l'indirizzo di BitMap
             mov        eax,DWORD PTR [si+18]  ; EAX <- Larghezza immagine
             mul        DWORD PTR [si+22]      ; EDX:EAX <- EAX * Altezza Immagine
_If1_:
             cmp        edx,0                  ; Se EDX:EAX > DimMaxImmagine allora
             jne        _OperazioneFallita_    ; l'immagine Š troppo grande e
_If2_:                                         ; la funzione termina rilasciando
             cmp        eax,DimMaxImmagine     ; come risultato il valore NIL.
             jbe        _Continua1_            ; Salta se minore o uguale

_OperazioneFallita_:
             xor        ax,ax
             xor        dx,dx
             pop        ds
             leave                             ; Operazione Fallita
             ret        RetBytes               ; FINE della FUNZIONE
_Continua1_:

; Inizializzazione di DimX e DimY nell'HCA
             les        di,CompatibleArea      ; Legge l'indirizzo dell'HCA
             mov        ebx,DWORD PTR [si+22]  ; BX <- Altezza immagine
             mov        es:[di.DimY],bx        ; HCA.DimY <- BX
             mov        ebx,DWORD PTR [si+18]  ; BX <- Larghezza immagine
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
             mov        BytesL4,ax             ; Bytes per una linea di 4 piani
             mov        bx,es:[di.DimY]
             mul        bx                     ; DX:AX <- Numero di bytes totali
                                               ; per la descrizione di tutti e
                                               ; quattro i piani.
             mov        OrigDescr,ax
             mov        cx,4
             div        cx                     ; In AX Š contenuto lo spazio
                                               ; di memoria sufficiente per
                                               ; un singolo piano.
             cmp        ax,0FFF8h
             ja         _OperazioneFallita_
             mov        DimSeg,ax
             mov        ax,_ds
             mov        ds,ax

; Allocazione dei segmenti di memoria per i piani di colore
             REPT       4
             push       es
             push       di
             push       DimSeg                 ; DimSeg contiene la dimensione da
                                               ; allocare.
             call       GetMem
             add        di,4
             ENDM
             sub        di,16

             lds        si,BitMap              ; Legge l'indirizzo di BitMap
             add        si,118                 ; Posiziona DS:SI all'inizio
                                               ; della descrizione originale
                                               ; del BITMAP.
             add        si,OrigDescr           ; Posiziona sull'ultimo byte di BitMap
             sub        si,BytesL4             ; Posiziona DS:SI all'inizio
                                               ; della prima linea del BITMAP.

; PROCESSO DI TRASFORMAZIONE

             mov        bx,BytesL4
             mov        _2BytesL4,bx
             shl        _2BytesL4,1            ; _2BytesL4 <- _2BytesL4 * 2
             shr        bx,2                   ; BX <- BX div 4 Questo poter
                                               ; effettuare all'interno del
                                               ; LoopInterno una scansione
                                               ; a 4 bytes alla volta.
             TRASFORMA_PAGINA  1,4,0,12,8,20,16,28,24
             TRASFORMA_PAGINA  2,5,1,13,9,21,17,29,25
             TRASFORMA_PAGINA  3,6,2,14,10,22,18,30,26
             TRASFORMA_PAGINA  4,7,3,15,11,23,19,31,27

             mov        ax,0FFFFh
             mov        dx,0FFFFh
	     pop        ds
	     leave
	     ret        RetBytes
CreateCompatibleArea ENDP

CODE         ENDS
             END