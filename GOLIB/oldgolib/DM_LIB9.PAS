{ Ernesto CIANCIOTTA Productions }

{$D+}
{$L+}

uses
     mouse,
     menu,
     strings,
     crt,
     graph,
     resman,
     graftool,
     codici,
     golib_h,
     golib9,
     fonts,
     w_intest,
     buttons,
     __menu,  {
     scrolls,
     bitmap,
     statusln, }

   {$IFDEF ToolBarResInCode}  {
     t_barRes,                }
   {$ENDIF}

     applic,

     frame,
     window,
     toolbar,
     t_barcod,
     roma;

type OTMyWindow = object(OTFrame)
        constructor Init(_ID:word;_r:OTRect; intestazione:string);
     end;


{var stl:OPDemoStatusLine;}



constructor OTMyWindow.Init(_ID:word; _r:OTRect; intestazione:string);
  var _rb_,___r,__r:OTRect;
      buf:PChar;
      _int:PChar;
      menuL:OPMenuLine;
  begin
    __r.assign(0,0,382,184);
    ___r.assign(250,150,500,500);
    _rb_.assign(0,0,0,0);

    inherited Init(_r,intestazione,FullIntestParam(true,true,true));
    (*
    stl:=AddTitle(
      new(OPDemoStatusLine, Init(NullRect,150)),
      NewLayoutMetrics(
        NewLayout(LmLeft,InPixels,4),
        NewLayout(LmHeight,InPixels,MenuLFont^.GetHeight+3),
        NewLayout(LmRight,InPixels,4),
        NewLayout(LmBottom,InPixels,4),
        LmParent,nil
      ),
    _sud_);
    stl^.AddKeyBoardInfoField(
       swCapsLock or
       swBLOCNUM
    );
*)
{$IFDEF ToolBarResInCode}
    SetRESPtr(@ToolBar_RESOURCES,NumeroBitmaps);
{$ELSE}
    SetRESFileName('c:\tp7\golib8.bmp\toolbar.res');
{$ENDIF}
    AddMenu(new(OPToolBar,Init(Horiz,
       NewButton(Null_ID,Punto_Esclamativo,Federica,0,true,
       NewButton(Null_ID,Lettera_A,Laura,0,true,
       NewButton(Null_ID,Lettera_M,Gloria,0,true,
       NewButton(Null_ID,Lettera_O,Cristina,0,true,
       NewButton(Null_ID,Lettera_R,Lavinia,0,true,
    NewSEPARATOR(
       NewButton(Null_ID,Matita_R,Matita_P,0,true,
       NewButton(_ZOOM_FINESTRA_,Documento_R,Documento_P,0,true,
       NewButton(_UNZOOM_FINESTRA_,Vuoto_R,Vuoto_P,0,true,
    NewSEPARATOR(
       NewButton(Null_ID,Paint_R,Paint_P,0,true,
    NewSEPARATOR(
       NewButton(Null_ID,Cascata_R,Cascata_P,0,true,
       nil))))))) ) )))))
    )),_nord_);
    (*
    if paramcount>=7 then begin
      if paramstr(7)='1' then menuL:=AddMenu(GetDemoMenu,_nord_);
      if paramstr(7)='2' then menuL:=AddMenu(GetDemoMenu2,_nord_);
      if paramstr(7)='3' then menuL:=AddMenu(GetDemoMenu3,_nord_);
    end
    else menuL:=AddMenu(GetDemoMenu3,_nord_);
    menuL^.LinkToStatusLine(stl);
    *)

    menuL:=AddMenu(GetDemoMenu3,_nord_);

    AddOther( new(OPIncavo3d,Init(Null_ID,r,1,15)),
                                  NewLayoutMetrics(
                                      NewLayout(LmWidth,InPercent,24),
                                      NewLayout(LmTop,InPixels,0),
                                      NewLayout(LmRight,InPixels,0),
                                      NewLayout(LmBottom,InPixels,2),
                                      LmOther,@RectOther)
    );
  end;



var window2:OTMyWindow;
    ww:OTFrame;
    r:OTRect;
    view:OPView;
    {bmp:OTBackground;}
    bmpC:boolean;
    l:OPLayoutMetrics;
    _w_:word;
    bmp_P:boolean;
    {tbox:OTToolBox;}
    res:TResSettings;
    {s:OPScrollBox;}

begin
  WaitInRefreshDelay:=-1;
  MakeSpecialEffect:=true;
  LookVideoOnShutDown:=false;
  SelectedItemColor:=11;
  SelectedTextColor:=0;
  spessore_bordo:=4;
  InizializzaGrafica(3,16);
  {
  if (paramcount>=6) and ((paramStr(6)='c') or (paramStr(6)='C'))
  then bmpC:=true
  else bmpC:=false;
  bmp_P:=true;
  if paramcount>=5
  then  begin
    if paramstr(5)='golib' then bmp.Init('c:\tp7\golib8.bmp\golib8tm.bmp',bmpc)
    else if paramstr(5)='golib2' then bmp.Init('c:\tp7\golib8.bmp\golib8_2.bmp',bmpc)
    else if paramstr(5)='golib3' then bmp.Init('c:\tp7\golib8.bmp\golib8_3.bmp',bmpc)
    else
      bmp.Init(paramstr(5),bmpC);
  end
  else bmp_P:=false;
  if bmp_P then bmp.PutOnDeskTop;
  }

  r.SetRect(200,200,55,100);
{$IFDEF ToolBarResInCode}
    SetRESPtr(@ToolBar_RESOURCES,NumeroBitmaps);
{$ELSE}
    SetRESFileName('c:\tp7\golib8.bmp\toolbar.res');
{$ENDIF}
  {TBox.Init(r,'',
     NewButton(Null_ID,Matita_R,Matita_P,0,true,
     NewButton(Null_ID,Documento_R,Documento_P,0,true,
     NewButton(Null_ID,Vuoto_R,Vuoto_P,0,true,
     NewButton(Null_ID,Vuoto_R,Vuoto_P,0,true,
     NewButton(Null_ID,Paint_R,Paint_P,0,true,
     NewButton(Null_ID,Cascata_R,Cascata_P,0,true,
     nil))))))
  );
  }
  {r.SetRect(200,200,260,260);
  new(s,Init(Null_ID,r,all));
  s^.ScrollerH^.Step:=8;
  s^.AddObject(new(OPBitmap,LoadBitmap(Null_ID,0,0,paramstr(8),0)));
  }
  r.SetRect(0,0,450,350);
  ww.Init(r,'Finestra 2',FullIntestParam(true,true,true));
  ww.PutOnDeskTop;
  r.SetRect(200,230,300,350);
  window2.Init(Null_ID,r,'*** Golib ''96 ***');
  {window2.SetLimitSize(230,150);
  {window2.AddOther(s, NewLayoutMetrics(
                                      NewLayout(LmLeft,InPixels,0),
                                      NewLayout(LmTop,InPixels,0),
                                      NewLayout(LmRight,InPercent,25),
                                      NewLayout(LmBottom,InPixels,2),
                                      LmOther,nil)
  );
  }
  window2.PutOnDeskTop;
  {TBox.PutOnDesktop;
  }
  if WaitInRefreshDelay<>-1 then asm
    MOV AH,12H
    MOV BL,36H
    MOV AL,0
    INT 10H      (* Attiva il refresh della memoria video *)
  end;
  EvMoveDirection:=All;

  StartApplication;
end.