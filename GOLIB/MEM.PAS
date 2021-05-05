uses strings;

type

   TPointer = record
      offset,
      segment:word;
   end;


var s:string;
    c:PChar;
    p2,
    p:pointer;
    m:longint;
    l:byte;

begin
  m:=maxavail;
  if m>30000 then m:=30000;
  getmem(p,m);
  s:='cianciotta';
  l:=length(s);
  s[l+1]:=#0;
  c:=@s;
  inc(TPointer(c).offset);
  StrCopy(PChar(p),c);
  p2:=p;
  inc(TPointer(p).offset,l+1);
  FreeMem(p,m-(l+1));
end.