{ by Ernesto CIANCIOTTA Productions }

program Prova_editor;

uses
     g_utile,
     codici,

     dos,
     crt,
     strings,
     mouse,
     graph,
     graftool,
     golib8,
     applic{,
     editor }
    ;


{var e:OTEditBox;
    r:OTRect;}

begin
  InizializzaGrafica(3,16);
{  r.SetRect(100,100,200,200);
  e.Init(Null_ID,r);
  e.PutOnDesktop;}
  StartApplication;
end.