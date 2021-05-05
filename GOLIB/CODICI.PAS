{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



{******************************************}
{*                                        *}
{*  Codici predefiniti per gli eventi     *}
{*  degli oggetti.                        *}
{*                                        *}
{*  La loro utilit… Š solamente quella    *}
{*  di semplificare l'assegnazione dei    *}
{*  codici.                               *}
{*                                        *}
{******************************************}


{ NOTA BENE.
  ----------

  Prossimo codice = $0055

  Altri codici disponibili:
    nessuno



- I messaggi con codice tipo $8xxx si riferiscono al MOUSE.
- I messaggi con codice tipo $1xxx sono messaggi che vengono direttamente
  eseguiti dal sistema senza essere passati a nessun oggetto.
}

UNIT Codici;

INTERFACE

const

   Null_ID    = $0000;


  _SEPARATOR_ = $FFFF;


{ Operazioni generiche sugli oggetti: }

  _MUOVI_OGGETTO_         = $0001;
  _DIMENSIONA_OGGETTO_    = $0003;



{ Operazioni sulle finestre: }

  _CHIUDI_FINESTRA_       = $0002;
  _RIDIMENSIONA_FINESTRA_ = $0019;
  _ZOOM_FINESTRA_         = $0004;
  _UNZOOM_FINESTRA_       = $0018;
  _RIDUCI_FINESTRA_       = $0005;
  _NASCONDI_FINESTRA_     = $0016;
  _SCOPRI_FINESTRA_       = $0017;

  _CHANGE_WIN_NAME_       = $004A;



{ Messaggi delle ScrollBar: }

  _SCROLL_H_AVANTI_=$001A;
  _SCROLL_H_INDIETRO_=$001B;
  _SCROLL_H_MOVE_=$001C;            { Messaggi delle scrollbar orizzontali }
  _SCROLL_H_PAGE_AVANTI_=$001D;     {              OUTPUT*                 }
  _SCROLL_H_PAGE_INDIETRO_=$001E;

  _SCROLL_V_AVANTI_=$001F;
  _SCROLL_V_INDIETRO_=$0020;
  _SCROLL_V_MOVE_=$0021;            { Messaggi delle scrollbar verticali }
  _SCROLL_V_PAGE_AVANTI_=$0022;     {              OUTPUT*               }
  _SCROLL_V_PAGE_INDIETRO_=$0023;

  _SCROLL_AVANTI_=$0024;
  _SCROLL_INDIETRO_=$0025;
  _SCROLL_MOVE_=$0026;              { Messaggi delle scrollbar v/h }
  _SCROLL_PAGE_AVANTI_=$0027;       {           INPUT*             }
  _SCROLL_PAGE_INDIETRO_=$0028;
  {
    Le prime due serie di messaggi sono generati come output dall'oggetto
    OTScrollBar, metre l'ultima serie di messaggi, che si riferisce ad
    una scrollbar qualsiasi (sia verticale che orizzontale), pu• essere
    passata come input alla scrollbar.
    Questo input sar… valido sia nel caso in cui la scrollbar sar… verticale
    sia nel caso in cui sar… orizzontale. Come input della suddetta procedura
    non possono essere usate la prime due serie di messaggi perchŠ non verrebbero
    riconosciuti.
  }

{ Messaggi delle ScrollBox }
  {
    I messaggi che seguono possono essere utilizzati come input per un oggetto
    ScrollBox. Questo oggetto per• non rilascia come output lo stesso messaggio,
    ma un messaggio di una sua scrollbar per indicare il tipo di movimento
    generato dal messaggio ricevuto come input.
  }
  _SCROLLBOX_H_AVANTI_=$002C;
  _SCROLLBOX_H_INDIETRO_=$002D;
  _SCROLLBOX_H_MOVE_=$002F;            { Messaggi delle scrollbox }
  _SCROLLBOX_H_PAGE_AVANTI_=$0030;     {              INPUT*      }
  _SCROLLBOX_H_PAGE_INDIETRO_=$0031;

  _SCROLLBOX_V_AVANTI_=$0032;
  _SCROLLBOX_V_INDIETRO_=$0033;
  _SCROLLBOX_V_MOVE_=$0034;            { Messaggi delle scrollbox }
  _SCROLLBOX_V_PAGE_AVANTI_=$0035;     {              INPUT*      }
  _SCROLLBOX_V_PAGE_INDIETRO_=$0036;


{ Messaggi delle ToolBar }
  {
    Questi messaggi valgono sia come input che come output.
  }
  _TOOLBAR_SCROLL_LEFT_  = $0041;
  _TOOLBAR_SCROLL_RIGHT_ = $0042;


{ Messaggi per i gruppi di ratio button }
  _SET_NEW_RADIO_BUTTON_ = $0040;




{ Operazioni sui file: }

  _NUOVO_FILE_=$0014;
  _APRI_FILE_=$0006;
  _CHIUDI_FILE_=$0007;
  _SALVA_FILE_=$0008;
  _SALVA_FILE_COME_=$0009;
  _SALVA_TUTTO_=$0015;



{ Operazioni generali sull'applicazione: }

  _ESCI_=$000A;



{ Operazioni di editor: }

  _ANNULLA_=$000B;
  _RIPRISTINA_=$000C;
  _TAGLIA_=$000D;
  _COPIA_=$000E;
  _INCOLLA_=$000F;
  _CANCELLA_=$0010;



{ Operazioni di stampa: }

  _ANTEPRIMA_DI_STAMPA_=$0011;
  _IMPOSTA_STAMPANTE_=$0012;
  _STAMPA_=$0013;



{ Operazioni generali: }
  _HELP_=$002A;


{ Codici per l'indentificazione degli oggetti che spediscono i messaggi: }
  _GOLIB_SYSTEM_ = $003B;
  _WINDOW_       = $0029;
  _STATUS_LINE_  = $002B;
  _STRING_FIELD_ = $0037;
  _PULL_DOWN_    = $0038;
  _LIST_VIEWER_  = $0039;
  _LINE_MENU_    = $003C;
  _POPUP_MENU_   = $003D;
  _RADIO_BUTTON_ = $003F;
  _TOOL_BAR_     = $0043;
  _SCROLL_BAR_   = $0045;
  _SCROLL_BOX_   = $0046;

  _OBJ_DELETING_ = $003E;
  _OBJ_POINTED_  = $0044;

  _XLIST_        = $0047;
  _X_TEXT_LINE_  = $0048;



{ Messaggi delle liste OTXTextLine }
  _TEXT_LINE_    = $0049;


{ Messaggi generati dall'intestazione delle finestre }
  HEADER_DOUBLECLICK =$004C;


{ Messaggi per il dimensionamento di una finestra }
  EvWinDimNORTH      =$004D;
  EvWinDimNORTHEAST  =$004E;
  EvWinDimEAST       =$004F;
  EvWinDimSOUTHEAST  =$0050;
  EvWinDimSOUTH      =$0051;
  EvWinDimSOUTHWEST  =$0052;
  EvWinDimWEST       =$0053;
  EvWinDimNORTHWEST  =$0054;


{ Messaggi relativi a eventi provenienti dalla tastiera }
  EvKEYDOWN               = $003A;


{ Messaggi relativi a eventi provenienti dal mouse }
  EvMOUSE_MOVES           = $8000;
  EvMOUSE_MOVES_OUT       = $8200;

  EvMOUSE_L_PRESSED       = $8081;
  EvMOUSE_R_PRESSED       = $8082;
  EvMOUSE_C_PRESSED       = $8084;

  EvMOUSE_L_RELEASED      = $8001;
  EvMOUSE_R_RELEASED      = $8002;
  EvMOUSE_C_RELEASED      = $8004;

  EvMOUSE_L_MULTIPRESSED  = $8181;
  EvMOUSE_R_MULTIPRESSED  = $8182;
  EvMOUSE_C_MULTIPRESSED  = $8184;

  EvMOUSE_L_MULTIRELEASED = $8101;
  EvMOUSE_R_MULTIRELEASED = $8102;
  EvMOUSE_C_MULTIRELEASED = $8104;



{ Messaggi eseguibili dall'application controller }
  SYS_CREATE_OBJECT = $1000;
  SYS_DELETE_OBJECT = $1001;
  SYS_SEND_MESSAGE  = $1002;
  SYS_REFRESH_OBJ   = $1003;




{***************************************************************************}
{             Codici per il controllo degli eventi della tastiera.          }
{***************************************************************************}


{ Costanti per l'analisi del campo Shifts di un record di tipo TMessage
  che indica lo stato degli shifts della tastiera. }

    kbRightShift  = $0001; { Set if the Right Shift key is currently down   }
    kbLeftShift   = $0002; { Set if the Left Shift key is currently down    }
    kbShift       = $0003; { Per vedere se uno dei tasti shift Š premuto    }
    kbCtrlShift   = $0004; { Set if the Ctrl key is currently down          }
    kbAltShift    = $0008; { Set if the Alt key is currently down           }
    kbScrollState = $0010; { Set if the keyboard is in the Scroll Lock state}
    kbNumState    = $0020; { Set if the keyboard is in the Num Lock state   }
    kbCapsState   = $0040; { Set if the keyboard is in the Caps Lock state  }
    kbInsState    = $0080; { Set if the keyboard is in the Ins Lock state   }

    kbSysRq       = $8000; { Set if SysRq Key is pressed                    }
    kbCapsLock    = $4000; { Set if Caps Lock Key is pressed                }
    kbNumLock     = $2000; { Set if Num Lock Key is pressed                 }
    kbScrollLock  = $1000; { Set if Scroll Lock Key is pressed              }
    kbRightAlt    = $0800; { Set if Right Alt Key is pressed                }
    kbRightCtrl   = $0400; { Set if Right Ctrl Key is pressed               }
    kbLeftAlt     = $0200; { Set if Left Alt Key is pressed                 }
    kbLeftCtrl    = $0100; { Set if Left Ctrl Key is pressed                }


{ Codici tasto estesi utili per interpretare il campo KeyComb della variabile
  di tipo TInputEvent quando questa si riferisce ad un evento della tastiera.}

    kbEsc       = $011B;    kbAltEsc    = $0100;    kbTab       = $0F09;
    kbShiftTab  = $0F00;    kbCtrlTab   = $9400;    kbAltTab    = $A500;
    kbBack      = $0E08;    kbCtrlBack  = $0E7F;    kbAltBack   = $0E00;
    kbEnter     = $1C0D;    kbCtrlEnter = $1C0A;    kbAltEnter  = $1C00;
    kbIns       = $52E0;    kbCanc      = $53E0;    kbHome      = $47E0;
    kbEnd       = $4FE0;    kbPgUp      = $49E0;    kbPgDown    = $51E0;
    kbCtrlIns   = $92E0;    kbCtrlCanc  = $93E0;    kbCtrlHome  = $77E0;
    kbCtrlEnd   = $75E0;    kbCtrlPgUp  = $84E0;    kbCtrlPgDown = $76E0;
    kbAltIns    = $A200;    kbAltCanc   = $A300;    kbAltHome   = $9700;
    kbAltFine   = $9F00;    kbAltPgUp   = $9900;    kbAltPgDown = $A100;
    kbLeft      = $4BE0;    kbRight     = $4DE0;    kbUp        = $48E0;
    kbDown      = $50E0;    kbCtrlLeft  = $73E0;    kbAltRight  = $9D00;
    kbAltUp     = $9800;    kbAltDown   = $A000;    kbCtrlRight = $74E0;
    kbCtrlUp    = $8DE0;    kbCtrlDown  = $91E0;    kbAltLeft   = $9B00;
    kbSpace     = $3920;    kbF1        = $3B00;    kbF2        = $3C00;
    kbF3        = $3D00;    kbF4        = $3E00;    kbF5        = $3F00;
    kbF6        = $4000;    kbF7        = $4100;    kbF8        = $4200;
    kbF9        = $4300;    kbF10       = $4400;    kbF11       = $8500;
    kbF12       = $8600;    kbCtrlF1    = $5E00;    kbCtrlF2    = $5F00;
    kbCtrlF3    = $6000;    kbCtrlF4    = $6100;    kbCtrlF5    = $6200;
    kbCtrlF6    = $6300;    kbCtrlF7    = $6400;    kbCtrlF8    = $6500;
    kbCtrlF9    = $6600;    kbCtrlF10   = $6700;    kbCtrlF11   = $8900;
    kbCtrlF12   = $8A00;    kbAltF1     = $6800;    kbAltF2     = $6900;
    kbAltF3     = $6A00;    kbAltF4     = $6B00;    kbAltF5     = $6C00;
    kbAltF6     = $6D00;    kbAltF7     = $6E00;    kbAltF8     = $6F00;
    kbAltF9     = $7000;    kbAltF10    = $7100;    kbAltF11    = $8B00;
    kbAltF12    = $8C00;    kbCtrl2     = $0300;    kbCtrl6     = $071E;
    kbAlt1      = $7800;    kbAlt2      = $7900;    kbAlt3      = $7A00;
    kbAlt4      = $7B00;    kbAlt5      = $7C00;    kbAlt6      = $7D00;
    kbAlt7      = $7E00;    kbAlt8      = $7F00;    kbAlt9      = $8000;
    kbAlt0      = $8100;    kbCtrlA     = $1E01;    kbCtrlB     = $3002;
    kbCtrlC     = $2E03;    kbCtrlD     = $2004;    kbCtrlE     = $1205;
    kbCtrlF     = $2106;    kbCtrlG     = $2207;    kbCtrlH     = $2308;
    kbCtrlI     = $1709;    kbCtrlJ     = $240A;    kbCtrlK     = $250B;
    kbCtrlL     = $260C;    kbCtrlM     = $320D;    kbCtrlN     = $310E;
    kbCtrlO     = $180F;    kbCtrlP     = $1910;    kbCtrlQ     = $1011;
    kbCtrlR     = $1312;    kbCtrlS     = $1F13;    kbCtrlT     = $1414;
    kbCtrlU     = $1615;    kbCtrlV     = $2F16;    kbCtrlW     = $1117;
    kbCtrlX     = $2D18;    kbCtrlY     = $1519;    kbCtrlZ     = $2C1A;
    kbAltA      = $1E00;    kbAltB      = $3000;    kbAltC      = $2E00;
    kbAltD      = $2000;    kbAltE      = $1200;    kbAltF      = $2100;
    kbAltG      = $2200;    kbAltH      = $2300;    kbAltI      = $1700;
    kbAltJ      = $2400;    kbAltK      = $2500;    kbAltL      = $2600;
    kbAltM      = $3200;    kbAltN      = $3100;    kbAltO      = $1800;
    kbAltP      = $1900;    kbAltQ      = $1000;    kbAltR      = $1300;
    kbAltS      = $1F00;    kbAltT      = $1400;    kbAltU      = $1600;
    kbAltV      = $2F00;    kbAltW      = $1100;    kbAltX      = $2D00;
    kbAltY      = $1500;    kbAltZ      = $2C00;    kbAltPlus   = $4E00;
    kbAltMinus  = $4A00;    kbPlus      = $4E2B;    kbMinus     = $4A2D;
    kbCtrlPlus  = $9000;    kbCtrlMinus = $8E00;


IMPLEMENTATION

END.