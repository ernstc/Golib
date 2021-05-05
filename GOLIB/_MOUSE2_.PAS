{ (c) Ernesto CIANCIOTTA Productions 1996 }

uses
     crt,
     graph,
     fonts,
     utility,
     graftool,
     mouse2;

var
   b,precx,precy,mx,my:word;
   _precx,_precy,_mx,_my:integer;

begin
  InizializzaGrafica(3,16);
  M_Show;
  precx:=0;
  precy:=0;
  _precx:=0;
  _precy:=0;
  setfillstyle(1,0);
  while not keypressed do begin
    M_GetPos(b,mx,my);
    M_ReadMotion(_mx,_my);
    if (mx<>precx) or (my<>precy) {or (_mx<>_precx) or (_my<>_precy)} then begin
      m_hide;
      bar(0,0,600,100);
      serife83.DrawText(20,20,textleft,'X = '+NumStr(mx)+'    Y = '+NumStr(my));
      serife83.DrawText(20,50,textleft,'m X = '+NumStr(_mx)+'    m Y = '+NumStr(_my));
      {_precx:=_mx;
      _precy:=_my;}
      precx:=mx;
      precy:=my;
      m_show;
    end;
  end;
end.