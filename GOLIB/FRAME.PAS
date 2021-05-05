{ by ERNESTO CIANCIOTTA Productions }

{***************************************************}
{*                                                 *}
{*  Modulo della libreria GOLIB contenente         *}
{*  OTFrame e OTToolBox.                           *}
{*                                                 *}
{*  Scritto con Turbo Pascal ver 7.0.              *}
{*                                                 *}
{***************************************************}

{$D+}
{$L+}
{$X+}


UNIT Frame;

INTERFACE


uses

{ Moduli per il debug }
     crt,
     timer,
     fonts,

{ Moduli conteneti codici }
     codici,
     golibcod,
     golib_h,

{ Moduli di sistema }
     strings,
     mouse,
     graph,
     graftool,
     golib9,
       dispfile,
     applic,

{ Modulo per l'accesso ai bottoni }
     buttons,

{ Moduli necessari per l'utilizzo del bitmap ReducedIcon }
     bitmap,
     bitmaps,
     resman,

{ Moduli di utilit… }
     utility,

{ Altri }

     window;



const
      _SEPARATOR_=$FFFF;

      HeaderSelectedColor  : word = 4;
      HeaderDeselectedColor: word = 7;


type
     OPFrame = ^OTFrame;
     OTFrame = object (OTWindow)
        constructor Init(var coord:OTRect; intest:string; Param:pointer);
        destructor Done; virtual;
        procedure Select; virtual;
        procedure Deselect; virtual;
        procedure ExecMessage(var Message:TMessage); virtual;
        { viene eseguita da Done e pu• essere chiamata per chiudere la finestra }
        procedure CloseWin; virtual;
     private
        Button_Z_UNZ:OPView;

        UnZoomRect,
        NormalRect:OTRect; { In questa variabile viene memorizzata la dimensione
                             della finestra prima di ridurla o ingrandirla. }
        PrecImage:OPView;

        procedure ReactionParam(Param:PParametri); virtual;
        {-- Procedure di risposta agli eventi di default --}
        procedure Chiudi;
        procedure Zoom;
        procedure DimensioniNormali;
        procedure Riduci;
     end;


     OPToolBox = ^OTToolBox;
     OTToolBox = object (OTFrame)
        constructor Init(var coord:OTRect; intest:string; _button_:OPButton);
     end;


     OPDialogBox = ^OTDialogBox;
     OTDialogBox = object (OTFrame)
        constructor Init(var coord:OTRect; centrale:boolean; intest:string; help:boolean);
        procedure ExecMessage(var Message:TMessage); virtual;
        procedure CloseWin; virtual;
        { Il metodo Execute prende il controllo dall'applicazione eseguendo
          la dialog box e restiuisce un messaggio quando la dialog box viene
          chiusa. }
        function Execute:word;
     end;



IMPLEMENTATION


uses
     w_intest;

const
      wndZoomed   = $01;
      wndReduced  = $02;
      wndSelected = $04;

      { TRUE se Š in corso OTFrame.Done }
      WinDestruction: boolean = false;




                    {----- OTFrame -----}
   constructor OTFrame.Init(var coord:OTRect; intest:string; Param:pointer);
     const
       LarghezzaMinima=152;
       AltezzaMinima=45;
     var lk:boolean;
     begin
       Button_Z_UNZ:=nil;
       inherited Init(coord,intest,Param);
       WinInfo:=WinInfo or wndMov8;
       MinDimX:=LarghezzaMinima;
       MinDimY:=AltezzaMinima;
       lk:=lookvideo;
       lookvideo:=false;
       AddBackGround( new(OPWin3D,Init(Null_ID,NullRect,1,8)),
                                       __NewLayoutMetrics__(
                                           LmLeft,InPixels,0,
                                           LmTop,InPixels,0,
                                           LmRight,InPixels,0,
                                           LmBottom,InPixels,0,
                                           LmParent,nil)
       );
       lookvideo:=lk;
     end;


   destructor OTFrame.Done;
     begin
       if Parametri<>nil then case Parametri^[1] of
         1: DisposeIntestParam(Parametri);
         2: DisposeCloseIntestParam(Parametri);
         3: DisposeFullIntestParam(Parametri);
         4: DisposeDialogIntestParam(Parametri);
       end;
       if Button_Z_UNZ<>nil then dispose(Button_Z_UNZ,Done);
       WinDestruction:=true;
       CloseWin;
       WinDestruction:=false;
       inherited Done;
     end;


   procedure OTFrame.Select;
     var testo:OPText;
         barra:OPBar;
         p:pointer;
         sm:TSortMethod;
         i:byte;
     begin
       if ((WinInfo and wndSelected)<>0) or
          (Parametri=nil)
       then exit;
       WinInfo:=WinInfo or wndSelected;
       inherited Select;
       if (WinInfo and wndReduced)<>0 then begin
         hidemousecursor;
         barra:=pointer(_gruppo_^._down_);
         barra^.SetStyle(1,4);
         testo:=pointer(_gruppo_);
         { Modifica gli attributi del testo che compone l'intestazione }
         testo^.SetTextProperties(IntestFont,15);
       {$IFDEF oldrefresh}
         testo^.SetFont(@_system_);
         testo^.SetStyle(1,4);
       {$ENDIF}
         p:=barra^._down_;
         barra^._down_:=nil;
         RefreshRect(barra^.r,_gruppo_,NullObj);
         barra^._down_:=p;
         showmousecursor;
       end
       else begin
         barra:=pointer(_gruppo_);
         if Parametri^[2]<>1 then for i:=2 to Parametri^[2] do barra:=pointer(barra^._down_);
         testo:=pointer(barra^._up_);
         { Modifica gli attributi del testo che compone l'intestazione }
         testo^.SetTextProperties(IntestFont,15);
       {$IFDEF oldrefresh}
         testo^.SetFont(@_system_);
         testo^.SetStyle(1,4);
       {$ENDIF}
         { Modifica gli attributi della barra dell'intestazione }
         barra^.SetStyle(1,4);
         if lookVideo then begin
           p:=barra^._down_;
           barra^._down_:=nil;
           sm:=RectSortMethod;
           RectSortMethod:=TLBR;
           HideMouseCursor;
           RefreshRect(barra^.r,_gruppo_,GetLightListOf(@Self,@barra^.r,NullObj));
           ShowMouseCursor;
           RectSortMethod:=sm;
           barra^._down_:=p;
         end;
       end;
     end;


   procedure OTFrame.Deselect;
     var testo:OPText;
         barra:OPBar;
         p:pointer;
         sm:TSortMethod;
         i:byte;
     begin
       if ((WinInfo and wndSelected)=0) or
          (Parametri=nil)
       then exit;
       WinInfo:=WinInfo and not wndSelected;
       inherited Deselect;
       if (WinInfo and wndReduced)<>0 then begin
         hidemousecursor;
         barra:=pointer(_gruppo_^._down_);
         barra^.SetStyle(1,7);
         testo:=pointer(_gruppo_);
         { Modifica gli attributi del testo che compone l'intestazione }
         testo^.SetTextProperties(IntestFont,8);
       {$IFDEF oldrefresh}
         testo^.SetFont(@_system_);
         testo^.SetStyle(1,7);
       {$ENDIF}
         p:=barra^._down_;
         barra^._down_:=nil;
         RefreshRect(barra^.r,_gruppo_,GetLightListOf(@Self,@barra^.r,NullObj));
         barra^._down_:=p;
         showmousecursor;
       end
       else begin
         barra:=pointer(_gruppo_);
         if Parametri^[2]<>1 then for i:=2 to Parametri^[2] do barra:=pointer(barra^._down_);
         testo:=pointer(barra^._up_);
         { Modifica gli attributi del testo che compone l'intestazione }
         testo^.SetTextProperties(IntestFont,8);
       {$IFDEF oldrefresh}
         testo^.SetFont(@_system_);
         testo^.SetStyle(1,7);
       {$ENDIF}
         { Modifica gli attributi della barra dell'intestazione }
         barra^.SetStyle(1,7);
         if lookVideo then begin
           p:=barra^._down_;
           barra^._down_:=nil;
           sm:=RectSortMethod;
           RectSortMethod:=TLBR;
           HideMouseCursor;
           RefreshRect(barra^.r,_gruppo_,GetLightListOf(@Self,@barra^.r,NullObj));
           ShowMouseCursor;
           RectSortMethod:=sm;
           barra^._down_:=p;
         end;
       end;
     end;


const ttt:boolean=true;

   procedure OTFrame.ExecMessage(var Message:TMessage);
     var i:word;
         parola:PChar;
         _r_:OTRect;
         buf:string;
         width:word;
         Event:word;

     begin
       case Message.Message of
         EvMOUSE_L_PRESSED: begin
              PutOnFirst;
              Select;
            end;
         EvMOUSE_L_MULTIPRESSED: begin
              if (WinInfo and wndZoomed)=0 then begin
                PutOnFirst;
                Select;
                Zoom;
              end
              else begin
                DimensioniNormali;
              end;
            end;
         _MUOVI_OGGETTO_       : begin
              if ( (WinInfo and wndReduced)=0 ) and
                 ( (WinInfo and wndMov8)<>0 )
                then MovimentMode8:=true;
              EvMoveObject(Message.Mcx,Message.Mcy);
              MovimentMode8:=false;
            end;
         _DIMENSIONA_OGGETTO_  : begin
              MovimentMode8:=true;
              EvDimObject(Message.mcx,Message.mcy);
              MovimentMode8:=false;
            end;
         _RIDIMENSIONA_FINESTRA_: DimensioniNormali;
         _CHIUDI_FINESTRA_      : begin
              Chiudi;
              Event:=Null_ID;
            end;
         _ZOOM_FINESTRA_        : Zoom;
         _UNZOOM_FINESTRA_      : DimensioniNormali;
         _RIDUCI_FINESTRA_      : Riduci;
         _ESCI_                 :
                                  ShutDown;
         {$IFDEF Debugging}
         789                    : begin
              width:=350;
              _r_.assign((MaxXResolution-width) div 2,
                         (MaxYResolution-67) div 2,
                         (MaxXResolution-width) div 2+width,
                         (MaxYResolution-67) div 2+67);
              with _r_ do begin
                hidemousecursor;
                Window3D(x1,y1,x2,y2,8);
                Incavo3dSoft(x1+5,y1+5,x2-5,y2-5,-1);
                textcolor:=0;
                cour.DrawText(x1+10,y1+15,TextLeft,'                 Memoria libera:  '+NumStr(MemAvail));
                cour.DrawText(x1+10,y1+40,TextLeft,'Memoria libera contigua massima:  '+NumStr(MaxAvail));
                showmousecursor;
                while (not keypressed) and
                      (PositionAndButtonStatus=0) do;
                if keypressed then readkey;
                hidemousecursor;
                RefreshRect(_r_,Primo,NullObj);
                showmousecursor;
              end;
            end;
         10104                  : begin
              asm
                mov ah,$12
                mov bl,$36
                mov al,1
                int 10h
              end;
              while not keypressed do;
              asm
                mov ah,$12
                mov bl,$36
                mov al,0
                int 10h
              end;
            end;
         {$ENDIF}
       end;
       {if Event <>Null_ID then begin
         Message.HNDL:=Event;
         SendMessage(Message);
       end;}
     end;


   procedure OTFrame.CloseWin;
     begin
       if not WinDestruction then DeleteObject(@Self);
     end;

{$R-}
   procedure OTFrame.ReactionParam(Param:PParametri);
     var int: record
           case byte of
           1: (norm:OTIntest);
           2: (clos:OTCloseIntest);
           3: (full:OTFullIntest);
           4: (dialog:OTDialogIntest);
         end;
         Layout:PLayoutList;
         bordo:PListaBordi;
         view:OPView;
     begin
       if (Parametri=nil) then exit;
       case Param^[1] of
       1: begin
            _gruppo_:=int.norm.New(StrPas(WindowName));
            LayoutMetrics:=int.norm.GetLayouts;
            FirstTitleEdges:=int.norm.GetEdges;
          end;
       2: begin
            _gruppo_:=int.clos.New(StrPas(WindowName),
                                   boolean(Param^[3]));
            LayoutMetrics:=int.clos.GetLayouts;
            FirstTitleEdges:=int.clos.GetEdges;
          end;
       3: begin
            _gruppo_:=int.full.New(StrPas(WindowName),
                                   boolean(Param^[3]),
                                   boolean(Param^[4]),
                                   boolean(Param^[5]));
            LayoutMetrics:=int.full.GetLayouts;
            FirstTitleEdges:=int.full.GetEdges;
            Button_Z_UNZ:=new(OPButton,RegisterAll(_UNZOOM_FINESTRA_,0,0,true,@UnzoomBTN));
            Button_Z_UNZ^._Father_:=@Self;
          end;
       4: begin
            _gruppo_:=int.dialog.New(StrPas(WindowName),
                                     boolean(Param^[3]),
                                     boolean(Param^[4]));
            LayoutMetrics:=int.dialog.GetLayouts;
            FirstTitleEdges:=int.dialog.GetEdges;
          end;
       end;
       if Param^[1] in [1..4] then begin
         { Il seguente codice provvede alla sistemazione della lista dei layouts,
           dei bordi e del rettangolo RectOther.
         }
         LastLayoutMetr:=LayoutMetrics;
         bordo:=FirstTitleEdges;
         _last_:=_gruppo_;
         while _gruppo_^._up_<>nil do _gruppo_:=_gruppo_^._up_;
         view:=_gruppo_;
         while LastLayoutMetr^.succ<>nil do begin
           { Conversione del Layout }
           if LastLayoutMetr^.layout<>nil then LastLayoutMetr^.layout^.GetRect(r,view^.r);
           { Adeguamento del rettangolo RectOther }
           AdjustRectOther(view^.r,bordo^.bordo);
           { Avanzamento delle liste }
           LastLayoutMetr:=LastLayoutMetr^.succ;
           bordo:=bordo^.succ;
           view^._Father_:=@Self;
           view:=view^._down_;
         end;
         if view<>nil then view^._Father_:=@Self;
         { Conversione del Layout }
         if LastLayoutMetr^.layout<>nil then LastLayoutMetr^.layout^.GetRect(r,view^.r);
         { Adeguamento del rettangolo RectOther }
         AdjustRectOther(view^.r,bordo^.bordo);
       end;
     end;
{$R+}

   procedure OTFrame.Chiudi;
     var toRect:OTRect;
     begin
       if Parametri=nil then exit;
       {if _down_<>nil then _down_^.Select;}
       if MakeSpecialEffect then begin
         toRect.assign(r.x1+15, r.y1+15,
                       r.x1+15, r.y1+15);
         NumeroPassi:=20;
         SpecialEffect(r,toRect);
         SpecialEffect(r,toRect);
       end;
       StopESP:=true;
       DeleteObject(@Self);
     end;


   procedure OTFrame.Zoom;
     var D_obj:boolean;
         p,bufV:OPView;
         i:byte;
     begin
       if ((WinInfo and wndZoomed)<>0) or
          (Parametri=nil)
       then exit;
       WinInfo:=WinInfo or wndZoomed;
       UnZoomRect:=r;
       if motion then NumeroPassi:=10
                 else NumeroPassi:=20;
       if Parametri^[1]=3
       then begin
         D_obj:=DeleteObjectWhenChange;
         DeleteObjectWhenChange:=false;
         p:=Button_Z_UNZ;
         Button_Z_UNZ:=_gruppo_^._down_;
         if MakeSpecialEffect then begin
           { Effetto speciale }
           SpecialEffect(Button_Z_UNZ^.r,fullRect);
           SpecialEffect(Button_Z_UNZ^.r,fullRect);
         end;
         ChangeObject(Button_Z_UNZ,p);
         DeleteObjectWhenChange:=D_obj;
       end
       else if MakeSpecialEffect then begin
         { Effetto speciale }
         SpecialEffect(r,fullRect);
         SpecialEffect(r,fullRect);
       end;
       bufV:=_gruppo_;
       if Parametri^[2]<>1 then for i:=2 to Parametri^[2] do bufV:=bufV^._down_;
       bufV^.ID:=Null_ID;
       bufV^._up_^.ID:=Null_ID;
       if Parametri^[1]=3 then with _gruppo_^ do SysConfig:=SysConfig and not cfVisible;
       Resize(FullRect);
       if Parametri^[1]=3 then Button_Z_UNZ^.r:=p^.r;
     end;


   procedure OTFrame.DimensioniNormali;
     var p,bufV:OPView;
         D_obj:boolean;
         r2:OTRect;
         i:byte;
         MX,MY:integer;
     begin
       if ((WinInfo and wndReduced)<>0) or
          (Parametri=nil)
       then begin
         NumeroPassi:=27;
         MX:=(R.DimX+NormalRect.DimX) div 2;
         MY:=(R.DimY+NormalRect.DimY) div 2;
         r2.SetRect(0,0,MX,MY);
         r2.Move((MaxXResolution-MX) div 2,(MaxYResolution-MY) div 2);
         HideMouseCursor;
         Hide;
         if MakeSpecialEffect then begin
           { Effetto speciale }
           if not motion then SpecialEffect(r,r2);
           SpecialEffect(r,r2);
         end;
         bufV:=_gruppo_;
         while bufV<>nil do begin
           bufV:=_gruppo_^._down_;
           dispose(_gruppo_,done);
           _gruppo_:=bufV;
         end;
         r:=NormalRect;
         WinInfo:=WinInfo and not wndReduced;
         _gruppo_:=PrecImage;
         if MakeSpecialEffect then begin
           { Effetto speciale }
           if not motion then SpecialEffect(r2,r);
           SpecialEffect(r2,r);
         end;
         SysConfig:=SysConfig and not cfAlwaysAsFirst;
         Show;
         ShowMouseCursor;
       end
       else if (WinInfo and wndZoomed)<>0 then begin
         if motion then NumeroPassi:=10
                   else NumeroPassi:=20;
         WinInfo:=WinInfo and not wndZoomed;
         bufV:=_gruppo_;
         if Parametri^[2]<>1 then for i:=2 to Parametri^[2] do bufV:=bufV^._down_;
         bufV^.ID:=_MUOVI_OGGETTO_;
         bufV^._up_^.ID:=_MUOVI_OGGETTO_;
         if Parametri^[1]=3 then with _gruppo_^ do SysConfig:=SysConfig or cfVisible;
         Resize(UnZoomRect);
         if Parametri^[1]=3 then begin
           D_obj:=DeleteObjectWhenChange;
           DeleteObjectWhenChange:=false;
           p:=Button_Z_UNZ;
           { Button_Z_UNZ punta al tasto di Zoom/Unzoom invisibile }
           Button_Z_UNZ:=_gruppo_^._down_;
           ChangeObject(Button_Z_UNZ,p);
           DeleteObjectWhenChange:=D_obj;
         end;
         if Parametri^[1]=3 then begin
           p^.r:=Button_Z_UNZ^.r;
           if MakeSpecialEffect then begin
             { Effetto speciale }
             SpecialEffect(fullRect,Button_Z_UNZ^.r);
             SpecialEffect(fullRect,Button_Z_UNZ^.r);
           end;
           RefreshRect(r,primo,GetLightListOf(@Self,@p^.r,NullObj));
           {p^.Disegna;}
         end
         else if MakeSpecialEffect then begin
           { Effetto speciale }
           SpecialEffect(fullRect,r);
           SpecialEffect(fullRect,r);
         end;
       end;
     end;


   procedure OTFrame.Riduci;
     const BrickDimX=140;
     var bufR, r2, r3: OTRect;
         bufV:OPView;
         BrickDimY:word;
         MX,MY:integer;
     begin
       if ((WinInfo and wndReduced)<>0) or
          (Parametri=nil)
       then exit;
       BrickDimY:=IntestFont^.GetHeight+25;
       NumeroPassi:=27;
       HideMouseCursor;
       Hide;
       NormalRect:=r;
       MX:=(BrickDimX-1+R.DimX) div 2;
       MY:=(BrickDimY-1+R.DimY) div 2;
       r2.SetRect(0,0,MX,MY);
       r2.Move((MaxXResolution-MX) div 2,(MaxYResolution-MY) div 2);
       if MakeSpecialEffect then begin
         { Effetto speciale }
         if not motion then SpecialEffect(r,r2);
         SpecialEffect(r,r2);
       end;
       r.assign(0,MaxYResolution-BrickDimY,BrickDimX-1,_MaxYResolution);
       bufV:=Primo;
       while bufV<>nil do
         if bufV^.ID<>_WINDOW_ then bufV:=bufV^._down_
         else
           if ((OPWindow(bufV)^.WinInfo and wndReduced)<>0) and
              OPWindow(bufV)^.r.Intersect(r,bufR) then begin
              r.MoveRel(BrickDimX,0);
              bufV:=Primo;
              if r.x2>_MaxXResolution then r.Move(0,r.y1-BrickDimY);
              if r.y1<0 then begin
                r.Move(0,0);
                break;
              end;
           end
           else bufV:=bufV^._down_;
       if MakeSpecialEffect then begin
         { Effetto speciale }
         if not motion then SpecialEffect(r2,r);
         SpecialEffect(r2,r);
       end;
       r2.assign(r.x1+40,r.y1+3,r.x2-3,r.y2-3);
       r3.assign(r.x1+45,r.y1+6,r.x2-4,r.y2-4);
       WinInfo:=WinInfo or wndReduced;
       PrecImage:=_gruppo_;
       _gruppo_:=
         AddObject( new( OPWin3D,  Init(_MUOVI_OGGETTO_,r,1,8)),
         AddObject( new( OPBitmap, RegisterHCA(_UNZOOM_FINESTRA_,r.x1+4,r.y1+7,ReducedIcon)),
         AddObject( new( OPBar,    Init(_MUOVI_OGGETTO_,r2,1,4)),
         AddObject( new( OPText,   Init(_MUOVI_OGGETTO_,r3,IntestFont,StrPas(WindowName),1,4,15)),
         nil)))
       );
       while _gruppo_^._up_<>nil do begin
         _gruppo_^._Father_:=@Self;
         _gruppo_:=_gruppo_^._up_;
       end;
       _gruppo_^._Father_:=@Self;
       SysConfig:=SysConfig or cfAlwaysAsFirst;
       Show;
       ShowMouseCursor;
     end;


                    {----- OTToolBox -----}
   constructor OTToolBox.Init(var coord:OTRect; intest:string; _button_:OPButton);
     var BtnSucc:OPView;
         rect:OTRect;
         x,y,maxY2,limiteY:integer;
     begin
       inherited Init(coord,intest,CloseIntestParam(true));
       SysConfig:=SysConfig and not cfSelectable
                            or cfAlwaysAsFirst;
       MinDimX:=coord.DimX;
       MinDimY:=coord.DimY;
       AddBackGround( new(OPWin3D,Init(Null_ID,NullRect,1,8)),
                                       __NewLayoutMetrics__(
                                           LmLeft,InPixels,0,
                                           LmTop,InPixels,0,
                                           LmRight,InPixels,0,
                                           LmBottom,InPixels,0,
                                           LmParent,nil)
       );
       if _button_=nil then exit;
       BtnSucc:=_button_^._up_;
       maxY2:=0;
       x:=0;
       y:=2;
       while _button_<>nil do begin
         BtnSucc:=_button_^._up_;
         limiteY:=_button_^.R.DimY+y+1;
         if maxY2<limiteY then maxY2:=limiteY;
         if x+_button_^.R.DimX>RectOther.DimX then begin
           x:=0;
           y:=maxY2;
         end;
         _button_^.R.Move(x,y);
         x:=_button_^.R.x2+1;
         AddOther(_button_,nil);
         _button_:=pointer(BtnSucc);
       end;
     end;


                      {----- OTDialogBox -----}
const
      CloseDialogBox: boolean = false;

   constructor OTDialogBox.Init(var coord:OTRect; centrale:boolean; intest:string; help:boolean);
     begin
       if centrale then with coord do
         Move((MaxXResolution-DimX) div 2,
              (MaxYResolution-DimY) div 2);
       inherited Init(coord,intest,DialogIntestParam(true,help));
       SysConfig:=SysConfig or cfModal;
     end;


   procedure OTDialogBox.ExecMessage(var Message:TMessage);
     begin
       SendMessage(Message);
       if Message.HNDL=_CHIUDI_FINESTRA_ then Message.HNDL:=Null_ID;
       inherited ExecMessage(Message);
     end;


   procedure OTDialogBox.CloseWin;
     begin
       CloseDialogBox:=true;
     end;


   function OTDialogBox.Execute:word;
     var EventMessage:word;        { messaggio rilasciato da ExecuteNextEvent }
         f,flag:boolean;
     begin
       PutOnDeskTop;
       Execute:=Null_ID;
       EventMessage:=Null_ID;
       while EventMessage<>_CHIUDI_FINESTRA_ do begin
         {EventMessage:=ExecuteNextEvent;}
         if EventMessage=_CHIUDI_FINESTRA_ then f:=true
                                           else f:=false;
         Execute:=EventMessage;
         {ReactionEvent(EventMessage);}
         if CloseDialogBox then begin
           CloseDialogBox:=false;
           break;
         end;
       end;
{       if not f then begin
         flag:=MakeSpecialEffect;
         MakeSpecialEffect:=false;
       end;
       Chiudi;
       if not f then MakeSpecialEffect:=flag;
}       inherited closeWin;
     end;


END.



