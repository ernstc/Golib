{ by Ernesto CIANCIOTTA Productions }

{*************************************************************************}
{*                                                                       *}
{*  Interfaccia alla memoria estesa.                                     *}
{*                                                                       *}
{*  Scritto con Turbo Pascal 7.0.                                        *}
{*                                                                       *}
{*************************************************************************}

UNIT XMS;

INTERFACE


{$IFDEF debugging}
  const
       XMSForApplication = 1024;
{$ENDIF}


type
     THandleInfo = record
        lock_count:byte;
        NFHL:byte; { number of free handles left }
        size:word;
     end;


     TOfs = record
       case boolean of
       false: ( ofs: longint;
               );
       true : ( ptr: pointer;
               );
     end;


     EMMStructure = record
        NumBytes : longint;
        source   : word;
        sourceOfs: TOfs;
        dest     : word;
        destOfs  : TOfs;
     end;

var
    XMS_ErrorCode: byte;
    XMS_Available: boolean;
    XMS_Ver, XMS_RevNum: word;



    (*********************************************************************
         Chiamare questa funzione all'inizio dei programmi che fanno
         uso della memoria estesa durante il debuging.
    *********************************************************************)

    procedure AccessToXMS;

    (*********************************************************************
         Chiamare questa funzione alla fine dei programmi che fanno
         uso della memoria estesa durante il debuging.
    *********************************************************************)

    procedure PreserveXMS;



    function GetXMSEntryPoint:pointer;
    procedure AllocXMS(var handle:word; mem:word);
    procedure DeallocXMS(var handle:word);
    procedure MoveXMSBlock(var EMM: EMMStructure);
    procedure FreeExtendedMemory(var Largest,Total:word);
    procedure GetHandleInfo(handle:word; var info:THandleInfo);



IMPLEMENTATION


uses
     dos
     {$IFDEF debugging}
     ,
     crt,
     utility
     {$ENDIF}
     ;

var
    EP_offset, EP_segment: word;
    XMS_EntryPoint: procedure absolute EP_offset;
    XMS_drv_pointer:pointer absolute XMS_EntryPoint;




{$IFDEF debugging}

const
      PreservedXMS_Size:word=0;

    procedure AccessToXMS;
      var f:file of word;
          handle:word;
          info:THandleInfo;

      procedure CheckError1;
        begin
          if XMS_ErrorCode<>0 then begin
            writeln('Impossibile accedere al blocco di lavoro della memoria estesa.'#13#10#13#10+
                    'Codice d''errore XMS  ',HexW(XMS_ErrorCode),#13#10#13#10+
                    'Il file HANDLE.XMS contiene un handle errato o non pi— disponibile.'#13#10+
                    'Si consiglia di riavviare il computer e poi l''utility ALLOCXMS.EXE'#13#10+
                    'prima di rieseguire questo programma.');
            halt(XMS_ErrorCode);
          end;
        end;

      begin
        if not XMS_Available then begin
          writeln('Il driver per la memoria estesa non Š installato.'#13#10#13#10+
                  'Verificare che la seguente linea sia presente nel CONFIG.SYS:'#13#10#13#10+
                  'DEVICE = HIMEM.SYS');
          halt(XMS_ErrorCode);
        end;
        assign(f,'c:\handle.xms');
        {$I-}
        reset(f);
        {$I+}
        if ioresult=0 then begin
          read(f,handle);
          GetHandleInfo(handle,info); CheckError1;
          PreservedXMS_Size:=info.size;
          DeallocXMS(handle);         CheckError1;
        end
        else begin
          writeln('Impossibile accedere al file HANDLE.XMS'#13#10#13#10+
                  'Uscire dall''IDE, eseguire l''utility ALLOCXMS.EXE e tornare nell''IDE per'#13#10+
                  'rieseguire il programma.');
          halt(ioresult);
        end;
        close(f);
        erase(f);
      end;


    procedure PreserveXMS;
      var f:file of word;
          handle:word;
      begin
        if PreservedXMS_Size=0 then begin
          writeln('E'' stata chiamata la procedura "PreserveXMS" prima di "AccessToXMS".');
          exit;
        end;
        AllocXMS(handle,PreservedXMS_Size);
        if XMS_ErrorCode<>0 then begin
          writeln('Durante la chiusura dell''applicazione Š impossibile ripristinare'#13#10+
                  'il buffer tampone nella memoria XMS.'#13#10#13#10+
                  'E'' probabile che l''applicazione non abbia provveduto a deallocare'#13#10+
                  'tutti i blocchi allocati durante l''esecuzione.'#13#10#13#10+
                  'Uscire dall''IDE ed eseguire l''utility ALLOCXMS.EXE e rientrare nell''IDE.'#13#10#13#10+
                  'Se l''utility non riesce nel suo intento riavviare il computer.');
          halt(XMS_ErrorCode);
        end;
        assign(f,'c:\handle.xms');
        rewrite(f);
        write(f,handle);
        close(f);
      end;
{$ENDIF}




    function GetXMSEntryPoint:pointer;
      begin
        GetXMSEntryPoint:=pointer(XMS_drv_pointer);
      end;


    procedure XMS_Detect; assembler;
    asm
       { Controlla se HIMEM.SYS Š installato }
       mov        ax,4300h
       int        2Fh
       cmp        al,80h
       jne        @noDriver
     {* Il driver Š installato *}
       mov        XMS_Available,01h
       { Preleva l'entry point  del driver }
       mov       ax,4310h
       int       2Fh
       mov       EP_offset,bx
       mov       EP_segment,es
       { Preleva la versione del driver }
       xor        ah,ah
       call       XMS_EntryPoint
       mov        XMS_Ver,ax
       mov        XMS_RevNum,bx
       jmp        @end
    @noDriver:
     {* Il driver non Š installato *}
       mov        XMS_Available,00h
    @end:
    end;


    procedure AllocXMS(var handle:word; mem:word); assembler;
    asm
       mov        dx,mem
       mov        ah,09h
       call       XMS_EntryPoint
       les        di,handle
       mov        WORD PTR es:[di],dx
       mov        XMS_ErrorCode,bl
    end;


    procedure DeallocXMS(var handle:word); assembler;
    asm
       les        di,handle
       mov        dx,WORD PTR es:[di]
       mov        ah,0Ah
       call       XMS_EntryPoint
       mov        XMS_ErrorCode,bl
    end;


    procedure MoveXMSBlock(var EMM: EMMStructure); assembler;
      asm
        push      ds
        lds       si,EMM
        mov       ah,0Bh
        call      XMS_EntryPoint
        pop       ds
      end;


    procedure FreeExtendedMemory(var Largest,Total:word); assembler;
    asm
       mov        ah,08h
       xor        bl,bl
       call       XMS_EntryPoint
       les        di,Largest
       mov        WORD PTR es:[di],ax
       les        di,Total
       mov        WORD PTR es:[di],dx
       mov        XMS_ErrorCode,bl
    end;


    procedure GetHandleInfo(handle:word; var info:THandleInfo); assembler;
    asm
       mov        ah,0Eh
       mov        dx,handle
       call       XMS_EntryPoint
       cmp        ax,0001h
       jne        @end
       les        di,info
       mov        es:[di+THandleInfo.lock_count],bh
       mov        es:[di+THandleInfo.NFHL],bl
       mov        es:[di+THandleInfo.size],dx
       mov        XMS_ErrorCode,0
       jmp        @end
    @error:
       mov        XMS_ErrorCode,bl
    @end:
    end;






BEGIN
{$IFDEF debugging}
  clrscr;
{$ENDIF}
  XMS_Detect;
END.