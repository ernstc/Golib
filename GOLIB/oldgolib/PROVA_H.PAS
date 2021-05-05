{ by ERNESTO CIANCIOTTA Productions }

{***************************************************}
{*                                                 *}
{* Prove sull'allocazione dinamica degli oggetti.  *}
{*                                                 *}
{***************************************************}


{$D+}
{$L+}


uses
      codici,
      golib8,
      window,
      frame
      ;



var
    buf:OPView;
    l:pLayout;

    before,
    afterInit,
    afterDone,
    difference,
    DeltaHEAP:longint;

begin
  before:=MemAvail;

  buf:=new(OPframe,

  Init(

    NullRect, '', nil

  ));

  afterInit:=MemAvail;

  dispose(buf,Done);

  afterDone:=MemAvail;
  difference:=afterDone-afterInit;
  DeltaHEAP:=before-afterDone;

end.




