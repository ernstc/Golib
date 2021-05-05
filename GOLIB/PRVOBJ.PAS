{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



{$R-}
{$S-}

program prova_dispfile;
uses
     crt,
     codici,
     graph,
     graftool,
     mouse,
     golib_h,
     golib9,
       dispfile;

type

    o1 = object (OTView)
      procedure mth1;
      procedure mth2(param:pointer);
    end;


    procedure norm1(x,y:integer); far; forward;
    procedure norm2(p:pointer;x,y:integer); far; forward;

    procedure o1.mth1;
      begin
        norm1(r.x1,r.y1);
      end;


    procedure o1.mth2(param:pointer);
      begin
        norm2(param,r.x1,r.y1);
      end;


    procedure norm1(x,y:integer);
      var i:integer;
      begin
        setcolor(random(14)+1);
        setwriteMode(NormalPut);
        for i:= 1 to 50 do begin
          circle(MaxXResolution div 2+x, MaxYResolution div 2+y,i*3);
        end;
      end;


    procedure norm2(p:pointer; x,y:integer);
      var i:integer;
          incr:integer;
      begin
        setcolor(ofs(p^));
        setwriteMode(NormalPut);
        {for i:= 0 to 50 do
          ellipse(MaxXResolution div 2+x, MaxYResolution div 2+y,0,360,i*4,i*3);}
        for i:= 1 to 50 do begin
          incr:=trunc(i*(2+0.2*i));
          line(100+x+incr,100+y,100+x+incr,400+y);
          line(100+x,100+y+incr,600+x,100+y+incr);
        end;
      end;


var o:o1;
    m:TMessage;

    list, list2, p: PRefreshRectList;

    x,i:integer;

    proc:pointer;

    rr:OTRect;

begin
  randomize;
  { creazione di una dista di prova }
  list:=nil;
  for i:=1 to 30 do begin
    if list=nil then begin
      new(p);
      list:=p;
    end
    else begin
      new(p^.succ);
      p:=p^.succ;
    end;
    p^.succ:=nil;
    p^.r.SetRect(random(400)+100,random(300)+50,random(100),random(100));
  end;

  InizializzaGrafica(3,16);

  EnableVideo;

  hidemousecursor;


  DrawRefreshListProc(list,nil,@norm1,nil,NoParam);

  cleardevice;

  readkey;

  new(p);
  p^.succ:=nil;

  repeat
    p^.r.SetRect(random(400)+100,random(300)+50,random(100),random(100));
    DrawRefreshListProc(p,nil,@norm1,nil,NoParam);
  until readkey=#27;


  DrawRefreshListProc(list,nil,@norm2,Ptr(0,random(14)+1),YesParam);

  readkey;

  cleardevice;

  new(p);
  p^.succ:=nil;

  repeat
    p^.r.SetRect(random(400)+100,random(300)+50,random(100),random(100));
    DrawRefreshListProc(p,nil,@norm2,Ptr(0,random(14)+1),YesParam);
  until keypressed;

  {
  DisposeRefreshList(list);
  }

  rr.setRect(100,200,400,200);
  o.Init(Null_ID,rr);


  proc:=@prova_dispfile.o1.mth1;

  DrawRefreshListProc(list,@o,proc,nil,ObjectNoParam);

  readkey;

  cleardevice;

  new(p);
  p^.succ:=nil;

  repeat
    p^.r.SetRect(random(400)+100,random(300)+50,random(100),random(100));
    DrawRefreshListProc(p,@o,proc,nil,ObjectNoParam);
  until keypressed;


  proc:=@prova_dispfile.o1.mth2;

  DrawRefreshListProc(list,@o,proc,Ptr(0,random(14)+1),ObjectYesParam);

  readkey;

  cleardevice;

  new(p);
  p^.succ:=nil;

  repeat
    p^.r.SetRect(random(400)+100,random(300)+50,random(100),random(100));
    DrawRefreshListProc(p,@o,proc,Ptr(0,random(14)+1),ObjectYesParam);
  until keypressed;


  o.Done;
  readkey;
end.