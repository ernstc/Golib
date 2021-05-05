{ Ernesto CIANCIOTTA Productions }

{*************************************************************************}
{*                                                                       *}
{*  Modulo contenente gli oggetti scroller della libreria GOLIB 1.0      *}
{*                                                                       *}
{*  Scritto con Turbo Pascal 7.0                                         *}
{*                                                                       *}
{*************************************************************************}

{$D+}
{$L+}


{DEFINE Win3D}
{DEFINE Warp}

{$DEFINE NormalScrolls}

UNIT SCROLLS;


INTERFACE

  uses
        strings,
        graph,
        codici,
        mouse,
        graftool,
        fonts,
        bitmaps,
        resman,
        golib_h,
        applic,
        golib9,
          dispfile,
        golibcod,
        buttons,
        window;


  const
       cfScrollBar = cfStartUpObj or  { cfStartUpObj Š definito nel modulo GOLIB }
                     cfScanGroup or
                     cfPostDraw or
                     cfCancBar;

       cfPopUpField = (cfStartUpObj or  { cfStartUpObj Š definito nel modulo GOLIB }
                       cfScanGroup or
                       cfPostDraw
                      ) and not cfDrawFatherRect;

       scbDinamicCursor = $01;
       scbStaticCursor  = $02;
       scbExtendedIndex = $04;
       scbClippedIndex  = $08;

       scbExternalPageSize = $10; { Reservato, sola lettura}

       WaitBeforeRepeat:word = 7;

  type
       TStrBuffer = ^PChar;


       OPScrollBar = ^OTScrollBar;
       OTScrollBar = object(OTView)
       public
          { Per default lo step Š settato a 0.
            Lo Step Š il numero di pixels di cui deve essere spostato ogni volta
            il piano virtuale. }
          Step:word;
          MaxVSCursorPos:integer;
          constructor Init(_ID:word; x,y:integer; Dim:word; Dir:TDirection; VDim:longint; ScrollStyle:byte);
          destructor Done; virtual;
          procedure Adjust; virtual;
          procedure ExecMessage(var Message:TMessage); virtual;
          procedure Disable; virtual;
          procedure Enable; virtual;
          procedure SetPageSize(Size:word);
          procedure SetVirtualDim(NewVDim:word);
          procedure SetCursorPosition(NewPos:word);
          function GetCursorPosition:integer;
       private
       public
       {*** Componenti ***}
          FirstBtn,
          LastBtn : OTButton;
          Cursor  : OTButton;
          BackGr  : OTIncavo3DSoft;
       {*** Campi per la gestione ***}
          ScrollType   : byte;          { Tipo della scroll bar }
          Direction    : TDirection;    { Orientamento della barra }
          VirtualDim   : longint;       { Dimensione dello spazio virtuale }
          PassoPerPixel: real;
          DimCursor    : word;          { Dimensione del cursore }
          VSCursorPos,                  { VS = Virtual Screen }
          InternalDim  : integer;       { Dimensione tra i due bottoni }
          PageSize     : word;          { Dimensione della pagina }

          procedure SetStartingFromVSCursorPos;
          procedure Reaction;
          procedure SetVariables;
       end;


       OPScrollBox = ^OTScrollBox;
       OTScrollBox = object (OTWindow)
          ScrollerV,
          ScrollerH:OPScrollBar;
          constructor Init(_ID:word;var coord:OTRect; dir:TDirection);
          procedure Adjust; virtual;
          procedure ExecMessage(var Message:TMessage); virtual;
          procedure AddObject(obj:OPView);
          procedure SetCursorPosition(x,y:integer);
       private
          Direction:TDirection;
          posX,
          posY:integer;
       end;

{$IFDEF NormalScrolls}
       PStrList = ^TStrList;
       TStrList = record
          Str:PChar;
          succ:PStrList;
       end;


       { Oggetto che contiene una serie di stringhe e le visualizza una sotto
         l'altra. }
       OPListViewer = ^OTListViewer;
       OTListViewer = object (OTView)
          constructor Init(_ID:word; x,y:integer; font:OPFont;
                           strBuffer:TStrBuffer;var numBuffer:word; strings_:PStrList);
          procedure Disegna; virtual;
          procedure ExecMessage(var Message:TMessage); virtual;
          procedure Appendstrings(strings_:PStrList);
          procedure DeleteAllstrings;
          procedure Deletestrings(From,Count:word);
       private
       { buffers per la comunicazione con l'esterno }
          PtrNumBuffer:^Word;
          PtrStrBuffer:TStrBuffer;
       { altri campi privati }
          numLines:word;
          FontUsed:OPFont;
          _lastStr_,
          _strings_:PStrList;
       end;


       { ScrollBox contenente solo linee testo. }
       OPListBox = ^OTListBox;
       OTListBox = object (OTScrollBox)
          constructor Init(_ID:word;var coord:OTRect; font:OPFont;
                           strBuffer:TStrBuffer;var numBuffer:word; strings_:PStrList);
          procedure ExecMessage(var Message:TMessage); virtual;
          procedure Appendstrings(strings_:PStrList);
          procedure DeleteAllstrings;
          procedure Deletestrings(From,Count:word);
       private
       { buffers per la comunicazione con l'esterno
          PtrNumBuffer:^Word;
          PtrStrBuffer:TStrBuffer;
       { altri campi privati }
          ListViewer:OPListViewer;
          StaticReaction:boolean;
          PrecFather:OPView;
       end;
{$ENDIF}

       OPStrField = ^OTStrField;
       OTStrField = object (OTWindow)
          constructor Init(_ID:word;var coord:OTRect; font:OPFont;var strBuffer:PChar);
          procedure ExecMessage(var Message:TMessage); virtual;
          procedure Refresh;
          procedure ChangeString(str:string);
          procedure __ChangeString(str:PChar);
          function GetString:string;
          function __GetString:PChar;
          procedure Edit;
       private
          PtrStrBuffer:TStrBuffer;
       end;

{$IFDEF NormalScrolls}
       OPPopUpField = ^OTPopUpField;
       OTPopUpField = object (OTView)
          constructor Init(_ID:word;var coord:OTRect; font:OPFont;
                           strBuffer:TStrBuffer;var numBuffer:word; strings_:PStrList);
          destructor Done; virtual;
          procedure Adjust; virtual;
          procedure ExecMessage(var Message:TMessage); virtual;
       private
       { buffers per la comunicazione con l'esterno }
          PtrNumBuffer:^Word;
          PtrStrBuffer:TStrBuffer;
       { altri campi privati }
          FontUsed:OPFont;
          _strings_:PStrList;
          PullDown:OTButton;
          StrField:OTStrField;
       end;



  function NewString(Str:string; next:PStrList):PStrList;
{$ENDIF}



{ ** VARIABILI PRIVATE ** }

  const
        { * N.B.: Flag utilizzato solo dall'oggetto OTPopUpField *
                  Serve per eliminare il bisnonno dell'oggetto OTListViewer.
        }
        ListViewerPopUpMode: boolean=false;
  var

          PullDown1BTN: TButtonHCAs;

        __PullDown1BTN,
        __PullDown2BTN: ^TButtonHCAs;


IMPLEMENTATION


   var
         FrecciaSopraBTN,

         FrecciaSottoBTN,

         FrecciaSinistraBTN,

         FrecciaDestraBTN: TButtonHCAs;


   const
         { Utilizzato solo dall'oggetto OTScrollBox per impedire al metodo
           OTScrollBar.SetCursorPosition di spedire il messaggio _SCROLL_MOVE_ }
         ReactionAtSetPosition:boolean=true;

         { Buffer interno utilizzato da alcuni oggetti quando non li viene
           passato nessun buffer stringa. }
         BufferDiFuga:PChar=nil;



const __Dx=18;
      _SCROLL_PAGE_ = _SCROLL_PAGE_AVANTI_ or _SCROLL_PAGE_INDIETRO_;


                          {----- OTScrollBar -----}
   constructor OTScrollBar.Init(_ID:word; x,y:integer; Dim:word; dir:TDirection; VDim:longint; ScrollStyle:byte);
     var rect,bufR:OTRect;
         primoBtn,
         ultimoBtn:pointer;
         lk:boolean;
     begin
       if dir=Vert then rect.assign(x,y,x+__Dx,y+Dim-1)
                   else rect.assign(x,y,x+Dim-1,y+__Dx);
       if not inherited Init(_ID,rect) then fail;
       SysConfig:=cfScrollBar;
       _CancBar_:=8;
       ScrollType:=ScrollStyle;
       Direction:=Dir;
       if Direction=Vert then begin
         primoBtn:=@FrecciaSopraBTN;
         ultimoBtn:=@FrecciaSottoBTN;
       end
       else begin
         primoBtn:=@FrecciaSinistraBTN;
         ultimoBtn:=@FrecciaDestraBTN;
       end;
       lk:=lookvideo;
       lookvideo:=false;
       _gruppo_:=@Cursor;
       BackGr.Init(_SCROLL_PAGE_,rect,1,8);
       { Rimpicciolisce il rettangolo }
       inc(rect.x1);
       inc(rect.y1);
       dec(rect.x2);
       dec(rect.y2);
       AutoAssignedButton:=true;
       { Impostazione del primo bottone }
       with FirstBtn do begin
         RegisterAll(_SCROLL_INDIETRO_,rect.x1,rect.y1,true,primoBtn);
         ButtonConfig:=ButtonConfig or btReactionInRealTime
                                    or btRepeatButtonReaction;
       end;
       { Impostazione dell'ultimo bottone }
       with rect do
         if dir=Vert then begin
           x:=x1;
           y:=y2-__Dx+2;
         end
         else begin
           x:=x2-__Dx+2;
           y:=y1;
         end;
       with LastBtn do begin
         RegisterAll(_SCROLL_AVANTI_,x,y,true,ultimoBtn);
         ButtonConfig:=ButtonConfig or btReactionInRealTime
                                    or btRepeatButtonReaction;
       end;
       { Impostazione del cursore }
       with rect do if dir=Vert then bufR.assign(x1,y1+__Dx+2,x2,y1+__Dx*2+1)
                                else bufR.assign(x1+__Dx+1,y1,x1+__Dx*2+1,y2);
       Cursor.ClearButton(_SCROLL_MOVE_,bufR,false,1,14);
       Cursor.SysConfig:=Cursor.SysConfig and not cfBitBtl;
       { Collega i vari elementi che compongono l'oggetto }
       Cursor.LinkTo(@FirstBtn);
       FirstBtn.LinkTo(@LastBtn);
       LastBtn.LinkTo(@BackGr);
       { Collegamento dei componenti con Self }
       Cursor._Father_:=@Self;
       FirstBtn._Father_:=@Self;
       LastBtn._Father_:=@Self;
       BackGr._Father_:=@Self;

       Cursor.Disable;

       ScrollType:=ScrollType and not scbExternalPageSize;
       Step:=0;
       VSCursorPos:=0;
       InternalDim:=0;
       PageSize:=0;
       VirtualDim:=VDim;
       SetVariables;
       lookvideo:=lk;
     end;


   destructor OTScrollBar.Done;
     begin
       DestroySubList;
       inherited Done;
     end;


   procedure OTScrollBar.Adjust;
     var coord:OTRect;
         dimMin:integer;
     begin
       coord:=R;
       BackGr.R:=coord;
       { Rimpicciolimento del rettangolo }
       inc(coord.x1);
       inc(coord.y1);
       dec(coord.x2);
       dec(coord.y2);
       with coord do if direction=Vert then FirstBtn.R.SetRect(x1,y1,DimX-2,__Dx-2)
                                       else FirstBtn.R.SetRect(x1,y1,__Dx-2,DimY-2);
       with coord do if direction=Vert then LastBtn.R.SetRect(x1,y2-__Dx+2,DimX-2,__Dx-2)
                                       else LastBtn.R.SetRect(x2-__Dx+2,y1,__Dx-2,DimY-2);
       with coord do if direction=Vert then Cursor.R.SetRect(x1,FirstBtn.R.y2,DimX-2,(__Dx-1)*2)
                                       else Cursor.R.SetRect(FirstBtn.R.x2,y1,(__Dx-1)*2,DimY-2);
       SetVariables;
     end;


   procedure OTScrollBar.SetVariables;
     { Imposta:
       - InternalDim;
       - CursorSize;
       - IDMDC (Intervallo Di Mobilit… Del Cursore);
       - PassoPerPixel
       - abilitazione/disabilitazione dei componenti
     }
     var IDMDC: integer;
         CursorPos: integer;
     begin
       if VirtualDim=0 then begin
         Disable;
         exit;
       end;
       if direction=Vert then begin
         if (ScrollType and scbExternalPageSize)=0
           then PageSize:=R.DimY + 1;
         InternalDim := LastBtn.R.y1 - FirstBtn.R.y2 - 1;
         DimCursor := round(PageSize * InternalDim / VirtualDim);
         IDMDC := InternalDim - DimCursor;
         if (IDMDC <= 0) {or (PageSize >= VirtualDim)}
           then begin
             Disable;
             exit;
           end
           else begin
             PassoPerPixel := (VirtualDim - PageSize) / IDMDC;
             MaxVSCursorPos := round(IDMDC * PassoPerPixel);
             CursorPos := round(VSCursorPos / PassoPerPixel);
             Enable;
             with Cursor.R do begin
               DimY := DimCursor - 1;
               y1 := CursorPos + FirstBtn.R.y2 + 1;
               y2 := y1 + DimY;
               if y2 > LastBtn.R.y1 - 1 then begin
                 y2 := LastBtn.R.y1 - 1;
                 y1 := y2 - DimY;{
                 LastBtn.Disable; }
               end
               else LastBtn.Enable;
             end;
           end;
       end
       else begin
         if (ScrollType and scbExternalPageSize)=0
           then PageSize:=R.DimX + 1;
         InternalDim := LastBtn.R.x1 - FirstBtn.R.x2 - 1;
         DimCursor := round(PageSize * InternalDim / VirtualDim);
         IDMDC := InternalDim - DimCursor;
         if (IDMDC <= 0) {or (PageSize >= VirtualDim)}
           then begin
             Disable;
             exit;
           end
           else begin
             PassoPerPixel := (VirtualDim - PageSize) / IDMDC;
             MaxVSCursorPos := round(IDMDC * PassoPerPixel);
             CursorPos := round(VSCursorPos / PassoPerPixel);
             Enable;
             with Cursor.R do begin
               DimX := DimCursor - 1;
               x1 := CursorPos + FirstBtn.R.x2 + 1;
               x2 := x1 + DimX;
               if x2 > LastBtn.R.x1 - 1 then begin
                 x2 := LastBtn.R.x1 - 1;
                 x1 := x2 - DimX;
                 LastBtn.Disable;
               end
               else LastBtn.Enable;
             end;
           end;
       end;
       if VSCursorPos >= MaxVSCursorPos then LastBtn.Disable;
       if VSCursorPos <= 0 then FirstBtn.Disable;
     end;


   procedure OTScrollBar.SetStartingFromVSCursorPos;
     { Imposta partendo da VSCursorPos e rilascia:
       FALSE se l'impostazione Š ridondante, cioŠ non cambia lo stato della barra;
       TRUE  se la nuova impostazione pu• generare un messaggio da spedire.
     }
     begin
       if VSCursorPos >= MaxVSCursorPos then begin
         VSCursorPos := MaxVSCursorPos;
         LastBtn.Disable;
       end;
       if VSCursorPos <= 0 then begin
         VSCursorPos := 0;
         FirstBtn.Disable;
       end;
       if Direction = Vert
         then Cursor.Move(Cursor.R.x1, round(VSCursorPos / PassoPerPixel) + FirstBtn.R.y2 + 1)
         else Cursor.Move(round(VSCursorPos / PassoPerPixel) + FirstBtn.R.x2 + 1, Cursor.R.y1);
     end;


(* Da considerarsi come parte integrante del metodo OTScrollBar.Reaction *)
var
    StopReaction:boolean;
    BRect        : OTRect;
    color        : byte;

    procedure DrawBRect; far;
      begin
        SetFillStyle(1,color);
        with BRect do bar(x1,y1,x2,y2);
      end;

    procedure DrawBRectFromOrigin(x,y:integer); far;
      begin
        SetFillStyle(1,color);
        with BRect do bar(0,0,DimX,DimY);
      end;

   procedure OTScrollBar.Reaction;
     var CursorRange   : OTRect;
         precBRect     : OTRect;
         PrecDir       : TDirection;
         PaginaIndietro: boolean;
         wait          : boolean;
         VList         : PRefreshRectList;
         Msg           : TMessage;
         precStopESP   : boolean;

         precCursorPos : integer;
         correggere    : boolean;

       procedure Correggi;
         begin
           correggere:=true;
           { Correzione grafica }
           color:=8;
           if VList=nil
             then begin
               hidemousecursor;
               DrawBRect;
               showmousecursor;
             end
             else begin
               DisposeRefreshList(VList);
               VList:=GetVisibleZone(@Self,@BRect,NullObj);
               hidemousecursor;
               DrawRefreshListProc(VList,nil,@DrawBRectFromOrigin,nil,NoParam);
               showmousecursor;
             end;
         end;

     { Per il wait prima della ripetizione del cambio pagina verr…
       utilizzato il contatore "TimeCounter" che Š collegato all'INT 1Ch }

     begin
       Msg.HNDL:=_SCROLL_BAR_;
       if FirstBtn.r.XYIn(mcx,mcy) or LastBtn.r.XYIn(mcx,mcy) then exit;
       (*** Preparazione per la reazione del cursore ***)
       if Direction=Vert
         then CursorRange.assign( FirstBtn.r.x1 ,  FirstBtn.r.y2+1,
                                  LastBtn.r.x2  ,  LastBtn.r.y1-1  )
         else CursorRange.assign( FirstBtn.r.x2+1 ,  FirstBtn.r.y1,
                                  LastBtn.r.x1-1,  LastBtn.r.y2  );
       if Cursor.r.XYIn(mcx,mcy) then begin
       {*** Reazione del cursore ***}
         { Salvataggio valori }
         PrecDir:=EvMoveDirection;
         { Impostazione nuovi valori }
         EvMoveDirection:=Direction;
         EvMoveRange:=CursorRange;
         { Moviemnto del curosore }
         Cursor.EvMoveObject(mcx,mcy);
         { Ripristino valori }
         EvMoveDirection:=PrecDir;
         EvMoveRange:=NullRect;
       end
       else with BackGr.R do if (mcx>=x1+1) and (mcx<=x2-1) and (mcy>=y1+1) and (mcy<=y2-1) then begin
         (** Reazione del background per lo spostamento di pagina **)
         if Direction=Vert then begin
           PaginaIndietro:=mcy<Cursor.R.y1;
           if PaginaIndietro
             then BRect.assign(FirstBtn.R.x1, FirstBtn.R.y2+1,
                               FirstBtn.R.x2, Cursor.R.y1-1)
             else BRect.assign(FirstBtn.R.x1, Cursor.R.y2+1,
                               FirstBtn.R.x2, LastBtn.R.y1-1);
         end
         else begin
           PaginaIndietro:=mcx<Cursor.R.x1;
           if PaginaIndietro
             then BRect.assign(FirstBtn.R.x2+1, FirstBtn.R.y1,
                               Cursor.R.x1-1,   FirstBtn.R.y2)
             else BRect.assign(Cursor.R.x2+1,   FirstBtn.R.y1,
                               LastBtn.R.x1-1,  FirstBtn.R.y2);
         end;
         VList:=GetVisibleZone(@Self,@BRect,NullObj);
         if (VList<>nil) and (VList^.succ=nil) and BRect.Equal(VList^.r)
           then DisposeRefreshList(VList);
         hidemousecursor;
         color:=7;
         if VList=nil
           then DrawBRect
           else DrawRefreshListProc(VList,nil,@DrawBRectFromOrigin,nil,NoParam);
         showmousecursor;
         wait:=true;
         StopReaction:=false;
         while PositionAndButtonStatus<>0 do begin
           precStopESP:=StopESP;
           if wait then begin

             TimeCounter:=0;  { TimeCounter Š direttamente collegato all'INT 1Ch }

             while (TimeCounter<WaitBeforeRepeat) and
                   (PositionAndButtonStatus<>0)
             do;
             wait:=false;
           end;
           correggere:=false;
           if PaginaIndietro then begin
             if Direction=Vert then precCursorPos:=Cursor.R.y2
                               else precCursorPos:=Cursor.R.x2;
             precBRect:=BRect;
             { Movimento del cursore }
             Msg.Message:=_SCROLL_PAGE_INDIETRO_;
             ExecMessage(Msg);
             { Determina se Š il caso di una correzione grafica }
             if Direction = Vert
               then begin
                 if precCursorPos > Cursor.R.y2 + Cursor.R.DimY + 1 then begin
                   BRect.assign(Cursor.R.x1, Cursor.R.y2 + 1, Cursor.R.x2, precCursorPos);
                   Correggi;
                 end;
               end
               else begin
                 if precCursorPos > Cursor.R.x2 + Cursor.R.DimX + 1 then begin
                   BRect.assign(Cursor.R.x2 + 1, Cursor.R.y1, precCursorPos, Cursor.R.y2);
                   Correggi;
                 end;
               end;
             if correggere then BRect:=precBRect;
             { Aggiorna BRect dopo il movimento del cursore }
             if Direction=Vert then BRect.y2:=Cursor.R.y1-1
                               else BRect.x2:=Cursor.R.x1-1;
             if StopReaction then break;
           end
           else begin
             if Direction=Vert then precCursorPos:=Cursor.R.y1
                               else precCursorPos:=Cursor.R.x1;
             precBRect:=BRect;
             { Movimento del cursore }
             Msg.Message:=_SCROLL_PAGE_AVANTI_;
             ExecMessage(Msg);
             { Determina se Š il caso di una correzione grafica }
             if Direction = Vert
               then begin
                 if precCursorPos < Cursor.R.y1 - Cursor.R.DimY - 1 then begin
                   BRect.assign(Cursor.R.x1, precCursorPos, Cursor.R.x2, Cursor.R.y1 - 1);
                   Correggi;
                 end;
               end
               else begin
                 if precCursorPos < Cursor.R.x1 - Cursor.R.DimX - 1 then begin
                   BRect.assign(precCursorPos, Cursor.R.y1, Cursor.R.x1 - 1, Cursor.R.y2);
                   Correggi;
                 end;
               end;
             if correggere then BRect:=precBRect;
             { Aggiorna BRect dopo il movimento del cursore }
             if Direction=Vert then BRect.y1:=Cursor.r.y2+1
                               else BRect.x1:=Cursor.r.x2+1;
             if StopReaction then break;
           end;
           StopESP:=precStopESP;
         end; { while }
         with BRect do if (x2-x1>0) and (y2-y1>0) then begin
           Correggi;
         end;
         DisposeRefreshList(VList);
       end;
       StopESP:=true;
     end;


   procedure OTScrollBar.ExecMessage(var Message:TMessage);
     var precFlags:boolean;
         OriginalEvent:word;
         CursorPos: integer;
         IDMDC: integer;


       procedure CurPos_VSPos;
         { Imposta partendo da CursorPos }
         begin
           if CursorPos <= 0 then begin
             CursorPos := 0;
             FirstBtn.Disable;
           end
           else begin
             IDMDC := InternalDim - DimCursor;
             if CursorPos >= IDMDC then begin
               CursorPos := IDMDC;
               LastBtn.Disable;
             end;
           end;
           VSCursorPos := round(CursorPos * PassoPerPixel);
           if Direction = Vert
             then Cursor.Move(Cursor.R.x1, CursorPos + FirstBtn.R.y2 + 1)
             else Cursor.Move(CursorPos + FirstBtn.R.x2 + 1, Cursor.R.y1);
         end;


     begin
       if (SysConfig and cfEnable)=0 then exit;
       OriginalEvent:=Message.Message;
       precFlags:=GOLIBProcPrefered;
       GOLIBProcPrefered:=true;

       if Direction = Vert
         then CursorPos := Cursor.r.y1 - FirstBtn.R.y2 - 1
         else CursorPos := Cursor.r.x1 - FirstBtn.R.x2 - 1;

       case Message.Message of

         EvMOUSE_L_PRESSED :begin
            mcx:=Message.MCX;
            mcy:=Message.MCY;
            Reaction;
            exit;
         end;
         _SCROLL_AVANTI_       :begin
            if (LastBtn.SysConfig and cfEnable)=0 then begin
              Message.Message:=Null_ID;
              exit;
            end;
            if step=0 then begin
              inc(CursorPos);
              CurPos_VSPos;
              if Direction=Vert
                then Message.Message:=_SCROLL_V_AVANTI_
                else Message.Message:=_SCROLL_H_AVANTI_;
            end
            else begin
              inc(VSCursorPos,Step);
              SetStartingFromVSCursorPos;
              if Direction=Vert then Message.Message:=_SCROLL_V_AVANTI_
                                else Message.Message:=_SCROLL_H_AVANTI_;
            end;
            FirstBtn.Enable;
         end;
         _SCROLL_INDIETRO_     :begin
            if (FirstBtn.SysConfig and cfEnable)=0 then begin
              Message.Message:=Null_ID;
              exit;
            end;
            if step=0 then begin
              dec(CursorPos);
              CurPos_VSPos;
              if Direction=Vert
                then Message.Message:=_SCROLL_V_INDIETRO_
                else Message.Message:=_SCROLL_H_INDIETRO_;
            end
            else begin
              dec(VSCursorPos,Step);
              VSCursorPos := ((VSCursorPos div step)) * step;
              SetStartingFromVSCursorPos;
              if Direction=Vert then Message.Message:=_SCROLL_V_INDIETRO_
                                else Message.Message:=_SCROLL_H_INDIETRO_;
            end;
            LastBtn.Enable;
         end;
         _SCROLL_MOVE_         :begin
            if direction=Vert then Message.Message:=_SCROLL_V_MOVE_
                              else Message.Message:=_SCROLL_H_MOVE_;
            if CursorPos <= 0 then begin
              CursorPos := 0;
              VSCursorPos:=0;
              FirstBtn.Disable;
              LastBtn.Enable;
            end
            else begin
              IDMDC := InternalDim - DimCursor;
              if CursorPos >= IDMDC then begin
                CursorPos := IDMDC;
                VSCursorPos:=MaxVSCursorPos;
                FirstBtn.Enable;
                LastBtn.Disable;
              end
              else begin
                FirstBtn.Enable;
                LastBtn.Enable;
                VSCursorPos := round(CursorPos * PassoPerPixel);
                if step<>0 then VSCursorPos := ((VSCursorPos div step)) * step;  end;
            end;
         end;
         _SCROLL_PAGE_AVANTI_  :begin
            if (LastBtn.SysConfig and cfEnable)=0 then begin
              Message.Message:=Null_ID;
              exit;
            end;
            inc(VSCursorPos, PageSize);
            if step<>0 then VSCursorPos := ((VSCursorPos div step)) * step;
            SetStartingFromVSCursorPos;
            if Direction=Vert
              then Message.Message:=_SCROLL_V_PAGE_AVANTI_
              else Message.Message:=_SCROLL_H_PAGE_AVANTI_;
            FirstBtn.Enable;
            if VSCursorPos = MaxVSCursorPos then StopReaction:=true;
         end;
         _SCROLL_PAGE_INDIETRO_:begin
            if (FirstBtn.SysConfig and cfEnable)=0 then begin
              Message.Message:=Null_ID;
              exit;
            end;
            dec(VSCursorPos, PageSize);
            if step<>0 then VSCursorPos := ((VSCursorPos div step)) * step;
            SetStartingFromVSCursorPos;
            if Direction=Vert
              then Message.Message:=_SCROLL_V_PAGE_INDIETRO_
              else Message.Message:=_SCROLL_H_PAGE_INDIETRO_;
            LastBtn.Enable;
            if VSCursorPos = 0 then StopReaction:=true;
         end;
         else exit;
       end;
       GOLIBProcPrefered:=precFlags;
       (*
       if Message.Message<>Null_ID then begin
         Message.Message:=SYS_SEND_MESSAGE;
         Message.w2Reg:=Message.Message;
         Message.long2Reg:=longint(@_Father_);
         Message.w1Reg:=VSCursorPos;
         {Message.long2Reg:=longint(@Self);
         SendMessage(Message);} AllocMessage(Message);
       end;
       *)
       if Message.Message<>Null_ID then begin
         Message.w1Reg:=VSCursorPos;
         Message.long2Reg:=longint(@Self);
         SendMessage(Message);
       end;
     end;


   procedure OTScrollBar.Disable;
     begin
       if (SysConfig and cfEnable)=cfEnable then begin
         Cursor.Hide;
         inherited Disable;
       end;
     end;


   procedure OTScrollBar.Enable;
     begin
       if (SysConfig and cfEnable)<>cfEnable then begin
         Cursor.Show;
         inherited Enable;
         Cursor.Disable;
       end;
     end;


   procedure OTScrollBar.SetPageSize(Size:word);
     begin
       if Size=0
         then ScrollType:=ScrollType and not scbExternalPageSize
         else begin
           ScrollType:=ScrollType or scbExternalPageSize;
           PageSize:=Size;
         end;
       SetVariables;
     end;


   procedure OTScrollBar.SetVirtualDim(NewVDim:word);
     begin
       VirtualDim:=NewVDim;
       SetVariables;
     end;


   procedure OTScrollBar.SetCursorPosition(NewPos:word);
     var n_coord:integer;
         _Enable_:boolean;
         Msg:TMessage;
     begin
       if VSCursorPos=NewPos then exit;
       VSCursorPos:=NewPos;

       SetStartingFromVSCursorPos;

       if ReactionAtSetPosition then begin
         Msg.HNDL:=_SCROLL_BAR_;
         Msg.Message:=_SCROLL_MOVE_;
         Msg.w1Reg:=VSCursorPos;
         Msg.long2Reg:=longint(@Self);
         SendMessage(Msg);
       end;
     end;


   function OTScrollBar.GetCursorPosition:integer;
     begin
       GetCursorPosition:=VSCursorPos;
     end;


                       {----- OTScrollBox -----}
   constructor OTScrollBox.Init(_ID:word;var coord:OTRect; dir:TDirection);
     const d_=19;
           Marg=2;
     var dx,dy:integer;
         spEdge:integer;
         lk:boolean;
     begin
       lk:=lookvideo;
       lookvideo:=false;
       spEdge:=Spessore_Bordo;
       Spessore_Bordo:=2;
       inherited Init(coord,'',nil);
       ID:=_ID;
       SysConfig:=SysConfig and not cfSelectable;
       Spessore_Bordo:=spEdge;
       MargSin:=Marg;   MargDes:=Marg;
       MargSup:=Marg;   MargInf:=Marg;
       Direction:=dir;
       posX:=0;    posY:=0;
       case dir of
         Vert :  begin
                   dx:=d_;
                   dy:=0;
                 end;
         Horiz:  begin
                   dx:=0;
                   dy:=d_;
                 end;
         All  :  begin
                   dx:=d_;
                   dy:=d_;
                 end;
       end;
       ScrollerH:=nil;
       if dir in [Vert,All] then begin
         ScrollerV:=New(OPScrollBar, Init(Null_ID,0,0,0,vert,0,0));
         {ScrollerV^.SetPageSize(R.DimY-2);}
         AddTitle(ScrollerV, NewLayoutMetrics(
                                           NewLayout(LmWidth,InPixels,18),
                                           NewLayout(LmTop,InPixels,2),
                                           NewLayout(LmRight,InPixels,0),
                                           NewLayout(LmBottom,InPixels,dy+2),
                                           LmParent,nil),
         _est_
         )
       end
       else
         ScrollerV:=nil;
       if dir in [Horiz,All] then begin
         ScrollerH:=New(OPScrollBar, Init(Null_ID,0,0,0,horiz,0,0));
         {ScrollerH^.SetPageSize(R.DimX-2);}
         AddTitle(ScrollerH, NewLayoutMetrics(
                                           NewLayout(LmLeft,InPixels,2),
                                           NewLayout(LmHeight,InPixels,18),
                                           NewLayout(LmRight,InPixels,dx+2),
                                           NewLayout(LmBottom,InPixels,0),
                                           LmParent,nil),
         _sud_
         );
       end;
       AddBackGround( new(OPBar, Init(Null_ID,NullRect,1,8)),
                                       NewLayoutMetrics(
                                           NewLayout(LmLeft,InPixels,0),
                                           NewLayout(LmTop,InPixels,0),
                                           NewLayout(LmRight,InPixels,0),
                                           NewLayout(LmBottom,InPixels,0),
                                           LmParent,nil)
       );
       AddBackGround( new(OPIncavo3D, Init(Null_ID,NullRect,1,15)),
                                       NewLayoutMetrics(
                                           NewLayout(LmLeft,InPixels,0),
                                           NewLayout(LmTop,InPixels,0),
                                           NewLayout(LmRight,InPixels,dx),
                                           NewLayout(LmBottom,InPixels,dy),
                                           LmParent,nil)
       );
       lookvideo:=lk;
     end;


   procedure OTScrollBox.Adjust;
     var s:OPView;
         dx,dy:integer;
         precPos:integer;
     begin
       inherited Adjust;

       if _altri_<>nil then begin
         s:=_altri_^._last_^._down_;
         _altri_^._last_^._down_:=nil;
       end;

       if ScrollerH<>nil then begin
         {ScrollerH^.SetPageSize(R.DimX-2);}
         precPos:=PosX;
         if (ScrollerH^.SysConfig and cfEnable)=0
           then posX:=0
           else begin
             if (ScrollerH^.LastBtn.SysConfig and cfEnable)=0
               then posX:=ScrollerH^.MaxVSCursorPos
               else posX:=ScrollerH^.GetCursorPosition;
           end;
         dx:=precPos-posX;
       end
       else dx:=0;

       if ScrollerV<>nil then begin
         {ScrollerV^.SetPageSize(R.DimY-2);}
         precPos:=PosY;
         {ScrollerV^.SetPageSize(R.DimY+4);}
         if (ScrollerV^.SysConfig and cfEnable)=0
           then posY:=0
           else begin
             if (ScrollerV^.LastBtn.SysConfig and cfEnable)=0
               then posY:=ScrollerV^.MaxVSCursorPos
               else posY:=ScrollerV^.GetCursorPosition;
           end;
         dy:=precPos-posY;
       end
       else dy:=0;

       if _altri_<>nil then begin
         _altri_^.MoveGroupRel(dx,dy);
         _altri_^._last_^._down_:=s;
       end;
     end;


   procedure OTScrollBox.ExecMessage(var Message:TMessage);
     var s:OPView;
         precPos:integer;
         completa:boolean;
         Msg:TMessage;
     begin
       if _altri_=nil then exit;
       Msg:=Message;
       Msg.HNDL:=_SCROLL_BOX_;
       s:=_altri_^._last_^._down_;
       _altri_^._last_^._down_:=nil;
       case Msg.Message of
       { Movimento della scrollbar orizzontale }
          _SCROLL_H_AVANTI_,
          _SCROLL_H_INDIETRO_,
          _SCROLL_H_MOVE_,
          _SCROLL_H_PAGE_AVANTI_,
          _SCROLL_H_PAGE_INDIETRO_: begin
             if ScrollerH=nil then begin
               Message.Message:=Null_ID;
               exit;
             end;
             precPos:=PosX;
             posX:=ScrollerH^.GetCursorPosition;
             _altri_^.MoveGroupRel(precPos-posX,0);
             StopESP:=True;
          end;
       { Movimento della scrollbar verticale }
          _SCROLL_V_AVANTI_,
          _SCROLL_V_INDIETRO_,
          _SCROLL_V_MOVE_,
          _SCROLL_V_PAGE_AVANTI_,
          _SCROLL_V_PAGE_INDIETRO_: begin
             if ScrollerV=nil then begin
               Message.Message:=Null_ID;
               exit;
             end;
             precPos:=PosY;
             posY:=ScrollerV^.GetCursorPosition;
             _altri_^.MoveGroupRel(0,precPos-posY);
             StopESP:=True;
          end;
          else begin
            if (ScrollerH<>nil) and
               ((ScrollerH^.SysConfig and cfEnable)<>0)
            then begin
              completa:=false;
              case Msg.Message of
           { Comando esterno di movimento della scrollbar orizzontale }
              _SCROLLBOX_H_AVANTI_:
                begin
                  Msg.Message:=_SCROLL_AVANTI_;
                  completa:=true;
                end;
              _SCROLLBOX_H_INDIETRO_:
                begin
                  Msg.Message:=_SCROLL_INDIETRO_;
                  completa:=true;
                end;
              _SCROLLBOX_H_MOVE_:
                begin
                  Msg.Message:=_SCROLL_MOVE_;
                  completa:=true;
                end;
              _SCROLLBOX_H_PAGE_AVANTI_:
                begin
                  Msg.Message:=_SCROLL_PAGE_AVANTI_;
                  completa:=true;
                end;
              _SCROLLBOX_H_PAGE_INDIETRO_:
                begin
                  Msg.Message:=_SCROLL_PAGE_INDIETRO_;
                  completa:=true;
                end;
              end;
              if completa then begin
                ScrollerH^.ExecMessage(Msg);
                Msg.Message:=Null_ID;
              end;
            end;
            if (ScrollerV<>nil) and
               ((ScrollerV^.SysConfig and cfEnable)<>0)
            then begin
              completa:=false;
              case Msg.Message of
           { Movimento della scrollbar verticale }
              _SCROLLBOX_V_AVANTI_:
                begin
                  Msg.Message:=_SCROLL_AVANTI_;
                  completa:=true;
                end;
              _SCROLLBOX_V_INDIETRO_:
                begin
                  Msg.Message:=_SCROLL_INDIETRO_;
                  completa:=true;
                end;
              _SCROLLBOX_V_MOVE_:
                begin
                  Msg.Message:=_SCROLL_MOVE_;
                  completa:=true;
                end;
              _SCROLLBOX_V_PAGE_AVANTI_:
                begin
                  Msg.Message:=_SCROLL_PAGE_AVANTI_;
                  completa:=true;
                end;
              _SCROLLBOX_V_PAGE_INDIETRO_:
                begin
                  Msg.Message:=_SCROLL_PAGE_INDIETRO_;
                  completa:=true;
                end;
              end;
              if completa then begin
                ScrollerV^.ExecMessage(Msg);
                Msg.Message:=Null_ID;
              end;
            end;
          end;
       end;
       _altri_^._last_^._down_:=s;
     end;


   procedure OTScrollBox.AddObject(obj:OPView);
     begin
       if obj=nil then exit;
       { Aggiornamento delle scrollbars }
       if (ScrollerH<>nil) and (obj^.R.x2+1>ScrollerH^.VirtualDim)
         then ScrollerH^.SetVirtualDim(obj^.R.x2+1);
       if (ScrollerV<>nil) and (obj^.R.y2+1>ScrollerV^.VirtualDim)
         then ScrollerV^.SetVirtualDim(obj^.R.y2+1);
       { Inserimento del nuovo oggetto }
       AddOther(obj,nil);
     end;


   procedure OTScrollBox.SetCursorPosition(x,y:integer);
     var s:OPView;
         precPosX,precPosY:integer;
     begin
       if _altri_=nil then exit;
       precPosX:=PosX;
       precPosY:=PosY;
       { Movimento dei cursori }
       ReactionAtSetPosition:=false;
       if ScrollerH<>nil then with ScrollerH^ do begin
         SetCursorPosition(x);
         PosX:=GetCursorPosition;
       end
       else PosX:=0;
       if ScrollerV<>nil then with ScrollerV^ do begin
         SetCursorPosition(y);
         PosY:=GetCursorPosition;
       end
       else PosY:=0;
       ReactionAtSetPosition:=true;
       { Movimento degli oggetti della scroll-box }
       s:=_altri_^._last_^._down_;
       _altri_^._last_^._down_:=nil;
       _altri_^.MoveGroupRel(precPosX-PosX,precPosY-PosX);
       _altri_^._last_^._down_:=s;
     end;


{$IFDEF NormalScrolls}
                        {----- OTListViewer -----}
{var
   __StaticReaction:boolean;}

   constructor OTListViewer.Init(_ID:word; x,y:integer; font:OPFont;
                                 strBuffer:TStrBuffer;var numBuffer:word; strings_:PStrList);
     begin
       inherited Init(_ID,R);
       R.SetRect(x,y,MaxXResolution,0);
       PtrNumBuffer:=@numBuffer;
       PtrStrBuffer:=strBuffer;
       numLines:=0;
       FontUsed:=font;
       _strings_:=nil;
       Appendstrings(strings_);
     end;


   procedure OTListViewer.Disegna;
     var x,y:integer;
         Height:word;
         point:PStrList;
         numStr:word;
         StringRect:OTRect;
         __Enable:boolean;
         SelectedIndex:word;
         { Variabili necessarie per l'ottimizzazione delle prestazioni di
           questo metodo. }
         view:ViewPortType;
         Drawing:boolean;
     begin
       __Enable:=(SysConfig and cfEnable)<>0;
       SelectedIndex:=PtrNumBuffer^;
       SetFillStyle(1,15);
       with R do bar(x1,y1,x2,y2);
       Height:=FontUsed^.GetHeight;
       x:=R.x1+3;
       y:=R.y1;
       point:=_strings_;
       if __Enable then TextColor:=0
                   else TextColor:=8;
       numStr:=1;
       Drawing:=false;
       GetViewSettings(view);
       while point<>nil do begin
         if RefreshProcessing
           then with precR do StringRect.assign(x1,y-R.y1+y1,x2,y-R.y1+y1+Height)
           else with     R do StringRect.assign(x1,y,x2,y+Height);
         if StringRect.IntersectViewPort(view,StringRect) then begin
           Drawing:=true;
           if (numStr=SelectedIndex) and __Enable then begin
             SetFillStyle(1,3);
             with R do bar(x1,y,x2,y+Height-1);
             TextColor:=15;
             FontUsed^.__DrawText(x,y,TextLeft,point^.Str);
             TextColor:=0;
           end
           else FontUsed^.__DrawText(x,y,TextLeft,point^.Str);
         end
         else if Drawing then exit;
         inc(y,Height);
         inc(numStr);
         point:=point^.succ;
       end;
     end;


   procedure OTListViewer.ExecMessage(var Message:TMessage);
     var PrecStrRect,
         StringRect    : OTRect;
         point         : PStrList;
         x,y           : integer;
         Height        : word;
         numStr        : word;
         MinY,
         MaxY          : integer;
         PrecFather    : OPView;
         selected      : boolean;
         SelectedIndex : word;
         SelectedStr   : PChar;
         Msg           : TMessage;
         precStopESP   : boolean;
     begin
       case Message.Message of
         EvMOUSE_L_PRESSED: begin
            if (SysConfig and cfEnable)=0 then exit;

            Msg.HNDL:=ID;

            if _Father_<>nil
              then begin
                if ListViewerPopUpMode then begin
                  PrecFather:=_Father_^._Father_^._Father_;
                  _Father_^._Father_^._Father_:=nil;
                end;
                MinY:=_Father_^.R.y1;
                MaxY:=_Father_^.R.y2;
              end
              else begin
                MinY:=1;
                MaxY:=_MaxXResolution-1;
              end;
            Height:=FontUsed^.GetHeight;
            selected:=false;
            SelectedIndex:=PtrNumBuffer^;
            SelectedStr:=nil;
            {__StaticReaction:=false;}

            while {__StaticReaction or}
                  (PositionAndButtonStatus<>0) do begin
              {if __StaticReaction then PositionAndButtonStatus;}
              point:=_strings_;
              x:=R.x1;
              y:=R.y1;
              numStr:=1;
              while point<>nil do begin
                StringRect.SetRect(x,y,R.DimX,Height-1);
                if StringRect.XYIn(mcx,mcy) then begin
                  selected:=true;
                  if numStr=SelectedIndex then break;
                  PtrNumBuffer^:=numStr;
                  hidemousecursor;
                  { Disattiva la voce precedente }
                  if SelectedIndex<>0 then begin
                    PrecStrRect.SetRect(x,R.y1+(SelectedIndex-1)*Height,R.DimX,Height);
                    SelectedIndex:=numStr;
                    RefreshRect(PrecStrRect,@Self,GetVisibleZone(@Self,@PrecStrRect,NullObj));
                  end;
                  { Attivazione della nuova voce }
                  SelectedIndex:=numStr;
                  SelectedStr:=point^.Str;
                  RefreshRect(StringRect,@Self,GetVisibleZone(@Self,@StringRect,NullObj));
                  showmousecursor;
                  break;
                end;
                inc(y,Height);
                inc(numStr);
                point:=point^.succ;
              end;
              {if __StaticReaction and
                 selected         and
                 (PositionAndButtonStatus<>0)
              then break;}

              precStopESP:=StopESP;
              if mcy<MinY
                then begin
                  Msg.Message:=_SCROLLBOX_V_INDIETRO_;
                  SendMessage(Msg)
                end
                else if mcy>MaxY then begin
                  Msg.Message:=_SCROLLBOX_V_AVANTI_;
                  SendMessage(Msg);
                end;
              StopESP:=precStopESP;
            end; {while}

            {__StaticReaction:=false;}
            if ListViewerPopUpMode then _Father_^._Father_^._Father_:=PrecFather;
            if selected then begin
              if (PtrStrBuffer<>nil) and (SelectedStr<>nil) then begin
                StrDispose(PtrStrBuffer^);
                PtrStrBuffer^:=StrNew(SelectedStr);
              end;
              Msg.Message:=ID;
              SendMessage(Msg);
            end;
         end;
       end;
     end;


   procedure OTListViewer.Appendstrings(strings_:PStrList);
     var point:PStrList;
         numstrings_:word;
         LengthStr:word;
     begin
       if strings_=nil then exit;
       if _strings_=nil then _strings_:=strings_
                        else _lastStr_^.succ:=strings_;
       numstrings_:=0;
       point:=strings_;
       while true do begin
         inc(numstrings_);
         if point^.succ=nil then begin
           _lastStr_:=point;
           break;
         end;
         point:=point^.succ;
       end;
       inc(numLines,numstrings_);
       with R do begin
         DimY:=numLines*FontUsed^.GetHeight;
         y2:=y1+DimY;
       end;
       if lookvideo then RefreshRect(R,@Self,GetVisibleZone(@Self,nil,NullObj));
     end;


   procedure OTListViewer.DeleteAllstrings;
     var point,
         succ:PStrList;
     begin
       point:=_strings_;
       while point<>nil do begin
         succ:=point^.succ;
         FreeMem(point^.Str,StrLen(point^.Str)+1);
         dispose(point);
         point:=succ;
       end;
       _strings_:=nil;
       numLines:=0;
       with R do begin
         DimY:=0;
         y2:=y1;
       end;
       { Refresh }
       if lookvideo then RefreshRect(R,@Self,GetVisibleZone(@Self,nil,NullObj));
     end;


   procedure OTListViewer.Deletestrings(From,Count:word);
     var point,
         succ,
         DelList:PStrList;
         DelTheFirst:boolean;
         IndiceStr,
         Limite:word;
     begin
       if (From=0) or
          (From>numLines) or
          (Count=0) or
          (_strings_=nil) then exit;
       Limite:=From+Count-1;
       if Limite>numLines then Count:=numLines-From+1;
       point:=_strings_;
       { "point" si posiziona sulla stringa che precede la prima stringa
         che deve essere cancellata }
       if From>1
         then begin
           if From>2
              then for IndiceStr:=3 to From do
                     if point^.succ=nil then exit
                                        else point:=point^.succ;
           DelList:=point^.succ;
           if DelList=nil then exit;
           DelTheFirst:=false;
         end
         else begin
           point:=nil;
           DelList:=_strings_;
           DelTheFirst:=true;
         end;
       { Cancellazione di "Count" stringhe a partire da "DelList" }
       for IndiceStr:=1 to Count do begin
         if DelList=nil then break;
         succ:=DelList^.succ;
         FreeMem(DelList^.Str,StrLen(DelList^.Str)+1);
         dispose(DelList);
         DelList:=succ;
       end;
       if DelTheFirst then _strings_:=succ
                      else point^.succ:=succ;
       dec(numLines,Count);
       with R do begin
         DimY:=numLines*FontUsed^.GetHeight;
         y2:=y1+DimY;
       end;
       { Refresh }
       if lookvideo then RefreshRect(R,@Self,GetVisibleZone(@Self,nil,NullObj));
     end;


                         {----- OTListBox -----}
   constructor OTListBox.Init(_ID:word;var coord:OTRect; font:OPFont;
                              strBuffer:TStrBuffer;var numBuffer:word; strings_:PStrList);
     var lk:boolean;
         i:word;
         Msg:TMessage;
     begin
       lk:=lookvideo;
       lookvideo:=false;
       { ListViewer deve essere impostato a nil perchŠ durante l'inizializzazione
         viene chiamata la procedura Adjust che opera su ListViewer. }
       ListViewer:=nil;
       if not inherited Init(_ID,coord,Vert) then fail;
       StaticReaction:=false;
       PrecFather:=nil;
       ScrollerV^.Step:=font^.GetHeight;
       new(ListViewer, Init(_LIST_VIEWER_,0,0,font,strBuffer,numBuffer,strings_));

       ScrollerV^.SetVirtualDim(ListViewer^.R.y2+1);
       AddOther(ListViewer,nil);

       Msg.HNDL:=ID;
       with ScrollerV^ do
         if numBuffer>1
           then for i:=2 to numBuffer do
                  if (LastBtn.SysConfig and cfEnable)<>0 then begin
                    Msg.Message:=_SCROLL_AVANTI_;
                    ExecMessage(Msg);
                  end;
       StopESP:=false;
       lookvideo:=lk;
     end;


   procedure OTListBox.ExecMessage(var Message:TMessage);
     begin
       case Message.Message of
         EvMOUSE_L_PRESSED: begin
             if StaticReaction and (PrecFather=nil) then begin
               PrecFather:=_Father_;
               _Father_:=nil;
             end;
           end;
         _LIST_VIEWER_: begin
             if StaticReaction and
                ((SysConfig and cfOnDesktop)<>0)
             then begin
               if PrecFather<>nil then PrecFather^.ExecMessage(Message);
               StopESP:=true;
               PopUpMode:=false;
               { Autodistruzione }
               if seg(self)<>DSeg then dispose(OPListBox(@self),Done)
                                  else Done;
             end
             else inherited ExecMessage(Message);
           end
         else inherited ExecMessage(Message);
       end;
     end;


   procedure OTListBox.Appendstrings(strings_:PStrList);
     begin
       ListViewer^.Appendstrings(strings_);
     end;


   procedure OTListBox.DeleteAllstrings;
     begin
       ListViewer^.DeleteAllstrings;
     end;


   procedure OTListBox.Deletestrings(From,Count:word);
     begin
       ListViewer^.Deletestrings(From,Count);
     end;
{$ENDIF}


                       {----- OTStrField -----}
   constructor OTStrField.Init(_ID:word;var coord:OTRect; font:OPFont;var strBuffer:PChar);
     const d_=19;
           Marg=2;
           {$IFDEF Warp}
           bkColor=14;
           {$ELSE}
           bkColor=15;
           {$ENDIF}
     var spEdge:integer;
         rect:OTRect;
         lk:boolean;
     begin
       lk:=lookvideo;
       lookvideo:=false;
       spEdge:=Spessore_Bordo;
       Spessore_Bordo:=2;
       inherited Init(coord,'',nil);
       ID:=_ID;
       PtrStrBuffer:=@strBuffer;
       Spessore_Bordo:=spEdge;
       MargSin:=Marg;   MargDes:=Marg;
       MargSup:=Marg;   MargInf:=Marg;
       AddBackGround( new(
       {$IFNDEF Warp}
          OPIncavo3D
       {$ELSE}
          OPBar
       {$ENDIF}
                    , Init(Null_ID,NullRect,1,bkColor)),
                                       NewLayoutMetrics(
                                           NewLayout(LmLeft,InPixels,0),
                                           NewLayout(LmTop,InPixels,0),
                                           NewLayout(LmRight,InPixels,0),
                                           NewLayout(LmBottom,InPixels,0),
                                           LmParent,nil)
       );
       AddOther( new(OPText, Init(Null_ID,NullRect,font,StrPas(strBuffer),1,bkColor,0)),
                                        NewLayoutMetrics(
                                           NewLayout(LmLeft,InPixels,2),
                                           NewLayout(LmTop,InPixels,2),
                                           NewLayout(LmRight,InPixels,0),
                                           NewLayout(LmBottom,InPixels,0),
                                           LmOther,nil)
       );
       {$IFDEF Warp}
       AddBackGround( new(OPRectangle, Init(NullRect,1,In3D)),
                                        NewLayoutMetrics(
                                           NewLayout(LmLeft,InPixels,0),
                                           NewLayout(LmTop,InPixels,0),
                                           NewLayout(LmRight,InPixels,0),
                                           NewLayout(LmBottom,InPixels,0),
                                           LmParent,nil)
       );
       {$ENDIF}
       lookvideo:=lk;
     end;


   procedure OTStrField.ExecMessage(var Message:TMessage);
     var Msg:TMessage;
     begin
       if Message.Message<>EvMOUSE_L_PRESSED then exit;
       Msg.HNDL:=ID;
       Msg.Message:=ID;
       SendMessage(Msg);
       StopESP:=true;
     end;


   procedure OTStrField.Refresh;
     begin
       OPText(_gruppo_^._gruppo_)^.ChangeText(PtrStrBuffer^);
     end;


   procedure OTStrField.ChangeString(str:string);
     begin
       StrDispose(PtrStrBuffer^);
       GetMem(PtrStrBuffer^,length(str)+1);
       StrPCopy(PtrStrBuffer^,str);
       OPText(_gruppo_^._gruppo_)^.ChangeText(PtrStrBuffer^);
     end;


   procedure OTStrField.__ChangeString(str:PChar);
     begin
       StrDispose(PtrStrBuffer^);
       PtrStrBuffer^:=StrNew(str);
       OPText(_gruppo_^._gruppo_)^.ChangeText(PtrStrBuffer^);
     end;


   function OTStrField.GetString:string;
     var str:PChar;
         f:pointer;
         w:word;
     begin
       OPText(_gruppo_^._gruppo_)^.GetTextInfo(str,f,w);
       GetString:=StrPas(str);
     end;


   function OTStrField.__GetString:PChar;
     var str:PChar;
         f:pointer;
         w:word;
     begin
       OPText(_gruppo_^._gruppo_)^.GetTextInfo(str,f,w);
       __GetString:=str;
     end;


   procedure OTStrField.Edit;
     begin
     end;


{$IFDEF NormalScrolls}
                       {----- OTPopUpField -----}
   constructor OTPopUpField.Init(_ID:word;var coord:OTRect; font:OPFont;
                                 strBuffer:TStrBuffer;var numBuffer:word; strings_:PStrList);
     var rect:OTRect;
         lk:boolean;
         buf:PStrList;
         i:word;
         str:PChar;
     begin
       lk:=lookvideo;
       lookvideo:=false;
       if not inherited Init(_ID,coord) then fail;
       PtrNumBuffer:=@numBuffer;
       PtrStrBuffer:=strBuffer;
       SysConfig:=cfPopUpField;
       FontUsed:=font;
       _strings_:=strings_;
       if strings_=nil
         then str:=nil
         else begin
           if numBuffer<2
             then str:=strings_^.str
             else begin
               buf:=strings_;
               for i:=2 to numBuffer do
                 if buf^.succ<>nil then buf:=buf^.succ
                                   else break;
               str:=buf^.Str;
             end;
         end;
       if PtrStrBuffer<>nil then begin
         StrDispose(PtrStrBuffer^);
         PtrStrBuffer^:=StrNew(str);
       end
       else PtrStrBuffer:=@BufferDiFuga;
       SysConfig:=cfPopUpField;
       with coord do rect.SetRect(x1,y1,DimX,24);
       with PullDown do begin
         RegisterAll(_PULL_DOWN_,rect.x2-19,rect.y1+2,true,@PullDown1BTN);
         ButtonConfig:=ButtonConfig or btReactionInRealTime;
       end;
       StrField.Init(_STRING_FIELD_,rect,font,PtrStrBuffer^);
       { Collega i vari elementi che compongono l'oggetto }
       _gruppo_:=@PullDown;
       PullDown.LinkTo(@StrField);
       PullDown._Father_:=@Self;
       StrField._Father_:=@Self;
       lookvideo:=lk;
     end;


   destructor OTPopUpField.Done;
     begin
       DestroySubList;
       inherited Done;
     end;


   procedure OTPopUpField.Adjust;
     var rect:OTRect;
     begin
       with R do
         if DimY<100 then begin
           DimY:=100;
           y2:=y1+100;
         end;
       with R do rect.SetRect(x1,y1,DimX,24);
       StrField.Resize(rect);
       PullDown.Move(rect.x2-19,rect.y1+2);
     end;


   procedure OTPopUpField.ExecMessage(var Message:TMessage);
     var ListBox:OPListBox;
         ListBoxRect:OTRect;
         f:boolean;
     begin
       case Message.Message of
         _PULL_DOWN_: begin
             with R do ListBoxRect.assign(x1,y1+26,x2,y2);
             new(ListBox, Init(Null_ID,ListBoxRect,FontUsed,PtrStrBuffer,PtrNumBuffer^,_strings_));
             f:=ListViewerPopUpMode;
             ListViewerPopUpMode:=true;
             with ListBox^ do begin
               _Father_:=@Self;
               SysConfig:=SysConfig or cfAlwaysAsFirst;
               PutOnDesktop;
               while (PositionAndButtonStatus<>0) and
                     (mcy<=PullDown.R.y2+4)
               do;
               StaticReaction:=PositionAndButtonStatus=0;
               {__StaticReaction:=StaticReaction;}
               if not StaticReaction then begin
                 Message.Message:=EvMOUSE_L_PRESSED;
                 ListViewer^.ExecMessage(Message);
                 ListViewerPopUpMode:=f;
                 dispose(ListBox,Done);
               end
               else begin
                 ListViewerPopUpMode:=f;
                 PopUpMode:=true;
               end;
             end;
         end;
         _STRING_FIELD_: begin
             with R do ListBoxRect.assign(x1,y1+26,x2,y2);
             new(ListBox, Init(Null_ID,ListBoxRect,FontUsed,PtrStrBuffer,PtrNumBuffer^,_strings_));
             f:=ListViewerPopUpMode;
             ListViewerPopUpMode:=true;
             with ListBox^ do begin
               _Father_:=@Self;
               SysConfig:=SysConfig or cfAlwaysAsFirst;
               PutOnDesktop;
               while (PositionAndButtonStatus<>0) and
                     (mcy<=PullDown.R.y2+4)
               do;
               StaticReaction:=PositionAndButtonStatus=0;
               {__StaticReaction:=StaticReaction;}
               if not StaticReaction then begin
                 Message.Message:=EvMOUSE_L_PRESSED;
                 ListViewer^.ExecMessage(Message);
                 ListViewerPopUpMode:=f;
                 dispose(ListBox,Done);
               end
               else begin
                 ListViewerPopUpMode:=f;
                 PopUpMode:=true;
               end;
             end;
         end;
         _LIST_VIEWER_ : begin
             StrField.Refresh;
             Message.Message:=ID;
             SendMessage(Message);
         end;
       end;
     end;

               {****** Fine del codice degli oggetti ******}


   function NewString(Str:string; next:PStrList):PStrList;
     var buf:PStrList;
     begin
       new(buf);
       GetMem(buf^.Str,Length(Str)+1);
       StrPCopy(buf^.Str,Str);
       buf^.succ:=next;
       NewString:=buf;
     end;
{$ENDIF}




type Proc=procedure;

var precExitProc:pointer;


{$F+}
   procedure ExitScrolls;
     var i:TButtonStatus;
     begin
       for i:=StReleased to StDisable do begin
         DestroyDC(FrecciaSopraBTN[i]);
         DestroyDC(FrecciaSottoBTN[i]);
         DestroyDC(FrecciaSinistraBTN[i]);
         DestroyDC(FrecciaDestraBTN[i]);
         DestroyDC(PullDown1BTN[i]);

         DestroyDC(__PullDown1BTN^[i]);
         DestroyDC(__PullDown2BTN^[i]);

       end;

       dispose(__PullDown1BTN);
       dispose(__PullDown2BTN);

       if precExitProc<>nil then Proc(precExitProc);
     end;
{$F-}


   procedure ErroreRisorse;
     begin
       restoreCRTMode;
       writeln('Errore SCROLLS.TPU: Il caricamento delle risorse Š fallito!');
       halt;
     end;


   procedure PerformResources;
     var _bmp_:pointer;
         size:longint;
         B:^TButtonHCAs;
     begin
       new(__PullDown1BTN);
       GetButtonHCAs(__PullDown1BTN^,PullDown1_R,PullDown1_P,PullDown1_D);
       new(__PullDown2BTN);
       GetButtonHCAs(__PullDown2BTN^,PullDown2_R,PullDown2_P,PullDown2_D);
     end;


begin
  SetRESPtr(@Golib_RESOURCES,NumeroRisorse);
  {* Inizializzazione dei tasti "FrecciaX" utilizzati dalle scrollbar. *}
  GetButtonHCAs(FrecciaSopraBTN,FrecciaSopra_R,FrecciaSopra_P,FrecciaSopra_D);
  GetButtonHCAs(FrecciaSottoBTN,FrecciaSotto_R,FrecciaSotto_P,FrecciaSotto_D);
  GetButtonHCAs(FrecciaSinistraBTN,FrecciaSinistra_R,FrecciaSinistra_P,FrecciaSinistra_D);
  GetButtonHCAs(FrecciaDestraBTN,FrecciaDestra_R,FrecciaDestra_P,FrecciaDestra_D);

  GetButtonHCAs(PullDown1BTN,PullDown1_R,PullDown1_P,PullDown1_D);

  PerformResources;

  precExitProc:=ExitProc;
  ExitProc:=@ExitScrolls;
end.
