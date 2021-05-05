; by ERNESTO CIANCIOTTA (c) 1995

; /*********************************************************************
; \
; / Rilevatore dei cambiamenti di stato delle periferiche di input.
; \ Tali periferiche sono la testiera e il mouse.
; /
; \ Ver 2.0
; /
; \ N.B.: Solo per Intel 80386 e successivi.
; /
; \*********************************************************************


;---------------------- Definizione Strutture -----------------------------


                          ; Mouse            | Tastiera
TDevInfo  STRUC           ;------------------|---------------------
   Byte1         DB  ?    ; Button Status    | 0
   Word0         DW  ?    ; TimeCounter      | 0
   Word1         DW  ?    ; X coord.         | 0
   Word2         DW  ?    ; Y coord.         | Key Stroke
   Word3         DW  ?    ; KB Shifts        | KB Shifts
TDevInfo  ENDS




;---------------------- Definizione Dati ----------------------------------


DATA         SEGMENT WORD PUBLIC
             ASSUME ds:DATA

; *** Variabili ESTERNE ***

             EXTRN IDevDelayC : WORD
             EXTRN KBDelayC   : WORD
             EXTRN MMDelayC   : WORD
             EXTRN MBDelayC   : WORD
             EXTRN TimeCounter: DWORD

             EXTRN PressDelayL : WORD
             EXTRN PressDelayR : WORD
             EXTRN PressDelayC : WORD
             EXTRN ReleaseDelayL : WORD
             EXTRN ReleaseDelayR : WORD
             EXTRN ReleaseDelayC : WORD

             EXTRN MultipleMClickDelay :WORD

             EXTRN precMCX       : WORD
             EXTRN precMCY       : WORD
             EXTRN precBtnStatus : BYTE

             EXTRN _Get_Int_    : BYTE
             EXTRN _Check_Int_  : BYTE
             EXTRN _Shifts_Int_ : BYTE

             EXTRN DevInfoBuffer : BYTE

             EXTRN OTBuffer_Alloc : DWORD


; *** Variabili INTERNE ***

             EvScanStoped    DB     0

             precShifts      DW     0

             LastDeviceInfo  TDevInfo ?

DATA         ENDS


;---------------------- Definizione Codice --------------------------------


CODE         SEGMENT BYTE PUBLIC
             ASSUME cs:CODE

             PUBLIC  EventController
             PUBLIC  EventCtrlSetup
             PUBLIC  StopEvScanning
             PUBLIC  StartEvScanning

.386

;  Gestore dell'applicazione

EventController  PROC   FAR

IntHeader:
             nop

; Disattiva l'ingresso all'interrupt mettendo come prima istruzione IRET.
; In questo modo ogni volta che l'int 1Ch verrÖ chiamato durante l'esecuzione
; non accadra nulla.

             mov        BYTE PTR IntHeader,0CFh

             mov ax,1
             mov bx,2
             mov cx,3
             mov dx,4
             mov si,5
             mov di,6

             pusha
             push       ds
             push       es

; MOV AX,<WORD che identifica il Segmento Dati>
             db         0B8h
_DataSeg_:
             dw         ?

             mov        ds,ax
             sti


; incremento dei contatori
             inc 	IDevDelayC
             inc 	KBDelayC
             inc 	MMDelayC
             inc	MBDelayC
             inc        TimeCounter
             cmp        BYTE PTR TimeCounter,0
             jnz        Continua
             inc        TimeCounter
Continua:

; contatori per il clicking multiplo
             inc 	PressDelayL            ; Left
             inc 	PressDelayR            ; Right
             inc 	PressDelayC            ; Center
             inc 	ReleaseDelayL          ; Left
             inc 	ReleaseDelayR          ; Right
             inc 	ReleaseDelayC          ; Center

; controllo verifica eventi della tastiera
_KeyCtrl_:
             mov        ah,_Shifts_Int_
             int        16h
             push       ax                     ; Salva gli shifts
             mov        dx,ax                  ; DX = Shifts
             mov        ah,_Check_Int_
             int        16h                    ; Check for KeyStrokes
      	     jnz      	_AllocKeyEv_           ; Se non vuoto allora memorizza
             cmp        dx,precShifts          ; Controlla se ä cambiato qualche shift
             je         _MouseCtrl_            ; Se uguale allora passa al controllore
                                               ;  del mouse perchä non c'e nessun
                                               ;  evento dalla tastiera.
             xor        ax,ax
             jmp        SHORT _EndIf2_         ; Se sono cambiati solo gli shifts
                                               ;  non effettua le READKEYs.
_AllocKeyEv_:
             mov        ah,_Get_Int_
             int        16h                    ; Reads the Key Stroke
_EndIf2_:
             mov        si,sp
             sub        si,7
             push       ax                     ; Key Stroke
             push       1
             push       2
             push       0300h
             mov        precShifts,dx          ; Memorizza gli Shifts
             push       ss
             push       si
             push       ds
             push       OFFSET DevInfoBuffer
             call    	OTBuffer_Alloc
             add        sp,10
             jmp        SHORT _FineEvCtrl_

; controllo verifica eventi del mouse
_MouseCtrl_:
             mov 	ax,03h
             int        33h
             and        bl,07h
             cmp        precBtnStatus,bl
             jne        _AllocMouseEv_
             cmp        precMCX,cx
             jne        _AllocMouseEv_
             cmp        precMCY,dx
             jne        _AllocMouseEv_
             pop        ax                     ; Recupera gli shifts
             jmp        SHORT _FineEvCtrl_

_AllocMouseEv_:
             mov        precBtnStatus,bl
             mov        precMCX,cx
             mov        precMCY,dx
             mov        si,sp
             sub        si,7
             push       dx                     ; Y
             push       cx                     ; X
             push       WORD PTR TimeCounter   ; Time Counter
             push       bx                     ; Button Status
             push       ss
             push       si
             push       ds
             push       OFFSET DevInfoBuffer
             call    	OTBuffer_Alloc
             add        sp,10
             jmp        SHORT _FineEvCtrl_

_FineEvCtrl_:
             pop        es
             pop        ds
             popa
             cli
             push       ax

; MOV AL,<ISTRUZIONE da inserire in IntHeader>
             db         0B0h
AutoProg2:
             db         090h

; Riattiva l'ingresso all'interrupt mettendo come prima istruzione NOP.
             mov        BYTE PTR IntHeader,al

             pop        ax
             iret

EventController ENDP



;*****************************************************************************



;  Procedura che deve essere chiamata prima che EventController venga collegata
;  all'interrupt 1Ch. La sua funzione ä di impostare dei parametri sul codice
;  di EventController.

EventCtrlSetup  PROC   NEAR

             mov        WORD PTR _DataSeg_,ds
             mov        ah,_Shifts_Int_
             int        16h
             mov        precShifts,ax
             mov        ax,0003
             int        33h
             mov        precBtnStatus,bl
             mov        precMCX,cx
             mov        precMCY,dx
             retn

EventCtrlSetup  ENDP



;*****************************************************************************


; Procedura per bloccare la scansione degli eventi.

StopEvScanning  PROC   FAR

             mov        BYTE PTR EvScanStoped,1

; Disattiva EventController in modo permanente affinchä l'istruzione
; che si auto imposta per riattivarsi sia IRET invece di NOP.
             mov        BYTE PTR AutoProg2,0CFh
             retf

StopEvScanning  ENDP


;--------------------------------------------------------------------------


; Procedura per ripristinare la scansione degli eventi.

StartEvScanning  PROC   FAR

             cmp        BYTE PTR EvScanStoped,1
             jne        _FineStartScan_

; Attiva EventController facendo in modo che l'istruzione che si auto imposta
; per riattivarsi sia NOP e ripristinando l'intestazione.
             mov        BYTE PTR IntHeader,090h
             mov        BYTE PTR AutoProg2,090h

             mov        BYTE PTR EvScanStoped,0

_FineStartScan_:
             retf

StartEvScanning  ENDP



;*****************************************************************************




CODE         ENDS
             END