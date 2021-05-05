{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



{
 Editor di risorse Hot Spots.

 Questo programma genera dei files di risorsa oggetto (.RCG) che contengono
 dei riferimenti ad altri files di risorsa, come i cursori, che vengono
 editati con un altro editor.

 Per poter utilizzare le risorse oggetto Š necessario compilarle in
 risorse binarie (.RES) nelle quali non sono pi— contenuti riferimenti
 esterni.

 In questa versione la dimensione massima del file di risorsa (oggetto e
 binario) Š limitata a soli 65520 bytes.
}




program Editor_di_Risorse;

uses
    crt,
    dos,
    utility,
    OpenFile,
    bios_utt,
    Htp_Edit;


const
      risorsa_presente: boolean = false;
      salvato:          boolean = true;
      anonimo:          boolean = true;

var
      fileName:string;
      ext:TExtention;
      res:file;

      ch:char;



procedure aspetta;
  begin
    writeln;
    write('Premi un tasto per continuare...');
    readkey;
  end;


function Leggi_fileName(per_salvataggio:boolean):boolean;
  var ok:boolean;
      precFileName:string;
      ext:TExtention;
      ch:char;
      x,y:shortint;

  procedure AltriProblemi;
    begin
      writeln;
      writeln('ATTENZIONE!');
      writeln('  Problemi durante l''accesso al file ',fileName);
      writeln;
      writeln('Descrizione errore:');
      writeln('  ',GetRunErrorMessage(LastIOResult));
      aspetta;
    end;

  begin
    precFileName:=fileName;
    Leggi_fileName:=true;
    repeat
      clrscr;
      RipristinaCursore;
      x:=whereX;
      y:=whereY;
      fileName:=ValidRead('\X');
      EliminaCursore;
      if fileName='\' then begin
        writeln;
        writeln('ATTENZIONE!');
        writeln('  Operazione annullata.');
        delay(600);
        fileName:=precFileName;
        Leggi_fileName:=false;
        exit;
      end;
      GetExtention(fileName,ext,'RCG');
      { Riscrive il nome del file }
      gotoxy(x,y);
      write(fileName); clreol;
      writeln;
      { Controlla la validit… del nome del file inserito }
      if ResetFile(res,fileName,1)=0 then begin
        if per_salvataggio then begin
          writeln;
          writeln('ATTENZIONE!');
          writeln('  Il file Š esistente.');
          writeln;
          writeln('Vuoi sovrascriverlo ? (S/N)');
          repeat ch:=UpCase(readkey); until (ch='S') or (ch='N');
          ok:= ch='S';
        end
        else ok:=true;
        close(res);
      end
      else begin
        if (LastIOResult<>2) and (LastIOResult<>3) and (LastIOResult<>7)
          then AltriProblemi
          else begin
            if LastIOResult=7 then begin
              writeln;
              writeln('ATTENZIONE!');
              writeln('  Nome del file errato.');
              aspetta;
              ok:=false;
            end
            else begin
              if not per_salvataggio then begin
                writeln;
                writeln('ATTENZIONE!');
                writeln('  Il file non esiste.');
                aspetta;
                ok:=false;
              end
              else ok:=true;
            end;
          end;
      end;
    until ok;
  end;


procedure Menu;
  begin
    window(1,3,80,25);
    clrscr;
    writeln('Nome file:  ',fileName);
    writeln;
    textattr:=$0E;
    writeln('------------------------------  Menu Principale  ------------------------------');
    textattr:=$07;
    writeln;
    writeln('1.   Nuovo');
    writeln('2.   Apri');
    writeln('3.   Salva');
    writeln('4.   Salva come ...');
    writeln('5.   Modifica risorse');
    writeln;
    writeln('6.   Compila in formato GLBr 1.0 per Golib 97');
    writeln;
    textAttr:=3;  write('ESC');  textAttr:=7;
    writeln('. Esci');
    writeln;
    write('Scegli...');
  end;


function Salva:boolean; forward;


function Salva_come:boolean; forward;


function Chiedi_di_salvare:boolean;
  var ok:boolean;
  begin
    window(1,5,80,25);
    clrscr;
    writeln('Vuoi salvare le risorse ? (S/N)');
    ok:=false;
    repeat
      ch:=UpCase(readkey);
      if ch in ['S','N'] then ok:=true;
    until ok;
    if ch='S' then Chiedi_di_salvare:=Salva
              else Chiedi_di_salvare:=true;
  end;


procedure Nuovo;
  begin
    if risorsa_presente and (anonimo or not salvato) then Chiedi_di_salvare;
    CreaRisorsaVuota;
    salvato:=false;
    anonimo:=true;
    fileName:='Risorsa anonima';
    window(1,3,80,25);
    clreol;
    writeln('Nome file:  ',fileName);
    risorsa_presente:=EditaRisorsa;
    Menu;
  end;


procedure Apri;
  var precFileName:string;
  begin
    if risorsa_presente and (anonimo or not salvato) then Chiedi_di_salvare;
    window(1,5,80,25);
    clrscr;
    textAttr:=$0E;
    writeln('-----------------------------  Apri risorsa...  -------------------------------');
    textAttr:=$07;
    writeln;
    writeln('{\} + INVIO per annullare');
    writeln;
    writeln('Inseriscri il nome del file:');
    window(1,10,80,25);
    precFileName:=fileName;
    if Leggi_fileName(false) and ApriRisorsa(fileName) then begin
      window(1,3,80,25);
      clreol;
      writeln('Nome file:  ',fileName);
      risorsa_presente:=true;
      anonimo:=false;
      salvato:=not EditaRisorsa;
    end
    else fileName:=precFileName;
    Menu;
  end;


function Salva:boolean;
  var esito:boolean;

  procedure OK;
    var s:string;
    begin
      s:='Salvataggio del file '+fileName+' effettuato con successo !';
      TextAttr:=$0A;
      writeln(#13,s:Length(s)+(78-Length(s)) div 2);
      TextAttr:=$07;
      delay(1000);
      Menu;
    end;

  begin
    if salvato and not anonimo then begin
      Salva:=true;
      OK;
      exit;
    end;
    if anonimo or not risorsa_presente
      then esito:=Salva_come
      else begin
        esito:=true;
        SalvaRisorsa(fileName);
        risorsa_presente:=true;
        salvato:=true;
        anonimo:=false;
      end;
    if esito then OK;
    Salva:=esito;
  end;


function Salva_come:boolean;
  var   ok:boolean;
        edita:boolean;
  begin
    edita:=false;
    window(1,5,80,25);
    clrscr;
    textAttr:=$0E;
    writeln('------------------------------  Salva come ...  -------------------------------');
    textAttr:=$07;
    writeln;
    writeln('{\} + INVIO per annullare');
    writeln;
    writeln('Inseriscri il nome del nuovo file:');
    window(1,10,80,25);
    if Leggi_fileName(true) then begin
      if not risorsa_presente then begin
        CreaRisorsaVuota;
        risorsa_presente:=true;
        edita:=true;
      end;
      SalvaRisorsa(fileName);
      salvato:=true;
      anonimo:=false;
      if edita then  EditaRisorsa;
      Salva_come:=true;
    end
    else Salva_come:=false;
    Menu;
  end;


procedure Modifica;
  begin
    if not risorsa_presente
      then Nuovo
      else begin
        salvato:=not EditaRisorsa;
        Menu;
      end;
  end;


procedure Compila;
  var fName:string;
  begin
    if not risorsa_presente then begin
      TextAttr:=$0C;
      writeln(#13'Creare o aprire una risorsa sorgente (.RCG) prima di eseguire questo comando !');
      TextAttr:=$07;
      delay(2000);
    end
    else begin
      fName:=fileName;
      SetExtention(fName,'GLB');
      Compila_RCG_in_GLBr(fName);
    end;
    Menu;
  end;


procedure Esci;
  begin
    if risorsa_presente and (not salvato or anonimo)
      then if not Chiedi_di_salvare then exit;
    window(1,1,80,25);
    clrscr;
    RipristinaCursore;
    halt(0);
  end;


const anon = 'Risorsa anonima';


begin
  {$IFDEF DPMI}
  writeln('Dos Protect Mode Application');
  writeln;
  writeln('Memory Available    = ',ThousandsFormat(memavail),' bytes');
  writeln('Max Block Available = ',ThousandsFormat(maxavail),' bytes');
  delay(1500);
  {$ENDIF}
  if paramcount<>0 then begin
    fileName:=paramstr(1);
    GetExtention(fileName,ext,'RCG');
    if ValidFileName(fileName)=0
      then begin
        ApriRisorsa(fileName);
        risorsa_presente:=true;
        anonimo:=false;
        salvato:=true;
      end
      else fileName:=anon;
  end
  else fileName:=anon;
  clrscr;
  textattr:=$1F; clreol;
  writeln('Resource Editor 1.0 (c) Ernesto CIANCIOTTA Productions 1996');
  textattr:=$7;
  Menu;
  while true do begin
    ch:=readkey;
    EliminaCursore;
    case ch of
      '1': Nuovo;
      '2': Apri;
      '3': Salva;
      '4': Salva_come;
      '5': Modifica;
      '6': Compila;
      #27: Esci;
    end;
    RipristinaCursore;
  end;
end.