{ by ERNESTO CIANCIOTTA Productions }

{***********************************************************}
{*                                                         *}
{*  Modulo per la gestione dei file di inizializzazione    *}
{*  con estenzione INI.                                    *}
{*  Questi files sono di tipo testo due tipici esempi sono *}
{*  i files WIN.INI e SYSTEM.INI.                          *}
{*                                                         *}
{*  N.B.: Possono essere aperti massimo 10 files di        *}
{*        inizializzazione.                                *}
{*                                                         *}
{*  Scritto con Turbo Pascal ver 7.0.                      *}
{*                                                         *}
{***********************************************************}

{$D+}
{$L+}


UNIT INI;

INTERFACE


const
      MaxINIfiles = 10;


type

     OPItem = ^OTItem;
     OTItem = object
        name: PChar;
        value: PChar;
     private
        next: OPItem;
     end;


     OPSection = ^OTSection;
     OTSection = object
     private
        Name: PChar;
        items: OPItem;
        next: OPSection;
     end;


     OPInitFile = ^OTInitFile;
     OTInitFile = object
        function Init(FileName:PChar):boolean;
        procedure Done;
        { Metodi per al selezione delle sezioni del file.INI }
        function  SelectSection(SectionName:PChar):boolean;
        procedure FindFirstSection(var SectionName:PChar);
        procedure FindNextSection(var SectionName:PChar);
        { Metodi per accedere alle voci della sezione selezionata }
        function  FindItem(ItemName:PChar; var item:OTItem):boolean;
        procedure FindFirstItem(var item:OTItem);
        procedure FindNextItem(var item:OTItem);
        { Metodi per ottenere informazioni sullo stato del gestore
          sul file }
        { TRUE se sono finite le voci della sezione corrente }
        function  EndOfSection:boolean;
        { TRUE se sono finite le sezioni del file .INI }
        function  EndOfFile:boolean;
        function  SectionSelected:PChar;
        { Metodi per la candellazione di voci e sezioni }
        procedure DeleteSelectedSection;
        function  DeleteSection(SectionName:PChar):boolean;
        procedure DeleteAllSections;
        function  DeleteItem(Item:PChar):boolean;
        procedure DeleteAllItems;
        { Metodi per l'aggiornamento delle sezioni e delle voci }
        procedure RenameSelectedSection(newName:PChar);
        function  RenameSection(OldSectionName, NewName:PChar):boolean;
        { Controlla se gi… esiste item e in questo caso la aggiorna, altrimenti
          aggiunge direttamente item alla sezione }
        function  UpdateItem(var item:OTItem):boolean;
        { Aggiunge una nuova sezione al file .INI }
        procedure NewSection(SectionName:PChar);
        { Aggiunge direttamente item alla sezione }
        procedure NewItem(var item:OTItem);
     private
        FName: PChar;
        sections: OPSection;

        modified: boolean;
     end;



IMPLEMENTATION

{ OTInitFile crea una struttura ad albero dal file di testo al momento della
  sua inizializzazione e successivamente lavora solo su questa struttura.
  Al momento della distruzione, se la struttura Š stata modificata, ricrea
  il file di testo partendo dalla struttura ad albero. }


uses strings;

type
    TProc = procedure;

var
    iniFile : array[1..MaxINIfiles] of OPInitFile;
    numFiles:word;



                     {----- OTInitFile -----}
    function OTInitFile.Init(FileName:PChar):boolean;
      var FInit:text;
          Errore:boolean;
          str:string; {buffer}
          lastSection:OPSection;
          lastItem:OPItem;


      procedure CreaSezione;
        var buf:OPSection;
            item:OPItem;
            equal:byte;
        begin
          new(buf);
          buf^.Name:=StrNewPas(str);
          buf^.next:=nil;
          if Sections=nil
            then begin
              Sections:=buf;
              lastSection:=buf;
            end
            else begin
              lastSection^.next:=buf;
              lastSection:=buf;
            end;
          while not eof(FInit) do begin
            readln(FInit,str);
            if str[1]='[' then exit;
            equal:=pos('=',str);
            if equal<>0 then begin
              new(item);
              item^.name:=StrNewPas(copy(str,1,equal-1));
              item^.value:=StrNewPas(copy(str,equal+1,length(str)-equal));
              item^.next:=nil;
              if lastItem=nil
                then begin
                  lastItem:=item;
                  buf^.items:=item;
                end
                else begin
                  lastItem^.next:=item;
                  lastItem:=item;
                end;
            end;
          end;
        end;


      function PrendiSezione:boolean;
        var d:byte;
        begin
          PrendiSezione:=false;
          repeat
            if str[1]='[' then begin
              d:=pos(']',str);
              str:=copy(str,2,d-2);
              PrendiSezione:=true;
              lastItem:=nil;
              CreaSezione;
              break;
            end;
            readln(FInit,str);
          until eof(FInit);
        end;


      begin
        FName:=StrNew(FileName);
        modified:=false;
        { Apertura del file }
        assign(FInit,FileName);
        {$I-}
        reset(FInit);
        {$I+}
        if ioresult<>0 then begin
          StrDispose(FName);
          Init:=false;
          exit;
        end;
        Init:=true;
        { Creazione dell'albero }
        sections:=nil;
        str:=' ';
        while PrendiSezione do;
        close(FInit);
      end;


    procedure OTInitFile.Done;
      begin
      end;


    function  OTInitFile.SelectSection(SectionName:PChar):boolean;
      begin
      end;


    procedure OTInitFile.FindFirstSection(var SectionName:PChar);
      begin
      end;


    procedure OTInitFile.FindNextSection(var SectionName:PChar);
      begin
      end;


    function  OTInitFile.FindItem(ItemName:PChar; var item:OTItem):boolean;
      begin
      end;


    procedure OTInitFile.FindFirstItem(var item:OTItem);
      begin
      end;


    procedure OTInitFile.FindNextItem(var item:OTItem);
      begin
      end;


    function  OTInitFile.EndOfSection:boolean;
      begin
      end;


    function  OTInitFile.EndOfFile:boolean;
      begin
      end;


    function  OTInitFile.SectionSelected:PChar;
      begin
      end;


    procedure OTInitFile.DeleteSelectedSection;
      begin
      end;


    function  OTInitFile.DeleteSection(SectionName:PChar):boolean;
      begin
      end;


    procedure OTInitFile.DeleteAllSections;
      begin
      end;


    function  OTInitFile.DeleteItem(Item:PChar):boolean;
      begin
      end;


    procedure OTInitFile.DeleteAllItems;
      begin
      end;


    procedure OTInitFile.RenameSelectedSection(newName:PChar);
      begin
      end;


    function  OTInitFile.RenameSection(OldSectionName, NewName:PChar):boolean;
      begin
      end;


    function  OTInitFile.UpdateItem(var item:OTItem):boolean;
      begin
      end;


    procedure OTInitFile.NewSection(SectionName:PChar);
      begin
      end;


    procedure OTInitFile.NewItem(var item:OTItem);
      begin
      end;



var
    i:word;
    precExitProc: pointer;


    procedure INIExitProc; far;
      begin
        for i:=1 to numFiles do iniFile[i]^.Done;
      end;


BEGIN
  {for i:=1 to MaxINIfiles do iniFile[i]:=nil;
  numFiles:=0;
  precExitProc:=ExitProc;
  ExitProc:=@INIExitProc;}
END.

















