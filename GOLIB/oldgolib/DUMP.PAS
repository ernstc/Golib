uses crt,dos,g_utile,mouse,inter_fc,bios_utt;

type
     TStr=string[45];
     TStr2=string[27];
     TStr9=array[1..9] of char;

     PLinea= ^TLinea;
     TLinea= record
               testo:TStr9;
               succ,
               prec:PLinea;
             end;


var _f:file;
    f_buf:TStr9;
    buffer:byte;
    ch:char;
    i:word;
    linea,
    _linea:PLinea;
    PrimaL,UltimaL:PLinea;

    DimUltimo:integer;

    nome_sorgente:string;
    nome_dest:string;

    par:byte;
    txtbuf:TStr;
    txtbuf2:TStr2;

    _mcx,_mcy,
    mcx,mcy:word;
    selezionato:boolean;
    tasto:word;

    precV:bufferVideo;
    buf:PLinea;


procedure NuovaLinea;
begin
  new(Buf);
  buf^.succ:=nil;
  if PrimaL=nil then begin
    PrimaL:=buf;
    UltimaL:=buf;
    buf^.prec:=nil;
  end
  else begin
    UltimaL^.succ:=buf;
    buf^.prec:=UltimaL;
    UltimaL:=buf;
  end;
end;

procedure CancellaLinee;
begin
  UltimaL:=PrimaL;
  PrimaL:=PrimaL^.succ;
  while UltimaL<>nil do begin
    dispose(UltimaL);
    UltimaL:=PrimaL;
    PrimaL:=PrimaL^.succ;
  end;
end;


function Gettxt1(lin:PLinea):string;
var nch,h:byte;
begin
  if lin=UltimaL then nch:=DimUltimo
                 else nch:=9;
  txtbuf:='';
  for h:=1 to nch do begin
    buffer:=ord(lin^.testo[h]);
    if buffer<10 then
      txtbuf:=txtbuf+'   '
    else if buffer<100 then
      txtbuf:=txtbuf+'  '
    else txtbuf:=txtbuf+' ';
    txtbuf:=txtbuf+'#'+NumStr(buffer);
  end;
  Gettxt1:=txtbuf;
end;


function Gettxt2(lin:PLinea):string;
var nch,h:byte;
begin
  if lin=UltimaL then nch:=DimUltimo
                 else nch:=9;
  txtbuf2:='';
  for h:=1 to nch do begin
    ch:=lin^.testo[h];
    case ch of
    #7,#8,#10,#13:txtbuf2:=txtbuf2+'#'+NumStr(ord(ch));
    else
      txtbuf2:=txtbuf2+ch;
    end;
  end;
  Gettxt2:=txtbuf2;
end;


procedure AggiornaTutto;
var buf:PLinea;
    h,i:byte;
    nch:byte;
begin
  buf:=linea;
  window(2,4,47,24);
  for i:=1 to 21 do begin
    if buf=nil then break;
    gotoxy(1,i);
    write(gettxt1(buf):45);
    buf:=buf^.succ;
  end;
  buf:=linea;
  window(50,4,79,24);
  for i:=1 to 21 do begin
    if buf=nil then break;
    gotoxy(1,i);
    write(gettxt2(buf):29);
    buf:=buf^.succ;
  end;
  if _mcy in [4..24] then begin
    evidenzia(2,_mcy,47,_mcy,$07);
    evidenzia(49,_mcy,79,_mcy,$07);
  end;
end;


procedure SchermataIniziale;
var i:byte;
begin
  TextBackground(7);
  TextColor(0);
  clrscr;
  write('ษอออออออออออออออออออออออออออออออออออออออออออออออออออออ'#24'ออ'#25'อออออPgUpออPgDnออออออป');
  write('บ',nome_sorgente);
  gotoxy(58,2); write('by Ernesto Cianciotta บ');
  write('ฬออออออออออออออออออออออออออออออออออออออออออออออัอออออออออออออออออออออออออออออออน');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('บ                                              ณ                               บ');
  write('ศออออออออออออออออออออออออออออออออออออออออออออออฯอออออออออออออออออออออออออออออออ');
  linea:=PrimaL;
  _linea:=linea;
  for i:=1 to 20 do
   if _linea^.succ<>nil then _linea:=_linea^.succ
                        else break;
  AggiornaTutto;
end;




procedure SalvaLinee;
var buf:PLinea;
    s:TStr;
    j:integer;
    precV:buffervideo;
    nch:byte;
begin
  precV:=visualvideo^;
  textattr:=$3a;
  window(2,2,79,2);
  clrscr;
  write('Salvataggio file in corso...');
  textattr:=$70;
  rewrite(_f,1);
  buf:=PrimaL;
  while buf<>nil do begin
    if buf=UltimaL then nch:=DimUltimo
                   else nch:=9;
    blockwrite(_f,buf^.testo,nch);
    buf:=buf^.succ;
  end;
  visualvideo^:=precv;
  close(_f);
  reset(_f);
end;


procedure Modifica;
const y2=15;
var buf:PLinea;
    ch:char;
    nch:byte;
    s:TStr;
begin
  if not selezionato then exit;
  buf:=linea;
  if _mcy<>4 then
    for i:=1 to _mcy-4 do
      if buf^.succ<>nil then buf:=buf^.succ
                        else exit;
  if buf=UltimaL then nch:=DimUltimo
                 else nch:=9;
  precV:=VisualVideo^;
  window(10,10,70,y2);
  HidemouseCursor;
  write('ษอออออออออออออออออัออออออModificaอออออออออออออออออออออออออออป');
  write('บ Vecchia stringa ณ                                         บ');
  write('วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤsolo ',nch,' caratteriฤฤฤฤฤฤฤฤถ');
  write('บ   Nuova Stringa ณ                                         บ');
  write('ศอออออออออออออออออฯอออออออออออออออออออออออออออออออออออออออออผ');
  evidenzia(29,11,69,11,$3A);
  evidenzia(29,13,69,13,$3E);
  evidenzia(12,y2,72,y2,$07);
  evidenzia(71,11,72,y2,$07);

  gotoxy(20,2);
  textAttr:=$3A;

  write(gettxt2(buf));
  ShowmouseCursor;
  txtbuf2:='';
  txtbuf:='';
  textattr:=$3e;
  for i:=1 to nch do begin
    ch:=readkey;
    f_buf[i]:=ch;
    case ch of
    #7,#8,#10,#13:txtbuf2:=txtbuf2+'#'+NumStr(buffer);
    else
      txtbuf2:=txtbuf2+ch;
    end;
    gotoxy(20,4);
    write(txtbuf2);
  end;
  buf^.testo:=f_buf;
  hidemouseCursor;
  visualVideo^:=precV;
  TextAttr:=$70;
  AggiornaTutto;
  evidenzia(2,_mcy,47,_mcy,$07);
  evidenzia(49,_mcy,79,_mcy,$07);
  ShowmouseCursor;
end;


procedure zoom;
const y2=17;
var nch:byte;
    buf:PLinea;
    h:byte;
begin
  if not selezionato then exit;
  buf:=linea;
  if _mcy<>4 then
    for i:=1 to _mcy-4 do
      if buf^.succ<>nil then buf:=buf^.succ
                        else exit;
  if buf=UltimaL then nch:=DimUltimo
                 else nch:=9;
  precV:=VisualVideo^;
  window(11,10,74,y2);
  HidemouseCursor;
  write('ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป');
  write('บ                             Zoom                             บ');
  write('ฬออออออัออออออัออออออัออออออัออออออัออออออัออออออัออออออัออออออน');
  write('บ      ณ      ณ      ณ      ณ      ณ      ณ      ณ      ณ      บ');
  write('วฤฤฤฤฤฤลฤฤฤฤฤฤลฤฤฤฤฤฤลฤฤฤฤฤฤลฤฤฤฤฤฤลฤฤฤฤฤฤลฤฤฤฤฤฤลฤฤฤฤฤฤลฤฤฤฤฤฤถ');
  write('บ      ณ      ณ      ณ      ณ      ณ      ณ      ณ      ณ      บ');
  write('ศออออออฯออออออฯออออออฯออออออฯออออออฯออออออฯออออออฯออออออฯออออออผ');
  evidenzia(12,11,73,11,$3A);
  evidenzia(13,y2,76,y2,$07);
  evidenzia(75,11,76,y2,$07);
  txtbuf:='';
  txtbuf2:='';
  for h:=1 to nch do begin
    buffer:=ord(buf^.testo[h]);
    if buffer<10 then
      txtbuf:=txtbuf+'   '
    else if buffer<100 then
      txtbuf:=txtbuf+'  '
    else txtbuf:=txtbuf+' ';
    txtbuf:=txtbuf+'#'+NumStr(buffer);
    gotoxy(2+(h-1)*7,4);
    write(txtbuf);
    txtbuf:='';

    ch:=buf^.testo[h];
    case ch of
    #7,#8,#10,#13:txtbuf2:=txtbuf2+'#'+NumStr(ord(ch));
    else
      txtbuf2:=txtbuf2+ch;
    end;
    gotoxy(5+(h-1)*7,6);
    write(txtbuf2);
    txtbuf2:='';
  end;
  ShowmouseCursor;
  while not keypressed and (PositionAndButtonStatus(mcx,mcy)<>1) do;
  if keypressed then readkey;
  hidemouseCursor;
  visualVideo^:=precV;
  ShowmouseCursor;
end;



procedure operativo1;
begin
  clrscr;
  gotoxy(1,24);
  writeln('Attendere!');
  write('Caricamento file in corso...');
  nome_sorgente:=paramstr(par);
  assign(_f,nome_sorgente);
  nome_sorgente:=FExpand(nome_sorgente);
  reset(_f,1);
  PrimaL:=nil;
  while not eof(_f) do begin
    NuovaLinea;
    blockread(_f,buf^.testo,9,DimUltimo);
  end;
  SchermataIniziale;
  selezionato:=false;
  showmouseCursor;
  while true do begin
    tasto:=PositionAndButtonStatus(mcx,mcy);
    case tasto of
    1: begin
         mcy:=mcy div 8+1;
         if _mcy<>mcy then begin
           if _mcy in [4..24] then begin
             hideMouseCursor;
             evidenzia(2,_mcy,47,_mcy,$70);
             evidenzia(49,_mcy,79,_mcy,$70);
             ShowMouseCursor;
           end;
           if mcy in [4..24] then begin
             selezionato:=true;
             hideMouseCursor;
             evidenzia(2,mcy,47,mcy,$07);
             evidenzia(49,mcy,79,mcy,$07);
             ShowMouseCursor;
           end
           else Selezionato:=false;
         end;
         _mcx:=mcx;
         _mcy:=mcy;
       end;
    2: begin
         zoom;
       end;
    end;

    if keypressed then begin
      ch:=readkey;
      case ch of
       #0: case readkey of
  { sale } #72: if linea^.prec<>nil then begin
                  linea:=linea^.prec;
                  _linea:=_linea^.prec;
                  AggiornaTutto;
                end;
  {scende} #80: if _linea^.succ<>nil then begin
                  linea:=linea^.succ;
                  _linea:=_linea^.succ;
                  AggiornaTutto;
                end;
  { PgUp } #73: if linea^.prec<>nil then begin
                  for i:=1 to 21 do
                    if linea^.prec<>nil then begin
                      linea:=linea^.prec;
                      _linea:=_linea^.prec;
                    end
                    else break;
                  AggiornaTutto;
                end;
  { PgDn } #81: if _linea^.succ<>nil then begin
                  for i:=1 to 21 do
                    if _linea^.succ<>nil then begin
                      linea:=linea^.succ;
                      _linea:=_linea^.succ;
                    end
                    else break;
                  AggiornaTutto;
                end;
{CTRL+PgUp}#132:begin
                  linea:=PrimaL;
                  _linea:=linea;
                  for i:=1 to 20 do
                    if _linea^.succ<>nil then _linea:=_linea^.succ
                                         else break;
                  AggiornaTutto;
                end;
{CTRL+PgDn}#118:begin
                  _linea:=UltimaL;
                  linea:=_linea;
                  for i:=1 to 20 do
                    if linea^.prec<>nil then linea:=linea^.prec
                                        else break;
                  AggiornaTutto;
                end;
           end;
      #13: Modifica;
      'S': Salvalinee;
      #27: break;
      end;
    end;

  end;
end;



procedure presentazione;
begin
  writeln('Micro Dump 1.0   (c) 1995 Ernesto Cianciotta');
  writeln('Sintassi:    DUMP [percorso]nomefile');
  writeln;
end;

begin
  if paramcount=0 then begin
    presentazione;
    exit;
  end;
  if lastmode=7 then visualVideo:=Ptr($B000,0) else VisualVideo:=ptr($B800,0);
  resetmouse;
  Eliminacursore;
  textbackground(0);
  textcolor(7);
  par:=1;

  operativo1;

  close(_f);
  HideMouseCursor;
  CancellaLinee;
  textbackground(0);
  textcolor(7);
  window(1,1,80,25);
  clrscr;
  SetDimCursor(13,14);
end.

