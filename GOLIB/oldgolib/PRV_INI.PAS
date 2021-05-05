{ by Ernesto CIANCIOTTA Priductions }


uses strings,ini;

var f:OTInitFile;
    name:PChar;

begin
  name:=StrNewPas('c:\windows\win.ini');
  f.Init(name);
  StrDispose(name);
end.