{by Ernesto CIANCIOTTA Productions}

{$M 3072,0,0}

uses utility,dos,crt;

const passo=2048;

var f:file;
    DirInfo:SearchRec;
    i,size:longint;
    main:string;
    ch:char;
    p,path,mask:string;
    messages:boolean;

    txt:array[1..passo div 32] of string[32];

    totbytes:longint;

begin
  totbytes:=0;
  getDir(0,p);
  if (paramcount>=3) and (paramstr(3)='no') then messages:=false
                                            else messages:=true;
  if messages then writeln('RESET by OKK Soft (c) 1995');
  if paramcount=0 then begin
    writeln;
    writeln('Sintassi ->  RESET (files) [/Y]');
    halt(0);
  end;
  writeln;
  if (paramcount>=2) and ((paramstr(2)='/y') or (paramstr(2)='/Y'))
  then
  else begin
    while not (ch in ['s','S','n','N']) do begin
      write('Vuoi procedere con il reset dei files ? (s/n)');
      ch:=readkey;
      writeln(ch);
    end;
    if ch in ['n','N'] then halt(0);
  end;
  writeln;
  for i:=1 to passo div 32 do txt[i]:='     RESET OKK Soft (c) ''95     ';
  main:=paramstr(0);
  mask:=paramstr(1);
  if (pos('\',mask)<>0) or (pos(':',mask)<>0) then begin
    i:=length(mask);
    while not (mask[i] in [':','\']) and (i>1) do dec(i);
    path:=copy(mask,1,i);
    mask:=copy(mask,i+1,length(mask)-i);
    if path[length(path)]='\' then dec(byte(path[0]));
    chDir(path);
  end
  else getDir(0,path);
  FindFirst(mask, Archive, DirInfo);
  main:=StrUpperPas(main);
  while DosError = 0 do begin
    if StrUpperPas(path+'\'+DirInfo.Name)<>main then begin
      if messages then write(DirInfo.Name,' ':15-length(DirInfo.Name));
      assign(f,DirInfo.Name);
      reset(f,1);
      size:=FileSize(f);
      inc(totbytes,size);
      if messages then write(MillesFormat(size):23,'  bytes   =>   ');
      rewrite(f,1);
      while size>=passo do begin
        blockwrite(f,txt,passo);
        dec(size,passo);
      end;
      if size>0 then blockwrite(f,txt,size);
      close(f);
      if messages then writeln('Resettati !');
    end
    else if messages then writeln(DirInfo.Name,'    (programma in esecuzione)');
    FindNext(DirInfo);
  end;
  writeln;
  writeln('Directory: ',StrUpperPas(path));
  writeln('  ',MillesFormat(totbytes),' bytes resettati.');
  writeln;
  chDir(p);
end.
