{ by ERNESTO CIANCIOTTA Productions }

{*************************************************}
{*                                               *}
{*  Modulo della libreria GOLIB contenente       *}
{*  l'oggetto finestra OTWindow_0.               *}
{*                                               *}
{*  Scritto con Turbo Pascal ver 7.0.            *}
{*                                               *}
{*************************************************}


{
  DIFFERENZE TRA L'OGGETTO "OTWindow" E L'OGGETTO "OTWindow_0".
  _____________________________________________________________


  L'oggetto "OTWindow" e un tipo di oggetto finestra che si autogestisce.
  Nel senso che per creare un finestra con determinate caratteristiche
  (es.: oggetti che ne determinano il layout) vengono utilizzati direttamente
  i metodi dell'oggetto. Se si vuole creare una finestra che abbia delle
  particolari funzionalit…, l'unica ragione per cui l'oggetto debba essere
  ereditato Š quella di installare un nuovo gestore di eventi (ReactionEvent).
  Questo oggetto contiene solo una pagina di visualizzazione e questa pu• essere
  una limitazione qualora si voglia creare una finestra derivata che abbia due
  pagine invece di una. Non Š un'operazione impossibile, ma verrebbe creata una
  struttura a pi— livelli complicherebbe il calcolo.

  L'oggetto "OTWindow_0" Š, invece, un oggetto che deve essere necessariamente
  ereditato se si vuole creare una finestra (o dialog-box) con determinate
  funzionalit…. Questo oggetto non utilizza i layouts e ci• lo rende molto
  pi— semplice dell'oggetto "OTWindow" e pi— snello dal punto di vista dello
  spazio occupato e della complessit… di calcolo nel ridimensionamento.
  La completa assenza di qualsiasi riferimento a dei layouts rende l'oggetto
  molto rigido in quando non Š possibile ridefinire lo stile fondamentale della
  finestra composto dall'intestazione e dallo sfondo. Viceversa, il completo
  distacco dell'oggetto "OTWindow" da modelli definiti in fase di proggettazione
  dell'oggetto, ci• Š reso possibile grazie ai layouts, lo rende completamente
  flessibile a esigenze di restyling dell'applicazione o semplicemente di una
  finestra. In questo caso Š, per•, necessario derivare l'oggetto e ridefinire
  il metodo ReactionParam.
}


{$D+}
{$L+}
{$X+}


UNIT Win;

INTERFACE

uses

 { Moduli per il debug }
      crt,
      timer,
      g_utile,
      fonts,

 { Moduli conteneti codici }
      codici,
      golibcod,

 { Moduli di sistema }
      strings,
      mouse,
      graph,
      graftool,
      golib8,

 { Modulo per l'accesso ai bottoni }
      buttons,

 { Moduli necessari per l'utilizzo del bitmap ReducedIcon }
      bitmap,
      bitmaps,
      resman;



type
      OPWindow_0 = ^OTWindow_0;
      OTWindow_0 = object (OTCompositeObject)
         constructor Init(var coord:OTRect; intest:string; Param:pointer);
         destructor Done; virtual;
         procedure Disegna; virtual;
         function ReactionEvent(Event:word):word; virtual;
         procedure Reaction; virtual;
         procedure Adjust; virtual;
         procedure MoveRel(dx,dy:integer); virtual;
         procedure Select; virtual;
         procedure Deselect; virtual;
         function GetWindowName:PChar;
         procedure SetWindowName(intest:PChar);

         { Inserisce degli oggetti nella sub-list _gruppo_.
           Questi metodi effettuano delle operazioni di refresh. }
         procedure PutObjectInWin(obj:OPView);
         procedure RemoveObjectFromWin(obj:OPView);
      private
         WinInfo: byte;
         UnZoomRect,
         NormalRect:OTRect; { In questa variabile viene memorizzata la dimensione
                              della finestra prima di ridurla o ingrandirla. }
         WindowName:PChar; { Intestazione della finestra }
         Button_Z_UNZ:OPView;

         PrecImage:OPView;

         {-- Procedure di risposta agli eventi di default --}
         procedure Chiudi;
         procedure Zoom;
         procedure DimensioniNormali;
         procedure Riduci;
      end;





IMPLEMENTATION


end.