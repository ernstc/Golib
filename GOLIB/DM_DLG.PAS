{ Ernesto CIANCIOTTA Productions }

program Esempio_DialogBox;

uses menu,
     strings,
     crt,
     mouse,
     graph,
     graftool,
     codici,
     applic,
     golib_h,
     golib9,
     fonts,
     w_header,
     buttons,
     __menu,{
     scrolls,}
     bitmap,
     window2,
     frame2;


{type WIcon=object(OTBitmap)
       procedure Reaction; virtual;
     end;


     procedure WIcon.Reaction;
       begin
         PutOnFirst;
         EvMoveObject;
       end;
}


var www1,www3:OTFrame;
    r:OTRect;
    view:OPView;
    bmp:OTBackground;
    bmpC:boolean;
    l:OPLayoutMetrics;

    v2,variabile:boolean;
    _w_:word;
    _l_:longint;
    bmp_p:boolean;

    {icon:WIcon;}

begin
  WaitInRefreshDelay:=-1;

  MakeSpecialEffect:=true;
  GraphParamControl:=false;
  LookVideoOnShutDown:=false;
  SelectedItemColor:=11;
  SelectedTextColor:=0;
  spessore_bordo:=4;
  InizializzaGrafica(3,16);

  if (paramcount>=2) and ((paramStr(2)='c') or (paramStr(2)='C'))
  then bmpC:=true
  else bmpC:=false;

  bmp_p:=true;
  if paramcount>=1
  then  begin
    if paramstr(1)='golib' then bmp.Init('c:\tp7\golib8.bmp\golib8tm.bmp',bmpc)
    else if paramstr(1)='golib2' then bmp.Init('c:\tp7\golib8.bmp\golib8_2.bmp',bmpc)
    else if paramstr(1)='golib3' then bmp.Init('c:\tp7\golib8.bmp\golib8_3.bmp',bmpc)
    else
      bmp.Init(paramstr(1),bmpC);
  end
  else {bmp_P:=false;}bmp.Init({'c:\TCWIN\OWL\EXAMPLES\CHECKERS\redman.bmp'}'c:\windows\redbrick.bmp',false);


  if bmp_p then bmp.PutOnDeskTop;



{ fullbar(8);
  CancBarColor:=8;
  CancObjWithBar:=true;}
  r.assign(0,0,350,200);
  www1.Init(r,new(OPFullHeader,Init(StrNewPas('Window'),true,true,true)));
  www1.PutOnDesktop;

  r.assign(144,50,500,250);
  www3.Init(r,new(OPHelpHeader,Init(StrNewPas('Dialog Box'),true,true)));
  www3.AddMenu(GetDemoMenu,_nord_);
  variabile:=true;
  www3.AddOther( new(OPCheckButton, Init(Null_ID,10,10,'Premi qui',true,@variabile,0)),nil);
  v2:=false;
  _w_:=3;
  _l_:=5;

  www3.AddOther( new(OPGroup, Init(Null_ID,'Prova gruppo',
    AddObject(
      new(OPRadioButtons,Init(Null_ID,10,70,@_w_,17,vert,
         NewRadioButton('Radio Button 3',true,0,
         NewRadioButton('Radio Button 2',true,0,
         NewRadioButton('Radio Button 1',true,0,
         nil)))
      )),
    AddObject(
      new(OPCheckButtons,Init(Null_ID,190,70,nil,17,all,
         NewCheckButton('Check Button 3',true,0,
         NewCheckButton('Check Button 2',true,0,
         NewCheckButton('Check Button 1',true,0,
         nil)))
      ))
      ,nil))
  )),nil);

  r.assign(137,7,180,50);
{  www3.AddOther(new(OPCircle,Init(r,0,In3D)),nil);
}  www3.PutOnDeskTop;

  EvMoveDirection:=All;

  if WaitInRefreshDelay<>-1 then asm
    MOV AH,12H
    MOV BL,36H
    MOV AL,0
    INT 10H      (* Attiva il refresh della memoria video *)
  end;

  {icon.RegisterHCA(Null_ID,0,0,ReducedIcon);
  icon.PutOnDesktop;
  }
  StartApplication;
end.