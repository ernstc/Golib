{ by Ernesto CIANCIOTTA Productions }


uses timer,dos,crt,graph,graftool,bitmaps;


var BMP_FileName:string;
    BMP:file;

    bmpM1,bmpM2:pointer;

    Result:word;



var p:pointer;
    CA:array[1..2] of HCA;
    ca2,_ca_:hca;
    _x_,_y_,dx,dy:word;
    numprove:word;

    w:byte;





var i:word;

begin
  {if paramcount=0 then begin
    writeln;
    writeln('** by Ernesto CIANCIOTTA Productions (c) 1995 **');
    writeln;
    writeln('   Sintassi:  BMP_DEMO file_bmp');
    exit;
  end;

  {Caricamento del file BMP in memoria }
  {LoadBitMap(bmpM,paramstr(1));}




  LoadBitMap('c:\tp7\bwcc\ok_rlsd.bmp',bmpM1);
  LoadBitMap('c:\tp7\bwcc\ok_prsd.bmp',bmpM2);



  GraphParamControl:=false;
  InizializzaGrafica(3,16);

  SetAllPalette(GolibPalette);
  fullBar(0);




  randomize;

  CreateCompatibleArea(CA[1],bmpM1^);
  CreateCompatibleArea(_CA_,bmpM2^);
  CA[2]:=_ca_;


  CreateCompatibleDC(ca2,640,480);


  BitBtl(CA[2],VideoDC,0,0,0,0,CA[1].DimX,CA[1].DimY);
  readkey;


  GTimerStart;

{for i:=1 to 10 do begin
  cleardevice;}
  _y_:=0;
  _x_:=0;
  dx:=CA[1].DimX;
  dy:=CA[1].DimY;
  while _y_<MaxYResolution do begin
    BitBtl(CA[1],VideoDC,0,0,_x_,_y_,dx,dy);
    _x_:=_x_+CA[1].DimX;
    if _x_+dx>MaxXResolution then dx:=MaxXResolution-_x_;
    if _y_+dy>MaxYResolution then dy:=MaxYResolution-_y_;
    if _x_>MaxXResolution then begin
      _x_:=0;
      dx:=CA[1].DimX;
      inc(_y_,CA[1].DimY);
    end;
  end;
{end;}

  GTimerStop;





  _y_:=0;
  _x_:=0;
  dx:=CA[1].DimX;
  dy:=CA[1].DimY;
  while _y_<MaxYResolution do begin
    BitBtl(CA[1],Ca2,0,0,_x_,_y_,dx,dy);
    _x_:=_x_+CA[1].DimX;
    if _x_+dx>MaxXResolution then dx:=MaxXResolution-_x_;
    if _y_+dy>MaxYResolution then dy:=MaxYResolution-_y_;
    if _x_>MaxXResolution then begin
      _x_:=0;
      dx:=CA[1].DimX;
      inc(_y_,CA[1].DimY);
    end;
  end;

  GTimerStart;


  for i:=1 to 10 do begin
    cleardevice;
    bitbtl(ca2,VideoDC,0,0,0,0,640,480);
  end;

  GTimerStop;


end.




  fullbar(random(13)+1);
  while not keypressed do
    BitBtl(CA[random(2)+1],VideoDC,0,0,random(600),random(400),CA[1].DimX,CA[1].DimY);
  numprove:=100;

  readkey;

  GTimerStart;
  for i:=1 to numprove do
    BitBtl(VideoDC,VideoDC,0,0,1,0,numprove,numprove);

  GTimerStop;

  readkey;
  fullbar(random(13)+1);
  while not keypressed do
    BitBtl(CA[random(2)+1],VideoDC,0,0,random(600),random(400),CA[1].DimX,CA[1].DimY);


  resettimer;
  starttimer;
  for i:=1 to numprove do
    BitBtlMove(0,0,1,0,numprove,numprove);
  blocktimer;
  restorecrtmode;
  writelntimerstate;
  while keypressed do readkey;
  readkey;

end.