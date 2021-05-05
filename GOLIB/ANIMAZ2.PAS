{ by Ernesto CIANCIOTTA Productions }


uses g_utile,timer,dos,crt,graph,graftool,bitmaps,font,
     frame1,
     frame2,
     frame3,
     frame4,
     frame5,
     frame6;

const Frames=6;


var BMP_FileName:string;
    BMP:file;

    bmpM:array[1..Frames] of pointer;

    Result:word;



var p:pointer;
    CA:array[1..Frames] of HCA;
    ca2:hca;
    _x_,_y_,dx,dy:word;
    numprove:word;

    squadr_2,squadr_1:word;

    dimension:word;
    MaxXResolution_2,
    MaxYResolution_2:word;



var i:word;
    pausa:word;
    incremento:shortint;


procedure SerifFont10; external; {$L c:\tp7\obj\serif10.obj}


begin
  _serif10_.RegisterFont(@SerifFont10);

  p:=@Frame1_;  CreateCompatibleArea(CA[1],p^);
  p:=@Frame2_;  CreateCompatibleArea(CA[2],p^);
  p:=@Frame3_;  CreateCompatibleArea(CA[3],p^);
  p:=@Frame4_;  CreateCompatibleArea(CA[4],p^);
  p:=@Frame5_;  CreateCompatibleArea(CA[5],p^);
  p:=@Frame6_;  CreateCompatibleArea(CA[6],p^);

  GraphParamControl:=false;
  InizializzaGrafica(3,16);
  MaxXResolution_2:=MaxXResolution div 2;
  MaxYResolution_2:=MaxYResolution div 2;

  SetAllPalette(GolibPalette);
  setfillstyle(1,7);
  graph.bar(0,0,MaxXResolution,MaxYResolution);
  fullBar(7);
  for i:=1 to 15 do begin
    setcolor(i mod 2 + 7);
    rectangle(MaxXResolution_2-128-15+i,MaxYResolution_2-128-15+i,MaxXResolution_2+128+15-i,MaxYResolution_2+128+15-i);
  end;

  TextColor:=15;
  with _serif10_ do begin
    DrawText(10,50,'Dimostrativo sulle potenzialit… delle procedure per il');
    DrawText(10,65,'trasferimento di bits (BITBTL -> BIT Block Transfer Line) nel campo dell''animazione.');
  end;

  squadr_1:=0;
  squadr_2:=0;

  readkey;

  for i:=1 to 256 do begin

    BitBtl(VideoDC,VideoDC,MaxXResolution_2-128,MaxYResolution_2-128,MaxXResolution_2-128,MaxYResolution_2-128+1,256,i);
    BitBtl(CA[1],VideoDC,0,256-i,MaxXResolution_2-128,MaxYResolution_2-128,256,1);
{
    BitBtl(CA[1],VideoDC,0,256-i,MaxXResolution_2-128,MaxYResolution_2-128,256,i);
}
  end;


  with _serif10_ do begin
    DrawText(10,400,'Realizzato da Ernesto CIANCIOTTA (c) 1995');
    DrawText(10,415,'Tasti utilizzati:');
    DrawText(10,430,'  + , - , 0 , ESC');
  end;

  readkey;

  BitBtl(CA[1],VideoDC,0,0,MaxXResolution_2-128,MaxYResolution_2-128,256,256);

  dimension:=256;
  incremento:=-1;

  while true do begin
    for i:=2 to Frames do BitBtl(CA[i],VideoDC,0,0,MaxXResolution_2-128,MaxYResolution_2-128,dimension,dimension);
    for i:=Frames-1 downto 1 do BitBtl(CA[i],VideoDC,0,0,MaxXResolution_2-128,MaxYResolution_2-128,dimension,dimension);
    inc(dimension,incremento);
    if dimension=256
      then incremento:=-1
      else if dimension=1 then incremento:=1;
    if keypressed then
      case readkey of
      #27: exit;
      '+': if dimension<256 then incremento:=1;
      '-': if dimension>1 then incremento:=-1;
      '0': incremento:=0;
      end;
  end;

  readkey;
end.


{ partizione di programma per testare a quale dimensione massima e risoluzione
  si riesce a raggiungere la velocit… di 25 frames al secondo }


{
  Risultati del test al 8/4/1995:

  - risoluzione video 320x200x16:
    a) 28.5 frames/sec. full screen;

  - risoluzione video 640x200x16:
    a) 28 frames/sec. 320x200;
    b) 25 frames/sec. 370x200

  - risoluzione video 640x350x16:
    a) 28 frames/sec. 320x200;
    b) 25 frames/sec. 256x256

  - risoluzione video 640x480x16:
    a) 28 frames/sec. 320x200;
    b) 25 frames/sec. 256x256;

  - risoluzione video 800x600x16:
    a) 16.2 frames/sec. 320x200;
    b) 25 frames/sec. 192x192;

}


