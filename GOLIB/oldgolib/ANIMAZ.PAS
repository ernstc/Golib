{ by Ernesto CIANCIOTTA Productions }


uses g_utile,timer,dos,crt,graph,graftool,bitmaps,font;

const Frames=16;


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





var i:word;
    pausa:word;


procedure SerifFont10; external; {$L serif10.obj}

procedure SuperVGA16; external; {$L svga16.obj}

procedure Frame1 ; external;  {$L c:\tp7\frames\frame1.obj}
procedure Frame2 ; external;  {$L c:\tp7\frames\frame2.obj}
procedure Frame3 ; external;  {$L c:\tp7\frames\frame3.obj}
procedure Frame4 ; external;  {$L c:\tp7\frames\frame4.obj}
procedure Frame5 ; external;  {$L c:\tp7\frames\frame5.obj}
procedure Frame6 ; external;  {$L c:\tp7\frames\frame6.obj}
procedure Frame7 ; external;  {$L c:\tp7\frames\frame7.obj}
procedure Frame8 ; external;  {$L c:\tp7\frames\frame8.obj}
procedure Frame9 ; external;  {$L c:\tp7\frames\frame9.obj}
procedure Frame10; external;  {$L c:\tp7\frames\frame10.obj}
procedure Frame11; external;  {$L c:\tp7\frames\frame11.obj}
procedure Frame12; external;  {$L c:\tp7\frames\frame12.obj}
procedure Frame13; external;  {$L c:\tp7\frames\frame13.obj}
procedure Frame14; external;  {$L c:\tp7\frames\frame14.obj}
procedure Frame15; external;  {$L c:\tp7\frames\frame15.obj}
procedure Frame16; external;  {$L c:\tp7\frames\frame16.obj}


begin
  _serif10_.RegisterFont(@SerifFont10);

  p:=@Frame1;  CreateCompatibleArea(CA[1],p^);
  p:=@Frame2;  CreateCompatibleArea(CA[2],p^);
  p:=@Frame3;  CreateCompatibleArea(CA[3],p^);
  p:=@Frame4;  CreateCompatibleArea(CA[4],p^);
  p:=@Frame5;  CreateCompatibleArea(CA[5],p^);
  p:=@Frame6;  CreateCompatibleArea(CA[6],p^);
  p:=@Frame7;  CreateCompatibleArea(CA[7],p^);
  p:=@Frame8;  CreateCompatibleArea(CA[8],p^);
  p:=@Frame9;  CreateCompatibleArea(CA[9],p^);
  p:=@Frame10;  CreateCompatibleArea(CA[10],p^);
  p:=@Frame11;  CreateCompatibleArea(CA[11],p^);
  p:=@Frame12;  CreateCompatibleArea(CA[12],p^);
  p:=@Frame13;  CreateCompatibleArea(CA[13],p^);
  p:=@Frame14;  CreateCompatibleArea(CA[14],p^);
  p:=@Frame15;  CreateCompatibleArea(CA[15],p^);
  p:=@Frame16;  CreateCompatibleArea(CA[16],p^);

  GraphParamControl:=false;
  InizializzaGrafica(3,16);

  SetAllPalette(GolibPalette);
  fullBar(7);
  for i:=1 to 15 do begin
    setcolor(i mod 2 + 7);
    rectangle(320-32-15+i,240-32-15+i,320+32+15-i,240+32+15-i);
  end;

  TextColor:=15;
  with _serif10_ do begin
    DrawText(10,150,'Dimostrativo sulle potenzialit… delle procedure per il');
    DrawText(10,165,'trasferimento di bits (BITBTL -> BIT Block Transfer Line) nel campo dell''animazione.');
  end;

  pausa:=64;
  squadr_1:=0;
  squadr_2:=0;

  readkey;

  for i:=1 to 64 do begin
    BitBtl(CA[1],VideoDC,0,64-i,320-32,240-32,64,i);
    delay((pausa-i) div 12);
  end;

  pausa:=10;

  with _serif10_ do begin
    DrawText(10,350,'Realizzato da Ernesto CIANCIOTTA (c) 1995');
    DrawText(10,380,'Tasti utilizzati:');
    DrawText(10,395,'   + , - , 7 , 9 , 1 , 3 , ESC');
  end;

  readkey;

  BitBtl(CA[1],VideoDC,0,0,320-32,240-32,64,64);

  while true do begin
    for i:=2 to Frames do begin
      BitBtl(CA[i],VideoDC,0,0,320-32,240-32,64,64);
      if keypressed then begin
        case readkey of
        #27: exit;
        '-': inc(pausa);
        '+': begin
               dec(pausa);
               if integer(pausa)<1 then pausa:=1;
             end;
        '7': if squadr_2<21 then inc(squadr_2);
        '9': begin
               dec(squadr_2);
               if integer(squadr_2)<1 then squadr_2:=1;
             end;
        end;
      end;
      delay(pausa+squadr_2);
    end;

    for i:=Frames-1 downto 1 do begin
      BitBtl(CA[i],VideoDC,0,0,320-32,240-32,64,64);
      if keypressed then begin
        case readkey of
        #27: exit;
        '-': inc(pausa);
        '+': begin
               dec(pausa);
               if integer(pausa)<1 then pausa:=1;
             end;
        '1': if squadr_1<21 then inc(squadr_1);
        '3': begin
               dec(squadr_1);
               if integer(squadr_1)<1 then squadr_1:=1;
             end;

        end;
      end;

      delay(pausa+squadr_1);
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


