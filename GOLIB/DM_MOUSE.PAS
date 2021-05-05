{ by ERNESTO CIANCIOTTA }
uses crt,graph,graftool,mouse,fonts;


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


function NumStr(num:longint):string;
     var s:string;
     begin
       str(num,s);
       NumStr:=s;
     end;



procedure FullBar(colore:word);
     begin
       setfillstyle(1,colore);
       bar(0,0,getmaxx,getmaxy);
     end;

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

  {DefineGraphicCursor(crs,-16,-16);}
  SetLargeGraphicsCursorBlock(cr2,1,1);
  while true do;
  ShowMouseCursor;
  px:=1000;
  py:=1000;
  PositionMouseCursor(0,0);
  while not keypressed do begin

    px:=x;
    py:=y;
    x:=xCursor;
    y:=yCursor;
    if (px<>x) or (py<>y) then begin
      bar(10,460,70,479);
      f.drawtext(10,460,TextLeft,numstr(x)+' : '+numstr(y));
    end;
  end;
  readkey;
  DefineThreSholdSpeed(0);

  setfillstyle(1,0);
  f.drawtext(250,50,TextLeft,'Prova Tasti');
  while not keypressed do begin
    case PositionAndButtonStatus of
    1: begin
      setfillstyle(1,0);
      bar(1,1,30,30);
      delay(100);
      setfillstyle(1,7);
      bar(1,1,30,30);
    end;
    4: begin
      setfillstyle(1,0);
      bar(370,1,400,30);
      delay(100);
      setfillstyle(1,7);
      bar(370,1,400,30);
    end;
    2: begin
      setfillstyle(1,0);
      bar(638,1,610,30);
      delay(100);
      setfillstyle(1,7);
      bar(638,1,610,30);
    end;
  end;
  end;
  readkey;

  {
  setlargegraphicscursorblock(4,16,8,8,crs);
  if getmouseresult<>$FFFF then exit;
  }


  rilievo3d(60,60,300,300,7);
  DefineCursorRange(61,61,298,297);
  readkey;

  DefineCursorRange(0,0,639,479);
  nowindowmouse(62,62,292,293);
  readkey;
  showmousecursor;

  DefinePixelRatio(1,100);
  readkey;
  DefinePixelRatio(100,1);
  readkey;
  DefinePixelRatio(1,1);
  readkey;



  HideMouseCursor;



  readkey;
end.