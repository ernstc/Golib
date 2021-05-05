uses
    crt;

var hz:word;
begin
  hz:=0;
  writeln(hz:5);
  while true do begin
    case readkey of
    '+': if hz<20000 then begin
           inc(hz,2);
           writeln(hz:5);
         end;
    '-': if hz>0 then begin
           dec(hz,2);
           writeln(hz:5);
         end;
    #27: break;
    end;
    sound(hz);
  end;
  nosound;
end.