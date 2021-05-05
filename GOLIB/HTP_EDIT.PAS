{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



{ Modulo del programma HOTEDIT.PAS  per l'editing delle risorse HotSpots }


UNIT Htp_Edit;

INTERFACE

uses
    GLBr_sdk;

type

    TCursorResRCG = record
       indirizzo: Char;
    end;


    PRisorsaInfo = ^TRisorsaInfo;
    TRisorsaInfo = record
       next: longint;
       tipo: word;    { = 0001/0002 }
       ID: longint;
       Attr: word;
    end;


    PRisorsaRCG = ^TRisorsaRCG;
    TRisorsaRCG = record
    (*
       next: longint;
       Attr: word;
       tipo: word;    { = 0001/0002 }
       ID: longint;
     *)
       info:TRisorsaInfo;
       case word of
       0001: ( package: TPackage;
              );
       0002: ( cur: TCursorResRCG);
    end;


    PResHeaderRCG = ^TResHeaderRCG;
    TResHeaderRCG = record
       ver: word;
       num_ris:longint;
    end;


    PStrutturaRCG = ^TStrutturaRCG;
    TStrutturaRCG = record
       header: TResHeaderRCG;
       risorse: array[sizeof(TResHeaderRCG)+1..sizeof(TResHeaderRCG)+1] of byte;
    end;



    procedure CreaRisorsaVuota;

    function ApriRisorsa(fileName:string):boolean;

    procedure SalvaRisorsa(fileName:string);

    { Restituisce true se le risorse sono state modificate }
    function EditaRisorsa:boolean;

    procedure Compila_RCG_in_GLBr(fileName:string);



IMPLEMENTATION

uses
    crt,
    strings,
    OpenFile,
    bios_utt,
    crt_adv,
    utility;



const
      maxDim    = 65520;

type

    PUltimaRisorsa = ^TUltimaRisorsa;
    TUltimaRisorsa = record
       dimensione_file: longint;
       tipo:word;
    end;


    PStatoInizialeRCG = ^TStatoInizialeRCG;
    TStatoInizialeRCG = record
       ver: word;
       num_ris:longint;
       dimensione_file: longint;
       tipo:word;
    end;


    PImmagine = ^TImmagine;
    TImmagine = array[1..maxDim] of byte;


    PTabellaIDX = ^TTabellaIDX;
    TTabellaIDX = array[1..32760] of word;


    PImmagineIDX = ^TImmagineIDX;
    TImmagineIDX = array[1..1] of record
       ID    : longint;
       indice: longint;
    end;


const
      minDimRCG = sizeof(TResHeaderRCG)+sizeof(TUltimaRisorsa);

      DimCursorResRCG = sizeof(TRisorsaInfo)+sizeof(TCursorResRCG);

      DimPackageRes = sizeof(TRisorsaInfo)+sizeof(TPackage);

      { immagine del file di risorse su cui si opera }

      dim_Immagine: longint = 0;

      immagine:PImmagine    = nil;

      StatoInizialeRCG: TStatoInizialeRCG =
        (
         ver: $0100;
         num_ris: 0;
         dimensione_file: minDimRCG;
         tipo: 0000
        );


      CursoreRCG_vuoto: TCursorResRCG =
        (
         indirizzo: #0
        );

      Package_vuoto: TPackage =
        (
         n: 1;
         hot: (
               (x1: 0; y1: 0;
                x2: 0; y2: 0;
                IDCursor: 0;
                Message: 0
               )
              )
        );

      DimMinCursorRCG = sizeof(TCursorResRCG)+255;


var
    header:PResHeaderRCG absolute immagine;

    f, GLBr:file;

    { Tabella indici per localizzare le risorse nell'immagine }
    idx: PTabellaIDX;



    { Crea la tabella IDX }
    procedure CreaIDX;
      var i,
          index:longint;
      begin
        if immagine=nil then exit;
        index:=sizeof(TResHeaderRCG)+1;
        for i:=1 to header^.num_ris+1 do begin
          idx^[i]:=index;
          index:=PRisorsaRCG(@immagine^[index])^.info.next;
        end;
      end;


    function GetConfigPrefered(var config:word):boolean;
      const NumAttributi=2;
            pos:byte = 1;
            normal   = $30;
            selected = $2F;
            StartX   = 20;
            StartY   = 10;
      var
         modified:boolean;

      procedure marca(y:byte; v:boolean);
        begin
          if pos+2 = y then TextAttr:=$20
                       else TextAttr:=normal;
          gotoxy(3,y);
          if v then write('û')
               else write(' ');
        end;

      procedure Aggiorna;
        begin
          marca(3,(config and ConfMOVABLE)<>0);
          marca(4,(config and ConfPERSONAL)<>0);
        end;

      procedure Interagisci;
        var   b:word;
        begin
          while true do
          case readkey of
          #13: exit;
          #32: begin
                 modified:=true;
                 b:=1 shl (pos-1);
                 if (config and b)<>0 then config:=config and not b
                                      else config:=config or b;
                 Aggiorna;
               end;
          #0: case readkey of
              { Su }
              #$48: if pos>1 then begin
                      Evidenzia(StartX+1,StartY+2+pos,StartX+39,StartY+2+pos,normal);
                      dec(pos);
                      Evidenzia(StartX+1,StartY+2+pos,StartX+39,StartY+2+pos,selected);
                    end;
              { Gi— }
              #$50: if pos<NumAttributi then begin
                      Evidenzia(StartX+1,StartY+2+pos,StartX+39,StartY+2+pos,normal);
                      inc(pos);
                      Evidenzia(StartX+1,StartY+2+pos,StartX+39,StartY+2+pos,selected);
                    end;
              end;
          end;
        end;

      begin
        modified:=false;
        window(1,1,80,25);
        PushVideo;

        {Evidenzia(StartX-2,StartY+1,StartX+42,StartY+5+NumAttributi,$08);}
        Evidenzia(1,6,80,25,$08);

        rect(StartX,StartY,StartX+40,StartY+4+NumAttributi,$38,true);

        window(StartX+1,StartY+1,StartX+39,StartY+3+NumAttributi);
        textattr:=$30;
        clrscr;
        SpecialWrite  ('Definisci gli attributi');
        writeln(#10#10#13'               MOVEBLE');
        writeln('               PERSONAL');
        Aggiorna;
        Evidenzia(StartX+1,StartY+2+pos,StartX+39,StartY+2+pos,selected);
        Interagisci;
        PopVideo;
        window(1,1,80,25);
        GetConfigPrefered:=modified;
      end;


    procedure Errore1;
      begin
        writeln;
        writeln('Errore durante le operazioni di accesso al disco!');
        delay(600);
      end;


    procedure Errore2;
      begin
        writeln;
        writeln('Il file di risorsa Š danneggiato o Š di una versione superiore alla 1.00');
        delay(600);
        close(f);
      end;


    procedure Errore3;
      begin
        Errore1;
        close(f);
      end;



    procedure CreaRisorsaVuota;
      begin
        if immagine=nil then new(immagine);
        dim_immagine:=minDimRCG;
        PStatoInizialeRCG(immagine)^:=StatoInizialeRCG;
      end;


    function ApriRisorsa(fileName:string):boolean;
      var ris:word;
          i, size_res,
          size,
          pos:longint;  { pos indica la posizione in cui immagazzinare }
          new_immagine:PImmagine;
      begin
        ApriRisorsa:=false;

        new(new_immagine);

        assign(f,fileName);
        {$I-}
        reset(f,1);
        {$I+}
        if ioresult<>0 then begin
          Errore1;
          dispose(new_immagine);
          exit;
        end;
        size:=fileSize(f);
        { Controlla la dimensione }
        if size<sizeof(TResHeaderRCG) then begin
          Errore2;
          dispose(new_immagine);
          exit;
        end;
        { Legge la versione }
        blockread(f,new_immagine^,2,ris);
        if ris<>2 then begin
          Errore3;
          exit;
        end;
        { Controlla la versione }
        if PResHeaderRCG(new_immagine)^.ver>$0100 then begin
          Errore2;
          dispose(new_immagine);
          exit;
        end;
        (*
        { Legge il numero di risorse }
        blockread(f,new_immagine^[3],4);
        pos:=7;
        for i:=1 to PResHeaderRCG(new_immagine)^.num_ris do begin
          { Carica le informazione sulla risorsa }
          blockread(f,new_immagine^[pos],sizeof(TRisorsaInfo)-2);
          PRisorsaInfo(@new_immagine^[pos])^.Attr:=0;
          { Carica la risorsa }
          size_res:=PRisorsaInfo(@new_immagine^[pos])^.next-pos;
          pos:=pos+sizeof(TRisorsaInfo);
          blockread(f,new_immagine^[pos],size_res);
          { Aggiorna pos }
          pos:=pos+size_res;
        end;
        *)

        { Legge il resto del file }
        blockread(f,new_immagine^[3],size-2,ris);
        if ris<>size-2 then begin
          Errore3;
          dispose(new_immagine);
          exit;
        end;

        close(f);
        if immagine<>nil then dispose(immagine);
        immagine:=new_immagine;
        dim_immagine:=size;
        ApriRisorsa:=true;
      end;


    procedure SalvaRisorsa(fileName:string);
      var ris:word;
          ext:TExtention;
      begin
        { completa il nome del file nel caso non sia provvisto di estensione }
        GetExtention(fileName,ext,'GLB');

        assign(f,fileName);
        {$I-}
        rewrite(f,dim_immagine);
        {$I+}
        if ioresult<>0 then begin
          Errore1;
          exit;
        end;
        blockwrite(f,immagine^,1,ris);
        if ris<>1 then begin
          Errore3;
          exit;
        end;
        close(f);
      end;


    {*******************************************************************}

    function EditaRisorsa:boolean;
      const pieno = 'File risorsa pieno!';
      var
         ch:char;
         modificato:boolean;
         is_package:boolean;
         index:longint;     { indice risorsa }
         sub_index:longint; { indice hot spot all'interno del package }


      procedure Menu_Modifica;
        begin
          window(2,7,33,19);
          clrscr;
          textAttr:=$1F; clreol;
          writeln('            Menu');
          textAttr:=$07;
          write  ('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
          writeln('1. Aggiungi Package');
          writeln('2. Aggiungi Cursore');
          writeln('3. Cancella');
          writeln('4. Cancella tutto');
          writeln('5  Modifica attributi');
          writeln('6. Modifica risorsa');
          writeln;
          writeln('7. Precedente');
          writeln('9. Prossima');
          writeln;
          write  ('0. Torna al menu principale');
        end;


      procedure Menu_Modifica_Package;
        begin
          window(2,7,33,19);
          clrscr;
          textAttr:=$4E; clreol;
          writeln('     Menu modifica Package');
          textAttr:=$07;
          write  ('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
          writeln('1. Aggiungi hot spot');
          writeln('2. Modifica hot spot');
          writeln('3. Cancella hot spot');
          writeln;
          writeln('7. Precedente');
          writeln('9. Prossimo');
          writeln;
          write  ('0. Fine modifica Package');
        end;


      procedure AggiornaInfoGenerali;
        begin
          window(1,5,80,25);
          gotoxy(20,18);  write(header^.num_ris:8);
          gotoxy(20,19);  write(index:8);
          window(39,7,78,23);
        end;


      procedure Messaggio(msg:string);
        begin
          window(1,1,80,25);
          gotoxy(1,25);
          RipristinaCursore;
          textattr:=$87;
          write('ATTENZIONE! ');
          textattr:=$07;
          write(msg);
          delay(1500);
          gotoxy(1,25);
          clreol;
          window(39,7,78,23);
          while keypressed do readkey;
          EliminaCursore;
        end;


      procedure MessagePackage;
        begin
          { Messaggio }
          window(1,1,80,25);
          gotoxy(1,25);
          textattr:=$07;
          if sub_index=1
            then write('Primo hot spot del package')
            else if sub_index=PRisorsaRCG(@immagine^[idx^[index]])^.package.n
                   then write('Ultimo hot spot del package');
          clreol;
          window(39,7,78,23);
        end;


      {****************************}
      procedure Vis_HotSpot;
        begin
          window(39,16,78,23);
          clrscr;
          write    ('ÄÄÄÄÄÄÄÄÄ  Hot Spot: ',sub_index:5,'  ÄÄÄÄÄÄÄÄÄÄÄÄ');
          with PRisorsaRCG(@immagine^[idx^[index]])^.package.hot[sub_index] do begin
            writeln;
            writeln(' x1 = ',x1:6,' ':9,'y1 = ',y1:6);
            writeln(' x2 = ',x2:6,' ':9,'y2 = ',y2:6);
            writeln;
            writeln(' IDCursor = ',IDCursor:6);
            writeln;
            write  (' Message  = ',Message:6);
          end;
        end;

      procedure Vis_Info;

        procedure Vis_Package;
          begin
            is_package:=true;
            writeln('Package di Hot Spots');
            writeln;
            writeln(' ID    = ',PRisorsaRCG(@immagine^[idx^[index]])^.info.ID:5);
            writeln(' Hot spots presenti',PRisorsaRCG(@immagine^[idx^[index]])^.package.n:6);
            writeln;
            writeln(' <-  o  -> per visitare il package');
            Vis_HotSpot;
          end;

        procedure Vis_Cursore;
          begin
            is_package:=false;
            writeln('Cursore');
            writeln;
            writeln(' ID    = ',PRisorsaRCG(@immagine^[idx^[index]])^.info.ID:5);
            writeln;
            writeln(' Indirizzo del file binario:');
            writeln('   ',PChar(@PRisorsaRCG(@immagine^[idx^[index]])^.cur.indirizzo));
          end;

        begin { Vis_Info }
          window(39,7,78,23);
          clrscr;
          textAttr:=$6f; clreol;
          writeln(' Informazioni sulla risorsa');
          textAttr:=$07;
          write  ('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
          write  (' Descrizione: ');
          if index=0
            then writeln('Nessuna risora presente')
            else
              case PRisorsaRCG(@immagine^[idx^[index]])^.info.tipo of
              0001: Vis_Package;
              0002: Vis_Cursore;
              end;
        end; { Vis_Info }
      {****************************}


      procedure AgguingiRisorsaCoda;
        begin
          with PUltimaRisorsa(@immagine^[dim_immagine+1])^ do begin
            dimensione_file:=dim_immagine+sizeof(TUltimaRIsorsa);
            tipo:=0000;
          end;
          idx^[header^.num_ris+1]:=dim_immagine+1;
          dim_immagine:=dim_immagine+sizeof(TUltimaRIsorsa);
        end;


      procedure AggiungiPackage;
        begin
          if dim_immagine+DimPackageRes > maxDim then begin
            Messaggio(pieno);
            exit;
          end;
          inc(header^.num_ris);
          with PRisorsaRCG(@immagine^[idx^[header^.num_ris]])^ do begin
            info.next:=0;
            info.Attr:=ConfMOVABLE or ConfPERSONAL;
            info.ID:=0;
            info.tipo:=0001;
            package:=package_vuoto;
            dim_immagine:=dim_immagine+DimPackageRes-sizeof(TUltimaRIsorsa);
            AgguingiRisorsaCoda;
            info.next:=idx^[header^.num_ris+1];
          end;
          index:=header^.num_ris;
          AggiornaInfoGenerali;
        end;


      procedure AggiungiCursore;
        begin
          if dim_immagine+DimCursorResRCG > maxDim then begin
            Messaggio(pieno);
            exit;
          end;
          inc(header^.num_ris);
          with PRisorsaRCG(@immagine^[idx^[header^.num_ris]])^ do begin
            info.ID:=0;
            info.tipo:=0002;
            info.Attr:=0;
            cur:=CursoreRCG_vuoto;
            dim_immagine:=dim_immagine+DimCursorResRCG-sizeof(TUltimaRIsorsa);
            AgguingiRisorsaCoda;
            info.next:=idx^[header^.num_ris+1];
          end;
          index:=header^.num_ris;
          AggiornaInfoGenerali;
        end;


      procedure Cancella;
        var i,j:word;
            next:word;
        begin
          if header^.num_ris=0 then begin
            Messaggio('Nessuna risora presente nel file');
            exit;
          end;
          i:=idx^[index];
          next:=idx^[index+1];
          { aggiorna i campi "next" delle risorse }
          i:=next-i;
          for j:=index+1 to header^.num_ris+1 do dec(PRisorsaRCG(@immagine^[idx^[j]])^.info.next,i);
          { aggiorna l'immagine }
          i:=idx^[index];
          for j:=next to maxDim do immagine^[i+j-next]:=immagine^[j];
          { ricrea la tabella IDX }
          dec(header^.num_ris);
          dim_immagine:=dim_immagine-(next-i);
          CreaIDX;
          if index>header^.num_ris then index:=header^.num_ris;
        end;


      procedure Cancella_Tutto;
        var ch:char;
        begin
          window(39,7,78,23);
          clrscr;
          writeln;
          writeln(' Sei sicuro di voler cancellare tutte    le risorse ?  (S/N)');
          repeat ch:=UpCase(readkey); until ch in ['S','N'];
          if ch='S' then begin
            PStatoInizialeRCG(immagine)^:=StatoInizialeRCG;
            index:=0;
            dim_immagine:=minDimRCG;
          end;
          Vis_Info;
        end;


      {****************************}
      procedure Modifica;
        var i,next:word;


        procedure Muovi_in_Coda;
          var i,j:word;
              next,dest:word;
              buf:PImmagine;
          begin
            i:=idx^[index];
            next:=idx^[index+1];
            { salva in buf la risorsa }
            new(buf);
            for j:=i to next-1 do buf^[1+j-i]:=immagine^[j];
            Cancella;
            { ripristina la risorsa su Ultima Risorsa di immagine }
            inc(header^.num_ris);
            dest:=idx^[header^.num_ris];
            for j:=1 to next-i do immagine^[dest+j-1]:=buf^[j];
            dim_immagine:=dim_immagine-sizeof(TUltimaRisorsa);
            dispose(buf);
            {N.B.: dim_immagine Š uguale alla dimensione precednte meno
                   la dimensione dell'Ultima Risorsa meno
                   la dimensione della risorsa che si Š spostata.}
          end;

        procedure Modifica_Package;
          var ch:char;
              dim_imm:longint;

              procedure Modifica_HotSpot;
                begin
                  window(39,16,78,23);
                  clrscr;
                  write    ('ÄÄÄÄÄÄÄÄÄ  Hot Spot: ',sub_index:5,'  ÄÄÄÄÄÄÄÄÄÄÄÄ');
                  writeln;
                  RipristinaCursore;
                  with PRisorsaRCG(@immagine^[idx^[index]])^.package.hot[sub_index] do begin
                  {with PHotSpotRes(@immagine^[dim_imm+1])^ do begin}
                    write(' x1 = '); x1:=ValidReadNum;
                    gotoxy(21,3);
                    write(' y1 = '); y1:=ValidReadNum;
                    gotoxy(1,4);
                    write(' x2 = '); x2:=ValidReadNum;
                    gotoxy(21,4);
                    write(' y2 = '); y2:=ValidReadNum;
                    gotoxy(1,6);
                    write(' IDCursor = '); IDCursor:=ValidReadNum;
                    gotoxy(1,8);
                    write(' Message  = '); Message:=ValidReadNum;
                  end;
                  EliminaCursore;
                  Vis_HotSpot;
                end;

              procedure Aggiungi_HotSpot;
                begin
                  if dim_imm+sizeof(THotSpotRes) > maxDim then begin
                    Messaggio(pieno);
                    exit;
                  end;
                  inc(PRisorsaRCG(@immagine^[idx^[index]])^.package.n);
                  sub_index:=PRisorsaRCG(@immagine^[idx^[index]])^.package.n;
                  window(58,11,78,11);
                  write(sub_index:6);
                  Modifica_HotSpot;
                  inc(dim_imm,sizeof(THotSpotRes));
                end;

              procedure Cancella_HotSpot;
                var n:word;
                    imm:PImmagine;
                begin
                  if PRisorsaRCG(@immagine^[idx^[index]])^.package.n=1 then begin
                    Messaggio('Deve rimanere almeno un hot spot nel package');
                    exit;
                  end;
                  imm:=@PRisorsaRCG(@immagine^[idx^[index]])^.package.hot[sub_index];
                  for n:=1 to (PRisorsaRCG(@immagine^[idx^[index]])^.package.n-sub_index)*sizeof(THotSpotRes) do
                    imm^[n]:=imm^[n+sizeof(THotSpotRes)];
                  dec(PRisorsaRCG(@immagine^[idx^[index]])^.package.n);
                  window(58,11,78,11);
                  n:=PRisorsaRCG(@immagine^[idx^[index]])^.package.n;
                  write(n:6);
                  if sub_index>n then sub_index:=n;
                  Vis_HotSpot;
                end;

              procedure Prec_HotSpot;
                begin
                  if sub_index > 1 then begin
                    dec(sub_index);
                    Vis_HotSpot;
                  end;
                  MessagePackage;
                end;

              procedure Succ_HotSpot;
                begin
                  if sub_index < PRisorsaRCG(@immagine^[idx^[index]])^.package.n then begin
                    inc(sub_index);
                    Vis_HotSpot;
                  end;
                  MessagePackage;
                end;

          begin { Modifica_Package }
            dim_imm:=dim_immagine+sizeof(TRisorsaInfo)+
                     sizeof(TPackage)-sizeof(THotSpotRes)+sizeof(THotSpotRes)*PRisorsaRCG(@immagine^[idx^[index]])^.package.n;
            writeln('Package di Hot Spots');
            writeln;
            writeln(' Hot spots presenti',PRisorsaRCG(@immagine^[idx^[index]])^.package.n:6);
            writeln;
            RipristinaCursore;
            write  (' ID    = ');  PRisorsaRCG(@immagine^[idx^[index]])^.info.ID:=ValidReadNum;
            EliminaCursore;
            Menu_Modifica_Package;
            Vis_HotSpot;
            window(39,14,78,23);
            repeat
              ch:=readkey;
              case ch of
              '1': Aggiungi_HotSpot;
              '2': Modifica_HotSpot;
              '3': Cancella_HotSpot;
              '7': Prec_HotSpot;
              '9': Succ_HotSpot;
              end;
            until ch='0';
            dim_immagine:=dim_immagine+sizeof(TRisorsaInfo)+
                          sizeof(TPackage)-sizeof(THotSpotRes)+
                          sizeof(THotSpotRes)*PRisorsaRCG(@immagine^[idx^[index]])^.package.n;
            AgguingiRisorsaCoda;
            PRisorsaRCG(@immagine^[idx^[index]])^.info.next:=idx^[header^.num_ris+1];
            Menu_Modifica;
          end;

        procedure Modifica_Cursore;
          var s:string;
              p:PChar;
          begin
            RipristinaCursore;
            write('Cursore');
            writeln;
            writeln;
            write(' ID    = '); PRisorsaRCG(@immagine^[idx^[index]])^.info.ID:=ValidReadNum;
            writeln;
            p:=@PRisorsaRCG(@immagine^[idx^[index]])^.cur.indirizzo;
            write(' Indirizzo = '); s:=ValidRead('\X');
            EliminaCursore;
            StrPCopy(p,s);
            dim_immagine:=dim_immagine+sizeof(TRisorsaInfo)+sizeof(TCursorResRCG)+length(s);
            AgguingiRisorsaCoda;
            PRisorsaRCG(@immagine^[idx^[index]])^.info.next:=idx^[header^.num_ris+1];
          end;

        begin { Modifica }

          { Sequanza delle operazioni da eseguire:
            - muovere la risorsa in coda all'immagine sovrapponendo
              Ultima Risorsa;
            - modificare la risorsa;
            - ricreare Ultima Risorsa.
          }
          if index=0 then begin
            Messaggio('Nessuna risorsa da modificare');
            exit;
          end;
          i:=idx^[index];
          next:=idx^[index+1];
          case PRisorsaRCG(@immagine^[idx^[index]])^.info.tipo of
          0002: if dim_immagine-(next-i)+DimMinCursorRCG > maxDim then begin
                  Messaggio(pieno);
                  exit;
                end;
          end;
          Muovi_in_Coda;
          index:=header^.num_ris;
          AggiornaInfoGenerali;
          window(39,7,78,23);
          clrscr;
          textAttr:=$5f; clreol;
          writeln(' Modifica risorsa');
          textAttr:=$07;
          write  ('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
          write  (' Descrizione: ');
          case PRisorsaRCG(@immagine^[idx^[index]])^.info.tipo of
          0001: Modifica_Package;
          0002: Modifica_Cursore;
          end;
        end;  { Modifica }

      {****************************}


      var www:word;

      begin { EditaRisorsa }
        CreaIDX;
        modificato:=false;
        if header^.num_ris=0 then index:=0
                             else index:=1;
        sub_index:=1;
        window(1,5,80,25);
        clrscr;
        textAttr:=$0E;
        writeln('--------------------------  Modifica delle risorse  ---------------------------');
        textAttr:=$07;
        rect(1,2,34,16,$03,false);
        Menu_Modifica;
        window(1,5,80,25);
        gotoxy(2,18);
        writeln(' Numero risorse = ',header^.num_ris:8);
         write('  Indice risorsa = ',index:8);
        rect(1,17,34,20,$03,false);
        rect(38,2,79,20,$03,false);
        Vis_Info;
        repeat
          ch:=readkey;
          case ch of
          '1': begin
                 modificato:=true;
                 AggiungiPackage;
                 sub_index:=1;
                 Modifica;
                 Vis_Info;
               end;
          '2': begin
                 modificato:=true;
                 AggiungiCursore;
                 sub_index:=1;
                 Modifica;
                 Vis_Info;
               end;
          '3': begin
                 modificato:=true;
                 sub_index:=1;
                 Cancella;
                 AggiornaInfoGenerali;
                 Vis_Info;
               end;
          '4': begin
                 modificato:=true;
                 sub_index:=1;
                 Cancella_tutto;
                 AggiornaInfoGenerali;
                 Vis_Info;
               end;
          '5': begin
                 sub_index:=1;
                 modificato:=GetConfigPrefered(PRisorsaRCG(@immagine^[idx^[index]])^.info.Attr) or modificato;
               end;
          '6': begin
                 modificato:=true;
                 sub_index:=1;
                 Modifica;
                 Vis_Info;
               end;
          '7': if index>1 then begin
                 dec(index);
                 sub_index:=1;
                 AggiornaInfoGenerali;
                 Vis_Info;
               end;
          '9': if index<header^.num_ris then begin
                 inc(index);
                 sub_index:=1;
                 AggiornaInfoGenerali;
                 Vis_Info;
               end;
          end;
          { Messaggio }
          window(1,1,80,25);
          gotoxy(1,25);
          textattr:=$07;
          if index=1
            then write('Prima risorsa')
            else if index=header^.num_ris
                   then write('Ultima risorsa');
          clreol;
          window(39,7,78,23);
          { Controllo all'interno del package }
          if is_package then begin
            if ch=#0 then begin
              ch:=readkey;
              case ch of
              #$4B: if sub_index > 1 then begin
                      dec(sub_index);
                      Vis_HotSpot;
                    end;
              #$4D: if sub_index < PRisorsaRCG(@immagine^[idx^[index]])^.package.n then begin
                      inc(sub_index);
                      Vis_HotSpot;
                    end;
              end;
              MessagePackage;
            end;
          end;
        until ch='0';
        EditaRisorsa:=modificato;
      end;


    {*******************************************************************}


    { Ordina la tabella IDX secondo l'ID delle risorse }
    procedure OrdinaIDX;

      procedure Sort(l, r: Integer);
        var
           i, j: integer;
           x: longint; { para all'ID della risorsa puntata }
           y: word;    { serve per lo scambio dei puntatori }
        begin {Sort}
          i := l; j := r; x := PRisorsaRCG(@immagine^[idx^[(l+r) DIV 2]])^.info.ID;
          repeat
            while PRisorsaRCG(@immagine^[idx^[i]])^.info.ID < x do i := i + 1;
            while x < PRisorsaRCG(@immagine^[idx^[j]])^.info.ID do j := j - 1;
            if i <= j then
            begin
              y := idx^[i]; idx^[i] := idx^[j]; idx^[j] := y;
              i := i + 1; j := j - 1;
            end;
          until i > j;
          if l < j then Sort(l, j);
          if i < r then Sort(i, r);
        end;  {Sort}

      begin { OrdinaIDX }
        Sort(1,header^.num_ris);
      end;  { OrdinaIDX }



    procedure Compila_RCG_in_GLBr(fileName:string);
      type PWord = ^word;
      var i,j: word;
          immagineIDX: PImmagineIDX;
          immagineGLBr: PImmagine;
          puntIDX,
          puntGLBr: word;
          displacement: word;
          cur:file;

      procedure EndProcedure;
        begin
          FreeMem(immagineIDX,header^.num_ris*8);
          dispose(immagineGLBr);
        end;

      procedure Abort;
        begin
          writeln;
          writeln;
          write('Premere un tasto per continuare . . .');
          readkey;
          gotoxy(1,whereY);
          clreol;
          TextAttr:=$0C;
          write('Compilazione abortita !');
          TextAttr:=$07;
          delay(600);
        end;

      procedure EndMessage;
        var s:string;
        begin
          gotoxy(1,whereY-1); clreol;
          s:='Compilazione sul file '+fileName+' effettuata con successo!';
          TextAttr:=$0A;
          writeln(#10#13,s:Length(s)+(78-Length(s)) div 2);
          TextAttr:=$07;
          delay(1000);
        end;

      procedure ErroreRisorsa;
        begin
          EndProcedure;
          TextAttr:=$C;
          writeln(#10#10#13'ERRORE nella risorsa ID = ',PRisorsaRCG(@immagine^[idx^[i]])^.info.ID:5);
          TextAttr:=7;
        end;

      const collMesg ='Il collegamento esterno:  ';

      begin
        if fileName='' then exit;
        CreaIDX;
        OrdinaIDX;
        { crea un'immagine delle risorse ordinate in memoria }
        GetMem(immagineIDX,header^.num_ris*8);
        new(immagineGLBr);
        puntIDX:=1;
        puntGLBr:=1;
        displacement:=header^.num_ris*8+6+sizeof(TGLBrHeader)-1;
        for i:=1 to header^.num_ris do begin
          with immagineIDX^[puntIDX] do begin
            ID:=PRisorsaRCG(@immagine^[idx^[i]])^.info.ID;
            indice:=puntGLBr+displacement;
          end;
          inc(puntIDX);
          { memorizza gli attributi della risorsa }

          PWord(@immagineGLBr^[puntGLBr])^:=PRisorsaRCG(@immagine^[idx^[i]])^.info.Attr;
          inc(puntGLBr,2);

          case PRisorsaRCG(@immagine^[idx^[i]])^.info.tipo of
          0001: begin
              { memorizza il tipo di risorsa }
              PWord(@immagineGLBr^[puntGLBr])^:=0001;
              inc(puntGLBr,2);
              { memorizza il package }
              for j:=0 to (PRisorsaRCG(@immagine^[idx^[i]])^.package.n)*sizeof(THotSpotRes)-1+2 do
                immagineGLBr^[puntGLBr+j]:=immagine^[idx^[i]+j+sizeof(TRisorsaInfo)];
              inc(puntGLBr,(PRisorsaRCG(@immagine^[idx^[i]])^.package.n)*sizeof(THotSpotRes)+2);
            end;
          0002: begin
              __ResetFile(cur,PChar(@PRisorsaRCG(@immagine^[idx^[i]])^.cur.indirizzo),1);
              if LastIOResult<>0 then begin
                ErroreRisorsa;
                write(collMesg);
                TextAttr:=3;
                writeln(PChar(@PRisorsaRCG(@immagine^[idx^[i]])^.cur.indirizzo));
                TextAttr:=7;
                writeln('non Š valido !');
                write(GetRunErrorMessage(LastIOResult));
                Abort;
                exit;
              end;
              if filesize(cur)<>sizeof(TCursorRes) then begin
                ErroreRisorsa;
                write(collMesg);
                TextAttr:=3;
                writeln(PChar(@PRisorsaRCG(@immagine^[idx^[i]])^.cur.indirizzo));
                TextAttr:=7;
                writeln('deve avere dimensione pari a ',sizeof(TCursorRes),' bytes per poter essere importato!');
                Abort;
                exit;
              end;
              { memorizza il tipo di risorsa }
              PWord(@immagineGLBr^[puntGLBr])^:=0002;
              inc(puntGLBr,2);
              { carica la risorsa binaria collegata }
              blockread(cur,immagineGLBr^[puntGLBr],68);
              inc(puntGLBr,68);
              close(cur);
            end;
          end;
        end;
        { Salvataggio su disco }
        assign(GLBr,fileName);
        {$I-}
        rewrite(GLBr,1);
        {$I+}
        if ioresult<>0 then begin
          Errore1;
          exit;
        end;
        { scrive l'intestazione }
        blockwrite(GLBr,GLBr_Header,sizeof(GLBr_Header));
        { scrive versione e numero di risorse }
        i:=1;
        blockwrite(GLBr,i,2);
        blockwrite(GLBr,header^.num_ris,4);
        { scrive la tabella d'accesso alle risorse }
        blockwrite(GLBr,immagineIDX^,(puntIDX-1)*8);
        { scrive le risorse }
        blockwrite(GLBr,immagineGLBr^,puntGLBr-1);
        { Fine della compilazione del file GLBr }
        EndProcedure;
        EndMessage;
      end;



    procedure Htp_Edit_Esci; far;
      begin
        dispose(idx);
        if immagine<>nil then dispose(immagine);
      end;



BEGIN
  new(idx);
  ExitProc:=@Htp_Edit_Esci;
END.
