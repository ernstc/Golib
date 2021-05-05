uses crt,
     fonts,
     graph,
     timer,
     graftool;

var symbole4,
    symbole6,
    sserife,
    vgasys,
    cour3,
    borte,
    serife83:OTFont;

    h,j,i:integer;
    l:longint;


procedure Rect;
  var view:ViewPortType;
  begin
    GetViewSettings(view);
    setcolor(14);
    with view do rectangle(0,0,x2-x1,y2-y1);
  end;


begin
  symbole4.Init;
  symbole6.Init;
  sserife.Init;
  vgasys.Init;
  cour3.Init;
  serife83.Init;

  symbole4.LoadFontFrom('c:\tp7\symbole4.fnt');
  symbole6.LoadFontFrom('c:\tp7\symbole6.fnt');
  sserife.LoadFontFrom('c:\tp7\sserife.fnt');
  vgasys.LoadFontFrom('c:\tp7\vgasys.fnt');
  cour3.LoadFontFrom('c:\tp7\cour92.fnt');
  borte.LoadFontFrom('c:\tp7\borte.fnt');
  serife83.LoadFontFrom('c:\tp7\sserife.fnt');

  InizializzaGrafica(3,16);
{  fullbar(15);
}  setfillstyle(1,1);
  bar(165,10,300,100);

{  setviewPort(0,0,156,100,true);
  rect;
}
  setfillstyle(1,12);
  bar(150,80,500,300);

  readkey;

  rect;

  setfillstyle(1,0);
  i:=100;

  TextColor:=1;
  vgasys.DrawText(115,260,textleft,'Windows ''95');

  TextColor:=2;
  symbole6.DrawText(115,160,textleft,'Windows ''95');

  TextColor:=3;
  cour3.DrawText(70,70,textleft,'PlanetSoft''s  Golib ''95 ');

  TextColor:=4;
  serife83.DrawText(115,360,textleft,'Ernesto');

  TextColor:=14;
  borte.DrawText(245,360,textleft,'Cianciotta');

  rect;
  readkey;

  textcolor:=15;

  DisableVideo;

{$DEFINE prova3}


{$IFDEF prova1}
  GTimerStart;
  for j:=1 to 100 do begin
    textcolor:=random(15);
    for i:=1 to 45 do begin
      cour3.DrawText(10+random(200),0+12*i,TextLeft,'ABCDEFGHIJKLMOPQRSTUVWXYZabcdefghijklmopqrstuvwxyz0123456789');
      {readkey;}
    end;
  end;
  EnableVideo;
  GTimerStop;
{$ENDIF}





{$IFDEF prova2}
  h:=symbole6.GetHeight;
  GTimerStart;
  for j:=1 to 200 do
  for i:=1 to 13 do begin
    textcolor:=j and $F;
    symbole6.DrawText(10,h*(i-1),TextLeft,'ABCDEFGHIJKLMOPQRSTUVWXYZabcdefghijklmopqrstuvwxyz0123456789');
  end;
  EnableVideo;
  GTimerStop;
{$ENDIF}





{$IFDEF prova3}
  GTimerStart;
  for j:=1 to 50 do
    for i:=1 to 450 do begin
      textcolor:=random(15);
      sserife.DrawText(10+j*3,0+i,TextLeft,'Curier Font 123456789mmmmmmmmmmmmmmmmmmmmmmmmmmmmmm');
    end;
  EnableVideo;
  GTimerStop;
{$ENDIF}

end.