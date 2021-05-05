uses crt,__oprova;

var o1:__obj1;
    o2:__obj2;
    buf:pointer;
    c:TCharPos;

begin
  clrscr;
  c.c:=1;
  new(o1,Init);
  new(o2,Init);
  o1^._1;
  buf:=o1;
  o1:=o2;
  o1^._1;
  o1:=buf;
  o1^._1;
  o2^._1;
  o2^._2;
  dispose(o1,done);
  dispose(o2,done);
  readkey;
end.