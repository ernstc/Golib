{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



{ *************************************** }
{ *                                     * }
{ * Modulo della libreria GOLIB per la  * }
{ * gestione della tastiera.            * }
{ *                                     * }
{ * Scritto con Turbo Pascal 7.0        * }
{ *                                     * }
{ *************************************** }



UNIT Keyboard;


INTERFACE

type
     TKeyStroke = record
        case byte of
        0: ( KeyStroke: word
            );
        1: ( Character: char;
             ScanCode: byte;
            );
     end;

const
     { Costanti per consultare il byte delle funzionalit… della
       tastiera }
     fkb122Keyboard   = $40;
     fkbEnhKeyboard   = $20;
     fkbIDAvailable   = $10;
     fkbGetRateDelay  = $08;
     fkbSetRateDelay  = $04;
     fkbTurnOffRepeat = $02;
     fkbSetDefault    = $01;

     NoKeyboardAttached = 0;



   function GetKeyStroke: word;
   function CheckForKeyStroke: boolean;
   function GetShiftFlags: word;

   procedure GetRateAndDelay(var rate, delay:byte);
   procedure SetRateAndDelay(rate:byte; delay:byte);
   procedure TurnOffTypematicRepeat;
   procedure SetDefaultRateAndDelay;
   procedure GetKeyboardFunctionality(var funcs:byte);
   procedure GetKeyboarID(var ID:word);


   { Restituisce gli interrupts da chiamare per rispettivamente per le funzioni:
   - GetKeyStroke;
   - CheckForKeyStroke;
   - GetShiftFlags.
   }
   procedure GetKeyInterrupts(var _get,_check,_shifts: byte);


IMPLEMENTATION


var
    Functionality: byte;
    KeyboardID: word;

    GetKeyStroke_Int,
    GetShiftFlags_Int,
    CheckForKeyStroke_Int: byte;



   function GetKeyStroke:word; assembler;
   asm
	mov		ah,GetKeyStroke_Int
	int		16h
   end;


   function CheckForKeyStroke:boolean; assembler;
   asm
	mov		ah,CheckForKeyStroke_Int
	int		16h
	jz		@NoChecked
	mov		al,01h
	jmp		@Fine

   @NoChecked:
	xor		al,al

   @Fine:
   end;


   function GetShiftFlags:word; assembler;
   asm
	mov		ah,GetShiftFlags_Int
	int		16h
        cmp		GetShiftFlags_Int,02h
	jne		@001
	xor		ah,ah
   @001:
   end;


{--- Procedure valide per tutti i tipi di tastiere ---}
   procedure GetRateAndDelay(var rate, delay:byte); assembler;
   asm
	test		Functionality,fkbGetRateDelay
	jz		@Fine
	mov		ax,0306h
	int		16h
	les		di,rate
	mov		BYTE PTR es:[di],bl
	les		di,delay
	mov		BYTE PTR es:[di],bh
   @Fine:
   end;


   procedure SetRateAndDelay(rate:byte; delay:byte); assembler;
   asm
	test		Functionality,fkbSetRateDelay
	jz		@Fine
	mov		ax,0305h
	mov		bh,delay
	mov		bl,rate
	int		16h
   @Fine:
   end;


   procedure TurnOffTypematicRepeat; assembler;
   asm
	test		Functionality,fkbTurnOffRepeat
	jz		@Fine
	mov		ax,0304h
	int		16h
   @Fine:
   end;


   procedure SetDefaultRateAndDelay; assembler;
   asm
	test		Functionality,fkbSetDefault
	jz		@Fine
	mov		ax,0300h
	int		16h
   @Fine:
   end;


   procedure GetKeyboardFunctionality(var funcs:byte);
     begin
       funcs:=Functionality;
     end;


   procedure GetKeyboarID(var ID:word);
     begin
       ID:=KeyboardID;
     end;


   procedure GetKeyInterrupts(var _get,_check,_shifts: byte);
     begin
       _get:=GetKeyStroke_Int;
       _check:=CheckForKeyStroke_Int;
       _shifts:=GetShiftFlags_Int;
     end;







BEGIN
  { Procedura diagnostica per la tastiera }
  asm
	{ Prende informazioni sul sistema }
	mov		ah,0C0h
	int		15h
	jnc		@OK1
	or		ah,ah
	jnz             @OK1
	jmp		@CheckBIOSMem
  @OK1:
	test		BYTE PTR es:[bx+06h],40h
	jnz		@09Supported
  @CheckBIOSMem:
	mov		Functionality,00
	mov		KeyboardID,0FFh
	push		0040h
	pop		es
	mov		al,es:[0096h]
	test		al,10h
	jnz		@Enhanced
	jmp		@SetStandardK

  @09Supported:
	{ Ottiene informazioni riguardo le funzionalit… della tastiera }
	mov		ah,09h
	int		16h
	mov		Functionality,al

	{ Determina l'ID della tastiera }
	test		Functionality,fkbIDAvailable
	jnz		@0ASupported
	xor		bx,bx
	jmp		@001

  @0ASupported:
	mov		ah,0Ah
	int		16h
  @001:
	mov		keyboardID,bx

  	{ Determina gli interrupts da chiamare rispettivamente per le funzioni:
  	- GetKeyStroke;
  	- CheckForKeyStroke;
  	- GetShiftFlags. }
  @CheckFor122K:
	test		Functionality,fkb122Keyboard
	jz		@CheckForEnhancedK
	mov		GetKeyStroke_Int,20h
	mov		CheckForKeyStroke_Int,21h
	mov		GetShiftFlags_Int,22h
	jmp		@Fine

  @CheckForEnhancedK:
	test		Functionality,fkbEnhKeyboard
	jz		@SetStandardK
  @Enhanced:
	mov		GetKeyStroke_Int,10h
	mov		CheckForKeyStroke_Int,11h
	mov		GetShiftFlags_Int,12h
	jmp		@Fine

  @SetStandardK:
	mov		GetKeyStroke_Int,00h
	mov		CheckForKeyStroke_Int,01h
	mov		GetShiftFlags_Int,02h

  @Fine:
  end;
END.