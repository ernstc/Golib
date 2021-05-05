{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



{*************************************************************************}
{*                                                                       *}
{*  Modulo della libreria GOLIB contenente gli oggetti OTBitmap e        *}
{*  OTIcon.                                                              *}
{*                                                                       *}
{*  Scritto con Turbo Pascal 7.0.                                        *}
{*                                                                       *}
{*************************************************************************}

{$DEFINE FastBackground}

{ Questa opzione fa in modo che venga costruito in memoria centrale l'intero
  background cosç da visualizzarlo in una sola passata. }

UNIT BitMap;

INTERFACE


uses
     codici,
     utility,
     graftool,
     bitmaps,
     resman,
     golib_h,
     golib9;



type

     OPBitmap = ^OTBitmap;
     OTBitmap = object (OTView)
        constructor LoadBitmap(_ID:word; x,y:integer; fromFile:string; identifier:word);
        constructor LoadBitmapStr(_ID:word; x,y:integer; fromFile:string; identifier:string);
        constructor RegisterHCA(_ID:word; x,y:integer; var fromMem:HCA);
        constructor RegisterBMP(_ID:word; x,y:integer; var fromMem);
        constructor RegisterBMP_RESStr(_ID:word; x,y:integer; var fromMem; NRes:word; IDStr:string);
        constructor RegisterBMP_RESWord(_ID:word; x,y:integer; var fromMem; NRes:word; IDWord:word);
        destructor Done; virtual;
        procedure Moving(X, Y, DX, DY: integer);
        procedure Disegna; virtual;
        procedure GetDuplicate(var Duplicate:HCA);
     private
        ExternalHCA:boolean;
        HeaderCA:HCA;
     end;


     OPIcon = ^OTIcon;
     OTIcon = object (OTView)
     end;


     OPBackground = ^OTBackground;
     OTBackground = object (OTView)
        constructor Init(bkgrFile:string; centrale:boolean);
        destructor Done; virtual;
        procedure Disegna; virtual;
     private
        center:boolean;
        Background:HCA;
     end;




IMPLEMENTATION


                              {----- OTBitmap -----}
   constructor OTBitmap.LoadBitmap(_ID:word; x,y:integer; fromFile:string; identifier:word);
     var DimBMP:Longint;
         BMPPointer:pointer;
         coord:OTRect;
         estensioneFile:TExtention;
     begin
       GetExtention(fromFile,estensioneFile,'BMP');
       if estensioneFile='BMP'
       then DimBMP:=Bitmaps.LoadBitmap(fromFile,BMPpointer)
       else
         if estensioneFile='RES'
         then DimBMP:=LoadBMPResource_IDNum(fromFile,identifier,BMPpointer);
       if DimBMP=0 then fail;
       if CreateCompatibleArea(HeaderCA,BMPpointer^)=nil then fail;
       FreeMem(BMPpointer,DimBMP);
       with HeaderCA do coord.assign(x,y,DimX+x-1,DimY+y-1);
       ExternalHCA:=false;
       inherited Init(_ID,coord);
       SysConfig:=SysConfig or cfPostDraw;
     end;


   constructor OTBitmap.LoadBitmapStr(_ID:word; x,y:integer; fromFile:string; identifier:string);
     var DimBMP:Longint;
         BMPPointer:pointer;
         coord:OTRect;
         estensioneFile:TExtention;
     begin
       GetExtention(fromFile,estensioneFile,'BMP');
       if estensioneFile='BMP' then DimBMP:=Bitmaps.LoadBitmap(fromFile,BMPpointer);
       if estensioneFile='RES' then DimBMP:=LoadBMPResource_IDStr(fromFile,identifier,BMPpointer);
       if DimBMP=0 then fail;
       if CreateCompatibleArea(HeaderCA,BMPpointer^)=nil then fail;
       FreeMem(BMPpointer,DimBMP);
       with HeaderCA do coord.assign(x,y,DimX+x-1,DimY+y-1);
       ExternalHCA:=false;
       inherited Init(_ID,coord);
       SysConfig:=SysConfig or cfPostDraw;
     end;


   constructor OTBitmap.RegisterHCA(_ID:word; x,y:integer; var fromMem:HCA);
     var coord:OTRect;
     begin
       HeaderCA:=fromMem;
       with HeaderCA do coord.assign(x,y,DimX+x-1,DimY+y-1);
       ExternalHCA:=true;
       inherited Init(_ID,coord);
       SysConfig:=SysConfig or cfPostDraw;
     end;


   constructor OTBitmap.RegisterBMP(_ID:word; x,y:integer; var fromMem);
     var BMPpointer:pointer;
         coord:OTRect;
     begin
       BMPpointer:=@fromMem;
       if CreateCompatibleArea(HeaderCA,BMPpointer^)=nil then fail;
       with HeaderCA do coord.assign(x,y,DimX+x-1,DimY+y-1);
       ExternalHCA:=false;
       inherited Init(_ID,coord);
       SysConfig:=SysConfig or cfPostDraw;
     end;


   constructor OTBitmap.RegisterBMP_RESStr(_ID:word; x,y:integer; var fromMem; NRes:word; IDStr:string);
     var BMPpointer:pointer;
         coord:OTRect;
     begin
       if GetBMPResource_IDStr(@fromMem,NRes,IDStr,BMPpointer)=0 then fail;
       if CreateCompatibleArea(HeaderCA,BMPpointer^)=nil then fail;
       with HeaderCA do coord.assign(x,y,DimX+x-1,DimY+y-1);
       ExternalHCA:=false;
       inherited Init(_ID,coord);
       SysConfig:=SysConfig or cfPostDraw;
     end;


   constructor OTBitmap.RegisterBMP_RESWord(_ID:word; x,y:integer; var fromMem; NRes:word; IDWord:word);
     var BMPpointer:pointer;
         coord:OTRect;
     begin
       if GetBMPResource_IDNum(@fromMem,NRes,IDWord,BMPpointer)=0 then fail;
       if CreateCompatibleArea(HeaderCA,BMPpointer^)=nil then fail;
       with HeaderCA do coord.assign(x,y,DimX+x-1,DimY+y-1);
       ExternalHCA:=false;
       inherited Init(_ID,coord);
       SysConfig:=SysConfig or cfPostDraw;
     end;


   destructor OTBitmap.Done;
     begin
       if not ExternalHCA then DestroyDC(HeaderCA);
       inherited Done;
     end;


   procedure OTBitmap.Moving(X, Y, DX, DY: integer);
     var Rx,Ry:real;
     begin
     end;


   procedure OTBitmap.Disegna;
     begin
       BitBtl(HeaderCA,VideoDC,0,0,r.x1,r.y1,r.DimX+1,r.DimY+1);
     end;


   procedure OTBitmap.GetDuplicate(var Duplicate:HCA);
     begin
     end;


                         {----- OTBackground -----}
   constructor OTBackground.Init(bkgrFile:string; centrale:boolean);
     var BMP:pointer;
         BMPsize:longint;
         coord:OTRect;
         x1,y1:integer;
     {$IFDEF FastBackground}
         HeaderCA:HCA;
         _x_,_y_,dx,dy:integer;
     {$ENDIF}
     begin
       if bkgrFile='' then fail;
       center:=centrale;
       { Carica il bitmap e lo prepara in memoria }
       BMPsize:=LoadBitmap(bkgrFile,BMP);
       if CreateCompatibleArea(Background,BMP^)=nil then fail;
       FreeMem(BMP,BMPsize);
       if centrale then begin
         { Determina le coordinate per centrare il bitmap in mezzo allo schermo }
         x1:=(MaxXResolution-Background.DimX) div 2;
         x1:=x1-(x1 mod 8);
         y1:=(MaxYResolution-Background.DimY) div 2;
         y1:=y1-(y1 mod 8);
         coord.assign(x1,
                      y1,
                      x1 + Background.DimX-1,
                      y1 + Background.DimY-1);
         inherited Init(Null_ID,coord);
       end
       {$IFNDEF FastBackground}
       else inherited Init(Null_ID,FullRect);
       {$ELSE}
       else begin
         { Crea un HCA che copre tutta la superficie dello schermo e duplica
           il bitmap all'interno di questa nuova HCA }
         ClippingForBITBTL:=false;
         HeaderCA:=Background;
         CreateCompatibleDC(Background,MaxXResolution,MaxYResolution);
         _y_:=0;
         _x_:=0;
         dx:=HeaderCA.DimX;
         dy:=HeaderCA.DimY;
         asm
           MOV AX,2
           INT 33H     {nasconde il mouse}
         end;
         while _y_<MaxYResolution do begin
           BitBtl(HeaderCA,Background,0,0,_x_,_y_,dx,dy);
           _x_:=_x_+HeaderCA.DimX;
           if _x_+dx>MaxXResolution then dx:=MaxXResolution-_x_;
           if _y_+dy>MaxYResolution then dy:=MaxYResolution-_y_;
           if _x_>MaxXResolution then begin
             _x_:=0;
             dx:=HeaderCA.DimX;
             inc(_y_,HeaderCA.DimY);
           end;
         end;
         asm
           MOV AX,1
           INT 33H     {mostra il mouse}
         end;
         ClippingForBITBTL:=true;
         inherited Init(Null_ID,FullRect);
       end;
       {$ENDIF}
     end;


   destructor OTBackground.Done;
     begin
       DestroyDC(Background);
       inherited Done;
     end;


   procedure OTBackground.Disegna;
     var  _x_, _y_,
          dx , dy ,
          dx2, dy2: integer;

     begin
       ClippingForBITBTL:=true;
       if center then BitBtl(Background,VideoDC,0,0,r.x1,r.y1,background.DimX,background.DimY)
       else begin
         {$IFNDEF FastBackground}
         _y_:=0;
         _x_:=0;
         dx:=Background.DimX;
         dy:=Background.DimY;
         dx2:=abs(r.x1) mod dx;
         dy2:=abs(r.y1) mod dy;
         asm
           MOV AX,2
           INT 33H     {nasconde il mouse}
         end;
         while _y_<MaxYResolution do begin
           BitBtl(Background,VideoDC,dx2,dy2,_x_,_y_,dx,dy);
           if dx2<>0 then begin
             dec(_x_,dx2);
             dx2:=0;
           end;
           _x_:=_x_+Background.DimX;
           if _x_+dx>MaxXResolution then dx:=MaxXResolution-_x_;
           if _y_+dy>MaxYResolution then dy:=MaxYResolution-_y_;
           if _x_>MaxXResolution then begin
             _x_:=0;
             dx:=Background.DimX;
             dx2:=abs(r.x1) mod dx;
             if dy2<>0 then begin
               dec(_y_,dy2);
               dy2:=0;
             end;
             inc(_y_,Background.DimY);
           end;
         end;
         asm
           MOV AX,1
           INT 33H     {mostra il mouse}
         end;
         {$ELSE}
         BitBtl(Background,VideoDC,0,0,0,0,MaxXResolution,MaxYResolution);
         {$ENDIF}
       end;
     end;





END.