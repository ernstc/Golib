uses
     crt,
     graph,
     graftool,
     applic,
     golib8,
       dispfile,
     w_intest,
     bitmap,
     g_utile,
     codici,
     window,
     frame;


var win:OPFrame;
    win_2:OTFrame;
    r:OTRect;
    intestazione:string;
    i:byte;
    bmp:OTBackground;
    bmpC:boolean;
    num_win, w:word;

begin
  GraphParamControl:=false;

  InizializzaGrafica(3,16);
  num_win:=12;

  if (paramcount>=2) then
    if ((paramStr(2)='c') or (paramStr(2)='C'))
    then bmpC:=true
    else begin
      bmpC:=false;
      num_win:=StrNum(paramStr(2));
      if num_win<1 then num_win:=1;
    end;

  if paramcount>=1
  then  begin
    if paramstr(1)='golib' then bmp.Init('c:\tp7\golib8.bmp\golib8tm.bmp',bmpc)
    else if paramstr(1)='golib2' then bmp.Init('c:\tp7\golib8.bmp\golib8_2.bmp',bmpc)
    else if paramstr(1)='golib3' then bmp.Init('c:\tp7\golib8.bmp\golib8_3.bmp',bmpc)
    else
      bmp.Init(paramstr(1),bmpC);
  end
  else
    bmp.Init('c:\windows\system\epson.bmp',false);

  bmp.PutOnDeskTop;

  LookVideoOnShutDown:=false;
  i:=20;
  intestazione:='Finestra ';
  for w:=1 to num_win do begin
    r.assign(10+i*w,10+i*w,260+i*w,160+i*w);
    win:=new(OPFrame,Init(r,intestazione+NumStr(w),FullIntestParam(true,true,true)));
    win^.PutOnDeskTop;
  end;

  refreshdisplay;
  asm
    MOV AH,12H
    MOV BL,36H
    MOV AL,0
    INT 10H      (* Attiva il refresh della memoria video *)
  end;
  readkey;
  lookvideo:=true;
  win:=pointer(primo);
  w:=_RIDUCI_FINESTRA_;
  while win<>nil do begin
    win^.Reaction;
    if win^.ID=_WINDOW_ then win^.ReactionEvent(w);
    win:=pointer(win^._down_);
  end;
  startApplication;
end.