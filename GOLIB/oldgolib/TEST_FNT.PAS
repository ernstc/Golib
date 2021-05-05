uses
     codici,
     utility,
     keyboard,
     graph,
     graftool,
     fonts;

var
   fnt:OTFont;
   i,j:integer;
   s:string;


begin
  s:='ABCDEFGHIJKLMNOPQRSTUVXYWZ';
  InizializzaGrafica(3,16);
  fnt.Init;
  fnt.LoadFontFrom('c:\tp7\serife.fnt');
  setfillstyle(1,0);
  i:=-1;
  j:=0;
  bar(i,j,i+400,j+40);
  fnt.DrawText(i,j,TextLeft,s);
  repeat
    case GetKeyStroke of
    kbLeft:  dec(i);
    kbRight: inc(i);
    kbUp:    dec(j);
    kbDown:  inc(j);
    kbSpace: break;
    kbEnter: begin
       bar(550,400,639,479);
       fnt.DrawText(550,400,TextLeft,'i = '+NumStr(i));
       fnt.DrawText(550,450,TextLeft,'j = '+NumStr(j));
       continue;
    end;
    else continue;
    end;
    bar(i-1,j-1,i+400,j+40);
    fnt.DrawText(i,j,TextLeft,s);
  until false;
  cleardevice;
  fnt.DrawText(10,200,TextLeft,'FINE !');
  repeat until CheckForKeyStroke;
end.