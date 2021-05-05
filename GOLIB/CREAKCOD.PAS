{by Ernesto CIANCIOTTA Productions }


{ Programma per testare le procedure per la gestione delle applicazioni
  GOLIB.
}


program CreaKeyCodes;

uses
     crt,
     dos,
     codici,
     mouse,
     utility,
     evctrl
     ;



const altezzaRiga = 16;

var riga:word;
    NumEVento:longint;

   procedure VisEvent(var Ev:TMessage);
     begin
       hidemousecursor;
       if riga>24 then begin
         clrscr;
         riga:=1;
       end;
       case Ev.Message of
         EvKeyboard: begin
           gotoxy(1,riga);
           writeln(NumStr(NumEvento)+' - '+HexW(IndexFirstMSG)+' - '+HexW(IndexLastMsg)+' - '+
             'Tastiera -> ('+HexW(Ev.KeyStroke)+'h - '+HexW(Ev.shifts)+'h)');
         end;
         EvMouse: begin
           gotoxy(1,riga);
           writeln(NumStr(NumEvento)+' - '+HexW(IndexFirstMsg)+' - '+HexW(IndexLastMsg)+' - '+
             'Mouse -> ( '+NumStr(Ev.mcx)+' , '+NumStr(Ev.mcy)+' ) - '+
             HexW(word(Ev.Message))+'h - '+NumStr(Ev.Clicks));
         end;
       end;
       inc(riga);
       inc(NumEvento);
       showmousecursor;
     end;



const
     max__=10000;

var
    KeyStrokeVet:array[0..max__] of word;
    KIndex:word;



   function KeyStrokePresent(cod:word):boolean;
     var present:boolean;
         i:word;
     begin
       present:=false;
       if KIndex<>0 then
         for i:=1 to KIndex do
           if KeyStrokeVet[i]=cod then begin
             present:=true;
             break;
           end;
       KeyStrokePresent:=present;
     end;


var
   colonna:byte;
   f:text;


   procedure MemCod(Ev:TMessage);
     var ConstName:string;
         preStr:string;
     begin
       with Ev do begin
         if KeyStroke=0 then exit;
         if KeyStrokePresent(KeyStroke) then exit;
         clrscr;
         writeln('Inserisci il nome della costante relativa all''evento:');
         riga:=3;
         VisEvent(Ev);
         writeln;
         preStr:='kb';
         if (Shifts and kbCtrlShift)<>0 then preStr:=preStr+'Ctrl';
         if (Shifts and kbAltShift)<>0 then preStr:=preStr+'Alt';
         if (Shifts and kbShift)<>0 then preStr:=preStr+'Shift';
         write('Nome della costante (non pi— di 11 caratteri): ',preStr);
         readln(ConstName);
         ConstName:=preStr+ConstName;
         inc(KIndex);
         KeyStrokeVet[KIndex]:=KeyStroke;
         write(f,'    ');
         inc(colonna);
         if colonna=4 then begin
	   writeln(f);
           write(f,'    ');
           colonna:=1;
         end;
         write(f,ConstName,' ':11-length(ConstName),' = $',HexW(KeyStroke),';');
         clrscr;
  	 writeln('Attendo per un nuovo evento . . .');
       end;
     end;


var i:longint;
    Ev__:TMessage;


begin
  clrscr;
  writeln('Programma per la creazione della tebella codici KeyStroke.');
  writeln;
  writeln('Inizio scansione eventi.  Attendere...');
  wait(1);
  clrscr;
  ResetMouse;
  showmousecursor;

  InitMessageManagerF3;

  KIndex:=0;
  colonna:=0;

  assign(f,'c:\tp7\KeyCod.PAS');
  rewrite(f);

  riga:=1;
  NumEvento:=1;
  Ev__.KeyStroke:=$011B;
  MemCod(Ev__);
  clrscr;
  writeln('Attendo per un evento . . .');
  while true do begin
    asm
      int    0F3h
    end;
    if (GetNextMessage(Ev__)=EvKEYDOWN) and (Ev__.KeyStroke<>0) then
      MemCod(Ev__);
    with Ev__ do if (Message=EvKEYDOWN) and (KeyStroke=$011B) then break;
  end;
  clrscr;
  writeln('Uscita . . .');
  close(f);
end.