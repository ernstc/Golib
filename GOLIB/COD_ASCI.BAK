{ (c) Ernesto CIANCIOTTA Productions 1994 }

{$A+				word align }
{$B-				boolean shortcut }
{$N-,E-			        gira con e senza il coprocessore }
{$G+				gira su sistemi 80286 e superiori }
{$I-,P-,Q-,R-,S-,T-,V-	        nessun controllo sul codice }
{$D-,L-,Y-                      nessuna informazione di debug }


uses crt,mouse,utility;
var ch:char;
    i,cod:integer;
begin
  textbackground(0);
  textcolor(7);
  clrscr;
  resetmouse;
  showmouse;
  writeln('1: Tabella generale'#13#10'2: Restituzione codice alla pressione di un tasto');
  Writeln('Tipo Ricerca: ');
  ch:=readkey;
  if ch='2' then begin
    clrscr;
    writeln('Premi ESC per uscire.');
    ch:=#32;
    while ch<>#27 do begin
      write('#');
      ch:=readkey;
      if ch=#0 then begin
        write('0 - #');
        ch:=readkey;
      end;
      writeln(HexB(byte(ch)));
    end;
  end
  else begin
    for i:=1 to 192 do begin
      case i of
      10,
      13: write(' #',i,'   ');
      else write(chr(i),' #',i,'   ');
      end;
      if i mod 8 = 0 then
        writeln;
    end;
    ch:=readkey;
    if ch=#27 then exit;
    for i:=193 to 255 do begin
      write(chr(i),' #',i,'   ');
      if i mod 8 = 0 then writeln;
    end;
    ch:=readkey;
  end;
end.