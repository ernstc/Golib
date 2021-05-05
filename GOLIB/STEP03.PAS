{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



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


procedure Step03Resources; external; {$L step03.obj}

const
      _CIRCLE_ = $ABCD;



type
     OPCircleObj = ^OTCircleObj;
     OTCircleObj = object (OTView)
        constructor Init;
        procedure Disegna; virtual;
        procedure ExecMessage(var Message:TMessage); virtual;
        function SetCursor(x,y:integer):word; virtual;
     private
        mx,my:integer;
        NelCerchio,
        traccia: boolean;
     end;


     OPDimRect = ^OTDimRect;
     OTDimRect = object (OTView)
       constructor Init(x,y:integer);
       procedure Disegna; virtual;
     end;


     OPFinestra = ^OTFinestra;
     OTFinestra = object (OTFrame)
        procedure ExecMessage(var Message:TMessage); virtual;
     end;



                     {----- OTCircleObj -----}
     constructor OTCircleObj.Init;
       begin
         inherited Init(Null_ID,NullRect);
         AssignResource(12);

         { Bisognerebbe mettere qualcosa per indicare all'App Controller di
           non considerare le risorse. La chiamata a SetCursor, per•, deve
           avvenire lo stesso. }

         SysConfig:=SysConfig or cfPostDraw;
         MouseReactionMask:=MouseReactionMask or rcMove;
         mx:=-1;
         my:=-1;
         NelCerchio:=false;
         traccia:=false;
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
         if (Message.Message = EvMOUSE_MOVES) and NelCerchio then begin
            SetWriteMode(xorput);
            hidemousecursor;
            if mx>=0 then rect(mx,my);
            rect(Message.mcx,Message.mcy);
            showmousecursor;
            mx:=Message.mcx;
            my:=Message.mcy;
            traccia:=true;
         end;
         if ((Message.Message = EvMOUSE_MOVES_OUT) or not NelCerchio) and traccia then begin
           SetWriteMode(xorput);
           hidemousecursor;
           rect(mx,my);
           showmousecursor;
           mx:=-1;
           traccia:=false;
         end;
       end;


     function OTCircleObj.SetCursor(x,y:integer):word;
       var alfa,
           beta,
           raggio:real;
       begin
         alfa:=(R.x1+R.x2)/2;
         beta:=(R.y1+R.y2)/2;
         raggio:=R.DimX/2;
         if sqr(x-alfa)+sqr(y-beta) <= sqr(raggio)
           then begin
             NelCerchio:=true;
             SetCursor:=_CIRCLE_;
             SetMouseCursor(ResourcePtr^.cur,12);
           end
           else begin
             NelCerchio:=false;
             SetCursor:=Null_ID;
             SetMouseCursor(SystemCursor^,0);
           end;
       end;


                      {----- OTDimRect -----}
     constructor OTDimRect.Init(x,y:integer);
       begin
         R.SetRect(x,y,100,100);
         inherited Init(Null_ID,R);
         AssignResource(13);
         SysConfig:=SysConfig or cfPostDraw;
       end;


     procedure OTDimRect.Disegna;
       begin
         with R do begin
           rectangle(x1,y1,x2,y2);
           rectangle(x1+10,y1+10,x2-10,y2-10);
           rectangle(x1,y1,x1+10,y1+10);
           rectangle(x2-10,y1,x2,y1+10);
           rectangle(x2-10,y2-10,x2,y2);
           rectangle(x1,y2-10,x1+10,y2);
         end;
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
    dm:OTDimRect;

begin
  InizializzaGrafica(3,16);  {- Entra in modalit… grafica }

  AssignUserResources(@Step03Resources);

  r.SetRect(70,90,500,300);  {- Imposta l'angolo in alto a sinistra e la
                                dimensione orizzontale e verticale della
                                finestra }

  c.Init;

  dm.Init(0,0);

  { Segue la inizializzazione della finestra 1 }
  windowObj1.Init( r,
                { Intestazione della finestra 1 }
                new(OPFullHeader, Init( StrNewPas('Programma dimostrativo con livello di difficolta'' 3.'),
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
  windowObj1.AddOther(@dm, NewLayoutMetrics(
                                      NewLayout(LmLeft,InPixels,80),
                                      NewLayout(LmTop,InPixels,80),
                                      NewLayout(LmWidth,InPixels,100),
                                      NewLayout(LmHeight,InPixels,100),
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

  StartApplication;         {- Fa partire l'applicazione }
end.