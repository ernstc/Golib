{by Ernesto CIANCIOTTA Productions}

{$M 3072,0,0}

{$D-}
{$L-}
{$I-}
{$R-}
{$S-}
{$E-}
{$Y-}

uses crt,
     utility,
     xms;



function ErrorCodeOK:boolean;
  begin
    if XMS_ErrorCode<>0 then begin
      writeln('Operazione fallita. Codice d''errore ',HexW(XMS_ErrorCode));
      halt(XMS_ErrorCode);
    end
    else ErrorCodeOK:=true;
  end;


procedure Pausa;
  begin
    textattr:=$30;
    gotoxy(1,19);  clreol;
    write('Premi un tasto per continuare . . .');
    textattr:=$07;
    readkey;
    clrscr;
  end;


var handle,l,t:word;
    info:THandleInfo;
    f:file of word;
    driverstr:string;
    XMS_EntryPoint:pointer;
    mega:byte;

begin
  if paramcount>0
    then begin
      mega:=StrNum(paramStr(1));
      if mega=0 then mega:=1;
    end
    else mega:=1;
  clrscr;
  if not XMS_Available then begin
    writeln('Nessun driver per la memoria estesa.');
    halt($FFFF);
  end;
  XMS_EntryPoint:=GetXMSEntryPoint;
  driverstr:='HIMEM.SYS ver '+NumStr(hi(XMS_RevNum))+'.'++NumStr(lo(XMS_RevNum));
  textattr:=$1F;
  writeln('Driver per la memoria estesa installato:',driverstr:39);
  textattr:=$0E;
  writeln;
  writeln('Entry point ',HexW(seg(XMS_EntryPoint^)),':',HexW(ofs(XMS_EntryPoint^)));
  textattr:=$07;
  writeln;
  window(1,6,80,25);
  writeln('Questo programma alloca un buffer di ',mega,' Mb nella memoria estesa per poter'#13#10+
          'fare il debug di programmi che usano la memoria estesa, in ambienti che'#13#10+
          'allocano tutta la memoria XMS.');
  writeln;
  writeln('Una volta allocato il buffer viene registrato il suo HANDLE nel file'#13#10+
          'HANDLE.XMS');
  pausa;
  assign(f,'c:\handle.xms');
  reset(f);
  if ioresult=0 then begin
    writeln('Il file HANDLE.XMS Š gi… esistente.');
    read(f,handle);
    close(f);
    writeln('L''handle memorizzato nel file Š  ',HexW(handle));
    writeln;
    writeln('Deallocazione del buffer intercettato . . .');
    DeallocXMS(handle);
    if XMS_ErrorCode<>0 then begin
      writeln('Operazione fallita. Codice d''errore ',HexW(XMS_ErrorCode));
      writeln;
      writeln('Se precedenetmente Š stato riavviato il computer Š consigliato cancellare'#13#10+
              'manualmente il file HANDLE.XMS e rieseguire questo programma.');
      halt(XMS_ErrorCode);
    end;
    if ErrorCodeOK then writeln('. . . deallocazione del vecchio buffer effettuata.');
    writeln;
    writeln('Cancellazione del vecchio file HANDLE.XMS . . .');
    erase(f);
    if ioresult<>0 then begin
      writeln('Impossibile cancellare il file o problemi durante l''accesso al disco.');
      halt(ioresult);
    end
    else begin
      writeln('. . . cancellazione effettetata con successo.');
      pausa;
    end;
  end;
  writeln('Informazioni sulla memoria estesa libera:');
  FreeExtendedMemory(l,t);
  case XMS_ErrorCode of
    $00: begin
           writeln('- totale memoria estesa libera . . . . . . . . . . . . . . . . . ',MillesFormat(t):10,' Kb');
           writeln('- dimensione del blocco libero pi— grande  . . . . . . . . . . . ',MillesFormat(l):10,' Kb');
         end;
    $80: writeln('- funzione non disponibile !');
    $81: writeln('- intercettato il driver VDISK.SYS che ha allocato tutta la memoria XMS.');
    $A0: writeln('- tutta la memoria estesa Š stata gi… allocata.');
  end;
  writeln;
  writeln('Allocazione del buffer . . .');
  AllocXMS(handle,mega*1024);
  if ErrorCodeOK then writeln('. . . il buffer Š stato allocato e il suo handle Š  ',HexW(handle),'.');
  writeln;
  writeln('Salvataggio dell''HANDLE nel file HANDLE.XMS . . .');
  rewrite(f);
  if ioresult<>0 then begin
    writeln('Problemi nell''accesso al disco.');
    writeln('Deallocazione del buffer . . .');
    DeallocXMS(handle);
    if ErrorCodeOK then writeln('. . . il buffer Š stato deallocato deallocato.');
    halt(ioresult);
  end;
  write(f,handle);
  close(f);
  writeln('. . . salvataggio effettuato con successo.');
  writeln;
end.
