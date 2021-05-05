{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}


UNIT Mouse;

INTERFACE


type

	 TGraphicCursor = array [0..31] of word;



	function StartMouse:boolean;

	function ResetMouse:word;
	  {
		 Attiva il mouse senza visualizzare il cursore e posiziona il puntatore
		 al centro dello schermo.
		 Se l'operazione Š riuscita allora restituisce $FFFF
	  }

	{procedure ShowMouseCursor;}
	procedure ShowMouse;
	  {
		 Visualizza il cursore del mouse.
	  }

	{procedure HideMouseCursor;}
	procedure HideMouse;
	  {
		 Nasconde il cursore del mouse.
	  }

	{function PositionAndButtonStatus:word;}
	function GetButtonStatus:word;

	procedure XYMouse(var x, y: word);

	{function  XCursor:word;}
	function  GetXMouse:word;
	  {
		 Restituisce la coordinata coorrente della X.
	  }

	{function  YCursor:word;}
	function  GetYMouse:word;
	  {
		 Restituisce la coordinata coorrente della Y.
	  }

	{procedure PositionMouseCursor(x, y: word);}
	procedure SetMousePos(x, y: word);
	  {
		 Posiziona il cursore nelle coordinate (x,y).
	  }

	{procedure ButtonPressData(var button, times, column, row: word);
	 procedure ButtonReleaseData(var button, times, column, row: word);}
	procedure GetButtonData(var button, times, column, row:word; pressed: boolean);

	procedure DefineHorizontalCursorRange(x1, x2: word);
	procedure DefineVerticalCursorRange(y1, y2: word);
	procedure DefineCursorRange(x1, y1, x2, y2: word);
	  {
		 Vincolano il cursore del mouse.
	  }

	procedure DefineGraphicCursor(var cursore; hotx, hoty: integer);
	  {
		 Cambia l'aspetto del cursore.
		 -  hotx e hoty indicano la posizione del puntatore relativamente al
			 nuovo cursore e possono ed hanno un intervallo di [-16;16]
	  }

	procedure DefineTextCursor(tipo, param1, param2: word);


	{procedure XYRelative(var x, y: integer);
	 function  XRelative:word;
	 function  YRelative:word;}
	procedure XYMouseRel(var x, y: integer);
	function  GetXMouseRel:word;
	function  GetYMouseRel:word;
	  {
		 Coordinate relative alla precedente chiamata ad una funzione
		 *Relative.
	  }

	procedure LigthPenEmulationON;      { INT 33-0Dh }
	procedure LigthPenEmulationOFF;    { INT 33-0Eh }

	procedure DefinePixelRatio(oriz, vert: word);
	  {
		 Stabilisce la "velocit…" del mouse per il movimento orizzontale
		 (oriz) e verticale (vert).
		 Pi— i valori sono piccolo pi— il mouse sara veloce.

		 N.B.: oriz e vert non devono mai essere uguali a zero.
	  }

	procedure NoWindowMouse(x, y, x1, y1: word);
	  {
		 Fa scomparire il cursore del mouse quando il suo puntatore entra
		 nella regione di schermo (x,y);(x1,y1).
	  }


	var _HotX_  , _HotY_: integer;   { Indicano la posizione dell'hotspot del mouse. }
		 MCX     , MCY   : word;      { Coordinate del cursore dell'ultima localizzazione }
		 MousePresent: wordbool;
		 NumButtons: byte;

IMPLEMENTATION


	{$I SYSCUR.PCR}


	function StartMouse:boolean;
	  begin
		 StartMouse:=false;
		 if ResetMouse=0 then exit;
		 ShowMouse;
		 DefineGraphicCursor(syscur_cursore,syscur_cursore[32],syscur_cursore[33]);
		 StartMouse:=true;
	  end;


	function ResetMouse:word; assembler;
	  asm
			XOR	AX,AX
			XOR	BX,BX
			INT	33h
			MOV	_HotX_,0
			MOV	_HotY_,0
			MOV	MousePresent,AX
			MOV	NumButtons,BL
	  end;


	procedure ShowMouse; assembler;
	  asm
			MOV 	AX,1
			INT 	33H
	  end;


	procedure HideMouse; assembler;
	  asm
			MOV	AX,2
			INT 	33H
	  end;


	function GetButtonStatus:word; assembler;
	  asm
			XOR	BX,BX
			XOR	CX,CX
			XOR	DX,DX
			MOV 	AX,3
			INT 	33H
			MOV 	Mcx,CX
			MOV 	Mcy,DX
			MOV 	AX,BX
	  end;

	procedure XYMouse(var x, y: word); assembler;
	  asm
			XOR	CX,CX
			XOR	DX,DX
			MOV 	AX,3
			INT 	33H
			MOV 	Mcx,CX
			MOV 	Mcy,DX
			LES	DI,x
			MOV 	WORD PTR ES:[DI],CX
			LES	DI,y
			MOV 	WORD PTR ES:[DI],DX
	  end;


	function  GetXMouse:word; assembler;
	  asm
			XOR	CX,CX
			MOV 	AX,3
			INT 	33H
			MOV	Mcx,CX
			MOV 	AX,CX
	  end;


	function  GetYMouse:word; assembler;
	  asm
			XOR	DX,DX
			MOV 	AX,3
			INT 	33H
			MOV	Mcy,DX
			MOV 	AX,DX
	  end;


	procedure SetMousePos(x, y: word); assembler;
	  asm
			MOV 	AX,4
			MOV 	CX,x
			MOV 	DX,y
			INT 	33H
	  end;


	procedure GetButtonData(var button, times, column, row: word;
									pressed: boolean); assembler;
	  asm
			CMP   pressed,0
			JZ    @RequestRelease
		@RequestPressed:
			MOV   AX,5
			JMP   @Start
		@RequestRelease:
			MOV   AX,6
		@Start:
			LES 	DI,button
			CMP 	MousePresent,0
			JE  	@Else
			MOV 	BX,ES:[DI]
			INT 	33H
			MOV 	ES:[DI],AX
			LES 	DI,times
			MOV 	ES:[DI],BX
			LES 	DI,column
			MOV 	ES:[DI],CX
			LES 	DI,row
			MOV 	ES:[DI],DX
			JMP 	@Fine
		@Else:
			MOV 	WORD PTR ES:[DI],0
			LES 	DI,times
			MOV 	WORD PTR ES:[DI],0
			LES 	DI,column
			MOV 	WORD PTR ES:[DI],0
			LES 	DI,row
			MOV 	WORD PTR ES:[DI],0
			JMP 	@Fine
		@Fine:
	  end;


	procedure DefineHorizontalCursorRange(x1, x2: word); assembler;
	  asm
			MOV 	AX,7
			MOV 	CX,x1
			MOV 	DX,x2
			INT 	33H
	  end;


	procedure DefineVerticalCursorRange(y1, y2: word); assembler;
	  asm
			MOV 	AX,8
			MOV 	CX,y1
			MOV 	DX,y2
			INT 	33H
	  end;


	procedure DefineCursorRange(x1, y1, x2, y2: word); assembler;
	  asm
			MOV 	AX,7
			MOV 	CX,x1
			MOV 	DX,x2
			INT 	33H
			MOV 	AX,8
			MOV 	CX,y1
			MOV 	DX,y2
			INT 	33H
	  end;


	procedure DefineGraphicCursor(var cursore; hotx, hoty: integer); assembler;
	  asm
			MOV 	AX,09h
			MOV 	BX,hotx
			MOV 	CX,hoty
			MOV 	_HotX_,BX
			MOV 	_HotY_,CX
			LES 	DX,cursore
			INT 	33h
	  end;


	procedure DefineTextCursor(tipo, param1, param2: word); assembler;
	  { se tipo Š uguale a 1 (Hardware) allora
			  param1 specifica il primo scan line e
			  param2 specifica l'ultimo scan line;

		 se tipo Š uguale a 0 (Software) allora
			  param1 specifica screen mask e
			  param2 specifica cursor mask.
	  }
	  asm
			MOV 	BX,tipo
			MOV 	CX,param1
			MOV 	DX,param2
			MOV 	AX,10
			INT 	33H
	  end;


	procedure XYMouseRel(var x, y: integer); assembler;
	  asm
			XOR	CX,CX
			XOR	DX,DX
			MOV 	AX,11
			INT 	33H
			LES 	DI,x
			MOV   WORD PTR ES:[DI],CX
			LES 	DI,y
			MOV 	WORD PTR ES:[DI],DX
	  end;


	function  GetXMouseRel:word; assembler;
	  asm
			XOR 	CX,CX
			MOV 	AX,11
			INT 	33H
			MOV 	AX,CX
	  end;


	function  GetYMouseRel:word; assembler;
	  asm
			XOR 	DX,DX
			MOV 	AX,11
			INT 	33H
			MOV 	AX,DX
	  end;


	procedure LigthPenEmulationON; assembler;     { INT 33-0Dh }
	  asm
			MOV 	AX,0Dh;
			INT 	33h
	  end;


	procedure LigthPenEmulationOFF; assembler;   { INT 33-0Eh }
	  asm
			MOV	AX,0Eh;
			INT 	33h
	  end;


	procedure DefinePixelRatio(oriz, vert: word); assembler;
	  asm
			MOV 	AX,0FH
			MOV 	CX,oriz
			MOV 	DX,vert
			INT 	33H
	  end;


	procedure NoWindowMouse(x, y, x1, y1: word); assembler;
	  asm
			MOV 	AX,10H
			MOV 	CX,x
			MOV 	DX,y
			MOV 	SI,x1
			MOV 	DI,y1
			INT 	33H
	  end;



(*
	Prototipi delle procedure da inserire nella sezione INTERFACE
	-------------------------------------------------------------

	procedure DefineMouseSubRoutine(call_mask:word; var p);      { INT 33-0Ch }

	procedure SetLargeGraphicsCursorBlock(var cursore; hotx,hoty:shortint);	{ INT 33-12h }

	procedure DefineThreSholdSpeed(mickeys_at_second:integer);  { INT 33-13h }
	procedure ExchangeMouseSubRoutine(var call_mask:word; var p);  { INT 33-14h }
	function GetDriverStorageRequirments:integer;  { INT 33-15h }
	procedure SaveDriverState(size_buffer:word; var buffer);  { INT 33-16h }
	procedure RestoreDriverState(size_buffer:word; var buffer_saved); { INT 33-17h }

	procedure SetAlternateMouseHandler(call_mask:integer; p:pointer); { INT 33-18h }

	procedure GetAlternativeInterruptVector(call_mask:integer; var p); { INT 33-19h }
	procedure SetMouseSensitivity(HSpeed,VSpeed,ThreSholdSpeed:integer); { INT 33-1Ah }
	procedure GetMouseSensitivity(var HSpeed,VSpeed,ThreSholdSpeed:integer); { INT 33-1Bh }
	procedure SetInterruptRate(rate:integer); { INT 33-1Ch }
	procedure DefineDisplayPageNumber(num_page:integer); { INT 33-1Dh }
	procedure GetDisplayPageNumber(var num_page:integer); { INT 33-1Eh }



	Le seguenti procedure non sono operative
	----------------------------------------

	procedure DefineMouseSubRoutine(call_mask:word; var p); assembler;    { INT 33-0Ch }
	  asm
		 MOV AX,0Ch
		 MOV CX,call_mask
		 LES DX,p
		 INT 33h
	  end;


	procedure SetLargeGraphicsCursorBlock(var cursore; hotx,hoty:shortint); assembler;
	{ INT 33-12h }
	  asm
		 CMP MousePresent,0
		 JE  @Fine
		 MOV AX,12h
		 MOV BH,2
		 MOV CH,32
		 MOV BL,hotx
		 MOV CL,hoty
		 LES DX,cursore
		 INT 33h
		 MOV MouseResult,AX
	  @Fine:
	  end;


	procedure DefineThreSholdSpeed(mickeys_at_second:integer);  { INT 33-13h }
	assembler;
	  asm
		 MOV AX,13H
		 MOV DX,mickeys_at_second
		 INT 33H
	  end;


	procedure ExchangeMouseSubRoutine(var call_mask:word; var p);  { INT 33-14h }
	  begin
	  end;
	function GetDriverStorageRequirments:integer;  { INT 33-15h }
	  begin
	  end;
	procedure SaveDriverState(size_buffer:word; var buffer);  { INT 33-16h }
	  begin
	  end;
	procedure RestoreDriverState(size_buffer:word; var buffer_saved); { INT 33-17h }
	  begin
	  end;


	procedure SetAlternateMouseHandler(call_mask:integer; p:pointer); assembler; { INT 33-18h }
	  asm
		 MOV AX,18h
		 MOV CX,call_mask
		 LES DX,p
		 INT 33h
	  end;


	procedure GetAlternativeInterruptVector(call_mask:integer; var p); { INT 33-19h }
	  begin
	  end;
	procedure SetMouseSensitivity(HSpeed,VSpeed,ThreSholdSpeed:integer); { INT 33-1Ah }
	  begin
	  end;
	procedure GetMouseSensitivity(var HSpeed,VSpeed,ThreSholdSpeed:integer); { INT 33-1Bh }
	  begin
	  end;
	procedure SetInterruptRate(rate:integer); { INT 33-1Ch }
	  begin
	  end;
	procedure DefineDisplayPageNumber(num_page:integer); { INT 33-1Dh }
	  begin
	  end;
	procedure GetDisplayPageNumber(var num_page:integer); { INT 33-1Eh }
	  begin
	  end;

*)


END.