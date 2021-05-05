{by Ernesto CIANCIOTTA Productions}

{$A+				word align }
{$B-				boolean shortcut }
{$N+,E+			        gira con e senza il coprocessore }
{$G+				gira su sistemi 80286 e superiori }
{$I-,P-,Q-,R-,S-,T-,V-	        nessun controllo sul codice }
{$D-,L-,Y-                      nessuna informazione di debug }

{ Programma per effettuare un dump di file .BMP nel formato 16*16 pixels in
  16 colori.
  La dimensione di questi file Š di 246 bytes. }

{$P+}

uses crt,dos,utility,bios_utt;

const tabula:string[2]='Þ';
      espansione:boolean=true;
      colonna_vis:boolean=false;
      colonna_vis16:boolean=false;


type vet=array[1..1] of byte;

var bmp:file;
    dump:^vet;
    bin:array[1..16] of string[80];
    str8:Stringa8;

    i:longint;
    ch:char;

    dimF:longint;


procedure espandi(var s:string);
var i:word;
    j:byte;
    s2:string;
    trattieni:byte;
begin
  i:=length(s)*2;
  if i>255 then i:=255;
  for j:=1 to i do s2[j]:=' ';
  s2[0]:=chr(i);
  trattieni:=0;
  for j:=1 to length(s) do
    if s[j]='0' then s2[j*2-trattieni]:='_'
                else s2[j*2-trattieni]:=s[j];
  s:=s2;
end;


procedure visualizzaBin;
const colonne=4;
      numBinari=16*colonne;
var j:word;
    ii:word;
    cc:byte;
    str16:string[16];
    fattoreX:byte;
begin
  ii:=i;
  if numBinari-1+ii> dimF then
    ii:=dimF-numBinari+1;
  for j:=1 to 16 do begin
    str8:=Byte_BinStr(dump^[(j-1)*colonne+ii]);
    bin[j]:=str8;
    if colonne > 1 then for cc:=1 to colonne-1 do begin
      str8:=Byte_BinStr(dump^[(j-1)*colonne+ii+cc]);
      bin[j]:=bin[j]+tabula+str8;
    end;
  end;
  gotoxy(1,1);
  writeln('Valori espressi sotto forma di bits (acceso/spento)');
  writeln;
  for j:=1 to 16 do begin
    if espansione then espandi(bin[j]);
    writeln(bin[j]);
  end;
  if not colonna_vis then exit;
  ii:=i;
  if colonna_vis16 then fattoreX:=2
                   else fattoreX:=1;
  if 16*fattoreX-1+ii> dimF then
    ii:=dimF-16*fattoreX+1;
  for j:=1 to 16 do begin
    str16:=Byte_BinStr(dump^[(j-1)*fattoreX+ii]);
    if colonna_vis16 then str16:=str16+Byte_BinStr(dump^[(j-1)*fattoreX+ii+1]);
    gotoxy(60,2+j);
    write(str16);
  end;
end;


procedure aggiornaVideo;
var j,l:word;
    _b:array[1..4] of byte;
    _w:word absolute _b;
    _l:longint absolute _b;
begin
  visualizzaBin;
  writeln;
  writeln;
  writeln('Element pointer = ',i-1:5,'              Dimensione del file = ',dimF);
  writeln;
  writeln('--------------------------------------------------------------------------------');
  gotoxy(1,25);
  clreol; writeln;
  clreol; writeln;
  clreol; writeln;
  clreol; writeln;
  clreol; writeln;
  clreol; writeln;
  gotoxy(1,25);
  writeln('Valori decimali (BYTE)');
  writeln;
  l:=i+16;
  for j:=i to i+15 do begin
    write(dump^[j]:3,' -');
  end;
  for j:=j+1 to j+16 do begin
    write(dump^[j]:3,' -');
  end;
  writeln;
  writeln('--------------------------------------------------------------------------------');
  writeln('Codici ASCII');
  writeln;
  for j:=i to i+32 do
     if dump^[j] in [0,7,8,10,13,255] then write('.')
                                else write(chr(dump^[j]));
  writeln;
  writeln;
  writeln('--------------------------------------------------------------------------------');
  write  ('WORD: ');
  _b[1]:=dump^[i];
  _b[2]:=dump^[i+1];
  writeln(_w,' ':10);
  writeln;
  writeln('--------------------------------------------------------------------------------');
  write  ('DOUBLE WORD: ');
  _b[1]:=dump^[i];
  _b[2]:=dump^[i+1];
  _b[3]:=dump^[i+2];
  _b[4]:=dump^[i+3];
  writeln(_l,' ':10);
end;


begin
  if paramcount=0 then begin
    writeln('by Ernesto CIANCIOTTA Productions (c) 1995');
    writeln;
    writeln('Dump per file bitmapped.');
    writeln('Sintassi:  DUMP_BMP filename.BMP');
    exit;
  end;
  if (paramcount>=2) and ((paramstr(2)='b') or (paramstr(2)='B')) then begin
    __uno:='Û';
    __zero:=' ';
    tabula:='³';
    espansione:=false;
    colonna_vis:=true;
  end;
  if (paramcount>=3) and (paramstr(3)='16') then colonna_vis16:=true;
  textmode(C80 + Font8x8);
  EliminaCursore;
  assign(bmp,paramstr(1));
  reset(bmp,1);
  dimF:=FileSize(bmp);
  getmem(dump,dimF);
  blockread(bmp,dump^,dimF);
  close(bmp);
  clrscr;
  i:=1;
  ch:=#0;
  aggiornaVideo;
  gotoxy(1,46);
  writeln('Tastierino numerico:');
  writeln;
  writeln('1= Inizio   3= Fine   8=[Element Pointer+110]ø byte   9= 118ø byte');
  writeln('0= Ricarica file      2=[Element Pointer-110]ø byte');
  write('4= Sinistra           6= Destra');
  while ch<>#27 do begin
    ch:=readkey;
    case ch of
      '1': i:=1;
      '9': i:=119;
      '3': i:=dimF;
      '6': begin
             inc(i);
             if i>dimF then i:=dimF;
           end;
      '8': begin
             inc(i,110);
             if i>dimF then i:=dimF;
           end;
      '2': begin
             dec(i,110);
             if i<1 then i:=1;
           end;
      '4': if i>1 then dec(i);
      '0': begin
             reset(bmp,1);
             blockread(bmp,dump^,dimF);
             close(bmp);
             clrscr;
             i:=1;
             aggiornaVideo;
             gotoxy(1,46);
             writeln('Tastierino numerico:');
             writeln;
             writeln('1= Inizio   3= Fine   8=[Element Pointer+110]ø byte   9= 118ø byte');
             writeln('0= Ricarica file      2=[Element Pointer-110]ø byte');
             write('4= Sinistra           6= Destra');
           end;
    end;
    if ch in ['4','6','1','9','3','8','2'] then aggiornaVideo;
  end;
  RipristinaCursore;
  textmode(C80);
end.