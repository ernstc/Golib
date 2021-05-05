{ (c) 1994,96 Ernesto CIANCIOTTA Productions }
{ Programma dimostravo con livello di difficolt… bassissimo. }
uses
     codici,
     graph,
     mouse,
     strings,   {- Primitive per la gestione delle stringhe ASCIIZ }
     graftool,  {- Primitive grafiche per il disegno degli oggetti }
     golib9,    {- Modulo principale della libreria }
     applic,    {- Gestore dell'applicazione }
     frame2,    {- Modulo contenente l'oggetto finestra }
     w_header,  {- Modulo di utilit… per la creazione delle intestazioni
                   per le finestre }
     window2,
     golib_h,
     __menu;


{$I lente.pcr}

const
      _CIRCLE_ = $ABCD;



type
     OPCircleObj = ^OTCircleObj;
     OTCircleObj = object (OTView)
        constructor Init;
        procedure Disegna; virtual;
        procedure ExecMessage(var Message:TMessage); virtual;
        function SetCursor(x,y:integer):word; virtual;
        function GetHotSpots(ResID:word):PHotSpotsArray; virtual;
     private
        mx,my:integer;
     end;

     OPFinestra = ^OTFinestra;
     OTFinestra = object (OTFrame)
        procedure ExecMessage(var Message:TMessage); virtual;
     end;



                     {----- OTCircleObj -----}
     constructor OTCircleObj.Init;
       begin
         inherited Init(Null_ID,NullRect);
         SysConfig:=SysConfig or cfPostDraw;
         CursorID:=2;
         MouseReactionMask:=MouseReactionMask or rcMove;
         MarkHotSpot(2,lente_cursore,8,8);
         mx:=-1;
         my:=-1;
       end;


     procedure OTCircleObj.Disegna;
       begin
         SetColor(0);
         Circle(round((R.x1+R.x2)/2),round((R.y1+R.y2)/2),round(R.DimX/2));
       end;

     procedure OTCircleObj.ExecMessage(var Message:TMessage);
       const rd=10;

       procedure Rect(x,y:integer);
         begin
           rectangle(x-rd,y-rd,
                     x+rd,y+rd);
         end;

       begin
         setcolor(15);
         case Message.Message of
         EvMOUSE_MOVES: begin
               SetWriteMode(xorput);
               hidemousecursor;
               if mx>=0 then rect(mx,my);
               rect(Message.mcx,Message.mcy);
               showmousecursor;
               mx:=Message.mcx;
               my:=Message.mcy;
            end;
         EvMOUSE_MOVES_OUT: begin
               SetWriteMode(xorput);
               hidemousecursor;
               rect(mx,my);
               showmousecursor;
               mx:=-1;
            end;
         end;
       end;


     function OTCircleObj.SetCursor(x,y:integer):word;
       var a,b,c,
           alfa,
           beta,
           raggio:real;
       begin
         alfa:=(R.x1+R.x2)/2;
         beta:=(R.y1+R.y2)/2;
         raggio:=R.DimX/2;
         a:=-2*alfa;
         b:=-2*beta;
         c:=sqr(alfa)+sqr(beta)-sqr(raggio);
         if sqr(x)+sqr(y)+a*x+b*y+c=0
           then SetCursor:=_CIRCLE_
           else SetCursor:=Null_ID;
       end;


     function OTCircleObj.GetHotSpots(ResID:word):PHotSpotsArray;
       begin
         GetHotSpots:=nil;
       end;



                     {----- OTFinestra -----}
     procedure OTFinestra.ExecMessage(var Message:TMessage);
       begin
         inherited ExecMessage(Message);
         if Message.Message=_CIRCLE_ then begin
           Deselect;
           Select;
         end;
       end;




var windowObj1:OTFinestra; {- oggetto finestra 1}
    windowObj2:OTFrame;    {- oggetto finestra 2}
    r:OTRect;           {- oggetto rettangolo; non Š un oggetto visualizzabile }
    c:OTCircleObj;

begin
  InizializzaGrafica(3,16);  {- Entra in modalit… grafica }

  r.SetRect(70,90,500,300);  {- Imposta l'angolo in alto a sinistra e la
                                dimensione orizzontale e verticale della
                                finestra }

  c.Init;

  { Segue la inizializzazione della finestra 1 }
  windowObj1.Init( r,
                { Intestazione della finestra 1 }
                new(OPFullHeader, Init( StrNewPas('Programma dimostrativo con livello di difficolta'' bassissimo.'),
                                       true,
                                       true,
                                       true)
                )
  );
  windowObj1.AddMenu(GetDemoMenu,_nord_);
  windowObj1.AddOther(@c, NewLayoutMetrics(
                                      NewLayout(LmLeft,InPixels,0),
                                      NewLayout(LmTop,InPixels,0),
                                      NewLayout(LmWidth,InPixels,50),
                                      NewLayout(LmHeight,InPixels,50),
                                      LmOther,nil)
  );

  r.moverel(40,40);
  { Segue la inizializzazione della finestra 2 }
  windowObj2.Init( r,
                { Intestazione della finestra 2 }
                new(OPNormalHeader, Init( StrNewPas('Finestra 2'))
                )
  );

  windowObj2.PutOnDeskTop;  {- Fa si che la finestra 2 venga posizionata sul Desktop }
  windowObj1.PutOnDeskTop;  {- Fa si che la finestra 1 venga posizionata sul Desktop }

  StartApplication;      {- Fa partire l'applicazione }
end.