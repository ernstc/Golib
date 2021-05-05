{by Ernesto CIANCIOTTA Productions}

{***************************************************************************}
{ Programma per la risoluzione di problemi di Programmazione Lineare con il }
{ metodo del simplesso.                                                     }
{***************************************************************************}

uses crt;


type
     TPos = (sinistra,destra);


     TCoefficente = record
        c:real;
        posizione:TPos;
     end;


     PEquazione = ^TEquazione;
     TEquazione = record
        nVar:word;
        MainVar:char;
        MainVarC:TCoefficente;
        TermineNoto:TCoefficente;
        tipoEqu:char;
        c:array[1..1] of TCoefficente;
     end;


     PSistema = ^TSistema;
     TSistema = record
        equ:PEquazione;
        succ:PSistema;
     end;


     PSoluzione = ^TSoluzione;
     TSoluzione = array[1..1] of real;


     PVideo = ^TVideo;
     TVideo = array[1..80,1..25] of word;




var
     Max:PEquazione;
     sistema:PSistema;
     soluzione:PSoluzione;
     NVincoli,NEqu,NVar,NBasiche:word;
     i:word;
     ProblemaDiMassimo:boolean;

     video:TVideo absolute $B800:$0000;



const
      separatoreDS:string[2]='=';
      latoVariabili:TPos=destra;
      latoTermineNoto:TPos=destra;



 {**************************************************************************}
 {**********   Procedure per l'inserimento e la visualizzazione   **********}
 {**************************************************************************}

procedure Isola_TermineNoto(equ:PEquazione; lato:TPos); forward;


procedure Pausa;
  begin
    gotoxy(1,20);
    write('Premi un tasto per continuare...');
    readkey;
    gotoxy(1,20);
    clreol;
  end;



{$R-}
procedure VisEquazione(x,y:word; equ:PEquazione);
  var j:word;

  procedure visLato(l:TPos);
    var dec:boolean;
        lato:boolean;
        j:word;
    begin
      lato:=false;
      for j:=1 to equ^.nVar do begin
        with equ^.c[j] do
          if posizione=l then begin
            if c=-1 then write(' - X',j)
            else if c=1 then begin
                   if lato then write(' + ');
                   write('X',j);
                 end
                 else if c<>0 then begin
                        if c>0 then begin
                          if lato then write(' + ')
                        end
                        else write(' - ');
                        dec:=(c-trunc(c))<>0;
                        if dec then write(abs(c):2:2,'*X',j)
                               else write(trunc(abs(c)),'*X',j);
                      end;
            if c<>0 then lato:=true;
          end;
      end;
      if equ^.MainVar<>#0 then
        with equ^.MainVarC do
          if posizione=l then begin
            if c=-1 then write(' - ',equ^.MainVar)
            else if c=1 then begin
                   if lato then write(' + ');
                   write(equ^.MainVar);
                 end
                 else if c<>0 then begin
                        if c>0 then begin
                          if lato then write(' + ')
                        end
                        else write(' - ');
                        dec:=(c-trunc(c))<>0;
                        if dec then write(abs(c):2:2,'*',equ^.MainVar)
                               else write(trunc(abs(c)),'*',equ^.MainVar)
                      end;
            if c<>0 then lato:=true;
          end;
      if equ^.TermineNoto.c<>0 then
        with equ^.TermineNoto do
          if posizione=l then begin
            if c=-1 then write(' - 1')
            else if c=1 then begin
                   if lato then write(' + ');
                   write('1');
                 end
                 else if c<>0 then begin
                        if c>0 then begin
                          if lato then write(' + ')
                        end
                        else write(' - ');
                        dec:=(c-trunc(c))<>0;
                        if dec then write(abs(c):2:2)
                               else write(trunc(abs(c)))
                      end;
            if c<>0 then lato:=true;
          end;
      if not lato then write('0');
    end;

  begin
    gotoxy(x,y);
    clreol;
    visLato(sinistra);
    write(' ',equ^.tipoEqu,' ');
    visLato(destra);
  end;


procedure VisSistema(msg,ottimo:boolean);
  var precVideo:TVideo;
      buf:PSistema;
      i:word;
      coeff:real;
  begin
    precVideo:=video;
    clrscr;
    textAttr:=$02;
    writeln('ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป');
    writeln('บ    Sistema di lavoro:                                                       บ');
    write  ('วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ');
    textAttr:=$07;
    buf:=sistema;
    i:=4;
    while buf<>nil do begin
      VisEquazione(9,i,buf^.equ);
      buf:=buf^.succ;
      inc(i);
    end;
    textAttr:=$02;
    writeln;
    writeln('ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');
    textAttr:=$07;
    if msg then begin
      if ottimo then begin
        write('E'' stata raggiunta la soluzione ');
        textAttr:=$02+128;
        write('OTTIMA');
        textAttr:=$07;
        writeln('!');
      end
      else writeln('La soluzione trovata non  ottima. E'' necessario reiterare.');
      write('Soluzione: (');
      for i:=1 to NVar-1 do write(soluzione^[i]:6:2,',');
      writeln(soluzione^[NVar]:6:2,')');
      write('Z = ');
      if ProblemaDiMassimo then coeff:=1
                           else coeff:=-1;
      with max^ do
        if MainVarC.c<0 then write(-(TermineNoto.c*coeff/MainVarC.c):6:2)
                        else write((TermineNoto.c*coeff/MainVarC.c):6:2);
    end;
    pausa;
    video:=precvideo;
  end;


procedure LeggiEquazione(var equ:PEquazione; MainVar:char);
  var _nVar_:word;
      buf:string;
      j:word;
  begin
    j:=1;
    if separatoreDS='' then begin
      clreol;
      writeln('Inserisci il tipo di equazione o disequazione:');
      write  ('1. =          2. ๓          3. ๒                ฤ> ');
      textattr:=$02;
      read(j);
      textattr:=$07;
      gotoxy(1,wherey-1); clreol;
      gotoxy(1,wherey-1); clreol;
    end;
    write('Inserisci il numero di variabili: ');
    readln(_nVar_);
    if NVar<_nVar_ then NVar:=_nVar_;
    getmem(equ,sizeof(TCoefficente)*(_nVar_-1)+sizeof(TEquazione));
    case j of
    2: equ^.tipoEqu:='๓';
    3: equ^.tipoEqu:='๒';
    else equ^.tipoEqu:='=';
    end;
    equ^.nVar:=_nVar_;
    equ^.MainVar:=MainVar;
    equ^.MainVarC.posizione:=sinistra;
    if MainVar<>#0 then begin
      gotoxy(1,whereY-1);
      clreol;
      write('Inserisci il coefficente di ',MainVar,': ');
      readln(equ^.MainVarC.c);
    end;
    gotoxy(1,whereY-1);
    clreol;
    writeln('Inserimento dei coefficenti dell''equazione.');
    writeln;
    for j:=1 to _nVar_ do begin
      gotoxy(3,whereY-1);
      clreol;
      write('coefficente di x',j,': ');
      readln(equ^.c[j].c);
      equ^.c[j].posizione:=latoVariabili;
    end;
    gotoxy(1,whereY-1);
    clreol;
    gotoxy(1,whereY-1);
    clreol;
    write('Inserimento del termine noto dell''equazione: ');
    readln(equ^.TermineNoto.c);
    equ^.TermineNoto.posizione:=latoTermineNoto;
  end;
{$R+}


procedure CancellaEquazione(var equ:PEquazione);
  begin
    Freemem(equ,sizeof(TCoefficente)*(equ^.nVar-1)+sizeof(TEquazione));
    equ:=nil;
  end;


procedure CreaSistema;
  var buf:PSistema;
      x,y:word;
      _i_:word;
  begin
    separatoreDS:='';
    latoVariabili:=sinistra;
    new(sistema);
    sistema^.succ:=nil;
    writeln('Vincolo N. 1');
    LeggiEquazione(sistema^.equ,#0);
    x:=wherex;
    y:=wherey;
    window(13,8,80,16);
    VisEquazione(1,1,sistema^.equ);
    window(1,6,80,25);
    gotoxy(x,y);
    if NVincoli>1 then
      buf:=sistema;
      for i:=2 to NVincoli do begin
        gotoxy(1,wherey-2);
        clreol;
        writeln('Vincolo N. ',i);
        new(buf^.succ);
        buf:=buf^.succ;
        LeggiEquazione(buf^.equ,#0);
        buf^.succ:=nil;
        x:=wherex;
        y:=wherey;
        window(13,8,80,16);
        _i_:=i;
        if _i_>9 then begin
          gotoxy(1,1);
          delline;
          _i_:=9;
        end;
        VisEquazione(1,_i_,buf^.equ);
        window(1,6,80,25);
        gotoxy(x,y);
      end;
    latoVariabili:=destra;
    separatoreDS:='=';
  end;

 {**************************************************************************}
 {**********           Procedure per il calcolo dell'ottimo       **********}
 {**************************************************************************}

{N.B.: Presupposto di queste procedure e funzioni  che ogni equazione abbia
       almeno una variabile (nVar<>0).}



{$R-}

{Variabile candidata nel sistema.}
function VarCandidata:word;
  type vet=array[1..1] of word;
  var i,cand:word;
      coeff:real;
      Ncandidate:word;
      candidate:^vet;
      precVideo:TVideo;
  begin
    cand:=1;
    coeff:=max^.c[1].c;
    getmem(candidate,NVar*2);
    Ncandidate:=0;
    for i:=1 to max^.nVar do begin
      if max^.c[i].c=coeff then begin
        inc(Ncandidate);
        candidate^[Ncandidate]:=i;
      end;
      if max^.c[i].c<coeff then begin
        coeff:=max^.c[i].c;
        cand:=i;
        NCandidate:=1;
        candidate^[1]:=i;
      end;
    end;
    if Ncandidate>1 then begin
      precVideo:=video;
      clrscr;
      textattr:=$02;
      writeln('Esistono pi— variabili candidate. Puoi scegliere!');
      writeln('ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ');
      textattr:=$07;
      for i:=1 to Ncandidate do writeln('  ',i,'. X',candidate^[i]);
      write(' -> ');
      textattr:=$02;
      readln(cand);
      textattr:=$07;
      video:=precvideo;
    end;
    Freemem(candidate,NVar*2);
    VarCandidata:=cand;
  end;


{Variabile basica nella equazione numero NEqu.}
function VarBasica(_NEqu_:word):word;
  var i,j:word;
      buf:PSistema;
      equ:PEquazione;
      VarBas:word;
      basica:boolean;
  begin
    if _NEqu_>NEqu then _NEqu_:=NEqu;
    buf:=sistema;
    if _NEqu_>1 then for i:=2 to _NEqu_ do buf:=buf^.succ;
    equ:=buf^.equ;
    VarBas:=0;
    for i:=1 to equ^.nVar do begin
      if equ^.c[i].c=0 then continue;
      basica:=true;
      buf:=sistema;
      for j:=1 to NEqu do begin
        if j<>_NEqu_ then
          if buf^.equ^.c[i].c<>0 then begin
            basica:=false;
            break;
          end;
        buf:=buf^.succ;
      end;
      if basica then begin
        VarBas:=i;
        break;
      end;
    end;
    VarBasica:=VarBas;
  end;


{Numero della equazione uscente nel sistema.}
function Equ_VarUscente(varCand:word; var uscente:word):PEquazione;
  var buf:PSistema;
      equ_u:PEquazione;
      i:word;
      precCoeff,coeff:real;
      primoCoeff:boolean;
  begin
    buf:=sistema;
    equ_u:=buf^.equ;
    uscente:=1;
    i:=1;
    primoCoeff:=true;
    precCoeff:=0;
    while (buf^.succ<>nil) and (buf^.equ^.c[varCand].c<=0) do begin
      inc(uscente);
      equ_u:=buf^.succ^.equ;
      buf:=buf^.succ;
    end;
    buf:=sistema;
    while buf^.succ<>nil do begin
      if buf^.equ^.c[varCand].c>0 then begin
        coeff:=buf^.equ^.TermineNoto.c/buf^.equ^.c[varCand].c;
        if (not primoCoeff) and (coeff<precCoeff) then begin
          precCoeff:=coeff;
          equ_u:=buf^.equ;
          uscente:=i;
        end;
        if primoCoeff then begin
          precCoeff:=coeff;
          primoCoeff:=false;
        end;
      end;
      buf:=buf^.succ;
      inc(i);
    end;
    Equ_VarUscente:=equ_u;
  end;


{Isola il termine noto sul lato specificato.}
procedure Isola_TermineNoto(equ:PEquazione; lato:TPos);
  var i:word;
      altroLato:TPos;
  begin
    if lato=sinistra then altroLato:=destra
                     else altroLato:=sinistra;
    with equ^ do begin
      if (MainVar<>'') and (MainVarC.posizione<>altroLato) then begin
        MainVarC.c:=-MainVarC.c;
        MainVarC.posizione:=altroLato;
      end;
      for i:=1 to nVar do
        if c[i].posizione<>altroLato then begin
          c[i].c:=-c[i].c;
          c[i].posizione:=altroLato;
        end;
      if TermineNoto.posizione<>lato then begin
        TermineNoto.c:=-TermineNoto.c;
        TermineNoto.posizione:=lato;
      end;
    end;
  end;


procedure AggiungiVar(var equ:PEquazione; segno:char);
  var buf:PEquazione;
      i:word;
  begin
    inc(NVar);
    buf:=equ;
    getmem(equ,sizeof(TCoefficente)*(NVar-1)+sizeof(TEquazione));
    equ^:=buf^;
    equ^.nVar:=NVar;
    for i:=1 to buf^.nVar do equ^.c[i]:=buf^.c[i];
    for i:=buf^.nVar+1 to NVar do begin
      equ^.c[i].c:=0;
      equ^.c[i].posizione:=sinistra;
    end;
    if segno='-' then equ^.c[NVar].c:=-1
                 else equ^.c[NVar].c:=1;
    Freemem(buf,sizeof(TCoefficente)*(buf^.nVar-1)+sizeof(TEquazione));
  end;


{Fa si che tutte le equazioni del sistema abbiano lo stesso numero di variabili.}
procedure AllineaSistema;
  var equ:PEquazione;
      buf:PSistema;
      i:word;
  begin
    buf:=sistema;
    while buf<>nil do begin
      equ:=buf^.equ;
      if equ^.nVar<NVar then begin
        getmem(buf^.equ,sizeof(TCoefficente)*(NVar-1)+sizeof(TEquazione));
        buf^.equ^:=equ^;
        buf^.equ^.nVar:=NVar;
        for i:=1 to equ^.nVar do buf^.equ^.c[i]:=equ^.c[i];
        for i:=equ^.nVar+1 to NVar do begin
          buf^.equ^.c[i].c:=0;
          buf^.equ^.c[i].posizione:=sinistra;
        end;
        if equ=max then max:=buf^.equ;
        Freemem(equ,sizeof(TCoefficente)*(equ^.nVar-1)+sizeof(TEquazione));
      end;
      buf:=buf^.succ;
    end;
  end;


procedure CreaSistemaDiLavoro;
  var buf, ultimo:PSistema;
  begin
    buf:=sistema;
    while buf<>nil do begin
      case buf^.equ^.tipoEqu of
      '๒': AggiungiVar(buf^.equ,'-');
      '๓': AggiungiVar(buf^.equ,'+');
      end;
      buf^.equ^.tipoEqu:='=';
      ultimo:=buf;
      buf:=buf^.succ;
    end;
    buf:=ultimo;
    new(buf^.succ);
    buf:=buf^.succ;
    buf^.equ:=max;
    buf^.succ:=nil;
    NEqu:=NVincoli+1;
    max^.MainVarC.c:=-max^.MainVarC.c;
    Isola_TermineNoto(max,destra);
    AllineaSistema;
  end;


function SoluzioneOttima:boolean;
  var i:word;
      ris:boolean;
  begin
    ris:=true;
    for i:=1 to max^.nVar do
      if max^.c[i].c<0 then begin
        ris:=false;
        break;
      end;
    SoluzioneOttima:=ris;
  end;


function EsisteSoluzione:boolean;
  var i,bas:word;
      buf:PSistema;
      ris:word;
  begin
    for i:=1 to NVar do soluzione^[i]:=0;
    buf:=sistema;
    ris:=0;
    i:=1;
    while buf^.succ<>nil do begin
      bas:=VarBasica(i);
      if bas<>0 then begin
        soluzione^[bas]:=buf^.equ^.TermineNoto.c/buf^.equ^.c[bas].c;
        inc(ris);
      end;
      buf:=buf^.succ;
      inc(i);
    end;
    EsisteSoluzione:=(ris=NBasiche);
  end;


procedure CercaAltraSoluzione;
  var candidata,uscente:word;
      equ_u:PEquazione;
      i,j:word;
      coeff:real;
      buf:PSistema;
  begin
    candidata:=VarCandidata;
    equ_u:=Equ_VarUscente(candidata,uscente);

  {*** METODO DEL PIVOT ***}
    {Rende unitario il coefficente della variabile cand. della equazione.}
    coeff:=equ_u^.c[candidata].c;
    for i:=1 to NVar do equ_u^.c[i].c:=equ_u^.c[i].c/coeff;
    equ_u^.TermineNoto.c:=equ_u^.TermineNoto.c/coeff;
    if equ_u^.MainVar<>#0 then equ_u^.MainVarC.c:=equ_u^.MainVarC.c/coeff;
    {Sistemazione delle altre equazioni del sistema.}
    j:=1;
    buf:=sistema;
    while buf<>nil do begin
      if j<>uscente then begin
        if buf^.equ^.c[candidata].c=0 then begin
          inc(j);
          buf:=buf^.succ;
          continue;
        end
        else coeff:=-1/buf^.equ^.c[candidata].c;
        for i:=1 to NVar do
          buf^.equ^.c[i].c:=buf^.equ^.c[i].c*coeff+equ_u^.c[i].c;
        buf^.equ^.TermineNoto.c:=buf^.equ^.TermineNoto.c*coeff+equ_u^.TermineNoto.c;
        if buf^.equ^.MainVar<>#0 then
          if UpCase(buf^.equ^.MainVar)=UpCase(equ_u^.MainVar)
          then buf^.equ^.MainVarC.c:=buf^.equ^.MainVarC.c*coeff+equ_u^.MainVarC.c
          else buf^.equ^.MainVarC.c:=buf^.equ^.MainVarC.c*coeff;
      end;
      inc(j);
      buf:=buf^.succ;
    end;
    EsisteSoluzione;
  end;
{$R+}



procedure Calcola;
  var buf:PSistema;
      i:word;
      bool:boolean;
  begin
    CreaSistemaDiLavoro;
    getmem(soluzione,NVar*6);
    VisSistema(false,false);
    NBasiche:=0;
    buf:=sistema;
    i:=1;
    while buf^.succ<>nil do begin
      if VarBasica(i)<>0 then inc(NBasiche);
      inc(i);
      buf:=buf^.succ;
    end;
    { Algoritmo del Simplesso. }
    if EsisteSoluzione then
      while not SoluzioneOttima do begin
        CercaAltraSoluzione;
        VisSistema(true,SoluzioneOttima);
        while not EsisteSoluzione do begin
          CercaAltraSoluzione;
          VisSistema(true,SoluzioneOttima);
        end;
      end;
  end;


 {**************************************************************************}
 {**********                  Programma principale                **********}
 {**************************************************************************}

begin
  NVar:=0;
  clrscr;
  textattr:=$0E;
  writeln('อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');
  textattr:=$03;
  writeln('                        Ernesto CIANCIOTTA Productions');
  textattr:=$0E;
  writeln('Risoluzione di problemi di P.L. con il metodo del simplesso.');
  writeln('อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');
  textattr:=$07;
  window(1,6,80,25);
  clrscr;
  gotoxy(1,8);
  textattr:=$02;
  writeln('Vuoi risolvere un problema di massimo o di minimo ?');
  writeln('ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ');
  textattr:=$07;
  writeln('  1. massimo');
  writeln('  2. minimo');
  textattr:=$02;
  write('-> ');
  readln(i);
  if i=1 then ProblemaDiMassimo:=true
         else ProblemaDiMassimo:=false;
  textattr:=$07;
  clrscr;
  textattr:=$02;
  writeln('                 Fase di inserimento della funzione di massimo');
  writeln('                 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ');
  textattr:=$07;
  LeggiEquazione(Max,'Z');
  clrscr;
  VisEquazione(1,1,max);
  if ProblemaDiMassimo then writeln('<= MAX':20)
                       else writeln('<= MIN':20);
  writeln;
  write('Vincoli:');
  gotoxy(1,15);
  textattr:=$02;
  writeln('                        Fase di inserimento dei vincoli');
  writeln('                 ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ');
  textattr:=$07;
  write('Inserisci il numero dei vincoli: ');
  readln(NVincoli);
  NEqu:=NVincoli;
  if NVincoli=0 then halt;
  gotoxy(1,wherey-1);
  clreol;
  CreaSistema;
  for i:=1 to 4 do begin
    gotoxy(1,wherey-1);  clreol;
  end;
  pausa;
  Calcola;
end.