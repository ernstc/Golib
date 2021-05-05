{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



{ *********************************************************************** }
{ *                                                                     * }
{ * Utility per la gestione della memoria e di buffers.                 * }
{ *                                                                     * }
{ * Modulo per la gestione di un buffer FIFO circolare di dimensione    * }
{ * massima di 65520 bytes. La gestione di questo buffer  Š simile alla * }
{ * gestione del buffer della tastiera gestito dal BIOS.                * }
{ *                                                                     * }
{ * Scritto con Turbo Pascal 7.0                                        * }
{ *                                                                     * }
{ *********************************************************************** }

{$R-}
{$S-}

UNIT MemMan;

INTERFACE

type
     TPointer = record
        offset,
        segment:word;
     end;


     OPBuffer = ^OTBuffer;
     OTBuffer = object
        BES        : word;    { Dimensione del singolo elemento immagazzinabile }
        BufferSize : word;    { Dimensione del buffer         }
        BufferPtr  : pointer; { Puntatore al buffer in cui verrano memorizzati i messaggi. }
        OfsOrigin  : word;    { Origine del buffer            }
        OfsLimit   : word;    { Limite dell'offset del buffer }
        OfsFirst   : word;    { Indice per il Message Buffer  }
        OfsLast    : word;    { Indice per il Message Buffer  }
        Elements   : word;    { Numero degli elementi presenti nel buffer }
        MaxElements: word;    { Numero massimo di elementi allocabili     }

        AccessBlocked:boolean; { Questo campo serve per bloccare l'accesso
                                 al buffer durante l'esecuzione di un metodo
                                 del gestore del buffer. Questo Š utile
                                 nel caso si colleghi una procedura ad un
                                 interrupt hardware (es. INT 1Ch) che preveda
                                 la memorizzazione periodica di dati in un
                                 buffer. }
        procedure CreateBuffer(BaseElementSize, NumElements: word);
        procedure DestroyBuffer;
        procedure Alloc(var Element);
        procedure Delete;
        procedure DeleteLast;
        procedure DeleteAll;
        function Empty:boolean;
        function Full:boolean;
        procedure VisElement(var Element);
        procedure GetElement(var Element);
        function GetElementPtr:pointer;
        function GetLastElementPtr:pointer;
        function GetBufferPtr:pointer;
        function AccessEnable:boolean;
        function ThereAreNews:boolean;
     private
        precOfsLast: word;
        NewElementPresent:boolean;
     end;


     { Ridimensiona un blocco di memoria allocato con GetMem. }
     procedure ResizeMemBlock(var p:pointer; SizeBlock,NewSize:longint);


IMPLEMENTATION


                    { ----- OTBuffer ----- }
   procedure OTBuffer.CreateBuffer(BaseElementSize, NumElements: word);
     begin
       BufferSize:=BaseElementSize*NumElements;
       GetMem(BufferPtr,BufferSize);
       OfsFirst:=TPointer(BufferPtr).Offset;
       OfsOrigin:=OfsFirst;
       OfsLimit:=OfsFirst+BufferSize;
       OfsLast:=OfsLimit;
       precOfsLast:=OfsLimit;
       BES:=BaseElementSize;
       MaxElements:=NumElements;
       Elements:=0;
       AccessBlocked:=false;
       newElementPresent:=false;
     end;


   procedure OTBuffer.DestroyBuffer;
     begin
       if (BufferPtr=nil) or AccessBlocked then exit;
       AccessBlocked:=true;
       FreeMem(BufferPtr,BufferSize);
       BufferPtr:=nil;
       Elements:=0;
     end;


   procedure OTBuffer.Alloc(var Element); assembler;
   asm
       les         di,[bp+6]
       cmp         es:[di+AccessBlocked],TRUE
       je          @Fine
       mov         es:[di+AccessBlocked],TRUE
       mov         ax,es:[di+Elements]
       cmp         ax,es:[di+MaxElements]
       je          @Fine
       { Calcolo del nuovo valore di OfsLast }
       mov         ax,es:[di+OfsLast]
       mov         es:[di+precOfsLast],ax
       add         ax,es:[di+BES]
       cmp         ax,es:[di+OfsLimit]
       jb          @Assegna
       mov         ax,es:[di+OfsOrigin]
   @Assegna:
       mov         es:[di+OfsLast],ax
       inc         es:[di+Elements]
       { Alloca }
       mov         cx,es:[di+BES]
       push        ds
       lds         si,Element
       les         di,es:[di+BufferPtr]
       mov         di,ax
       cld
       rep         movsb
       pop         ds
       les         di,[bp+6]
       mov         es:[di+newElementPresent],TRUE
       mov         es:[di+AccessBlocked],FALSE
   @Fine:
   end;


   procedure OTBuffer.Delete; assembler;
   asm
       les         di,[bp+6]
       cmp         es:[di+AccessBlocked],TRUE
       je          @Fine
       mov         es:[di+AccessBlocked],TRUE
       cmp         es:[di+Elements],0
       je          @Fine
       { Calcolo del nuovo valore di OfsFirst }
       mov         ax,es:[di+OfsFirst]
       { Calcolo del nuovo valore di OfsFirst }
       add         ax,es:[di+BES]
       cmp         ax,es:[di+OfsLimit]
       jb          @Assegna
       mov         ax,es:[di+OfsOrigin]
   @Assegna:
       mov         es:[di+OfsFirst],ax
       dec         es:[di+Elements]
       jnz         @NonVuoto
       mov         es:[di+newElementPresent],FALSE
   @NonVuoto:
       mov         es:[di+AccessBlocked],FALSE
   @Fine:
   end;


   procedure OTBuffer.DeleteLast; assembler;
   asm
       les         di,[bp+6]
       cmp         es:[di+AccessBlocked],TRUE
       je          @Fine
       mov         es:[di+AccessBlocked],TRUE
       cmp         es:[di+Elements],0
       je          @Fine
       dec         es:[di+Elements]
       mov         ax,es:[di+precOfsLast]
       mov         es:[di+OfsLast],ax
       mov         es:[di+newElementPresent],FALSE
       mov         es:[di+AccessBlocked],FALSE
   @Fine:
   end;


   procedure OTBuffer.DeleteAll;
     begin
       if AccessBlocked or (BufferPtr=nil) then exit;
       AccessBlocked:=true;
       OfsFirst:=TPointer(BufferPtr).Offset;
       OfsLast:=OfsLimit;
       precOfsLast:=OfsLimit;
       Elements:=0;
       AccessBlocked:=false;
       newElementPresent:=false;
     end;


   function OTBuffer.Empty:boolean;
     begin
       Empty:= Elements = 0;
     end;


   function OTBuffer.Full:boolean;
     begin
       Full:= Elements = MaxElements;
     end;


   procedure OTBuffer.VisElement(var Element); assembler;
   asm
       les         di,[bp+6]
       cmp         es:[di+AccessBlocked],TRUE
       je          @Fine
       mov         es:[di+AccessBlocked],TRUE
       cmp         es:[di+Elements],0
       je          @Fine
       mov         bx,es:[di+OfsFirst]
       mov         cx,es:[di+BES]
       push        ds
       lds         si,es:[di+BufferPtr]
       les         di,Element
       mov         si,bx
       cld
       rep         movsb
       pop         ds
       les         di,[bp+6]
       mov         es:[di+newElementPresent],FALSE
       mov         es:[di+AccessBlocked],FALSE
   @Fine:
   end;


   procedure OTBuffer.GetElement(var Element); assembler;
   asm
       les         di,[bp+6]
       cmp         es:[di+AccessBlocked],TRUE
       je          @Fine
       mov         es:[di+AccessBlocked],TRUE
       cmp         es:[di+Elements],0
       je          @Fine
       mov         ax,es:[di+OfsFirst]
       mov         dx,ax
       { Calcolo del nuovo valore di OfsFirst }
       add         ax,es:[di+BES]
       cmp         ax,es:[di+OfsLimit]
       jb          @Assegna
       mov         ax,es:[di+OfsOrigin]
   @Assegna:
       mov         es:[di+OfsFirst],ax
       dec         es:[di+Elements]
       mov         cx,es:[di+BES]
       push        ds
       lds         si,es:[di+BufferPtr]
       les         di,Element
       mov         si,dx
       cld
       rep         movsb
       pop         ds
       les         di,[bp+6]
       mov         es:[di+newElementPresent],FALSE
       mov         es:[di+AccessBlocked],FALSE
   @Fine:
   end;


   function OTBuffer.GetElementPtr:pointer;
     begin
       GetElementPtr:=Ptr(TPointer(BufferPtr).Segment,OfsFirst);
     end;


   function OTBuffer.GetLastElementPtr:pointer;
     begin
       GetLastElementPtr:=Ptr(TPointer(BufferPtr).Segment,OfsLast);
     end;


   function OTBuffer.GetBufferPtr:pointer;
     begin
       GetBufferPtr:=BufferPtr;
     end;


   function OTBuffer.AccessEnable:boolean;
     begin
       AccessEnable:=not AccessBlocked;
     end;


   function OTBuffer.ThereAreNews:boolean;
     begin
       ThereAreNews:=NewElementPresent;
     end;



{***************************************************************************}


type
     PSave = ^TSave;
     TSave = array[1..8] of char;

var
     RzSave:TSave;


   { Ridimensiona un blocco di memoria allocato con GetMem. }
   procedure ResizeMemBlock(var p:pointer; SizeBlock,NewSize:longint);
     var precPoint:pointer;
         lessSize:word;
         i:byte;
     begin
       if p=nil then begin
         GetMem(p,NewSize);
         exit;
       end;
       precPoint:=p;
       { Salva in RzSave }
       asm
         push      ds
         cld
         mov       ax,ds
         mov       es,ax
         lea       di,RzSave
         lds       si,p
         lds       si,DWORD PTR ds:[si]
         mov       cx,8
         rep       movsb
         pop       ds
       end;
       FreeMem(p,SizeBlock);
       GetMem(p,NewSize);
       if precPoint=p then begin
         { In questo caso Š stata utilizzata la stessa partizione per
           la rilocazione. }
         asm
           cld
           { Ripristina con RzSave }
           lea       si,RzSave
           les       di,p
           les       di,DWORD PTR es:[di]
           mov       cx,8
           rep       movsb
         end;
       end
       else begin
         { In questo caso Š stata utilizzata una partizione diversa per
           la rilocazione e quindi il blocco precedente ed il nuovo blocco
           non hanno nessun byte in comune. }
         if SizeBlock<NewSize then LessSize:=SizeBlock
                              else LessSize:=NewSize;
         asm
           add       LessSize,7
           and       LessSize,0FFF8h    { (LessSize div 8) *8 }
           cld
           { Copia la i primi 8 bytes del blocco da RzSave }
           lea       si,RzSave
           les       di,p
           les       di,DWORD PTR es:[di]
           mov       cx,8
           sub       LessSize,8
           mov       bx,cx
           rep       movsb
           cmp       LessSize,0
           je        @Fine
           { Copia il resto del blocco da precPoint }
           push      ds
           lds       si,precPoint
           add       si,bx
           mov       cx,LessSize
           rep       movsb
           pop       ds
         @Fine:
         end;
       end;
     end;


END.