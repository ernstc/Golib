{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



{*************************************************************************}
{*                                                                       *}
{*  Modulo contenente routines per la manipolazione delle immagini       *}
{*  bitmapped in modalit… grafica a 16 colori (contemporaneamente).      *}
{*                                                                       *}
{*  Scritto con Turbo Pascal 7.0 con implementazione di moduli           *}
{*  oggetto scritti in Turbo Assembler 2.0.                              *}
{*                                                                       *}
{*************************************************************************}

UNIT BitMaps;

INTERFACE


uses graph,graftool;


const ClippingForBITBTL:boolean=true;


var
     PageC:boolean;



{ Sposta un bitmapped da un Device Contex ad un'altro }
     procedure BitBtl(var FromDC,ToDC:HCA; da_x1_,da_y1_,a_x1_,a_y1_:integer; DimX,DimY:integer);
{ Come BitBtl, ma solo per spostamenti all'interno del FRAME-BUFFER. }
     procedure  BitBtlVideoDC(da_x1_,da_y1_,a_x1_,a_y1_:integer; DimX,DimY:word);
{ Partendo da un bitmap crea un'area compatibile al dispositivo video attivo.
  Se l'operazione non riesce restituisce nil.}
     function CreateCompatibleArea(var CompatibleArea:HCA; var BitMap):pointer;
{ Crea un Device Context di dimnesioni DimX e DimY. }
     procedure CreateCompatibleDC(var CA:HCA;dimX,dimY:word);
{ Distrugge un DC creato nello HEAP. }
     function DestroyDC(var DC:HCA):byte;
{ Legge un file bitmapped (.BMP formato Windows(TM)) e rilascia il
  puntatore al BMP. }
     function LoadBitmap(FileName:string; var ResourcePointer:pointer):LongInt;
{ Scarica dallo HEAP un'immagine bitmapped }
     procedure DisposeBMP(bmp:pointer);



IMPLEMENTATION

uses
    OpenFile;

   {$L BITBTLRD.OBJ}
   {$L BITBTLRI.OBJ}
   {$L BITBTLLD.OBJ}
   {$L BITBTLLI.OBJ}

   {$L SHIFTR8D.OBJ}
   {$L SHIFTR8I.OBJ}
   {$L SHIFTL8D.OBJ}
   {$L SHIFTL8I.OBJ}

   {$L CreateCA.OBJ}
   {$L CreateDC.OBJ}


   procedure  BitBtl_RD(var FromDC,ToDC:HCA; da_x1_,da_y1_,a_x1_,a_y1_:integer; DimX,DimY:word);
   external;

   procedure  BitBtl_RI(var FromDC,ToDC:HCA; da_x1_,da_y1_,a_x1_,a_y1_:integer; DimX,DimY:word);
   external;

   procedure  BitBtl_LD(var FromDC,ToDC:HCA; da_x1_,da_y1_,a_x1_,a_y1_:integer; DimX,DimY:word);
   external;

   procedure  BitBtl_LI(var FromDC,ToDC:HCA; da_x1_,da_y1_,a_x1_,a_y1_:integer; DimX,DimY:word);
   external;



{ Procedure altamente OTTIMIZZATE per i casi di TRASFERIMENTO NEL
  FRAME-BUFFER in cui si verifica la condizione (a_x1_ mod 8 =0) and
  (da_x1_ mod 8 =0).
}
   procedure  BitBtlMoveRD8(da_x1_,da_y1_,a_x1_,a_y1_, DimX,DimY:word);
   external;

   procedure  BitBtlMoveRI8(da_x1_,da_y1_,a_x1_,a_y1_, DimX,DimY:word);
   external;

   procedure  BitBtlMoveLD8(da_x1_,da_y1_,a_x1_,a_y1_, DimX,DimY:word);
   external;

   procedure  BitBtlMoveLI8(da_x1_,da_y1_,a_x1_,a_y1_, DimX,DimY:word);
   external;



{ Procedura di selezione di una delle procedure sopra dichiarate. }

   procedure  BitBtl(var FromDC,ToDC:HCA; da_x1_,da_y1_,a_x1_,a_y1_:integer; DimX,DimY:integer);
     var Shift8:boolean;
         E_DC:boolean;   {TRUE se FromDC e ToDC sono uguali.
                          Se FALSE il medoto diretto sar… sempre il preferito.}
         i:byte;
         view:ViewPortType;
         view1,view2:ViewPortType;
         da_x2_,da_y2_,
          a_x2_, a_y2_: integer;
     begin
       GetViewSettings(view);
       if not ClippingForBITBTL then SetViewPort(0,0,_MaxXResolution,_MaxYResolution,false);

       if (@FromDC<>@VideoDC) or not ClippingForBITBTL then with view1 do begin
         x1:=0;
         y1:=0;
         x2:=FromDC.DimXCA;
         y2:=FromDC.DimY;
         clip:=ClippingForBITBTL;
       end
       else view1:=view;
       if (@ToDC<>@VideoDC) or not ClippingForBITBTL then with view2 do begin
         x1:=0;
         y1:=0;
         x2:=ToDC.DimXCA;
         y2:=ToDC.DimY;
         clip:=ClippingForBITBTL;
       end
       else view2:=view;

       if a_x1_<0 then begin
         da_x1_:=da_x1_-a_x1_;
         DimX:=DimX+a_x1_;
         a_x1_:=0;
       end;

       if a_y1_<0 then begin
         da_y1_:=da_y1_-a_y1_;
         DimY:=DimY+a_y1_;
         a_y1_:=0;
       end;

       if da_x1_<0 then begin
         a_x1_:=a_x1_-da_x1_;
         DimX:=DimX+da_x1_;
         da_x1_:=0;
       end;

       if da_y1_<0 then begin
         a_y1_:=a_y1_-da_y1_;
         DimY:=DimY+da_y1_;
         da_y1_:=0;
       end;


       da_x2_:=da_x1_+DimX-1;
       da_y2_:=da_y1_+DimY-1;
        a_x2_:= a_x1_+DimX-1;
        a_y2_:= a_y1_+DimY-1;


       with view1 do SetViewPort(x1,y1,x2,y2,clip);
       if not AdjustForViewPort(da_x1_,da_y1_,da_x2_,da_y2_) then begin
         with view do SetViewPort(x1,y1,x2,y2,clip);
         exit;
       end;

       with view2 do SetViewPort(x1,y1,x2,y2,clip);
       if not AdjustForViewPort(a_x1_,a_y1_,a_x2_,a_y2_) then begin
         with view do SetViewPort(x1,y1,x2,y2,clip);
         exit;
       end;

       dimX:=a_x2_-a_x1_+1;
       if da_x2_-da_x1_+1<dimX then dimX:=da_x2_-da_x1_+1;

       dimY:=a_y2_-a_y1_+1;
       if da_y2_-da_y1_+1<dimY then dimY:=da_y2_-da_y1_+1;

       {if ClippingForBITBTL then }
         with view do SetViewPort(x1,y1,x2,y2,clip);
       {else
         SetViewPort(0,0,_MaxXResolution,_MaxYResolution,false);}

       E_DC:=true;
       for i:=0 to 3 do
         if FromDC.piano[i]<>ToDC.piano[i] then begin
           E_DC:=FALSE;
           break;
         end;

       Shift8:=((a_x1_ mod 8 =0) and (da_x1_ mod 8 =0));
       if Shift8 then
         for i:=0 to 3 do
           if (FromDC.piano[i]<>Ptr($A000,0)) or (ToDC.piano[i]<>Ptr($A000,0)) then begin
             shift8:=false;
             break;
           end;

       PageC:=false;
       for i:=0 to 3 do
         if (FromDC.piano[i]=Ptr($A000,0)) or (ToDC.piano[i]=Ptr($A000,0)) then begin
           PageC:=true;
           break;
         end;


       if ((da_x1_=a_x1_) and (da_y1_=a_y1_) and E_DC )
          or (DimY<=0)
          or (DimX<=0)
       then exit;

       { Scelta della procedura pi— adatta per lo shifting }
       inline($B8/$02/$00/$CD/$33);  {nasconde il mouse}
       if da_x1_<=a_x1_
       then if (da_y1_>=a_y1_) or not E_DC
              then if Shift8
                     then BitBtlMoveRD8(da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY)
                     else BitBtl_RD(FromDC,ToDC,da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY)
              else if Shift8
                     then BitBtlMoveRI8(da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY)
                     else BitBtl_RI(FromDC,ToDC,da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY)
       else if (da_y1_>=a_y1_) or not E_DC
              then if Shift8
                     then BitBtlMoveLD8(da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY)
                     else BitBtl_LD(FromDC,ToDC,da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY)
              else if Shift8
                     then BitBtlMoveLI8(da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY)
                     else BitBtl_LI(FromDC,ToDC,da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY);
       inline($B8/$01/$00/$CD/$33);  {mostra il mouse}
     end;



   procedure  BitBtlVideoDC(da_x1_,da_y1_,a_x1_,a_y1_:integer; DimX,DimY:word);
     var view:ViewPortType;
         da_x2_,da_y2_,
          a_x2_, a_y2_: integer;
     begin
       if ClippingForBITBTL then GetViewSettings(view);
       if a_x1_<0 then begin
         da_x1_:=da_x1_-a_x1_;
         DimX:=DimX+a_x1_;
         a_x1_:=0;
       end;
       if a_y1_<0 then begin
         da_y1_:=da_y1_-a_y1_;
         DimY:=DimY+a_y1_;
         a_y1_:=0;
       end;
       if da_x1_<0 then begin
         a_x1_:=a_x1_-da_x1_;
         DimX:=DimX+da_x1_;
         da_x1_:=0;
       end;
       if da_y1_<0 then begin
         a_y1_:=a_y1_-da_y1_;
         DimY:=DimY+da_y1_;
         da_y1_:=0;
       end;

       if ClippingForBITBTL then begin
         da_x2_:=da_x1_+DimX-1;
         da_y2_:=da_y1_+DimY-1;
          a_x2_:= a_x1_+DimX-1;
          a_y2_:= a_y1_+DimY-1;
         if not AdjustForViewPort(da_x1_,da_y1_,da_x2_,da_y2_) then begin
           with view do SetViewPort(x1,y1,x2,y2,clip);
           exit;
         end;
         if not AdjustForViewPort(a_x1_,a_y1_,a_x2_,a_y2_) then begin
           with view do SetViewPort(x1,y1,x2,y2,clip);
           exit;
         end;
         dimX:=a_x2_-a_x1_+1;
         if da_x2_-da_x1_+1<dimX then dimX:=da_x2_-da_x1_+1;
         dimY:=a_y2_-a_y1_+1;
         if da_y2_-da_y1_+1<dimY then dimY:=da_y2_-da_y1_+1;
       end;
       if ((da_x1_=a_x1_) and (da_y1_=a_y1_)) or
           (DimY<=0)                          or
           (DimX<=0)
       then exit;

       { Scelta della procedura pi— adatta per lo shifting }
       inline($B8/$02/$00/$CD/$33);  {nasconde il mouse}
       if da_x1_<=a_x1_
       then if da_y1_<a_y1_
              then if (a_x1_ mod 8 =0) and (da_x1_ mod 8 =0)
                     then BitBtlMoveRI8(da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY)
                     else BitBtl_RI (VideoDC,VideoDC,da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY)
              else if (a_x1_ mod 8 =0) and (da_x1_ mod 8 =0)
                     then BitBtlMoveRD8(da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY)
                     else BitBtl_RD (VideoDC,VideoDC,da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY)
       else if da_y1_<a_y1_
              then if (a_x1_ mod 8 =0) and (da_x1_ mod 8 =0)
                     then BitBtlMoveLI8(da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY)
                     else BitBtl_LI (VideoDC,VideoDC,da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY)
              else if (a_x1_ mod 8 =0) and (da_x1_ mod 8 =0)
                     then BitBtlMoveLD8(da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY)
                     else BitBtl_LD (VideoDC,VideoDC,da_x1_,da_y1_,a_x1_,a_y1_,DimX,DimY);
       inline($B8/$01/$00/$CD/$33);  {mostra il mouse}
     end;




   procedure GetMem(var P: Pointer; Size: Word);
     begin
       system.GetMem(P,Size);
     end;




{ Se l'operazione fallisce la funzione restituisce NIL }
   function CreateCompatibleArea(var CompatibleArea:HCA; var BitMap):pointer;
   external;


   procedure CreateCompatibleDC(var CA:HCA;dimX,dimY:word);
   external;


   function DestroyDC(var DC:HCA):byte;
     var dimSeg:longint;
         i,piani_c:byte;
     begin
       piani_c:=4;
       with DC do begin
         dimSeg:=(DimXCA div 8) * DimY;
         for i:=0 to 3 do
           if Seg(piano[i]^) <> Seg(VideoDC.piano[i]^) then begin
             dec(piani_c);
             FreeMem(piano[i],word(dimSeg));
           end;
       end;
     end;


   function LoadBitmap(FileName:string; var ResourcePointer:pointer):LongInt;
     var BitMapFile:file;
         BMPSize:longint;
         Ris:word;
     begin
       ResourcePointer:=nil;
       LoadBitMap:=0;
       if ResetFile(BitMapFile,FileName,1)<>0 then begin
         RestoreCRTMode;
         writeln('Errore BITMAPS.TPU: errore nel caricamento del file ',FileName);
         HaltApplication(LastIOResult);
       end;
       BMPSize:=FileSize(BitMapFile);
       if BMPSize>65528 then exit;
       reset(BitMapFile,BMPSize);
       GetMem(ResourcePointer,BMPSize);
       BlockRead(BitMapFile,ResourcePointer^,1,Ris);
       if Ris<>1 then exit;
       LoadBitMap:=BMPSize;
       close(BitMapFile);
     end;


   procedure DisposeBMP(bmp:pointer);
     var DimFileImage:longint;
     begin
       { N.B.: Codice inline per 80386 e successivi }
       inline(
         { Legge il contenuto di bmp }
         $C4/$7E/$06/        { LES    DI,DWORD PTR SS:[BP+6]  }

         { Carica in DimFileImage la dimensione della immagine del
           file contenuta nello HEAP }
         $66/$26/$8B/$45/$02/{ MOV    EAX,DWORD PTR ES:[DI+2]  }
         $66/$89/$46/$FC     { MOV    DWORD PTR SS:[BP-4],EAX  }
       );
       FreeMem(bmp,DimFileImage);
     end;



end.