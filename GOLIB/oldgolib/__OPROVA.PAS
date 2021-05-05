unit __oprova;
interface
type obj1=object
       constructor init;
       destructor done;
       procedure _1; virtual;
     end;

     obj2=object(obj1)
     private
       procedure _1; virtual;
       procedure _2;
     end;

     __obj1=^obj1;
     __obj2=^obj2;

     TCharPos = ^TCharPos;

implementation
type
     TCharPos = record
       c,w:longint;
     end;

     constructor obj1.init;
       begin
       end;

     destructor obj1.done;
       begin
       end;

     procedure obj1._1;
       begin
         writeln('ciao!');
       end;

     procedure obj2._1;
       begin
         writeln('CIAO ?');
       end;

     procedure obj2._2;
       begin
         writeln('Bye Bye');
       end;

end.