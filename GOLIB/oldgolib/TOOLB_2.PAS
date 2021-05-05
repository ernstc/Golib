{ Ernesto CIANCIOTTA Productions }

{ *************************************** }
{ *                                     * }
{ * Modulo della libreria GOLIB per la  * }
{ * gestione delle toolbar.             * }
{ *                                     * }
{ * Scritto con Turbo Pascal 7.0        * }
{ *                                     * }
{ *************************************** }

{$D+}
{$L+}

UNIT ToolB_2;

INTERFACE

uses
     crt,

     codici,
     mouse,
     graph,
     graftool,
     bitmaps,
     bitmap,
     golib8,
       dispfile,
     buttons,
     menu,
     resman,

   {$IFDEF ToolBarResInCode}
     t_barRes,
   {$ENDIF}
     t_barcod;


const
      ToolBarRESFile = 'c:\tp7\golib8.bmp\toolbar.res';


      _SEPARATOR_=$FFFF;



type

     OPToolBar = ^OTToolBar;
     OTToolBar = object(OTCompositeObject)
        constructor Init(Direction:TDirection; buttons:OPButton);
        procedure Adjust; virtual;
        procedure Disegna; virtual;
        {procedure Reaction; virtual;}
        function ReactionEvent(Event:word):word; virtual;
     private
        { Nessaria per i casi in cui lo spazio Š insufficente }
        SubView:OPCompositeObject;
        { Tasti che appaiono quando la finestra padre Š troppo stretta e non
          permette la viasualizzazione di tutti i buttoni della ToolBar.
          Servono per far scorrere i bottoni a destra e a sinistra. }
        ScrollerLeft,
        ScrollerRight:OPButton;
        { Le variabili seguenti non funzionali al caso descritto sopra. }
        BtnLimitedAreaWidth,
        BtnAreaWidth        :word;
        BtnsPosition        :integer;
     end;


{
  function NewButton(_ID,Released,Pressed,Disable:word; attiv:boolean; next:OPButton):OPButton;
  function NewSEPARATOR(next:OPButton):OPButton;
}

IMPLEMENTATION


{
  ***********************************************************************
  N.B.: Gli oggetti della lista _buttons_ usano i puntatori _up_ e _down_
        nel seguente modo: _up_ punta all'oggetto a sinistra di Self e
        _down_ punta all'oggetto a destra di Self.
  ***********************************************************************
}


   const _SCROLL_LEFT_  = $1111;
         _SCROLL_RIGHT_ = $2222;


   var
        RightBTN,
         LeftBTN:TButtonHCAs;

        precExitProc:pointer;


(*
   function NewButton(_ID,Released,Pressed,Disable:word; attiv:boolean; next:OPButton):OPButton;
     var button:OPView;
         BtnHCAs:^TButtonHCAs;
     begin
     {$IFDEF ToolBarResInCode}
       BtnHCAs:=NewButtonHCAs(Released,Pressed,Disable,@Toolbar_RESOURCES,NumeroBitmaps);
     {$ELSE}
       BtnHCAs:=LoadButtonHCAs(Released,Pressed,Disable,ToolBarRESFile);
     {$ENDIF}
       button:=new(OPButton, RegisterAll(_ID,0,0,attiv,BtnHCAs));
       OPButton(button)^.ExternalHCA:=false;
       if Disable=0 then OPButton(button)^._disable_:=false;
       button^._up_:=next;
       button^._down_:=nil;
       if next<>nil then next^._down_:=button;
       NewButton:=OPButton(button);
     end;


   function NewSEPARATOR(next:OPButton):OPButton;
     var button:OPView;
     begin
       new(button,Init(_SEPARATOR_,NullRect));
       button^._up_:=next;
       button^._down_:=nil;
       if next<>nil then next^._down_:=button;
       NewSEPARATOR:=OPButton(button);
     end;
*)

const _spazio_=15;
      da_sinistra=3;
      da_sopra=5;



                        { ----- OTToolBar ----- }
   constructor OTToolBar.Init(Direction:TDirection; buttons:OPButton);
     var x:integer;
     begin
       if buttons=nil then begin
         fail;
         exit;
       end;
       inherited Init(Null_ID,r,buttons);
       x:=da_sinistra;
       buttons:=OPButton(_Gruppo_);
       BtnAreaWidth:=16;
       while buttons<>nil do begin
         if buttons^.ID=_SEPARATOR_ then begin
           inc(x,_spazio_);
           inc(BtnAreaWidth,_spazio_);
         end
         else with buttons^.r do begin
           Move(x,da_sopra);
           x:=x2+1;
           inc(BtnAreaWidth,DimX);
         end;
         buttons:=pointer(buttons^._down_);
       end;
       ScrollerLeft:=nil;
       ScrollerRight:=nil;
       SubView:=nil;
       BtnsPosition:=0;
       SysConfig:=SysConfig and __cfDrawFatherRect
                            and __cfScanGroup
                            or cfITLF
                            or cfPostDraw;
     end;


   procedure OTToolBar.Adjust;
     var buf:OPView;
         x:integer;
         dx,dy:integer;
         subRect:OTRect;
     begin
       with r do begin
         DimY:=30;
         y2:=y1+DimY;
       end;
       if BtnAreaWidth>r.DimX
       then begin
         if SubView=nil then begin
           with R do subRect.assign(x1+20,y1,x2-20,y2);
           new(SubView,Init(Null_ID,subRect,_gruppo_));
           with SubView^ do SysConfig:=SysConfig and __cfDrawFatherRect
                                                 and __cfScanGroup
                                                 or cfPostDraw;
           new(ScrollerLeft,RegisterAll(_SCROLL_LEFT_,r.x1,r.y1+3,true,@LeftBTN));
           new(ScrollerRight,RegisterAll(_SCROLL_RIGHT_,r.x1+41-17,r.y1+3,true,@RightBTN));
           AssignGroup(
             AddObject(ScrollerLeft,
             AddObject(ScrollerRight,
             AddObject(SubView,
             nil)))
           );
           BtnsPosition:=0;
           BtnLimitedAreaWidth:=ScrollerRight^.r.x1-ScrollerLeft^.r.x2;
         end
         else begin
           ScrollerLeft^.SysConfig:=ScrollerRight^.SysConfig or cfEnable;
           ScrollerRight^.SysConfig:=ScrollerRight^.SysConfig or cfEnable;
           x:=r.DimX+1-17;
           ScrollerRight^.r.Move(x,3);
           BtnLimitedAreaWidth:=ScrollerRight^.r.x1-ScrollerLeft^.r.x2;
           inc(BtnLimitedAreaWidth,BtnLimitedAreaWidth mod 8);
           if BtnsPosition>BtnAreaWidth-BtnLimitedAreaWidth then ScrollerRight^.Disable;
         end;
       end
       else begin
         if SubView<>nil then begin
           dispose(SubView,GiveGroupTo(@Self));
           dispose(ScrollerLeft,Done);
           dispose(ScrollerRight,Done);
           SubView:=nil;
           ScrollerLeft:=nil;
           ScrollerRight:=nil;
         end
         else MoveGroupRel(r.x1+da_sinistra-_gruppo_^.r.x1,r.y1+da_sopra-_gruppo_^.r.y1);
       end;
     end;


   procedure OTToolBar.Disegna;
     begin
       inherited Disegna;
     end;
(*     var buf:OPButton;
         view:ViewPortType;
         _r,r2:OTRect;
         dx,dy:integer;

     procedure MoveBlockRel(dx,dy:integer);
       begin
         buf:=_buttons_;
         while buf<>nil do begin
           buf^.r.MoveRel(dx,dy);
           buf:=OPButton(buf^._down_);
         end;
       end;

     begin
       line_in_3D(r.x1,r.y1,r.x2,r.y1);
       dx:=0;
       dy:=0;
       if ScrollerLeft<>nil then begin
         ScrollerLeft^.r.MoveRel(r.x1,r.y1);
         ScrollerLeft^.Disegna;
         ScrollerLeft^.r.MoveRel(-r.x1,-r.y1);
         ScrollerRight^.r.MoveRel(r.x1,r.y1);
         ScrollerRight^.Disegna;
         ScrollerRight^.r.MoveRel(-r.x1,-r.y1);
         GetViewSettings(view);
         _r.assign(precR.x1+18,precR.y1,precR.x1+r.DimX-17,precR.y2);
         if _r.IntersectViewPort(view,r2) then begin
           dx:=_r.x1-r2.x1;
           dy:=_r.y1-r2.y1;
           with r2 do SetViewPort(x1,y1,x2,y2,true);
         end
         else exit;
       end
       else MoveBlockRel(r.x1,r.y1);
       if (dx<>0) or (dy<>0) then MoveBlockRel(dx,dy);
       setfillstyle(1,8);
       buf:=_buttons_;
       while buf<>nil do begin
         if buf^.ID<>_SEPARATOR_ then buf^.Disegna;
         buf:=OPButton(buf^._down_);
       end;
       if (dx<>0) or (dy<>0) then MoveBlockRel(-dx,-dy);
       if ScrollerLeft=nil then MoveBlockRel(-r.x1-dx,-r.y1-dy);
     end;*)

(*
   procedure OTToolBar.Reaction;
     var buf:OPButton;
         _mcx,_mcy:integer;
         dx:integer;
     begin
       buf:=OPButton(_Gruppo_);
       _mcx:=mcx-r.x1;
       _mcy:=mcy-r.y1;
       if ScrollerLeft<>nil then begin
         DelayBeforeRepeatBR := 3000;
         ReactionInRealTime  := true;
         RepeatButtonReaction:=true;
         if ScrollerLeft^.r.XYIn(_mcx,_mcy) then begin
           ScrollerLeft^.r.MoveRel(r.x1,r.y1);
           ScrollerLeft^.Reaction;
           ScrollerLeft^.r.MoveRel(-r.x1,-r.y1);
           exit;
         end;
         if ScrollerRight^.r.XYIn(_mcx,_mcy) then begin
           ScrollerRight^.r.MoveRel(r.x1,r.y1);
           ScrollerRight^.Reaction;
           ScrollerRight^.r.MoveRel(-r.x1,-r.y1);
           exit;
         end;
         SetViewPort(r.x1+18,0,r.x2-17,_MaxYResolution,true);
         dec(_mcx,18);
         dx:=18-(r.x1+18);
       end
       else dx:=0;
       while (buf<>nil) and ((buf^.ID=_SEPARATOR_) or not buf^.r.XYIn(_mcx,_mcy)) do
         buf:=OPButton(buf^._down_);
       if buf<>nil then begin
         buf^.r.MoveRel(r.x1+dx,r.y1);
         buf^.Reaction;
         buf^.r.MoveRel(-r.x1-dx,-r.y1);
         if buf^.ButtonPressed then SendMessage(buf^.ID);
       end;
       SetViewPort(0,0,_MaxXResolution,_MaxYResolution,false);
     end;
*)

   function OTToolBar.ReactionEvent(Event:word):word;
     var buf,buf2:OPView;
         lk:boolean;
         dx:integer;
         rect_:OTRect;
     begin
       case Event of
         _SCROLL_LEFT_: begin
             if SubView=nil then exit;
             if BtnsPosition<=0 then begin
               ScrollerLeft^.Disable;
               exit;
             end;
             ScrollerRight^.r.MoveRel(r.x1,r.y1);
             ScrollerRight^.Enable;
             ScrollerRight^.r.MoveRel(-r.x1,-r.y1);
             dec(BtnsPosition,8);
             BitBtlVideoDC(r.x1+18,r.y1+5,r.x1+18+8,r.y1+5,r.DimX-42,24);
             buf:=_Gruppo_;
             lk:=lookvideo;
             lookvideo:=false;
             while buf<>nil do begin
               if buf^.ID<>_SEPARATOR_ then buf^.MoveRel(8,0);
               buf:=buf^._down_;
             end;
             lookvideo:=lk;
             dx:=ScrollerLeft^.r.DimX+1;
             with R do rect_.assign(x1+dx,y1+1,x1+dx+7,y2-1);
             hidemousecursor;
             RefreshRect(rect_,Primo,NullObj);
             showmousecursor;
             delay(5);
         end;
         _SCROLL_RIGHT_: begin
             if SubView=nil then exit;
             if BtnsPosition>BtnAreaWidth-BtnLimitedAreaWidth then begin
               ScrollerRight^.Disable;
               exit;
             end;
             ScrollerLeft^.r.MoveRel(r.x1,r.y1);
             ScrollerLeft^.Enable;
             ScrollerLeft^.r.MoveRel(-r.x1,-r.y1);
             inc(BtnsPosition,8);
             BitBtlVideoDC(r.x1+18+8,r.y1+5,r.x1+18,r.y1+5,r.DimX-42,24);
             buf:=_Gruppo_;
             lk:=lookvideo;
             lookvideo:=false;
             while buf<>nil do begin
               if buf^.ID<>_SEPARATOR_ then buf^.MoveRel(-8,0);
               buf:=buf^._down_;
             end;
             lookvideo:=lk;
             dx:=ScrollerRight^.r.DimX+0;
             with R do rect_.assign(x2-dx-8,y1+1,x2-dx,y2-1);
             hidemousecursor;
             RefreshRect(rect_,Primo,NullObj);
             showmousecursor;
             delay(5);
         end;
         else SendMessage(Event);
       end;
     end;




{$F+}
   procedure ExitToolBar;
     var state:TButtonStatus;
     begin
       for state:=StReleased to StPressed do begin
         DestroyDC(RightBTN[state]);
         DestroyDC(LeftBTN[state]);
       end;
       if precExitProc=nil then TProc(precExitProc);
     end;
{$F-}


begin
{$IFNDEF ToolBarResInCode}
  SetRESFileName(ToolBarRESFile);
{$ELSE}
  SetRESPtr(@ToolBar_RESOURCES,NumeroBitmaps);
{$ENDIF}
  GetButtonHCAs(RightBTN,RigthToolBar_R,RigthToolBar_P,RigthToolBar_D);
  GetButtonHCAs(LeftBTN,LeftToolBar_R,LeftToolBar_P,LeftToolBar_D);

  precExitProc:=exitProc;
  exitProc:=@ExitToolBar;


(*
  {$IFDEF ToolBarResInCode}
  GetButtonHCAs(RightBTN,RigthToolBar_R,RigthToolBar_P,RigthToolBar_D,@ToolBar_RESOURCES,NumeroBitmaps);
  GetButtonHCAs(LeftBTN,LeftToolBar_R,LeftToolBar_P,LeftToolBar_D,@ToolBar_RESOURCES,NumeroBitmaps);
  {$ELSE}
  StoreButtonHCAs(RightBTN,RigthToolBar_R,RigthToolBar_P,RigthToolBar_D,ToolBarRESFile);
  StoreButtonHCAs(LeftBTN,LeftToolBar_R,LeftToolBar_P,LeftToolBar_D,ToolBarRESFile);
  {$ENDIF}

  precExitProc:=exitProc;
  exitProc:=@ExitToolBar;*)
end.


