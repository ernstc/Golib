; by ERNESTO CIANCIOTTA (c) 1995

; /*********************************************************************
; \
; / Event Controller 1.0
; \
; /
; \ N.B.: Solo per Intel 80386 e successivi.
; /
; \*********************************************************************


;---------------------- Definizione Strutture -----------------------------



TMessageMouse  STRUC
  HNDL           DW  ?
  Message        DW  ?
  Shifts         DW  ?
  Clicks         DB  ?
  Mcx            DW  ?
  Mcy            DW  ?
TMessageMouse  ENDS


TMessageKeyB   STRUC
  HNDL           DW  ?
  Message        DW  ?
  Shifts         DW  ?
  KeyStroke      DW  ?
TMessageKeyB   ENDS



;---------------------- Definizione Dati ----------------------------------


DATA         SEGMENT WORD PUBLIC
             ASSUME ds:DATA

             EXTRN IDevDelayC : WORD
             EXTRN KBDelayC   : WORD
             EXTRN MMDelayC   : WORD
             EXTRN MBDelayC   : WORD

             EXTRN TimeCounter: DWORD

             EXTRN MultipleMClickDelay :WORD

             EXTRN DelayActive : BYTE

             EXTRN PressDelayL : WORD
             EXTRN PressDelayR : WORD
             EXTRN PressDelayC : WORD

             EXTRN ReleaseDelayL : WORD
             EXTRN ReleaseDelayR : WORD
             EXTRN ReleaseDelayC : WORD

             EXTRN btnInfo : BYTE

             EXTRN LastSysMessage : TMessageKeyB

             EXTRN _Get_Int_    : BYTE
             EXTRN _Check_Int_  : BYTE
             EXTRN _Shifts_Int_ : BYTE


; function GetShiftFlags: word;
             EXTRN   GetShiftFlags : DWORD

             EvScanStoped    DB     0

             precShifts      DW     0



; -- Costanti -----

EvKEYBOARD              = 003Ah
SYSTEM_SENDER           = 0000h


DATA         ENDS


;---------------------- Definizione Codice --------------------------------


CODE         SEGMENT BYTE PUBLIC
             ASSUME cs:CODE

             EXTRN   MouseEventController: NEAR
             EXTRN   PutMessageInBuffer: NEAR

             PUBLIC  EventController
             PUBLIC  CounterRoutine
             PUBLIC  EventCtrlSetup
             PUBLIC  StopEvScanning
             PUBLIC  StartEvScanning

.386

;  Gestore dell'applicazione

EventController  PROC   FAR

IntHeader:
             nop

; Disattiva l'ingresso all'interrupt mettendo come prima istruzione IRET.
; In questo modo ogni volta che l'int 1Ch verr… chiamato durante l'esecuzione
; non accadra nulla.

             mov        BYTE PTR IntHeader,0CFh

             pusha
             push       ds
             push       es

; MOV AX,<WORD che identifica il Segmento Dati>
             db         0B8h
_DataSeg_:
             dw         ?

             mov        ds,ax

; verifica del termine dei periodi di multi-clicking
             lea        di,btnInfo             ; Carica in DI l'offset di btnInfo
             lea  	si,PressDelayL         ; Carica in SI l'offset di PressDelayL
             mov 	bl,1                   ; BL funge da maschera
             mov 	cx,6                   ; CX=6 perchŠ 6 sono i contatori
_loop_:
             test 	DelayActive,bl         ; Controlla il bit X di DelayActive
             jz  	_EndIf1_               ; Se z=1 allora il periodo non Š in corso
             mov 	ax,MultipleMClickDelay
             cmp 	ds:[si],ax             ; Confronta ClickDelayX con AX
             jb  	_EndIf1_               ; Se <= non lo interrompe
             not 	bl
             and 	DelayActive,bl         ; Interrompe il periodo di multi-clicking
             not 	bl
             mov        WORD PTR ds:[si],1     ; Setta a 1 ClickDelayX
             mov        dx,6
             sub        dx,cx
             inc        dx                     ; Determina in DX l'indice di btnInfo
             mov        BYTE PTR ds:[di],0     ; Azzera il btnInfo corrispondente

_EndIf1_:
             inc	si
             inc	si                     ; Aggiorna l'indice
             shl	bl,1                   ; Aggiorna la maschera
             loop	_loop_

; controllo verifica eventi della tastiera
_KeyCtrl_:
             mov        ah,_Shifts_Int_
             int        16h
             mov        dx,ax                  ; DX = Shifts
             mov        ah,_Check_Int_
             int        16h                    ; Check for KeyStrokes
      	     jnz      	_AllocKeyEv_           ; Se non vuoto allora memorizza
             cmp        dx,precShifts          ; Controlla se Š cambiato qualche shift
             je         _MouseCtrl_            ; Se uguale allora passa al controllore
                                               ;  del mouse perchŠ non c'e nessun
                                               ;  evento dalla tastiera.
             xor        ax,ax
             jmp        SHORT _EndIf2_         ; Se sono cambiati solo gli shifts
                                               ;  non effettua le READKEYs.
_AllocKeyEv_:
             mov        ah,_Get_Int_
             int        16h                    ; Reads the Key Stroke
_EndIf2_:
             mov        precShifts,dx                  ; Memorizza gli Shifts
      	     mov     	LastSysMessage.KeyStroke,ax    ; Memorizza il Key Stroke
      	     mov     	LastSysMessage.Shifts,dx       ; Memorizza gli Shifts
      	     mov     	LastSysMessage.Message,EvKEYBOARD
             mov        LastSysMessage.HNDL,SYSTEM_SENDER
      	     call    	PutMessageInBuffer
             mov        IDevDelayC,0           ; Azzera il General Input Device Delay Counter
             mov        KBDelayC,0             ; Azzera il Keyboard Device Delay Counter
             jmp        SHORT _FineAppCtrl_

; controllo verifica eventi del mouse
_MouseCtrl_:
             mov 	ax,03h
             int        33h
             push 	dx
             push 	cx
             push 	bx
             call 	MouseEventController

_FineAppCtrl_:
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
; \
; / Questa routine deve essere collegata all'INT1Ch e si limita
; \ esclusivamente all'incremento di contatori.
; /


CounterRoutine  PROC   FAR

CountHeader:
             nop

; Disattiva l'ingresso all'interrupt mettendo come prima istruzione IRET.
; In questo modo ogni volta che l'int 1Ch verr… chiamato durante l'esecuzione
; non accadra nulla.

             mov        BYTE PTR CountHeader,0CFh

             push       ds

; MOV AX,<WORD che identifica il Segmento Dati>
             db         0B8h
_DataSeg2_:
             dw         ?

             mov        ds,ax


; incremento dei contatori
             inc 	IDevDelayC
             inc 	KBDelayC
             inc 	MMDelayC
             inc	MBDelayC

             inc        TimeCounter

; contatori per il clicking multiplo
             inc 	PressDelayL            ; Left
             inc 	PressDelayR            ; Right
             inc 	PressDelayC            ; Center
             inc 	ReleaseDelayL          ; Left
             inc 	ReleaseDelayR          ; Right
             inc 	ReleaseDelayC          ; Center

             pop        ds

; Riattiva l'ingresso all'interrupt mettendo come prima istruzione NOP.
             mov        BYTE PTR CountHeader,90h

             iret

CounterRoutine ENDP



;*****************************************************************************
; \
; / Procedura che deve essere chiamata prima che EventController venga collegata
; \ all'interrupt 1Ch. La sua funzione Š di impostare dei parametri sul codice
; / di EventController.
; \

EventCtrlSetup  PROC   NEAR

             mov        WORD PTR _DataSeg_,ds
             mov        WORD PTR _DataSeg2_,ds
             retn

EventCtrlSetup  ENDP



;*****************************************************************************
; \
; / Procedura per bloccare la scansione degli eventi.
; \

StopEvScanning  PROC   FAR

             mov        BYTE PTR EvScanStoped,1

; Disattiva EventController in modo permanente affinchŠ l'istruzione
; che si auto imposta per riattivarsi sia IRET invece di NOP.
             mov        BYTE PTR AutoProg2,0CFh
             retf

StopEvScanning  ENDP


;--------------------------------------------------------------------------


;*****************************************************************************
; \
; / Procedura per ripristinare la scansione degli eventi.
; \

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