{ Ernesto CIANCIOTTA Productions }

{$D+}
{$L+}

uses
     dos,
     mouse,
     utility,
     graph,
     fonts,
     graftool,
     codici,
     golib_h,
     applic,
     golib9,
     bitmap,
     buttons,
     w_intest,
     scrolls,
     window,
     frame;


type
     Tw2 = object (OTFrame)
        procedure ExecMessage(var Message:TMessage); virtual;
     end;

     procedure Tw2.ExecMessage(var Message:TMessage);

       procedure DrawMessage(msg:string);
         begin
           setfillstyle(1,0);
           TextColor:=15;
           hidemousecursor;
           bar(0,450,300,479);
           _system_.Drawtext(10,450,TextLeft,msg);
           showmousecursor;
         end;


       begin
         inherited ExecMessage(Message);
         case Message.Message of
           _SCROLL_H_AVANTI_ :begin
             DrawMessage('_SCROLL_H_AVANTI_'+NumStr(Message.w1Reg));
           end;
           _SCROLL_H_INDIETRO_ :begin
             DrawMessage('_SCROLL_H_INDIETRO_'+NumStr(Message.w1Reg));
           end;
           _SCROLL_H_MOVE_ :begin
             DrawMessage('_SCROLL_H_MOVE_'+NumStr(Message.w1Reg));
           end;
           _SCROLL_H_PAGE_AVANTI_ :begin
             DrawMessage('_SCROLL_H_PAGE_AVANTI_'+NumStr(Message.w1Reg));
           end;
           _SCROLL_H_PAGE_INDIETRO_ :begin
             DrawMessage('_SCROLL_H_PAGE_INDIETRO_'+NumStr(Message.w1Reg));
           end;
           _SCROLL_V_AVANTI_ :begin
             DrawMessage('_SCROLL_V_AVANTI_'+NumStr(Message.w1Reg));
           end;
           _SCROLL_V_INDIETRO_ :begin
             DrawMessage('_SCROLL_V_INDIETRO_'+NumStr(Message.w1Reg));
           end;
           _SCROLL_V_MOVE_ :begin
             DrawMessage('_SCROLL_V_MOVE_'+NumStr(Message.w1Reg));
           end;
           _SCROLL_V_PAGE_AVANTI_ :begin
             DrawMessage('_SCROLL_V_PAGE_AVANTI_'+NumStr(Message.w1Reg));
           end;
           _SCROLL_V_PAGE_INDIETRO_ :begin
             DrawMessage('_SCROLL_V_PAGE_INDIETRO_'+NumStr(Message.w1Reg));
           end;

         end;
       end;


var window2:Tw2;
    w3:OTFrame;
    r:OTRect;

    box:OPScrollBox;

    pop:OPPopUpField; {
    pop:OPListBox;     }

    scoll_b:OPScrollBar;

    bmp:OPBitmap;

    scrH,scrV:OPScrollBar;


    StrBuf:PChar;
     NumBuf:word;

    immagine:string;

begin
  immagine:='C:\tp7\golib8.bmp\net3.bmp';
  WaitInRefreshDelay:=-1;

  MakeSpecialEffect:=true;
  GraphParamControl:=false;
  LookVideoOnShutDown:=false;
  spessore_bordo:=4;
  InizializzaGrafica(3,16);
  r.SetRect(200,40,350,350);
  window2.Init(r,'*** Golib ''96 ***',FullIntestParam(true,true,true));
  window2.PutOnDeskTop;

  r.SetRect(20,0,152,45);
  w3.Init(r,'Primo piano',FullIntestParam(true,true,true));
  w3.PutOnDeskTop;

  StrBuf:=nil;
  NumBuf:=1;
  r.SetRect(5,150,200,100);
  new(pop,
    Init(null_ID,r,@cour,@StrBuf,NumBuf,
      NewString('Golib8TM.BMP',
      NewString('Golib_2.BMP',
      NewString('Golib_3.BMP',
      NewString('Drive D:',
      NewString('Drive E:',
      NewString('Drive F:',
      NewString('Drive G:',
      NewString('New York',
      NewString('San Francisco',
      NewString('Luciano',
      NewString('Pietro',
      NewString('San Paolo',
      NewString('Alessandria',
      NewString('Boston',
      NewString('Philadenphia',
      NewString('Las Vegas',
      NewString('Chicago',
      NewString('Detroyt',
      NewString('Los Angeles',
      nil))))))))))))) ))))))
    )
  );

  window2.AddOther(pop,nil);

  r.SetRect(5,25,82,82);
  box:=new(OPScrollBox,Init(null_ID,r,all));
  box^.AddObject(new(OPBitmap,LoadBitmap(Null_ID,0,0,immagine,0)));
  box^.ScrollerH^.Step:=60;

  window2.AddOther(box,nil);

  scrH:=window2.AddOther(New(OPScrollBar, Init(Null_ID,120,25,100,horiz,256,0)),nil);
  scrV:=window2.AddOther(New(OPScrollBar, Init(Null_ID,250,25,200,vert,256,0)),
    NewLayoutMetrics(
                     NewLayout(LmWidth,InPixels,18),
                     NewLayout(LmTop,InPixels,30),
                     NewLayout(LmRight,InPixels,10),
                     NewLayout(LmBottom,InPixels,30),
                     LmParent,nil)
  );

  scrH^.Step:=1;

  r.SetRect(120,70,100,30);
  window2.AddOther(New(OPTextButton, Init(_ESCI_,r,'Esci',true,1,8,0)),nil);

  if WaitInRefreshDelay<>-1 then asm
    MOV AH,12H
    MOV BL,36H
    MOV AL,0
    INT 10H      (* Attiva il refresh della memoria video *)
  end;
  EvMoveDirection:=All;

  StartApplication;
end.