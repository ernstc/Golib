{ by Ernesto CIANCIOTTA Productions }

{ Modulo contenente funzioni che restituiscono menu demo }

unit __menu;

interface

{$D-}
{$L-}

  uses
        paths,
        codici,
        golib_h,
        golib9,
        menu,
      {$IFDEF ToolBarResInCode}
        t_barRes,
      {$ENDIF}
        resman,
        roma,
        statusln
        ;


  function GetDemoMenu:OPMenuLine;
  function GetDemoMenu2:OPMenuLine;
  function GetDemoMenu3:OPMenuLine;
  function GetDemoMenu4:OPMenuLine;


type
     OPDemoStatusLine = ^OTDemoStatusLine;
     OTDemoStatusLine = object (OTStatusLine)
        procedure Hints(MessageCode:word); virtual;
     end;


implementation


  function GetDemoMenu:OPMenuLine;
  begin
  GetDemoMenu:=new(OPMenuLine,
       Init(
          NewItem('@File',Null_ID,_Attivo_,
             NewItemPP('@Nuovo...',Null_ID,0,itEnable,_No_SubMenu_,
             NewItemPP('@Apri',Null_ID,0,itEnable or itMarcable or itMarked,_No_SubMenu_,
             NewItemPP('@Chiudi',_CHIUDI_FINESTRA_,0,itEnable,_No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('Esci',_ESCI_,0,itEnable,_No_SubMenu_,
             nil))))),
          NewItem('@GOLIB 1.0',Null_ID,_Attivo_,
             NewItemPP('@Memoria libera...',789,0,itEnable,_No_SubMenu_,
             NewItemPP('@Programmato da...',Null_ID,0,itEnable,
                NewItemPP('       @Ernesto Cianciotta',Null_ID,0,itEnable,_No_SubMenu_,
                NewSEPARATOR_PP(
                NewItemPP('             1994/96',Null_ID,0,itEnable,_No_SubMenu_,
                NewSEPARATOR_PP(
                NewItemPP('con Borland Pascal 7.0    &',Null_ID,0,itDisable,_No_SubMenu_,
                NewItemPP('con Turbo Assembler 2.0',Null_ID,0,itDisable,_No_SubMenu_,
                nil)))))),
             nil)),
          NewItem('@Window',Null_ID,_Attivo_,
             NewItemPP('@Zoom',_ZOOM_FINESTRA_,0,itEnable,_No_SubMenu_,
             NewItemPP('@Mouvi',_MUOVI_OGGETTO_,0,itDisable,_No_SubMenu_,
             NewItemPP('@Ridimensiona',_RIDIMENSIONA_FINESTRA_,0,itEnable,_No_SubMenu_,
             NewItemPP('Ri@duci',_RIDUCI_FINESTRA_,0,itEnable,_No_SubMenu_,
             NewItemPP('@Chiudi',_CHIUDI_FINESTRA_,0,itEnable,_No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('Nasc@ondi',_NASCONDI_FINESTRA_,0,itEnable,_No_SubMenu_,
             NewItemPP('Scopri...',Null_ID,0,itDisable or itMarcable or itMarked,_No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('Cambia Nome',10102,0,itEnable,_No_SubMenu_,
             NewItemPP('Aggiungi Tasto',10103,0,itEnable,_No_SubMenu_,
             NewItemPP('Occulta',10104,0,itEnable,_No_SubMenu_,
             nil)))))))))))),
          NewItem('@Help',Null_ID,not _Attivo_,_No_SubMenu_,
          nil))))
       )
    );
  end;


  function GetDemoMenu2:OPMenuLine;
  begin
    GetDemoMenu2:=new(OPMenuLine,
       Init(
          NewItem('@File',Null_ID,_Attivo_,
             NewItemPP('@Memoria libera...',789,0,itEnable,_No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('@Nuovo...',Null_ID,0,itEnable or itMarcable or itMarked,_No_SubMenu_,
             NewItemPP('@Apri',Null_ID,0,itDisable or itMarcable or itMarked,_No_SubMenu_,
             NewItemPP('@Chiudi',_CHIUDI_FINESTRA_,0,itEnable,_No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('Esci',Null_ID,0,itEnable,
                NewItemPP('@Si',Null_ID,0,itEnable,
                   NewItemPP('@Domani...',_ESCI_,0,itEnable,
                      NewItemPP('E'' un altro giorno',_ESCI_,0,itDisable,
                         NewItemPP('E dopo domani chi lo sÖ',_ESCI_,0,itEnable,
                            NewItemPP('Arrivederci !',_ESCI_,0,itEnable,
                               NewItemPP('-- Bye Bye --',_ESCI_,0,itEnable,_No_SubMenu_,
                               nil),
                            nil),
                         nil),
                      nil),
                   NewSEPARATOR_PP(
                   NewItemPP('D@opo domani',Null_ID,0,itEnable or itMarcable or itMarked,_No_SubMenu_,
                   NewItemPP('Il Mese prossimo',Null_ID,0,itEnable or itMarcable,_No_SubMenu_,
                   NewItemPP('In questo istante !',_ESCI_,0,itEnable,_No_SubMenu_,
                   nil))))),
                NewSEPARATOR_PP(
                NewItemPP('@No',Null_ID,0,itEnable,_No_SubMenu_,
                nil))),
             nil))))))),
          NewItem('@Window',Null_ID,_Attivo_,
             NewItemPP('@Zoom',_ZOOM_FINESTRA_,0,itEnable,_No_SubMenu_,
             NewItemPP('@Mouvi',_MUOVI_OGGETTO_,0,itDisable,_No_SubMenu_,
             NewItemPP('@Ridimensiona',_RIDIMENSIONA_FINESTRA_,0,itEnable,_No_SubMenu_,
             NewItemPP('Ri@duci',_RIDUCI_FINESTRA_,0,itEnable,_No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('Nasc@ondi',_NASCONDI_FINESTRA_,0,itEnable,_No_SubMenu_,
             NewItemPP('Scopri...',Null_ID,0,itDisable or itMarked,_No_SubMenu_,
             nil))))))),
          NewItem('GOLIB',Null_ID,_Attivo_,
             NewItemPP('ABCDEFGHILMNOPQRSTUVZJKWXY',Null_ID,0,itEnable,_No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('abcdefghilmnopqrstuvzjkwxy',Null_ID,0,itEnable,_No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('<>,.-;:_@@#ïÖóá¯[]ä+Ç*\|''ç!"ú$%&/()=?^',Null_ID,0,itEnable,_No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('1234567890',Null_ID,0,itEnable,_No_SubMenu_,
             nil))))))),
          NewItem('1.@0',Null_ID,_Attivo_,_No_SubMenu_,
          NewItem('@Programmato da...',Null_ID,_Attivo_,
             NewItemPP(' @Ernesto Cianciotta',Null_ID,0,itEnable,_No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('      1994/96',Null_ID,0,itEnable,_No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('con Turbo Pascal 7.0',Null_ID,0,itDisable,_No_SubMenu_,
             nil))))),
          NewItem('@Help',Null_ID,not _Attivo_,_No_SubMenu_,
          nil))))))
       )
    );
  end;


  function GetDemoMenu3:OPMenuLine;
  begin
  SetRESFileName(Work_Dir+'golib8.bmp\t_bar2.res');
  GetDemoMenu3:=new(OPMenuLine,
       Init(
          NewItem('@File',Null_ID,_Attivo_,
             NewItemPP('Nuov@o...',Null_ID,1,itEnable,_No_SubMenu_,
             NewItemPP('A@pri',Null_ID,2,itEnable or itMarcable or itMarked,_No_SubMenu_,
             NewItemPP('Chi@udi',_CHIUDI_FINESTRA_,3,itEnable,_No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('Esci',_ESCI_,4,itEnable,_No_SubMenu_,
             nil))))),
          NewItem('@GOLIB 1.0',Null_ID,_Attivo_,
             NewItemPP('Mem@oria libera...',789,0,itEnable,_No_SubMenu_,
             NewItemPP('@Programmato da...',Null_ID,0,itEnable,
              (*
                {$IFDEF ToolBarResInCode}
                NewBitmapPP_GetRES(Null_ID,0,Lavinia,@ToolBar_RESOURCES,NumeroBitmaps,itEnable,
                {$ELSE}
                NewBitmapPP_LoadRES(Null_ID,0,Lavinia,ToolBarRESFile,itEnable,
                {$ENDIF}
              *)
                   NewItemPP('ROMA',Null_ID,10,itEnable,_No_SubMenu_,
              (*
                nil),
              *)
                NewItemPP(' @Ernesto Cianciotta',Null_ID,11,itEnable,_No_SubMenu_,
                NewSEPARATOR_PP(
                NewItemPP('      1994/96',Null_ID,12,itEnable,_No_SubMenu_,
                NewSEPARATOR_PP(
                NewItemPP('con @Turbo Pascal 7.0',Null_ID,0,itDisable,_No_SubMenu_,
                nil)))))),
             nil)),
          NewItem('@Window',Null_ID,_Attivo_,
             NewItemPP('@Zoom',_ZOOM_FINESTRA_,20,itEnable,_No_SubMenu_,
             NewItemPP('@Mouvi',_MUOVI_OGGETTO_,0,itDisable,_No_SubMenu_,
             NewItemPP('@Ridimensiona',_RIDIMENSIONA_FINESTRA_,0,itEnable,_No_SubMenu_,
             NewItemPP('Ri@duci',_RIDUCI_FINESTRA_,0,itEnable,_No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('Nasc@ondi',_NASCONDI_FINESTRA_,0,itEnable,_No_SubMenu_,
             NewItemPP('Scopri...',Null_ID,0,itDisable or itMarcable or itMarked,_No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('Occulta',10104,0,itEnable,_No_SubMenu_,
             nil))))))))),
          NewItem('@Sports',Null_ID,_Attivo_,
             NewItemPP('Calcio',Null_ID,0,itDisable,_No_SubMenu_,
             NewBitmapPP_LoadRES(Null_ID,0,Cristina+1,Work_Dir+'golib8.bmp\t_bar2.res',itEnable or itMarcable or itMarked,
             _No_SubMenu_,
             NewSEPARATOR_PP(
             NewItemPP('Tennis',Null_ID,0,itDisable,_No_SubMenu_,
             NewBitmapPP_LoadRES(Null_ID,0,Cristina,Work_Dir+'golib8.bmp\t_bar2.res',itEnable or itMarcable or itMarked,
             _No_SubMenu_,
             nil))))),
          NewItem('@Sports 2',Null_ID,_Attivo_,
             NewItemPP('Calcio/Tennis',Null_ID,0,itDisable,_No_SubMenu_,
             NewBitmapPP(Null_ID,0,Cristina+1,Cristina,itEnable,
             _No_SubMenu_,
             nil)),
          NewItem('@Help',Null_ID,not _Attivo_,_No_SubMenu_,
          nil))))))
       )
    );
  end;



  function GetDemoMenu4:OPMenuLine;
  begin
  GetDemoMenu4:=new(OPMenuLine,
       Init(
          NewItem('@File',Null_ID,_Attivo_,_No_SubMenu_,
          NewItem('@GOLIB 1.0',Null_ID,_Attivo_,_No_SubMenu_,
          NewItem('@Window',Null_ID,_Attivo_,_No_SubMenu_,
          NewItem('@Sports',Null_ID,_Attivo_,_No_SubMenu_,
          NewItem('@Help',Null_ID,_Attivo_,_No_SubMenu_,
          nil)))))
       )
    );
  end;



  procedure OTDemoStatusLine.Hints(MessageCode:word);
    begin
      case MessageCode of
      1: SetMessage(MAIN_MESSAGE_FIELD,'Crea un nuovo file.');
      2: SetMessage(2{MAIN_MESSAGE_FIELD},'Apre un file esistente.');
      3: SetMessage(MAIN_MESSAGE_FIELD,'Chiude la finestra attiva.');
      4: SetMessage(2{MAIN_MESSAGE_FIELD},'Esce dall''applicazione.');
      10: SetMessage(1{MAIN_MESSAGE_FIELD},'Bella cittÖ.');
      11: SetMessage(1{MAIN_MESSAGE_FIELD},'Programmatore di GOLIB.');
      12: SetMessage(1{MAIN_MESSAGE_FIELD},'Da Settembre ad Agosto.');
      20: SetMessage(1{MAIN_MESSAGE_FIELD},'Ingrandisce la finestra. 88888888888888888888888');
      else inherited Hints(MessageCode);
      end;
    end;


end.