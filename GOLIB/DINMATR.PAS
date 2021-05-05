unit DinMatr;

{************************************************************}
{*                                                          *}
{*        DinMatr => Dinamic Matrox                         *}
{*                                                          *}
{*  by ERNESTO CIANCIOTTA                                   *}
{*                                                          *}
{*       Modulo per Turbo Pascal ver 7.0                    *}
{*                                                          *}
{************************************************************}


interface
  {$X+,R-}
  uses DinArray;

  type   OPDinamicMatrox = ^OTDinamicMatrox;
         OTDinamicMatrox = object ( ArrayGenerico )
         private
            Sx, Sy, Ex, Ey,
            delta, deltaX:integer;
            generico:PArrayByte;
            DimUnita:word;
         public
            constructor Init(x1,y1,x2,y2:integer; Dimensione:word;
                                                  HeapPos:pointer);
            function Mem(var info; x,y:integer):boolean;
            function Get(x,y:integer; var info):longint;
            procedure FastIn(var info; x,y:integer);
            procedure FastOut(x,y:integer; var info);
            procedure ResetStartCoordinates(Nx,Ny:integer);
            function OttieniDimLavoro:word; virtual;
            function StartX:integer;
            function StartY:integer;
            function EndX:integer;
            function EndY:integer;
            function DimX:integer;
            function DimY:integer;
         end;

implementation

  constructor OTDinamicMatrox.Init;
    begin
      Sx:=x1;  Sy:=y1;
      Ex:=x2;  Ey:=y2;
      DimUnita:=Dimensione;
      deltaX:=Ex-Sx+1; delta:=Sx+Sy*deltaX-1;
      ArrayGenerico.Init(DimX*DimY,Dimensione,HeapPos);
    end;

  function OTDinamicMatrox.Mem;
    begin
      if (x>=Sx) and (x<=Ex) and (y>=Sy) and (y<=Ey) then
        Mem:=Memorizza(info,x+y*deltaX-delta)
      else Mem:=False;
    end;

  function OTDinamicMatrox.Get;
    begin
      if (x>=Sx) and (x<=Ex) and (y>=Sy) and (y<=Ey) then
        Get:=Richiama(x+y*deltaX-delta,info)
      else Get:=0;
    end;

  procedure OTDinamicMatrox.FastIn;
    var i,j:word;
    begin
      generico:=@info;
      j:=(x+y*deltaX-delta-1)*DimUnita;
      for i:=1 to dimUnita do PuntaDati^[i+j]:=generico^[i];
    end;

  procedure OTDinamicMatrox.FastOut;
    var i,j,k:word;
    begin
      generico:=@info;
      j:=(x+y*deltaX-delta-1)*DimUnita;
      for i:=1 to dimUnita do generico^[i]:=PuntaDati^[i+j]
    end;

  function OTDinamicMatrox.OttieniDimLavoro;
    begin
      OttieniDimLavoro:=0;
    end;

  procedure OTDinamicMatrox.ResetStartCoordinates;
    begin
      inc(Ex,Nx-Sx);
      inc(Ey,Ny-Sy);
      Sx:=Nx;   Sy:=Ny;
      delta:=Sx+Sy*deltaX-1;
    end;

  function OTDinamicMatrox.StartX;
    begin
      StartX:=Sx;
    end;

  function OTDinamicMatrox.StartY;
    begin
      StartY:=Sy;
    end;

  function OTDinamicMatrox.EndX;
    begin
      EndX:=Ex;
    end;

  function OTDinamicMatrox.EndY;
    begin
      EndY:=Ey;
    end;

  function OTDinamicMatrox.DimX;
    begin
      DimX:=Ex-Sx+1;
    end;

  function OTDinamicMatrox.DimY;
    begin
      DimY:=Ey-Sy+1;
    end;


end.
