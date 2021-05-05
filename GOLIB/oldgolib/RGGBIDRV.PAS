
 {RgBGIdrv.PAS}

{ Example for RegisterBGIDriver function.}

uses Graph;
var
 Driver, Mode: Integer;
 DriverF: file;
 DriverP: pointer;
begin
 { Open driver file, read, register }
 Assign(DriverF, 'c:\tp7\svga16.BGI');
 Reset(DriverF, 1);
 GetMem(DriverP, FileSize(DriverF));
 BlockRead(DriverF, DriverP^,
           FileSIze(DriverF));
 if RegisterBGIdriver(DriverP) < 0 then
 begin
   WriteLn('Error registering driver: ',
           GraphErrorMsg(GraphResult));
   Halt(1);
 end;
 { Init graphics }
 Driver := CGA;
 Mode := CGAHi;
 InitGraph(Driver, Mode,' ');
 if GraphResult < 0 then
   Halt(1);
 OutText('Driver loaded by user program');
 ReadLn;
 CloseGraph;
end.


