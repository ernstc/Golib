{ Ernesto CIANCIOTTA Productions }

{ *************************************** }
{ *                                     * }
{ * Modulo della libreria GOLIB per la  * }
{ * gestione delle Status line.         * }
{ *                                     * }
{ * Scritto con Turbo Pascal 7.0        * }
{ *                                     * }
{ *************************************** }

{$D+}
{$L+}

UNIT StatusLn;

INTERFACE

 uses
      codici,
      dos,
      mouse,
      graph,
      graftool,
      fonts,
      golib_h,
      golib9,
        dispfile;



const
       MAIN_MESSAGE_FIELD = $0001;

       swINS       = $0080;
       swCAPSLOCK  = $0040;
       swBLOCNUM   = $0020;
       swBLOCSCORR = $0010;

type
      PString = ^String;

      TAlign = (Left,Center,Right,Normal);

      TKeySwicth = (INS,CAPSLOCK,BLOCNUM,BLOCSCORR);

      OPField = ^OTField;
      OTField = object (OTIncavo3dSoft)
      private
         txt:String;
         allineamento:TAlign;
      public
         constructor Init(FieldNum:word; var coord:OTRect; text:String);
         procedure Disegna; virtual;
         procedure UpDate;
      end;


      OPStatusLine = ^OTStatusLine;
      OTStatusLine = object (OTView)
         constructor Init(var coord:OTRect; DimMainField:word);
         destructor Done; virtual;
         procedure Adjust; virtual;
         procedure AddMessageField(x,y:integer; dim:word; align:TAlign);
         procedure AddKeyBoardInfoField(info:byte);
         function GetNumFields:byte;
         { Aggiorna il messaggio di un campo con una stringa provaniente
           dall'esterno. }
         procedure SetMessage(FieldNum:word; Message:string);
         { Aggiorna il messaggio di un campo tramite codice. Questo metodo
           contiene una struttura "case" che seleziona il codice e aggiorna il
           il campo corrispondente con il messaggio corrispondente con il
           metodo SetMessage. Questo puï risultare utile se si vuole separare
           i messaggi dal codice dell'oggetto che li vuole visualizzare tramite
           la status line. Un esempio ä la Menó line.
           Questo metodo ä utile solo per il polimorfismo. }
         procedure Hints(MessageCode:word); virtual;
      private
         NumFields: byte;
         FullMainField: boolean;
         KeyboardInfo: byte;
         KeySwicth: array[TKeySwicth] of OPField;
         { Puntatore all'interrupt della tastiera. }
         KbdInt09vec: procedure;

         primoAdjust:boolean;
      end;



IMPLEMENTATION

const
      wdINS        = 22;
      wdCAPSLOCK   = 33;
      wdBLOCNUM    = 29;
      wdBLOCSCORR  = 42;
      SpaceBeetwen =  4;

      Swicthes: array[TKeySwicth] of byte =
        ( swINS      ,
          swCAPSLOCK ,
          swBLOCNUM  ,
          swBLOCSCORR );

      swDescr: array[TKeySwicth] of string[5] =
        ('INS','LOCK','NUM','SCORR');

      wdData: array[TKeySwicth] of byte =
        ( wdINS      ,
          wdCAPSLOCK ,
          wdBLOCNUM  ,
          wdBLOCSCORR );

var
    StatusLine: OPStatusLine;
    Int09vec:pointer;


{$F+}
   procedure Keyclick; interrupt;
     var swicth:TKeySwicth;
     begin
       asm
         cli
       end;
       SetIntVec($9,Int09vec);
       { Call old ISR using saved vector }
       inline ($9C);TProc(Int09vec);
       if Port[$60] >= $80 then begin
         hidemousecursor;
         with StatusLine^ do begin
           for swicth:=INS to BLOCSCORR do
             if StatusLine^.KeySwicth[swicth]<>nil then begin
               if (mem[$0040:$0017] and Swicthes[swicth])=0
               then begin
                 if StatusLine^.KeySwicth[swicth]^.txt[0]<>#0 then begin
                   KeySwicth[swicth]^.txt[0]:=#0;
                   KeySwicth[swicth]^.UpDate;
                 end
               end
               else begin
                 if StatusLine^.KeySwicth[swicth]^.txt[0]=#0 then begin
                   KeySwicth[swicth]^.txt:=swDescr[swicth];
                   KeySwicth[swicth]^.UpDate;
                 end;
               end;
             end;
         end;
         showmousecursor;
       end;
       SetIntVec($9,@Keyclick);
       asm
         sti
       end;
     end;
{$F-}

                      {----- OTField -----}
  constructor OTField.Init(FieldNum:word; var coord:OTRect; text:String);
    begin
      txt:=text;
      inherited Init(FieldNum,coord,1,-1);
      SysConfig:=SysConfig or cfPostDraw
                           or cfTrasparent;
    end;


  procedure OTField.Disegna;
    var view:ViewPortType;
    begin
      inherited Disegna;
      textcolor:=0;
      GetViewSettings(view);
      with view do begin
        if x1=precR.x1 then inc(x1);
        if y1=precR.y1 then inc(y1);
        if x2=precR.x2 then dec(x2);
        if y2=precR.y2 then dec(y2);
        SetViewPort(x1,y1,x2,y2,true);
      end;
      with R do MenuLFont^.DrawText(x1+2,y1+1,TextLeft,txt);
    end;


  procedure OTField.UpDate;
    var newView:OTRect;
        obj:OPView;
        RefreshM:TSortMethod;
        LightList:PRefreshRectList;
    begin
      textcolor:=0;
      with R do NewView.assign(x1+1,y1+1,x2-1,y2-1);
      if ((_Father_<>nil) and not _Father_^.R.Intersect(NewView,NewView))
      then
      else begin
        { Determinazione delle regioni visibili del campo.
          Quest'operazione ä necessaria perchä il campo puï essere
          aggiornato in qualsiasi momento, anche quando ä in secondo
          piano. }
        obj:=@Self;
        LightList:=NullObj;
        while obj^._Father_<>nil do begin
          obj:=obj^._Father_;
          LightList:=GetLightListOf(obj,@NewView,LightList);
        end;
        RefreshM:=RectSortMethod;
        RectSortMethod:=LTRB;
        RefreshRect(NewView,Primo,LightList);
        RectSortMethod:=RefreshM;
      end;
    end;


                    {----- OTStatusLine -----}
  constructor OTStatusLine.Init(var coord:OTRect; DimMainField:word);
    var field:OPField;
        rect:OTRect;
        i:TKeySwicth;
    begin
      NumFields:=1;
      KeyboardInfo:=0;
      for i:=INS to BLOCSCORR do KeySwicth[i]:=nil;
      if DimMainField=0
        then begin
          FullMainField:=true;
          rect:=coord;
        end
        else begin
          FullMainField:=false;
          with coord do rect.SetRect(x1,y1,DimMainField,MenuLFont^.GetHeight+3);
        end;
      new(field, Init(MAIN_MESSAGE_FIELD,rect,'Ready'));
      field^.allineamento:=Left;
      inherited InitComposite(Null_ID,coord,field);
      SysConfig:=SysConfig and __cfDrawFatherRect
                           and __cfScanGroup
                           or cfITLF
                           or cfPostDraw;
      primoAdjust:=true;
    end;


  destructor OTStatusLine.Done;
    begin
      SetIntVec($9,Addr(KbdInt09vec));
      inherited Done;
    end;


  procedure OTStatusLine.Adjust;
    var field:OPView;
        swicth:TKeySwicth;
    begin
      if primoAdjust then begin
        precR:=R;
        primoAdjust:=false;
      end;
      if FullMainField
        then _gruppo_^.R:=R
        else begin
          field:=_gruppo_;
          while field<>nil do begin
            case OPField(field)^.allineamento of
            Left,
            Normal: with R do field^.R.SetRect(x1+(field^.R.x1-precR.x1),y1,
                                               field^.R.DimX,field^.R.DimY);
            Right:  with R do field^.R.SetRect(x2-(precR.x2-field^.R.x1),y1,
                                               field^.R.DimX,field^.R.DimY);
            Center: with R do field^.R.SetRect((DimX-field^.R.DimX) div 2,y1,
                                               field^.R.DimX,field^.R.DimY);
            end;
            field:=field^._down_;
          end;
        end;
      for swicth:=INS to BLOCSCORR do
        if KeySwicth[swicth]<>nil then begin
          if (mem[$0040:$0017] and Swicthes[swicth])=0
          then begin
            if KeySwicth[swicth]^.txt[0]<>#0 then KeySwicth[swicth]^.txt[0]:=#0;
          end
          else begin
            if KeySwicth[swicth]^.txt[0]=#0 then KeySwicth[swicth]^.txt:=swDescr[swicth];
          end;
        end;
    end;


  procedure OTStatusLine.AddMessageField(x,y:integer; dim:word; align:TAlign);
    var field:OPField;
        rect:OTRect;
    begin
      inc(NumFields);
      with r do rect.SetRect(x+x1,y+y1,dim,MenuLFont^.GetHeight+3);
      new(field, Init(NumFields,rect,''));
      field^.allineamento:=align;
      AppendObject(field);
    end;


  procedure OTStatusLine.AddKeyBoardInfoField(info:byte);
    var x:integer;
        rect:OTRect;
        swicth:TKeySwicth;
        descr:string[5];
    begin
      x:=R.x2-20+SpaceBeetwen;
      for swicth:=BLOCSCORR downto INS do
        if KeySwicth[swicth]<>nil
          then dec(x,wdData[swicth]+SpaceBeetwen)
          else begin
            if (info and Swicthes[swicth])<>0 then begin
              dec(x,wdData[swicth]+SpaceBeetwen);
              with r do rect.SetRect(x,y1,wdData[swicth],MenuLFont^.GetHeight+3);
              if (mem[$0040:$0017] and Swicthes[swicth])=0
                then descr:=''
                else descr:=swDescr[swicth];
              new(KeySwicth[swicth], Init(0,rect,descr));
              KeySwicth[swicth]^.allineamento:=Right;
              AppendObject(KeySwicth[swicth]);
            end;
          end;
      if KeyBoardInfo=0 then begin
        StatusLine:=@Self;
        { Insert ISR into keyboard chain }
        GetIntVec($9,@KbdInt09vec);
        GetIntVec($9,Int09vec);
        SetIntVec($9,Addr(Keyclick));
      end
      else KeyBoardInfo:=info;
    end;


  function OTStatusLine.GetNumFields:byte;
    begin
      GetNumFields:=NumFields;
    end;


  procedure OTStatusLine.SetMessage(FieldNum:word; Message:string);
    var field:OPField;
    begin
      if FieldNum>NumFields then FieldNum:=MAIN_MESSAGE_FIELD;
      field:=pointer(_gruppo_);
      while (field<>nil) and (field^.ID<>FieldNum) do field:=pointer(field^._down_);
      field^.txt:=Message;
      if lookvideo then begin
        hidemousecursor;
        field^.UpDate;
        showmousecursor;
      end;
    end;


  procedure OTStatusLine.Hints(MessageCode:word);
    begin
      if MessageCode=0 then SetMessage(MAIN_MESSAGE_FIELD,'');
    end;




end.