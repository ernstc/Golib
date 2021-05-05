; by ERNESTO CIANCIOTTA (c) 1995

; /*********************************************************************
; \
; / File di utilit… per effettuare alcuni esperimenti sui programmi
; \ Assembler.
; /
; \*********************************************************************

;------------------------ Definizione Codice -------------------------------


DATA         SEGMENT WORD PUBLIC
             ASSUME ds:DATA

             LastEv DD ?

DATA         ENDS


CODE         SEGMENT BYTE PUBLIC
             ASSUME cs:CODE



             PUBLIC Utile



Utile        PROC NEAR
             ;ARG    = RetBytes
             ;LOCAL  =VariabiliLocali
.386p
             ;enter     VariabiliLocali,0
             push      ds

; ********************************************************
; Corpo della procedura
; --------------------------------------------------------

             mov    DWORD PTR [si],0
             mov    DWORD PTR [si+4],0


         cld
         push     ds
         pop      es
         lea      di,LastEv
         xor      ax,ax
         mov      cx,4
         rep      stosw

             db     '****'
             mov    ax,1
             int    33h
             db     '****'


; ********************************************************

             pop       ds
             leave
             ret       ;RetBytes
Utile        ENDP



CODE         ENDS
             END