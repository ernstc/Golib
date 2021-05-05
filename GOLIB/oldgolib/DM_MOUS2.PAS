{ by ERNESTO CIANCIOTTA }
uses dos,crt,graph,g_utile,graftool,mouse,fonts;


const crs:array[1..32] of word =
      ($EE00,
       $1000,
       $1000,
       $1000,
       $100f,
       $100f,
       $100f,
       $100f,
       $100f,
       $100f,
       $100f,
       $100f,
       $1000,
       $1000,
       $1000,
       $EE00,



       $FFFF,
       $FFFF,
       $FFFF,
       $FFFF,
       $FFF0,
       $FFF0,
       $FFF0,
       $FFF0,
       $FFFF,
       $FFFF,
       $FFFF,
       $FFFF,
       $FFF0,
       $FFF0,
       $FFF0,
       $FFF0);



var x:word;
    y:word;
    px,py:word;

    e:boolean;
    i,num:word;
    f:OTFont absolute _serif10_;

    cr2:array[1..32,1..2] of word;

    Int33:pointer;


{$F+}
procedure prova; interrupt; assembler;
  asm
    push 639
    push dx
    push 0
    push dx
    call line
  end;
{$F-}


begin
  InizializzaGrafica(3,16);

  textcolor:=0;
  fullbar(7);
  for i:=1 to 16 do incavo3d(40+i*21,70,60+i*21,90,i);
  setfillstyle(1,7);

  num:=resetMouse;
  f.drawtext(10,100,TextLeft,NumStr(num)+' Tasti');
  PositionMouseCursor(10,400);

  ShowMouseCursor;
  readkey;
  HideMouseCursor;

  GetIntVec($33,Int33);
  SetAlternateMouseHandler($0081,@prova);
  showmousecursor;
  while true do;
end.