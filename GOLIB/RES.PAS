uses crt,graph,graftool,bitmaps,bitmap,golib8,w_intest;

var bmp:OTBackground;
    CA:HCA;
    i:word;
    ww:OTWindow;
    r:OTRect;

begin
  InizializzaGrafica(3,16);

{  asm
    (* Attiva il refresh della memoria video *)
    MOV AH,12H
    MOV BL,36H
    MOV AL,0
    INT 10H
  end;
}

  bmp.Init('c:\tp7\golib8.bmp\golib8tm.bmp',true);
  bmp.PutOnDesktop;


  r.assign(0,0,100,100);
  ww.Init(Null_ID,r,'Res.EXE - Prova Background',FullIntestParam(true,true,true));
  ww.PutOndesktop;


  StartApplication;
end.















{
  SetAllPalette(GolibPalette);
  LoadBitmap('c:\windows\leaves.bmp',bmp);
  CreateCompatibleArea(CA,bmp^);

  SetViewPort(0,48,639,100,true);
  bitbtl(CA,VideoDC,0,0,0,0,CA.DimX,CA.DimY);

  readkey;

  SetViewPort(0,48,639,100,false);
  bitbtl(CA,VideoDC,0,0,-100,0,CA.DimX,CA.DimY);

  readkey;
  }