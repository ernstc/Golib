; by ERNESTO CIANCIOTTA (c) 1995

; /*********************************************************************
; \
; / Procedura di per la trattazione dei fonts bitmapped formato Windows(TM).
; \ Questa procedura trasforma un carattere in stile normale in stile
; / corsivo.
; \
; /
; \ VERSIONE DEFINITIVA  1.0.
; /
; \ N.B.: Solo per Intel 80386 e successivi.
; /
; \*********************************************************************

;------------------------ Definizione Codice -------------------------------



CODE         SEGMENT BYTE PUBLIC
             ASSUME cs:CODE



             EXTRN   GetMem: NEAR     ; Procedura importata dalla RTL del TP 7



ItalicChar   PROC NEAR
             PUBLIC ItalicChar
             ARG    NewWidth:DWORD, italic:DWORD, SHeight:WORD, SWidth:WORD, source:DWORD= RetBytes

             LOCAL  Mem,colonne=VariabiliLocali
.386
             enter     VariabiliLocali,0
             push      ds

; NewWidth = BX = SWidth + (SWidth div 2) +1
             mov       ax,SWidth
             mov       bx,ax
             shr       ax,1                 ; AX = AX div 2
             add       bx,ax
             les       di,NewWidth
             mov       WORD PTR es:[di],bx  ; NewWidth = BX

; colonne = (BX + 7) div 8
             mov       ax,bx
             add       ax,7
             shr       ax,3                 ; AX = AX div 8
             mov       colonne,ax

; Mem = SHeight * colonne
             mov       cx,SHeight
             mul       cx
             mov       Mem,ax

; allocazione dinamica della memoria per il carattere in
; corsivo
             les       di,italic
             push      es
             push      di
             push      ax                   ; AX contiene la dimensione
                                            ; da allocare.
             call       GetMem



FineProc:
             mov       ax,Mem

             pop       ds

             leave
             ret       RetBytes
ItalicChar   ENDP



CODE         ENDS
             END