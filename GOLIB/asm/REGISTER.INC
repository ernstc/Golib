; by ERNESTO CIANCIOTTA (c) 1996

; /*********************************************************************
; \
; / Macro di uso comune nella gestione diretta del frame buffer.
; \
; /
; \
; /
; \*********************************************************************


;\\\\\\\\\\\\\\\\\\\\\\\\ Definizione MACRO /////////////////////////////////

;----------------------------------------------
; IMPOSTAZIONE DEL SEQUENCER DELLA SCHEDA VIDEO


SetSequReg MACRO Address,Data
             SetSequAddress  Address
             __SetData       Data
ENDM


SetSequAddress MACRO Address
             mov       dx,3C4h
             mov       al,Address
             out       dx,al
ENDM


SetSequData MACRO Data
             mov       dx,3C5h
             mov       al,Data
             out       dx,al
ENDM


ResetSequAddress MACRO Address
             mov       dx,3C4h
             xor       al,al
             out       dx,al
ENDM


ResetSequData MACRO Data
             mov       dx,3C5h
             xor       al,al
             out       dx,al
ENDM


IncSequAddress MACRO Address
             mov       dx,3C4h
             inc       al
             out       dx,al
ENDM


IncSequData MACRO Data
             mov       dx,3C5h
             inc       al
             out       dx,al
ENDM


DecSequAddress MACRO Address
             mov       dx,3C4h
             dec       al
             out       dx,al
ENDM


DecSequData MACRO Data
             mov       dx,3C5h
             dec       al
             out       dx,al
ENDM




;-------------------------------------------------------
; IMPOSTAZIONE DEL GRAPHIC CONTROLLER DELLA SCHEDA VIDEO


SetGraphReg MACRO Address,Data
             SetGraphAddress  Address
             __SetData   Data
ENDM


SetGraphAddress MACRO Address
             mov       dx,3CEh
             mov       al,Address
             out       dx,al
ENDM


SetGraphData MACRO Data
             mov       dx,3CFh
             mov       al,Data
             out       dx,al
ENDM


ResetGraphAddress MACRO Address
             mov       dx,3CEh
             xor       al,al
             out       dx,al
ENDM


ResetGraphData MACRO Data
             mov       dx,3CFh
             xor       al,al
             out       dx,al
ENDM


IncGraphAddress MACRO Address
             mov       dx,3CEh
             inc       al
             out       dx,al
ENDM


IncGraphData MACRO Data
             mov       dx,3CFh
             inc       al
             out       dx,al
ENDM


DecGraphAddress MACRO Address
             mov       dx,3CEh
             dec       al
             out       dx,al
ENDM


DecGraphData MACRO Data
             mov       dx,3CFh
             dec       al
             out       dx,al
ENDM


;----------------------------------------------------------
; Macro per una impostazione sequenziale dei registri video


__SetAddress MACRO Address
             dec       dx
             mov       al,Address
             out       dx,al
ENDM


__SetData MACRO Data
             inc       dx
             mov       al,Data
             out       dx,al
ENDM


__ResetAddress MACRO
             dec       dx
             xor       al,al
             out       dx,al
ENDM


__ResetData MACRO
             inc       dx
             xor       al,al
             out       dx,al
ENDM


__IncAddress MACRO
             dec       dx
             inc       al
             out       dx,al
ENDM


__IncData MACRO
             inc       dx
             inc       al
             out       dx,al
ENDM


__DecAddress MACRO
             dec       dx
             dec       al
             out       dx,al
ENDM


__DecData MACRO
             inc       dx
             dec       al
             out       dx,al
ENDM


