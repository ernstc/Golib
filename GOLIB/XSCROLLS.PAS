{ Ernesto CIANCIOTTA Productions }

{*************************************************************************}
{*                                                                       *}
{*  Modulo contenente gli oggetti scroller estesi della libreria         *}
{*  GOLIB 1.0.                                                           *}
{*                                                                       *}
{*  Scritto con Turbo Pascal 7.0                                         *}
{*                                                                       *}
{*************************************************************************}

{$D+}
{$L+}


UNIT XSCROLLS;


INTERFACE

  uses
        strings,
        codici,
        mouse,
        graph,
        graftool,
        fonts,
        bitmaps,
        golib_h,
        applic,
        golib9,
          dispfile,
        buttons,
        xlist,
        scrolls;


type
       OPXListViewer = ^OTXListViewer;
       OTXListViewer = object (OTView)
          constructor Init(_ID:word; x,y:integer; font:OPFont;
                           strBuffer:TStrBuffer;var numBuffer:word; List:OPXXList);
          procedure Disegna; virtual;
          procedure ExecMessage(var Message:TMessage); virtual;
          procedure AppendLines(Lines:OPXList);
          procedure DeleteAllLines;
          function DeleteLines(From,Count:word):word;
          {Ricalcola il proprio rettangolo. Deve essere chiamato quando la lista
           subisce delle modifiche dall'esterno.}
          procedure CalcRect;
          {Imposta la voce che deve essere visualizzata come selezionata. Imposta
           anche i valori dei buffers per la comunicazione. }
          procedure SetSelectedItem(n:word);
       private
       { buffers per la comunicazione con l'esterno }
          PtrNumBuffer:^Word;
          PtrStrBuffer:TStrBuffer;
       { altri campi privati }
          FontUsed:OPFont;
          _List_:OPXXList;
          SelectedLine:OPXList;
       end;


       OPXListBox = ^OTXListBox;
       OTXListBox = object (OTScrollBox)
          constructor Init(_ID:word;var coord:OTRect; font:OPFont;
                           strBuffer:TStrBuffer;var numBuffer:word; List:OPXXList);
          procedure ExecMessage(var Message:TMessage); virtual;
          procedure Refresh;
          procedure AppendLines(Lines:OPXList);
          procedure DeleteAllLines;
          function DeleteLines(From,Count:word):word;
          {Rinfresca il viewer. Deve essere chiamato quando la lista subisce
           delle modifiche dallesterno.}
          procedure RefreshViewer;
          {Rinfresca il viewer selezionando la linea indicata da N.}
          procedure RefreshListBox(n:word);
          {Seleziona automaticamente l' Nø elemento della lista.}
          procedure SelectItem(n:word);
       private
          ListViewer:OPXListViewer;
          StaticReaction:boolean;
          PrecFather:OPView;
       end;


       OPXPopUpField = ^OTXPopUpField;
       OTXPopUpField = object (OTView)
          constructor Init(_ID:word;var coord:OTRect; font:OPFont;
                           strBuffer:TStrBuffer;var numBuffer:word; List:OPXXList);
          destructor Done; virtual;
          procedure Adjust; virtual;
          procedure MoveRel(dx,dy:integer); virtual;
          procedure ExecMessage(var Message:TMessage); virtual;
          {Cambia la stringa del campo del pop-up con una stringa che non
           appartiene alla lista.}
          procedure ChangeString(Str:PChar);
          {Imposta la stringa del campo con il messaggio stringa dell'Nø
           elemento della lista.}
          procedure RefreshPopUp(n:word);
          {Seleziona automaticamente l' Nø elemento della lista.}
          procedure SelectItem(n:word);
       private
       { buffers per la comunicazione con l'esterno }
          PtrNumBuffer:^Word;
          PtrStrBuffer:TStrBuffer;
       { altri campi privati }
          FontUsed:OPFont;
          _List_:OPXXList;
          PullDown:OTButton;
          StrField:OTStrField;
          DownListBoxDir:boolean;
          procedure MakeListBoxRect(var rect:OTRect);
       end;



IMPLEMENTATION


   const
         { Buffer interno utilizzato da alcuni oggetti quando non li viene
           passato nessun buffer stringa. }
         BufferDiFuga:PChar=nil;



                        {----- OTXListViewer -----}
var
   __StaticReaction:boolean;

   constructor OTXListViewer.Init(_ID:word; x,y:integer; font:OPFont;
                                  strBuffer:TStrBuffer;var numBuffer:word; List:OPXXList);
     begin
       inherited Init(_ID,R);
       _List_:=List;
       with _List_^ do
         if _List_<>nil then R.SetRect(x,y,MaxXResolution,GetNumElements*_List_^.GetHeight)
                        else R.SetRect(x,y,MaxXResolution,-1);
       PtrNumBuffer:=@numBuffer;
       PtrStrBuffer:=strBuffer;
       FontUsed:=font;
       SelectedLine:=nil;
     end;


   procedure OTXListViewer.Disegna;
     var x,y:integer;
         Height:word;
         _Lines_,
         point:OPXList;
         numL:word;
         StringRect:OTRect;
         __Enable:boolean;
         SelectedIndex:word;
         { Variabili necessarie per l'ottimizzazione delle prestazioni di
           questo metodo. }
         view:ViewPortType;
         Drawing:boolean;
     begin
       SetFillStyle(1,15);
       with R do bar(x1,y1,x2,y2);
       _Lines_:=_List_^._List_;
       if _Lines_=nil then exit;
       GetViewSettings(view);
       _List_^.InitProperties;
       __Enable:=(SysConfig and cfEnable)<>0;
       SelectedIndex:=PtrNumBuffer^;
       Height:=_Lines_^.GetHeight;
       x:=R.x1+3;
       y:=R.y1;
       point:=_Lines_;
       if __Enable then TextColor:=0
                   else TextColor:=8;
       numL:=1;
       Drawing:=false;
       while point<>nil do begin
         if RefreshProcessing
           then with precR do StringRect.assign(x1,y-R.y1+y1,x2,y-R.y1+y1+Height)
           else with     R do StringRect.assign(x1,y,x2,y+Height);
         if StringRect.IntersectViewPort(view,StringRect) then begin
           Drawing:=true;
           if (numL=SelectedIndex) and __Enable then begin
             SetFillStyle(1,0);
             with R do bar(x1,y,x2,y+Height-1);
             point^.DrawElement(x,y,true);
           end
           else point^.DrawElement(x,y,false);
         end
         else if Drawing then exit;
         inc(y,Height);
         inc(numL);
         point:=point^.succ;
       end;
     end;


   procedure OTXListViewer.ExecMessage(var Message:TMessage);
     var PrecStrRect,
         StringRect         : OTRect;
         _Lines_,
         point              : OPXList;
         x,y                : integer;
         Height             : word;
         numL               : word;
         MinY,
         MaxY               : integer;
         PrecFather         : OPView;
         selected           : boolean;
         SelectedIndex      : word;
         Sinistra,Larghezza : integer;
         precStopESP        : boolean;

         Msg                : TMessage;

     begin
       case Message.Message of
         EvMOUSE_L_PRESSED: begin
            if ((SysConfig and cfEnable)=0) or (_List_^._List_=nil) then exit;

            Msg.HNDL:=ID;

            with _List_^ do begin
              InitProperties;
              _Lines_:=_List_;
            end;
            if _Father_<>nil
              then begin
                Sinistra:=_Father_^.R.x1;
                Larghezza:=_Father_^.R.DimX;
                if ListViewerPopUpMode then begin
                  PrecFather:=_Father_^._Father_^._Father_;
                  _Father_^._Father_^._Father_:=nil;
                end;
                MinY:=_Father_^.R.y1;
                MaxY:=_Father_^.R.y2;
              end
              else begin
                Sinistra:=0;
                Larghezza:=_MaxXResolution;
                MinY:=1;
                MaxY:=_MaxXResolution-1;
              end;
            Height:=_Lines_^.GetHeight;
            selected:=false;
            SelectedIndex:=PtrNumBuffer^;

            while __StaticReaction or
                  (PositionAndButtonStatus<>0) do begin
              if __StaticReaction then PositionAndButtonStatus;
              point:=_Lines_;
              x:=R.x1;
              y:=R.y1;
              numL:=1;
              while point<>nil do begin
                StringRect.SetRect(Sinistra,y,Larghezza,Height-1);
                if StringRect.XYIn(mcx,mcy) then begin
                  selected:=true;
                  SelectedLine:=point;
                  if numL=SelectedIndex then break;
                  PtrNumBuffer^:=numL;
                  hidemousecursor;
                  { Disattiva la voce precedente }
                  if SelectedIndex<>0 then begin
                    PrecStrRect.SetRect(x,R.y1+(SelectedIndex-1)*Height,R.DimX,Height);
                    SelectedIndex:=numL;
                    RefreshRect(PrecStrRect,@Self,GetVisibleZone(@Self,@PrecStrRect,NullObj));
                  end;
                  { Attivazione della nuova voce }
                  SelectedIndex:=numL;
                  RefreshRect(StringRect,@Self,GetVisibleZone(@Self,@StringRect,NullObj));
                  showmousecursor;
                  break;
                end;
                inc(y,Height);
                inc(numL);
                point:=point^.succ;
              end;
              if __StaticReaction and
                 selected         {and
                 (PositionAndButtonStatus<>0)}
              then break;
              precStopESP:=StopESP;
              if (mcy<MinY)
                then begin
                  if (mcx>=Sinistra) and (mcx<=Sinistra+Larghezza) then begin
                    Msg.Message:=_SCROLLBOX_V_INDIETRO_;
                    SendMessage(Msg);
                  end;
                end
                else begin
                  if (mcy>MaxY) then begin
                    if (mcx>=Sinistra) and (mcx<=Sinistra+Larghezza) then begin
                      Msg.Message:=_SCROLLBOX_V_AVANTI_;
                      SendMessage(Msg);
                    end;
                  end;
                end;
              StopESP:=precStopESP;
            end; {while}

            __StaticReaction:=false;
            if ListViewerPopUpMode then _Father_^._Father_^._Father_:=PrecFather;
            if selected then begin
              { Eventuale Reazione della linea }
              Msg.HNDL:=ID;
              Msg.Message:=EvMOUSE_L_PRESSED;
              SelectedLine^.ExecMessage(Msg);
              if PtrStrBuffer<>nil then begin
                StrDispose(PtrStrBuffer^);

                SelectedLine^.ExecMessage(Msg);
                if (Msg.HNDL=_X_TEXT_LINE_) and
                   (Msg.Message=_TEXT_LINE_)
                then begin
                  GetMem(PtrStrBuffer^,StrLen(PChar(Msg.ParametersPtr1))+1);
                  StrCopy(PtrStrBuffer^,PChar(Msg.ParametersPtr1));
                end;

              end;
              Msg.Message:=ID;
              SendMessage(Msg);
              {StopESP:=true;}
            end;
         end;
       end;
     end;


   procedure OTXListViewer.AppendLines(Lines:OPXList);
     begin
       if Lines=nil then exit;
       _List_^.AppendElement(Lines);
       with R do begin
         with _List_^ do DimY:=GetNumElements*_List_^.GetHeight;
         y2:=y1+DimY;
       end;
       if lookvideo then RefreshRect(R,@Self,GetVisibleZone(@Self,nil,NullObj));
     end;


   procedure OTXListViewer.DeleteAllLines;
     begin
       _List_^.DeleteAllElements;
       with R do begin
         DimY:=0;
         y2:=y1;
       end;
       { Refresh }
       if lookvideo then RefreshRect(R,@Self,GetVisibleZone(@Self,nil,NullObj));
     end;


   function OTXListViewer.DeleteLines(From,Count:word):word;
     begin
       DeleteLines:=_List_^.DeleteElements(From,Count);
       with R do begin
         with _List_^ do
           if _List_<>nil then DimY:=GetNumElements*_List_^.GetHeight
                          else DimY:=0;
         y2:=y1+DimY;
       end;
       { Refresh }
       if lookvideo then RefreshRect(R,@Self,GetVisibleZone(@Self,nil,NullObj));
     end;


   procedure OTXListViewer.CalcRect;
   {$IFDEF debugging}
     var p1,p2:word;
   {$ENDIF}
     begin
       if _List_<>nil then
         with R do begin
           with _List_^ do
             if _List_<>nil then begin
             {$IFDEF debugging}
               p1:=GetNumElements;
               p2:=_List_^.GetHeight;
             {$ENDIF}
               DimY:=GetNumElements*_List_^.GetHeight
             end
             else DimY:=0;
           y2:=y1+DimY;
         end;
     end;


   procedure OTXListViewer.SetSelectedItem(n:word);
     var l:word;
         point:OPXList;
         MStr:string;
         Msg:TMessage;
     begin
       {if n=PtrNumBuffer^ then exit;}
       if (_List_^._List_=nil) or (n=0) then begin
         PtrNumBuffer^:=0;
         if PtrStrBuffer<>nil then begin
           StrDispose(PtrStrBuffer^);
           PtrStrBuffer^:=nil;
         end;
       end
       else begin
         l:=_List_^.GetNumElements;
         if n>l then n:=l;
         PtrNumBuffer^:=n;
         if PtrStrBuffer<>nil then begin
           l:=n;
           point:=_List_^._List_;
           while (point<>nil) and (l<>1) do begin
             dec(l);
             point:=point^.succ;
           end;
           StrDispose(PtrStrBuffer^);

           point^.ExecMessage(Msg);
           if (Msg.HNDL=_X_TEXT_LINE_) and
              (Msg.Message=_TEXT_LINE_) then begin
             GetMem(PtrStrBuffer^,StrLen(PChar(Msg.ParametersPtr1))+1);
             StrCopy(PtrStrBuffer^,PChar(Msg.ParametersPtr1));
           end;

         end;
       end;
       Refresh;
     end;


                        {----- OTXListBox -----}
   constructor OTXListBox.Init(_ID:word;var coord:OTRect; font:OPFont;
                               strBuffer:TStrBuffer;var numBuffer:word; List:OPXXList);
     var lk:boolean;
         i:word;
         Msg:TMessage;
     begin
       if List=nil then begin
         fail;
         exit;
       end;
       lk:=lookvideo;
       lookvideo:=false;
       { ListViewer deve essere impostato a nil perchŠ durante l'inizializzazione
         viene chiamata la procedura Adjust che opera su ListViewer. }
       ListViewer:=nil;
       if not inherited Init(_ID,coord,Vert) then fail;
       StaticReaction:=false;
       PrecFather:=nil;
       if List^._List_<>nil then
         ScrollerV^.Step:=List^._List_^.GetHeight;
       new(ListViewer, Init(_LIST_VIEWER_,0,0,font,strBuffer,numBuffer,List));
       AddObject(ListViewer);
       Msg.HNDL:=ID;
       Msg.Message:=_SCROLL_AVANTI_;
       with ScrollerV^ do
         if numBuffer>1
           then for i:=2 to numBuffer do {
                  if (LastBtn.SysConfig and cfEnable)<>0 then} ExecMessage(Msg);
       StopESP:=false;
       lookvideo:=lk;
     end;


   procedure OTXListBox.ExecMessage(var Message:TMessage);
     var Msg:TMessage;
     begin
       Msg.HNDL:=ID;
       case Message.Message of
         EvMOUSE_L_PRESSED: begin
           if StaticReaction and (PrecFather=nil) then begin
             PrecFather:=_Father_;
             _Father_:=nil;
           end;
         end;
         _LIST_VIEWER_: begin
           if StaticReaction        and
              ((SysConfig and cfOnDesktop)<>0)
           then begin
             if PrecFather<>nil then begin
               Msg.Message:=_LIST_VIEWER_;
               PrecFather^.ExecMessage(Msg);
             end;
             StopESP:=true;
             PopUpMode:=false;
             { Autodistruzione }
             if seg(self)<>DSeg then dispose(OPXListBox(@self),Done)
                                else Done;
           end;
         end
         else begin
           inherited ExecMessage(Message);
           if Message.Message=_LIST_VIEWER_ then begin
             Msg.Message:=ID;
             SendMessage(Msg);
           end;
         end;
       end;
     end;


   procedure OTXListBox.Refresh;
     begin
       if lookvideo then begin
         hidemousecursor;
         ScrollerV^.Refresh;
         RefreshRect(NullRect,ListViewer,GetVisibleZone(ListViewer,@R,NullObj));
         showmousecursor;
       end;
     end;


   procedure OTXListBox.AppendLines(Lines:OPXList);
     begin
       ListViewer^.AppendLines(Lines);
     end;


   procedure OTXListBox.DeleteAllLines;
     begin
       ListViewer^.DeleteAllLines;
     end;


   function OTXListBox.DeleteLines(From,Count:word):word;
     begin
       ListViewer^.DeleteLines(From,Count);
     end;


   procedure OTXListBox.RefreshViewer;
     begin
       with ListViewer^ do begin
         CalcRect;
         Refresh;
       end;
     end;


   procedure OTXListBox.RefreshListBox(n:word);
     var h:word;
         lk:boolean;
     begin
       lk:=lookvideo;
       lookvideo:=false;
       with ListViewer^ do begin
         if _List_^._List_ <>nil then h:=_List_^._List_^.GetHeight
                                 else h:=0;
         CalcRect;
         ScrollerV^.SetVirtualDim(R.DimY);
         SetSelectedItem(n);
       end;
       SetCursorPosition(0,h*(n-1));
       lookvideo:=lk;
       Refresh;
     end;


   procedure OTXListBox.SelectItem(n:word);
     var Msg:TMessage;
     begin
       RefreshListBox(n);
       Msg.HNDL:=ID;
       Msg.Message:=ID;
       SendMessage(Msg);
     end;


                       {----- OTXPopUpField -----}
   constructor OTXPopUpField.Init(_ID:word;var coord:OTRect; font:OPFont;
                                  strBuffer:TStrBuffer;var numBuffer:word; List:OPXXList);
     var str:PChar;
         rect:OTRect;
         lk:boolean;
         buf:OPXList;
         i:word;
         Msg:TMessage;

     begin
       lk:=lookvideo;
       lookvideo:=false;
       if not inherited Init(_ID,coord) then fail;
       PtrNumBuffer:=@numBuffer;
       PtrStrBuffer:=strBuffer;
       SysConfig:=cfPopUpField;
       FontUsed:=font;
       _List_:=List;
       if _List_^._List_=nil
         then begin
           str:='';
           numBuffer:=0;
         end
         else begin
           if numBuffer<2
             then begin
               _List_^._List_^.ExecMessage(Msg);
               if (Msg.HNDL=_X_TEXT_LINE_) and
                  (Msg.Message=_TEXT_LINE_) then begin
                 str:=PChar(Msg.ParametersPtr1);
               end
               else str:=nil;
             end
             else begin
               buf:=_List_^._List_;
               for i:=2 to numBuffer do
                 if buf^.succ<>nil then buf:=buf^.succ
                                   else break;
               buf^.ExecMessage(Msg);
               if (Msg.HNDL=_X_TEXT_LINE_) and
                  (Msg.Message=_TEXT_LINE_) then begin
                 str:=PChar(Msg.ParametersPtr1);
               end
               else str:=nil;

               numBuffer:=i;
             end;
         end;
       if PtrStrBuffer<>nil then begin
         if str<>nil then begin
           StrDispose(PtrStrBuffer^);
           GetMem(PtrStrBuffer^,StrLen(str)+1);
           StrCopy(PtrStrBuffer^,str);
         end;
       end
       else PtrStrBuffer:=@BufferDiFuga;
       SysConfig:=cfPopUpField;
       _gruppo_:=@PullDown;
       with coord do rect.SetRect(x1,y1,DimX,24);
       with PullDown do begin
         RegisterAll(_PULL_DOWN_,rect.x2-19,rect.y1+2,true,@PullDown1BTN);
         ButtonConfig:=ButtonConfig or btReactionInRealTime;
       end;
       StrField.Init(_STRING_FIELD_,rect,font,PtrStrBuffer^);
       { Collega i vari elementi che compongono l'oggetto }
       PullDown.LinkTo(@StrField);
       PullDown._Father_:=@Self;
       StrField._Father_:=@Self;
       lookvideo:=lk;
     end;


   destructor OTXPopUpField.Done;
     begin
       DestroySubList;
       inherited Done;
     end;


   procedure OTXPopUpField.Adjust;
     var rect:OTRect;
         ListBoxRect:OTRect;
         lk,f:boolean;
         Msg:TMessage;
     begin
       with R do
         if DimY<100 then begin
           DimY:=100;
           y2:=y1+100;
         end;
       with R do rect.SetRect(x1,y1,DimX,24);
       StrField.Resize(rect);
       PullDown.Move(rect.x2-19,rect.y1+2);
       f:=DownListBoxDir;
       MakeListBoxRect(ListBoxRect);
       if DownListBoxDir<>f then begin
         lk:=lookvideo;
         lookvideo:=false;
         if DownListBoxDir then PullDown.PerformButton(__PullDown1BTN)
                           else PullDown.PerformButton(__PullDown2BTN);
         lookvideo:=lk;
         Msg.Message:=SYS_REFRESH_OBJ;
         Msg.long2Reg:=longint(@Self);
         AllocMessage(Msg);
       end;
     end;


   procedure OTXPopUpField.MoveRel(dx,dy:integer);
     var ListBoxRect:OTRect;
         lk,f:boolean;
         bufR:OTRect;
         Msg:TMessage;
     begin
       if (dx=0) and (dy=0) then exit;
       bufR:=R;
       R.MoveRel(dx,dy);
       f:=DownListBoxDir;
       MakeListBoxRect(ListBoxRect);
       R:=bufR;
       inherited MoveRel(dx,dy);
       if DownListBoxDir<>f then begin
         lk:=lookvideo;
         lookvideo:=false;
         if DownListBoxDir then PullDown.PerformButton(__PullDown1BTN)
                           else PullDown.PerformButton(__PullDown2BTN);
         lookvideo:=lk;
         Msg.Message:=SYS_REFRESH_OBJ;
         Msg.long2Reg:=longint(@Self);
         AllocMessage(Msg);
       end;
     end;


   procedure OTXPopUpField.ExecMessage(var Message:TMessage);
     var ListBox:OPXListBox;
         ListBoxRect:OTRect;
         f:boolean;
         Msg:TMessage;
     begin
       case Message.Message of
         _STRING_FIELD_,
         _PULL_DOWN_: begin
             MakeListBoxRect(ListBoxRect);
             new(ListBox, Init(Null_ID,ListBoxRect,FontUsed,PtrStrBuffer,PtrNumBuffer^,_List_));
             f:=ListViewerPopUpMode;
             ListViewerPopUpMode:=true;
             with ListBox^ do begin
               _Father_:=@Self;
               SysConfig:=SysConfig or cfAlwaysAsFirst;
               PutOnDesktop;
               while (PositionAndButtonStatus<>0) and
                     ((mcy<=PullDown.R.y2+4) or
                      (_List_^._List_=nil))
               do;
               StaticReaction:=PositionAndButtonStatus=0;
               __StaticReaction:=StaticReaction;
               if not StaticReaction then begin
                 Msg.Message:=EvMOUSE_L_PRESSED;
                 ListViewer^.ExecMessage(Msg);
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
             Msg.HNDL:=ID;
             Msg.Message:=ID;
             SendMessage(Msg);
         end;
       end;
     end;


   procedure OTXPopUpField.ChangeString(Str:PChar);
     var Msg:TMessage;
     begin
       PtrNumBuffer^:=0;
       StrDispose(PtrStrBuffer^);
       PtrStrBuffer^:=StrNew(Str);
       StrField.Refresh;
       Msg.HNDL:=ID;
       Msg.Message:=ID;
       SendMessage(Msg);
     end;


   procedure OTXPopUpField.RefreshPopUp(n:word);
     var str:PChar;
         i,lim:word;
         buf:OPXList;
         Msg:TMessage;
     begin
       if _List_^._List_=nil
         then begin
           str:='';
           n:=0;
         end
         else begin
           if n=1
             then begin
               _List_^._List_^.ExecMessage(Msg);
               if (Msg.HNDL=_X_TEXT_LINE_) and
                  (Msg.Message=_TEXT_LINE_) then begin
                 str:=PChar(Msg.ParametersPtr1);
               end
               else str:=nil;
             end
             else begin
               buf:=_List_^._List_;
               lim:=_List_^.GetNumElements;
               if n>lim then n:=lim;
               for i:=2 to n do buf:=buf^.succ;
               buf^.ExecMessage(Msg);
               if (Msg.HNDL=_X_TEXT_LINE_) and
                  (Msg.Message=_TEXT_LINE_) then begin
                 str:=PChar(Msg.ParametersPtr1);
               end
               else str:=nil;
             end;
         end;
       PtrNumBuffer^:=n;
       StrDispose(PtrStrBuffer^);
       GetMem(PtrStrBuffer^,StrLen(str)+1);
       StrCopy(PtrStrBuffer^,str);
       StrField.Refresh;
     end;


   procedure OTXPopUpField.SelectItem(n:word);
     var Msg:TMessage;
     begin
       RefreshPopUp(n);
       Msg.HNDL:=ID;
       Msg.Message:=ID;
       SendMessage(Msg);
     end;


   procedure OTXPopUpField.MakeListBoxRect(var rect:OTRect);
     const Limite=40;
     var limY:word;
     begin
       with _List_^ do
         if _List_<>nil then limY:=GetNumElements*_List_^.GetHeight+4
                        else limY:=Limite;
       if limY<Limite then limY:=Limite;
       with R do Rect.assign(x1,y1+26,x2,y2);
       with Rect do begin
         if DimY>limY then begin
           DimY:=limY;
           y2:=y1+DimY;
         end;
         if x2>_MaxXResolution then begin
           x2:=_MaxXResolution;
           x1:=x2-DimX;
         end;
         if x1<0 then begin
           x1:=0;
           x2:=x1+DimX;
         end;
         if y2>_MaxYResolution then begin
           y2:=R.y1-2;
           y1:=y2-DimY;
           DownListBoxDir:=false;
         end
         else DownListBoxDir:=true;
         if y1<0 then begin
           if DimY>_MaxYResolution then begin
             y1:=0;
             y2:=y1+DimY;
             DownListBoxDir:=true;
           end
           else begin
             y2:=_MaxYResolution;
             y1:=y2-DimY;
             DownListBoxDir:=false;
           end;
         end;
       end;
     end;

                {****** Fine del codice degli oggetti ******}


END.