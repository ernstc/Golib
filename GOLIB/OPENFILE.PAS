{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



{$I-}

UNIT OpenFile;

INTERFACE


const
    AutoHaltApplication: boolean = false;


var
    LastIOResult:word;


    { Le funzioni che seguono effettuano una validazione del nome del file
      restuendo un codice d'errore e il relativo messaggio in formato stringa. }

    function ValidFileName(FileName:string):word;

    function __ValidFileName(FileName:PChar):word;

    { Restituisce il messaggio corrispondente al Runtime Error passatole }
    function GetRunErrorMessage(ErrorCode:word):string;

    function ResetFile(var f; FileName:string; recordSize:word):word;
    function __ResetFile(var f; FileName:PChar; recordSize:word):word;
    function ResetTextFile(var f:Text; FileName:string):word;
    function __ResetTextFile(var f:Text; FileName:PChar):word;

    procedure HaltApplication(ErrorCod:word);


IMPLEMENTATION



    function GetRunErrorMessage(ErrorCode:word):string;
      begin
        case ErrorCode of
          1 : GetRunErrorMessage:='Numero della funzione non valido';
          2 : GetRunErrorMessage:='File non trovato';
          3 : GetRunErrorMessage:='Path non trovato';
          4 : GetRunErrorMessage:='Troppi files aperti';
          5 : GetRunErrorMessage:='Accesso al file negato';
          6 : GetRunErrorMessage:='File handle non valido';

{ Run Error generato dalle procedure del modulo OpenFile.TPU }
          7 : GetRunErrorMessage:='Nome del file errato';

         12 : GetRunErrorMessage:='Codice d''accesso al file non valido';
         15 : GetRunErrorMessage:='Il numeor del drive non Š valido';
         16 : GetRunErrorMessage:='Non Š possibile rimuovere la directory corrente';
         17 : GetRunErrorMessage:='Non Š possibile rinominare attraverso i drives';
         18 : GetRunErrorMessage:='Non ci sono altri files';
        100 : GetRunErrorMessage:='Errore durante al lettura del disco';
        101 : GetRunErrorMessage:='Errore durante la scrittura del disco';
        102 : GetRunErrorMessage:='File non assegnato';
        103 : GetRunErrorMessage:='File non aperto';
        104 : GetRunErrorMessage:='File non aperto per l''input';
        105 : GetRunErrorMessage:='File non aperto per l''output';
        106 : GetRunErrorMessage:='Formato numerico non valido';
        150 : GetRunErrorMessage:='Il disco Š protetto da scrittura';
        151 : GetRunErrorMessage:='Lunghezza della struttura richiesta dal drive errata';
        152 : GetRunErrorMessage:='Il drive non Š pronto';
        154 : GetRunErrorMessage:='Errore CRC nei dati';
        156 : GetRunErrorMessage:='Errore la Seek del disco';
        157 : GetRunErrorMessage:='Il tipo disco nel drive Š sconosciuto';
        158 : GetRunErrorMessage:='Settore non trovato';
        159 : GetRunErrorMessage:='Si Š esaurita la carta della stampante';
        160 : GetRunErrorMessage:='Difetto hardware durante la scrittura sul dispositivo';
        161 : GetRunErrorMessage:='Difetto hardware durante la lettura dal dispositivo';
        162 : GetRunErrorMessage:='Guasto hardware';
        200 : GetRunErrorMessage:='Divisione per zero';
        201 : GetRunErrorMessage:='Range check error';
        202 : GetRunErrorMessage:='Stack overflow error';
        203 : GetRunErrorMessage:='Heap overflow error';
        204 : GetRunErrorMessage:='Operazione sul puntatore non valida';
        205 : GetRunErrorMessage:='Floating point overflow';
        206 : GetRunErrorMessage:='Floating point underflow';
        207 : GetRunErrorMessage:='Operazione floating point non valida';
        208 : GetRunErrorMessage:='Overlay manager non installato';
        209 : GetRunErrorMessage:='Overlay file read error';
        210 : GetRunErrorMessage:='Oggetto non inizializzato';
        215 : GetRunErrorMessage:='Arithmetic overflow error';
        216 : GetRunErrorMessage:='General Protection fault';
        else GetRunErrorMessage:='';
        end;
      end;


    { Questa procedura, interna al modulo, verifica se il file si riferisce
      ad un file inesistente o se il nome del file Š errato.
      In quest'ultimo caso corregge LastIOResult e lo imposta al valore 7.
    }
    procedure ValidCorrectFileName(var f);
      var _f:file absolute f;
      begin
        LastIOResult:=ioresult;
        if (LastIOResult<>2) and (LastIOResult<>3) then exit;
        rewrite(_f);
        if ioresult<>0
          then LastIOResult:=7
          else begin
            close(_f);
            erase(_f);
          end;
      end;


    function ValidFileName(FileName:string):word;
      var f:file;
      begin
        assign(f,FileName);
        reset(f);
        ValidCorrectFileName(f);
        if LastIOResult=0 then close(f);
        ValidFileName:=LastIOResult;
      end;


    function __ValidFileName(FileName:PChar):word;
      var f:file;
      begin
        assign(f,FileName);
        reset(f);
        ValidCorrectFileName(f);
        if LastIOResult=0 then close(f);
        __ValidFileName:=LastIOResult;
      end;

   {

   if ResetFile(f,'xxxxxxxx.xxx',sizeof(Tipo Record)) <> 0
   then
     HaltApplication(LastIOresult);

   }
    function ResetFile(var f; FileName:string; recordSize:word):word;
      var generic_file:file absolute f;
      begin
        assign(generic_file,FileName);
        reset(generic_file,recordSize);
        ValidCorrectFileName(generic_file);
        ResetFile:=LastIOResult;
        if AutoHaltApplication and (LastIOResult<>0) then HaltApplication(LastIOresult);
      end;


    function __ResetFile(var f; FileName:PChar; recordSize:word):word;
      var generic_file:file absolute f;
      begin
        assign(generic_file,FileName);
        reset(generic_file,recordSize);
        ValidCorrectFileName(generic_file);
        __ResetFile:=LastIOResult;
        if AutoHaltApplication and (LastIOResult<>0) then HaltApplication(LastIOresult);
      end;


    function ResetTextFile(var f:Text; FileName:string):word;
      begin
        assign(f,FileName);
        reset(f);
        ValidCorrectFileName(f);
        ResetTextFile:=LastIOResult;
        if AutoHaltApplication and (LastIOResult<>0) then HaltApplication(LastIOresult);
      end;


    function __ResetTextFile(var f:Text; FileName:PChar):word;
      begin
        assign(f,FileName);
        reset(f);
        ValidCorrectFileName(f);
        __ResetTextFile:=LastIOResult;
        if AutoHaltApplication and (LastIOResult<>0) then HaltApplication(LastIOresult);
      end;


    procedure HaltApplication(ErrorCod:word);
      begin
        writeln(#10#13'Runtime error ',ErrorCod:4,
                #10#13'Descrizione errore:'#10#13,' ':20,GetRunErrorMessage(LastIOResult));
        halt(LastIOResult);
      end;





END.