uses crt,dos;

var f,f2:text;
    buf:string;
    count:longint;
    j:integer;
    esito:char;
    g,m,a,d:word;
    h,min,sec,s100:word;


begin
  assign(f,'c:\dos\scandisk.chm');
  assign(f2,'c:\dos\scandisk.ch_');
  {$I-}
  reset(f);
  {$I+}
  if ioresult<>0 then count:=1
  else begin
    readln(f,buf);
    readln(f,buf);
    val(buf,count,j);
    inc(count);
    close(f);
  end;
  rewrite(f2);
  writeln(f2,'Dal 18/5/1995 lo ScanDisk Š stato chiamato un numero di volte pari a:');
  writeln(f2,count);
  writeln(f2);
  writeln(f2,'---------------------------------------------------------------------');
  writeln(f2,'Data            Ora           Esito');
  writeln(f2,'---------------------------------------------------------------------');
  if count<>1 then begin
    reset(f);
    for m:=1 to 6 do readln(f,buf);
    while not eof(f) do begin
      readln(f,buf);
      writeln(f2,buf);
    end;
    close(f);
  end;
  clrscr;
  writeln('La scansione ha avuto esito positivo o negativo? (P/N)');
  esito:=#0;
  while not (esito in ['p','P','n','N']) do esito:=readkey;
  getDate(a,m,g,d);
  gettime(h,min,sec,s100);
  writeln(f2,g:2,'/',m:2,'/',a:4,'      ',h:2,':',min:2,':',sec:2,'      ',upcase(esito));
  close(f2);
  if count<>1 then erase(f);
  rename(f2,'c:\dos\scandisk.chm');
end.