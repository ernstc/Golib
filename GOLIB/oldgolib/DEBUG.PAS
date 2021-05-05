{ by Ernesto CIANCIOTTA Productions }

unit DEBUG;

INTERFACE

   procedure EndOfProgram;

IMPLEMENTATION

uses dos;

var f:text;


   procedure EndOfProgram;
     begin
       rewrite(f);
       writeln(f,'t');
       close(f);
     end;


begin
  assign(f,'c:\dos\golibug.bat');
  rewrite(f);
  writeln(f,'scandisk c:');
  writeln(f,'t');
  close(f);
end.