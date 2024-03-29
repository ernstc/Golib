{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



UNIT CRT_adv;

INTERFACE

type
     TCarattere = record
        case byte of
        0: (ch: word);
        1: (car: char; attr: byte);
     end;


     PVideo = ^TVideo;
     TVideo = record
        case byte of
        0: (mem: array[0..1999] of word);
        1: (scr: array[0..1999] of TCarattere);
        2: (ch : array[1..25,1..80] of TCarattere);
     end;


var
     { Buffer in cui viene salvata la videata prima della modifica }
     PrecVideo  : PVideo;
     { Puntatore al buffer della memoria video }
     Video      : PVideo;


     function VideoSegment:word;
     function MaxX:integer;
     function MaxY:integer;

     procedure SpecialWrite(stringa:string);

     procedure Evidenzia(x1,y1,x2,y2:integer; attributo:byte);

     procedure Tasto(col,riga:integer;intestazione:string;larghezza,fase:byte);
     procedure TastoOmbreggiato(stato:boolean;col,riga:integer;intestazione:string);
     procedure Bordo(attivo:boolean; x1,y1,x2,y2:integer; TextAttributes:byte;
                     primo:boolean);

     procedure Rect(x1,y1,x2,y2:byte; TextAttributes:byte; attivo:boolean);

     procedure OpenWin(x1,y1,x2,y2:integer;int,crn,intr:byte;intest:string;max:boolean);


{* Gestione di uno stack in cui vengono salvate le videate *}

     { Salva la videata e mette nello stack }
     procedure PushVideo;
     { Ripristina la videata e la elimina dallo stack }
     procedure PopVideo;

     { Restituisce il puntatore alla "idx"-esima videata presente nello stack }
     function GetStackPtr(idx:word):PVideo;

     {Utility per la lettura validata dell'input}
     function ValidRead(format:string):string;
     function ValidReadNum:longint;



IMPLEMENTATION

uses
    crt,
    bios_utt;

type
     PVideata = ^TVideata;
     TVideata = record
        video: PVideo;
        succ : PVideata;
     end;

var
     indice: byte;
     ch    : char;
const
     { Stack }
     stack: PVideata =nil;




  function VideoSegment:word;
    begin
      if LastMode=7 then VideoSegment:=SegB000
                    else VideoSegment:=SegB800;
    end;


  function MaxX:integer;
    begin
      MaxX:=Lo(WindMax)-Lo(WindMin)+1;
    end;


  function MaxY:integer;
    begin
      MaxY:=Hi(WindMax)-Hi(WindMin)+1;
    end;


  procedure SpecialWrite(stringa:string);
    var i,j,c,y:integer;
        corrige,lrg,lrg2:byte;
        cr,cr2:char;
    begin
      y:=whereY;
      lrg:=lo(windMax)-lo(windMin)+1;
      if odd(lrg) then corrige:=1
                  else corrige:=0;
      lrg2:=lrg div 2;
      c:=length(stringa);
      if not(odd(c))
        then c:=c div 2
        else begin
          c:=(c+1) div 2;
          stringa:=stringa+' ';
        end;
      for i:=1 to c do begin
        cr:=stringa[c-i+1];
        cr2:=stringa[c+i];
        for j:=1 to lrg2-i do begin
          gotoxy(j,y);         writeln(' ',cr);
          delay(1);
          gotoxy(lrg-j-corrige,y);     write(cr2,' ');
          delay(1);
        end;
      end;
    end;


  procedure Tasto(col,riga:integer; intestazione:string; larghezza,fase:byte);
    const cl:array[0..2,0..1] of byte=((15,8),(8,8),(8,15));
    var i:integer;
    begin
      textcolor(cl[fase,0]);
      textbackground(7);
      gotoxy(col,riga);  write('�');
      for i:=1 to larghezza-2 do write('�');
      gotoxy(col,riga+1);  write('�');
      gotoxy(col,riga+2);  write('�');
      textcolor(cl[fase,1]);
      for i:=1 to larghezza-2 do write('�');
      write('�');
      gotoxy(col+larghezza-1,riga+1);  write('�');
      gotoxy(col+larghezza-1,riga);    write('�');
      if intestazione<>'' then begin
        textcolor(14);
        gotoxy(col+((larghezza-length(intestazione)) div 2),riga+1);
        write(intestazione);
      end;
    end;


  procedure TastoOmbreggiato(stato:boolean; col,riga:integer; intestazione:string);
    const carattere:array[false..true] of byte = (0,9);
          speciale:boolean = false;
    var i:integer;
    begin
      textcolor(carattere[stato]);
      textbackground(2);
      gotoxy(col,riga);
      for i:=col to length(intestazione)-1+col do
        if intestazione[i-col+1]='~' then begin
          speciale:=not(speciale);
          if speciale then textcolor(6)
                      else textcolor(carattere[stato]);
        end
        else write(intestazione[i-col+1]);
      TextAttr:=$70;
      write('�');
      gotoxy(col+1,riga+1);
      for i:=1 to length(intestazione)-2 do write('�');
    end;


  procedure Evidenzia(x1,y1,x2,y2:integer; attributo:byte);
    var cella,x,y:integer;
    begin
      for y:=y1 to y2 do
        for x:=x1 to x2 do
          begin
            cella:=80*y+x-81;
            Video^.mem[cella]:=(Video^.mem[cella] AND $00FF)+(attributo SHL 8);
          end;
    end;


  procedure Bordo(attivo:boolean; x1,y1,x2,y2:integer; TextAttributes:byte;
                  primo:boolean);
    const risorse:array[false..true,1..10] of char =
                               (('�','�','�','�','�','�','�','�','�','�'),
                                ('�','�','�','�','�','�','�','�','�','�'));
    var i:integer;
        sfondo,at:byte;
    begin
      sfondo:=TextAttributes shr 4;
      at:=textattr shr 4;
      window(x1,y1,x2,y2+1);
      TextAttr:=TextAttributes;
      write(risorse[attivo,1]);
      for i:=2 to maxx-1 do write(risorse[attivo,7]);
      write(risorse[attivo,2]);
      gotoxy(1,2);    write(risorse[attivo,5]);
      gotoxy(maxx,2); write(risorse[attivo,6]);
      gotoxy(1,3);    write(risorse[attivo,5]);
      gotoxy(maxx,3); write(risorse[attivo,6]);
      textbackground(at);
      for i:=4 to maxy-2 do
        begin
          gotoxy(1,i);    write(risorse[attivo,5]);
          gotoxy(maxx,i); write(risorse[attivo,6]);
        end;
      write(risorse[attivo,3]);
      for i:=2 to maxx-1 do write(risorse[attivo,8]);
      write(risorse[attivo,4]);
      textbackground(sfondo);
      gotoxy(1,3);    write(risorse[attivo,9]);
      gotoxy(maxx,3); write(risorse[attivo,10]);
      gotoxy(2,3);    for i:=2 to maxx-1 do write('�');
      if not primo then
        Evidenzia(2+x1-1,2+y1-1,maxx+x1-1,2+y1-1,TextAttr)
      else begin
        gotoxy(2,2); for i:= 2 to maxx-1 do write(' ');
      end;
    end;


  procedure Rect(x1,y1,x2,y2:byte; TextAttributes:byte; attivo:boolean);
    const risorse:array[false..true,1..6] of char =
                               (('�','�','�','�','�','�'),
                                ('�','�','�','�','�','�'));
    var i:byte;
    begin
      textAttr:=TextAttributes;
      if x2<=x1 then x2:=x1+1;
      if y2<=y1 then y2:=y1+1;
      gotoxy(x1,y1);  write(risorse[attivo,1]);
      if x2-x1>1 then for i:=2 to x2-x1 do write(risorse[attivo,6]);
      write(risorse[attivo,2]);
      if y2-y1>1 then
        for i:=y1+1 to y2-1 do begin
          gotoxy(x1,i); write(risorse[attivo,5]);
          gotoxy(x2,i); write(risorse[attivo,5]);
        end;
      gotoxy(x1,y2); write(risorse[attivo,3]);
      if x2-x1>1 then for i:=2 to x2-x1 do write(risorse[attivo,6]);
      write(risorse[attivo,4]);
      textAttr:=$07;
    end;


  procedure OpenWin(x1,y1,x2,y2:integer; int,crn,intr:byte; intest:string; max:boolean);
    var l,i:integer;
        ang:byte;
    begin
      textattr:=intr;
      window(x1,y1,x2,y2);
      clrscr;
      if length(intest)>MaxX-5 then intest[0]:=chr(MaxX-5);
      textattr:=int;
      write('���');
      l:=x2-x1-4-length(intest);
      for i:=1 to l div 2 do write('�');
      write(intest);
      for i:=1 to l div 2 + l mod 2 do write('�');
      if max then write('׽')
             else write('ּ');
      for i:=y1+1 to y2-1 do begin
        with Video^.ch[i,x1] do begin
          attr:=crn;
          car:='�';
        end;
        with Video^.ch[i,x2] do begin
          attr:=crn;
          car:='�';
        end;
      end;
      ang:=(crn and $f0)+(int and $0f);
      textattr:=ang;
      gotoxy(1,maxY);
      write('�');
      for i:=x1+1 to x2-1 do
        with Video^.ch[y2,i] do begin
          attr:=crn;
          car:='�';
        end;
      with Video^.ch[y2,x2] do begin
        attr:=ang;
        car:='�';
      end;
      Evidenzia(x2+1,y1+1,x2+2,y2+1,$08);
      Evidenzia(x1+2,y2+1,x2,y2+1,$08);
    end;


  procedure PushVideo;
    var v:PVideata;
    begin
      { Crea l'elemento e lo inserisce nello stack }
      new(v);
      new(v^.video);
      v^.succ:=stack;
      stack:=v;
      { Salva la videata }
      v^.video^:=Video^;
    end;


  procedure PopVideo;
    var v:PVideata;
    begin
      if stack = nil then exit;
      { Ripristina la videata }
      Video^:=stack^.video^;
      { Elimina l'elelmento dallo stack }
      v:=stack;
      stack:=stack^.succ;
      dispose(v^.video);
      dispose(v);
    end;


  function GetStackPtr(idx:word):PVideo;
    var v:PVideata;
    begin
      v:=stack;
      while idx>1 do begin
        if stack=nil then begin
          GetStackPtr:=nil;
          exit;
        end;
        dec(idx);
        v:=v^.succ;
      end;
      GetStackPtr:=v^.video;
    end;

  { Questa procedure legge una stringa validando ogni carattere
    durante l'input secondo quanto descritto dalla variabile
    "format".

    ValidRead legge massimo un numero di caratteri pari alla
    lunghezza di "format" e il carattere i-esimo della stringa
    che si va a leggere deve essere del formato specificato
    dal carattere i-esimo di "format".

    Il risultato della lettura viene restituito in "s".

    E' possibile utilizzare, durante l'editing, i seguenti tasti speciali:
    CANC, INS, HOME, END, BACKSPACE, LEFTROW, RIGHTROW.

    I caratteri di "format" possono assumere i seguenti valori
    con il rispettivo significato indicato al lato:
    X     carattere generico;
    N     numero;
    C     carattere alfabetico;
    K     carattere alfa-numerico.

    "format" pu� assumere anche i seguenti valori:
    '\X'          legge qualsiasi stringa
    '\N'          legge solo caratteri numerici
    '\C'          legge solo caratteri alfabetici
    '\K'          legge caratteri alfa-nuemrici
    Se poi si aggiunge:
    '\'+numero'
    andr� a leggere massimo "numero" caratteri del tipo specificato.

    Se viene specificato un formato che non inizia con il carattere '\',
    allora verr� disattivati i tasti INS e CANC ed il tasto BACKSPACE
    potr� essere utlizzato solo se il cursore si trova dopo l'ultimo
    carattere. Disattivando il tasto INS si potr� scrivere solo il
    modalit� OVERWRITE MODE.

    Se viene specificato un formato che inizia con il carattere '\'
    sar�, invece, possibile usare tutti i tasti speciali e scrivere
    anche in modalit� INSERT MODE.

    Per terminare l'editing, digitare ENTER.
  }
  function ValidRead(format:string):string;
    var
        s:string;
        i:integer;
        ch,tipo:char;
        InsMode:boolean;
        x,y:shortint;
        writeBlank:boolean;
        AllMode:boolean;
        maxLength:byte;

    procedure Avviso;
      begin
        sound(200);
        delay(50);
        nosound;
      end;

    begin
      AllMode:= format[1]='\';
      if AllMode then begin
        { controlla se � stata specificata la lunghezza }
        if format[3]='\' then begin
          maxLength:=0;
          { determina la lunghezza }
          for i:=4 to length(format) do maxLength:=maxLength*10+ord(format[i])-48;
        end
        else maxLength:=255;
      end
      else maxLength:=length(format);
      InsMode:=true;
      x:=whereX;
      y:=whereY;
      i:=1;
      s:='';
      repeat
        writeBlank:=false;
        ch:=readkey;
        { controlla se � stato digitato un tasto speciale }
        case ch of
        #0: case readkey of
            { CANC }
            #$53: if AllMode then begin
                    delete(s,i,1);
                    writeBlank:=true;
                  end;
            { INS }
            #$52: if AllMode then begin
                    InsMode:=not InsMode;
                    if InsMode then SetStandardDimCursor
                               else SetDimCursor(1,14);
                   end;
            { HOME }
            #$47: i:=1;
            { END }
            #$4F: i:=length(s)+1;
            { LEFTROW }
            #$4B: if i>1 then dec(i);
            { RIGHTROW }
            #$4D: if i<=length(s) then inc(i);
            end;
        { BACKSPACE }
        #8: if (AllMode and (i>1)) or (not AllMode and (i=length(s)+1)) then begin
              delete(s,i-1,1);
              dec(i);
              writeBlank:=true;
            end;          #13: ;
        else if (InsMode and (length(s)=maxLength)) or
                (not InsMode and (i>maxLength))
               then Avviso
               else begin
                 if AllMode then tipo:=format[2]
                            else tipo:=format[i];
                 case tipo of
                 'X': begin
                        if InsMode then insert(ch,s,i)
                        else begin
                          s[i]:=ch;
                          if i>length(s) then s[0]:=char(i);
                        end;
                        inc(i);
                      end;
                 'N': if (ch in ['0'..'9']) or (ch='-') or (ch='+') then begin
                        if InsMode then insert(ch,s,i)
                        else begin
                          s[i]:=ch;
                          if i>length(s) then s[0]:=char(i);
                        end;
                        inc(i);
                      end
                      else Avviso;
                 'C': if UpCase(ch) in ['A'..'Z'] then begin
                        if InsMode then insert(ch,s,i)
                        else begin
                          s[i]:=ch;
                          if i>length(s) then s[0]:=char(i);
                        end;
                        inc(i);
                      end
                      else Avviso;
                 'K': if (UpCase(ch) in ['A'..'Z']) or
                         (ch in ['0'..'9']) or (ch='-') or (ch='+') then begin
                        if InsMode then insert(ch,s,i)
                        else begin
                          s[i]:=ch;
                          if i>length(s) then s[0]:=char(i);
                        end;
                        inc(i);
                      end
                      else Avviso;
                 end;
               end;
        end;
        gotoxy(x,y);
        write(s);
        if writeBlank then write(' ');
        gotoxy(x + (i-1) mod 80, y + (i-1) div 80);
      until ch=#13;
      SetStandardDimCursor;
      gotoxy(x + length(s) mod 80, y + length(s) div 80);
      ValidRead:=s;
    end;


  function ValidReadNum:longint;
    var buf:string[11];
        j:integer;
        n:longint;
    begin
      buf:=ValidRead('\N\11');
      val(buf,n,j);
      ValidReadNum:=n;
    end;






  { Procedure di uscita dal modulo }
  procedure Exit_CRTadv; far;
    var v:PVideata;
    begin
      while stack<>nil do begin
        v:=stack;
        stack:=stack^.succ;
        dispose(v^.video);
        dispose(v);
      end;
    end;


BEGIN
  ExitProc:=@Exit_CRTadv;
  if Lastmode=7 then Video:=Ptr(SegB000,0)
                else Video:=ptr(SegB800,0);
END.