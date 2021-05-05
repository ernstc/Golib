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

UNIT ToolBar;

INTERFACE

uses
     paths,
     crt,

     codici,
     mouse,
     graph,
     resman,
     graftool,
     bitmaps,
     bitmap,
     golib_h,
     applic,
     golib9,
     buttons,
     menu,

   {$IFDEF ToolBarResInCode}
     t_barRes,
   {$ENDIF}

     t_barcod;



type

     OPToolBar = ^OTToolBar;
     OTToolBar = object(OTView)
        constructor Init(Direction:TDirection; buttons:OPButton);
        procedure Adjust; virtual;
        procedure Disegna; virtual;
        procedure ExecMessage(var Message:TMessage); virtual;
     private
        { Nessaria per i casi in cui lo spazio Š insufficente }
        SubView:OPView;
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


IMPLEMENTATION


{
  ***********************************************************************
  N.B.: Gli oggetti della lista dei buttoni usano i puntatori _up_ e _down_
        nel seguente modo: _up_ punta all'oggetto a sinistra di Self e
        _down_ punta all'oggetto a destra di Self.
  ***********************************************************************
}

   var
        RightBTN,
         LeftBTN:TButtonHCAs;

        precExitProc:pointer;


const _spazio_=15;
      da_sinistra=3;
      da_sopra=7;


                        { ----- OTToolBar ----- }
   constructor OTToolBar.Init(Direction:TDirection; buttons:OPButton);
     const SeparatorConfig=0;
     var x:integer;
     begin
       if buttons=nil then fail;
       if not inherited InitComposite(_TOOL_BAR_,r,buttons) then fail;
       x:=da_sinistra;
       buttons:=OPButton(_Gruppo_);
       BtnAreaWidth:=16;
       while buttons<>nil do begin
         if buttons^.ID=_SEPARATOR_ then begin
           buttons^.SysConfig:=SeparatorConfig;
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
       SysConfig:=SysConfig and not cfDrawFatherRect
                            and not cfScanGroup
                            {or cfITLF
                            }or cfPostDraw;
       MoveGroupRel(r.x1+da_sinistra-_gruppo_^.r.x1,r.y1+da_sopra-_gruppo_^.r.y1);
     end;


   procedure OTToolBar.Adjust;
     var buf:OPView;
         x:integer;
         dx,dy:integer;
         subRect:OTRect;
     begin
       with R do begin
         DimY:=35;
         y2:=y1+DimY;
       end;
       if BtnAreaWidth>r.DimX
       then begin
         if SubView=nil then begin
           with R do subRect.assign(x1+18,y1+da_sopra,x2-17,y2);
           new(SubView,InitComposite(Null_ID,subRect,_gruppo_));
           with SubView^ do SysConfig:=SysConfig and not cfDrawFatherRect
                                                 and not cfScanGroup
                                                 or cfPostDraw;
           new(ScrollerLeft,RegisterAll(_TOOLBAR_SCROLL_LEFT_,r.x1,r.y1+da_sopra-2,true,@LeftBTN));
           new(ScrollerRight,RegisterAll(_TOOLBAR_SCROLL_RIGHT_,r.x2+1-17,r.y1+da_sopra-2,true,@RightBTN));
           with ScrollerLeft^ do ButtonConfig:=ButtonConfig or btReactionInRealTime
                                                            or btRepeatButtonReaction;
           with ScrollerRight^ do ButtonConfig:=ButtonConfig or btReactionInRealTime
                                                             or btRepeatButtonReaction;
           AssignGroup(
             AddObject(ScrollerLeft,
             AddObject(ScrollerRight,
             AddObject(SubView,
             nil)))
           );
           SysConfig:=SysConfig and not cfDrawFatherRect
                                and not cfScanGroup
                                {or cfITLF
                                }or cfPostDraw;
           SubView^.MoveGroupRel(17,0);
           BtnsPosition:=0;
           BtnLimitedAreaWidth:=ScrollerRight^.r.x1-ScrollerLeft^.r.x2;
         end
         else begin
           with R do subRect.assign(x1+18,y1+da_sopra,x2-17,y2);
           SubView^.Resize(subRect);
           ScrollerLeft^.r.Move(r.x1,r.y1+da_sopra-2);
           ScrollerRight^.r.Move(r.x2+1-17,r.y1+da_sopra-2);
           ScrollerLeft^.SysConfig:=ScrollerRight^.SysConfig or cfEnable;
           ScrollerRight^.SysConfig:=ScrollerRight^.SysConfig or cfEnable;
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
           MoveGroupRel(-17+BtnsPosition,0);
         end;
       end;
     end;


   procedure OTToolBar.Disegna;
     begin
       with R do line_In_3d(x1,y1,x2,y1);
       inherited Disegna;
     end;


   procedure OTToolBar.ExecMessage(var Message:TMessage);
     var buf,buf2:OPView;
         lk:boolean;
         dx:integer;
         rect_:OTRect;
     begin
       case Message.Message of
         _TOOLBAR_SCROLL_LEFT_: begin
             if SubView=nil then exit;
             if BtnsPosition<=0 then begin
               ScrollerLeft^.Disable;
               exit;
             end;
             ScrollerRight^.Enable;
             dec(BtnsPosition,8);
             SubView^.MoveGroupRel(8,0);
             Message.HNDL:=ID;
             AllocMessage(Message);
         end;
         _TOOLBAR_SCROLL_RIGHT_: begin
             if SubView=nil then exit;
             if BtnsPosition>BtnAreaWidth-BtnLimitedAreaWidth then begin
               ScrollerRight^.Disable;
               exit;
             end;
             ScrollerLeft^.Enable;
             inc(BtnsPosition,8);
             SubView^.MoveGroupRel(-8,0);
             Message.HNDL:=ID;
             AllocMessage(Message);
         end;
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
end.


