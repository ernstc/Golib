{ Ernesto CIANCIOTTA Productions }

{ ************************************************************************ }
{ *                                                                      * }
{ * Modulo della libreria GOLIB contene tipi e costanti utilizzati dalla * }
{ * libreria e dalle applicazioni.                                       * }
{ *                                                                      * }
{ * Scritto con Turbo Pascal 7.0                                         * }
{ *                                                                      * }
{ ************************************************************************ }


UNIT Golib_H;

INTERFACE


{* Costanti sui metodi virtuali *}

const
      { VMs = Virtual Methods }
      VMs_OTView = 14;

      { VMI = Virtual Method Index }
      VMI_OTView_SetCursor  = 11;

      VMI_OTButton_Pressed  = VMs_OTView + 1;       { BUTTONS }
      VMI_OTButton_Released = VMs_OTView + 2;       { BUTTONS }
      VMI_OTButton_Disabled = VMs_OTView + 3;       { BUTTONS }

      VMI_OTMenuLine_SelectItem = VMs_OTView + 1;   { MENU    }


{* Costanti e tipi relativi agli eventi *}

const
      btLPressMask = $0001;
      btRPressMask = $0002;
      btCPressMask = $0004;
      btLReleaseMask = $0008;
      btRReleaseMask = $0010;
      btCReleaseMask = $0020;

      DefaultMultipleMClickDelay = 6;


type
      TKeyEvent = record
         KeyStroke:word;   { Codifica del evento ricevuto da tastiera }
         Message:word;     { Messaggio associato                      }
      end;


      PKeyEvArray = ^TKeyEvArray;
      TKeyEvArray = array[0..0] of TKeyEvent;


{* Tipo risorsa HOT SPOT *}

      THotSpot = record
         x1, y1,
         x2, y2:   integer;
         IDCursor: word;
         Message:  word;
      end;

      PHotSpotsArray = ^THotSpotsArray;
      THotSpotsArray = record
         v: array [0..0] of THotSpot;
         lim: word;
      end;


const
      { Tipi di Eventi }
      EvSysMessage = $0000;
      EvKeyboard   = $0001;
      EvMouse      = $0002;
      EvCommand    = $0003;

type
      TObjectSender = word;

      PMessage = ^TMessage;
      TMessage = record
         HNDL: TObjectSender;
         Message: word;
         case byte of
         0: ( b1Reg, b2Reg, b3Reg, b4Reg: byte;
              b5Reg, b6Reg, b7Reg, b8Reg: byte;
             );
         1: ( w1Reg, w2Reg: word;
              w3Reg, w4Reg: word;
             );
         2: ( long1Reg: longint;
              long2Reg: longint;
             );
         3: ( ParametersPtr1: pointer;
              ParametersPtr2: pointer;
             );
         4: ( Shifts: word;
              case byte of
              0: ( case byte of
                   0: ( KeyStroke:word;
                       );
                   1: ( Character: Char;
                        ScanCode: byte;
                       );
                  );
              1: ( Clicks: byte;
                   mcx, mcy: word;
                  );
             );
      end;


const
      Null_Message: TMessage =
        ( HNDL: 0;
          Message: 0;
          long1Reg: 0;
          long2Reg: 0
        );




{* Costanti e tipi presi da GOLIB8.PAS *}

const

     VMI_Disegna=3;

{ Files di risorsa }
     GolibRESFile  : string = 'c:\tp7\golib8.bmp\golib8.res';


{ Costanti per la definizione del campo di configuarione degli oggetti:
  SysConfig. }
     cfVisible         = $0001;
     cfOnDeskTop       = $0002;
     cfScanGroup       = $0004;
     cfBitBtl          = $0020;
     cfAlwaysAsFirst   = $0100;
     cfSelectable      = $0200;
     cfSelected        = $0400;
   { Flags per la gestione degli eventi }
     cfCustomControl   = $0008;              {** ? **}
     cfEnable          = $0010;
     cfTrasparent      = $0040;
     cfModal           = $0080;
     cfNoEvent         = cfTrasparent;
   { Flag per il refresh }
     cfCancBar         = $8000;
     cfPostDraw        = $4000;
     cfCDraw           = $C000;
     cfLPriority       = $2000;
     cfDrawFatherRect  = $1000;
     cfCompactable     = $0800;
     cfITLF            = $0010;

     cfPassive         = $0000;
     cfAllActive       = $FFFF;
     cfStartupObj      = cfVisible or
                         cfEnable  or
                         cfSelectable or
                         cfBitBtl  or
                         cfDrawFatherRect;

   { Valori negativi dei flag }
     __cfCancBar       = not cfCancBar;
     __cfPostDraw      = not cfPostDraw;
     __cfNDraw         = not cfCDraw;
     __cfLPriority     = not cfLPriority;
     __cfDrawFatherRect= not cfDrawFatherRect;
     __cfITLF          = not cfITLF;

     __cfVisible       = not cfVisible;
     __cfOnDeskTop     = not cfOnDeskTop;
     __cfScanGroup     = not cfScanGroup;
     __cfTrasparent    = not cfTrasparent;
     __cfModal         = not cfModal;
     __cfBitBtl        = not cfBitBtl;
     __cfAlwaysAsFirst = not cfAlwaysAsFirst;
     __cfSelectable    = not cfSelectable;
     __cfCustomControl = not cfCustomControl;
     __cfDisable       = not cfEnable;


   { Costanti per impostare il campo MouseReactionMask }
     rcMove       = $80;
     rcMultiClick = $40;
     rcLReleased  = $20;
     rcRReleased  = $10;
     rcCReleased  = $08;
     rcLPressed   = $04;
     rcRPressed   = $02;
     rcCPressed   = $01;

   { Impostazione di partenza del campo  al "MouseReactionMask" momento
     dell'esecuzione di un costruttore di "OTView". }

     rcStandardMouseMask = rcLPressed {or
                           rcRPressed or
                           rcCPressed {or
                           rcLReleased or
                           rcRReleased or
                           rcCReleased{ or
                           rcMultiClick};



type
     { Fa riferimento ai metodi di ordinamento che possono essere utilizzati
       dalla procedura "RefreshRect" del modulo "DISPFL_8" }
     TSortMethod = (LIFO,FIFO,TLBR,LTRB);
          {
            LIFO => Last In First Out
            FIFO => Firt In First Out
            TLBR => Top Left Bottom Right
          }
     TSortingMethod = (TopLeft,BottomLeft,TopRight,BottomRight);

     TLine = (Normal,In3D,Out3D);

     TDirection = (Vert,Horiz,All);


     PProcedure = ^TProcedure;
     TProcedure = procedure;


     PParametri = ^TParametri;
     TParametri = array[1..255] of byte;


     TBordo = (_nord_,_sud_,_ovest_,_est_);




{* Costanti e tipi presi da WINDOW.PAS *}

const
      _SEPARATOR_=$FFFF;

      { costanti per la consultazione di OTWindow.WinInfo }
      wndZoomed   = $01;
      wndReduced  = $02;
      wndSelected = $04;
      wndMov8     = $80;


{* Costanti e tipi presi da MENU.PAS *}


const
         _Attivo_=true;
         _Inattivo_=false;
         _No_SubMenu_=nil;

         {Varibili per la manipolazione dei flags del campo
          "attributes" del record "TMenuPP"}
         itDisable  = $00;
         itEnable   = $01;
         itSelected = $02;
         itMarked   = $04;
         itMarcable = $08;
         itBitmap   = $10;
         itSeparator= $80;

         {Negativi del precedente gruppo di costanti}
         __itEnable   = not itEnable;
         __itSelected = not itSelected;
         __itMarked   = not itMarked;
         __itMarcable = not itMarcable;
         __itBitmap   = not itBitmap;





type
     OPGolibObject = ^OTGolibObject;
     OTGolibObject = object
        constructor Init;
        destructor Done;
        procedure ExecMessage(var Message:TMessage); virtual;
     end;



IMPLEMENTATION


     constructor OTGolibObject.Init;
       begin
       end;


     destructor OTGolibObject.Done;
       begin
       end;


     procedure OTGolibObject.ExecMessage(var Message:TMessage);
       begin
       end;


END.