{ by Ernesto CIANCIOTTA Productions (c) 1996 }

uses
    crt,
    graph,
    timer,
    graftool,
    bitmaps;


const
     { Modalit… di scrittura per BarGoLIB }
     wmNormal = $00;
     wmAND    = $08;
     wmOR     = $10;
     wmXOR    = $18;


procedure BarGoLIB_old(x,y:integer; DimX,DimY:word; colore:word); far;
external;
{$L bar_slow.obj}

procedure BarGoLIB(x,y:integer; DimX,DimY:word; colore:word; wm:byte); far;
external;
{$L bar.obj}


var
   bmp:pointer;
   bmpHCA:HCA;
   i,j:word;

begin
  InizializzaGrafica(3,16);
  fullbar(4);
  LoadBitMap('c:\tp7\golib8.bmp\golib8tm.bmp',bmp);
  CreateCompatibleArea(bmpHCA,bmp^);
  BitBtl(bmpHCA,VideoDC,0,0,0,0,bmpHCA.DimX,bmpHCA.DimY);

  while readkey<>#27 do BarGoLIB(0,0,630,470,15,wmxor);

  exit;

  SetWriteMode(1);
  SetFillStyle(1,3);

  GTimerStart;
  for j:=0 to 2 do begin
    {
    for i:=1 to 630 do BarGoLIB_old(j,0,i,470,3);
    for i:=1 to 470 do BarGoLIB_old(j,0,630,i,4);
    for i:=1 to 470 do BarGoLIB_old(j,0,i,i,5);
    }
    for i:=1 to 630 do BarPat(j,0,j-1+i,470-1);
    for i:=1 to 470 do BarPat(j,0,j-1+630,i-1);
    for i:=1 to 470 do BarPat(j,0,j-1+i,i-1);

  end;
  GTimerStop;

  fullbar(4);
  BitBtl(bmpHCA,VideoDC,0,0,0,0,bmpHCA.DimX,bmpHCA.DimY);

  GTimerStart;
  for j:=0 to 2 do begin
    for i:=1 to 630 do BarGoLIB(j,0,i,470,3,wmXor);
    for i:=1 to 470 do BarGoLIB(j,0,630,i,4,wmXor);
    for i:=1 to 470 do BarGoLIB(j,0,i,i,5,wmXor);
  end;
  GTimerStop;


  {LoadBitMap('c:\tp7\golib8.bmp\golib8tm.bmp',bmp);
  CreateCompatibleArea(bmpHCA,bmp^);
  BitBtl(bmpHCA,VideoDC,0,0,0,0,bmpHCA.DimX,bmpHCA.DimY);}


end.