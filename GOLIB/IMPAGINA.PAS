{by Ernesto CIANCIOTTA Productions}

{$M 3072,0,0}

uses
    dos,
    crt,
    utility;

const
     COLONNE = 68;
     RIGHE   = 59;
     PAGINA  = 61;
     TAB     = 8;

var
   f_in,out:Text;
   dir,mask:string;
   ext:TExtention;

   bufIn,bufOut:string;

   n_pagina,
   n_linea_out:integer;



   procedure Stampa2;
     var i:byte;
     begin
       if n_linea_out>RIGHE then begin
         for i:=1 to PAGINA-RIGHE-1 do writeln(out);
         if odd(n_pagina)
           then writeln(out,('pag. '+NumStr(n_pagina)):COLONNE)
           else writeln(out,'pag. ',n_pagina);
         close(out);
         inc(n_pagina);
         assign(out,dir+'\PAG_'+NumStr(n_pagina)+'.TXT');
         rewrite(out);
         n_linea_out:=1;
       end
       else inc(n_linea_out);
       writeln(out,bufOut);
     end;


   procedure Stampa;
     var l:byte;
     begin
       l:=length(bufIn);
       bufOut:=bufIn;
       while l>COLONNE do begin
         bufOut:=copy(bufIn,1,COLONNE);
         delete(bufIn,1,COLONNE);
         Stampa2;
         dec(l,COLONNE);
       end;
       bufOut:=bufIn;
       Stampa2;
     end;


   procedure clearBufIn;
     var i:byte;
         t:string;
     begin
       for i:=1 to 255 do t[i]:=' ';  byte(t[0]):=TAB;
       for i:=1 to length(bufIn) do
        if bufIn[i]=#9 then begin
          delete(bufIn,i,1);
          insert(t,bufIn,i);
        end;
     end;


begin
  writeln('Impaginatore (c) 1996');
  if paramcount=0 then begin
    writeln;
    writeln('Sintassi ->  IMPAGINA <file>[.TXT]');
    halt(0);
  end;
  writeln;
  mask:=paramstr(1);
  GetExtention(mask,ext,'TXT');
  {if (pos('\',mask)<>0) or (pos(':',mask)<>0) then begin
    i:=length(mask);
    while not (mask[i] in [':','\']) and (i>1) do dec(i);
    path:=copy(mask,1,i);
    mask:=copy(mask,i+1,length(mask)-i);
    if path[length(path)]='\' then dec(byte(path[0]));
    chDir(path);
  end
  else getDir(0,path);}
  { Creazione della directory in cui immagazinare le pagine }
  dir:=mask;
  SetExtention(dir,'PGN');
  assign(f_in,mask);
  {$I-}
  reset(f_in);
  if ioresult<>0 then begin
    writeln('Nome del file errato o inesistente.');
    halt;
  end;
  mkdir(dir);
  if ioresult<>0 then begin
    writeln('Impossibile creare la directory ',dir);
    halt;
  end;
  {$I+}
  n_pagina:=1;
  n_linea_out:=1;
  assign(out,dir+'\PAG_'+NumStr(n_pagina)+'.TXT');
  rewrite(out);
  while not eof(f_in) do begin
    readln(f_in,bufIn);
    clearBufIn;
    stampa;
  end;
end.