procedure Cursor;
  var ch:char;
      DimX:word;


  function NoEvent:boolean;
    begin
      if PositionAndButtonStatus<>0 then begin
        Event:=EvMouse;
        NoEvent:=false;
      end
      else if keypressed then begin
        Event:=EvKeyBoard;
        NoEvent:=false;
      end
      else begin
        Event:=EvNothing;
        NoEvent:=true xor PersistentCursor;
      end;
      if PersistentCursor and (Event=EvMouse) then begin
        Event:=EvNothing;
        NoEvent:=true;
      end
    end;


  procedure DrawCursor;
    var ris:ViewPortType;
        MouseIntersectCursor:boolean;
        {__mcx,}__mcy:integer;
    begin
      if MousePresent then begin
        PositionAndButtonStatus;
        {__mcx:=mcx-_HotX_;}
        __mcy:=mcy-_HotY_;
        {if __mcx>=CurX then Ris.x1:=__mcx
                       else Ris.x1:=CurX;}
        if __mcy>=CurY then Ris.y1:=__mcy
                       else Ris.y1:=CurY;
        {if __mcx+16<CurX+DimX then Ris.x2:=__mcx+16
                              else Ris.x2:=CurX+DimX;}
        if __mcy+16<CurY+CurHeight then Ris.y2:=__mcy+16
                                   else Ris.y2:=CurY+CurHeight;
        with Ris do if {(x2<x1) or} (y2<y1) then MouseIntersectCursor:=false
                                            else MouseIntersectCursor:=true;
      end
      else
        MouseIntersectCursor:=false;
      if MouseIntersectCursor then hidemousecursor;
      if InsMode then begin
        line(CurX,CurY,CurX,CurY+CurHeight-1);
        line(CurX+1,CurY,CurX+1,CurY+CurHeight-1);
      end
      else begin
        line(CurX,CurY+CurHeight-2,CurX+DimX,CurY+CurHeight-2);
        line(CurX,CurY+CurHeight-1,CurX+DimX,CurY+CurHeight-1);
      end;
      if MouseIntersectCursor then showmousecursor;
    end;


  { N.B.: Questo potrebbe funzionare sullo stesso principio dello "Scheduler"
          negli ambienti multitasking preempitive. }

  procedure WaitCursor;
    begin
      TimerCounter:=0;
      GetIntVec($1C,Int1CSave);
      SetIntVec($1C,Addr(TimerHandler));
      while NoEvent and (TimerCounter/18.2<WaitTime) do;
      SetIntVec($1C,Int1CSave);
    end;



  begin  { Cursor }
    if not InsMode then begin
      if XStringPresent and (ChIndex<=DimXString)
        then ch:=XString^[ChIndex]
        else ch:=chr(ActiveFont^.Font^.Header.Break);
      if ch=#0 then ch:=#32;
      DimX:=ActiveFont^.TextLength(ch,0,0);
    end
    else DimX:=15;
    SetWriteMode(XorPut);
    SetColor(15);
    Event:=EvNothing;
    {if InsMode then begin
      line(CurX+2,CurY+CurHeight-1,CurX+DimX,CurY+CurHeight-1);
      line(CurX+2,CurY+CurHeight,CurX+DimX,CurY+CurHeight);
    end;}
    while Event=EvNothing do begin
      { Disegna il cursore }
      DrawCursor;
      { Pausa }
      WaitCursor;
      { Cancella il cursore }
      DrawCursor;
      { Pausa }
      if Event=EvNothing then WaitCursor;
      if PersistentCursor and not NoEvent then break;
    end; {while}
    {if InsMode then begin
      line(CurX+2,CurY+CurHeight-1,CurX+DimX,CurY+CurHeight-1);
      line(CurX+2,CurY+CurHeight,CurX+DimX,CurY+CurHeight);
    end;}
    SetWriteMode(NormalPut);
  end;




procedure EditorShutDown;
  begin
    if XStringPresent then FreeMem(XString,MemXString);
    shutdown;
  end;




{ Inserisce una nuova linea sopra CurrentLine }
procedure InsertLine;
  var l:PLine;
  begin
    new(l);
    with l^ do begin
      TextLine:=nil;
      prec:=CurrentLine^.prec;
      succ:=CurrentLine;
      if prec<>nil then prec^.succ:=l
                   else Text:=l;
    end;
    CurrentLine^.prec:=l;
  end;



{ Inserisce una nuova linea sotto CurrentLine e imposta CurrentLine sulla
  nuova linea. }
procedure NewLine;
  var l:PLine;
  begin
    new(l);
    with l^ do begin
      TextLine:=nil;
      succ:=CurrentLine^.succ;
      prec:=CurrentLine;
      if succ<>nil then succ^.prec:=l
                   else LastLine:=l;
    end;
    CurrentLine^.succ:=l;
    CurrentLine:=l;
  end;




procedure AppendLine;
  begin
    new(LastLine^.succ);
    LastLine^.succ^.prec:=LastLine;
    LastLine:=LastLine^.succ;
    with LastLine^ do begin
      TextLine:=nil;
      succ:=nil;
    end;
  end;




{ Ridimensiona un blocco di memoria allocato con GetMem. }
procedure ResizeMemBlock(var p:pointer; SizeBlock,NewSize:longint);
  var precPoint:pointer;
      lessSize:word;
      i:byte;
  begin
    if p=nil then begin
      GetMem(p,NewSize);
      exit;
    end;
    precPoint:=p;
    { Salva in RzSave }
    asm
      push      ds
      cld
      mov       ax,ds
      mov       es,ax
      lea       di,RzSave
      lds       si,p
      lds       si,DWORD PTR ds:[si]
      mov       cx,8
      rep       movsb
      pop       ds
    end;
    FreeMem(p,SizeBlock);
    GetMem(p,NewSize);
    if precPoint=p then begin
      { In questo caso Š stata utilizzata la stessa partizione per
        la rilocazione. }
      asm
        cld
        { Ripristina con RzSave }
        lea       si,RzSave
        les       di,p
        les       di,DWORD PTR es:[di]
        mov       cx,8
        rep       movsb
      end;
    end
    else begin
      { In questo caso Š stata utilizzata una partizione diversa per
        la rilocazione e quindi il blocco precedente ed il nuovo blocco
        non hanno nessun byte in comune. }
      if SizeBlock<NewSize then LessSize:=SizeBlock
                           else LessSize:=NewSize;
      asm
        add       LessSize,7
        and       LessSize,0FFF8h    { (LessSize div 8) *8 }
        cld
        { Copia la i primi 8 bytes del blocco da RzSave }
        lea       si,RzSave
        les       di,p
        les       di,DWORD PTR es:[di]
        mov       cx,8
        sub       LessSize,8
        mov       bx,cx
        rep       movsb
        cmp       LessSize,0
        je        @Fine
        { Copia il resto del blocco da precPoint }
        push      ds
        lds       si,precPoint
        add       si,bx
        mov       cx,LessSize
        rep       movsb
        pop       ds
      @Fine:
      end;
    end;
  end;




procedure SeparateLines;
  var
      precPoint:pointer;
      _DX_:word;
      txLen:word;
      Save:TSave;
      ch:char;
      _line_:PChar;
      x1:integer;


  procedure Separa(var startLine:pointer; Length {Lunghezza della linea}:word; DimLine {Memoria occupata dalla linea}:longint);


    procedure Mode1; assembler;
            (*
                 (Seg(_line_^) = Seg(precPoint^)) AND
                 (Ofs(_line_^) < Ofs(precPoint^)+DX)
            *)
    asm
      { In BX viene messo il numero di caratteri da copiare }
      mov       bx,ss:[bp+42] {txLen}
      { Numero di caratteri da prendere da RzSave }
      mov       cx,ss:[bp+44] {_DX_}
      sub       cx,ChIndex
      inc       cx
      cmp       BYTE PTR ss:[bp+44],8 {_DX_}
      jbe       @002
      xor       cx,cx
    @002:
      { Carica SI }
      lea       si,RzSave
      add       si,8
      sub       si,cx
      les       di,ss:[bp+28] {_line_}
      push      di
      sub       bx,cx
      jns       @001
      xor       bx,bx
    @001:
      cld
      rep       movsb
      cmp       bx,0
      je        @Fine
      push      ds
      mov       dx,ChIndex
      cmp       dx,8
      ja        @003
      mov       dx,8
      jmp       @004
    @003:
      dec       dx
    @004:
      lds       si,ss:[bp+46] {precPoint}
      add       si,dx
      mov       cx,bx
      rep       movsb
      pop       ds
    @Fine:
      pop       di
      mov       al,ss:[bp+33] {ch}
      mov       es:[di],al
    end;


    procedure Mode2; assembler;
            (*
                 (Seg(_line_^) = Seg(precPoint^)) AND
                 (Ofs(_line_^) > Ofs(precPoint^)+DX)
            *)
    asm
    end;


    begin
      txLen:=Length-ChIndex+2;
      precPoint:=startLine;
    { AffinchŠ l'operazione abbia successo Š necessario salvare gli 8 bytes
      che seguono il blocco di memoria "startLine" che contiene la prima
      parte della parola.
      L'offset del primo byte da salvare Š:

        ofs(startLine)+(ChIndex+7) div 8 * 8

      E' importante notare che ogni blocco di memoria ha una dimensione di 8
      o di un multiplo di 8, cossichŠ se la prima parte della parola occupa
      9 bytes, bisogner… salvare gli 8 bytes che seguono i primi 16 bytes
      di "startLine" che rappresentano proprio il blocco di memoria dedicato
      per la prima parola. Infatti solo gli 8 bytes che verranno salvati
      potrebbero subire una mofica dopo la chiamata alla procedura
      ResizeMemBlock.
    }
      asm
        push      ds
        mov       dx,ChIndex
    { Salva in Save }
        cld
        lds       si,startLine
        lds       si,DWORD PTR ds:[si]
        mov       bx,si
        add       si,dx
        add       si,7
        and       si,0FFF8h    { (SI div 8) *8 }
        mov       ax,ss
        mov       es,ax
        { Carica l'offset di Save }
        mov       di,bp
        add       di,28  {Save}
        mov       cx,8
        rep       movsb
        mov       si,dx
        mov       al,BYTE PTR ds:[si+bx-1]
        mov       ss:[bp+27],al {ch}
        mov       BYTE PTR ds:[si+bx-1],0
        pop       ds
      end;
      { Rimpicciolisce il blocco di memoria }
      ResizeMemBlock(pointer(startLine),DimLine,ChIndex);
      CurrentLine^.TextLine:=pointer(startLine);
      if XStringPresent then begin
        { Calcolo della dimensione del buffer }
        MemXString:=MaxAvail;
        if MemXString>65520 then MemXString:=65520;
        MemXString:=MemXString div RapportoMemAvail;
        GetMem(_line_,MemXString);
        DimXString:=txLen-1;
      end
      else GetMem(_line_,txLen);
      { Separazione della linea }
      asm
      end;

      _DX_:=(ChIndex+7) and $FFF8;

      if startLine<>precPoint then begin
        if Seg(_line_^) = Seg(precPoint^)
        then begin
          if Ofs(_line_^) < Ofs(precPoint^)+_DX_ then Mode1
          else if Ofs(_line_^) > Ofs(precPoint^)+_DX_ then Mode2;
        end
        else Mode1;
      end
      else asm
    { Imposta il flag di direzione per una copia inversa della linea. Questo
      perchŠ la nuova linea pu• trovarsi sovrapposta alla vecchia per alcuni
      bytes e una copia diretta darebbe dei risultati errati. }
        push      ds
        std
        { BX Š il registro che contiene il numero di caratteri che rimangono
          da copiare }
        mov       bx,ss:[bp+36] {txLen}
        les       di,ss:[bp+22] {_line_}
        add       di,bx
        dec       di
        { Nel codice che comincia da qui e che finisce alla fine della prima
          parte, viene impostato in DX il displacement da applicare a CX nella
          seconda parte. Questo displacement Š necessario per i casi in cui la
          fine di _line_ Š contenuta in Save e non in precPoint. }
        { DX = (ChIndex+7) div 8 * 8   -> Dimensione della memoria occupata da _line_ }
        mov       dx,ChIndex
        add       dx,7
        and       dx,0FFF8h    { (DX div 8) *8 }
        { Mette in CX il numero della prima serie di caratteri che devono essere
          presi da startLine }
        mov       cx,Length
        cmp       dx,Length
        jae       @TerzaParte
        sub       cx,dx
        sub       cx,7
        jns       @001
        not       cx
        inc       cx
        { Assegna il displacement a DX }
        mov       dx,cx
        xor       cx,cx
        jmp       @003
    @001:
        jnz       @003
        xor       dx,dx
    @003:
        cmp       cx,0
        je        @SecondaParte
        { Azzera il displacement per CX nella seconda parte }
        xor       dx,dx
        { Carica registri per la copia con precPoint }
        lds       si,startLine
        lds       si,DWORD PTR ds:[si]
        add       si,Length
        sub       bx,cx
        rep       movsb

    @SecondaParte:
        { Carica i registri per la copia da Save }
        mov       ax,ss
        mov       ds,ax
        { Carica l'offset di Save }
        mov       si,bp
        add       si,28  {Save}
        mov       cx,8
        sub       cx,dx
        sub       bx,cx
        add       si,cx
        dec       si
        rep       movsb

    @TerzaParte:
        { Carica registri per la copia con startLine }
        dec       bx
        mov       cx,bx
        pop       ds
        mov       dx,ChIndex
        push      ds
        lds       si,startLine
        lds       si,DWORD PTR ds:[si]
        add       si,dx
        add       si,bx
        dec       si
        rep       movsb
        mov       al,ss:[bp+27] {ch}
        stosb
        pop       ds
      end;
      x1:=ActiveFont^.__TextLength(startLine,0,0);
      {**** Debugging delle stringhe generate ****}
      bar(0,455,639,479);
      setcolor(0);
      line(0,455,639,455);
      cour.__DrawText(5,460,TextLeft,startLine);
      cour.__DrawText(634,460,TextRight,_line_);
      ActiveFont^.Select;
      {*******************************************}
    end;

  begin { SeparateLines }
    if XStringPresent then begin
      XString^[DimXString+1]:=#0;
      Separa(pointer(XString),DimXString,MemXString);
    end
    else with CurrentLine^ do begin
      txLen:=StrLen(TextLine);

      Separa(pointer(TextLine),txLen,txLen+1);
    end;
    NewLine;
    if XStringPresent then begin
      XString:=pointer(_line_);
      CurrentLine^.TextLine:=@LineEditing;
    end
    else CurrentLine^.TextLine:=_line_;
    if NumActiveLine<NumLines then begin
      BitBtlVideoDC(0,CurY+Interlinea,0,CurY+Interlinea*2,
                    _MaxXResolution,Interlinea*(NumLines-NumActiveLine));
      bar(0,CurY+Interlinea,_MaxXResolution,CurY+Interlinea*2);
    end;
    txLen:=ActiveFont^.__TextLength(PChar(_line_),0,0);
    BitBtlVideoDC(x1,CurY,0,CurY+Interlinea,txLen,Interlinea);
    bar(x1,CurY,x1+txLen,CurY+Interlinea);
  end;




procedure KeyController; forward;

procedure MouseController; forward;







procedure GoToChar(x:word);
  var ChInd,
      DimX, DimX2, displacement, CX: word;
  begin
    ChInd:=ChIndex;
    CX:=CurX;
    if (ActiveFont^.Font^.Header.Proportional and $01) <> 0 then begin
      { Carattere proporzionale }
      if x<>CX then begin
        DimX:=ActiveFont^.TextLength(XString^[ChInd],0,0);
        if x>CX then begin
          if InsMode then displacement:=(DimX+1) div 2
                     else displacement:=DimX;
          while (x >= CX+displacement) and (ChInd<=DimXString) do begin
            inc(CX,DimX);
            inc(ChInd);
            if ChInd>DimXString then break;
            DimX:=ActiveFont^.TextLength(XString^[ChInd],0,0);
            if InsMode then displacement:=DimX div 2
                       else displacement:=DimX;
          end;
        end
        else begin
          { Ricerca verso sinistra }
          if ChInd>1 then begin
            DimX2:=ActiveFont^.TextLength(XString^[ChInd-1],0,0);
            if InsMode then displacement:=DimX2 div 2
                       else displacement:=0;
          end
          else displacement:=0;
          while (x < CX-displacement) and (ChInd>1) do begin
            dec(ChInd);
            DimX:=ActiveFont^.TextLength(XString^[ChInd],0,0);
            if ChInd>1 then begin
              DimX2:=ActiveFont^.TextLength(XString^[ChInd-1],0,0);
              if InsMode then displacement:=DimX2 div 2
                         else displacement:=0;
            end
            else displacement:=0;
            dec(CX,DimX);
          end;
        end;
      end;
    end
    else begin
      { Carattere non proporzionale }
      if x<>CX then begin
        DimX:=ActiveFont^.Font^.Header.Width;
        if x>CX then begin
          { Ricerca verso destra }
          if InsMode then displacement:=DimX div 2
                     else displacement:=DimX;
          while (x-displacement>CX) and (ChInd<=DimXString) do begin
            inc(CX,DimX);
            inc(ChInd);
            if ChInd>DimXString then break;
          end;
        end
        else begin
          { Ricerca verso sinistra }
          if InsMode then displacement:=DimX div 2
                     else displacement:=0;
          while (x+displacement<CX) and (ChInd>1) do begin
            dec(ChInd);
            dec(CX,DimX);
          end;
        end;
      end;
    end;
    CurX:=CX;
    ChIndex:=ChInd;
  end;


{ Si posiziona sulla linea specificata. Se allineaX=TRUE allora in cursore
  sar… posizionato sul carattere della nuova linea che Š puntato da CurX,
  altrimenti sar… posizionato all'inizio della nuova linea. }
procedure GoToLine(numLine:word; allineaX:boolean);
  var SearchLine:PLine;
      x:word;
  begin
    if numLine<1 then numLine:=1
                 else if numLine>NumLines then numLine:=NumLines;
    if numLine<>NumActiveLine then begin
      SearchLine:=CurrentLine;
      CurY:=CurY+(numLine-NumActiveLine)*Interlinea;
      if numLine>NumActiveLine then
        { Ricerca verso il basso }
        for NumActiveLine:=NumActiveLine+1 to numLine do SearchLine:=SearchLine^.succ
      else
        { Ricerca verso l'alto }
        for NumActiveLine:=NumActiveLine-1 downto numLine do SearchLine:=SearchLine^.prec;
      XString_ASCIIZ;
      CurrentLine:=SearchLine;
      ASCIIZ_XString;
      ChIndex:=1;
      x:=CurX;
      CurX:=0; { CurX viene impostato a 0 anche per attivare la ricerca del carattere
                 da sinistra a destra, oltre che posizionare il carattere all'inizio
                 della linea se allineaX=FALSE }
      if allineaX then GotoChar(x);
    end;
  end;



{ Date le coordinate (x,y) vengono determinate le coordinate (CurX,CurY) e
  viene selezionato il carattere corrispondente. }
procedure FindChar(x,y:integer);
  var SearchLine:PLine;
      CX,CY:integer;
      NumLine,ChInd,DimX,DimX2:word;
      displacement:integer;
  begin
    { Ricerca della linea puntata dal cursore }
    SearchLine:=CurrentLine;
    CY:=CurY;
    NumLine:=NumActiveLine;
    if y<>CY then begin
      if y>CY then begin
        { Ricerca verso il basso }
        while (y-Interlinea+1>CY) and (SearchLine^.succ<>nil) do begin
          inc(CY,Interlinea);
          inc(NumLine);
          SearchLine:=SearchLine^.succ;
        end;
      end
      else begin
        { Ricerca verso l'alto }
        while (y<CY) and (SearchLine^.prec<>nil) do begin
          dec(CY,Interlinea);
          dec(NumLine);
          SearchLine:=SearchLine^.prec;
        end;
      end;
    end;
    if SearchLine<>CurrentLine then begin
      XString_ASCIIZ;
      CurrentLine:=SearchLine;
      ASCIIZ_XString;
      ChIndex:=1; CurX:=0;
    end;
    NumActiveLine:=NumLine;
    CurY:=CY;
    GoToChar(x);
  end;




{ Ordina i punti e restituisce TRUE solo se i punti sono uguali }
function EqualPoints(var SBlock,DBlock:TCharPos):boolean;
  var l:longint;
  begin
    EqualPoints:=false;
    if SBlock.line>DBlock.line then begin
      l:=DBlock.line;
      DBlock.line:=SBlock.line;
      SBlock.line:=l;
      asm
        push    ds
        lds     si,SBlock
        les     di,DBlock
        mov     ax,TCharPos(ds:[si]).index
        xchg    ax,TCharPos(es:[di]).index
        mov     TCharPos(ds:[si]).index,ax
        pop     ds
      end;
    end
    else begin
      if SBlock.line=DBlock.line then
        if SBlock.index>DBlock.index
          then
            asm
              push    ds
              lds     si,SBlock
              les     di,DBlock
              mov     ax,TCharPos(ds:[si]).index
              xchg    ax,TCharPos(es:[di]).index
              mov     TCharPos(ds:[si]).index,ax
              pop     ds
            end
          else
            if SBlock.index=DBlock.index then EqualPoints:=true;
    end;
  end;




{ Ordina i punti e restituisce TRUE solo se i punti sono uguali }
function CompPoints(P1,P2:TCharPos):TCompRisults;
  begin
    if P1.line>P2.line then begin
      CompPoints:=CmpMaggiore;
      exit;
    end
    else begin
      if P1.line=P2.line then begin
        if P1.index=P2.index then begin
          CompPoints:=CmpUguale;
          exit;
        end
        else if P1.index>P2.index then CompPoints:=CmpMaggiore
                                  else CompPoints:=CmpMinore;
      end
      else CompPoints:=CmpMinore;
    end;
  end;




procedure SelectText(SBlock,DBlock:TCharPos);
  var l:PLine;
      DimXCh, PosCh:word;
      Line_Editing:boolean;
      NumL:word;
      SourceL, DestL:PLine;
      NumSLs:longint;
      SCurY:integer;
  begin
    SetWriteMode(XorPut);
    if SBlock.line>NumLines then SBlock.line:=NumLines;
    if DBlock.line>NumLines then begin
      DBlock.line:=NumLines;
      DBlock.index:=$FFFF;
    end;
    if EqualPoints(SBlock,DBlock) then exit;
    dec(DBlock.index);
    SourceL:=Text;
    NumL:=SBlock.line;
    while (SourceL<>nil) and (NumL<>1) do begin
      dec(NumL);
      SourceL:=SourceL^.succ;
    end;
    DestL:=Text;
    NumL:=DBlock.line;
    while (DestL<>nil) and (NumL<>1) do begin
      dec(NumL);
      DestL:=DestL^.succ;
    end;
    XString^[DimXString+1]:=#0;
    NumSLs:=DBlock.line-SBlock.line+1;
    SCurY:=Interlinea*(SBlock.line-1);
    Line_Editing:=SourceL^.TextLine=@LineEditing;
    if Line_Editing
      then l:=pointer(XString)
      else l:=pointer(SourceL^.TextLine);
    PosCh:=ActiveFont^.__TextLength(PChar(l),1,SBlock.index-1);
    hidemousecursor;
    if NumSLs=1 then begin
      DimXCh:=ActiveFont^.__TextLength(PChar(l),SBlock.index,DBlock.index);
      barPat(PosCh,SCurY,PosCh+DimXCh-1,SCurY+Interlinea-1);
    end
    else barPat(PosCh,SCurY,_MaxXResolution,SCurY+Interlinea-1);
    if NumSLs>2 then barPat(0,SCurY+Interlinea,_MaxXResolution,SCurY+Interlinea*(NumSLs-2+1)-1);
    if (NumSLs>1) and (DBlock.index>0) then begin
      Line_Editing:=DestL^.TextLine=@LineEditing;
      if Line_Editing
        then l:=pointer(XString)
        else l:=pointer(DestL^.TextLine);
      PosCh:=ActiveFont^.__TextLength(PChar(l),1,DBlock.index);
      barPat(0,SCurY+Interlinea*(NumSLs-1),PosCh-1,SCurY+Interlinea*NumSLs-1);
    end;
    showmousecursor;
    SetWriteMode(NormalPut);
  end;



{ Imposta la nuova fine della selezione e se questa precede l'inizio allora li scambia }
procedure AdjustEndSelection(NewEndBlock:TCharPos);
  var SBlock,
      EBlock:TCharPos;
  begin
    if NewEndBlock.line>NumLines then begin
      NewEndBlock.line:=NumLines;
      NewEndBlock.index:=$FFFF;
    end;
    if ((EndBlock.line=NewEndBlock.line) and
        (EndBlock.index=NewEndBlock.index))  then exit;
    if CompPoints(NewEndBlock,StartBlock)=CmpMinore then begin
      SBlock:=NewEndBlock;
      EBlock:=EndBlock;
      EndBlock:=StartBlock;
      StartBlock:=NewEndBlock;
    end
    else begin
      SBlock:=EndBlock;
      EBlock:=NewEndBlock;
      EndBlock:=NewEndBlock;
    end;
    if ((StartBlock.line=EndBlock.line) and
        (StartBlock.index=EndBlock.index))  then TextSelected:=false;
    SelectText(SBlock,EBlock);
  end;



{ Imposta il nuovo inizio della selezione e se questo segue la fine allora li scambia }
procedure AdjustStartSelection(NewStartBlock:TCharPos);
  var SBlock,
      EBlock:TCharPos;
  begin
    if NewStartBlock.line>NumLines then begin
      NewStartBlock.line:=NumLines;
      NewStartBlock.index:=$FFFF;
    end;
    if ((StartBlock.line=NewStartBlock.line) and
        (StartBlock.index=NewStartBlock.index))  then exit;
    if CompPoints(NewStartBlock,EndBlock)=CmpMaggiore then begin
      SBlock:=StartBlock;
      EBlock:=NewStartBlock;
      StartBlock:=EndBlock;
      EndBlock:=NewStartBlock;
    end
    else begin
      SBlock:=StartBlock;
      EBlock:=NewStartBlock;
      StartBlock:=NewStartBlock;
    end;
    if ((StartBlock.line=EndBlock.line) and
        (StartBlock.index=EndBlock.index))  then TextSelected:=false;
    SelectText(SBlock,EBlock);
  end;




procedure MouseController;
  var flag:boolean;
      ModifingSelection:boolean;
      MouseCTRLPos:TCharPos;

  function Uguale(var StartBlock,EndBlock:TCharPos):boolean;
    begin
      if ((StartBlock.line=EndBlock.line) and
          (StartBlock.index=EndBlock.index))  then Uguale:=true
                                              else Uguale:=false;
    end;

  procedure MouseTextSelection;
    begin
      if not ModifingSelection then begin
        { flag = TRUE se il cursore si trova all'inizio del blocco
                      selezionato }
        flag:=(StartBlock.line=CursorPos.line) and
              (StartBlock.index=CursorPos.index);
        { Se il cursore si trova all'inizio o alla fine del blocco
          selezionato allora }
        if flag or ( (EndBlock.line=CursorPos.line) and
                     (EndBlock.index=CursorPos.index)   )
        then begin
          FindChar(mcx,mcy);
          if flag then begin
            AdjustStartSelection(CursorPos);
          end
          else begin
            AdjustEndSelection(CursorPos);
          end;
        end
        else begin
          SelectText(StartBlock,EndBlock);
          StartBlock:=CursorPos;
          FindChar(mcx,mcy);
          EndBlock:=CursorPos;
          { Ordina i punti StartBlock e EndBlock }
          EqualPoints(StartBlock,EndBlock);
          SelectText(StartBlock,EndBlock);
        end;
      end
      else begin
        TCompRisults(flag):=CompPoints(CursorPos,MouseCTRLPos);
        if TCompRisults(flag)=CmpUguale then begin
          SelectText(StartBlock,EndBlock);
          TextSelected:=false;
        end
        else if TCompRisults(flag)=CmpMinore then begin
          if not Uguale(MouseCTRLPos,EndBlock) then begin
            SelectText(MouseCTRLPos,EndBlock);
            EndBlock:=MouseCTRLPos;
          end;
          AdjustStartSelection(CursorPos);
        end
        else begin
          if not Uguale(MouseCTRLPos,StartBlock) then begin
            SelectText(StartBlock,MouseCTRLPos);
            StartBlock:=MouseCTRLPos;
          end;
          AdjustEndSelection(CursorPos);
        end;
      end;
    end;

  procedure RepeatMouseSelection;
    var precPos:TCharPos;
        precMcx,precMcy:word;
    begin
      ModifingSelection:=true;
      precPos:=CursorPos;
      precMcx:=mcx; precMcy:=mcy;
      while PositionAndButtonStatus<>0 do begin
        if (precMcx<>mcx) or (precMcy<>mcy) then begin
          FindChar(mcx,mcy);
          precMcx:=mcx;
          precMcy:=mcy;
          if not Uguale(precPos,CursorPos) then begin
            if not TextSelected then begin
              StartBlock:=precPos;
              EndBlock:=CursorPos;
              EqualPoints(StartBlock,EndBlock);
              SelectText(StartBlock,EndBlock);
              TextSelected:=true;
            end
            else MouseTextSelection;
            precPos:=CursorPos;
          end;
        end;
      end;
      ModifingSelection:=false;
    end;


  begin { MouseController }
    if (mem[Seg0040:$0017] and $0003) <> 0 then begin
      { Modalit… di selezione del testo }
      ModifingSelection:=false;
      if not TextSelected then begin
        StartBlock:=CursorPos;
        FindChar(mcx,mcy);
        EndBlock:=CursorPos;
        SelectText(StartBlock,EndBlock);
        TextSelected:=true;
        MouseCTRLPos:=StartBlock
      end
      else begin
        if CompPoints(StartBlock,CursorPos)=CmpMinore then
          MouseCTRLPos:=StartBlock
        else MouseCTRLPos:=EndBlock;
        MouseTextSelection;
      end;
      RepeatMouseSelection;
    end
    else begin
      FindChar(mcx,mcy);
      if TextSelected then begin
        if Uguale(CursorPos,StartBlock) then
          MouseCTRLPos:=EndBlock
        else if Uguale(CursorPos,EndBlock) then
          MouseCTRLPos:=StartBlock
        else begin
          SelectText(StartBlock,EndBlock);
          TextSelected:=false;
          MouseCTRLPos:=CursorPos;
        end
      end
      else MouseCTRLPos:=CursorPos;
      RepeatMouseSelection;
    end;
    VMovX:=CurX;
    PersistentCursor:=true;
    Cursor;
    PersistentCursor:=false;
  end;




procedure KeyController;
  var DimCh,DimXCh:word;
      Dx:integer;
      rect:OTRect;
      ch:char;


  procedure DeleteChar;
    begin
      BitBtlVideoDC(CurX+ActiveFont^.TextLength(XString^[ChIndex],0,0),CurY,CurX,CurY,_MaxXResolution,CurHeight);
      asm
        push     ds
        cld
        mov      bx,ChIndex
        dec      bx
        mov      cx,DimXString
        sub      cx,bx
        les      di,XString
        add      di,bx
        lds      si,XString
        mov      si,di
        inc      si
        rep      movsb
        pop      ds
      end;
      dec(DimXString);
    end;


  procedure RefreshText(where:OTRect);
    var view:ViewPortType;
    begin
      GetViewSettings(view);
      if where.IntersectViewPort(view,where) then with where do begin
        SetViewPort(x1,y1,x2,y2,true);
        bar(0,0,DimX,DimY);
        ActiveFont^.__DrawText(-x1,CurY-y1,TextLeft,PChar(XString));
        with view do SetViewPort(x1,y1,x2,y2,clip);
      end;
    end;


  {**** N.B.: Questa procedure presuppone che TextSelected sia TRUE. ****}
  procedure CancellaTesto(var da,a:TCharPos);
    var moreLines:boolean;
        modifiedLine:boolean absolute moreLines;
        line:PLine;
        strPoint:TPointer absolute line; { strPoint Š necessario, ma viene usato una
                                           sola volta e quindi viene utilizzata la
                                           stessa locazione di line }
        SecondPart:PChar;
        i,CX,CY,DimX,precDimX:longint;
    begin
      moreLines:=da.line<>a.line;
      { Si ricava l'indirizzo del primo carattere dopo il blocco di testo
        selezionato. }
      GoToLine(a.line,false);
      { E' necessario allocare nello HEAP la seconda parte della stringa perchŠ
        pu• capitare in seguito che modificando XString si modifichi anche SecondPart
        che punterebbe a ad una zona della memoria dedicata per XString }
{ "i" diventa variabile indisponibile }
      { "i" contiene la lunghezza di SeconPart }
      i:=DimXString-a.index+2;
      GetMem(SecondPart,i);
      pointer(strPoint):=XString;
      inc(strPoint.offset,a.index-1);
      StrCopy(SecondPart,PChar(strPoint));
      { Concatenazione del testo che precede il blocco con il testo che segue
        il blocco }
      precDimX:=ActiveFont^.__TextLength(PChar(XSTring),0,0);
      if precDimX>R.DimX then precDimX:=R.DimX;
      CX:=ActiveFont^.__TextLength(PChar(XSTring),1,a.index-1);
      if moreLines then GoToLine(da.line,false);
      XString^[da.index]:=#0;
      StrCat(PChar(XString),SecondPart);
      { Cancellazione di SeconPart }
      FreeMem(SecondPart,i);
{ "i" torna variabile disponibile }
      DimXString:=StrLen(PChar(XString));
      CurX:=ActiveFont^.__TextLength(PChar(XString),1,da.index-1);
      { Eliminazione delle linee che vanno dalla seconda linea del blocco fino
        all'ultima linea che contiene del testo selezionato. }
      if moreLines then begin
        {* Aggiornameto del frame buffer per pi— linee *}
        { Collega le linee }
        BitBtlVideoDC(CX,   CurY+(a.line-da.line)*Interlinea,
                      CurX, CurY,
                      MaxXResolution,CurHeight);
        rect.assign(R.x2-(CX-CurX),CurY,R.x2,CurY+CurHeight);
        { Refresh del testo sulla nuova linea }
        RefreshText(rect);
        { Spostamento verso l'alto delle linee di sotto }
        BitBtlVideoDC(0, CurY+(a.line-da.line+1)*Interlinea,
                      0, CurY+Interlinea,
                      MaxXResolution,MaxYResolution);
        {* Refresh del testo in basso alla pagina *}
        CY:=(NumLines+1)*Interlinea;
        dec(NumLines,a.line-da.line);
        if CY>R.y2
          then begin
            line:=CurrentLine;
            CY:=CurY;
            i:=NumActiveLine;
            { Si posiziona sulla prima linea che non era completamente visualizzata }
            while (CY+Interlinea<=R.y2) and (line<>nil) do begin
              inc(CY,Interlinea);
              inc(i);
              line:=line^.succ;
            end;
            if line<>nil then begin
              { Procede a riscrivere le linee a cominciare da quella puntata da line
                fino all'ultima linea che pu• essere visualizzata sulla pagina }
              dec(CY,(a.line-da.line)*Interlinea);
              bar(0,CY,MaxXResolution,MaxYResolution);
              modifiedLine:= (i = a.line);
              while (CY<R.y2) and (line<>nil) do begin
                if modifiedLine then begin
                  ActiveFont^.__DrawText(0,CY,TextLeft,PChar(XString));
                  modifiedLine:=false;
                end
                else ActiveFont^.__DrawText(0,CY,TextLeft,line^.TextLine);
                inc(CY,Interlinea);
                line:=line^.succ;
              end;
            end;
          end
          else bar(0, CurY+(NumLines-NumActiveLine+1)*Interlinea, MaxXResolution, MaxYResolution);
        { Eliminazione delle linee in eccesso }
        {**** N.B.: Questa parte di codice presuppone che i valori di "da"
                    e "a" siano corretti. Questo comporta che "line" non sar…
                    mai uguale a NIL. }
        for i:=1 to a.line-da.line do begin
          line:=CurrentLine^.succ;
          CurrentLine^.succ:=line^.succ;
          if line^.succ<>nil then line^.succ^.prec:=CurrentLine;
          if line^.TextLine<>nil then FreeMem(line^.TextLine,StrLen(line^.TextLine)+1);
          dispose(line);
        end;
      end
      else begin
        { Aggiornameto del frame buffer per una sola linea }
        BitBtlVideoDC(CX,CurY+(a.line-da.line)*Interlinea,
                      CurX,CurY,
                      MaxXResolution,CurHeight);
        DimX:=CX-CurX;      {larghezza in pixels del testo selezionato}
        dec(precDimX,DimX);
        rect.assign(precDimX,CurY,R.x2,CurY+CurHeight);
        RefreshText(rect);
      end;
      ChIndex:=da.index;
    end;


  procedure UnisciLinee;
    var line:PLine;
    begin
      XString^[DimXString+1]:=#0;
      if CurrentLine^.succ^.TextLine<>nil then begin
        StrCat(PChar(XString),CurrentLine^.succ^.TextLine);
        DimXString:=StrLen(PChar(XString));
        BitBtlVideoDC(0,CurY+Interlinea,CurX,CurY,
                      _MaxXResolution,Interlinea);
      end;
      with CurrentLine^ do begin
        line:=succ;
        succ:=succ^.succ;
        if succ<>nil then succ^.prec:=CurrentLine;
        dispose(line);
      end;
      BitBtlVideoDC(0,CurY+Interlinea*2,0,CurY+Interlinea,
                    _MaxXResolution,Interlinea*(NumLines-NumActiveLine-1));
      bar(0,CurY+Interlinea*(NumLines-NumActiveLine),_MaxXResolution,CurY+Interlinea*(NumLines-NumActiveLine+1));
      dec(NumLines);
    end;


  procedure UnisciLinee2;
    var line:PLine;
    begin
      XString_ASCIIZ;
      CurrentLine:=CurrentLine^.prec;
      ASCIIZ_XString;
      ChIndex:=DimXString+1;
      dec(CurY,Interlinea);
      CurX:=ActiveFont^.__TextLength(PChar(XString),0,0);
      dec(NumActiveLine);
      UnisciLinee;
    end;


  procedure DebuggingLine;
    begin
      {**** Debugging delle stringhe generate ****}
      bar(0,455,639,479);
      setcolor(0);
      line(0,455,639,455);
      cour.__DrawText(5,460,TextLeft,CurrentLine^.TextLine);
      ActiveFont^.Select;
      {*******************************************}
    end;


  procedure DebuggingXString;
    begin
      {**** Debugging delle stringhe generate ****}
      bar(0,430,639,454);
      setcolor(0);
      line(0,430,639,430);
      if DimXString>0 then cour.__DrawText(5,435,TextLeft,PChar(XString));
      ActiveFont^.Select;
      {*******************************************}
    end;


  procedure FeedBack_X;
    begin
      { FeedBack per i movimenti orizzontali del cursore }
      SetWriteMode(XorPut);
      barPat(CurX,CurY,CurX+DimCh-1,CurY+Interlinea-1);
      SetWriteMode(NormalPut);
    end;


  var flag:boolean;


  begin
    ActiveFont^.Select;
    while keypressed do begin
      ch:=readkey;
      if ch in [FirstCH..LastCH]
      then begin
        if TextSelected then begin
          CancellaTesto(StartBlock,EndBlock);
          TextSelected:=false;
        end;
        DimCh:=ActiveFont^.TextLength(ch,0,0);
        if ChIndex<MemXString-1 then begin
          if ChIndex<=DimXString then begin
            if InsMode
              then begin
                BitBtlVideoDC(CurX,CurY,CurX+DimCh,CurY,_MaxXResolution,CurHeight);
                bar(CurX,CurY,CurX+DimCh-1,CurY+CurHeight);
                asm
                  push     ds
                  std
                  mov      bx,ChIndex
                  mov      cx,DimXString
                  inc      cx
                  les      di,XString
                  add      di,cx
                  inc      cx
                  sub      cx,bx
                  lds      si,XString
                  mov      si,di
                  dec      si
                  rep      movsb
                  pop      ds
                end;
                inc(DimXString);
              end
              else begin
                DimXCh:=ActiveFont^.TextLength(XString^[ChIndex],0,0);
                Dx:=DimCh-DimXCh;
                if Dx<>0 then BitBtlVideoDC(CurX+DimXCh,CurY,CurX+DimXCh+Dx,CurY,_MaxXResolution,CurHeight);
                bar(CurX,CurY,CurX+DimCh-1,CurY+CurHeight);
              end;
          end;
          if DimXString<ChIndex then DimXString:=ChIndex;
          ActiveFont^.DrawText(CurX,CurY,TextLeft,ch);
          XString^[ChIndex]:=ch;
          inc(CurX,DimCh);
          inc(ChIndex);
        end
        else Bip;
        VMovX:=CurX;
      end
      else case ch of
        #00:
           while keypressed do begin
             case readkey of
               #59: {F1}   { Tasto per il debug }
                  begin
                    while false do ;
                  end;
               #72: { Freccia sopra }
                  if CurrentLine^.prec<>nil then begin
                    if (mem[Seg0040:$0017] and $0003) <> 0 then begin
                      { Modalit… di selezione del testo }
                      if not TextSelected then begin
                        StartBlock:=CursorPos;
                        FindChar(VMovX,CurY-Interlinea);
                        EndBlock:=CursorPos;
                        SelectText(StartBlock,EndBlock);
                        TextSelected:=true;
                      end
                      else begin
                        flag:=(StartBlock.line=CursorPos.line) and (StartBlock.index=CursorPos.index);
                        if flag or ((EndBlock.line=CursorPos.line) and (EndBlock.index=CursorPos.index))
                        then begin
                          FindChar(VMovX,CurY-Interlinea);
                          if flag then begin
                            SelectText(CursorPos,StartBlock);
                            StartBlock:=CursorPos;
                          end
                          else begin
                            SelectText(CursorPos,EndBlock);
                            if StartBlock.Line=EndBlock.Line then begin
                              EndBlock.index:=StartBlock.index;
                              StartBlock:=CursorPos;
                            end
                            else begin
                              EndBlock:=CursorPos;
                            end;
                          end;
                          if (StartBlock.line=EndBlock.line) then
                            if StartBlock.index=EndBlock.index
                              then TextSelected:=false
                              else if EndBlock.index<StartBlock.index then asm
                                     mov    ax,StartBlock.index
                                     xchg   ax,EndBlock.index
                                     mov    StartBlock.index,ax
                                   end;
                        end
                        else begin
                          SelectText(StartBlock,EndBlock);
                          StartBlock:=CursorPos;
                          FindChar(VMovX,CurY-Interlinea);
                          EndBlock:=CursorPos;
                          SelectText(StartBlock,EndBlock);
                        end;
                      end;
                    end
                    else begin
                      if TextSelected then begin
                        SelectText(StartBlock,EndBlock);
                        TextSelected:=False;
                      end;
                      FindChar(VMovX,CurY-Interlinea);
                    end;
                  end
                  else Bip;
               #80: { Freccia sotto }
                  if CurrentLine^.succ<>nil then begin
                    if (mem[Seg0040:$0017] and $0003) <> 0 then begin
                      { Modalit… di selezione del testo }
                      if not TextSelected then begin
                        StartBlock:=CursorPos;
                        FindChar(VMovX,CurY+Interlinea);
                        EndBlock:=CursorPos;
                        SelectText(StartBlock,EndBlock);
                        TextSelected:=true;
                      end
                      else begin
                        flag:=(StartBlock.line=CursorPos.line) and (StartBlock.index=CursorPos.index);
                        if flag or ((EndBlock.line=CursorPos.line) and (EndBlock.index=CursorPos.index))
                        then begin
                          FindChar(VMovX,CurY+Interlinea);
                          if flag then begin
                            SelectText(StartBlock,CursorPos);
                            if StartBlock.Line=EndBlock.Line then begin
                              StartBlock.index:=EndBlock.index;
                              EndBlock:=CursorPos;
                            end
                            else begin
                              StartBlock:=CursorPos;
                            end;
                          end
                          else begin
                            SelectText(EndBlock,CursorPos);
                            EndBlock:=CursorPos;
                          end;
                          if (StartBlock.line=EndBlock.line) then
                            if StartBlock.index=EndBlock.index
                              then TextSelected:=false
                              else if EndBlock.index<StartBlock.index then asm
                                     mov    ax,StartBlock.index
                                     xchg   ax,EndBlock.index
                                     mov    StartBlock.index,ax
                                   end;
                        end
                        else begin
                          SelectText(StartBlock,EndBlock);
                          StartBlock:=CursorPos;
                          FindChar(VMovX,CurY+Interlinea);
                          EndBlock:=CursorPos;
                          SelectText(StartBlock,EndBlock);
                        end;
                      end;
                    end
                    else begin
                      if TextSelected then begin
                        SelectText(StartBlock,EndBlock);
                        TextSelected:=False;
                      end;
                      FindChar(VMovX,CurY+Interlinea);
                    end;
                  end
                  else Bip;
               #75: { Freccia sinistra }
                  begin
                    if ChIndex>1 then begin
                      DimCh:=ActiveFont^.TextLength(XString^[ChIndex-1],0,0);
                      dec(CurX,DimCh);
                      if (mem[Seg0040:$0017] and $0003) <> 0 then begin
                        { Modalit… di selezione del testo }
                        if not TextSelected then begin
                          EndBlock:=CursorPos;
                          dec(ChIndex);
                          StartBlock:=CursorPos;
                          TextSelected:=true;
                        end
                        else begin
                          flag:=(StartBlock.line=CursorPos.line) and (StartBlock.index=CursorPos.index);
                          if flag or ((EndBlock.line=CursorPos.line) and (EndBlock.index=CursorPos.index))
                          then begin
                            dec(ChIndex);
                            if flag
                              then dec(StartBlock.index)
                              else dec(EndBlock.index);
                            if ((StartBlock.line=EndBlock.line) and
                                (StartBlock.index=EndBlock.index)) then TextSelected:=false;
                          end
                          else begin
                            SelectText(StartBlock,EndBlock);
                            EndBlock:=CursorPos;
                            dec(ChIndex);
                            StartBlock:=CursorPos;
                          end;
                        end;
                        {- Feed Back -}
                        SetWriteMode(XorPut);
                        barPat(CurX,CurY,CurX+DimCh-1,CurY+Interlinea-1);
                        SetWriteMode(NormalPut);
                      end
                      else begin
                        if TextSelected then begin
                          SelectText(StartBlock,EndBlock);
                          TextSelected:=False;
                        end;
                        dec(ChIndex);
                      end;
                    end
                    else Bip;
                    VMovX:=CurX;
                  end;
               #77: { Freccia destra}
                  begin
                    if ChIndex<=DimXString then begin
                      DimCh:=ActiveFont^.TextLength(XString^[ChIndex],0,0);
                      if (mem[Seg0040:$0017] and $0003) <> 0 then begin
                        { Modalit… di selezione del testo }
                        if not TextSelected then begin
                          StartBlock:=CursorPos;
                          inc(ChIndex);
                          EndBlock:=CursorPos;
                          TextSelected:=true;
                        end
                        else begin
                          flag:=(StartBlock.line=CursorPos.line) and (StartBlock.index=CursorPos.index);
                          if flag or ((EndBlock.line=CursorPos.line) and (EndBlock.index=CursorPos.index))
                          then begin
                            inc(ChIndex);
                            if flag
                              then inc(StartBlock.index)
                              else inc(EndBlock.index);
                            if ((StartBlock.line=EndBlock.line) and
                                (StartBlock.index=EndBlock.index)) then TextSelected:=false;
                          end
                          else begin
                            SelectText(StartBlock,EndBlock);
                            StartBlock:=CursorPos;
                            inc(ChIndex);
                            EndBlock:=CursorPos;
                          end;
                        end;
                        {- Feed Back -}
                        SetWriteMode(XorPut);
                        barPat(CurX,CurY,CurX+DimCh-1,CurY+Interlinea-1);
                        SetWriteMode(NormalPut);
                      end
                      else  begin
                        if TextSelected then begin
                          SelectText(StartBlock,EndBlock);
                          TextSelected:=False;
                        end;
                        inc(ChIndex);
                      end;
                      inc(CurX,DimCh);
                    end
                    else Bip;
                    VMovX:=CurX;
                  end;
               #73: { Pagina Sopra }
                  if TextSelected then begin
                    SelectText(StartBlock,EndBlock);
                    TextSelected:=False;
                  end;
               #81: { Pagina Sotto }
                  if TextSelected then begin
                    SelectText(StartBlock,EndBlock);
                    TextSelected:=False;
                  end;
               #82: { Ins }
                  InsMode:=not InsMode;
               #83: { Canc }
                  begin
                    if TextSelected then begin
                      CancellaTesto(StartBlock,EndBlock);
                      TextSelected:=false;
                    end
                    else if ChIndex<=DimXString
                      then begin

                        {**** Debugging delle stringhe generate ****
                        bar(0,455,639,479);
                        setcolor(0);
                        line(0,455,639,455);
                        if XString^[ChIndex]<#32
                        then cour.DrawText(5,460,TextLeft,'#'+NumStr(ord(XString^[ChIndex])))
                        else cour.DrawText(5,460,TextLeft,XString^[ChIndex]);
                        ActiveFont^.Select;
                        {*******************************************}


                        DimCh:=ActiveFont^.__TextLength(PChar(XString),ChIndex,ChIndex+1);
                        DeleteChar;
                        rect.assign(R.x2-DimCh,CurY,R.x2,CurY+CurHeight);
                        RefreshText(rect);
                      end
                      else
                        if (NumActiveLine=NumLines) or
                           (StrLen(CurrentLine^.succ^.TextLine) > MemXString-DimXString)
                          then Bip
                          else begin

                            {**** Debugging delle stringhe generate ****
                            bar(0,455,639,479);
                            setcolor(0);
                            line(0,455,639,455);
                            if XString^[ChIndex]<#32
                            then cour.DrawText(5,460,TextLeft,'#'+NumStr(ord(XString^[ChIndex])))
                            else cour.DrawText(5,460,TextLeft,XString^[ChIndex]);
                            ActiveFont^.Select;
                            {*******************************************}

                            UnisciLinee;
                          end;
                    VMovX:=CurX;
                  end;
               #71: { Home }
                  begin
                    if ChIndex>1 then begin
                      DimCh:=CurX;
                      CurX:=0;
                      if (mem[Seg0040:$0017] and $0003) <> 0 then begin
                        if not TextSelected then begin
                          EndBlock:=CursorPos;
                          ChIndex:=1;
                          StartBlock:=CursorPos;
                          TextSelected:=true;
                        end
                        else begin
                          flag:=(StartBlock.line=CursorPos.line) and (StartBlock.index=CursorPos.index);
                          if flag or ((EndBlock.line=CursorPos.line) and (EndBlock.index=CursorPos.index))
                          then begin
                            ChIndex:=1;
                            if flag
                              then StartBlock.Index:=1
                              else EndBlock.Index:=1;
                            if (StartBlock.line=EndBlock.line) then
                              if StartBlock.index=EndBlock.index
                                then TextSelected:=false
                                else if EndBlock.index<StartBlock.index then asm
                                       mov    ax,StartBlock.index
                                       xchg   ax,EndBlock.index
                                       mov    StartBlock.index,ax
                                     end;
                          end
                          else begin
                            SelectText(StartBlock,EndBlock);
                            EndBlock:=CursorPos;
                            ChIndex:=1;
                            StartBlock:=CursorPos;
                          end;
                        end;
                        {- Feed Back -}
                        SetWriteMode(XorPut);
                        barPat(CurX,CurY,CurX+DimCh-1,CurY+Interlinea-1);
                        SetWriteMode(NormalPut);
                      end
                      else ChIndex:=1;
                    end;
                    VMovX:=0;
                  end;
               #79: { Fine }
                  begin
                    if ChIndex<=DimXString then begin
                      XString^[DimXString+1]:=#0;
                      DimCh:=ActiveFont^.__TextLength(PChar(XString),0,0)-CurX;
                      if (mem[Seg0040:$0017] and $0003) <> 0 then begin
                        if not TextSelected then begin
                          StartBlock:=CursorPos;
                          ChIndex:=DimXString+1;
                          EndBlock:=CursorPos;
                          TextSelected:=true;
                        end
                        else begin
                          flag:=(StartBlock.line=CursorPos.line) and (StartBlock.index=CursorPos.index);
                          if flag or ((EndBlock.line=CursorPos.line) and (EndBlock.index=CursorPos.index))
                          then begin
                            ChIndex:=DimXString+1;
                            if flag
                              then StartBlock.index:=ChIndex
                              else EndBlock.index:=ChIndex;
                            if (StartBlock.line=EndBlock.line) then
                              if StartBlock.index=EndBlock.index
                                then TextSelected:=false
                                else if EndBlock.index<StartBlock.index then asm
                                       mov    ax,StartBlock.index
                                       xchg   ax,EndBlock.index
                                       mov    StartBlock.index,ax
                                     end;
                          end
                          else begin
                            SelectText(StartBlock,EndBlock);
                            StartBlock:=CursorPos;
                            ChIndex:=DimXString+1;
                            EndBlock:=CursorPos;
                          end;
                        end;
                        {- Feed Back -}
                        SetWriteMode(XorPut);
                        barPat(CurX,CurY,CurX+DimCh-1,CurY+Interlinea-1);
                        SetWriteMode(NormalPut);
                      end
                      else ChIndex:=DimXString+1;
                      inc(CurX,DimCh);
                    end;
                    VMovX:=CurX;
                  end;
             end;
           end;
        #08: { Back space }
           begin
             if TextSelected then begin
               CancellaTesto(StartBlock,EndBlock);
               TextSelected:=false;
             end
             else if ChIndex>1 then begin
               dec(ChIndex);
               dec(CurX,ActiveFont^.TextLength(XString^[ChIndex],0,0));
               DimCh:=ActiveFont^.__TextLength(PChar(XString),ChIndex,ChIndex+1);
               DeleteChar;
               rect.assign(R.x2-DimCh,CurY,R.x2,CurY+CurHeight);
               RefreshText(rect);
             end
             else begin
               if (NumActiveLine>1) then begin
                 UnisciLinee2;
               end
               else Bip;
             end;
             VMovX:=CurX;
           end;
        #13: { Invio }
           begin
             if TextSelected then begin
               CancellaTesto(StartBlock,EndBlock);
               TextSelected:=false;
             end;
             if InsMode then begin
               if ChIndex=1 then begin
                 InsertLine;
                 BitBtlVideoDC(0,CurY,0,CurY+Interlinea,
                               _MaxXResolution,Interlinea*(NumLines-NumActiveLine+1));
                 bar(0,CurY,_MaxXResolution,CurY+Interlinea);
               end
               else begin
                 if ChIndex>DimXString
                 then begin
                   XString_ASCIIZ;
                   NewLine;
                   ASCIIZ_XString;
                   if NumActiveLine<NumLines then begin
                     BitBtlVideoDC(0,CurY+Interlinea,0,CurY+Interlinea*2,
                                   _MaxXResolution,Interlinea*(NumLines-NumActiveLine));
                     bar(0,CurY+Interlinea,_MaxXResolution,CurY+Interlinea*2);
                   end;
                 end
                 else SeparateLines;
               end;
               inc(NumLines);
             end
             else begin
               XString_ASCIIZ;
               if NumActiveLine<NumLines
                 then CurrentLine:=CurrentLine^.succ
                 else begin
                   NewLine;
                   inc(NumLines);
                 end;
               ASCIIZ_XString;
             end;
             CurX:=0;
             VMovX:=0;
             inc(CurY,Interlinea);
             ChIndex:=1;
             inc(NumActiveLine);
           end;
        #27:
           EditorShutDown;
      end;
    end;
  end;

{ ********************************************************************** }
{ ********************         MANCA ANCORA         ******************** }
{ **********************************************************************

1. Controllare tutte le procedure che modificano il testo implementandole
   con il controllo sulla variabile globale "R"
2. Controllo della dimensione delle stringhe nel caso in cui due stringhe
   vengono unite tra loro
3. Implementazione delle funzioni Pagina Su e Pagina Giu
4. Implementazione delle funzioni CTRL+LeftRow e CTRL+RightRow

{ **********************************************************************
}