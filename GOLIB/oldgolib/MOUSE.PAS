{ ERNESTO CIANCIOTTA Productions }

{
   In una futura conversione di questo modulo in linguaggio C++, tutte
   le costanti e le funzioni verranno scritte come macro con la
   direttiva #define.
}

{$X+}
{$D+}
{$L+}

unit mouse;

interface


type

    TGraphicCursor = array [0..31] of word;



   function GetMouseResult:word;
   { "GetMouseResult" restituisce l'ultimo esito negativo di un'operazione
     sul mouse.

     Questa funzione pu� essere chiamata solo una volta per lo stesso
     identico motivo (ossia in relazione alla stessa chiamata ad una
                      funzione del mouse).
     Se ad esempio viene chiamata due volte consecutive, la prima volta
     restituir� il valore dell'errore (se si � verificato), ma la seconda
     volta restituir� il valore di riuscita dell'operazione.

           Di seguito ci sono tutti i valori che pu� restituire:

     ---------------------------------------------------------------------
       Valore  /                      Descrizione
     ---------------------------------------------------------------------
        FFFFh  / Operazione riuscita con successo.
        0000h  / Hardware o driver non installato.



     ---------------------------------------------------------------------
   }

   function ResetMouse:word;
     {
       Attiva il mouse senza visualizzare il cursore e posiziona il puntatore
       al centro dello schermo.
       -  errore � TRUE se la procedure ha avuto buon fine
       -  num restituisce il numero dei bottoni
     }

   procedure ShowMouseCursor;
     {
       Visualizza il cursore del mouse.
     }

   procedure HideMouseCursor;
     {
       Nasconde il cursore del mouse.
     }

   function PositionAndButtonStatus:word;

   function  XCursor:word;
     {
       Restituisce la coordinata coorrente della X.
     }

   function  YCursor:word;
     {
       Restituisce la coordinata coorrente della Y.
     }

   procedure PositionMouseCursor(x,y:word);
     {
       Posiziona il cursore nelle coordinate (x,y).
     }

   procedure ButtonPressData(var button, times, column, row:word);
   procedure ButtonReleaseData(var button, times, column, row:word);

   procedure DefineCursorRange(x1,y1,x2,y2:word);
   procedure DefineHorizontalCursorRange(x1,x2:word);
   procedure DefineVerticalCursorRange(y1,y2:word);
     {
       Vincolano il cursore del mouse.
     }

   procedure DefineGraphicCursor(var cursore; hotx,hoty:integer);
     {
       Cambia l'aspetto del cursore.
       -  hotx e hoty indicano la posizione del puntatore relativamente al
          nuovo cursore e possono ed hanno un intervallo di [-16;16]
     }

   procedure DefineTextCursor(tipo,param1,param2:word);


   procedure XYRelative(var x,y:integer);
   function  XRelative:word;
   function  YRelative:word;
     {
       Coordinate relative alla precedente chiamata ad una funzione
       *Relative.
     }

   procedure DefineMouseSubRoutine(call_mask:word; var p);      { INT 33-0Ch }

   procedure LigthPenEmulationON;      { INT 33-0Dh }
   procedure LigthPenEmulationOFF;    { INT 33-0Eh }

   procedure DefinePixelRatio(oriz,vert:word);
     {
       Stabilisce la "velocit�" del mouse per il movimento orizzontale
       (oriz) e verticale (vert).
       Pi� i valori sono piccolo pi� il mouse sara veloce.

       N.B.: oriz e vert non devono mai essere uguali a zero.
     }

   procedure NoWindowMouse(x,y,x1,y1:word);
     {
       Fa scomparire il cursore del mouse quando il suo puntatore entra
       nella regione di schermo (x,y);(x1,y1).
     }

   procedure SetLargeGraphicsCursorBlock(var cursore; hotx,hoty:shortint);
   { INT 33-12h }

   procedure DefineThreSholdSpeed(mickeys_at_second:integer);  { INT 33-13h }
   procedure ExchangeMouseSubRoutine(var call_mask:word; var p);  { INT 33-14h }
   function GetDriverStorageRequirments:integer;  { INT 33-15h }
   procedure SaveDriverState(size_buffer:word; var buffer);  { INT 33-16h }
   procedure RestoreDriverState(size_buffer:word; var buffer_saved); { INT 33-17h }

   procedure SetAlternateMouseHandler(call_mask:integer; p:pointer); { INT 33-18h }

   procedure GetAlternativeInterruptVector(call_mask:integer; var p); { INT 33-19h }
   procedure SetMouseSensitivity(HSpeed,VSpeed,ThreSholdSpeed:integer); { INT 33-1Ah }
   procedure GetMouseSensitivity(var HSpeed,VSpeed,ThreSholdSpeed:integer);
   { INT 33-1Bh }
   procedure SetInterruptRate(rate:integer); { INT 33-1Ch }
   procedure DefineDisplayPageNumber(num_page:integer); { INT 33-1Dh }
   procedure GetDisplayPageNumber(var num_page:integer); { INT 33-1Eh }


   var _HotX_  , _HotY_: integer;   { Indicano la posizione dell'hotspot del mouse. }
       MCX     , MCY   : word;      { Coordinate del cursore dell'ultima localizzazione }
       (*MCursorX, MCursorY   : word; { Coordinate del cursore dell'ultima localizzazione }*)
       MousePresent: boolean;

implementation

   uses dos;

   var r:Registers;
       MouseResult : word;


   function GetMouseResult:word;
     begin
       if MousePresent then begin
         GetMouseResult:=MouseResult;
         MouseResult:=$FFFF;
       end
       else GetMouseResult:=0;
     end;


   function ResetMouse:word; assembler;
     asm
       MOV AX,0
       INT 33H
       MOV MouseResult,AX
       MOV _HotX_,0
       MOV _HotY_,0
       MOV MousePresent,0  {FALSE}
       CMP AX,0
       JE  @Fine
       MOV MousePresent,1  {TRUE}
     @Fine:
       MOV AX,BX
     end;


   procedure ShowMouseCursor; assembler;
     asm
       MOV AX,1
       INT 33H
     end;


   procedure HideMouseCursor; assembler;
     asm
       MOV AX,2
       INT 33H
       { multiple calls to hide the cursor will require multiple calls to
	 function 01h to unhide it. }
     end;


   function PositionAndButtonStatus:word; assembler;
     asm
       CMP MousePresent,0
       JE  @NoMouse
       MOV AX,3
       INT 33H
       MOV [DS:Mcx],CX
       MOV [DS:Mcy],DX
       MOV AX,BX
       JMP @Fine
     @NoMouse:
       MOV [DS:Mcx],0
       MOV [DS:Mcy],0
       XOR AX,AX
     @Fine:
     end;


   function  XCursor:word; assembler;
     asm
       XOR AX,AX
       CMP MousePresent,0
       JE  @Fine
       MOV AX,3
       INT 33H
       MOV AX,CX
     @Fine:
     end;


   function  YCursor:word; assembler;
     asm
       XOR AX,AX
       CMP MousePresent,0
       JE  @Fine
       MOV AX,3
       INT 33H
       MOV AX,DX
     @Fine:
     end;


   procedure PositionMouseCursor(x,y:word); assembler;
     asm
       MOV AX,4
       MOV CX,x
       MOV DX,y
       INT 33H
       { Imposta la posizione del cursore. }
     end;


   procedure ButtonPressData(var button, times, column, row:word);
     begin
       if MousePresent then begin
         r.ax:=5;
         r.bx:=button;
         intr($33,r);
         button:=r.ax;
         times:=r.bx;
         column:=r.cx;
         row:=r.dx;
       end
       else begin
         button:=0;
         times:=0;
         column:=0;
         row:=0;
       end;
     end;


   procedure ButtonReleaseData(var button, times, column, row:word);
     begin
       if MousePresent then begin
         r.ax:=6;
         r.bx:=button;
         intr($33,r);
         button:=r.ax;
         times:=r.bx;
         column:=r.cx;
         row:=r.dx;
       end
       else begin
         button:=0;
         times:=0;
         column:=0;
         row:=0;
       end;
     end;


   procedure DefineCursorRange(x1,y1,x2,y2:word); assembler;
     asm
       CMP MousePresent,0
       JE  @Fine
       MOV CX,x1
       MOV DX,x2
       MOV AX,7
       INT 33H
       MOV CX,y1
       MOV DX,y2
       MOV AX,8
       INT 33H
     @Fine:
     end;


   procedure DefineHorizontalCursorRange(x1,x2:word); assembler;
     asm
       MOV CX,x1
       MOV DX,x2
       MOV AX,7
       INT 33H
     end;


   procedure DefineVerticalCursorRange(y1,y2:word); assembler;
     asm
       MOV CX,y1
       MOV DX,y2
       MOV AX,8
       INT 33H
     end;


   procedure DefineGraphicCursor(var cursore; hotx,hoty:integer); assembler;
     asm
       CMP MousePresent,0
       JE  @Fine
       MOV AX,09h
       MOV BX,hotx
       MOV CX,hoty
       MOV _HotX_,BX
       MOV _HotY_,CX
       LES DX,cursore
       INT 33h
     @Fine:
     end;


   procedure DefineTextCursor(tipo,param1,param2:word); assembler;
     { se tipo � uguale a 1 (Hardware) allora
           param1 specifica il primo scan line e
           param2 specifica l'ultimo scan line;

       se tipo � uguale a 0 (Software) allora
           param1 specifica screen mask e
           param2 specifica cursor mask.
     }
     asm
       MOV BX,tipo
       MOV CX,param1
       MOV DX,param2
       MOV AX,10
       INT 33H
     end;


   procedure XYRelative(var x,y:integer);
     begin
       if MousePresent then begin
         r.ax:=11;
         intr($33,r);
         x:=r.cx;
         y:=r.dx;
       end
       else begin
         x:=0;
         y:=0;
       end;
     end;


   function  XRelative:word; assembler;
     asm
       XOR AX,AX
       CMP MousePresent,0
       JE  @Fine
       MOV AX,11
       INT 33H
       MOV AX,CX
     @Fine:
     end;


   function  YRelative:word; assembler;
     asm
       XOR AX,AX
       CMP MousePresent,0
       JE  @Fine
       MOV AX,11
       INT 33H
       MOV AX,DX
     @Fine:
     end;


   procedure DefineMouseSubRoutine(call_mask:word; var p); assembler;    { INT 33-0Ch }
     asm
       MOV AX,0Ch
       MOV CX,call_mask
       LES DX,p
       INT 33h
     end;


   procedure LigthPenEmulationON; assembler;     { INT 33-0Dh }
     asm
       MOV AX,0Dh;
       INT 33h
     end;


   procedure LigthPenEmulationOFF; assembler;   { INT 33-0Eh }
     asm
       MOV AX,0Eh;
       INT 33h
     end;


   procedure DefinePixelRatio(oriz,vert:word); assembler;
     asm
       MOV AX,0FH
       MOV CX,oriz
       MOV DX,vert
       INT 33H
     end;


   procedure NoWindowMouse(x,y,x1,y1:word); assembler;
     asm
       MOV AX,10H
       MOV CX,x
       MOV DX,y
       MOV SI,x1
       MOV DI,y1
       INT 33H
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
     begin
       r.ax:=$13;
       r.dx:=mickeys_at_second;
       intr($33,r);
     end;


   procedure ExchangeMouseSubRoutine(var call_mask:word; var p);  { INT 33-14h }
     var proc:pointer absolute p;
     begin
       if MousePresent then begin
         r.ax:=$14;
         r.cx:=call_mask;
         r.es:=seg(p);
         r.dx:=ofs(p);
         intr($33,r);
         call_mask:=r.ax;
         proc:=ptr(r.es,r.dx);
       end;
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
   procedure GetMouseSensitivity(var HSpeed,VSpeed,ThreSholdSpeed:integer);
   { INT 33-1Bh }
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


end.