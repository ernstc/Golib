{ Ernesto CIANCIOTTA Productions }

{***************************************************}
{*                                                 *}
{* Modulo della libreria GOLIB contenete           *}
{* la definizioni degli oggetti "Tasto" astratti   *}
{* e alcuni bottoni di default.                    *}
{*                                                 *}
{* Sritto con Turbo Pascal ver. 7.0.               *}
{*                                                 *}
{***************************************************}

{$D+}
{$L+}

UNIT Buttons;

INTERFACE

  uses crt,

       graph,
       graftool,
       bitmaps,
       resman,
       mouse,
       codici,
       golibcod,
       strings,
       fonts,
       golib_h,
       applic,
       golib9,
         dispfile;


  const
        { Costanti per la manipolazione del flag "ButtonConfig" }
        btPressed                =$01;
        btPersistentMouseControl =$02;
        btReactionInRealTime     =$04;
        btRepeatButtonReaction   =$08;
        btFinalState             =$10;
        btInternalState          =$80; { Riservato perchŠ utilizzato da
                                         OTCheckButton e figli. }


        AllineamentoTasti:(Destra,Sinistra)=Sinistra;
        { Intervallo di tempo prima che la reazione del tasto sia ripetuta }
        StandardDelayBeforeRepeatBR  = 7;
        DelayBeforeRepeatBR :word    = StandardDelayBeforeRepeatBR;
        { Attiva o disattiva l'uso degli effetti speciali per la reazione dei
          bottoni }
        ButtonSpecialEffect :boolean = true;

  type
        PBool = ^Boolean;

        PWord = ^Word;

        PLongint = ^Longint;

        TButtonStatus = (StReleased,StPressed,StDisable);

        TButtonHCAs = array[TButtonStatus] of HCA;

        OPButton = ^OTButton;
        OTButton = object (OTView)
           ButtonConfig:byte;  { vedi FLAGS.TXT }
           ExternalHCA:boolean;   {private}
           _disable_:boolean;     {private}
           ButtonPressed:boolean;
           constructor Load(_ID:word; x,y:integer; attiv:boolean; rlsd,prsd,dsbl:string);
           constructor Register(_ID:word; x,y:integer; attiv:boolean; rlsd,prsd,dsbl:pointer);
           constructor RegisterAll(_ID:word; x,y:integer; attiv:boolean; btn:pointer);
           constructor ClearButton(_ID:word;var coord:OTRect; attiv:boolean; stl:word; col:integer);
           destructor Done; virtual;
           procedure Disegna; virtual;
           procedure ExecMessage(var Message:TMessage); virtual;
           procedure PerformButton(b:pointer);
           procedure PerformStatus(bmp:PHCA; Status:TButtonStatus);
           procedure Pressed; virtual;   {** indicizzato VMI ** vedi GOLIB_H **}
           procedure Released; virtual;  {** indicizzato VMI ** vedi GOLIB_H **}
           procedure Disabled; virtual;  {** indicizzato VMI ** vedi GOLIB_H **}
           procedure SpecialEffect_BeforeReaction; virtual;
           procedure SpecialEffect_AfterReaction; virtual;
           procedure SetStyle(stl:word; col:integer);
        private
           button:^TButtonHCAs;
           stile,colore:word;
           procedure Draw(c1,c2,c3:word);
           function IsButtonPressed(mcx,mcy:integer):boolean;
        end;


        OPTextButton = ^OTTextButton;
        OTTextButton = object(OTButton)
           constructor Init(_ID:word;var coord:OTRect; txt:string; _stato:boolean; stl:word; col,txtcol:integer);
           destructor Done; virtual;
           procedure Disegna; virtual;
           procedure Pressed; virtual;
           procedure Released; virtual;
           procedure ChangeText(NewText:PChar);
        private
           testo:OTText;
           PrecImage:^HCA;
        end;


        OPCheckButton = ^OTCheckButton;
        OTCheckButton = object(OTButton)
           constructor Init(_ID:word; x,y:integer; _text:string; attiv:boolean; variable:PBool; textCol:word);
           procedure Disegna; virtual;
           procedure ExecMessage(var Message:TMessage); virtual;
           procedure Pressed; virtual;
           procedure Released; virtual;
           function GetText:string;
           procedure ChangeText(NewText:string);
        private
           text:string;
           PointVariable:PBool;
           bmp1Y,
           bmp2Y: byte;
        end;


        OPRadioButton = ^OTRadioButton;
        OTRadioButton = object(OTCheckButton)
           constructor Init(x,y:integer; _text:string; attiv:boolean; textCol:word);
           procedure Disegna; virtual;
           procedure ExecMessage(var Message:TMessage); virtual;
           procedure Pressed; virtual;
           procedure Released; virtual;
        end;


        OPCheckButtons = ^OTCheckButtons;
        OTCheckButtons = object(OTView)
           constructor Init(_ID:word; x,y:integer; variable:PLongint; Displaycement:integer; dir:TDirection; objs:OPView);
           procedure ExecMessage(var Message:TMessage); virtual;
           procedure SetButtonStatus(ButtonNum:word; status:boolean);
        private
           PointVariable:PLongint;
           InternalVariable:longint;
        end;


        OPRadioButtons = ^OTRadioButtons;
        OTRadioButtons = object(OTView)
           constructor Init(_ID:word; x,y:integer; variable:PWord; Displaycement:integer; dir:TDirection; objs:OPView);
           procedure ExecMessage(var Message:TMessage); virtual;
           procedure SetButtonStatus(ButtonNum:word; status:boolean);
        private
           PointVariable:PWord;
           InternalVariable:word;
           ActiveButtonPointer:OPRadioButton;
        end;


        OPCloseButton = ^OTCloseButton;
        OTCloseButton = object (OTButton)
           constructor Init(x,y:integer; attiv:boolean);
           procedure SpecialEffect_BeforeReaction; virtual;
        end;



  const
        AutoAssignedButton:boolean=false; {Serve per gli oggetti,  interni al modulo, che
                                           auto-inizializzano i loro bitmaps}

  var
           ZoomBTN,
         UnzoomBTN,
         ReduceBTN,
           HelpBTN,
          CloseBTN:TButtonHCAs;

      OtherBTN_HCA:HCA;

          Null_Var:boolean;


  { Carica dalle risorse le tre immagini del bottone e crea un oggetto
    TButtonHCAs nello HEAP. Infine restituisce il puntatore di tale oggetto. }
  function NewButtonHCAs(Released,Pressed,Disable:word):pointer;
  procedure GetButtonHCAs(var button:TButtonHCAs; Released,Pressed,Disable:word);

  { Procedure per creare liste di bottoni le cui risorse vengono caricate da
    moduli RES residenti in memoria (nei segmenti codice) o sulle memorie di massa. }
  function NewButton(_ID,Released,Pressed,Disable:word; attiv:boolean; next:OPButton):OPButton;
  function NewSEPARATOR(next:OPButton):OPButton;

  function NewCheckButton(_text:string; attiv:boolean; textCol:word; next:OPCheckButton):OPCheckButton;
  function NewRadioButton(_text:string; attiv:boolean; textCol:word; next:OPRadioButton):OPRadioButton;



IMPLEMENTATION


  const
        DrawLastReleased:boolean = true;



  function NewButtonHCAs(Released,Pressed,Disable:word):pointer;
    var buf:^TButtonHCAs;
        _bmp_:pointer;
        DimFileImage:longint;

    procedure DisposeBMP;
      begin
        { N.B.: Codice inline per 80386 e successivi }
        inline(
          { Legge il contenuto di _bmp_ }
          $C4/$7E/$0A/        { LES    DI,DWORD PTR SS:[BP+10]  }

          { Carica in DimFileImage la dimensione della immagine del
            file contenuta nello HEAP }
          $66/$26/$8B/$45/$02/{ MOV    EAX,DWORD PTR ES:[DI+2]  }
          $66/$89/$46/$06     { MOV    DWORD PTR SS:[BP+6],EAX  }
        );
        FreeMem(_bmp_,DimFileImage);
      end;

    begin
      new(buf);
      if Released<>0 then begin
        if GetResource_IDNum(Released,_bmp_)=0 then begin
          NewButtonHCAs:=nil;
          dispose(buf);
          exit;
        end;
        if CreateCompatibleArea(buf^[StReleased],_bmp_^)=nil then begin
          NewButtonHCAs:=nil;
          dispose(buf);
          DisposeBMP;
          exit;
        end;
        DisposeBMP;
      end;
      if Pressed<>0 then begin
        if GetResource_IDNum(Pressed,_bmp_)=0 then begin
          NewButtonHCAs:=nil;
          if Released<>0 then DestroyDC(buf^[StReleased]);
          dispose(buf);
          exit;
        end;
        if CreateCompatibleArea(buf^[StPressed],_bmp_^)=nil then begin
          NewButtonHCAs:=nil;
          if Released<>0 then DestroyDC(buf^[StReleased]);
          dispose(buf);
          DisposeBMP;
          exit;
        end;
        DisposeBMP;
      end;
      if Disable<>0 then begin
        if GetResource_IDNum(Disable,_bmp_)=0 then begin
          NewButtonHCAs:=nil;
          if Released<>0 then DestroyDC(buf^[StReleased]);
          if Pressed<>0 then DestroyDC(buf^[StPressed]);
          dispose(buf);
          exit;
        end;
        if CreateCompatibleArea(buf^[StDisable],_bmp_^)=nil then begin
          NewButtonHCAs:=nil;
          if Released<>0 then DestroyDC(buf^[StReleased]);
          if Pressed<>0 then DestroyDC(buf^[StPressed]);
          dispose(buf);
          DisposeBMP;
          exit;
        end;
        DisposeBMP;
      end;
      NewButtonHCAs:=buf;
    end;


  procedure GetButtonHCAs(var button:TButtonHCAs; Released,Pressed,Disable:word);
    var _bmp_:pointer;
        DimFileImage:longint;

    procedure DisposeBMP;
      begin
        { N.B.: Codice inline per 80386 e successivi }
        inline(
          { Legge il contenuto di _bmp_ }
          $C4/$7E/$0A/        { LES    DI,DWORD PTR SS:[BP+10]  }

          { Carica in DimFileImage la dimensione della immagine del
            file contenuta nello HEAP }
          $66/$26/$8B/$45/$02/{ MOV    EAX,DWORD PTR ES:[DI+2]  }
          $66/$89/$46/$06     { MOV    DWORD PTR SS:[BP+6],EAX  }
        );
        FreeMem(_bmp_,DimFileImage);
      end;

    begin
      if Released<>0 then begin
        if GetResource_IDNum(Released,_bmp_)=0 then exit;
        if CreateCompatibleArea(button[StReleased],_bmp_^)=nil then begin
          DisposeBMP;
          exit;
        end;
        DisposeBMP;
      end;
      if Pressed<>0 then begin
        if GetResource_IDNum(Pressed,_bmp_)=0 then begin
          if Released<>0 then DestroyDC(button[StReleased]);
          exit;
        end;
        if CreateCompatibleArea(button[StPressed],_bmp_^)=nil then begin
          if Released<>0 then DestroyDC(button[StReleased]);
          DisposeBMP;
          exit;
        end;
        DisposeBMP;
      end;
      if Disable<>0 then begin
        if GetResource_IDNum(Disable,_bmp_)=0 then begin
          if Released<>0 then DestroyDC(button[StReleased]);
          if Pressed<>0 then DestroyDC(button[StPressed]);
          exit;
        end;
        if CreateCompatibleArea(button[StDisable],_bmp_^)=nil then begin
          if Released<>0 then DestroyDC(button[StReleased]);
          if Pressed<>0 then DestroyDC(button[StPressed]);
          DisposeBMP;
          exit;
        end;
        DisposeBMP;
      end;
    end;


  function NewButton(_ID,Released,Pressed,Disable:word; attiv:boolean; next:OPButton):OPButton;
    var button:OPView;
        BtnHCAs:^TButtonHCAs;
    begin
      BtnHCAs:=NewButtonHCAs(Released,Pressed,Disable);
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


  function NewCheckButton(_text:string; attiv:boolean; textCol:word; next:OPCheckButton):OPCheckButton;
    var button:OPCheckButton;
    begin
      new(button, Init(Null_ID,0,0,_text,attiv,nil,textCol));
      button^._up_:=next;
      button^._down_:=nil;
      if next<>nil then next^._down_:=button;
      NewCheckButton:=button;
    end;


  function NewRadioButton(_text:string; attiv:boolean; textCol:word; next:OPRadioButton):OPRadioButton;
    var button:OPRadioButton;
    begin
      new(button,Init(0,0,_text,attiv,textCol));
      button^._up_:=next;
      button^._down_:=nil;
      if next<>nil then next^._down_:=button;
      NewRadioButton:=button;
    end;




                   { -----  OTButton ----- }
   const StartUpButtonConfig = btPersistentMouseControl;


   constructor OTButton.Load(_ID:word; x,y:integer; attiv:boolean; rlsd,prsd,dsbl:string);
     var BMP_buffer:pointer;
         size:longint;
     begin
       ExternalHCA:=false;
       if (rlsd='') or (prsd='') then begin
         restoreCRTMode;
         writeln('Errore BUTTONS.TPU: Parametri per inizializzazione pulsante errati!');
         halt;
       end;
       new(button);

       size:=LoadBitMap(rlsd,BMP_buffer);
       CreateCompatibleArea(button^[StReleased],BMP_buffer^);
       FreeMem(BMP_buffer,size);

       size:=LoadBitMap(prsd,BMP_buffer);
       CreateCompatibleArea(button^[StPressed],BMP_buffer^);
       FreeMem(BMP_buffer,size);

       if dsbl<>'' then begin
         size:=LoadBitMap(dsbl,BMP_buffer);
         CreateCompatibleArea(button^[StDisable],BMP_buffer^);
         FreeMem(BMP_buffer,size);
         _disable_:=true;
       end
       else _disable_:=false;
       inherited Init(_ID,r);
       r.assign(x,y,x+button^[StReleased].DimX-1,y+button^[StReleased].DimY-1);
       if attiv then SysConfig:=SysConfig or cfEnable
                else SysConfig:=SysConfig and __cfDisable;
       SysConfig:=SysConfig or cfPostDraw;
       ButtonConfig:=StartUpButtonConfig;
     end;


   constructor OTButton.Register(_ID:word; x,y:integer; attiv:boolean; rlsd,prsd,dsbl:pointer);
     begin
       ExternalHCA:=AutoAssignedButton;
       if not AutoAssignedButton then begin
         if (rlsd=nil) or (prsd=nil) then begin
           restoreCRTMode;
           writeln('Errore BUTTONS.TPU: Parametri per inizializzazione pulsante errati!');
           halt;
         end;
         new(button);
         CreateCompatibleArea(button^[StReleased],rlsd^);
         CreateCompatibleArea(button^[StPressed],prsd^);
         if dsbl<>nil then begin
           CreateCompatibleArea(button^[StDisable],dsbl^);
           _disable_:=true;
         end
         else _disable_:=false;
       end;
       inherited Init(_ID,r);
       r.assign(x,y,x+button^[StReleased].DimX-1,y+button^[StReleased].DimY-1);
       if attiv then SysConfig:=SysConfig or cfEnable
                else SysConfig:=SysConfig and __cfDisable;
       SysConfig:=SysConfig or cfPostDraw;
       ButtonConfig:=StartUpButtonConfig;
     end;


   constructor OTButton.RegisterAll(_ID:word; x,y:integer; attiv:boolean; btn:pointer);
     begin
       ExternalHCA:=true;
       _disable_:=true;
       button:=btn;
       inherited Init(_ID,r);
       r.assign(x,y,x+button^[StReleased].DimX-1,y+button^[StReleased].DimY-1);
       if attiv then SysConfig:=SysConfig or cfEnable
                else SysConfig:=SysConfig and __cfDisable;
       SysConfig:=SysConfig or cfPostDraw;
       ButtonConfig:=StartUpButtonConfig;
     end;


   constructor OTButton.ClearButton(_ID:word;var coord:OTRect; attiv:boolean; stl:word; col:integer);
     begin
       ExternalHCA:=false;
       button:=nil;
       stile:=stl;
       colore:=col;
       inherited Init(_ID,coord);
       if attiv then SysConfig:=SysConfig or cfEnable
                else SysConfig:=SysConfig and __cfDisable;
       SysConfig:=SysConfig or cfPostDraw;
       ButtonConfig:=StartUpButtonConfig;
     end;


   destructor OTButton.Done;
     begin
       if (button<>nil) and not ExternalHCA then begin
         DestroyDC(button^[StReleased]);
         DestroyDC(button^[StPressed]);
         if _disable_ then DestroyDC(button^[StDisable]);
         dispose(button);
       end;
       ButtonSpecialEffect:=false;
       inherited Done;
     end;


   procedure OTButton.Disegna;
     var precFlags:boolean;
     begin
       if (SysConfig and cfEnable)=0 then Disabled
       else begin
         if button<>nil then begin
           if (ButtonConfig and btPressed)=0 then Released
                                             else Pressed;
         end
         else begin
           if (ButtonConfig and btPressed)=0 then Draw(15,0,7)
                                             else Draw(7,colore,15);
           setfillstyle(stile,colore);
           precFlags:=GOLIBProcPrefered;
           GOLIBProcPrefered:=true;
           bar(r.x1+1,r.y1+1,r.x2-2,r.y2-2);
           GOLIBProcPrefered:=precFlags;
         end;
       end;
     end;


   procedure OTButton.ExecMessage(var Message:TMessage);
  label ExitReaction;
     var
         precStopESP,
         BSE,
         firstSend: boolean;
         view:ViewPortType;
         PrecView:ViewPortType;
         VisibleZone:PRefreshRectList;
         PtrPressed,
         PtrReleased:pointer;

     { Per il wait prima della ripetizione della reazione del tasto verr…
       utilizzato il contatore "TimeCounter" che Š collegato all'INT 1Ch }

     begin
       case Message.Message of
         EvMOUSE_L_PRESSED: begin
             mcx:=Message.Mcx;
             mcy:=Message.Mcy;

             PtrPressed:=GetVMP(typeOf(Self),VMI_OTButton_Pressed);
             PtrReleased:=GetVMP(typeOf(Self),VMI_OTButton_Released);
             VisibleZone:=GetVisibleZone(@Self,nil,NullObj);
             GetViewSettings(view);
             ButtonPressed:=false;
             if (SysConfig and cfEnable)<>0 then begin
               setwritemode(0);
               HideMouseCursor;
               if (ButtonConfig and btPressed)=0
                 then DrawRefreshListProc(VisibleZone,@Self,PtrPressed,nil,ObjectNoParam)
                 else DrawRefreshListProc(VisibleZone,@Self,PtrReleased,nil,ObjectNoParam);
               { Il Controllo sul flag si ripete per dare la possibilit…
                 ai metodi Pressed e Released di modificare il flag }
               if (ButtonConfig and btPressed)=0
                 then ButtonConfig:=ButtonConfig or  btPressed
                 else ButtonConfig:=ButtonConfig and not btPressed;
               ShowMouseCursor;
               TimeCounter:=0;
               FirstSend:=true;
               if (ButtonConfig and btPersistentMouseControl)<>0 then begin

                 while Message.Message<>EvMOUSE_L_RELEASED do begin
                   if R.XYIn(mcx-view.x1,mcy-view.y1) then begin
                     if (ButtonConfig and btPressed)=0 then begin
                       HideMouseCursor;
                       DrawRefreshListProc(VisibleZone,@Self,PtrPressed,nil,ObjectNoParam);
                       ShowMouseCursor;
                       { Il Controllo sul flag si ripete per dare la possibilit…
                         ai metodi Pressed e Released di modificare il flag }
                       if (ButtonConfig and btPressed)=0
                         then ButtonConfig:=ButtonConfig or  btPressed
                         else ButtonConfig:=ButtonConfig and not btPressed;
                     end;
                     ButtonPressed:=false;
                     if (ButtonConfig and btReactionInRealTime)<>0 then begin
                       Message.Message:=ID;
                       if FirstSend then begin

                         precStopESP:=StopESP;
                         SendMessage(Message);
                         StopESP:=precStopESP;

                         if (SysConfig and cfEnable)=0 then begin
                           ButtonConfig:=ButtonConfig and not btPressed;
                           goto ExitReaction;
                         end;
                         FirstSend:=false;
                       end;
                       if (ButtonConfig and btRepeatButtonReaction)<>0 then
                         if TimeCounter>=DelayBeforeRepeatBR then begin
                           TimeCounter:=DelayBeforeRepeatBR;

                           precStopESP:=StopESP;
                           SendMessage(Message);
                           StopESP:=precStopESP;

                           if (SysConfig and cfEnable)=0 then begin
                             ButtonConfig:=ButtonConfig and not btPressed;
                             goto ExitReaction;
                           end;
                         end;
                     end;
                   end
                   else if (ButtonConfig and btPressed)<>0 then begin
                     TimeCounter:=0;
                     FirstSend:=true;
                     HideMouseCursor;
                     DrawRefreshListProc(VisibleZone,@Self,PtrReleased,nil,ObjectNoParam);
                     ShowMouseCursor;
                     { Il Controllo sul flag si ripete per dare la possibilit…
                       ai metodi Pressed e Released di modificare il flag }
                     if (ButtonConfig and btPressed)=0
                       then ButtonConfig:=ButtonConfig or  btPressed
                       else ButtonConfig:=ButtonConfig and not btPressed;
                   end;
                   if (ButtonConfig and btRepeatButtonReaction)<>0
                     then GetLastMouseMessage(Message, rcMove or
                                                       rcLPressed or
                                                       rcLReleased)
                     else WaitNextMouseMessage(Message, rcMove or
                                                        rcLPressed or
                                                        rcLReleased);
                   mcx:=Message.Mcx;
                   mcy:=Message.Mcy;
                 end; { while }

                 ButtonPressed:=(ButtonConfig and btPressed)=btPressed;
                 if (ButtonConfig and btPressed)<>0 then begin
                   HideMouseCursor;
                   DrawRefreshListProc(VisibleZone,@Self,PtrReleased,nil,ObjectNoParam);
                   ShowMouseCursor;
                   { Il Controllo sul flag si ripete per dare la possibilit…
                     ai metodi Pressed e Released di modificare il flag }
                   if (ButtonConfig and btPressed)=0
                     then ButtonConfig:=ButtonConfig or  btPressed
                     else ButtonConfig:=ButtonConfig and not btPressed;
                 end;
               end
               else begin
                 { Chiave per far reagire il padre }
                 ButtonPressed:=true;
                 { Chiave per far reagire il bottone }
                 {ButtonConfig:=ButtonConfig and not btReactionInRealTime;}
               end;
             end
             else ButtonPressed:=false;
             if ButtonPressed
               then ButtonConfig:=ButtonConfig or btFinalState
               else ButtonConfig:=ButtonConfig and not btFinalState;
             if ((ButtonConfig and btReactionInRealTime)=0) and
                ButtonPressed
             then begin
               BSE:=ButtonSpecialEffect;
               if ButtonSpecialEffect then SpecialEffect_BeforeReaction;
               Message.HNDL:=_OBJ_POINTED_;
               Message.Message:=ID;

               SendMessage(Message);
               {AllocMessage(Message);}

               if ButtonSpecialEffect then SpecialEffect_AfterReaction;
               ButtonSpecialEffect:=BSE;
             end
             else EventVerified:=false;
             StopESP:=true;

         ExitReaction:

             DelayBeforeRepeatBR:=StandardDelayBeforeRepeatBR;
             DisposeRefreshList(VisibleZone);
           end;
         EvMOUSE_L_RELEASED: begin

           end;
         EvMOUSE_MOVES: begin

           end;
       end;
     end;


   procedure OTButton.PerformButton(b:pointer);
     begin
       if ExternalHCA then button:=b;
       Refresh;
     end;


   procedure OTButton.PerformStatus(bmp:PHCA; Status:TButtonStatus);
     begin
       button^[Status]:=bmp^;
       Refresh;
     end;


   procedure OTButton.Pressed;
     begin
       if button<>nil then
         BitBtl(button^[StPressed],VideoDC,0,0,r.x1,r.y1,r.DimX+1,r.DimY+1)
       else
         Draw(7,colore,15);
     end;


   procedure OTButton.Released;
     begin
       if button<>nil
         then
           BitBtl(button^[StReleased],VideoDC,0,0,r.x1,r.y1,r.DimX+1,r.DimY+1)
         else
           Draw(15,0,7);
     end;


   procedure OTButton.Disabled;
     var precFlags:boolean;
     begin
       if button<>nil
         then
           BitBtl(button^[StDisable],VideoDC,0,0,r.x1,r.y1,r.DimX+1,r.DimY+1)
         else begin
           Draw(15,0,7);
           setfillstyle(stile,colore);
           precFlags:=GOLIBProcPrefered;
           GOLIBProcPrefered:=true;
           bar(r.x1+1,r.y1+1,r.x2-2,r.y2-2);
           GOLIBProcPrefered:=precFlags;
         end;
     end;


   procedure OTButton.SetStyle(stl:word; col:integer);
     begin
       stile:=stl;
       colore:=col;
     end;


   procedure OTButton.SpecialEffect_BeforeReaction;
     begin
     end;


   procedure OTButton.SpecialEffect_AfterReaction;
     begin
     end;


   procedure OTButton.Draw(c1,c2,c3:word);
     begin
       setcolor(c1);
         moveTo(r.x1,r.y2-1);
         lineTo(r.x1,r.y1);
         lineTo(r.x2-1,r.y1);
       setcolor(c2);
         moveTo(r.x2,r.y1);
         lineTo(r.x2,r.y2);
         lineTo(r.x1,r.y2);
       setcolor(c3);
         moveTo(r.x1+1,r.y2-1);
         lineTo(r.x2-1,r.y2-1);
         lineTo(r.x2-1,r.y1+1);
     end;


   function OTButton.IsButtonPressed(mcx,mcy:integer):boolean;
     var view:ViewPortType;
         PrecView:ViewPortType;
         VisibleZone:PRefreshRectList;
         PtrPressed,
         PtrReleased:pointer;
         Message:TMessage;
     begin
       Message.Message:=EvMOUSE_L_PRESSED;
       Message.MCX:=mcx;
       Message.MCY:=mcy;
       PtrPressed:=GetVMP(typeOf(Self),VMI_OTButton_Pressed);
       PtrReleased:=GetVMP(typeOf(Self),VMI_OTButton_Released);
       VisibleZone:=GetVisibleZone(@Self,nil,NullObj);
       GetViewSettings(view);
       ButtonPressed:=false;
       if (SysConfig and cfEnable)<>0 then begin
         setwritemode(0);
         HideMouseCursor;
         if (ButtonConfig and btPressed)=0
           then DrawRefreshListProc(VisibleZone,@Self,PtrPressed,nil,ObjectNoParam)
           else DrawRefreshListProc(VisibleZone,@Self,PtrReleased,nil,ObjectNoParam);
         { Il Controllo sul flag si ripete per dare la possibilit…
           ai metodi Pressed e Released di modificare il flag }
         if (ButtonConfig and btPressed)=0
           then ButtonConfig:=ButtonConfig or  btPressed
           else ButtonConfig:=ButtonConfig and not btPressed;
         ShowMouseCursor;
         if (ButtonConfig and btPersistentMouseControl)<>0 then begin

           while Message.Message<>EvMOUSE_L_RELEASED do begin
             if R.XYIn(mcx-view.x1,mcy-view.y1) then begin
               if (ButtonConfig and btPressed)=0 then begin
                 HideMouseCursor;
                 DrawRefreshListProc(VisibleZone,@Self,PtrPressed,nil,ObjectNoParam);
                 ShowMouseCursor;
                 { Il Controllo sul flag si ripete per dare la possibilit…
                   ai metodi Pressed e Released di modificare il flag }
                 if (ButtonConfig and btPressed)=0
                   then ButtonConfig:=ButtonConfig or  btPressed
                   else ButtonConfig:=ButtonConfig and not btPressed;
               end;
               ButtonPressed:=false;
             end
             else if (ButtonConfig and btPressed)<>0 then begin
               HideMouseCursor;
               DrawRefreshListProc(VisibleZone,@Self,PtrReleased,nil,ObjectNoParam);
               ShowMouseCursor;
               { Il Controllo sul flag si ripete per dare la possibilit…
                 ai metodi Pressed e Released di modificare il flag }
               if (ButtonConfig and btPressed)=0
                 then ButtonConfig:=ButtonConfig or  btPressed
                 else ButtonConfig:=ButtonConfig and not btPressed;
             end;
             WaitNextMouseMessage(Message, rcMove or
                                           rcLPressed or
                                           rcLReleased);
             mcx:=Message.Mcx;
             mcy:=Message.Mcy;
           end; { while }

           ButtonPressed:=(ButtonConfig and btPressed)=btPressed;
           if (ButtonConfig and btPressed)<>0 then begin
             if DrawLastReleased then begin
               HideMouseCursor;
               DrawRefreshListProc(VisibleZone,@Self,PtrReleased,nil,ObjectNoParam);
               ShowMouseCursor;
             end;
             { Il Controllo sul flag si ripete per dare la possibilit…
               ai metodi Pressed e Released di modificare il flag }
             if (ButtonConfig and btPressed)=0
               then ButtonConfig:=ButtonConfig or  btPressed
               else ButtonConfig:=ButtonConfig and not btPressed;
           end;
         end
         else begin
           { Chiave per far reagire il padre }
           ButtonPressed:=true;
         end;
       end
       else ButtonPressed:=false;
       if ButtonPressed
         then ButtonConfig:=ButtonConfig or btFinalState
         else ButtonConfig:=ButtonConfig and not btFinalState;
       DisposeRefreshList(VisibleZone);
       IsButtonPressed:=ButtonPressed;
     end;


                   {----- OTTextButton -----}
   constructor OTTextButton.Init(_ID:word;var coord:OTRect; txt:string; _stato:boolean;
                                 stl:word; col,txtcol:integer);
     var rtxt:OTRect;
     begin
       with coord do rtxt.assign(0,0,DimX,DimY);
       testo.Init(Null_ID,rtxt,@_serif10_,txt,stl,col,txtcol);
       ClearButton(_ID,coord,_stato,stl,col);
       PrecImage:=nil;
     end;


   destructor OTTextButton.Done;
     begin
       testo.Done;
       inherited Done;
     end;


   procedure OTTextButton.Disegna;
     begin
       inherited Disegna;
       testo.r.Move(r.x1+3,r.y1+3);
       testo.disegna;
       testo.r.assign(0,0,r.DimX,r.DimY);
     end;


   procedure OTTextButton.Pressed;
     begin
       new(PrecImage);
       with R do begin
         CreateCompatibleDC(PrecImage^,DimX,DimY);
         BitBtl(VideoDC,PrecImage^,x1,y1,0,0,DimX,DimY);
         BitBtlVideoDC(x1+1,y1+1,x1+3,y1+3,DimX-3,DimY-3);
         putpixel(x1+2,y2-1,8);
         putpixel(x2-1,y1+2,8);
         setcolor(0);
         Rectangle(x1,y1,x2,y2);
         setcolor(7);
         line(x1+1,y1+1,x2-1,y1+1);
         line(x1+1,y1+1,x1+1,y2-1);
       end;
     end;


   procedure OTTextButton.Released;
     begin
       with R do BitBtl(PrecImage^,VideoDC,0,0,x1,y1,DimX,DimY);
       DestroyDC(PrecImage^);
       dispose(PrecImage);
     end;


   procedure OTTextButton.ChangeText(newText:PChar);
     begin
       testo.ChangeText(newText);
       testo.r.Move(r.x1+3,r.y1+3);
       testo.disegna;
       testo.r.assign(0,0,r.DimX,r.DimY);
     end;


                      { ----- OTCheckButton ----- }
const DimB=14;
      TxPos1=5;
      TxPos2=2;

   constructor OTCheckButton.Init(_ID:word; x,y:integer; _text:string; attiv:boolean; variable:PBool; textCol:word);
     const btCheckSet = {btPressed or} btInternalState;
     var coord:OTRect;
     begin
       text:=_text;
       coord.assign(x,y,x+DimB+_Serif10_.TextLength(_text,0,0)+TxPos1,y+DimB+TxPos2);
       ClearButton(_ID,coord,attiv,0,TextCol);
       PointVariable:=variable;
       if variable<>nil then begin
         if variable^
           then ButtonConfig:=ButtonConfig or btCheckSet
           else ButtonConfig:=ButtonConfig and not btCheckSet
       end
       else ButtonConfig:=ButtonConfig and not btCheckSet;
       {ButtonConfig:=ButtonConfig and not btPersistentMouseControl;}
       bmp1Y:=DimB;
       bmp2Y:=0;
     end;


   procedure OTCheckButton.Disegna;
     begin
       if (ButtonConfig and btInternalState)<>0
         then BitBtl(OtherBTN_HCA,VideoDC,0,DimB,r.x1,r.y1,DimB,DimB)
         else BitBtl(OtherBTN_HCA,VideoDC,0,0,r.x1,r.y1,DimB,DimB);
       TextColor:=colore;
       if (SysConfig and cfEnable)=cfEnable then
         _Serif10_.DrawText(r.x1+DimB+TxPos1,r.y1+TxPos2,TextLeft,text)
       else
         _Serif10_.DrawTextIn(r.x1+DimB+TxPos1,r.y1+TxPos2,TextLeft,text);
     end;


   procedure OTCheckButton.ExecMessage(var Message:TMessage);
     var method:pointer;
     begin
       case Message.Message of
         EvMOUSE_L_PRESSED: begin
             if (ButtonConfig and btInternalState)<>0 then begin
               bmp1Y:=DimB;
               bmp2Y:=DimB*3;
             end
             else begin
               bmp1Y:=0;
               bmp2Y:=DimB*2;
             end;
             IsButtonPressed(Message.MCX,Message.MCY);
             if (ButtonConfig and btFinalState)<>0 then begin
               if (ButtonConfig and btInternalState)<>0 then begin
                 ButtonConfig:=ButtonConfig and not btInternalState;
                 bmp1Y:=0;
                 method:=GetVMP(typeOf(Self),VMI_OTButton_Released);
                 if PointVariable<>nil then PointVariable^:=false;
               end
               else begin
                 ButtonConfig:=ButtonConfig or btInternalState;
                 bmp2Y:=DimB;
                 method:=GetVMP(typeOf(Self),VMI_OTButton_Pressed);
                 if PointVariable<>nil then PointVariable^:=true;
               end;
               DrawRefreshListProc( GetVisibleZone(@Self,nil,NullObj),
                                    @Self,
                                    method,nil,ObjectNoParam);
             end;
           end;
       end;
     end;


   procedure OTCheckButton.Pressed;
     begin
       BitBtl(OtherBTN_HCA,VideoDC,0,bmp2Y,r.x1,r.y1,DimB,DimB);
     end;


   procedure OTCheckButton.Released;
     begin
       BitBtl(OtherBTN_HCA,VideoDC,0,bmp1Y,r.x1,r.y1,DimB,DimB);
     end;

   function OTCheckButton.GetText:string;
     begin
       GetText:=text;
     end;


   procedure OTCheckButton.ChangeText(NewText:string);
     begin
     end;


                    { ----- OTRadioButton ----- }
   constructor OTRadioButton.Init(x,y:integer; _text:string; attiv:boolean; textCol:word);
     var coord:OTRect;
     begin
       text:=_text;
       coord.assign(x,y,x+DimB+4+_Serif10_.TextLength(_text,0,0)+TxPos1,y+DimB+TxPos2);
       ClearButton(Null_ID,coord,attiv,0,TextCol);
       {ButtonConfig:=ButtonConfig and not btPersistentMouseControl;}
       MouseReactionMask:=rcLPressed;
       PointVariable:=nil;
       bmp1Y:=0;
       bmp2Y:=DimB;
     end;


   procedure OTRadioButton.Disegna;
     begin
       if (ButtonConfig and btInternalState)<>0
         then BitBtl(OtherBTN_HCA,VideoDC,DimB+1,DimB,r.x1,r.y1+2,DimB+4,DimB)
         else BitBtl(OtherBTN_HCA,VideoDC,DimB+1,0,r.x1,r.y1+2,DimB+4,DimB);
       TextColor:=colore;
       if (SysConfig and cfEnable)=cfEnable then
         _Serif10_.DrawText(r.x1+DimB+4+TxPos1,r.y1+TxPos2,TextLeft,text)
       else
         _Serif10_.DrawTextIn(r.x1+DimB+4+TxPos1,r.y1+TxPos2,TextLeft,text);
     end;


   procedure OTRadioButton.ExecMessage(var Message:TMessage);
     var method:pointer;
     begin
       case Message.Message of
         EvMOUSE_L_PRESSED: begin
             if (ButtonConfig and btInternalState)<>0 then begin
               bmp1Y:=DimB;
               bmp2Y:=DimB*3;
             end
             else begin
               bmp1Y:=0;
               bmp2Y:=DimB*2;
               DrawLastReleased:=false;
             end;
             IsButtonPressed(Message.MCX,Message.MCY);
             DrawLastReleased:=true;
             if (ButtonConfig and btInternalState)=0 then begin
               if (ButtonConfig and btFinalState)<>0 then begin
                 bmp2Y:=DimB;
                 if _Father_<>nil
                   then begin
                     Message.HNDL:=_RADIO_BUTTON_;
                     Message.Message:=_SET_NEW_RADIO_BUTTON_;
                     Message.w1Reg:=ID;
                     _Father_^.ExecMessage(Message)
                   end
                   else begin
                     ButtonConfig:=ButtonConfig or btInternalState;
                     bmp2Y:=DimB;
                     DrawRefreshListProc( GetVisibleZone(@Self,nil,NullObj),
                                          @Self,
                                          GetVMP(typeOf(Self),VMI_OTButton_Pressed),nil,ObjectNoParam);
                   end;
               end;
             end
             else begin
               bmp1Y:=0;
               bmp2Y:=DimB;
             end;
           end;
       end;
     end;


   procedure OTRadioButton.Pressed;
     begin
       BitBtl(OtherBTN_HCA,VideoDC,DimB+1,bmp2Y,r.x1,r.y1+2,DimB+4,DimB)
     end;


   procedure OTRadioButton.Released;
     begin
       BitBtl(OtherBTN_HCA,VideoDC,DimB+1,bmp1Y,r.x1,r.y1+2,DimB+4,DimB);
     end;


                    { ----- OTCheckButtons ----- }
   constructor OTCheckButtons.Init(_ID:word; x,y:integer; variable:PLongint; Displaycement:integer; dir:TDirection;
                                   objs:OPView);
     const btCheckSet = {btPressed or} btInternalState;
     var bufV:OPCheckButton;
         dx,dy:integer;
         count:byte;
         mask:longint;
         bState:boolean;
     begin
       r.assign(x,y,x,y);
       inherited InitComposite(_ID,r,objs);
       SysConfig:=Sysconfig or cfPostDraw;
       SysConfig:=Sysconfig and not cfDrawFatherRect;
       MouseReactionMask:=rcLPressed;

       PointVariable:=variable;
       if variable<>nil then InternalVariable:=variable^
                        else InternalVariable:=0;
       bufV:=pointer(_gruppo_);
       dx:=0;
       dy:=0;
       count:=0;
       while bufV<>nil do begin
         mask:=1 shl count;
         if (InternalVariable and mask)<>0 then bState:=false
                                           else bState:=true;
         with bufV^ do begin
           if PointVariable<>nil then PointVariable^:=bState;
           if bState then ButtonConfig:=ButtonConfig or btCheckSet
                     else ButtonConfig:=ButtonConfig and not btCheckSet;
         end;
         bufV^.r.Move(x+dx, y+dy);
         r.Union(bufV^.r);
         if dir in [Horiz,All] then inc(dx,Displaycement);
         if dir in [Vert,All] then inc(dy,Displaycement);
         bufV:=pointer(bufV^._down_);
         inc(count);
         if count=32 then begin
           { ??? procedura di errore ??? }
           exit;
         end;
       end;
       if PointVariable<>nil then PointVariable^:=InternalVariable;
     end;


   procedure OTCheckButtons.ExecMessage(var Message:TMessage);
     var bufV:OPCheckButton;
         count:byte;
         mask:longint;
     begin
       {SendMessage(Message);}
       bufV:=pointer(_gruppo_);
       count:=0;
       while (bufV<>nil)  and (bufV^.ID<>Message.HNDL) do begin
         bufV:=pointer(bufV^._down_);
         inc(count);
       end;
       mask:=1 shl count;
       if (bufV^.ButtonConfig and btInternalState)=0
       then
         InternalVariable:=InternalVariable and not mask
       else InternalVariable:=InternalVariable or mask;
       if PointVariable<>nil then PointVariable^:=InternalVariable;
     end;


   procedure OTCheckButtons.SetButtonStatus(ButtonNum:word; status:boolean);
     begin
     end;


                    { ----- OTRadioButtons ----- }
   constructor OTRadioButtons.Init(_ID:word; x,y:integer; variable:PWord; Displaycement:integer; dir:TDirection;
                                   objs:OPView);
     const btCheckState = btInternalState;
     var bufV:OPRadioButton;
         dx,dy:integer;
         count:word;
         startValue:word;
     begin
       r.assign(x,y,x,y);
       inherited InitComposite(_ID,r,objs);
       SysConfig:=Sysconfig or cfPostDraw;
       SysConfig:=Sysconfig and not cfDrawFatherRect;
       PointVariable:=variable;
       bufV:=pointer(_gruppo_);
       dx:=0;
       dy:=0;
       count:=0;
       if variable=nil then startValue:=1
                       else startValue:=variable^;
       InternalVariable:=0;
       while bufV<>nil do begin
         inc(count);
         bufV^.ID:=count;
         if ((count=startValue) or
            (bufV^._down_=nil)) and
            (InternalVariable=0)
         then begin
           with bufV^ do ButtonConfig:=ButtonConfig or btCheckState;
           InternalVariable:=count;
           ActiveButtonPointer:=bufV;
         end
         else with bufV^ do ButtonConfig:=ButtonConfig and not btCheckState;
         bufV^.r.Move(x+dx, y+dy);
         r.Union(bufV^.r);
         if dir in [Horiz,All] then inc(dx,Displaycement);
         if dir in [Vert,All] then inc(dy,Displaycement);
         bufV:=pointer(bufV^._down_);
       end;
       if PointVariable<>nil then PointVariable^:=InternalVariable;
     end;


   procedure OTRadioButtons.ExecMessage(var Message:TMessage);
     { Questa procedura viene chiamata da uno dei Radio Buttons
       tramite la procedura SendMessage.
       Il parametro Event contiene il numero del tasto che Š stato
       attivato. Conoscendo tale tasto la procedura provveder… a disattivare
       il precedente tasto attivo. }
     var bufV:OPView;
         i:word;
     begin
       case Message.Message of
         _SET_NEW_RADIO_BUTTON_: begin
              if Message.w1Reg=InternalVariable then exit;
              with ActiveButtonPointer^ do begin
                ButtonConfig:=ButtonConfig and not btInternalState;
                DrawRefreshListProc(
                  GetVisibleZone(ActiveButtonPointer,nil,NullObj),
                  ActiveButtonPointer,
                  GetVMP(typeOf(ActiveButtonPointer^),VMI_OTButton_Released),
                  nil,
                  ObjectNoParam
                );
              end;
              InternalVariable:=Message.w1Reg;
              bufV:=_gruppo_;
              {$IFDEF debugging}
              while (bufV^.ID<>Message.w1Reg) and (bufV^._down_<>nil) do bufV:=bufV^._down_;
              {$ELSE}
              if Message.w1Reg<>1 then for i:=2 to Message.w1Reg do bufV:=bufV^._down_;
              {$ENDIF}
              ActiveButtonPointer:=OPRadioButton(bufV);
              if PointVariable<>nil then PointVariable^:=InternalVariable;
              with ActiveButtonPointer^ do begin
                ButtonConfig:=ButtonConfig or btInternalState;
                DrawRefreshListProc(
                  GetVisibleZone(ActiveButtonPointer,nil,NullObj),
                  ActiveButtonPointer,
                  GetVMP(typeOf(ActiveButtonPointer^),VMI_OTButton_Pressed),
                  nil,
                  ObjectNoParam
                );
              end;
              SendMessage(Message);
            end;
       end;
     end;


   procedure OTRadioButtons.SetButtonStatus(ButtonNum:word; status:boolean);
     begin
     end;


                    { -----  OTCloseButton ----- }
   constructor OTCloseButton.Init(x,y:integer; attiv:boolean);
     var bmp1, bmp2: pointer;
     begin
       RegisterAll(_CHIUDI_FINESTRA_,x,y,attiv,@CloseBTN);
     end;


   procedure OTCloseButton.SpecialEffect_BeforeReaction;
     var toRect:OTRect;
         VisibleZone:PRefreshRectList;
         PtrPressed,
         PtrReleased:pointer;
     begin
       PtrPressed:=GetVMP(typeOf(Self),VMI_OTButton_Pressed);
       PtrReleased:=GetVMP(typeOf(Self),VMI_OTButton_Released);
       VisibleZone:=GetVisibleZone(@Self,nil,NullObj);
       hidemousecursor;
       DrawRefreshListProc(VisibleZone,@Self,PtrPressed,nil,ObjectNoParam);
       delay(20);
       DrawRefreshListProc(VisibleZone,@Self,PtrReleased,nil,ObjectNoParam);
       delay(10);
       DrawRefreshListProc(VisibleZone,@Self,PtrPressed,nil,ObjectNoParam);
       toRect.assign(  (r.x1+r.x2) div 2,  (r.y1+r.y2) div 2,
                       (r.x1+r.x2) div 2,  (r.y1+r.y2) div 2);
       showmousecursor;
       DisposeRefreshList(VisibleZone);
     end;






type Proc=procedure;

var _bmp_:pointer;
    precExitProc:pointer;


{$F+}
   procedure ExitBitmap;
     var i:TButtonStatus;
     begin
       for i:=StReleased to StDisable do begin
         DestroyDC(ZoomBTN[i]);
         DestroyDC(UnzoomBTN[i]);
         DestroyDC(ReduceBTN[i]);
         DestroyDC(CloseBTN[i]);
         DestroyDC(HelpBTN[i]);
       end;
       DestroyDC(OtherBTN_HCA);
       if precExitProc<>nil then Proc(precExitProc);
     end;
{$F-}


   procedure ErroreRisorse;
     begin
       restoreCRTMode;
       writeln('Errore BUTTONS.TPU: Il caricamento delle risorse Š fallito!');
       halt;
     end;



begin
  SetRESPtr(@Golib_RESOURCES,NumeroRisorse);
  (* Inizializzazione dei tasti Zoom *)
  GetButtonHCAs(ZoomBTN,ZoomButton_R,ZoomButton_P,ZoomButton_D);
  (* Inizializzazione dei tasti Unzoom *)
  GetButtonHCAs(UnzoomBTN,UnzoomButton_R,UnzoomButton_P,UnzoomButton_D);
  (* Inizializzazione dei tasti Reduce *)
  GetButtonHCAs(ReduceBTN,ReduceButton_R,ReduceButton_P,ReduceButton_D);
  (* Inizializzazione dei tasti Help *)
  GetButtonHCAs(HelpBTN,HelpButton_R,HelpButton_P,HelpButton_D);
  (* Inizializzazione dei tasti Close *)
  GetButtonHCAs(CloseBTN,CloseButton_R,CloseButton_P,CloseButton_D);

  (* Inizializzazione degli altri tipi di tasti *)
  if GetBMPResource_IDNum(@Golib_RESOURCES,NumeroRisorse,OtherButtons,_bmp_)=0 then ErroreRisorse;
  if CreateCompatibleArea(OtherBTN_HCA,_bmp_^)=nil then ErroreRisorse;


  {
    L'istruzione sottostante provoca un errore che manda in TILT il sistema.
    Questo errore si verifica solo con il programma demo "DM_LIB8.EXE" e
    la mancanza di questa istruzione genera un costo di 678 bytes occupati
    nello HEAP.
    E' probabile che ci sia un errore all'interno della procedura
    "CreateCompatibleArea". (vedi file CREATECA.ASM)
  }
  (* if _bmp_<>nil then DisposeBMP(_bmp_); *)

  precExitProc:=ExitProc;
  ExitProc:=@ExitBitmap;
end.