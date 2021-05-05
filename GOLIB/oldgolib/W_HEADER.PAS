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

UNIT W_Header;

INTERFACE

  uses
       strings,
       mouse,
       codici,
       graph,
       graftool,
       fonts,
       golib_h,
       applic,
       resman,
       bitmaps,
       golibcod,
       golib9,
         dispfile,
       bitmap,
       buttons;


  type

       OPWinHeader = ^OTWinHeader;
       OTWinHeader = object (OTView)
          procedure ExecMessage(var Message:TMessage); virtual;
          { Un esecutore di messaggi per• su un canale non automatico, ossia
            non pu• essere chiamato dall'application controller. }
          procedure MakeSomething(var Message:TMessage); virtual;
          { Restituisce una stringa lunga tanti caratteri quanti sono gli
            oggetti e ogni carattere indica il lato sul quale l'oggetto
            corrispondente Š vincolato.
            'N' = lato nord;
            'S' = lato sud;
            'W' = lato ovest;
            'E' = lato est;
          }
          function GetEdges:PChar; virtual;
          function GetWindowName:PChar; virtual;
       end;


       OPNormalHeader = ^OTNormalHeader;
       OTNormalHeader = object (OTWinHeader)
          constructor Init(WinName: PChar);
          procedure Adjust; virtual;
          procedure Select; virtual;
          procedure Deselect; virtual;
          procedure ChangeWinName(NewName: PChar);
          function GetEdges:PChar; virtual;
          function GetWindowName:PChar; virtual;
          procedure MakeSomething(var Message:TMessage); virtual;
       private
          text: OPAutoText;
          rect: OPBar;
       end;


       OPCloseHeader = ^OTCloseHeader;
       OTCloseHeader = object (OTNormalHeader)
          constructor Init(WinName: PChar; close: boolean);
          procedure Adjust; virtual;
          function GetEdges:PChar; virtual;
          procedure MakeSomething(var Message:TMessage); virtual;
       private
          CloseButton:OPCloseButton;
       end;


       OPFullHeader = ^OTFullHeader;
       OTFullHeader = object (OTCloseHeader)
          constructor Init(WinName: PChar; close, reduce, zoom: boolean);
          procedure Adjust; virtual;
          function GetEdges:PChar; virtual;
          procedure MakeSomething(var Message:TMessage); virtual;
       private
          ZoomButton:   OPButton;
          ReduceButton: OPButton;
          DimButton:    OPBitmap;
       end;


       OPFullHeader2 = ^OTFullHeader2;
       OTFullHeader2 = object (OTFullHeader)
          function GetEdges:PChar; virtual;
       end;


       OPHelpHeader = ^OTHelpHeader;
       OTHelpHeader = object (OTCloseHeader)
          constructor Init(WinName: PChar; close, help:boolean);
          procedure Adjust; virtual;
          function GetEdges:PChar; virtual;
       private
          HelpButton:   OPButton;
       end;


IMPLEMENTATION

uses
     frame2;

   var ResizeIconHCA:HCA;



                      {----- OTWinHeader -----}
   procedure OTWinHeader.ExecMessage;
     begin
     end;


   procedure OTWinHeader.MakeSomething;
     begin
     end;


   function OTWinHeader.GetEdges:PChar;
     begin
       GetEdges:=nil;
     end;


   function OTWinHeader.GetWindowName:PChar;
     begin
       GetWindowName:=nil;
     end;


                      {----- OTNormalHeader -----}
   constructor OTNormalHeader.Init(WinName: PChar);
     begin
       if not inherited Init(Null_ID,NullRect) then fail;

       SysConfig:=SysConfig or cfCompactable;

       new(rect, Init(_MUOVI_OGGETTO_,NullRect,1,4));
       new(text, __Init(_MUOVI_OGGETTO_,NullRect,IntestFont,WinName,1,4,15));
       { coolegamento con il padre }
       rect^._Father_:=@Self;
       text^._Father_:=@Self;
       { collegamenti }
       text^.LinkTo(rect);
       _gruppo_:=text;
       _last_:=rect;
     end;


   procedure OTNormalHeader.Adjust;
     var h:word;
     begin
       h:=IntestFont^.GetHeight;
       with R do begin
         rect^.R.assign(3+x1,3+y1,x2-3,5+h+y1);
         text^.R.assign(8+x1,4+y1,x2-8,5+h+y1);
         text^.Adjust;
       end;
     end;


   procedure OTNormalHeader.Select;
     var p:pointer;
         sm:TSortMethod;
     begin
       { Modifica gli attributi del testo che compone l'intestazione }
       text^.SetTextProperties(IntestFont,15);
     {$IFDEF oldrefresh}
       text^.SetFont(@_system_);
       text^.SetStyle(1,HeaderSelectedColor);
     {$ENDIF}
       { Modifica gli attributi della barra dell'intestazione }
       rect^.SetStyle(1,HeaderSelectedColor);
       if lookVideo then begin
         p:=_last_;
         _last_:=nil;
         sm:=RectSortMethod;
         RectSortMethod:=TLBR;
         HideMouseCursor;
         RefreshRect(NullRect,_gruppo_,GetVisibleZone(@Self,@rect^.r,NullObj));
         ShowMouseCursor;
         RectSortMethod:=sm;
         _last_:=p;
       end;
     end;


   procedure OTNormalHeader.Deselect;
     var p:pointer;
         sm:TSortMethod;
     begin
       { Modifica gli attributi del testo che compone l'intestazione }
       text^.SetTextProperties(IntestFont,8);
     {$IFDEF oldrefresh}
       text^.SetFont(@_system_);
       text^.SetStyle(1,HeaderDeselectedColor);
     {$ENDIF}
       { Modifica gli attributi della barra dell'intestazione }
       rect^.SetStyle(1,HeaderDeselectedColor);
       if lookVideo then begin
         p:=_last_;
         _last_:=nil;
         sm:=RectSortMethod;
         RectSortMethod:=TLBR;
         HideMouseCursor;
         RefreshRect(NullRect,_gruppo_,GetVisibleZone(@Self,@rect^.r,NullObj));
         ShowMouseCursor;
         RectSortMethod:=sm;
         _last_:=p;
       end;
     end;


   procedure OTNormalHeader.ChangeWinName(NewName: PChar);
     begin
       text^.ChangeText(NewName);
     end;


   function OTNormalHeader.GetEdges:PChar;
     begin
       GetEdges:=StrNewPas('NN');
     end;


   function OTNormalHeader.GetWindowName:PChar;
     var t:PChar;
         p1:pointer;
         p2:word;
     begin
       text^.GetTextInfo(t,p1,p2);
       GetWindowName:=t;
     end;


   procedure OTNormalHeader.MakeSomething;
     begin
       case Message.Message of
       _CHANGE_WIN_NAME_: begin
           ChangeWinName(PChar(Message.ParametersPtr1));
         end;
       end;
     end;


                      {----- OTCloseHeader -----}
   constructor OTCloseHeader.Init(WinName: PChar; close: boolean);
     begin
       if not inherited Init(WinName) then fail;
       new(CloseButton, Init(0,0,close));
       CloseButton^._Father_:=@Self;
       CloseButton^.LinkTo(text);
       _gruppo_:=CloseButton;
     end;


   procedure OTCloseHeader.Adjust;
     var h:word;
     begin
       h:=IntestFont^.GetHeight;
       with R do begin
         rect^.R.assign(21+3+x1,3+y1,x2-3,5+h+y1);
         text^.R.assign(29+x1,4+y1,x2-25-19-5,5+h+y1);
         text^.Adjust;
         CloseButton^.R.SetRect(3+x1,3+y1,19,18);
       end;
     end;


   function OTCloseHeader.GetEdges:PChar;
     begin
       GetEdges:=StrNewPas('NNN');
     end;


   procedure OTCloseHeader.MakeSomething;
     begin
       inherited MakeSomething(Message);
       case Message.Message of
       _CHIUDI_FINESTRA_: begin
           if MakeSpecialEffect then begin
             NumeroPassi:=20;
             SpecialEffect(r,CloseButton^.R);
             SpecialEffect(r,CloseButton^.R);
           end;
         end;
       end;
     end;


                      {----- OTFullHeader -----}
   constructor OTFullHeader.Init(WinName: PChar; close, reduce, zoom: boolean);
     {$I check.pcr}
     begin
       if not inherited Init(WinName,close) then fail;
       new(ReduceButton, RegisterAll(_RIDUCI_FINESTRA_,0,0,reduce,@ReduceBTN));
       new(ZoomButton,   RegisterAll(_ZOOM_FINESTRA_,0,0,zoom,@ZoomBTN));
       new(DimButton,    RegisterHCA(_DIMENSIONA_OGGETTO_,0,0,ResizeIconHCA));
       { collegamento degli oggetti con il padre }
       ReduceButton^._Father_:=@Self;
       ZoomButton^._Father_:=@Self;
       DimButton^._Father_:=@Self;
       DimButton^.CursorID:=1;
       { concatenamento degli oggetti alla lista }
       ReduceButton^.LinkTo(ZoomButton);
       ZoomButton^.LinkTo(DimButton);
       DimButton^.LinkTo(CloseButton);
       _gruppo_:=ReduceButton;
       { impostazione di rect e text }
       with rect^ do MouseReactionMask:=MouseReactionMask or rcMultiClick;
       with text^ do MouseReactionMask:=MouseReactionMask or rcMultiClick;
       MarkHotSpot(1,check_cursore,8,8);
     end;


   procedure OTFullHeader.Adjust;
     var h:word;
     begin
       inherited Adjust;
       h:=IntestFont^.GetHeight;
       with R do begin
         ZoomButton^.R.SetRect(x2-5-19,y1+5,19,14);
         ReduceButton^.R.SetRect(x2-25-19,y1+5,19,14);
         DimButton^.R.SetRect(x2-4-15,y2-4-15,15,15);
       end;
     end;


   function OTFullHeader.GetEdges:PChar;
     begin
       GetEdges:=StrNewPas('NNXNNN');
     end;


   procedure OTFullHeader.MakeSomething;
     var lk:boolean;
     begin
       inherited MakeSomething(Message);
       case Message.Message of
       _ZOOM_FINESTRA_: begin
           if motion then NumeroPassi:=10
                     else NumeroPassi:=20;
           if MakeSpecialEffect then begin
             { Effetto speciale }
             SpecialEffect(ZoomButton^.r,fullRect);
             SpecialEffect(ZoomButton^.r,fullRect);
           end;
           lk:=lookvideo;
           lookvideo:=false;
           ZoomButton^.PerformButton(@UnzoomBTN);
           lookvideo:=lk;
           text^.ID:=Null_ID;
           rect^.ID:=Null_ID;
           ZoomButton^.ID:=_UNZOOM_FINESTRA_;
           with DimButton^ do SysConfig:=SysConfig and not cfVisible;
         end;
       _UNZOOM_FINESTRA_: begin
           if motion then NumeroPassi:=10
                     else NumeroPassi:=20;
           if MakeSpecialEffect then begin
             { Effetto speciale }
             SpecialEffect(fullRect,ZoomButton^.r);
             SpecialEffect(fullRect,ZoomButton^.r);
           end;
           ZoomButton^.PerformButton(@ZoomBTN);
           text^.ID:=_MUOVI_OGGETTO_;
           rect^.ID:=_MUOVI_OGGETTO_;
           ZoomButton^.ID:=_ZOOM_FINESTRA_;
           with DimButton^ do begin
             SysConfig:=SysConfig or cfVisible;
             Refresh;
           end;
         end;
       end;
     end;


                      {----- OTFullHeader2 -----}
   function OTFullHeader2.GetEdges:PChar;
     begin
       GetEdges:=StrNewPas('NNSNNN');
     end;


                      {----- OTHelpHeader -----}
   constructor OTHelpHeader.Init(WinName: PChar; close, help: boolean);
     begin
       if not inherited Init(WinName,close) then fail;
       new(HelpButton,  RegisterAll(_HELP_,0,0,help,@HelpBTN));
       { collegamento degli oggetti con il padre }
       HelpButton^._Father_:=@Self;
       { concatenamento degli oggetti alla lista }
       HelpButton^.LinkTo(CloseButton);
       _gruppo_:=HelpButton;
     end;


   procedure OTHelpHeader.Adjust;
     var h:word;
     begin
       inherited Adjust;
       h:=IntestFont^.GetHeight;
       with R do HelpButton^.R.SetRect(x2-5-19,y1+5,19,14);
     end;


   function OTHelpHeader.GetEdges:PChar;
     begin
       GetEdges:=StrNewPas('NNNN');
     end;






var _bmp_:pointer;

   procedure ErroreRisorse;
     begin
       restoreCRTMode;
       writeln('Errore W_HEADER.TPU: Il caricamento delle risorse Š fallito!');
       halt;
     end;

BEGIN
  if GetBMPResource_IDNum(@Golib_RESOURCES,NumeroRisorse,ResizeIcon,_bmp_)=0 then ErroreRisorse;
  if CreateCompatibleArea(ResizeIconHCA,_bmp_^)=nil then ErroreRisorse;
  if _bmp_<>nil then DisposeBMP(_bmp_);
END.