{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



uses
    crt,
    mouse,
    graftool,
    golib9;



  procedure disegnoInside(params:PDrawParameters; x,y:integer);
  far;
     begin
       with params^.rect do Incavo3D(x1+x,y1+y,x2+x,y2+y,6);
     end;



var o1,o2:OTBar;
    r:OTRect;


begin
  InizializzaGrafica(3,16);
  EnableVideo;
  hidemousecursor;

  r.SetRect(10,10,200,200);
  o1.Init(0,r,1,7);
  o1.PutOnDeskTop;
  o1.Disegna;

  r.SetRect(50,50,100,100);
  o2.Init(0,r,1,0);
  o2.PutOnDeskTop;
  o2.Disegna;

  readkey;

  o1.DrawInside(10,10,150,130,@disegnoInside,nil);

  readkey;

  o1.Done;
  o2.Done;
end.