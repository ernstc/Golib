{ by Ernesto CIANCIOTTA Productions }

{****************************************************}
{*                                                  *}
{*  Modulo della libreria GOLIB contenete           *}
{*  delle intestazioni di default per le finestre   *}
{*  discendenti di OTWindow.                        *}
{*                                                  *}
{*  Sritto con Turbo Pascal ver. 7.0.               *}
{*                                                  *}
{****************************************************}

{$D+}
{$L+}

UNIT W_Intest;

INTERFACE

  uses
       strings,
       codici,
       graph,
       graftool,
       golib_h,
       applic,
       resman,
       bitmaps,
       golibcod,
       golib9,
       bitmap,
       window,
       buttons;

  type

       OPIntest = ^OTIntest;
       OTIntest = object
          function New(intestazione:string):OPView;
          function GetLayouts:PLayoutList;
          function GetEdges:PListaBordi;
          procedure Dispose;
          function SetButton(ID:word; stato:boolean):boolean;
          function GetButton(ID:word):boolean;
          function FirstObj:OPView;
          function LastObj:OPView;
       private
          last,
          first:OPView;
       end;


       OPCloseIntest = ^OTCloseIntest;
       OTCloseIntest = object(OTIntest)
          function New(intestazione:string; close:boolean):OPView;
          function GetLayouts:PLayoutList;
          function GetEdges:PListaBordi;
       end;


       OPFullIntest = ^OTFullIntest;
       OTFullIntest = object(OTIntest)
          function New(intestazione:string;close, reduce, zoom:boolean):OPView;
          function GetLayouts:PLayoutList;
          function GetEdges:PListaBordi;
       end;


       OPDialogIntest = ^OTDialogIntest;
       OTDialogIntest = object(OTIntest)
          function New(intestazione:string;close, help:boolean):OPView;
          function GetLayouts:PLayoutList;
          function GetEdges:PListaBordi;
       end;


  function IntestParam:pointer;
  function CloseIntestParam(t1:boolean):pointer;
  function FullIntestParam(t1,t2,t3:boolean):pointer;
  function DialogIntestParam(t1,t2:boolean):pointer;

  procedure DisposeIntestParam(Param:pointer);
  procedure DisposeCloseIntestParam(Param:pointer);
  procedure DisposeFullIntestParam(Param:pointer);
  procedure DisposeDialogIntestParam(Param:pointer);


IMPLEMENTATION

   var Par1,
       Par2,
       Par3,
       Par4:TLayout;

       ResizeIconHCA:HCA;



                      {----- OTIntest -----}
   function OTIntest.New(intestazione:string):OPView;
     begin
       last:=AddObject( system.new(OPBar,   Init(_MUOVI_OGGETTO_,NullRect,1,4)),
             AddObject( system.new(OPText,  Init(_MUOVI_OGGETTO_,NullRect,IntestFont,intestazione,1,4,15)),
             nil)
       );
       first:=last;
       while first^._up_<>nil do first:=first^._up_;
       new:=last;
       last^.MouseReactionMask:=last^.MouseReactionMask or rcMultiClick;
       last:=last^._up_;
       last^.MouseReactionMask:=last^.MouseReactionMask or rcMultiClick;
     end;


   function OTIntest.GetLayouts:PLayoutList;
     var lay:PLayoutList;
     begin
       lay:=
         NewLayoutList(
           __NewLayoutMetrics__(
             LmLeft,InPixels,8,
             LmTop,InPixels,4,
             LmRight,InPixels,4,
             LmHeight,InPixels,IntestFont^.GetHeight,
             LmParent,nil
           ),
         NewLayoutList(
           __NewLayoutMetrics__(
             LmLeft,InPixels,3,
             LmTop,InPixels,3,
             LmRight,InPixels,4,
             LmHeight,InPixels,IntestFont^.GetHeight+2,
             LmParent,nil
           ),
         nil
       ));
       GetLayouts:=lay;
     end;


   function OTIntest.GetEdges:PListaBordi;
     var bordi:PListaBordi;
     begin
       system.new(bordi);
       bordi^.bordo:=_nord_;
       system.new(bordi^.succ);
       bordi^.bordo:=_nord_;
       bordi^.succ^.succ:=nil;
       GetEdges:=bordi;
     end;


   procedure OTIntest.Dispose;
     var buf:OPView;
     begin
       if last^._down_<>nil then last^._down_^._up_:=first^._up_;
       if first^._up_<>nil then first^._up_^._down_:=last^._down_;
       buf:=first;
       while buf<>last^._down_ do begin
         system.dispose(buf,Done);
         buf:=first^._down_;
         first:=buf;
       end;
     end;


   function OTIntest.SetButton(ID:word; stato:boolean):boolean;
     var buf:OPView;
         tasto:OPButton absolute buf;
     begin
       buf:=first;
       SetButton:=false;
       while buf<>last^._down_ do begin
         if buf^.ID=ID then begin
           SetButton:=(tasto^.SysConfig and cfEnable)=cfEnable;
           if stato then tasto^.Enable
                    else tasto^.Disable;
           break;
         end;
         buf:=buf^._down_;
       end;
     end;


   function OTIntest.GetButton(ID:word):boolean;
     var buf:OPView;
         tasto:OPButton absolute buf;
     begin
       buf:=first;
       GetButton:=false;
       while buf<>last^._down_ do begin
         if buf^.ID=ID then begin
           GetButton:=(tasto^.SysConfig and cfEnable)=cfEnable;
           break;
         end;
         buf:=buf^._down_;
       end;
     end;


   function OTIntest.FirstObj:OPView;
     begin
       FirstObj:=first;
     end;


   function OTIntest.LastObj:OPView;
     begin
       LastObj:=last;
     end;



                      {----- OTCloseIntest -----}
   function OTCloseIntest.New(intestazione:string; close:boolean):OPView;
     begin
       last:=
          AddObject( system.new(OPBar,         Init(_MUOVI_OGGETTO_,NullRect,1,4)),
          AddObject( system.new(OPText,        Init(_MUOVI_OGGETTO_,NullRect,IntestFont,intestazione,1,4,15)),
          AddObject( system.new(OPCloseButton, Init(0,0,close)),
          nil))
       );
       first:=last;
       while first^._up_<>nil do first:=first^._up_;
       new:=last;
       last^.MouseReactionMask:=last^.MouseReactionMask or rcMultiClick;
       last:=last^._up_;
       last^.MouseReactionMask:=last^.MouseReactionMask or rcMultiClick;
     end;


   function OTCloseIntest.GetLayouts:PLayoutList;
     var lay:PLayoutList;
     begin
       lay:=
         NewLayoutList(
           __NewLayoutMetrics__(
             LmLeft,InPixels,3,
             LmTop,InPixels,3,
             LmWidth,InPixels,19,
             LmHeight,InPixels,18,
             LmParent,nil
           ),
         NewLayoutList(
           __NewLayoutMetrics__(
             LmLeft,InPixels,28,
             LmTop,InPixels,4,
             LmRight,InPixels,4,
             LmHeight,InPixels,IntestFont^.GetHeight,
             LmParent,nil
           ),
         NewLayoutList(
           __NewLayoutMetrics__(
             LmLeft,InPixels,{2}3,
             LmTop,InPixels,3,
             LmRight,InPixels,4,
             LmHeight,InPixels,IntestFont^.GetHeight+2,
             LmParent,nil
           ),
         nil
       )));
       GetLayouts:=lay;
     end;


   function OTCloseIntest.GetEdges:PListaBordi;
     var bordi:PListaBordi;
     begin
       system.new(bordi);
       bordi^.bordo:=_nord_;
       system.new(bordi^.succ);
       bordi^.succ^.bordo:=_nord_;
       system.new(bordi^.succ^.succ);
       bordi^.succ^.succ^.bordo:=_nord_;
       bordi^.succ^.succ^.succ:=nil;
       GetEdges:=bordi;
     end;


                      {----- OTFullIntest -----}
   function OTFullIntest.New(intestazione:string; close, reduce, zoom:boolean):OPView;
     {$I check.pcr}
     begin
       last:=
          AddObject( system.new(OPBar,         Init(_MUOVI_OGGETTO_,NullRect,1,4)),
          AddObject( system.new(OPText,        Init(_MUOVI_OGGETTO_,NullRect,IntestFont,intestazione,1,4,15)),
          AddObject( system.new(OPCloseButton, Init(0,0,close)),
          AddObject( system.new(OPButton,      RegisterAll(_RIDUCI_FINESTRA_,0,0,reduce,@ReduceBTN)),
          AddObject( system.new(OPButton,      RegisterAll(_ZOOM_FINESTRA_,0,0,zoom,@ZoomBTN)),
          AddObject( system.new(OPBitmap,      RegisterHCA(_DIMENSIONA_OGGETTO_,0,0,ResizeIconHCA)),
          nil)))))
       );
       first:=last;
       while first^._up_<>nil do first:=first^._up_;
       first^.SysConfig:=first^.SysConfig and not cfLPriority;
       first^.RecoverHotSpotsResources(1);
       new:=last;
       last^.MouseReactionMask:=last^.MouseReactionMask or rcMultiClick;
       last:=last^._up_;
       last^.MouseReactionMask:=last^.MouseReactionMask or rcMultiClick;
       MarkHotSpot(1,check_cursore,8,8);
     end;


   function OTFullIntest.GetLayouts:PLayoutList;
     var lay:PLayoutList;
     begin
       { Sono sisposti in ordine inverso all'ordine di inizializzazione }
       lay:=
         NewLayoutList(
           __NewLayoutMetrics__(
             LmWidth,InPixels,{Spessore_Bordo+IntestFont^.GetMaxDim-1}15,
             LmHeight,InPixels,{Spessore_Bordo+IntestFont^.GetMaxDim-1}15,
             LmRight,InPixels,4,
             LmBottom,InPixels,4,
             LmParent,nil
           ),
         NewLayoutList(
           __NewLayoutMetrics__(
             LmWidth,InPixels,19,
             LmTop,InPixels,{3}5,
             LmRight,InPixels,{3}5,
             LmHeight,InPixels,14,
             LmParent,nil
           ),
         NewLayoutList(
           __NewLayoutMetrics__(
             LmWidth,InPixels,19,
             LmTop,InPixels,{3}5,
             LmRight,InPixels,{23}25,
             LmHeight,InPixels,14,
             LmParent,nil
           ),
         NewLayoutList(
           __NewLayoutMetrics__(
             LmLeft,InPixels,3,
             LmTop,InPixels,3,
             LmWidth,InPixels,19,
             LmHeight,InPixels,18,
             LmParent,nil
           ),
         NewLayoutList(
           __NewLayoutMetrics__(
             LmLeft,InPixels,28,
             LmTop,InPixels,4,
             LmRight,InPixels,48,
             LmHeight,InPixels,IntestFont^.GetHeight,
             LmParent,nil
           ),
         NewLayoutList(
           __NewLayoutMetrics__(
             LmLeft,InPixels,{2}3,
             LmTop,InPixels,3,
             LmRight,InPixels,{44}3,
             LmHeight,InPixels,IntestFont^.GetHeight+2,
             LmParent,nil
           ),
         nil
       ))))));
       GetLayouts:=lay;
     end;


   function OTFullIntest.GetEdges:PListaBordi;
     var bordi,bordo:PListaBordi;
     begin
       { Sono sisposti in ordine inverso all'ordine di inizializzazione }
       system.new(bordi);
       bordi^.bordo:=_sud_;

       system.new(bordi^.succ);
       bordo:=bordi^.succ;
       bordo^.bordo:=_nord_;

       system.new(bordo^.succ);
       bordo:=bordo^.succ;
       bordo^.bordo:=_nord_;

       system.new(bordo^.succ);
       bordo:=bordo^.succ;
       bordo^.bordo:=_nord_;

       system.new(bordo^.succ);
       bordo:=bordo^.succ;
       bordo^.bordo:=_nord_;

       system.new(bordo^.succ);
       bordo:=bordo^.succ;
       bordo^.bordo:=_nord_;

       bordo^.succ:=nil;
       GetEdges:=bordi;
     end;


                      {----- OTDialogIntest -----}
   function OTDialogIntest.New(intestazione:string; close, help:boolean):OPView;
     begin
       last:=
          AddObject( system.new(OPBar,         Init(_MUOVI_OGGETTO_,NullRect,1,4)),
          AddObject( system.new(OPText,        Init(_MUOVI_OGGETTO_,NullRect,IntestFont,intestazione,1,4,15)),
          AddObject( system.new(OPCloseButton, Init(0,0,close)),
          AddObject( system.new(OPButton,      RegisterAll(_HELP_,0,0,help,@HelpBTN)),
          nil)))
       );
       first:=last;
       while first^._up_<>nil do first:=first^._up_;
       first^.SysConfig:=first^.SysConfig and not cfLPriority;
       new:=last;
     end;


   function OTDialogIntest.GetLayouts:PLayoutList;
     var lay:PLayoutList;
     begin
       { Sono sisposti in ordine inverso all'ordine di inizializzazione }
       lay:=
         NewLayoutList(
           __NewLayoutMetrics__(
             LmWidth,InPixels,19,
             LmTop,InPixels,{3}5,
             LmRight,InPixels,{3}5,
             LmHeight,InPixels,14,
             LmParent,nil
           ),
         NewLayoutList(
           __NewLayoutMetrics__(
             LmLeft,InPixels,3,
             LmTop,InPixels,3,
             LmWidth,InPixels,19,
             LmHeight,InPixels,18,
             LmParent,nil
           ),
         NewLayoutList(
           __NewLayoutMetrics__(
             LmLeft,InPixels,28,
             LmTop,InPixels,4,
             LmRight,InPixels,48,
             LmHeight,InPixels,IntestFont^.GetHeight,
             LmParent,nil
           ),
         NewLayoutList(
           __NewLayoutMetrics__(
             LmLeft,InPixels,{2}3,
             LmTop,InPixels,3,
             LmRight,InPixels,{44}3,
             LmHeight,InPixels,IntestFont^.GetHeight+2,
             LmParent,nil
           ),
         nil
       ))));
       GetLayouts:=lay;
     end;


   function OTDialogIntest.GetEdges:PListaBordi;
     var bordi,bordo:PListaBordi;
     begin
       { Sono disposti in ordine inverso all'ordine di inizializzazione }
       system.new(bordi);
       bordi^.bordo:=_nord_;

       system.new(bordi^.succ);
       bordo:=bordi^.succ;
       bordo^.bordo:=_nord_;

       system.new(bordo^.succ);
       bordo:=bordo^.succ;
       bordo^.bordo:=_nord_;

       system.new(bordo^.succ);
       bordo:=bordo^.succ;
       bordo^.bordo:=_nord_;

       bordo^.succ:=nil;
       GetEdges:=bordi;
     end;


{$R-}
   var MemPos:^TParametri;

   function IntestParam:pointer;
     begin
       GetMem(MemPos,2);
       MemPos^[1]:=1; { Identificatore del tipo di intestazione }
       MemPos^[2]:=2; { posizione dell'oggetto OTBar }
       IntestParam:=MemPos;
     end;


   function CloseIntestParam(t1:boolean):pointer;
     begin
       GetMem(MemPos,3);
       MemPos^[1]:=2; { Identificatore del tipo di intestazione }
       MemPos^[2]:=3; { posizione dell'oggetto OTBar }
       MemPos^[3]:=byte(t1);
       CloseIntestParam:=MemPos;
     end;


   function FullIntestParam(t1,t2,t3:boolean):pointer;
     begin
       GetMem(MemPos,5);
       MemPos^[1]:=3; { Identificatore del tipo di intestazione }
       MemPos^[2]:=6; { posizione dell'oggetto OTBar }
       MemPos^[3]:=byte(t1);
       MemPos^[4]:=byte(t2);
       MemPos^[5]:=byte(t3);
       FullIntestParam:=MemPos;
     end;


   function DialogIntestParam(t1,t2:boolean):pointer;
     begin
       GetMem(MemPos,4);
       MemPos^[1]:=4; { Identificatore del tipo di intestazione }
       MemPos^[2]:=4; { posizione dell'oggetto OTBar }
       MemPos^[3]:=byte(t1);
       MemPos^[4]:=byte(t2);
       DialogIntestParam:=MemPos;
     end;
{$R+}

   procedure DisposeIntestParam(Param:pointer);
     begin
       FreeMem(Param,2);
     end;


   procedure DisposeCloseIntestParam(Param:pointer);
     begin
       FreeMem(Param,3);
     end;


   procedure DisposeFullIntestParam(Param:pointer);
     begin
       FreeMem(Param,5);
     end;


   procedure DisposeDialogIntestParam(Param:pointer);
     begin
       FreeMem(Param,4);
     end;


var
   _bmp_:pointer;


   procedure ErroreRisorse;
     begin
       restoreCRTMode;
       writeln('Errore W_INTEST.TPU: Il caricamento delle risorse Š fallito!');
       halt;
     end;

BEGIN
  if GetBMPResource_IDNum(@Golib_RESOURCES,NumeroRisorse,ResizeIcon,_bmp_)=0 then ErroreRisorse;
  if CreateCompatibleArea(ResizeIconHCA,_bmp_^)=nil then ErroreRisorse;
  if _bmp_<>nil then DisposeBMP(_bmp_);
END.