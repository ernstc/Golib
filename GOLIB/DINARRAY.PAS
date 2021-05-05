unit DinArray;

   {*******************************************************}
   {*                                                     *}
   {*        DinArray => Dinamic Array                    *}
   {*                                                     *}
   {* by ERNESTO CIANCIOTTA                               *}
   {*                                                     *}
   {*   N.B. :   Modulo per Turbo Pascal ver 7.0          *}
   {*                                                     *}
   {*******************************************************}

interface
  {$R-,V-,X+}

  const StringaFalsa='$1$2$3$4$5$6$7$8$9$0';
  type
     OrdinalConvertType=record
                          case byte of
                          0:(l:longint);
                          1:(w1,w2:byte);
                          2:(b1,b2,b3,b4:byte);
                        end;

     PArrayByte=^TArrayByte;
     TArrayByte=array[1..1] of byte;

     ArrayAstratto = object
     private
        MaxDim:word;
        ArrayOrdinato:boolean;
     public
        function ArrayInOrdine:boolean;
        function OttieniMaxDim:word;
        function OttieniDimLavoro:word; virtual;
        function Memorizza(var info; indice:word):boolean; virtual;
        function Richiama(indice:word; var info):longint; virtual;
        procedure FastMem(var info; indice:word); virtual;
        function FastGet(indice:word; var info):byte; virtual;
 {      procedure Ordina;
        function Ricerca(var info):word;
     private
        procedure QSort(sinistra,destra:word);
        function RicercaSequenziale(var info):word;
        function RicercaBinaria(var info):word;   }
     end;

     ArrayGenerico = object (ArrayAstratto)
        PuntaDati:PArrayByte;
     private
        Alfa, RealDim, DimLavoro, DimUnita:word;
        generico, destinazione:PArrayByte;
        function IndirizzoOf(indice:word):pointer;
     public

        { Il parametro "HeapPos" permette di indirizzare direttamente
          il controllo su una sezione dello HEAP indicata dal
          programmatore.
          Per evitare un indirizzamento guidato dal programmatore basta
          assegnare "nil" a questo parametro e provveder… la procedura
          ad allocare nuovo spazio nello HEAP. }

        constructor Init(MaxDimArray, DimUnitaria:word; HeapPos:pointer);
        destructor Done;
        function OttieniDimLavoro:word; virtual;
        function Memorizza(var info; indice:word):boolean; virtual;
        function Richiama(indice:word; var info):longint; virtual;
        procedure FastMem(var info; indice:word); virtual;
        function FastGet(indice:word; var info):byte; virtual;
     end;

     MVArrayGenerico = object (ArrayAstratto)
     private
        MVFile:file;
        posFile:word;
     public
        constructor Init(MVNomeFile:string; DimUnita:word);
        destructor Done;
        function Memorizza(var info; indice:word):boolean; virtual;
        function Richiama(indice:word; var info):longint; virtual;
        procedure FastMem(var info; indice:word); virtual;
        function FastGet(indice:word; var info):byte; virtual;
     end;

     ArrayByte = object (ArrayGenerico)
        constructor Init(MaxDimArray:word; HeapPos:pointer);
        procedure FastMem(var info; indice:word); virtual;
     end;

     MVArrayByte = object (MVArrayGenerico)
        constructor Init(MVNomeFile:string);
     end;


implementation

  {****************** Oggetto - ArrayAstratto - *************************}
  function ArrayAstratto.ArrayInOrdine;
    begin
      ArrayInOrdine:=ArrayOrdinato;
    end;

  function ArrayAstratto.OttieniMaxDim:word;
    begin
      OttieniMaxDim:=MaxDim;
    end;

  function ArrayAstratto.OttieniDimLavoro:word;
    begin
      OttieniDimLavoro:=MaxDim;
    end;

  function ArrayAstratto.Memorizza;
    begin
      Memorizza:=false;
    end;

  function ArrayAstratto.Richiama;
    begin
      Richiama:=0;
    end;

  procedure ArrayAstratto.FastMem;
    begin
    end;

  function ArrayAstratto.FastGet;
    begin
      FastGet:=0;
    end;
 {
  procedure ArrayAstratto.Ordina;
    begin
      Qsort(1,OttieniDimLavoro);
      ArrayOrdinato:=true;
    end;

  procedure ArrayAstratto.QSort(sinistra,destra:word);
    var i,j:word;
        x,w:string;
    begin
      i:=sinistra;
      j:=destra;
      x:=Richiama((i+j) div 2);
      repeat
        while Richiama(i)<x do inc(i);
        while x<Richiama(j) do dec(j);
        if i<=j then begin
          w:=Richiama(i);     FastMem(Richiama(j),i);
          FastMem(w,j);     inc(i);  dec(j);
        end;
      until i>j;
      if sinistra<j then QSort(sinistra,j);
      if i<destra then QSort(i,destra);
    end;

  function ArrayAstratto.Ricerca(chiave:string):word;
    begin
      if ArrayOrdinato then Ricerca:=RicercaBinaria(chiave)
                       else Ricerca:=RicercaSequenziale(chiave);
    end;

  function ArrayAstratto.RicercaSequenziale(chiave:string):word;
    var i:word;
        NonTrovato:boolean;
    begin
      i:=1;
      NonTrovato:=true;
      while NonTrovato and (i<=OttieniDimLavoro) do
        if Richiama(i)<>chiave then inc(i)
                               else NonTrovato:=false;
      if NonTrovato then RicercaSequenziale:=0
                    else RicercaSequenziale:=i;
    end;

  function ArrayAstratto.RicercaBinaria(chiave:string):word;
    var inf,sup,med:word;
        s:string;
    begin
      inf:=1;
      sup:=OttieniDimLavoro;
      repeat
        med:=(inf+sup) div 2;
        s:=Richiama(med);
        if chiave<s then sup:=med-1
                    else inf:=med+1;
      until (chiave=s) or (inf>sup);
      if chiave=s then RicercaBinaria:=med
                  else RicercaBinaria:=0;
    end;


  {***************** Oggetto - ArrayGenerico - **************************}
  constructor ArrayGenerico.Init;
    begin
      MaxDim:=MaxDimArray;
      DimUnita:=DimUnitaria;
      RealDim:=MaxDim * DimUnita;
      DimLavoro:=0;
      Alfa:=DimUnita-1;
      ArrayOrdinato:=false;
      if HeapPos=nil then GetMem(PuntaDati, RealDim)
                     else PuntaDati:=HeapPos;
    end;

  destructor ArrayGenerico.Done;
    begin
      FreeMem(PuntaDati, RealDim);
    end;

  function ArrayGenerico.OttieniDimLavoro:word;
    begin
      OttieniDimLavoro:=DimLavoro;
    end;

  function ArrayGenerico.Memorizza;
    var i,j:word;
    begin
      if (indice>0) and (indice<=MaxDim) then begin
        generico:=@info;
        j:=indice*dimUnita-dimUnita;
        for i:=1 to dimUnita do PuntaDati^[i+j]:=generico^[i];
        if indice>DimLavoro then DimLavoro:=indice;
        memorizza:=true;
      end
      else memorizza:=false;
    end;

  function ArrayGenerico.Richiama;
    var i,j:word;
        ris:longint absolute info;
    begin
      if (indice>0) and (indice<=MaxDim) then begin
        generico:=@info;
        j:=indice*dimUnita-dimUnita;
        for i:=1 to dimUnita do generico^[i]:=PuntaDati^[i+j];
        Richiama:=ris;
      end
      else Richiama:=0;
    end;

  procedure ArrayGenerico.FastMem;
    var i,j:word;
    begin
      generico:=@info;
      j:=indice*dimUnita-dimUnita;
      for i:=1 to dimUnita do PuntaDati^[i+j]:=generico^[i];
      if indice>DimLavoro then DimLavoro:=indice;
    end;

  function ArrayGenerico.FastGet;
    var i,j:word;
    begin
      generico:=@info;
      j:=indice*dimUnita-dimUnita;
      for i:=1 to dimUnita do generico^[i]:=PuntaDati^[i+j];
      FastGet:=generico^[1];
    end;

  function ArrayGenerico.IndirizzoOf;
    begin
      IndirizzoOf:=@PuntaDati^[indice*dimUnita-Alfa];
    end;

  {******************** Oggetto - MVArrayGenerico - *********************}
  constructor MVArrayGenerico.Init;
    begin
      MaxDim:=0;
      posfile:=0;
      assign(MVFile,MVNomeFile);
      rewrite(MVFile,DimUnita);
    end;

  destructor MVArrayGenerico.Done;
    begin
      close(MVFile);
      erase(MVFile);
    end;

  function MVArrayGenerico.Memorizza;
    var i:word;
    begin
      if indice>0 then begin
        if indice<>posfile then begin
          posfile:=indice;
          if indice>MaxDim then begin
            seek(MVFile,MaxDim-1);
            for i:=MaxDim to indice-1 do seek(MVFile,i);
            MaxDim:=indice;
          end
          else seek(MVFile,indice-1);
        end;
        BlockWrite(MVFile,info,1,i);
        if i=1 then memorizza:=true else memorizza:=false;
      end
      else memorizza:=false;
    end;

  function MVArrayGenerico.Richiama;
    var i:word;
        ris:longint absolute info;
    begin
      if (indice>0) and (indice<=MaxDim) then begin
        if posfile<>indice then begin
          seek(MVFile,indice-1);
          posfile:=indice;
        end;
        BlockRead(MVFile,info,1,i);
        if i=1 then Richiama:=ris else Richiama:=0;
      end
      else Richiama:=0;
    end;

  procedure MVArrayGenerico.FastMem;
    begin
      seek(MVFile,indice-1);
      BlockWrite(MVFile,info,1);
      posfile:=indice;
    end;

  function MVArrayGenerico.FastGet;
    var ris:byte absolute info;
    begin
      seek(MVFile,indice-1);
      BlockRead(MVFile,info,1);
      posfile:=indice;
      Fastget:=ris;
    end;

  {********************* Oggetto - ArrayByte - **************************}
  constructor ArrayByte.Init;
    begin
      ArrayGenerico.Init(MaxDimArray,1,HeapPos);
    end;

  procedure ArrayByte.FastMem;
    begin
      generico:=@info;
      PuntaDati^[indice]:=generico^[1];
    end;

  {******************* Oggetto - MVArrayByte - **************************}
  constructor MVArrayByte.Init;
    begin
      MVArrayGenerico.Init(MVNomeFile,1);
    end;

end.

   {**************** Fine del Modulo - DinArray - *******************}


