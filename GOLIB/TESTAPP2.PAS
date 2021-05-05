{by Ernesto CIANCIOTTA Productions }


{ Programma per testare le procedure per la gestione delle applicazioni
  GOLIB.
}


program Test_AppController;

uses
     crt,
     dos,
     codici,
     mouse,
     graph,
     graftool,
     golib_h,
     fonts,
     bitmaps,
     utility,
     applic
     ;


type
    TTypeOfEvent = (EvNothing,EvKeyboard,EvMouse);


const altezzaRiga = 16;

var riga:word;
    NumEvento:longint;


   function TipoEvento(msg:word):TTypeOfEvent;
     var t:TTypeOfEvent;
     begin
       if msg=EvKEYDOWN
         then t:=EvKeyboard
         else if (msg shr 12) = $8
                then t:=EvMouse
                else t:=EvNothing;
       TipoEvento:=t;
     end;


   procedure VisEvent(var Ev:TMessage);
     begin
       hidemousecursor;
       if riga*altezzaRiga>460 then begin
         cleardevice;
         riga:=0;
       end;
       case TipoEvento(Ev.Message) of
         EvKeyboard: begin
           textcolor:=3;
           _serif8_.DrawText(0,riga*altezzaRiga,TextLeft,
             NumStr(NumEvento)+' - '+
             'Tastiera -> ('+HexW(Ev.KeyStroke)+'h - '+HexW(Ev.shifts)+'h) - ('+
             Ev.Character+' - '+NumStr(Ev.ScanCode)+')');
         end;
         EvMouse: begin
           textcolor:=14;
           _system_.DrawText(0,riga*altezzaRiga,TextLeft,
             NumStr(NumEvento)+' - '+
             'Mouse -> ( '+NumStr(Ev.mcx)+' , '+NumStr(Ev.mcy)+' ) - '+
             HexW(word(Ev.Message))+'h - '+NumStr(Ev.Clicks));
         end;
       end;
       inc(riga);
       inc(NumEvento);
       showmousecursor;
     end;




var i:longint;
    Ev__:TMessage;

begin
  InizializzaGrafica(3,16);
  asm
         { Attiva il refresh della memoria video }
         MOV AH,12H
         MOV BL,36H
         MOV AL,0
         INT 10H
  end;
  _serif8_.DrawText(0,riga*20,TextLeft,'Inizio scansione eventi.  Attendere...');
  {
  readkey;
  }
  {wait(1);} delay(1000);

  cleardevice;
  {ResetMouse;
  showmousecursor;}
  NumEvento:=1;    {

  InitMessageManager;}

  {SetMultipleMClickDelay(round(1000/18.2*500));}

  while true do begin
    {$IFNDEF Installa1Ch}
    asm
      int 0f3h
    end;
    {$ENDIF}
    if GetNextMessage(Ev__)<>0 then
      VisEvent(Ev__);
    with Ev__ do if (Message=EvKEYDOWN) and (Character=#27) then break;
  end;
end.