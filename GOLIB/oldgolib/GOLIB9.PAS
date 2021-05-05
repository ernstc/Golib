{ by ERNESTO CIANCIOTTA Productions }  {24.265 linee circa di codice (senza alcune librerie)}

{*************************************************}
{*                                               *}
{*  GOLIB => Graphics Object LIBrary             *}
{*                                               *}
{*  Modulo principale della libreria.            *}
{*                                               *}
{*  Scritto con Turbo Pascal ver 7.0.            *}
{*                                               *}
{*************************************************}

{$D+}
{$L+}
{$X+}

UNIT GOLIB9;

INTERFACE


uses {$IFDEF debugging}
     crt,
     {$ENDIF}
     {IFDEF debugging}
     {ENDIF}
     codici,
     dos,
     utility,
     graph,
     strings,
     mouse,
     fonts,
     graftool,
     golib_h,
     bitmaps;



const

{ Costanti di carattere generale. }
     Spessore_Bordo:word=4;
     {Attiva:boolean=true;}
     {Disattiva:boolean=false;}
     {DimNorm:boolean=false;}
     DefaultCancBar:byte=0;
     LookVideo:boolean = false;
     DeleteObjectWhenChange:boolean=true;
     {_Set_Group_:pointer=nil;}
     MovimentMode8:boolean=false; { Se TRUE il movimento degli oggetti, nella
                                    sola direzione orizzontale, avviene di
                                    8 pixels alla volta. Questo velocizza
                                    l'esecuzione delle operazioni BITBTL. }


{ Costanti per la gestione della display-list. }
     CancObjWithBar  : boolean = false;
     CancBarColor    : word = 0;
     LookVideoOnShutDown: boolean = true;
     DeleteShadow    :boolean = true;    { * forse bisogna cambiarle il nome * }
     {$IFDEF Debugging }
       WaitInShutDown:boolean=false;
       WaitDelay:integer=-2;
       WaitInRefreshDelay:integer=-1;
     {$ENDIF}



type
     PRefreshRectList = ^TRefreshRect;


     OPRect = ^OTRect;
     OTRect = object
        x1,y1,x2,y2,
        DimX,DimY:longint;
        procedure Assign(a,b,c,d:longint);
        procedure SetRect(x,y,dmX,dmY:longint);
        procedure GetRect(var r:OTRect);
        procedure Union(var r:OTRect);
        procedure Move(x,y:longint);
        procedure MoveRel(dx,dy:longint);
        function RectIn(r:OTRect):boolean;
        function Intersect(var r, ris: OTRect):boolean;
        function IntersectViewPort(var v:ViewPortType; var ris: OTRect):boolean;
        function DifferenceWith(var r:OTRect):PRefreshRectList;
        function XYIn(x,y:longint):boolean;
        function Zero:boolean;
        function Equal(var r:OTRect):boolean;
     end;


     OPMouseRect = ^OTMouseRect;
     OTMouseRect = object (OTRect)
        procedure Make;
     end;


     TRefreshRect = record
        r: OTRect;
        succ:PRefreshRectList;
     end;


     { Vedere se si riesce ad eliminare il campo "last". }
     OPRects = ^OTRects;
     OTRects = object
        rect:OTRect;
        last,
        succ:OPRects;
        procedure ResetList;
        procedure newRect(var r:OTRect);
        procedure CopyListFrom(list:OPRects);
        procedure DisposeList;
     end;


     PDrawParameters = ^TDrawParameters;
     TDrawParameters = record
        rect:OTRect;
        params:pointer;
     end;


     PPointers = ^TPointers;
     TPointers = array [1..4] of pointer;


     { 12 metodi virtuali }
     OPView = ^OTView;
     OTView = object (OTGolibObject)
        ID:word; { Identificazione tramite codice non necessariamente primario.
                   Questo codice viene utilizzato per la reazione agli eventi
                   delle periferiche di puntamento, come ad esempio il Mouse, in
                   oggetti composti a loro volta da un insieme di oggetti
                 }

        { ********************************************************** }
        { **                                                      ** }
        { ** MAI CAMBIARE L'ORDINE DEI 4 PUNTATOTI CHE SEGUONO:   ** }
        { ** _Father_, _gruppo_, _down_, _up_.                    ** }
        { **                                                      ** }
        { ********************************************************** }

        _Father_,           { puntatore al padre dell'oggetto }
        _Gruppo_,  { puntatore al primo elemento della SubList ed Š a sola LETTURA}
        _down_  ,           { verso il basso }
        _up_,               { verso l'alto   }
        _last_  : OPView;

        SysConfig: word;    { Configurazione di sistema della finestra }
        MouseReactionMask:byte;
        PrefRefresh:TSortMethod;
                            { Se l'oggetto Š composto indica il metodo preferito
                              dall'oggetto per il refresh }
        precR: OTRect; { Rettangolo prima dell'ultima modifica (moving o resizing) che pu•
                         essere utilizzato nelle procedure Adjust e in alcuni casi nelle
                         procedure Disegna. Pu• essere sempre utilizzato dopo una chiamata
                         ai metodi MoveRel e Resize. }
        R: OTRect;     { Area di lavoro dell'oggetto. }
        _CancBar_:Byte;

        CursorID: word; { Identificatore che del CursorMap che deve essere visualizzato
                          quando il cursore del mouse Š nella regione di lavoro dell'oggetto. }
        HotSpotsResID:word;
        SubObjSelected: OPView;
        constructor Init(_ID:word; var coord:OTRect);
        constructor InitComposite(_ID:word; var coord:OTRect; objs:OPView);
        destructor Done; virtual;
        { Chiama il distruttore di tutti gli oggetti della sub-list senza
          eliminarli dallo HEAP. }
        procedure DestroySubList;
        { Inserisce l'oggetto nella lista principale (ROOT) e lo rende vidibile }
        procedure PutOnDeskTop;
        procedure Disegna; virtual;
        procedure DisegnaXY(x,y:integer);
        procedure Refresh;
      {
        Procedure di gestione della dimensione, del posizionamento e
        della visibilit… dell'oggetto:
      }
        function Resize(_r:OTRect):boolean; virtual;
        procedure Adjust; virtual;
        procedure SetLimitSize(DimX,DimY:word);
        procedure GetLimitSize(var DimX,DimY:word);
        procedure Move(x,y:integer);
        procedure MoveRel(dx,dy:integer); virtual;
        procedure Hide;
        procedure Show;
        procedure Select; virtual;
        procedure Deselect; virtual;
        { Rispettivamente abilitano e disabilitano l'oggetto e tutti gli
          oggetti della sub-list }
        procedure Enable; virtual;
        procedure Disable; virtual;
      {
        Procedure di gestione della lista di oggetti:
      }
        { Posiziona l'oggetto in capo alla display-list }
        procedure PutOnFirst;
        function UniqueInList:boolean;
        { Imposta obj come successivo di Self. }
        procedure LinkTo(obj:OPView);
      {
        Procedure di gestione degli eventi:
      }
        procedure ExecMessage(var Message:TMessage); virtual;
        procedure SendMessage(var Message:TMessage);
        procedure DispatchMessage(var Message:TMessage);

        procedure EvMoveObject(mcx,mcy:integer);
        procedure EvDimObject(mcx,mcy:integer);

        function SetCursor(x,y:integer):word; virtual;
        function GetHotSpots(ResID:word):PHotSpotsArray; virtual;
      {
        Procedure per il disegno all'interno di oggetti OTView.
      }
        procedure DrawInside(x1,y1,x2,y2:integer; proc,params:pointer); virtual;
        procedure DrawInside2(x1,y1,x2,y2:integer; proc,params:pointer; DrawList:PRefreshRectList); virtual;
        function GetDrawList:PRefreshRectList;

      {*** Procedure per la gestione della sub-list ***}
        { Assegna una nuova lista a _gruppo_ senza, per•, distruggere la lista
          esistente. }
        procedure  AssignGroup(NewGroup:OPView);
        { Sposta il gruppo nell'oggetto Dest aggiornando il campo _Father_ degli
          oggetti della lista e poi si auto distrugge. }
        destructor GiveGroupTo(Dest:OPView);
        procedure MoveGroupRel(dx,dy:integer);
        { Metodi per la gestione della lista delle sub-views.
          Se un oggetto viene inserito o rimosso non viene effettuata nessuna
          oparazione di refresh. }
        procedure AddAtTop(NewObj: OPView);
        procedure AppendObject(NewObj: OPView);
        procedure RemoveObject(obj: OPView);
        procedure ChangeObject(obj, NewObj: OPView);
        procedure InsertBefore(obj, NewObj: OPView);
        procedure InsertAfter(obj, NewObj: OPView);

     public
        MinDimX, MinDimY:word;
     {private}
        function PutObjectOverTheTop:OPView;
     end;


     OPGroup = ^OTGroup;
     OTGroup = object (OTView)
        constructor Init(_ID:word; _Title:string; objs:OPView);
        procedure Disegna; virtual;
        procedure Select; virtual;
        procedure Deselect; virtual;
        procedure Enable; virtual;
        procedure Disable; virtual;
     private
        Title:string;
     end;


     OPBar = ^OTBar;
     OTBar = object (OTView)
        style:word;
        colore:integer;
        constructor Init(_ID:word;var coord:OTRect; stl:word; col:integer);
        procedure SetStyle(stl:word; col:integer);
        procedure Disegna; virtual;
     end;


     OPText = ^OTText;
     OTText = object (OTBar)
        constructor Init(_ID:word;var coord:OTRect; _font:OPFont; str:string;
                         stl:word; bkcol,TxCol:integer);
        constructor __Init(_ID:word;var coord:OTRect; _font:OPFont; str:PChar;
                           stl:word; bkcol,TxCol:integer);
        destructor Done; virtual;
        procedure Disegna; virtual;
        procedure SetTextProperties(_font:OPFont; col:word);
        function  GetFont:OPFont;
        function  GetTextColor:word;
        procedure GetTextInfo(var text:PChar; var _font:pointer; var TxtCol:word);
        { Cambia il testo utilizzando lo stile Pascal per il parametro
          stringa. }
        procedure ChangeTextPas(var newText:string);
        { Cambia il testo utilizzando come parametro una stringa con
          terminatore nullo. }
        procedure ChangeText(newText:PChar);
     private
        _text_:PChar;
        TextFont:OPFont;
        TextCol:word;
     end;


     OPAutoText = ^OTAutoText;
     OTAutoText = object (OTText)
        constructor Init(_ID:word;var coord:OTRect; _font:OPFont; str:string;
                         stl:word; bkcol,TxCol:integer);
        constructor __Init(_ID:word;var coord:OTRect; _font:OPFont; str:PChar;
                           stl:word; bkcol,TxCol:integer);
        destructor Done; virtual;
        procedure Adjust; virtual;
        procedure GetTextInfo(var text:PChar; var _font:pointer; var TxtCol:word);
     private
        precText: PChar;
        changed: boolean;
     end;


     OPWin3D = ^OTWin3D;
     OTWin3D = object (OTBar)
        procedure Disegna; virtual;
     end;


     OPRilievo3D = ^OTRilievo3D;
     OTRilievo3D = object (OTBar)
        procedure Disegna; virtual;
     end;


     OPIncavo3D = ^OTIncavo3D;
     OTIncavo3D = object (OTBar)
        procedure Disegna; virtual;
     end;


     OPRilievo3DSoft = ^OTRilievo3DSoft;
     OTRilievo3DSoft = object (OTBar)
        procedure Disegna; virtual;
     end;


     OPIncavo3DSoft = ^OTIncavo3DSoft;
     OTIncavo3DSoft = object (OTBar)
        procedure Disegna; virtual;
     end;


     OPLine = ^OTLine;
     OTLine = object (OTView)
        constructor Init(var coord:OTRect; color:word; lineType:TLine);
        procedure Disegna; virtual;
        procedure ChangeLineSettings(color:word; lineType:TLine);
     private
        _LineType_:TLine;
        _Color_:word;
     end;


     OPRectangle = ^OTRectangle;
     OTRectangle = object (OTLine)
        procedure Disegna; virtual;
     end;


     OPCircle = ^OTCircle;
     OTCircle = object (OTLine)
        procedure Disegna; virtual;
     end;




const
      ESP: boolean = false;  { ESP => Event Scanning Processing
                               Se true allora vuol dire che Š in
                               sospeso la scansione della display-list
                               per rispondere ad un evento.
                             }
      EventVerified: boolean = true; { Serve agli oggetti per fare bloccare la
                                       trasmissione dei messaggi verso i padri }
      PopUpMode: boolean = false; { Se il PopUpMode Š attivato e il primo oggetto
                                    della display-list Š sul desktop, allora il
                                    gestore degli eventi provveder… a distruggere
                                    il primo oggetto non appena si verificher… un
                                    evento del mouse al difuori dell'area di lavoro
                                    dell'oggetto stesso.
                                    N.B.: Il gestore degli eventi disattiva PopUpMode
                                          solo dopo aver distrutto l'oggetto e di
                                          conseguenza Š consigliabile disattivare tale
                                          modalit… nel metodo Reaction o nel metodo
                                          ReactionEvent ,dell'oggetto che deve funzionare
                                          come PopUp, se la tale modalit… deve essere
                                          disattivata in risposta a determinati messaggi.
                                  }

var
      StopESP: boolean;      { Serve per interrompere l'ESP quando
                               l'oggetto processato venga distrutto
                               prima del termine del processo.
                             }


var

{ Variabili per la gestione della display-list. }
     Primo, Ultimo: OPView;
     Sfondo:OPView;
     RectSortMethod:TSortMethod;
const
     { Se TRUE vuol dire che Š in corso un'operazione di refresh.
       Utilizzabile solo nei metodi Disegna o comunque in tutti quei
       processi che possono essere creati durante un'operazione di
       refresh. }
     RefreshProcessing:boolean = false;

var
{ Variabili per l'uso dei fonts. }
     IntestFont,
     MenuLFont,
     MenuPPFont:OPFont;



{ Altre variabili. }
     {ConstructorMode:boolean;}
     MouseIn:boolean;  { Buffer di utilit… per il mouse.
                         Se Š uguale a true, prima di intraprendere
                         un'operazione di disegno, viene prima nascosto
                         il cursore del mouse e poi scoperto. }
     NullRect:OTRect; { Rettangolo nullo. }
     FullRect:OTRect; { Rettangolo di dimensione uguali alla risoluzione attiva. }
     NullObj:Pointer; { Oggetto nullo. }
     All_Objects:pointer;
     EvMoveRange:OTRect;
     EvMoveDirection:TDirection;

     DeallocMemory: pointer;


{ Variabili per il salvataggio degli indirizzi degli interrupts. }
     Int09Save: pointer;



{ INIZIO variabili globali *PRIVATE*. }


ObjectSelected:OPView;

{ FINE dichiarazione variabili *PRIVATE*. }


{
  Le procedure e le funzioni che seguono servono per la scansione della
  display-list per determinare l'insieme delle zone visibili o invisibili di
  un oggetto dato. Tali insiemi restituiti sotto forma di liste vengono
  utilizzati per il refresh.
}


{ ... Procedure del dislay-file ... }



{ Altre procedure di utilit…. }
   function GetVMP(VMT:pointer; NVMethod:word):pointer;
   procedure ClearDevice;
   procedure RestoreGolibGraphMode;
   procedure LookVideoOn;
   procedure LookVideoOff;
   function ViewMaxRect(view:OPView):OPRect;

   function AddObject(Obj, next: OPView):OPView;
   function NewRect(x1,y1,x2,y2:Integer):OPRect;



{*****************************************************************}
{+++        Costanti e procedure per gli Effetti Speciali      +++}
{*****************************************************************}
const
      NumeroPassi: word = 40;
      MakeSpecialEffect: boolean = true;
      Motion:boolean=true;

   procedure SpecialEffect(FromRect:OTRect; var toRect:OTRect);

{*****************************************************************}



   { Risorse bitmapped dell'interfaccia GOLIB. }
   procedure Golib_RESOURCES;


IMPLEMENTATION


   uses
        dispfile,
        applic;



   { Risorse bitmapped dell'interfaccia GOLIB. }
   procedure Golib_RESOURCES; external; {$L golib8.obj}


   const
          LookVideoPosOff:OPView=nil;


   type   PPointer = ^Pointer;

          PProc = ^TProc;
          TProc = procedure;

          {TCompositeRectRefresh = (rtPrec,rtNormal);}

          PNoteObjDeleted = ^TNoteObjDeleted;
          TNoteObjDeleted = record
             obj:pointer;
             next:PNoteObjDeleted;
          end;


   var
         PrecInitProc:pointer;
         PrecDoneProc:pointer;

         AddObj_First,           { Punta al primo oggetto creato con
                                   la funzione "AddObject"}
         AddObj_Last : OPView;   { Punta all'utimo oggetto creato con
                                   la funzione "AddObject" }

         {ObjectSelected:OPView;}

         Int00Save : Pointer;


   const
         {DEFINE GoodSpecialEffects}

         NoteObjDeleted: PNoteObjDeleted = nil;
         LastNote      : PNoteObjDeleted = nil;
         MessageDispatching: boolean = false;

{ ********************************************************************* }
{ +++       Procedure per l'inizializzazione della libreria.        +++ }
{ ********************************************************************* }


{$F+}
   procedure InitGOLIB;
     begin
       GolibPresent:=true;
       asm   { Disattiva il refresh della memoria video }
         MOV AH,12H
         MOV bl,36H
         MOV al,1
         INT 10H
       end;
       FullRect.Assign(0,0,_MaxXResolution,_MaxYResolution);
     { Inizializzazione dei vincoli per il gestore dell'evento di movimento degli
       oggetti. }
       EvMoveDirection:=All;
       EvMoveRange:=NullRect;
       ResetMouse;
       ShowMouseCursor;
       if PrecInitProc<>nil then TProc(PrecInitProc);

       InitDISPFILE;
     {$IFDEF Installa1Ch}
       InitMessageManager;
     {$ELSE}
       InitMessageManagerF3;
     {$ENDIF}
     end;


   procedure DoneGOLIB;
     begin
       {SetIntVec($00,Int00Save);}
       SetIntVec($09,Int09Save);

       DoneDISPFILE;

       HideMouseCursor;
       if PrecDoneProc<>nil then TProc(PrecDoneProc);
     end;
{$F-}


{ ************************************************************************* }
{ +++          Procedure per il refresh della Display-List.             +++ }
{ ************************************************************************* }


{ ********************************************************************* }
{ +++     Procedure di utilit… e di gestione dell'applicazione.     +++ }
{ ********************************************************************* }

   { VMP = Virtual Method Pointer }
   function GetVMP(VMT:pointer; NVMethod:word):pointer;
   assembler;
     asm
        mov    ax,NVMethod
        mov    cx,4
        mul    cl
        les    di,VMT
        add    di,ax
        les    di,DWORD PTR es:[di+4]
        mov    dx,es
        mov    ax,di
     end;


   procedure ClearDevice;
     begin
       HideMouseCursor;
       graph.cleardevice;
       ShowMouseCursor;
     end;


   procedure RestoreGolibGraphMode;
     begin
       RestoreGraphMode;
       disableVideo;
       RefreshDisplay;
       enableVideo;
       showmousecursor;
     end;


   procedure LookVideoOn;
     var punt:OPView;
     begin
       if not lookVideo then lookVideo:=true;
       if LookVideoPosOff=nil then punt:=ultimo
                              else punt:=LookVideoPosOff^._up_;
       while punt<>nil do begin
         punt^.disegna;
         punt:=punt^._up_;
       end;
     end;


   procedure LookVideoOff;
     begin
       if lookVideo then begin
         lookVideo:=false;
         LookVideoPosOff:=Primo;
       end;
     end;


var maxRect:OTRect;
   function ViewMaxRect(view:OPView):OPRect;
     var p:OPView;
     begin
       maxrect:=view^.r;
       p:=view^._Father_;
       while p<>nil do begin
         maxrect.Union(p^.r);
         p:=p^._Father_;
       end;
       ViewMaxRect:=@maxRect;
     end;


const Non_Analizzato:boolean=true;
   function AddObject(obj, next: OPView):OPView;
     begin
       if Non_Analizzato then begin
         AddObj_First:=obj;
         Non_Analizzato:=false;
       end;
       obj^._up_:=next;
       obj^._down_:=nil;
       if next=nil then begin
         Non_Analizzato:=true;
         AddObj_Last:=obj;
       end
       else next^._down_:=obj;
       AddObject:=obj;
     end;


   function NewRect(x1,y1,x2,y2:Integer):OPRect;
     var buf:OPRect;
     begin
       new(buf);
       buf^.assign(x1,y1,x2,y2);
       NewRect:=buf;
     end;


{*****************************************************************}
{+++             Procedure per gli Effetti Speciali.           +++}
{*****************************************************************}


   procedure SpecialEffect(FromRect:OTRect; var toRect:OTRect);
     var i:byte;
         prec:OTRect;
         x_m,y_m,passo:integer;
         p:OPView;
         passoX1,
         passoY1,
         passoX2,
         passoY2: real;
         _x1,_y1,
         _x2,_y2: real;
     begin
   { Animazione. }
       {hidemousecursor;}
       SetWriteMode(XorPut);
       SetColor(15);
       with FromRect do begin
         _x1:=x1;  _y1:=y1;
         _x2:=x2;  _y2:=y2;
         hidemousecursor;
         rectangle(x1,y1,x2,y2);
         showmousecursor;
         passoX1:=(toRect.x1-x1) / NumeroPassi;
         passoY1:=(toRect.y1-y1) / NumeroPassi;
         passoX2:=(toRect.x2-x2) / NumeroPassi;
         passoY2:=(toRect.y2-y2) / NumeroPassi;
       end;
       while (FromRect.x1<>toRect.x1) or
             (FromRect.y1<>toRect.y1) or
             (FromRect.x2<>toRect.x2) or
             (FromRect.y2<>toRect.y2) do begin
         prec:=FromRect;
         with FromRect do begin
           _x1:=_x1+passoX1;   x1:=round(_x1);
           _y1:=_y1+passoY1;   y1:=round(_y1);
           _x2:=_x2+passoX2;   x2:=round(_x2);
           _y2:=_y2+passoY2;   y2:=round(_y2);
           DimX:=x2-x1;
           DimY:=y2-y1;
           hidemousecursor;
           rectangle(x1,y1,x2,y2);
           showmousecursor;
         end;
         {Wait(0.01);}
       {$IFDEF GoodSpecialEffects}
         delay(5);
       {$ENDIF}
         if Motion then begin
           hidemousecursor;
           with prec do rectangle(x1,y1,x2,y2);
           showmousecursor;
         end;
       end;
       if Motion then begin
         hidemousecursor;
         with FromRect do rectangle(x1,y1,x2,y2);
         showmousecursor;
       end;
       SetWriteMode(NormalPut);
       {showmousecursor;}
     end;





{ *********************************************************************** }
{ +++        Inizio della definizione dei metodi degli oggetti        +++ }
{ *********************************************************************** }


                     { ----- OTRect ----- }
   procedure OTRect.Assign;
     begin
       x1:=a;
       y1:=b;
       x2:=c;
       y2:=d;
       Dimx:=c-a;
       DimY:=d-b;
     end;


   procedure OTRect.SetRect(x,y,dmX,dmY:longint);
     begin
       x1:=x;
       y1:=y;
       DimX:=dmX;
       DimY:=dmY;
       x2:=x1+DimX;
       y2:=y1+DimY;
     end;


   procedure OTRect.Union(var r:OTRect);
     begin
       if r.x1<x1 then x1:=r.x1;
       if r.x2>x2 then x2:=r.x2;
       if r.y1<y1 then y1:=r.y1;
       if r.y2>y2 then y2:=r.y2;
       Dimx:=x2-x1;
       DimY:=y2-y1;
     end;


   procedure OTRect.Move(x,y:longint);
     begin
       MoveRel(x-x1,y-y1);
     end;


   procedure OTRect.MoveRel(dx,dy:longint);
     begin
       inc(x1,dx);
       inc(x2,dx);
       inc(y1,dy);
       inc(y2,dy);
     end;



   function OTRect.Intersect;
     begin
       if x1<r.x1 then ris.x1:=r.x1
                  else ris.x1:=x1;
       if y1<r.y1 then ris.y1:=r.y1
                  else ris.y1:=y1;
       if x2<r.x2 then ris.x2:=x2
                  else ris.x2:=r.x2;
       if y2<r.y2 then ris.y2:=y2
                  else ris.y2:=r.y2;
       with ris do begin
         if (x2<x1) or (y2<y1) then Intersect:=false
                               else Intersect:=true;
         Dimx:=x2-x1;
         DimY:=y2-y1;
       end;
     end;


   function OTRect.IntersectViewPort(var v:ViewPortType; var ris: OTRect):boolean;
     begin
       if x1<v.x1 then ris.x1:=v.x1
                  else ris.x1:=x1;
       if y1<v.y1 then ris.y1:=v.y1
                  else ris.y1:=y1;
       if x2<v.x2 then ris.x2:=x2
                  else ris.x2:=v.x2;
       if y2<v.y2 then ris.y2:=y2
                  else ris.y2:=v.y2;
       with ris do begin
         if (x2<x1) or (y2<y1) then IntersectViewPort:=false
                               else IntersectViewPort:=true;
         Dimx:=x2-x1;
         DimY:=y2-y1;
       end;
     end;


   function OTRect.DifferenceWith(var r:OTRect):PRefreshRectList;
     var piano2,
         piano1:OTView;
         precStopESP:boolean;
     begin
       precStopESP:=StopESP;
       piano2.Init(Null_ID,r);
       piano1.Init(Null_ID,self);
       piano1._up_:=@piano2;
       DifferenceWith:=GetLightListof(@piano1,nil,NullObj);
       piano2.Done;
       piano1.Done;
       StopESP:=precStopESP;
     end;


   function OTRect.RectIn;
     begin
       RectIn:=Intersect(r,r);
     end;


   procedure OTRect.GetRect;
     begin
       r.x1:=x1;
       r.y1:=y1;
       r.x2:=x2;
       r.y2:=y2;
       r.DimX:=DimX;
       r.DimY:=DimY;
     end;


   { Questa andrebbe meglio a livello di MACRO. }
   function OTRect.XYIn(x,y:longint):boolean;
     begin
       if (x>=x1) and (x<=x2) and (y>=y1) and (y<=y2) then XYIn:=true
                                                      else XYIn:=false;
     end;


   { Questa andrebbe meglio a livello di MACRO. }
   function OTRect.Zero:boolean;
     begin
       if (x1=0) and (x2=0) and (y1=0) and (y2=0)
         then Zero:=true
         else Zero:=false;
     end;


   function OTRect.Equal(var r:OTRect):boolean;
     begin
       if (x1=r.x1) and (y1=r.y1) and (x2=r.x2) and (y2=r.y2)
         then Equal:=true
         else Equal:=false;
     end;


                       {----- OTMouseRect -----}
   procedure OTMouseRect.Make;
     begin
       x1:=mcx-_HotX_-32;
       y1:=mcy-_HotY_-32;
       DimX:=64;
       DimY:=64;
       x2:=x1+DimX;
       y2:=y1+DimY;
     end;


                         {----- OTRects -----}
   procedure OTRects.ResetList;
     begin
       rect.assign(0,0,0,0);
       succ:=nil;
       last:=nil;
     end;


   procedure OTRects.newRect(var r:OTRect);
     var buf:OPRects;
     begin
       if rect.Zero then rect:=r
       else begin
         if last=nil then begin
           new(last);
           succ:=last;
         end
         else begin
           new(last^.succ);
           last:=last^.succ;
         end;
         last^.rect:=r;
         last^.succ:=nil;
       end;
     end;


   procedure OTRects.CopyListFrom(list:OPRects);
     begin
       ResetList;
       while list<>nil do begin
         newRect(list^.rect);
         list:=list^.succ;
       end;
     end;


   procedure OTRects.DisposeList;
     var buf:OPRects;
     begin
       while succ<>nil do begin
         buf:=succ^.succ;
         dispose(succ);
         succ:=buf;
       end;
       succ:=nil;
       last:=nil;
       rect.assign(0,0,0,0);
     end;


                { ------  OTView  ------ }
   constructor OTView.Init(_ID:word;var coord:OTRect);
     begin
       if not inherited Init then fail;
       { Inizializzazione dei puntatori }
       _Father_:=nil;
       _gruppo_:=nil;
       _last_:=nil;
       _up_:=nil;
       _down_:=nil;
       { Configurazione passiva dell'oggetto }
       SysConfig:=cfStartupObj;
       ID:=_ID;
       R:=coord;
       precR:=R;
       _CancBar_:=DefaultCancBar;
       PrefRefresh:=FIFO;
       MinDimX:=1;
       MinDimY:=1;
       CursorID:=0;
       HotSpotsResID:=0;
       SubObjSelected:=nil;
       MouseReactionMask:=rcStandardMouseMask;
     end;


   constructor OTView.InitComposite(_ID:word;var coord:OTRect; objs:OPView);
     begin
       if not inherited Init then fail;
       { Inizializzazione dei puntatori }
       _Father_:=nil;
       _up_:=nil;
       _down_:=nil;
       { Configurazione passiva dell'oggetto }
       SysConfig:=cfStartupObj or cfScanGroup;;
       ID:=_ID;
       R:=coord;
       precR:=R;
       _CancBar_:=DefaultCancBar;
       PrefRefresh:=FIFO;
       MinDimX:=1;
       MinDimY:=1;
       CursorID:=0;
       HotSpotsResID:=0;
       SubObjSelected:=nil;
       AssignGroup(objs);
     end;


   destructor OTView.Done;
     var buf:OPView;
         lk:boolean;
     begin
       ID:=_OBJ_DELETING_;
       { Elimina l'eventuale sub-list. }
       if _gruppo_<>nil then begin
         lk:=lookvideo;
         lookVideo:=false;
         buf:=_gruppo_;
         repeat
           _gruppo_:=buf^._down_;
           if Seg(buf^)=DSeg then buf^.Done
                             else dispose(buf,done);
           buf:=_gruppo_;
         until buf=nil;
         lookVideo:=lk;
       end;
       { Se l'oggetto si trova nella lista principale, cioŠ se si trova
         sul Desktop allora procede alla sua rimozione da tale lista, altrimenti
         non fa nulla. }
       if (SysConfig and cfOnDeskTop)<>0 then begin
         if lookVideo then begin
           HideMouseCursor;
           RefreshRect(r,_down_,GetLightListOf(@Self,nil,NullObj));;
           ShowMouseCursor;
         end;
         if primo=ultimo then begin
           primo:=nil;
           ultimo:=nil;
         end
         else begin
           if _up_<>nil then _up_^._down_:=_down_
                        else primo:=_down_;
           if _down_<>nil then _down_^._up_:=_up_
                          else ultimo:=_up_;
         end;
       end;
       if ESP then StopESP:=true;
       if not ShutDownExecuting and (ObjectSelected=@Self) then begin
         buf:=primo;
         while (buf<>nil) and
               ((buf^.SysConfig and cfSelectable)=0) do buf:=buf^._down_;
         if buf<>nil then buf^.Select;
         ObjectSelected:=buf;
       end;
       if MessageDispatching then begin
         { Notificazione della cancellazione dell'oggetto }
         if LastNote=nil then begin
           new(LastNote);
           NoteObjDeleted:=LastNote;
         end
         else begin
           new(LastNote^.next);
           LastNote:=LastNote^.next;
         end;
         LastNote^.obj:=@Self;
         LastNote^.next:=nil;
       end;
       { Chiama il distruttore padre }
       inherited Done;
     end;


   procedure OTView.DestroySubList;
     var buf:OPView;
         lk:boolean;
     begin
       if _gruppo_<>nil then begin
         lk:=lookvideo;
         lookVideo:=false;
         buf:=_gruppo_;
         repeat
           buf^.Done;
           buf:=buf^._down_;
         until buf=nil;
         lookVideo:=lk;
       end;
       _gruppo_:=nil;
     end;


   procedure OTView.PutOnDeskTop;
     begin
       if (SysConfig and cfOnDesktop)<>0 then exit;
       SysConfig:=SysConfig or cfOnDeskTop;
       if primo=nil then begin
         primo:=@Self;
         ultimo:=@Self;
         _down_:=nil;
         _up_:=nil;
       end
       else begin
         {if (SysConfig and cfSelectable)<>0
           then if ObjectSelected<>nil then ObjectSelected^.Deselect;}
         PutObjectOverTheTop;
       end;
       {if (SysConfig and cfSelectable)<>0 then ObjectSelected:=@Self;}
       SysConfig:=SysConfig or cfVisible;
       if lookVideo then begin
         HideMouseCursor;
         Disegna;
         ShowMouseCursor;
       end;
       if (SysConfig and cfSelectable)<>0 then Select;
     end;


   procedure OTView.Disegna;
     var view:ViewPortType;
         ris:OTRect;
     begin
       if _gruppo_<>nil then begin
         if MouseIn then HideMouseCursor;
         if RefreshProcessing
           then begin
             GetViewSettings(view);
             precR.IntersectViewPort(view,ris);
             RefreshRect(ris,_gruppo_,NullObj);
           end
           else RefreshRect(R,_gruppo_,NullObj);
         if MouseIn then ShowMouseCursor;
       end
       else begin
         setfillstyle(1,0);
         bar(r.x1,r.y1,r.x2,r.y2);
       end;
     end;


   procedure OTView.DisegnaXY(x,y:integer);
     begin
       precR:=r;

       r.x2:=r.x2-r.x1+x;
       r.y2:=r.y2-r.y1+y;
       r.x1:=x;
       r.y1:=y;

       if MouseIn then HideMouseCursor;
       Disegna;
       if MouseIn then ShowMouseCursor;

       r:=precR;
     end;


   procedure OTView.Refresh;
     begin
       if lookvideo then begin
         hidemousecursor;
         RefreshRect(R,@Self,GetVisibleZone(@Self,nil,NullObj));
         showmousecursor;
       end;
     end;


   function OTView.Resize(_r:OTRect):boolean;
     var bufV:OPView;
         lk:boolean;
         LastDx,LastDy:integer;
         BeforeResizing:OTRect;
     begin
       with _r do begin
         if DimX<MinDimX then begin
           DimX:=MinDimX;
           x2:=x1+DimX;
         end;
         if DimY<MinDimY then begin
           DimY:=MinDimY;
           y2:=y1+DimY;
         end;
       end;
       with _r do if (x1=r.x1)  and
                     (x2=r.x2)  and
                     (y1=r.y1)  and
                     (y2=r.y2)  then Resize:=false
       else begin
         LastDx:=_r.x1-r.x1;
         LastDy:=_r.y1-r.y1;
         precR:=R;
         BeforeResizing:=R;
         r:=_r;
         {if (SysConfig and cfITLF)=cfITLF then}
         if (_gruppo_<>nil) and ((LastDX<>0) or (LastDY<>0)) then begin
           lk:=lookvideo;
           lookvideo:=false;
           bufV:=_gruppo_;
           while bufV<>nil do begin
             bufV^.MoveRel(LastDX,LastDY);
             bufV:=bufV^._down_;
           end;
           lookvideo:=lk;
         end;
         Adjust;
         if lookvideo then begin
           HideMouseCursor;
           RefreshRect(R,@Self,GetLightListOf(@Self,nil,NullObj));
           if _down_=nil then begin
             New(BufV);
             bufV^._up_:=@Self;
             with BeforeResizing do begin
               if x1<0 then x1:=0;
               if y1<0 then y1:=0;
             end;
             RefreshRect(R,_down_,GetLightListOf(bufV,@BeforeResizing,NullObj));
             dispose(bufV);
           end
           else RefreshRect(R,_down_,GetLightListOf(_down_,@BeforeResizing,NullObj));
           ShowMouseCursor;
         end;
       end;
     end;


   procedure OTView.Adjust;
     var bufV:OPView;
         LastDx,LastDy:integer;
     begin
       LastDx:=R.x1-precR.x1;
       LastDy:=R.y1-precR.y1;
       if (LastDx<>0) and (LastDy<>0) and (_gruppo_<>nil) then begin
         bufV:=_gruppo_;
         while bufV<>nil do begin
           bufV^.MoveRel(LastDx,LastDy);
           bufV:=bufV^._down_;
         end;
       end;
     end;


   procedure OTView.SetLimitSize(DimX,DimY:word);
     var __adjust:boolean;
         newRect:OTRect;
     begin
       MinDimX:=DimX;
       MinDimY:=DimY;
       if DimX>r.DimX then begin
         __adjust:=true;
         newRect.DimX:=DimX;
       end
       else NewRect.DimX:=r.DimX;
       if DimY>r.DimY then begin
         __adjust:=true;
         newRect.DimY:=DimY;
       end
       else NewRect.DimY:=r.DimY;
       if __adjust then begin
         with NewRect do begin
           x1:=r.x1;
           y1:=r.y1;
           x2:=x1+DimX;
           y2:=y1+DimY;
         end;
         Resize(newRect);
       end;
     end;


   procedure OTView.GetLimitSize(var DimX,DimY:word);
     begin
       DimX:=MinDimX;
       DimY:=MinDimY;
     end;


   procedure OTView.Move(x,y:integer);
     begin
       MoveRel(x-r.x1,y-r.y1);
     end;


   procedure OTView.MoveRel(dx,dy:integer);
     var bufV:OPView;
         _bufVR,
         BeforeDrawing:OTRect;
         _lk,variato:boolean;
         ShadowList,
         LightList,
         FirstSHDW,
              SHDW,
             _SHDW: PRefreshRectList;
         mth:byte;
         da_x1,da_y1:integer;
         MouseRect:OTMouseRect;

     procedure Adjust_bufVR;
       begin
         _bufVR:=BeforeDrawing;
         variato:=false;
         mth:=0;
         with _bufVR do begin
           if x1<0 then begin
             DimX:=DimX+x1;
             x1:=0;
             variato:=true;
             mth:=mth or $10;
           end;

           if y1<0 then begin
             DimY:=DimY+y1;
             y1:=0;
             variato:=true;
             mth:=mth or $20;
           end;

           if x1+DimX>_MaxXResolution then begin
             DimX:=_MaxXResolution-x1;
             variato:=true;
             mth:=mth or $01;
           end;

           if y1+DimY>_MaxYResolution then begin
             DimY:=_MaxYResolution-y1;
             variato:=true;
             mth:=mth or $02;
           end;

           x2:=x1+DimX;
           y2:=y1+DimY;
         end;
       end;

     begin
       if (dx=0) and (dy=0) then exit;
       if lookvideo and (_up_<>nil) then
         ShadowList:=GetShadowListOf(@Self,nil);
       precR:=R;
       BeforeDrawing:=R;
       with r do begin
         inc(x1,dx);
         inc(x2,dx);
         inc(y1,dy);
         inc(y2,dy);
       end;
       if _gruppo_<>nil then begin
         _lk:=lookvideo;
         lookvideo:=false;
         bufV:=_gruppo_;
         while bufV<>nil do begin
           bufV^.MoveRel(dx,dy);
           bufV:=bufV^._down_;
         end;
         lookvideo:=_lk;
       end;
       if lookvideo and ((SysConfig and cfVisible)=cfVisible) then begin
         PositionAndButtonStatus;
         MouseRect.Make;
         MouseIn:=precR.RectIn(MouseRect) or r.RectIn(MouseRect);
         if MouseIn then HideMouseCursor;
         if (SysConfig and cfBitBtl)=0
         then DrawRefreshRectList(GetVisibleZone(@Self,nil,NullObj),@Self)
         else begin
           { Spostamento bitmap }
           if _up_=nil
           then BitBtlVideoDC(precR.x1,precR.y1,r.x1,r.y1,r.DimX+1,r.DimY+1)
           else begin
             LightList:=GetLightListOf(@Self,nil,NullObj);

             SHDW:=LightList;
             while SHDW<>nil do begin
               SHDW^.r.MoveRel(-dx,-dy);
               SHDW:=SHDW^.succ;
             end;
             LightList:=GetLightListOf(@Self,nil,LightList);
             SHDW:=LightList;
             while SHDW<>nil do begin
               SHDW^.r.MoveRel(dx,dy);
               SHDW:=SHDW^.succ;
             end;

             SHDW:=ShadowList;
             while SHDW<>nil do begin
               SHDW^.r.MoveRel(dx,dy);
               SHDW:=SHDW^.succ;
             end;
             ShadowList:=GetLightListOf(@Self,nil,ShadowList);
          { Determinazione del tipo di ordinamento da effettuare nella lista. }
             { MTH sar… cos strutturato:
               bit 1 = 0 se lo shif della X Š verso sinistra
                     = 1 se lo shif della X Š verso destra
               bit 0 = 0 se lo shif della Y Š verso sopra
                     = 1 se lo shif della Y Š verso sotto
             }
             mth:=0;
             if R.x1>precR.x1 then mth:=mth or $02;
             if R.y1>precR.y1 then mth:=mth or $01;
             { Ordinamento della lista. }
             SortRefreshRectList(LightList,TSortingMethod(mth));
             while LightList<>nil do begin
               with LightList^.r do begin
                 da_x1:=precR.x1+(x1-R.x1);
                 da_y1:=precR.y1+(y1-R.y1);
                 BitBtlVideoDC(da_x1,da_y1,x1,y1,x2-x1+1,y2-y1+1);
               end;
               SHDW:=LightList;
               LightList:=LightList^.succ;
               dispose(SHDW);
             end;
             DrawRefreshRectList(ShadowList,@Self);
           end;
           Adjust_bufVR;
           if variato then begin
             case mth of
             $10,$20,$30: _bufVR.MoveRel(r.x2-_bufVR.x1-_bufVR.DimX,r.y2-_bufVR.y1-_bufVR.DimY);
             $01,$02,$03: _bufVR.MoveRel(r.x1-_bufVR.x1,r.y1-_bufVR.y1);
             $21        : _bufVR.MoveRel(r.x1-_bufVR.x1,r.y2-_bufVR.y1-_bufVR.DimY);
             $12        : _bufVR.MoveRel(r.x2-_bufVR.x1-_bufVR.DimX,r.y1-_bufVR.y1);
             end;
             with _bufVR do begin
               if x1<0 then x1:=r.x1;
               if y1<0 then y1:=r.y1;
               if x2>_MaxXResolution then x2:=r.x2;
               if y2>_MaxYResolution then y2:=r.y2;
               DimX:=x2-x1;
               DimY:=y2-y1;
             end;
             if not _bufVR.Zero and (_bufVR.DimX>0) and (_bufVR.DimY>0) then begin
               new(FirstSHDW);
               FirstSHDW^.r:=r;
               FirstSHDW^.succ:=nil;
               _SHDW:=FirstSHDW;
                SHDW:=FirstSHDW;
               Frammenta(FirstSHDW,_SHDW,SHDW,_bufVR);
               DrawRefreshRectList(GetLightListOf(@Self,nil,FirstSHDW),@Self);
             end;
           end;
         end;
         if _down_=nil then begin
           New(BufV);
           bufV^._up_:=@Self;
           bufV^._Father_:=nil;
           with BeforeDrawing do begin
             if x1<0 then x1:=0;
             if y1<0 then y1:=0;
           end;
           RefreshRect(NullRect,_down_,GetVisibleZone(bufV,@BeforeDrawing,NullObj));
           dispose(bufV);
         end
         else RefreshRect(NullRect,_down_,GetVisibleZone(_down_,@BeforeDrawing,NullObj));
         if MouseIn then ShowMouseCursor;
       end;
     end;


   procedure OTView.Hide;
     begin
       if (SysConfig and cfVisible)<>cfVisible then exit;
       SysConfig:=SysConfig and __cfVisible;
       if lookvideo then RefreshRect(r{Par.Ignorato},_down_,GetLightListOf(@Self,nil,NullObj));
     end;


   procedure OTView.Show;
     begin
       if (SysConfig and cfVisible)=cfVisible then exit;
       SysConfig:=SysConfig or cfVisible;
       if ((SysConfig and cfAlwaysAsFirst)=0) and
          (_down_<>nil) and
          ((_down_^.SysConfig and cfAlwaysAsFirst)<>0)
       then begin
         { Sganciamento dell'oggetto dalla lista. }
         if _down_<>nil then _down_^._up_:=_up_
                        else ultimo:=_up_;
         if _up_<>nil then _up_^._down_:=_down_
                      else primo:=_down_;
         PutObjectOverTheTop;
       end;
       if lookvideo then RefreshRect(r,@Self,GetLightListOf(@Self,nil,NullObj));
     end;


   procedure OTView.Select;
     var buf:^OPView;
         obj:OPView;
     begin
       if (SysConfig and cfSelectable)=0 then exit;
       if _Father_<>nil
         then buf:=@_Father_^.SubObjSelected
         else buf:=@ObjectSelected;
       obj:=buf^;
       buf^:=@Self;
       if (obj<>nil) and (obj^.ID<>_OBJ_DELETING_) then obj^.Deselect;
     end;


   procedure OTView.Deselect;
     var buf:^OPView;
         obj:OPView;
     begin
       if _Father_<>nil
         then buf:=@_Father_^.SubObjSelected
         else buf:=@ObjectSelected;
       if buf^=@Self then begin
         { Caso di deselezione esplicita, cioŠ non conseguente ad una
           selezione. }

         { Ricerca dell'oggetto da selezionare al posto di Self }
         obj:=_down_;
         while (obj<>nil) and ((obj^.SysConfig and cfSelectable)=0) do
           obj:=obj^._down_;
         if obj=nil then begin
           if _Father_<>nil then obj:=_Father_^._gruppo_
                            else obj:=Primo;
           while (obj<>@Self) and ((obj^.SysConfig and cfSelectable)=0) do
             obj:=obj^._down_;
         end;
         { Se non Š stato trovato nessun oggetto selezionabile automaticamente
           allora obj=@Self }
         if (obj<>@Self) and (obj^.ID<>_OBJ_DELETING_) then obj^.Select;
       end;
     end;


   procedure OTView.Enable;
     var buf:OPView;
         lk:boolean;
     begin
       if (SysConfig and cfEnable)<>0 then exit;
       SysConfig:=SysConfig or cfEnable;
       lk:=lookvideo;
       lookvideo:=false;
       if _gruppo_<>nil then begin
         buf:=_gruppo_;
         while buf<>nil do begin
           buf^.Enable;
           buf:=buf^._down_;
         end;
       end;
       lookvideo:=lk;
       {if lookvideo then DrawRefreshListProc(GetVisibleZone(@Self,nil,NullObj),@Self,GetVMP(typeOf(Self),VMI_Disegna));}
       if lookvideo then DrawRefreshRectList(GetVisibleZone(@Self,nil,NullObj),@Self);
     end;


   procedure OTView.Disable;
     var buf:OPView;
         lk:boolean;
     begin
       if (SysConfig and cfEnable)=0 then exit;
       SysConfig:=SysConfig and __cfDisable;
       lk:=lookvideo;
       lookvideo:=false;
       if _gruppo_<>nil then begin
         buf:=_gruppo_;
         while buf<>nil do begin
           buf^.Disable;
           buf:=buf^._down_;
         end;
       end;
       lookvideo:=lk;
       {if lookvideo then DrawRefreshListProc(GetVisibleZone(@Self,nil,NullObj),@Self,GetVMP(typeOf(Self),VMI_Disegna));}
       if lookvideo then DrawRefreshRectList(GetVisibleZone(@Self,nil,NullObj),@Self);
     end;


   procedure OTView.PutOnFirst;
     var ShadowList:pointer;
     begin
       { Attivazione dell'oggetto corrente }
       {Select;}
       { Questa procedure funziona solo per gli oggetti che appartengono
         alla Root della lista e se l'oogetto non Š unico. }
       if (@Self<>primo) and
          (@Self<>NullObj) and
          ((_down_<>nil) or (_up_<>nil))
       then begin
         ShadowList:=GetShadowListOf(@Self,nil);
         { Sganciamento dell'oggetto dalla lista. }
         if _down_<>nil then _down_^._up_:=_up_
                        else ultimo:=_up_;
         if _up_<>nil then _up_^._down_:=_down_;
         PutObjectOverTheTop;
         HideMouseCursor;
         DrawRefreshRectList(GetLightListOf(@Self,nil,ShadowList),@Self);
         ShowMouseCursor;
       end;
       {if ((SysConfig and cfSelectable)<>0) and
          (ObjectSelected<>@Self) then begin
         ObjectSelected^.Deselect;
         ObjectSelected:=@Self;
       end;}
     end;


   function OTView.UniqueInList:boolean;
     begin
       if (_down_=nil) and (_up_=nil) then UniqueInList:=true
                                      else UniqueInList:=false;
     end;


   procedure OTView.LinkTo(obj:OPView);
     begin
       if obj=nil then exit;
       _down_:=obj;
       obj^._up_:=@Self;
     end;


   procedure OTView.ExecMessage(var Message:TMessage);
     var Msg:TMessage;
     begin
       Msg:=Message;
       Msg.HNDL:=ID;
       Msg.Message:=ID;
       SendMessage(Msg);
     end;


   procedure OTView.SendMessage(var Message:TMessage);
     begin
       if _Father_<>nil then _Father_^.DispatchMessage(Message);
     end;


const
     FirstCallMemo:pointer=nil;

   procedure OTView.DispatchMessage(var Message:TMessage);
     var p:PNoteObjDeleted;
         dead:boolean;
         precSelf:pointer;
     begin
       if Message.Message=Null_ID then exit;
       if _Father_=nil then begin
         ExecMessage(Message);
         exit;
       end;
       if FirstCallMemo=nil then begin
         FirstCallMemo:=@Self;
         MessageDispatching:=true;
       end;
       precSelf:=@Self;
       _Father_^.DispatchMessage(Message);
       { Controllo sull'esistenza di Self }
       dead:=false;
       p:=NoteObjDeleted;
       while not dead and (p<>nil) do begin
          dead:= p^.obj=precSelf;
          p:=p^.next;
       end;
       if not (StopESP or dead) then ExecMessage(Message);
       if FirstCallMemo=@Self then begin
         {Cancellazione delle notificazioni di cancellazione }
         while NoteObjDeleted<>nil do begin
           p:=NoteObjDeleted^.next;
           dispose(NoteObjDeleted);
           NoteObjDeleted:=p;
         end;
         LastNote:=nil;
         MessageDispatching:=false;
         FirstCallMemo:=nil;
       end;
     end;


{DEFINE PlusLineMotion}
{DEFINE RealTimeMotion}

   procedure OTView.EvMoveObject(mcx,mcy:integer);
     var p_mcx,p_mcy:word;
         cxrel,cyrel:integer;
         _ok_,
         ctrl,
         precStopESP:boolean;
         NewRect ,
         PrecRect,
         RealPrecR:OTRect;
         view:ViewPortType;
         Message:TMessage;

     {$IFDEF PlusLineMotion}
     procedure DrawNewRect;
       begin
         with NewRect do begin
           setlinestyle(1,0,1);
           line(r.x1,r.y1,x1,y1);
           line(r.x1,r.y2,x1,y2);
           line(r.x2,r.y1,x2,y1);
           line(r.x2,r.y2,x2,y2);
           setlinestyle(0,0,1);
           rectangle(x1,y1,x2,y2);
         end;
       end;

     procedure DrawPrecRect;
       begin
         with precRect do begin
           setlinestyle(1,0,1);
           line(r.x1,r.y1,x1,y1);
           line(r.x1,r.y2,x1,y2);
           line(r.x2,r.y1,x2,y1);
           line(r.x2,r.y2,x2,y2);
           setlinestyle(0,0,1);
           rectangle(x1,y1,x2,y2);
         end;
       end;
     {$ENDIF}

     begin
       { Impostazione messaggio da mandare durante la fase di movimento
         all'oggetto che Š in movimento. }
       Message.HNDL:=ID;
       Message.Message:=EvMOUSE_L_PRESSED;

       {$IFNDEF RealTimeMotion}
       setcolor(15);
       setwritemode(xorput);
       {$ENDIF}
       setfullport;
       p_mcx:=mcx;
       p_mcy:=mcy;
       cxrel:=mcx-r.x1;
       cyrel:=mcy-r.y1;
       hideMouseCursor;
       NewRect:=R;
       PrecRect:=R;
       asm
         LEA DI,EvMoveRange
         LEA SI,NullRect
         MOV AX,SEG @Data
         MOV ES,AX
         MOV CX,5
         REPE CMPSW
         JZ  @001
         MOV ctrl,true
         JMP @002
       @001:
         MOV ctrl,false
       @002:
       end;
       {$IFNDEF RealTimeMotion}
       rectangle(r.x1,r.y1,r.x2,r.y2);
       {$ENDIF}
       showMouseCursor;
       RealPrecR:=R;
       asm      { Se Š ancora premuto un tasto allora     _ok_:=false  }
         MOV AX,3                          {   altrimenti _ok_:=true   }
         INT 33H
         CMP BX,0
         JNE @001
         MOV _ok_,true
         JMP @002
       @001:
         MOV _ok_,false
       @002:
       end;
       while Message.Message<>EvMOUSE_L_RELEASED do begin
         if (p_mcx<>mcx) or (p_mcy<>mcy) then begin
           case EvMoveDirection of
           All  : NewRect.SetRect(mcx-cxrel,  mcy-cyrel,
                                  r.dimx,     r.dimy);
           Vert : NewRect.assign(r.x1, mcy-cyrel,
                                 r.x2, mcy-cyrel+r.dimy);
           Horiz: NewRect.assign(mcx-cxrel,        r.y1,
                                 mcx-cxrel+r.dimx, r.y2);
           end;
           if MovimentMode8 then with NewRect do begin
             x1:=x1-(x1 mod 8);
             x2:=x1+DimX;
           end;
           if ctrl then with EvMoveRange do begin
             if EvMoveDirection<>Vert then begin
               if NewRect.x1<x1 then begin
                 NewRect.x1:=x1;
                 NewRect.x2:=NewRect.x1+NewRect.DimX;
               end;
               if NewRect.x2>x2 then begin
                 NewRect.x2:=x2;
                 NewRect.x1:=NewRect.x2-NewRect.DimX;
               end;
             end;
             if EvMoveDirection<>Horiz then begin
               if NewRect.y1<y1 then begin
                 NewRect.y1:=y1;
                 NewRect.y2:=NewRect.y1+NewRect.DimY;
               end;
               if NewRect.y2>y2 then begin
                 NewRect.y2:=y2;
                 NewRect.y1:=NewRect.y2-NewRect.DimY;
               end;
             end;
             if (NewRect.x1<>PrecRect.x1) or (NewRect.y1<>PrecRect.y1) then begin
               hidemousecursor;
               {$IFNDEF RealTimeMotion}
                 {$IFDEF PlusLineMotion}
                 DrawNewRect;
                 DrawPrecRect;
                 {$ELSE}
                 with NewRect do rectangle(x1,y1,x2,y2);
                 with PrecRect do rectangle(x1,y1,x2,y2);
                 {$ENDIF}
               {$ELSE}
               SetViewPort(0,0,_MaxXResolution,_MaxYResolution,false);
               move(NewRect.x1,NewRect.y1);
               {$ENDIF}
             end
           end
           else begin
             if (NewRect.x1<>PrecRect.x1) or
                (NewRect.y1<>PrecRect.y1) then begin
               hidemousecursor;
               {$IFNDEF RealTimeMotion}
                 {$IFDEF PlusLineMotion}
                 DrawNewRect;
                 DrawPrecRect;
                 {$ELSE}
                 with NewRect do rectangle(x1,y1,x2,y2);
                 with PrecRect do rectangle(x1,y1,x2,y2);
                 {$ENDIF}
               {$ELSE}
               SetViewPort(0,0,_MaxXResolution,_MaxYResolution,false);
               move(NewRect.x1,NewRect.y1);
               {$ENDIF}
             end;
           end;
         end;
         showmousecursor;
         if (NewRect.x1<>PrecRect.x1) or
            (NewRect.y1<>PrecRect.y1) then begin
            PrecRect:=NewRect;
            R:=NewRect;
            Message.HNDL:=ID;
            Message.Message:=ID;

            precStopESP:=StopESP;
            SendMessage(Message);
            StopESP:=precStopESP;

            { Ripristino dei parametri di scrittura che potrebbero essere stati
              modificati nell'esecuzione del metodo SendMessage }
            SetWriteMode(XorPut);
            SetColor(15);
         end;
         p_mcx:=mcx;
         p_mcy:=mcy;
         WaitNextMouseMessage(Message, rcMove or
                                       rcLPressed or
                                       rcLReleased);
         mcx:=Message.Mcx;
         mcy:=Message.Mcy;
       end; { while }
       {$IFNDEF RealTimeMotion}
       hidemousecursor;
       R:=RealPrecR;
       if _ok_ and ((NewRect.x1<>r.x1) or (NewRect.y1<>r.y1)) then rectangle(r.x1,r.y1,r.x2,r.y2);
       if (NewRect.x1<>r.x1) or (NewRect.y1<>r.y1) then begin
         {$IFDEF PlusLineMotion}
         DrawPrecRect;
         {$ELSE}
         with PrecRect do rectangle(x1,y1,x2,y2);
         {$ENDIF}
         setwritemode(NormalPut);
         SetViewPort(0,0,_MaxXResolution,_MaxYResolution,false);
         move(NewRect.x1,NewRect.y1);
       end
       else rectangle(r.x1,r.y1,r.x2,r.y2);
       setwritemode(Normalput);
       showmousecursor;
       {$ENDIF}
     end;


   procedure OTView.EvDimObject(mcx,mcy:integer);
     var p_mcx,p_mcy:word;
         cxrel,cyrel:integer;
         _ok_,
         precStopESP:boolean;
         rect:OTRect;
         PrecRect, NewRect:OTRect;
         Message:TMessage;

     begin
       { Impostazione messaggio da mandare durante la fase di dimensionamento
         all'oggetto che Š in fase di dimensionamento. }
       Message.HNDL:=ID;
       Message.Message:=EvMOUSE_L_PRESSED;

       rect:=r;
       PrecRect:=r;
       NewRect:=r;
       setcolor(15);
       setwritemode(xorput);
       setfullport;
       p_mcx:=mcx;
       p_mcy:=mcy;
       cxrel:=mcx-r.x1;
       cyrel:=mcy-r.y1;
       DefineCursorRange(r.x1+MinDimX-r.x2+mcx, r.y1+MinDimY-r.y2+mcy,
                         _MaxXResolution      , _MaxYResolution);
       hideMouseCursor;
       rectangle(r.x1,r.y1,r.x2,r.y2);
       showMouseCursor;
       asm      { Se Š ancora premuto un tasto allora     _ok_:=false  }
         MOV AX,3                          {   altrimenti _ok_:=true   }
         INT 33H
         CMP BX,0
         JNE @001
         MOV _ok_,true
         JMP @002
       @001:
         MOV _ok_,false
       @002:
       end;
       while Message.Message<>EvMOUSE_L_RELEASED do begin
         if (p_mcx<>mcx) or (p_mcy<>mcy) then begin
           NewRect.assign(rect.x1            , rect.y1,
                          mcx-cxrel+r.dimx   , mcy-cyrel+r.dimy);
         end;
         if (NewRect.DimX<>PrecRect.DimX) or
            (NewRect.DimY<>PrecRect.DimY) then begin
           hidemousecursor;
           with NewRect do begin
             {$IFDEF PlusLineMotion}
             setlinestyle(1,0,1);
             line(r.x2,r.y2,x2,y2);
             setlinestyle(0,0,1);
             {$ENDIF}
             rectangle(x1,y1,x2,y2);
           end;
           with PrecRect do begin
             {$IFDEF PlusLineMotion}
             setlinestyle(1,0,1);
             line(r.x2,r.y2,x2,y2);
             setlinestyle(0,0,1);
             {$ENDIF}
             rectangle(x1,y1,x2,y2);
           end;
           showmousecursor;
           PrecRect:=NewRect;
           Message.HNDL:=ID;
           Message.Message:=ID;

           precStopESP:=StopESP;
           SendMessage(Message);
           StopESP:=precStopESP;

           { Ripristino dei parametri di scrittura che potrebbero essere stati
             modificati nell'esecuzione del metodo SendMessage }
           SetWriteMode(XorPut);
           SetColor(15);
         end;
         p_mcx:=mcx;
         p_mcy:=mcy;
         WaitNextMouseMessage(Message, rcMove or
                                       rcLPressed or
                                       rcLReleased);
         mcx:=Message.Mcx;
         mcy:=Message.Mcy;
       end;
       hidemousecursor;
       if _ok_ and ((mcx-cxrel<>r.x1) or (mcy-cyrel<>r.y1)) then rectangle(r.x1,r.y1,r.x2,r.y2);
       if (mcx-cxrel<>r.x1) or (mcy-cyrel<>r.y1) then begin
         {$IFDEF PlusLineMotion}
         setlinestyle(1,0,1);
         line(r.x2,r.y2,p_mcx-cxrel+r.dimx,p_mcy-cyrel+r.dimy);
         setlinestyle(0,0,1);
         {$ENDIF}
         rectangle(rect.x1,rect.y1,
                   p_mcx-cxrel+r.dimx,p_mcy-cyrel+r.dimy);
         setwritemode(normalput);
         with rect do begin
           x2:=p_mcx-cxrel+r.dimx;
           y2:=p_mcy-cyrel+r.dimy;
           DimX:=x2-x1;
           DimY:=y2-y1;
         end;
         resize(rect);
       end
       else rectangle(r.x1,r.y1,r.x2,r.y2);
       PositionMouseCursor(p_mcx,p_mcy);
       setwritemode(Normalput);
       showmousecursor;
       DefineCursorRange(0,0,_MaxXResolution,_MaxYResolution);
     end;


   function OTView.SetCursor(x,y:integer):word;
     var hp:PHotSpotsArray;
         i:word;
     begin
       SetCursor:=Null_ID;
       { Recupera il puntatore agli hot spots associati all'oggetto. }
       hp:=GetHotSpots(HotSpotsResID);
       if hp=nil then exit;
       for i:=0 to hp^.lim do
         with hp^.v[i] do
           if (x>=x1) and (x<=x2) and (y>=y1) and (y<=y2) then begin
             SetMouseCursor(IDCursor);
             SetCursor:=Message;
             exit;
           end;
     end;


 var hp: THotSpotsArray;

   function OTView.GetHotSpots(ResID:word):PHotSpotsArray;
     begin
       hp.lim:=0;
       with hp.v[0] do begin
         x1:=R.x1;  y1:=R.y1;
         x2:=R.x2;  y2:=R.y2;
         IDCursor:=CursorID;
         Message:=ID;
       end;
       GetHotSpots:=@hp;
     end;


   procedure OTView.DrawInside(x1,y1,x2,y2:integer; proc,params:pointer);
     var DrawParameters: TDrawParameters;
     begin
       if proc=nil then exit;
       DrawParameters.rect.assign(x1+R.x1,y1+R.y1,x2+R.x1,y2+R.y1);
       DrawParameters.params:=params;
       DrawRefreshListProc( GetVisibleZone(@Self,nil,NullObj),
                            nil,
                            proc,
                            @DrawParameters,
                            YesParam);

     end;


   procedure OTView.DrawInside2(x1,y1,x2,y2:integer; proc,params:pointer; DrawList:PRefreshRectList);
     var DrawParameters: TDrawParameters;
     begin
       if proc=nil then exit;
       DrawParameters.rect.assign(x1+R.x1,y1+R.y1,x2+R.x1,y2+R.y1);
       DrawParameters.params:=params;
       DrawRefreshListProc( GetVisibleZone(@Self,nil,NullObj),
                            nil,
                            proc,
                            @DrawParameters,
                            YesParam);

     end;


   function OTView.GetDrawList:PRefreshRectList;
     begin
       GetDrawList:=GetVisibleZone(@Self,nil,NullObj);
     end;


   destructor OTView.GiveGroupTo(Dest:OPView);
     var buf:OPView;
     begin
       if _gruppo_<>nil then begin
         buf:=_gruppo_;
         while buf<>nil do begin
           buf^._Father_:=Dest;
           buf:=buf^._down_;
         end;
         Dest^._gruppo_:=_gruppo_;
         _gruppo_:=nil;
       end;
       OTView.Done;
     end;


   procedure  OTView.AssignGroup(NewGroup:OPView);
     var buf:OPView;
     begin
       if NewGroup=nil then begin
         _gruppo_:=nil;
         _last_:=nil;
       end
       else begin
         _gruppo_:=NewGroup;
         _last_:=NewGroup;
         buf:=_gruppo_^._down_;
         while _gruppo_^._up_<>nil do begin
           _gruppo_^._Father_:=@Self;
           _gruppo_:=_gruppo_^._up_;
         end;
         _gruppo_^._Father_:=@Self;
         while buf<>nil do begin
           buf^._Father_:=@Self;
           buf:=buf^._down_;
         end;
       end;
     end;


   procedure OTView.MoveGroupRel(dx,dy:integer);
     var bufV:OPView;
         R2:OTRect;
         lk,precFlag:boolean;
         view:ViewPortType;
         GFather:OPView;
         ShadowList,
         LightList,
         FirstSHDW,
              SHDW,
             _SHDW: PRefreshRectList;
         mth:byte;
         da_x1,da_y1:integer;

         ppp:PRefreshRectList;
     begin
       if (dx=0) and (dy=0) then exit;
       lk:=lookvideo;
       lookvideo:=false;
       bufV:=_gruppo_;
       while bufV<>nil do begin
         bufV^.MoveRel(dx,dy);
         bufV:=bufV^._down_;
       end;
       lookvideo:=lk;
       if lookvideo then begin
         hidemousecursor;
         { Trasferimento BitBtl }
         precFlag:=ClippingForBITBTL;
         ClippingForBITBTL:=true;
         GetViewSettings(view);
         R2:=R;
         R2.IntersectViewPort(view,R2);
         { Ricerca del livello pi— alto }
         GFather:=@Self;
         while GFather^._Father_<>nil do begin
           GFather:=GFather^._Father_;
           R2.Intersect(GFather^.R,R2);
         end;
         with R2 do SetViewPort(x1,y1,x2,y2,true);
         if GFather^._up_=nil
         then with R2 do BitBtlVideoDC(0,0,dx,dy,DimX+1,DimY+1)
         else begin
           ShadowList:=GetShadowListOf(GFather,@R);
           if ShadowList=nil
           then with R2 do BitBtlVideoDC(0,0,dx,dy,DimX+1,DimY+1)
           else begin
             LightList:=GetLightListOf(GFather,@R,NullObj);
             SHDW:=LightList;
             while SHDW<>nil do begin
               SHDW^.r.MoveRel(dx,dy);
               SHDW:=SHDW^.succ;
             end;
             LightList:=GetLightListOf(GFather,@R,LightList);
             SHDW:=LightList;
             while SHDW<>nil do begin
               SHDW^.r.MoveRel(-dx,-dy);
               SHDW:=SHDW^.succ;
             end;
             SHDW:=ShadowList;
             while SHDW<>nil do begin
               SHDW^.r.MoveRel(dx,dy);
               SHDW:=SHDW^.succ;
             end;
             ShadowList:=GetLightListOf(GFather,@R,ShadowList);
             SHDW:=ShadowList;
             _SHDW:=nil;
             while SHDW<>nil do begin
               if not SHDW^.r.Intersect(R2,SHDW^.r) then begin
                 if _SHDW=nil then begin
                   ShadowList:=SHDW^.succ;
                   dispose(SHDW);
                   SHDW:=ShadowList;
                 end
                 else begin
                   _SHDW^.succ:=SHDW^.succ;
                   dispose(SHDW);
                   SHDW:=_SHDW^.succ
                 end;
                 continue;
               end;
               _SHDW:=SHDW;
               SHDW:=SHDW^.succ;
             end;
          { Determinazione del tipo di ordinamento da effettuare nella lista. }
             { MTH sar… cos strutturato:
               bit 1 = 0 se lo shif della X Š verso sinistra
                     = 1 se lo shif della X Š verso destra
               bit 0 = 0 se lo shif della Y Š verso sopra
                     = 1 se lo shif della Y Š verso sotto
             }
             mth:=0;
             if dx>0 then mth:=mth or $02;
             if dy>0 then mth:=mth or $01;
             { Ordinamento della lista. }
             SortRefreshRectList(LightList,TSortingMethod(mth));
             while LightList<>nil do begin
               with LightList^.r do begin
                 BitBtlVideoDC(x1-R2.x1,y1-R2.y1,x1+dx-R2.x1,y1+dy-R2.y1,x2-x1+1,y2-y1+1);
               end;
               SHDW:=LightList;
               LightList:=LightList^.succ;
               dispose(SHDW);
             end;
             DrawRefreshRectList(ShadowList,@Self);
           end;
         end;
         ClippingForBITBTL:=precFlag;
         { Refresh nuova regione }
         R2.MoveRel(dx,dy);
         RefreshRect(NullRect,{@Self}GFather,GetVisibleZone(@Self,nil,R.DifferenceWith(R2)));
         with view do SetViewPort(x1,y1,x2,y2,clip);
         showmousecursor;
       end;
     end;


   procedure OTView.AddAtTop(NewObj:OPView);
     begin
       if _gruppo_=nil then AppendObject(NewObj)
       else begin
         NewObj^._up_:=nil;
         NewObj^._down_:=_gruppo_;
         _gruppo_^._up_:=NewObj;
         _gruppo_:=NewObj;
         NewObj^._Father_:=@Self;
       end;
     end;


   procedure OTView.AppendObject(NewObj:OPView);
     begin
       if _gruppo_=nil then begin
         SysConfig:=SysConfig or cfScanGroup;
         _gruppo_:=NewObj;
         _last_:=NewObj;
         _gruppo_^._up_:=nil;
         _gruppo_^._down_:=nil;
       end
       else begin
         NewObj^._down_:=nil;
         NewObj^._up_:=_last_;
         _last_^._down_:=NewObj;
         _last_:=NewObj;
       end;
       NewObj^._Father_:=@Self;
     end;


   procedure OTView.RemoveObject(obj: OPView);
     begin
       if obj^._down_<>nil then obj^._down_^._up_:=obj^._up_;
       if obj^._up_<>nil then obj^._up_^._down_:=obj^._down_;
       if obj=_gruppo_ then _gruppo_:=obj^._down_;
       if obj=_last_ then _last_:=obj^._up_;
       dispose(obj,Done);
       if _gruppo_=nil then SysConfig:=SysConfig or cfScanGroup;
     end;


   procedure OTView.ChangeObject(obj, NewObj:OPView);
     var _lk:boolean;
     begin
       if (obj<>nil) and (_gruppo_<>nil) then begin
         _lk:=lookvideo;
         lookvideo:=false;
         if obj^._up_<>nil then obj^._up_^._down_:=NewObj
                           else _gruppo_:=NewObj;
         if obj^._down_<>nil then obj^._down_^._up_:=NewObj;
         NewObj^._down_:=obj^._down_;
         NewObj^._up_:=obj^._up_;
         if DeleteObjectWhenChange then dispose(obj,done);
         lookvideo:=_lk;
         NewObj^._Father_:=@Self;
       end;
     end;


   procedure OTView.InsertBefore(obj,NewObj:OPView);
     begin
       if _gruppo_=nil then AppendObject(NewObj)
       else
         if obj=nil then AddAtTop(NewObj)
         else begin
           NewObj^._up_:=obj^._up_;
           NewObj^._down_:=obj;
           if obj^._up_<>nil then  obj^._up_^._down_:=NewObj;
           obj^._up_:=NewObj;
           if obj=_gruppo_ then _gruppo_:=NewObj;
           NewObj^._Father_:=@Self;
         end;
     end;


   procedure OTView.InsertAfter(obj,NewObj:OPView);
     begin
       if _gruppo_=nil then AppendObject(NewObj)
       else
         if obj=nil then AppendObject(NewObj)
         else begin
           NewObj^._down_:=obj^._down_;
           NewObj^._up_:=obj;
           if obj^._down_<>nil then obj^._down_^._up_:=NewObj;
           obj^._down_:=NewObj;
           if obj=_last_ then _last_:=NewObj;
           NewObj^._Father_:=@Self;
         end;
     end;


   function OTView.PutObjectOverTheTop:OPView;
     var pos:OPView;
     begin
       { Posizionamento dell'oggetto in capo alla lista tenendo conto della
         priorit… degli oggetti configurati per rimanere sempre in primo
         piano. }
       if (SysConfig and cfAlwaysAsFirst)<>0 then begin
         _up_:=nil;
         _down_:=primo;
         primo^._up_:=@Self;
         primo:=@Self;
         PutObjectOverTheTop:=nil;
       end
       else begin
         pos:=primo;
         while (pos<>nil) and
               ((pos^.SysConfig and cfAlwaysAsFirst)<>0)
         do pos:=pos^._down_;
         if pos=nil
         then begin
           {Caso in cui tutti gli oggetti della ROOT dell display-list siano
            configurati per rimanere sempre in primo piano.}
           _down_:=nil;
           _up_:=ultimo;
           ultimo^._down_:=@Self;
           ultimo:=@Self;
         end
         else begin
           {Caso opposto al precedente! Qui pos punta al primo oggetto non
            configurato per rimanere sempre in primo piano.}
           _up_:=pos^._up_;
           _down_:=pos;
           if _up_=nil then primo:=@Self
                       else _up_^._down_:=@Self;
           if _down_=nil then ultimo:=@Self
                         else _down_^._up_:=@Self;
         end;
         PutObjectOverTheTop:=pos;
       end;
     end;


                       { ----- OTGroup ----- }
   constructor OTGroup.Init(_ID:word; _Title:string; objs:OPView);
     var bufV:OPView;
     begin
       if not InitComposite(_ID,r,objs) then fail;
       SysConfig:=SysConfig or cfPostDraw;
       SysConfig:=Sysconfig and __cfDrawFatherRect and __cfScanGroup;
       Title:=_Title;
       if _gruppo_=nil then exit;
       r:=_gruppo_^.r;
       bufV:=_gruppo_^._down_;
       while bufV<>nil do begin
         r.Union(bufV^.r);
         bufV:=bufV^._down_;
       end;
       with r do begin
         dec(x1,10);
         dec(y1,20);
         inc(x2,10);
         inc(y2,10);
         DimX:=x2-x1;
         DimY:=y2-y1;
       end;
     end;


   procedure OTGroup.Disegna;
     var font:OPFont;
     begin
       if (SysConfig and cfEnable)=cfEnable
         then font:=@_system_
         else font:=@_serif10_;
       with r do begin
         rect_In_3D(x1+3,y1+5,x2-3,y2-3);
         setfillstyle(1,8);
         with font^ do begin
           bar(x1+15,y1,x1+15+3+TextLength(Title,0,0),y1+GetHeight);
           DrawText(x1+18,y1,TextLeft,Title);
         end;
       end;
       {CompositeRectRefresh:=rtPrec;}
       inherited Disegna;
     end;


   procedure OTGroup.Select;
     begin
       inherited Select;
     end;


   procedure OTGroup.Deselect;
     begin
       inherited Deselect;
     end;


   procedure OTGroup.Enable;
     begin
     end;


   procedure OTGroup.Disable;
     begin
     end;


                  { ----- OTBar ----- }
   constructor OTBar.Init(_ID:word;var coord:OTRect; stl:word; col:integer);
     begin
       if not inherited Init(_ID,coord) then fail;
       style:=stl;
       colore:=col;
     end;


   procedure OTBar.SetStyle(stl:word; col:integer);
     begin
       style:=stl;
       colore:=col;
     end;


   procedure OTBar.Disegna;
     begin
       setfillstyle(style,colore);
       bar(r.x1,r.y1,r.x2,r.y2);
     end;


                { ----- OTTesto ----- }
   constructor OTText.Init(_ID:word;var coord:OTRect; _font:OPFont; str:string;
                            stl:word; bkcol,TxCol:integer);
     begin
       if not inherited Init(_ID,coord,stl,bkcol) then fail;
       SysConfig:=(SysConfig or
                  cfPostDraw {or
                  cfLPriority}) and
                  __cfDrawFatherRect ;
       _text_:=StrNewPas(str);
       TextFont:=_font;
       TextCol:=TxCol;
       _CancBar_:=bkcol;
     end;


   constructor OTText.__Init(_ID:word;var coord:OTRect; _font:OPFont; str:PChar;
                            stl:word; bkcol,TxCol:integer);
     begin
       if not inherited Init(_ID,coord,stl,bkcol) then fail;
       SysConfig:=(SysConfig or
                  cfPostDraw {or
                  cfLPriority}) and
                  __cfDrawFatherRect ;
       _text_:=str;
       TextFont:=_font;
       TextCol:=TxCol;
       _CancBar_:=bkcol;
     end;


   destructor OTText.Done;
     begin
       StrDispose(_text_);
       inherited Done;
     end;


   procedure OTText.Disegna;
     var _T:integer;
     begin
{       setfillstyle(style,colore);
       bar(r.x1,r.y1,r.x2,r.y2);
}       _T:=TextColor;
       TextColor:=TextCol;
       TextFont^.__DrawText(r.x1,r.y1,TextLeft,_text_);
       TextColor:=_T;
     end;


   procedure OTText.SetTextProperties(_font:OPFont; col:word);
     begin
       TextFont:=_font;
       TextCol:=Col;
       if lookvideo then begin
         hidemousecursor;
         RefreshRect(R,@Self,GetVisibleZone(@Self,nil,NullObj));
         showmousecursor;
       end;
     end;


   function  OTText.GetFont:OPFont;
     begin
       GetFont:=TextFont;
     end;


   function  OTText.GetTextColor:word;
     begin
       GetTextColor:=TextCol;
     end;


   procedure OTText.GetTextInfo(var text:PChar; var _font:pointer; var TxtCol:word);
     begin
       text:=StrNew(_text_);
       _font:=TextFont;
       TxtCol:=TextColor;
     end;


   procedure OTText.ChangeTextPas(var newText:string);
     begin
       StrDispose(_text_);
       _text_:=StrNewPas(newText);
       if lookvideo then begin
         SysConfig:=SysConfig or cfCancBar;
         hidemousecursor;
         RefreshRect(R,@Self,GetVisibleZone(@Self,nil,NullObj));
         showmousecursor;
         SysConfig:=SysConfig and __cfCancBar;
       end;
     end;


   procedure OTText.ChangeText(newText:PChar);
     begin
       if _text_=newText then exit;
       StrDispose(_text_);
       _text_:=newText;
       if lookvideo then begin
         SysConfig:=SysConfig or cfCancBar;
         hidemousecursor;
         RefreshRect(R,@Self,GetVisibleZone(@Self,nil,NullObj));
         showmousecursor;
         SysConfig:=SysConfig and __cfCancBar;
       end;
     end;


                       {----- OTAutoText -----}
   constructor OTAutoText.Init(_ID:word;var coord:OTRect; _font:OPFont; str:string;
                               stl:word; bkcol,TxCol:integer);
     begin
       inherited Init(_ID,coord,_font,str,stl,bkcol,TxCol);
       changed:=false;
       Adjust;
     end;


   constructor OTAutoText.__Init(_ID:word;var coord:OTRect; _font:OPFont; str:PChar;
                                 stl:word; bkcol,TxCol:integer);
     begin
       inherited __Init(_ID,coord,_font,str,stl,bkcol,TxCol);
       changed:=false;
       Adjust;
     end;


   destructor OTAutoText.Done;
     begin
       if changed then StrDispose(precText);
     end;


   procedure OTAutoText.Adjust;
     const TrePunti = '....';
           Lunghezza= length(TrePunti);
     var i,l:word;
         change:boolean;
         dx_fisso:word;
         txt:PChar;
     begin
       if R.DimX<=0 then exit;
       { assegna a txt la stringa originale }
       if changed then txt:=precText
                  else txt:=_text_;
       if TextFont^.__TextLength(txt,0,0)<=R.DimX then begin
         if changed then begin
           StrDispose(_text_);
           _text_:=precText;
           changed:=false;
         end;
         exit;
       end;
       dx_fisso:=TextFont^.TextLength(TrePunti,0,0);
       change:=false;
       l:=0;
       for i:=1 to StrLen(txt) do begin
         inc(l,TextFont^.__TextLength(txt,i,i));
         if l+dx_fisso>R.DimX then begin
           change:=true;
           dec(i);
           break;
         end;
       end;
       if change then begin
         if changed
           then StrDispose(_text_)
           else begin
             changed:=true;
             precText:=_text_;
           end;
         GetMem(_text_,i+Lunghezza+1);
         StrLCopy(_text_,precText,i);
         StrCatPas(_text_,TrePunti);
       end
       else
         if changed then begin
           StrDispose(_text_);
           _text_:=precText;
           changed:=false;
         end;
     end;


   procedure OTAutoText.GetTextInfo(var text:PChar; var _font:pointer; var TxtCol:word);
     begin
       if changed then text:=StrNew(precText)
                  else text:=StrNew(_text_);
       _font:=TextFont;
       TxtCol:=TextColor;
     end;


                { ------ OTWin3D ------ }
   procedure OTWin3D.Disegna;
     begin
       setfillstyle(style,colore);
       with r do begin
         bar(x1+2,y1+2,x2-2,y2-2);
         setcolor(8);   line(x1,y1,x1,y2-1);
                        line(x1,y1,x2-1,y1);
         setcolor(15);  line(x1+1,y1+1,x1+1,y2-2);
                        line(x1+1,y1+1,x2-2,y1+1);
         setcolor(7);   line(x1+1,y2-1,x2-1,y2-1);
                        line(x2-1,y2-1,x2-1,y1+1);
         setcolor(0);   line(x1,y2,x2,y2);
                        line(x2,y2,x2,y1);
       end;
     end;


                { ------  OTRilievo3d  ------ }
   procedure OTRilievo3D.Disegna;
     begin
       Rilievo3D(r.x1,r.y1,r.x2,r.y2,colore);
     end;


                { ------  OTIncavo3d  ------ }
   procedure OTIncavo3D.Disegna;
     begin
       Incavo3D(r.x1,r.y1,r.x2,r.y2,colore);
     end;


                { ------  OTRilievo3dSoft  ------ }
   procedure OTRilievo3DSoft.Disegna;
     begin
       Rilievo3DSoft(r.x1,r.y1,r.x2,r.y2,colore);
     end;


                { ------  OTIncavo3dSoft  ------ }
   procedure OTIncavo3DSoft.Disegna;
     begin
       SetWriteMode(NormalPut);
       Incavo3DSoft(r.x1,r.y1,r.x2,r.y2,colore);
     end;


                      { ----- OTLine ----- }
   constructor OTLine.Init(var coord:OTRect; color:word; lineType:TLine);
     const cfLine=cfPostDraw or
                  cfNoEvent;
     begin
       if not inherited Init(Null_ID,coord) then fail;
       _LineType_:=lineType;
       _Color_:=Color;
       SysConfig:=SysConfig or cfLine;
     end;


   procedure OTLine.Disegna;
     begin
       with r do case _LineType_ of
       Normal: begin
                 SetColor(_Color_);
                 line(x1,y1,x2,y2);
               end;
         In3D: line_In_3D(x1,y1,x2,y2);
        Out3D: line_Out_3D(x1,y1,x2,y2);
       end;
     end;


   procedure OTLine.ChangeLineSettings(color:word; lineType:TLine);
     begin
       _LineType_:=lineType;
       _Color_:=color;
       if lookvideo then disegna;
     end;


                     { ----- OTRectangle ----- }
   procedure OTRectangle.Disegna;
     begin
       with r do case _LineType_ of
       Normal: begin
                 SetColor(_Color_);
                 rectangle(x1,y1,x2,y2);
               end;
         In3D: Rect_In_3D(x1,y1,x2,y2);
        Out3D: Rect_Out_3D(x1,y1,x2,y2);
       end;
     end;


                      { ----- OTCircle ----- }
   procedure OTCircle.Disegna;
     var X,Y:integer;
         Xradius,Yradius:word;
     begin
       with r do begin
         Xradius:=DimX div 2;
         Yradius:=DimY div 2;
         X:=x1+Xradius;
         Y:=y1+Yradius;
         case _LineType_ of
         Normal: begin
                   SetColor(_Color_);
                   Ellipse(X,Y,0,360,XRadius,Yradius);
                 end;
           In3D: begin
                   SetColor(7);
                   Ellipse(X,Y,0,360,XRadius,Yradius);
                   SetColor(15);
                   Ellipse(X+1,Y+1,0,360,XRadius,Yradius);
                 end;
          Out3D: begin
                   SetColor(15);
                   Ellipse(X,Y,0,360,XRadius,Yradius);
                   SetColor(7);
                   Ellipse(X+1,Y+1,0,360,XRadius,Yradius);
                 end;
         end;
       end;
     end;





{ *********************************************************************** }
{ +++     Fine della dichiarazione dei metodi degli oggetti           +++ }
{ *********************************************************************** }

type TDeallocMemory = function(Size:word):integer;

var  DeallocFunc : TDeallocMemory absolute DeallocMemory;


function GolibHeapFunc (Size: Word): Integer; far;
  var ch:char;
  begin
    if Size<>0 then begin
      if GraphicModeLoaded then RestoreCRTMode;
      writeln('Errore di allocazione nello HEAP.');
      writeln('MemAvail = ',memavail);
      writeln('MaxAvail = ',maxavail);
      writeln('Memoria richiesta = ',Size);
      writeln;
      writeln('1. Provoca un run-time error');
      writeln('2. Ritorna NIL al puntatore  (*)');
      writeln('3. Riprova                   (**)');
      writeln;
      write('(*)  ');
      TextAttr:=LightRed;
      write('Attenzione!');
      TextAttr:=LightGray;
      writeln(' Se non c''Š un controllo sul puntatore questo potrebbere creare      un crash di sistema.');
      writeln('(**) Chiamer… la funzione DeallocMemory (se installata) per liberare memoria         nello HEAP');
      ch:=#0;
      while not (ch in ['1'..'3']) do ch:=readkey;
      if (ch='2') or (ch='3') then begin
        if GraphicModeLoaded then RestoreGraphMode;
        if (ch='3') and (DeallocMemory<>nil) then DeallocFunc(Size);
      end;
      GolibHeapFunc:=ord(ch)-48-1;
    end;
  end;

(*
{$F+,S-,W-}
procedure Golib_Interrupt00(Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP: Word); interrupt;
  begin
    if GraphicModeLoaded then RestoreCRTMode;
    writeln('Errore di esecuzione rilevato dalla CPU!');
    writeln;
    writeln('Divisione per Zero.');
    writeln;
    writeln('AX = ',HexW(AX),'     DX = ',HexW(DX));
    writeln('CX = ',HexW(CX),'     BX = ',HexW(BX));
    writeln('IP = ',HexW(IP),'     CS = ',HexW(CS));
    writeln('SI = ',HexW(SI),'     DS = ',HexW(DS));
    writeln('DI = ',HexW(DI),'     ES = ',HexW(ES));
    {writeln('SP = ',HexW(SP),'     SS = ',HexW(SS));}
    writeln('BP = ',HexW(BP));
    writeln('Flags = ',HexW(Flags));
    writeln;
    writeln('Premi un tasto per continuare...');
    readkey;
    TProc(Int00Save);
  end;
{$F-,S+}

*)

begin
  DeallocFunc:=nil;
  HeapError:=@GolibHeapFunc;

  {GetIntVec($00,Int00Save);
  SetIntVec($00,Addr(Golib_Interrupt00));}

{ Inizializzazione delle variabili che indicano i font da utilizzare nei vari
  oggetti. }
  IntestFont:=@_system_;
{ Inizializzazione delle variabili delle procedure di inizializzazione. }
  PrecInitProc:=GraphEntryProc;
  PrecDoneProc:=GraphExitProc;
  GraphEntryProc:=@InitGOLIB;
  GraphExitProc:=@DoneGOLIB;

  NullObj:=@NullObj;
  All_Objects:=@All_Objects;

{  InizializzaGraficaMAX;}
  NullRect.DimX:=-3000;
  NullRect.DimY:=+3000;

  Sfondo:=nil;

  ObjectSelected:=nil;

  GetIntVec($09,Int09Save);
end.