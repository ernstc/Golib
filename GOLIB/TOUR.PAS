{ (c) 1994,96 Ernesto CIANCIOTTA Productions }
uses
    codici,
    keyboard,
    utility,
    fonts,
    graph,
    graftool,
    bitmaps;

var
   s:string;
   i:word;
   x,y:integer;
   bmp:pointer;
   h:HCA;
   f:file;
   max:word;

procedure header;
  begin
    writeln('TOUR (c) 1996 by Ernesto CIANCIOTTA Productions');
    writeln;
  end;

begin
  if paramcount=0 then begin
    header;
    writeln('Sintassi ->  TOUR <pack name>');
    writeln;
    writeln;
    writeln('Visualizzatore di files bitmapped a 16 colori.');
    halt(0);
  end
  else if length(paramstr(1)) >=8 then begin
    header;
    writeln('Avviso! : Il packd name non deve essere pi— lungo di sette caratteri.');
    halt(1);
  end;
  s:=paramstr(1)+'0.bmp';
  assign(f,s);
  {$I-}
  reset(f);
  {$I+}
  if ioresult<>0 then begin
    header;
    writeln('Avviso! : Nessun file trovato del tipo ',StrUpperPas(s),'.BMP');
    halt(1);
  end
  else close(f);
  inizializzagrafica(3,16);
  SetAllPalette(GolibPalette);
  {Enablevideo;}
  fullbar(8);
  TextColor:=0;
  serife83.DrawText(10,20,TextLeft,'TOUR (c) 1996 by ECP');
  serife83.DrawText(10,450,TextLeft,'Premere un tasto per continuare . . .');
  i:=0;
  while true do begin
    s:=paramstr(1)+NumStr(i)+'.bmp';
    assign(f,s);
    {$I-}
    reset(f);
    {$I+}
    if ioresult<>0
      then begin
        max:=i-1;
        break;
      end
      else close(f);
    i:=i+1;
  end;
  i:=0;
  while true do begin
    s:=paramstr(1)+NumStr(i)+'.bmp';
    LoadBitmap(s,bmp);
    CreateCompatibleArea(h,bmp^);
    x:=((MaxXResolution-h.DimX) div 2) and $FFF8;
    y:=((MaxYResolution-h.DimY) div 2) and $FFF8;
    BitBtl(h,VideoDC,0,0,x,y,h.DimX,h.DimY);
    DisposeBMP(bmp);
    DestroyDC(h);
    while true do
      case GetKeyStroke of
      kbRight,kbUp:
               if i<max then begin
                 i:=i+1;
                 break;
               end;
      kbLeft,kbDown:
               if i>0 then begin
                 i:=i-1;
                 break;
               end;
      kbEsc:   halt(0);
      kbHome: begin
                i:=0;
                break;
              end;
      kbEnd: begin
                i:=max;
                break;
              end;
      end;
  end;
end.
