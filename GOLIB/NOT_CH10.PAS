uses dos;
var f:file of byte;
    dest:file of byte;
    buf:byte;

begin
  if paramcount=0 then halt;
  if paramstr(1)='/?' then begin
    writeln;
    writeln('Ernesto CIANCIOTTA Productions');
    writeln;
    writeln('Utiliti per filtrare i file testo cosç da renderli compatibili con MS-Word.');
    writeln('not_ch10  file_sorgente  file_destinazione');
    halt;
  end;
  assign(f,paramstr(1));
  assign(dest,paramstr(2));
  reset(f);
  rewrite(dest);
  while not eof(f) do begin
    read(f,buf);
    if buf<>10 then write(dest,buf);
  end;
end.