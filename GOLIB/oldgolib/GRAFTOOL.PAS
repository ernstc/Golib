{ by ERNESTO CIANCIOTTA Productions }

{*************************************************}
{*                                               *}
{*  GrafTool                                     *}
{*                                               *}
{*  Modulo contenente una serie di tool grafici  *}
{*  che rappresentano le primitive di una        *}
{*  interfaccia tutta con look 3D.               *}
{*                                               *}
{*  Scritto con Turbo Pascal ver 7.0.            *}
{*                                               *}
{*************************************************}

{$D+}
{$L+}

UNIT GrafTool;

INTERFACE

uses
      graph;


const
      BGI_Directory:string  = 'c:\tp7\bgi\';
      Work_Directory:string = 'c:\tp7\';

      ShutDownExecuting:boolean = false;

      {Contengono l'indirizzo delle procedure che verranno eseguite
       automaticamente, rispettivamente quando viene inizializzata la
       modalit… grafica e quando viene deinizializzata.}
      GraphEntryProc:pointer=nil;
      GraphExitProc:pointer=nil;

      GOLIBProcPrefered:boolean=false;
      ColoreOmbra:word=7;
      ColoreRiflesso:word=15;

      GolibPalette:PaletteType=(
        size:16;
        colors:(0,4,2,6,1,5,3,56,7,36,50,54,9,45,27,63)
      );

      GolibPresent:boolean=false;
      GraphicModeLoaded:boolean=false;
      GraphParamControl:boolean=true;

      { Modalit… di scrittura per BarGoLIB }
      wmNormal = $00;
      wmAND    = $08;
      wmOR     = $10;
      wmXOR    = $18;
type
      { Definizione del tipo per il pattern }
      TGolibPattern = array [1..8] of byte;

const
      FullPattern: TGolibPattern =
        ($FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF);
      GranaPattern: TGolibPattern =
        ($AA,$55,$AA,$55,$AA,$55,$AA,$55);

type
      { Definizione di tipi di vettori dei quattro tipi interi.
        Questi tipi possono essere utilizzati per il typecasting. }
      PVetByte = ^TVetByte;
      TVetByte = array[0..65520] of byte;
      PVetWord = ^TVetWord;
      TVetWord = array[0..32760] of word;
      PVetLongint = ^TVetLongint;
      TVetLongint = array[0..16380] of longint;

      TProc=procedure;

      TPointer = record
         offset,
         segment:word;
      end;

      {
        HCA -> Header Compatible Area

        Contiene le informazioni necessarie per la visualizzazione
        dell'immagine.
      }
      PHCA = ^HCA;
      HCA = record
              piano:array[0..3] of pointer;
              DimXCA,  { Indica la larghezza in pixels dello schermo virtuale
                         creato nello HEAP e serve per parametrizzare la
                         procedura BitBtlMove per il successivo trasferimento
                         nel Frame-Buffer. }
              DimX,
              DimY:word;
            end;


var
   { Variabili per la risoluzione grafica attiva }
      _MaxXResolution,         { = GetMaxX   }
      _MaxYResolution,         { = GetMaxX   }
      MaxXResolution,          { = GetMaxX+1 }
      MaxYResolution:integer;  { = GetMaxX+1 }

      MaxXResByte:word;        { = MaxXResolution div 8 }

   { Pattern per la procedura BarGoLIB }
      GLBPattern: TGolibPattern;


   { Variabili per il background }
      BackGroundColor:word;

      BackGroundBar:procedure(col:byte);


      VideoDC:HCA;   { Contiene l'Header per utilizzare il Frame-Buffer come un
                        Device Context qualunque. }



{ Procedure che non rispettano la viewport corrente }
   procedure BarGoLIB(X,Y:integer; DimX,DimY:word; colore:word; WriteMode:byte);
   procedure BarGoLIBW(X,Y:integer; DimX,DimY:word; colore:word; WriteMode:byte);
{ Procedura Bar accellerata }
   procedure Bar(m1,n1,m2,n2:integer);
{ Procedura Bar per le varie modalit… di scrittura e patterns }
   procedure BarPat(m1,n1,m2,n2:integer);
{
  WriteMode pu• assumere i seguenti valori:
  0. Normal  Draw Mode
  1. XOR     Draw Mode
  2. ORFisic Draw Mode
  3. AND     Draw Mode
  4. NOT     Draw Mode
  5. ORLogic Draw Mode
}
   procedure SetWriteMode(WriteMode: Integer);
   function  GetWriteMode:integer;

   function AdjustForViewPort(var m1,n1,m2,n2:integer):boolean;

   function InizializzaGrafica(GraphMode:integer; num_col:word):boolean;
   function ChangeGraphicMode(GraphMode:integer; num_col:word):boolean;
{  procedure InizializzaGraficaMAX;}
   procedure ShutDown;

   procedure RestoreGraphMode;
   procedure EnableVideo;
   procedure DisableVideo;

   procedure SetFullPort;
   procedure FullBar(colore:word);

   procedure Rilievo3D(x1,y1,x2,y2:integer; colIn:integer);
   procedure Incavo3D(x1,y1,x2,y2:integer; colIn:integer);
   procedure _rect__(x1,y1,x2,y2:integer; c1,c2:word);
   procedure Rilievo3DSoft(x1,y1,x2,y2:integer; colIn:integer);
   procedure Incavo3DSoft(x1,y1,x2,y2:integer; colIn:integer);
   procedure Window3D(x1,y1,x2,y2:integer; colIn:integer);
   procedure Rect_In_3D(x1,y1,x2,y2:integer);
   procedure Rect_Out_3D(x1,y1,x2,y2:integer);
   procedure Line_In_3d(x1,y1,x2,y2:integer);
   procedure Line_Out_3d(x1,y1,x2,y2:integer);
   procedure Tasto(x,y:integer;dim:word; stl,col:word);

   function IntersectViewPorts(var v1,v2_Ris:ViewPortType):boolean;

{$IFDEF GerarchicViewPorts}
   { -- Procedure per il sistema di viewports gerarchico. -- }
   function NewFatherPort(m1,n1,m2,n2:integer; clp:boolean):boolean;
   procedure NewHighFatherPort(m1,n1,m2,n2:integer; clp:boolean);
   procedure SetFatherPort(m1,n1,m2,n2:integer; clp:boolean);
   function SetChildPort(m1,n1,m2,n2:integer; clp:boolean):boolean;
   procedure TransformPort(var view:ViewPortType; InViewType:boolean);
   procedure BackViewPort;
{$ENDIF}


IMPLEMENTATION

  {$L BAR.OBJ}
  {$L BAR_W.OBJ}
  {$L SVGA16.OBJ}


  type ArraySTR=array[1..1] of string;

  var  precExitProc:pointer;

  const tono=40;

        HaltSystem:boolean=true;
        InitExecuted:boolean=false;
        ShotDownExecuted:boolean=true;



{$IFDEF GerarchicViewPorts}
  type
        ListViewPort = ^TViewPort;
        TViewPort = record
                      v: ViewPortType;
                      succ,
                      prec: ListViewPort;
                      tipo: boolean;
                    end;
  const
        Father=true;
        Child=false;
  var
        { -- Variabili per il sistema di viewports gerarchico. -- }
        FirstViewPort,
        LastViewPort: ListViewPort;
        NullPort,
        FatherPort,
        ActivePort: ViewPortType;
{$ENDIF}




  var
        _WriteMode:Integer;
        { Se il bit pi— significativo del primo byte vale 1 (ossia se
          (_WriteMode and 8)<>0 ) allora verr… utilizzato il Pattern. }

        view:ViewPortType;
        fill:FillSettingsType;


   procedure BarGraphW(x1,y1,x2,y2:integer);
     var PatternIndex:byte;
         L:integer;
     begin
       GetFillSettings(fill);
       setColor(fill.color);
       if _WriteMode>127
       then begin
         PatternIndex:=1;
         for L:=y1 to y2 do begin
           SetLineStyle(UserBitln,GLBPattern[PatternIndex],1);
           Line(x1,L,x2,L);
           asm
             inc PatternIndex
             cmp PatternIndex,9
             jne @002
             mov PatternIndex,1
           @002:
           end;
         end
       end
       else begin
         SetLineStyle(UserBitln,$FFFF,1);
         for L:=y1 to y2 do Line(x1,L,x2,L);
       end;
       SetLineStyle(UserBitln,$FFFF,1);
     end;


   function AdjustForViewPort(var m1,n1,m2,n2:integer):boolean;
     begin
       GetFillSettings(fill);
       GetViewSettings(view);
       with view do begin
         inc(m1,x1);
         inc(n1,y1);
         inc(m2,x1);
         inc(n2,y1);
         if clip then begin
           if m1<x1 then m1:=x1;
           if n1<y1 then n1:=y1;
           if m2>x2 then m2:=x2;
           if n2>y2 then n2:=y2;
         end
         else begin
           if m1<0 then m1:=0;
           if n1<0 then n1:=0;
           if m2>_MaxXResolution then m2:=_MaxXResolution;
           if n2>_MaxYResolution then n2:=_MaxYResolution;
         end;
         if (m1<=m2) and (n1<=n2) then AdjustForViewPort:=true
                                  else AdjustForViewPort:=false;
       end;
     end;


   procedure BarGoLIB(X,Y:integer; DimX,DimY:word; colore:word; WriteMode:byte);
   external;


   procedure BarGoLIBW(X,Y:integer; DimX,DimY:word; colore:word; WriteMode:byte);
   external;


   procedure Bar(m1,n1,m2,n2:integer);
     var DimX,DimY:integer;
     begin
       GetFillSettings(fill);
       if fill.pattern<>1 then graph.bar(m1,n1,m2,n2)
       else if AdjustForViewPort(m1,n1,m2,n2) then begin
         DimX:=m2-m1+1;
         DimY:=n2-n1+1;
         BarGoLIB(m1,n1,DimX,DimY,fill.color,wmNormal);
       end;
     end;


   procedure BarPat(m1,n1,m2,n2:integer);
     var DimX,DimY:integer;
     begin
       if (_WriteMode and $07) in [3,5]
       then begin
         if AdjustForViewPort(m1,n1,m2,n2) then begin
           DimX:=m2-m1+1;
           DimY:=n2-n1+1;
           with fill do BarGoLIBW(m1,n1,DimX,DimY,GetColor,_WriteMode and $7);
         end
       end
       else BarGraphW(m1,n1,m2,n2);
     end;


   procedure SetWriteMode(WriteMode: Integer);
     begin
       _WriteMode:=WriteMode;
       graph.SetWriteMode(WriteMode and $07);
     end;


   function  GetWriteMode:integer;
     begin
       GetWriteMode:=_WriteMode and $07;
     end;


{$F+}
   procedure BackGroundBar_800_600_16(col:byte);
     assembler;
     asm
        mov     ax,2  { Nasconde il cursore del mouse }
        int     33h

        mov     dx,3C5h
        mov     al,col
        out     dx,al

        push    ds
        mov     ax,0A000h
        mov     es,ax
        mov     di,0
        xor     ax,ax
        cmp     col,0
        je      @001
        mov     ax,0FFFFh
     @001:
        mov     cx,30000
        rep     stosw
        mov     ax,1
        int     33h
        mov     al,col
        xor     ah,ah
        mov     BackGroundColor,ax

        mov     dx,3C5h
        mov     al,15
        out     dx,al
     end;


   procedure BackGroundBar_640_480_16(col:byte);
     assembler;
     asm
        mov     ax,2  { Nasconde il cursore del mouse }
        int     33h

        mov     dx,3C5h
        mov     al,col
        out     dx,al

        push    ds
        mov     ax,0A000h
        mov     es,ax
        mov     di,0
        xor     ax,ax
        cmp     col,0
        je      @001
        mov     ax,0FFFFh
     @001:
        mov     cx,19200
        rep     stosw
        mov     ax,1
        int     33h
        mov     al,col
        xor     ah,ah
        mov     BackGroundColor,ax

        mov     dx,3C5h
        mov     al,15
        out     dx,al
     end;
{$F-}



   procedure SuperVGA16; external;


   function InizializzaGrafica(GraphMode:integer; num_col:word):boolean;
     var GraphDriver:integer;
         j:integer;
         BGIdir:string;
     begin
       if (paramcount<>0) and GraphParamControl then begin
         if paramstr(1)='/?' then begin
           writeln('GOLIB 1.0 programmato da Ernesto CIANCIOTTA');
           writeln('  Avviamento con directory di lavoro alternative:');
           writeln('  -   Primo parametro: BGI Directory;');
           writeln('  - Secondo parametro: Directory di lavoro;');
           writeln;
           writeln('Altri parametri:');
           writeln(' x: modalit… grafica');
           writeln(' col: numero di colori');
           halt;
         end;
         BGI_Directory:=paramstr(1);
         if paramcount>=2 then Work_Directory:=paramstr(2)
                          else Work_Directory:='c:\tp7';
         if paramcount>=3 then val(paramstr(3),graphmode,j);
         if paramcount>=4 then val(paramstr(4),num_col,j);
       end;
       BGIdir:=BGI_Directory;
       if Work_Directory[length(Work_Directory)]<>'\' then Work_Directory:=Work_Directory+'\';
       { Caricamento dei driver grafici in memeoria }
       case num_col of
          16: begin
                GraphDriver:=InstallUserDriver('SVGA16',nil);
                if GraphMode=3 then BackGroundBar:=BackGroundBar_640_480_16
                               else BackGroundBar:=BackGroundBar_800_600_16;
                if RegisterBGIDriver(@SuperVGA16)<0 then begin
                  writeln(#13,'Errore GRAFTOOL.TPU:  Errore nella registrazione del driver SVGA16');
                  halt;
                end;
                BGIdir:='';
              end;
         256: GraphDriver:=InstallUserDriver('SVGA256',nil);
       32000: GraphDriver:=InstallUserDriver('SVGA32K',nil);
       else begin
           if HaltSystem then begin
             writeln(#13#10'Errore GRAFTOOL.TPU:  Numero dei colori non supportato dai driver !');
             halt;
           end
           else begin
             InizializzaGrafica:=false;
             exit;
           end;
         end;
       end;
       initgraph(GraphDriver,GraphMode,BGIdir);
       if graphResult<>grOk then begin
         if HaltSystem then begin
           writeln(#13#10'Errore GRAFTOOL.TPU: Modalit… grafica non supportata !');
           halt;
         end
         else begin
           InizializzaGrafica:=false;
           exit;
         end;
       end;
       _MaxXResolution:=getmaxx;
       _MaxYResolution:=getmaxy;
       MaxXResolution:=_MaxXResolution+1;
       MaxYResolution:=_MaxYResolution+1;

    {$IFDEF GerarchicViewPorts}
       with NullPort do begin
         x1:=0;
         y1:=0;
         x2:=MaxXResolution-1;
         y2:=MaxYResolution-1;
         clip:=false;
       end;
       FatherPort:=NullPort;
       ActivePort:=NullPort;
    {$ENDIF}

       { Inizializzazione a valori di default }
       SetRGBPalette(56,27,27,27);
       SetRGBPalette(7,48,48,48);

       with VideoDC do begin
         DimXCA:=MaxXResolution;
         DimX:=MaxXResolution;
         DimY:=MaxYResolution;
       end;

       { Setta i registri dell'Attribute controller per impostare i colori }
       if InitExecuted then if GraphExitProc<>nil then TProc(GraphExitProc);
       if GraphEntryProc<>nil then TProc(GraphEntryProc);
       if GolibPresent then SetAllPalette(GolibPalette);
       InitExecuted:=true;
       precExitProc:=ExitProc;
       ExitProc:=@shutdown;
       ShotDownExecuted:=false;
       GraphicModeLoaded:=true;
       InizializzaGrafica:=true;

       SetRGBPalette(4,40, 0,18);
       SetRGBPalette(2, 0,tono, 0);
       SetRGBPalette(6,tono,tono, 0);
       SetRGBPalette(1, 0, 0,tono);
       SetRGBPalette(5,tono, 0,tono);
       SetRGBPalette(3, 0,tono,tono);

       SetRGBPalette(56,32,32,32);
       SetRGBPalette(7,48,48,48);
       SetRGBPalette(36,63, 0, 0);
       SetRGBPalette(50, 0,63, 0);
       SetRGBPalette(54,63,63, 0);
       SetRGBPalette(9, 0, 0,63);
       SetRGBPalette(45,63, 0,63);
       SetRGBPalette(27, 0,63,63);
       SetRGBPalette(63,63,63,63);
     end;


   function ChangeGraphicMode(GraphMode:integer; num_col:word):boolean;
     begin
       if not InitExecuted then ChangeGraphicMode:=false
       else begin
       end;
     end;

{
   procedure InizializzaGraficaMAX;
     const colori:array[1..3] of word = (16,256,32000);
     var i,j:integer;
     begin
       clrscr;
       HaltSystem:=false;
       for j:=5 downto 0 do
         for i:=3 downto 1 do
           if InizializzaGrafica(j,colori[i]) then begin
             HaltSystem:=true;
             exit;
           end
           else closegraph;
       writeln(#13'Errore GRAFTOOL.TPU: Impossibile inizializzare la grafica !');
       halt;
     end;
}

   procedure ShutDown;
     begin
       if ShotDownExecuted then exit;
       ShutDownExecuting:=true;
       if GraphExitProc<>nil then TProc(GraphExitProc);
       { Scaricamento dei driver grafici dalla memoria }
       if precExitProc<>nil then TProc(precExitProc);
       closegraph;
       ShotDownExecuted:=true;
       GraphicModeLoaded:=false;
       Halt(0);
     end;


   procedure RestoreGraphMode;
     begin
       SetGraphMode(GetGraphMode);
       SetRGBPalette(56,27,27,27);
       SetRGBPalette(7,48,48,48);
       if GolibPresent then SetAllPalette(GolibPalette);
       SetRGBPalette(4,40, 0,18);
       SetRGBPalette(2, 0,tono, 0);
       SetRGBPalette(6,tono,tono, 0);
       SetRGBPalette(1, 0, 0,tono);
       SetRGBPalette(5,tono, 0,tono);
       SetRGBPalette(3, 0,tono,tono);

       SetRGBPalette(56,32,32,32);
       SetRGBPalette(7,48,48,48);
       SetRGBPalette(36,63, 0, 0);
       SetRGBPalette(50, 0,63, 0);
       SetRGBPalette(54,63,63, 0);
       SetRGBPalette(9, 0, 0,63);
       SetRGBPalette(45,63, 0,63);
       SetRGBPalette(27, 0,63,63);
       SetRGBPalette(63,63,63,63);
     end;


   procedure EnableVideo; assembler;
     asm
       { Attiva il refresh della memoria video }
       MOV AH,12H
       MOV BL,36H
       MOV AL,0
       INT 10H
     end;


   procedure DisableVideo; assembler;
     asm
       { Disattiva il refresh della memoria video }
       MOV AH,12H
       MOV bl,36H
       MOV AL,1
       INT 10H
     end;


   procedure SetFullPort;
     begin
       SetViewPort(0,0,getmaxx,getmaxy,false);
     end;


   procedure FullBar(colore:word);
     var DimX:word;
     begin
       setfillstyle(1,colore);
       bar(0,0,getmaxx,getmaxy);
     end;


   procedure Rilievo3D(x1,y1,x2,y2:integer; colIn:integer);
     begin
       if colIn>-1 then begin
         SetFillStyle(1,colIn);
         bar(x1+1,y1+1,x2-1,y2-1);
       end;
       setcolor(15);  line(x1,y1,x1,y2);
                      line(x1,y1,x2,y1);
       setcolor(0);   line(x1,y2,x2,y2);
                      line(x2,y2,x2,y1);
       setcolor(7);   line(x1+1,y2-1,x2-1,y2-1);
                      line(x2-1,y2,x2-1,y1+1);
     end;


   procedure Incavo3D(x1,y1,x2,y2:integer; colIn:integer);
     begin
       if colIn>-1 then begin
         SetFillStyle(1,colIn);
         bar(x1+2,y1+2,x2-2,y2-2);
       end;
       setcolor(0);   line(x1+1,y1+1,x1+1,y2-1);
                      line(x1+1,y1+1,x2-1,y1+1);
       setcolor(15);  line(x1+1,y2,x2,y2);
                      line(x2,y2,x2,y1+1);
       setcolor(7);   line(x1,y1,x1,y2);
                      line(x1,y1,x2,y1);
       setcolor(8);   line(x1+2,y2-1,x2-1,y2-1);
                      line(x2-1,y2-1,x2-1,y1+2);
     end;


   procedure _rect__(x1,y1,x2,y2:integer; c1,c2:word);
     begin
       setcolor(C1);   line(x1,y1,x1,y2);
                       line(x1,y1,x2,y1);
       setcolor(C2);  line(x1+1,y2,x2,y2);
                      line(x2,y2,x2,y1+1);
     end;


   procedure Rilievo3DSoft(x1,y1,x2,y2:integer; colIn:integer);
     begin
       if colIn>-1 then begin
         SetFillStyle(1,colIn);
         bar(x1+1,y1+1,x2-1,y2-1);
       end;
       _rect__(x1,y1,x2,y2,coloreRiflesso,coloreOmbra);
     end;


   procedure Incavo3DSoft(x1,y1,x2,y2:integer; colIn:integer);
     begin
       if colIn>-1 then begin
         SetFillStyle(1,colIn);
         bar(x1+1,y1+1,x2-1,y2-1);
       end;
       _rect__(x1,y1,x2,y2,coloreOmbra,coloreRiflesso);
     end;


   procedure Window3D(x1,y1,x2,y2:integer; colIn:integer);
     begin
       setfillstyle(1,colIn);
       bar(x1+2,y1+2,x2-2,y2-2);
       setcolor(8);   line(x1,y1,x1,y2-1);
                      line(x1,y1,x2-1,y1);
       setcolor(15);  line(x1+1,y1+1,x1+1,y2-2);
                      line(x1+1,y1+1,x2-2,y1+1);
       setcolor(7);   line(x1+1,y2-1,x2-1,y2-1);
                      line(x2-1,y2-1,x2-1,y1+1);
       setcolor(0);   line(x1,y2,x2,y2);
                      line(x2,y2,x2,y1);
     end;


   procedure Rect_In_3D(x1,y1,x2,y2:integer);
     begin
       setcolor(7);
         line(x1,y1,x1,y2);
         line(x1,y1,x2,y1);
         line(x2-1,y2-1,x1+1,y2-1);
         line(x2-1,y2-1,x2-1,y1+1);
       setcolor(15);
         line(x1+1,y1+1,x2-1,y1+1);
         line(x1+1,y1+1,x1+1,y2-1);
         line(x2,y2,x1+1,y2);
         line(x2,y2,x2,y1+1);
     end;


   procedure Rect_Out_3D(x1,y1,x2,y2:integer);
     begin
       setcolor(15);
         line(x1,y1,x1,y2);
         line(x1,y1,x2,y1);
         line(x2-1,y2-1,x1+1,y2-1);
         line(x2-1,y2-1,x2-1,y1+1);
       setcolor(7);
         line(x1+1,y1+1,x2-1,y1+1);
         line(x1+1,y1+1,x1+1,y2-1);
         line(x2,y2,x1+1,y2);
         line(x2,y2,x2,y1+1);
     end;


   procedure line_in_3d;
     begin
       setcolor(7);
       line(x1,y1,x2,y2);
       setcolor(15);
       line(x1+1,y1+1,x2+1,y2+1);
     end;


   procedure line_out_3d;
     begin
       setcolor(15);
       line(x1,y1,x2,y2);
       setcolor(7);
       line(x1+1,y1+1,x2+1,y2+1);
     end;


   procedure Tasto(x,y:integer;dim:word; stl,col:word);
     var x2,y2:integer;
     begin
       x2:=x+dim-1;
       y2:=y+dim-1;
       setcolor(15);
         moveTo(x,y2-1);
         lineTo(x,y);
         lineTo(x2-1,y);
       setcolor(0);
         moveTo(x2,y);
         lineTo(x2,y2);
         lineTo(x,y2);
       setcolor(7);
         moveTo(x+1,y2-1);
         lineTo(x2-1,y2-1);
         lineTo(x2-1,y+1);
       setfillstyle(stl,col);
       bar(x+1,y+1,x2-2,y2-2);
     end;


  function IntersectViewPorts(var v1,v2_Ris:ViewPortType):boolean;
    begin
      with v1 do begin
        if x1>=v2_Ris.x1 then v2_Ris.x1:=x1;
        if y1>=v2_Ris.y1 then v2_Ris.y1:=y1;
        if x2<v2_Ris.x2 then v2_Ris.x2:=x2;
        if y2<v2_Ris.y2 then v2_Ris.y2:=y2;
      end;
      with v2_Ris do
        if (x2<x1) or (y2<y1) then IntersectViewPorts:=false
                              else IntersectViewPorts:=true;
    end;


{$IFDEF GerarchicViewPorts}
  function AdjustCoord(var m1,n1,m2,n2:integer; condition:boolean):boolean;
    begin
      if m1<0 then m1:=0;
      if n1<0 then n1:=0;
      if m2>(MaxXResolution-1) then m2:=(MaxXResolution-1);
      if n2>(MaxYResolution-1) then n2:=(MaxYResolution-1);
      if condition and (
         ((m1>FatherPort.x2) and (n1>FatherPort.y2)) or
         ((m1>FatherPort.x2) and (n2<FatherPort.y1)) or
         ((m2<FatherPort.x1) and (n2<FatherPort.y1)) or
         ((m2<FatherPort.x1) and (n1>FatherPort.y2))
         )
      then begin
        AdjustCoord:=False;
        m2:=m1;
        n2:=n1;
      end
      else AdjustCoord:=true;
    end;


  procedure NewElementAtList(condition:boolean);
    begin
      if FirstViewPort=nil then begin
        new(FirstViewPort);
        LastViewPort:=FirstViewPort;
        LastViewPort^.prec:=nil;
        LastViewPort^.succ:=nil;
      end
      else
        if LastViewPort^.tipo or condition then begin
          new(LastViewPort^.succ);
          LastViewPort^.succ^.prec:=LastViewPort;
          LastViewPort:=LastViewPort^.succ;
          LastViewPort^.succ:=nil;
        end
    end;


  const swicth:boolean=true;  { come i ponticelli delle schede elettroniche }


  function NewFatherPort(m1,n1,m2,n2:integer; clp:boolean):boolean;
    var buf:boolean;
    begin
      buf:=AdjustCoord(m1,n1,m2,n2,true);
      NewFatherPort:=buf;
      if not buf then begin
        swicth:=false;
        SetChildPort(m1,n1,m1,n1,clp);
        swicth:=true;
        exit;
      end;
      if swicth then NewElementAtList(false);
      with LastViewPort^.v do begin
        x1:=m1+FatherPort.x1;
        y1:=n1+FatherPort.y1;
        if FatherPort.x2-FatherPort.x1+1>m2 then x2:=m2
                                            else x2:=FatherPort.x2-FatherPort.x1+1;
        if FatherPort.y2-FatherPort.y1+1>n2 then y2:=n2
                                            else y2:=FatherPort.y2-FatherPort.y1+1;
        clip:=clp;
      end;
      LastViewPort^.tipo:=Father;
      FatherPort:=LastViewPort^.v;
      ActivePort:=FatherPort;
      with ActivePort do setViewPort(x1,y1,x2,y2,clip);
    end;


  procedure NewHighFatherPort(m1,n1,m2,n2:integer; clp:boolean);
    begin
      AdjustCoord(m1,n1,m2,n2,false);
      NewElementAtList(true);
      with LastViewPort^.v do begin
        x1:=m1;
        y1:=n1;
        x2:=m2;
        y2:=n2;
        clip:=clp;
      end;
      LastViewPort^.tipo:=Father;
      FatherPort:=LastViewPort^.v;
      ActivePort:=FatherPort;
      with ActivePort do setViewPort(x1,y1,x2,y2,clip);
    end;


  procedure SetFatherPort(m1,n1,m2,n2:integer; clp:boolean);
    begin
      swicth:=false;
      if LastViewPort^.prec<>nil then FatherPort:=LastViewPort^.prec^.v
                                 else FatherPort:=NullPort;
      NewFatherPort(m1,n1,m2,n2,clp);
      swicth:=true;
    end;


  function SetChildPort(m1,n1,m2,n2:integer; clp:boolean):boolean;
    begin
      if swicth then SetChildPort:=AdjustCoord(m1,n1,m2,n2,true);
      if LastViewPort=nil then begin
        NewElementAtList(true);
        with LastViewPort^.v do begin
          x1:=m1;
          y1:=n1;
          x2:=m2;
          y2:=n2;
        end;
      end
      else begin
        if LastViewPort^.tipo then NewElementAtList(true);
        with LastViewPort^.v do begin
          x1:=m1+FatherPort.x1;
          y1:=n1+FatherPort.y1;
          if FatherPort.x2-FatherPort.x1+1>m2 then x2:=m2
                                              else x2:=FatherPort.x2-FatherPort.x1+1;
          if FatherPort.y2-FatherPort.y1+1>n2 then y2:=n2
                                              else y2:=FatherPort.y2-FatherPort.y1+1;
        end;
      end;
      LastViewPort^.v.clip:=clp;
      LastViewPort^.tipo:=Child;
      ActivePort:=LastViewPort^.v;
      with ActivePort do setViewPort(x1,y1,x2,y2,clip);
    end;


  procedure TransformPort(var view:ViewPortType; InViewType:boolean);
    begin
    end;


  procedure BackViewPort;
    begin
      if LastViewPort^.prec=nil then begin
        dispose(LastViewPort);
        LastViewPort:=nil;
        FirstViewPort:=nil;
        FatherPort:=NullPort;
        SetViewPort(0,0,MaxXResolution-1,MaxYResolution-1,true);
        exit;
      end;
      LastViewPort:=LastViewPort^.prec;
      if LastViewPort^.succ^.tipo then FatherPort:=LastViewPort^.v;
      dispose(LastViewPort^.succ);
      LastViewPort^.succ:=nil;
      ActivePort:=LastViewPort^.v;
      with ActivePort do setViewPort(x1,y1,x2,y2,clip);
    end;
{$ENDIF}



BEGIN

  with VideoDC do begin
    piano[0]:=ptr($A000,0);
    piano[1]:=ptr($A000,0);
    piano[2]:=ptr($A000,0);
    piano[3]:=ptr($A000,0);
  end;

{$IFDEF GerarchicViewPorts}
  FirstViewPort:=nil;
  LastViewPort:=nil;
{$ENDIF}

END.