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


UNIT SCROLLS2;


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
                      ) and __cfDrawFatherRect;

       scbDinamicCursor = $01;
       scbStaticCursor  = $02;
       scbExtendedIndex = $04;
       scbClippedIndex  = $08;

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
          procedure SetVirtualDim(NewVDim:word);
          procedure SetCursorPosition(NewPos:word);
          function GetCursorPosition:integer;
       private
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
          DimCursor,                    { Dimensione del cursore }
          VSCursorPos,                  { VS = Virtual Screen }
          InternalDim  :integer;        { Dimensione tra i due bottoni }

          procedure Reaction;
          procedure SetVariables(InitStage:boolean);
       end;


       OPScrollBox = ^OTScrollBox;
       OTScrollBox = object (OTWindow)
          ScrollerV,
          ScrollerH: OPScrollBar;
          constructor Init(_ID:word;var coord:OTRect; dir:TDirection);
          procedure Adjust; virtual;
          procedure ExecMessage(var Message:TMessage); virtual;
          procedure AddObject(obj:OPView);
          procedure SetCursorPosition(x,y:integer);
       private
          Direction: TDirection;
          posX,
          posY     : integer;
       end;



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


        __Dx=18;
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
       Cursor.SysConfig:=Cursor.SysConfig and __cfBitBtl;
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

       Step:=0;
       VSCursorPos:=0;
       VirtualDim:=VDim;
       InternalDim:=0;
       SetVariables(true);
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
       with coord do if direction=Vert then FirstBtn.R.SetRect(x1,y1,DimX,__Dx-2)
                                       else FirstBtn.R.SetRect(x1,y1,__Dx-2,DimY);
       with coord do if direction=Vert then LastBtn.R.SetRect(x1,y2-__Dx+2,DimX,DimY)
                                       else LastBtn.R.SetRect(x2-__Dx+2,y1,DimX,DimY);
       with coord do if direction=Vert then Cursor.R.SetRect(x1,FirstBtn.R.y2,DimX,(__Dx-1)*2)
                                       else Cursor.R.SetRect(FirstBtn.R.x2,y1,(__Dx-1)*2,DimY);
       SetVariables(false);
     end;


   procedure OTScrollBar.SetVariables(InitStage:boolean);
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
       if VirtualDim = 0 then begin
         Disable;
         exit;
       end;
       if direction=Vert then begin
         InternalDim := LastBtn.R.y1 - FirstBtn.R.y2 - 1;
         DimCursor := round(R.DimY * InternalDim / VirtualDim);
         IDMDC := InternalDim - DimCursor;
         if IDMDC <= 0
           then begin
             Disable;
             exit;
           end
           else begin
             PassoPerPixel := (VirtualDim - R.DimY) / IDMDC;
             MaxVSCursorPos := round(IDMDC * PassoPerPixel);
             CursorPos := round(VSCursorPos / PassoPerPixel);
             with Cursor.R do begin
               DimY := DimCursor;
               y1 := CursorPos + FirstBtn.R.y2 + 1;
               y2 := y1 + DimY;
             end;
             Enable;
           end;
       end
       else begin
         InternalDim := LastBtn.R.x1 - FirstBtn.R.x2 - 1;
         DimCursor := round(R.DimX * InternalDim / VirtualDim);
         IDMDC := InternalDim - DimCursor;
         if IDMDC <= 0
           then begin
             Disable;
             exit;
           end
           else begin
             PassoPerPixel := (VirtualDim - R.DimX) / IDMDC;
             MaxVSCursorPos := round(IDMDC * PassoPerPixel);
             CursorPos := round(VSCursorPos / PassoPerPixel);
             with Cursor.R do begin
               DimX := DimCursor;
               x1 := CursorPos + FirstBtn.R.x2 + 1;
               x2 := x1 + DimX;
             end;
             Enable;
           end;
       end;
       if VSCursorPos = MaxVSCursorPos then LastBtn.Disable;
       if VSCursorPos = 0 then FirstBtn.Disable;
     end;


var StopReaction:boolean;


   procedure OTScrollBar.Reaction;
     var CursorRange:OTRect;
         BRect:OTBar;
         PrecDir:TDirection;
         PaginaIndietro:boolean;
         Evento:word;
         pausa:word;
         wait:boolean;
         VList:PRefreshRectList;
         VMP:pointer;
         Msg:TMessage;

     { Per il wait prima della ripetizione del cambio pagina verr…
       utilizzato il contatore "TimeCounter" che Š collegato all'INT 1Ch }

     begin
       Msg.HNDL:=_SCROLL_BAR_;
     (* Preparazione per la reazione dei tasti direzionali *)
       if FirstBtn.r.XYIn(mcx,mcy) or LastBtn.r.XYIn(mcx,mcy) then begin
         {DelayBeforeRepeatBR:=WaitBeforeRepeat div 5;}
         exit;
       end;
     (* Preparazione per la reazione del cursore *)
       if Direction=Vert then begin
         CursorRange.assign( FirstBtn.r.x1 ,  FirstBtn.r.y2+1,
                             LastBtn.r.x2  ,  LastBtn.r.y1-1  )
       end
       else begin
         CursorRange.assign( FirstBtn.r.x2+1 ,  FirstBtn.r.y1,
                             LastBtn.r.x1-1,  LastBtn.r.y2  );
       end;
       if Cursor.r.XYIn(mcx,mcy) then begin
       (** Reazione del cursore **)
         { Salvataggio valori }
         PrecDir:=EvMoveDirection;
         { Impostazione nuovi valori }
         EvMoveDirection:=Direction;
         EvMoveRange:=CursorRange;
         Cursor.EvMoveObject(mcx,mcy);
         { Ripristino valori }
         EvMoveDirection:=PrecDir;
         EvMoveRange:=NullRect;
       end
       else with BackGr.r do if (mcx>=x1+1) and (mcx<=x2-1) and (mcy>=y1+1) and (mcy<=y2-1) then begin
       (** Reazione del background per lo spostamento di pagina **)
         BRect.Init(Null_ID,NullRect,1,7);
         if Direction=Vert then begin
           PaginaIndietro:=mcy<Cursor.r.y1;
           if PaginaIndietro then BRect.R.assign(FirstBtn.r.x1, FirstBtn.r.y2+1,
                                                 FirstBtn.r.x2, Cursor.r.y1-1)
                             else BRect.R.assign(FirstBtn.r.x1, Cursor.r.y2+1,
                                                 FirstBtn.r.x2, LastBtn.r.y1-1);
         end
         else begin
           PaginaIndietro:=mcx<Cursor.r.x1;
           if PaginaIndietro then BRect.R.assign(FirstBtn.r.x2+1, FirstBtn.r.y1,
                                                 Cursor.r.x1-1,   FirstBtn.r.y2)
                             else BRect.R.assign(Cursor.r.x2+1,   FirstBtn.r.y1,
                                                 LastBtn.r.x1-1,  FirstBtn.r.y2);
         end;
         VList:=GetVisibleZone(@Self,@BRect.R,NullObj);
         if (VList<>nil) and (VList^.succ=nil)
           then begin
             VMP:=nil;
             BRect.R:=VList^.r;
           end
           else VMP:=GetVMP(TypeOf(BRect),VMI_Disegna);
         hidemousecursor;
         if VMP=nil
           then BRect.Disegna
           else DrawRefreshListProc(VList,@BRect,VMP);
         showmousecursor;
         wait:=true;
         StopReaction:=false;
         while PositionAndButtonStatus<>0 do begin
           if wait then begin

             TimeCounter:=0;  { TimeCounter Š direttamente collegato all'INT 1Ch }

             while (TimeCounter<WaitBeforeRepeat) and
                   (PositionAndButtonStatus<>0)
             do;
             wait:=false;
           end;
           (*else begin
             { Ulteriore attesa per evitare che, su computers potenti, la
               ripetizione sia troppo veloce. }

             TimeCounter:=0;  { TimeCounter Š direttamente collegato all'INT 1Ch }

             while (TimeCounter<0) and
                   (PositionAndButtonStatus<>0)
             do;
             if PositionAndButtonStatus=0 then break;
           end;*)
           if PaginaIndietro then begin
             Msg.Message:=_SCROLL_PAGE_INDIETRO_;
             ExecMessage(Msg);
             if Direction=Vert then
               BRect.R.y2:=Cursor.r.y1-1
             else
               BRect.R.x2:=Cursor.r.x1-1;
             if StopReaction then break;
           end
           else begin
             Msg.Message:=_SCROLL_PAGE_AVANTI_;
             ExecMessage(Msg);
             if Direction=Vert then
               BRect.R.y1:=Cursor.r.y2+1
             else
               BRect.R.x1:=Cursor.r.x2+1;
             if StopReaction then break;
           end;
         end; { while }
         with BRect.R do if (x2-x1>0) and (y2-y1>0) then begin
           BRect.SetStyle(1,8);
           {asm
             mov ax,2
             int $33
           end;}  hidemousecursor;
           if VMP=nil
             then BRect.Disegna
             else DrawRefreshListProc(VList,@BRect,VMP);
           {asm
             mov ax,1
             int $33
           end;}  showmousecursor;
         end;
         BRect.Done;
         DisposeRefreshList(VList);
       end;
     end;


   procedure OTScrollBar.ExecMessage(var Message:TMessage);
     var precFlags:boolean;
         OriginalEvent:word;
         n_coord:integer;
         { Nella variabile che segue viene ricalcolato VSCursorPos.
           La necessit… di questo ricalcolo deriva dal fatto che
           che in alcuni casi la posizione contenuta in VSCursorPos
           non coincide alla posizione reale del VS. Questo avviene
           quando il cursore Š posizionato al limite destro/inferiore
           e si Š proceduto ad un ingrandimento della scrollbar. }
         RealVSCursorPos:integer;

     procedure VSPos_CurPos;
       { Imposta partendo da VSCursorPos }
       begin
         {if VSCursorPos>MaxVSCursorPos then begin
           VSCursorPos:=MaxVSCursorPos;
           LastBtn.Disable;
         end
         else LastBtn.Enable;
         if VSCursorPos<=0 then begin
           VSCursorPos:=0;
           FirstBtn.Disable;
         end
         else FirstBtn.Enable;}
         if step<>0 then begin
           n_coord:=VSCursorPos mod Step;
           if n_coord>0 then VSCursorPos:=VSCursorPos+Step-n_coord;
         end;
         if Direction=Vert then begin
           n_coord:=round(VSCursorPos/PassoPerPixel+0.5)+FirstBtn.R.y2;
           if n_coord<=FirstBtn.R.y2 then begin
             n_coord:=FirstBtn.R.y2+1;
             VSCursorPos:=0;
             FirstBtn.Disable;
           end
           else if n_coord+Cursor.R.DimY>=LastBtn.R.y1 then begin
             n_coord:=LastBtn.R.y1-Cursor.R.DimY-1;
             VSCursorPos:=MaxVSCursorPos;
             LastBtn.Disable;
           end;
           if n_coord<>Cursor.R.y1 then Cursor.Move(Cursor.R.x1,n_coord);
         end
         else begin
           n_coord:=round(VSCursorPos/PassoPerPixel+0.5)+FirstBtn.R.x2;
           if n_coord<=FirstBtn.R.x2 then begin
             n_coord:=FirstBtn.R.x2+1;
             VSCursorPos:=0;
             FirstBtn.Disable;
           end
           else if n_coord+Cursor.R.DimX>=LastBtn.R.x1 then begin
             n_coord:=LastBtn.R.x1-Cursor.R.DimX-1;
             VSCursorPos:=MaxVSCursorPos;
             LastBtn.Disable;
           end;
           if n_coord<>Cursor.R.x1 then Cursor.Move(n_coord,Cursor.R.y1);
         end;
         if VSCursorPos>MaxVSCursorPos then VSCursorPos:=MaxVSCursorPos;
       end;

     procedure CurPos_VSPos;
       { Imposta partendo da Cursor.R.x1/y1 }
       begin
         { Determinazione della posizione assoluta del cursore }
         if Direction=Vert then n_coord:=Cursor.r.y1-FirstBtn.R.y2-1
                           else n_coord:=Cursor.r.x1-FirstBtn.R.x2-1;
         VSCursorPos:=round(n_coord*PassoPerPixel);
         if Step<>0 then begin
           VSCursorPos:=VSCursorPos-(VSCursorPos mod Step);
           if Direction=Vert
             then begin
               if Cursor.R.y2+1=LastBtn.R.y1
                 then VSCursorPos:=MaxVSCursorPos;
             end
             else begin
               if Cursor.R.x2+1=LastBtn.R.x1
                 then VSCursorPos:=MaxVSCursorPos;
             end;
         end;
       end;

     begin
       if (SysConfig and cfEnable)=0 then exit;
       OriginalEvent:=Message.Message;
       precFlags:=GOLIBProcPrefered;
       GOLIBProcPrefered:=true;
       case Message.Message of

         EvMOUSE_L_PRESSED :begin
            mcx:=Message.MCX;
            mcy:=Message.MCY;
            Reaction;
            exit;
         end;
         _SCROLL_AVANTI_       :begin
            if step=0 then begin
              if Direction=Vert then begin
                if Cursor.r.y2+1>=LastBtn.r.y1 then begin
                  LastBtn.Disable;
                  Message.Message:=Null_ID;
                end
                else begin
                  Cursor.MoveRel(0,1);
                  Message.Message:=_SCROLL_V_AVANTI_;
                end;
              end
              else begin
                if Cursor.r.x2+1>=LastBtn.r.x1 then begin
                  LastBtn.Disable;
                  Message.Message:=Null_ID;
                end
                else begin
                  Cursor.MoveRel(1,0);
                  Message.Message:=_SCROLL_H_AVANTI_;
                end;
              end;
            end
            else begin
              inc(VSCursorPos,Step);
              if Direction=Vert then Message.Message:=_SCROLL_V_AVANTI_
                                else Message.Message:=_SCROLL_H_AVANTI_;
            end;
            FirstBtn.Enable;
         end;
         _SCROLL_INDIETRO_     :begin
            if step=0 then begin
              if Direction=Vert then begin
                if Cursor.r.y1<=FirstBtn.r.y2+1 then begin
                  FirstBtn.Disable;
                  Message.Message:=Null_ID;
                end
                else begin
                  Cursor.MoveRel(0,-1);
                  Message.Message:=_SCROLL_V_INDIETRO_;
                end;
              end
              else begin
                if Cursor.r.x1<=FirstBtn.r.x2+1 then begin
                  FirstBtn.Disable;
                  Message.Message:=Null_ID;
                end
                else begin
                  Cursor.MoveRel(-1,0);
                  Message.Message:=_SCROLL_H_INDIETRO_;
                end;
              end;
            end
            else begin
              dec(VSCursorPos,Step);
              if Direction=Vert then Message.Message:=_SCROLL_V_INDIETRO_
                                else Message.Message:=_SCROLL_H_INDIETRO_;
            end;
            LastBtn.Enable;
         end;
         _SCROLL_MOVE_         :begin
            if direction=Vert then Message.Message:=_SCROLL_V_MOVE_
                              else Message.Message:=_SCROLL_H_MOVE_;
            FirstBtn.Enable;
            LastBtn.Enable;
         end;
         _SCROLL_PAGE_AVANTI_  :begin
            if step<>0 then begin
              if Direction=Vert
                then begin
                  inc(VSCursorPos,R.DimY);
                  Message.Message:=_SCROLL_V_AVANTI_
                end
                else begin
                  inc(VSCursorPos,R.DimX);
                  Message.Message:=_SCROLL_H_AVANTI_;
                end;
            end
            else begin
              if Direction=Vert then begin
                Message.Message:=_SCROLL_V_PAGE_AVANTI_;
                if Cursor.R.y2+Cursor.R.DimY>=LastBtn.r.y1 then begin
                  Cursor.Move(Cursor.r.x1,LastBtn.r.y1-Cursor.r.DimY-1);
                  LastBtn.Disable;
                  StopReaction:=true;
                end
                else with Cursor do Move(R.x1,R.y1+R.DimY);
              end
              else begin
                Message.Message:=_SCROLL_H_PAGE_AVANTI_;
                if Cursor.R.x2+Cursor.R.DimX>=LastBtn.r.x1 then begin
                  Cursor.Move(LastBtn.R.x1-Cursor.R.DimX-1,Cursor.r.y1);
                  LastBtn.Disable;
                  StopReaction:=true;
                end
                else with Cursor do Move(R.x1+R.DimX,R.y1);
              end;
            end;
            FirstBtn.Enable;
         end;
         _SCROLL_PAGE_INDIETRO_:begin
            if Direction=Vert then begin
              Message.Message:=_SCROLL_V_PAGE_INDIETRO_;
              if Cursor.R.y1-Cursor.R.DimY<=FirstBtn.r.y2 then begin
                Cursor.Move(Cursor.R.x1,FirstBtn.R.y2+1);
                FirstBtn.Disable;
                StopReaction:=true;
              end
              else with Cursor do Move(R.x1,R.y1-R.DimY);
            end
            else begin
              Message.Message:=_SCROLL_H_PAGE_INDIETRO_;
              if Cursor.R.x1-Cursor.R.DimX<=FirstBtn.r.x2 then begin
                Cursor.Move(FirstBtn.R.x2+1,Cursor.R.y1);
                FirstBtn.Disable;
                StopReaction:=true;
              end
              else with Cursor do Move(R.x1-R.DimX,R.y1);
            end;
            LastBtn.Enable;
         end;
         else exit;
       end;
       if (step=0) or
          (OriginalEvent in [_SCROLL_MOVE_,
                             {_SCROLL_PAGE_AVANTI_,}
                             _SCROLL_PAGE_INDIETRO_])
       then CurPos_VSPos
       else VSPos_CurPos;
       GOLIBProcPrefered:=precFlags;
       (*if Message.Message<>Null_ID then begin
         Message.Message:=SYS_SEND_MESSAGE;
         Message.w2Reg:=Message.Message;
         Message.long2Reg:=longint(@_Father_);
         Message.w1Reg:=VSCursorPos;
         {Message.long2Reg:=longint(@Self);
         SendMessage(Message);} AllocMessage(Message);
       end;*)
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


   procedure OTScrollBar.SetVirtualDim(NewVDim:word);
     begin
       VirtualDim:=NewVDim;
       SetVariables(false);
     end;


   procedure OTScrollBar.SetCursorPosition(NewPos:word);
     var n_coord:integer;
         _Enable_:boolean;
         Msg:TMessage;
     begin
       if (VSCursorPos=NewPos)                 or
          not (NewPos in [0..VirtualDim])
       then exit;
       _Enable_:=(SysConfig and cfEnable)<>0;
       if not _Enable_ then NewPos:=0;
       VSCursorPos:=NewPos;
       n_coord:=VSCursorPos mod Step;
       if n_coord<>0 then VSCursorPos:=VSCursorPos+Step-n_coord;
       if Direction=Vert then begin
         { Determina la nuova coordinata Y1 del cursore }
         n_coord:=round(VSCursorPos/PassoPerPixel+0.5)+FirstBtn.R.y2;
         if n_coord<=FirstBtn.R.y2 then begin
           { Caso in cui il cursore andrebbe prima del primo tasto }
           n_coord:=FirstBtn.R.y2+1;
           { Ricalcolo della posizione del VS }
           VSCursorPos:=0;
           FirstBtn.Disable;
         end
         else begin
           if _Enable_ then FirstBtn.Enable;
           if n_coord+Cursor.R.DimY>=LastBtn.R.y1 then begin
             { Caso in cui il cursore andrebbe dopo il secondo tasto }
             n_coord:=LastBtn.R.y1-Cursor.R.DimY-1;
             VSCursorPos:=MaxVSCursorPos;
             LastBtn.Disable;
           end
           else if _Enable_ then LastBtn.Enable;
         end;
         { Movimento del cursore }
         if n_coord<>Cursor.R.y1 then Cursor.Move(Cursor.R.x1,n_coord);
       end
       else begin
         { Determina la nuova coordinata X1 del cursore }
         n_coord:=round(VSCursorPos/PassoPerPixel+0.5)+FirstBtn.R.x2;
         if n_coord<=FirstBtn.R.x2 then begin
           n_coord:=FirstBtn.R.x2+1;
           VSCursorPos:=0;
           FirstBtn.Disable;
         end
         else begin
           FirstBtn.Enable;
           if n_coord+Cursor.R.DimX>=LastBtn.R.x1 then begin
             n_coord:=LastBtn.R.x1-Cursor.R.DimX-1;
             VSCursorPos:=MaxVSCursorPos;
             LastBtn.Disable;
           end
           else LastBtn.Enable;
         end;
         if n_coord<>Cursor.R.x1 then Cursor.Move(n_coord,Cursor.R.y1);
       end;
       if ReactionAtSetPosition then begin
         Msg.HNDL:=_SCROLL_BAR_;
         Msg.Message:=_SCROLL_MOVE_;
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
       SysConfig:=SysConfig and __cfSelectable;
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
         AddTitle(ScrollerV, NewLayoutMetrics(
                                           NewLayout(LmWidth,InPixels,18),
                                           NewLayout(LmTop,InPixels,1),
                                           NewLayout(LmRight,InPixels,0),
                                           NewLayout(LmBottom,InPixels,dy),
                                           LmParent,nil),
         _est_
         )
       end
       else
         ScrollerV:=nil;
       if dir in [Horiz,All] then begin
         ScrollerH:=New(OPScrollBar, Init(Null_ID,0,0,0,horiz,0,0));
         AddTitle(ScrollerH, NewLayoutMetrics(
                                           NewLayout(LmLeft,InPixels,1),
                                           NewLayout(LmHeight,InPixels,18),
                                           NewLayout(LmRight,InPixels,dx),
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
         precPos:=PosY;
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
       Msg.HNDL:=_SCROLL_BOX_;
       Msg.Message:=Message.Message;  {** copia per non alterare Message.Message **}
       s:=_altri_^._last_^._down_;
       _altri_^._last_^._down_:=nil;
       case Msg.Message of
       { Movimento della scrollbar orizzontale }
          _SCROLL_H_AVANTI_,
          _SCROLL_H_INDIETRO_,
          _SCROLL_H_MOVE_,
          _SCROLL_H_PAGE_AVANTI_,
          _SCROLL_H_PAGE_INDIETRO_: begin
            precPos:=PosX;
            posX:=ScrollerH^.GetCursorPosition;
            _altri_^.MoveGroupRel(precPos-posX,0);
          end;
       { Movimento della scrollbar verticale }
          _SCROLL_V_AVANTI_,
          _SCROLL_V_INDIETRO_,
          _SCROLL_V_MOVE_,
          _SCROLL_V_PAGE_AVANTI_,
          _SCROLL_V_PAGE_INDIETRO_: begin
            precPos:=PosY;
            posY:=ScrollerV^.GetCursorPosition;
            _altri_^.MoveGroupRel(0,precPos-posY);
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
       if Msg.Message<>Null_ID then SendMessage(Msg);
     end;


   procedure OTScrollBox.AddObject(obj:OPView);
     begin
       { Aggiornamento delle scrollbars }
       if (ScrollerH<>nil) and (obj^.R.x2>ScrollerH^.VirtualDim)
         then ScrollerH^.SetVirtualDim(obj^.R.x2);
       if (ScrollerV<>nil) and (obj^.R.y2>ScrollerV^.VirtualDim)
         then ScrollerV^.SetVirtualDim(obj^.R.y2);
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


               {****** Fine del codice degli oggetti ******}


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
       end;
       if precExitProc<>nil then Proc(precExitProc);
     end;
{$F-}


   procedure ErroreRisorse;
     begin
       restoreCRTMode;
       writeln('Errore SCROLLS.TPU: Il caricamento delle risorse Š fallito!');
       halt;
     end;



begin
  SetRESPtr(@Golib_RESOURCES,NumeroRisorse);
  {* Inizializzazione dei tasti "FrecciaX" utilizzati dalle scrollbar. *}
  GetButtonHCAs(FrecciaSopraBTN,FrecciaSopra_R,FrecciaSopra_P,FrecciaSopra_D);
  GetButtonHCAs(FrecciaSottoBTN,FrecciaSotto_R,FrecciaSotto_P,FrecciaSotto_D);
  GetButtonHCAs(FrecciaSinistraBTN,FrecciaSinistra_R,FrecciaSinistra_P,FrecciaSinistra_D);
  GetButtonHCAs(FrecciaDestraBTN,FrecciaDestra_R,FrecciaDestra_P,FrecciaDestra_D);

  GetButtonHCAs(PullDown1BTN,PullDown1_R,PullDown1_P,PullDown1_D);

  precExitProc:=ExitProc;
  ExitProc:=@ExitScrolls;
end.
