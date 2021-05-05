{ Ernesto CIANCIOTTA Productions }

{ Programma Demo per la ricerca dell'errore generato dalla "assenza del  }
{ campo typename" dell'oggetto OTView.                                   }


{*********************************************************************}
{ N.B.:             ERRORE ELIMINATO IL 17/7/1995
{*********************************************************************}


uses
      crt,

      graftool,
      golib8,
      window,
      menu,
      __menu,
      w_intest;


var  Vista:OTWindow;
     r:OTRect;
begin
  SelectedItemColor:=11;
  SelectedTextColor:=0;

  InizializzaGrafica(3,16);
  asm
    MOV AH,12H
    MOV BL,36H
    MOV AL,0
    INT 10H      (* Attiva il refresh della memoria video *)
  end;
{  readkey;}
  r.assign(0,0,239,130);



  Vista.Init(r,'Prova Testo',fullintestparam(true,true,true));
  Vista.AddOther( new(OPIncavo3d,Init(Null_ID,r,1,15)),
                                  NewLayoutMetrics(
                                      NewLayout(LmLeft,InPixels,0)^,
                                      NewLayout(LmTop,InPixels,0)^,
                                      NewLayout(LmRight,InPixels,0)^,
                                      NewLayout(LmBottom,InPixels,2)^,
                                      LmOther,@Vista.RectOther)
  );
  Vista.AddMenu(GetDemoMenu3,_nord_);



  Vista.PutOnDesktop;
  StartApplication;
end.