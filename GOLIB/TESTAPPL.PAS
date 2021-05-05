{by Ernesto CIANCIOTTA Productions }


{ Programma per testare le procedure per la gestione delle applicazioni
  GOLIB.

  In questo programma la procedura "AppController" non viene collegata
  all'interrupt hardware 1Ch, ma viene eseguita ripetutamente in un ciclo
  while.

  Quando i test saranno finiti, allora verra collegata all'interrupt 1Ch.
}

{$DEFINE interrupt }

program Test_AppController;

uses
     crt,
     dos,
     mouse,
     graph,
     graftool,
     fonts,
     bitmaps,
     g_utile
     ;


type
     TProc = procedure;

     { Tipi di Eventi }
     TEvent = (EvNothing,EvKeyBoard,EvMouse);

     { Struttura degli eventi nel rispettivo buffer }
     PEventInBuf = ^TEventInBuf;
     TEventInBuf = record
        Event: TEvent;
        { Informazioni sull'evento }
        case TEvent of
          EvKeyboard: ( KeyComb: word;
                        Reserved1, Reserved2,        { Queste varibili riservate servono per fare }
                        Reserved3, Reserved4: byte;  { in modo che Shits occupi l'ottavo byte.    }
                        Shifts: byte);
          EvMouse:    ( mcx,mcy: word;
                        Button,Clicks: byte;
                        { Bits di "Button":
                          - I primi 2 bits indicano il numero del bottone che Š
                            stato toccato.
                          - L'ultimo bit indica se il bottone Š stato premuto o
                            rilasciato (1=premuto/0=rilasciato).
                        }
                        { Byte di allineamento affinchŠ la struttura abbia dimensione
                          8. }
                        AlignByte:byte;
                      );
     end;


const
      btLMask = $0001;
      btRMask = $0002;
      btCMask = $0004;
      btLMask2 = $0008;
      btRMask2 = $0010;
      btCMask2 = $0020;


var
    { Contatori di informazioni sul ritardo di eventi da parte degli
      INPUT DEVICE }
    IDevDelayC,     { General Input Device Delay Counter }
    KBDelayC,       { Keyboard Device Delay Counter }
    MMDelayC,       { Mouse Device Movement Delay Counter }
    MBDelayC: word; { Mouse Device Buttons Delay Counter }


const
      EvBufferSize = 2048;
      MaxNumEvents = EvBufferSize div 8;

var
    { Puntatore al buffer in cui verrano memorizzati gli eventi. }
    EvBuffer:pointer;
    { Indici per l'Event Buffer }
    NumEvents   : word;
    IndexFirstEv: word;
    IndexLastEv : word;
    BufferOfsLimit: word;  { Limite dell'offset del buffer }
    BufferOrigin: word;    { Origine del buffer            }
    { Ultimo evento che si Š verificato }
    LastEv: TEventInBuf;
    { Quando si verifica un evento allora l'AppController non deve fare altro
      che compilare LastEv e chiamare AllocEvent per memorizzare l'evento nel
      buffer.
    }





    { N.B.:
            Nel buffer verranno memorizzati al massimo
            (EvBufferSize/8) eventi.
    }




var
    MultipleMClickDelay: word;   { numero di ritardi del INT 1Ch }


    IntF3,

    Int1C, Int09: procedure;


    { variabili relative di controllo di MouseEventController }
    precBtnStatus:word;
    precMCX,precMCY:word;



const
    { I primi 3 bits indicano se Š in corso il periodo di tempo in cui si pu•
      verificare un MULTI-PRESS del relativo bottone.
      Gli ultimi 3 bits indicano se Š in corso il periodo di tempo in cui si pu•
      verificare un MULTI-RELEASE del relativo bottone.

              ÚÄÄÄÄÄÄÄÄÄÄÄ¿ÄÄÄÄÄÄÄÄÄÄÄ¿
              ³ M-RELEASE ³  M-PRESS  ³
      ÉÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍ»
      º \ ³ \ ³ C ³ R ³ L ³ C ³ R ³ L º
      ÈÍÍÍÏÍÍÍÏÍÍÍÏÍÍÍÏÍÍÍÏÍÍÍÏÍÍÍÏÍÍÍ¼


      Se il relativo bit Š 1 allora il periodo e in corso.

      Se il periodo non Š in corso, allora esso inizia non appena il rispettivo
      bottone viene premuto o rilasciato a seconda che si considerino i primi o
      gli ultimi bits.

      Tale periodo termina quando il contatore del periodo assume valore
      maggiore a MultipleMClickDelay.
    }
    DelayActive: byte = 0;

    { Contatori per il controllo dell'intervallo di tempo in cui  si pu•
      verificare un click multiplo dei bottoni del mouse.
      I contatori sono differenti per i vari tasti del mouse e per il tipo
      di click (pressione o rilascio del bottone).
      Questi vengono sempre incrementati da "AppController", ma successivamente
      resettati da "MouseEventController" se non Š in corso il periodo di
      clicking multiplo del relativo bottone.

      Se il periodo Š in corso allora il contatore viene incrementato fino a
      quando non Š maggiore a MultipleMClickDelay. Quando questo si verifica
      il periodo viene interrotto.
    }

    PressDelayL: word = 0;  { Left   }
    PressDelayR: word = 0;  { Right  }        {*****************************}
    PressDelayC: word = 0;  { Center }        {**   Non modificare il     **}
                                              {*    tipo e l'ordine di     *}
    ReleaseDelayL: word = 0;  { Left   }      {**   queste variabili      **}
    ReleaseDelayR: word = 0;  { Right  }      {*****************************}
    ReleaseDelayC: word = 0;  { Center }

    { Questo vettore memorizza il numero delle pressioni e dei rilasci dei
      bottoni che si verificano durante il periodo di tempo in cui tale evento
      pu• verificarsi.

      I primi 3 bytes si riferiscono alla pressione, mentre gli ultimi 3 bytes
      si riferiscono al rilascio.

      Quando un tasto viene premuto, se il relativo periodo di multi-clicking
      non Š in corso, allora esso viene attivato e il numero dei clicks settato
      a 1.
      Se il relativo periodo di multi-clicking Š in corso allora il numero dei
      clicks viene incrementato.

      Quando il periodo di multiclicking viene interrotto allora il relativo
      bitInfo deve essere settato a 0.
    }
                                   {ÚÄÄÄÄÄÄÄÄÄÄÄ¿ÄÄÄÄÄÄÄÄÄÄÄ¿}
                                   {³PRESS INFO ³RELEASE INF³}
    btnInfo: array [1..6] of byte = ( 0 , 0 , 0 , 0 , 0 , 0 );
                                   {  L , R , C , L , R , C  }


const riga:integer=0;


{ Procedure per la gestione dell' Event Buffer }


   procedure CreateEvBuffer;
     begin
       GetMem(EvBuffer,EvBufferSize);
       IndexFirstEv:=TPointer(EvBuffer).Offset;
       BufferOrigin:=IndexFirstEv;
       BufferOfsLimit:=IndexFirstEv+EvBufferSize;
       IndexLastEv:=BufferOfsLimit;
       NumEvents:=0;
       { Reset di LastEv }
       asm
         cld
         push     ds
         pop      es
         lea      di,LastEv
         xor      ax,ax
         mov      cx,4
         rep      stosw
       end;
     end;


   procedure DestroyEvBuffer;
     begin
       if EvBuffer=nil then exit;
       FreeMem(EvBuffer,EvBufferSize);
       EvBuffer:=nil;
     end;


   procedure DeleteAllEvents;
     begin
       if EvBuffer=nil then exit;
       IndexFirstEv:=TPointer(EvBuffer).Segment;
       IndexLastEv:=BufferOfsLimit;
       NumEvents:=0;
       precMCX:=0;
       precMCY:=0;
       precBtnStatus:=0;
     end;


   function EventPresent:boolean;
     begin
       EventPresent:= NumEvents<>0;
     end;


   { Copia in Event il primo evento in lista e lo cancella dal buffer }
   function GetNextEvent(var Event:TEventInBuf):TEvent; assembler;
   asm
       mov         al,EvNothing
       cmp         NumEvents,0
       je          @Fine
       cld
       mov         bx,IndexFirstEv
       push        ds
       les         di,Event
       lds         si,EvBuffer
       mov         si,bx
       mov         al,BYTE PTR ds:[si]
       mov         cx,4
       rep         movsw
       pop         ds
       { Calcolo del nuovo valore di IndexFirstEv }
       add         bx,8
       cmp         bx,BufferOfsLimit
       jne         @Assegna
       mov         bx,BufferOrigin
   @Assegna:
       mov         IndexFirstEv,bx
       dec         NumEvents
   @Fine:
   end;


   { Copia in Event il primo evento in lista }
   function VisNextEvent(var Event:TEventInBuf):TEvent; assembler;
   asm
       mov         al,EvNothing
       cmp         NumEvents,0
       je          @Fine
       cld
       mov         bx,IndexFirstEv
       push        ds
       les         di,Event
       lds         si,EvBuffer
       mov         si,bx
       mov         al,BYTE PTR ds:[si]
       mov         cx,4
       rep         movsw
       pop         ds
   @Fine:
   end;


   { Momorizza l'evento nel buffer }
   procedure AllocEvent; near; assembler;
   asm
       cmp         NumEvents,MaxNumEvents
       je          @Fine
       { Calcolo del nuovo valore di IndexLastEv }
       mov         ax,IndexLastEv
       add         ax,8
       cmp         ax,BufferOfsLimit
       jb          @Assegna
       mov         ax,BufferOrigin
   @Assegna:
       mov         IndexLastEv,ax
       inc         NumEvents
       { Alloca }
       cld
       push        ds
       pop         es
       lea         si,LastEv
       les         di,EvBuffer
       mov         di,IndexLastEv
       mov         cx,4
       rep         movsw
   @Fine:
   end;



const altezzaRiga = 16;

   procedure VisEvent(var Ev:TEventInBuf);
     begin
       hidemousecursor;
       if riga*altezzaRiga>460 then begin
         cleardevice;
         riga:=0;
         {
         BitBtlVideoDC(0,20,0,0,640,480-20);
         setfillstyle(1,0);
         bar(0,459,639,479);
         textcolor:=15;
         riga:=23;
         }
       end;
       case Ev.Event of
         EvKeyboard: begin
           _system_.DrawText(0,riga*altezzaRiga,TextLeft,
             'Tastiera -> ('+HexW(Ev.KeyComb)+'h - '+HexW(Ev.shifts)+'h)');
         end;
         EvMouse: begin
           cour.DrawText(0,riga*altezzaRiga,TextLeft,
             'Mouse -> ( '+NumStr(Ev.mcx)+' , '+NumStr(Ev.mcy)+' ) - '+
             HexW(word(Ev.Button))+'h - '+NumStr(Ev.Clicks));
         end;
       end;
       inc(riga);
       showmousecursor;
     end;

            {********* Rilevatore di eventi da mouse *********}
   procedure MouseEventController(row,column,btnStatus:word); near;
   var btC,btR,btL: byte;
   begin
       btnStatus:=btnStatus and $0007;  { Annulla tutti i bits che si riferiscono a bottoni }
       if (precBtnStatus=btnStatus) and
          (precMCY=row) and
          (precMCX=column) then
       begin
         asm
           { In questa parte si azzerano solo i contatori ClickDelayX }
            mov     dx,0801h              { DL e DH vengono usate come maschere
                                            rispettivamente per la pressione e per
                                            il rilascio }
            lea     di,PressDelayL        { DI viene utilizzato come indice per i
                                            contatori }
            mov     cx,3

         @loop:
           { Controllo per la pressione }
            test    DelayActive,dl        { Controlla il bit X di DelayActive   }
            jnz     @In_Corso1	          { Se z=0 allora il periodo Š in corso }
            mov	    WORD PTR ds:[di],0    { Se non in corso allora azzera PressDelayX }
         @In_Corso1:

            add     di,6                  { Aggiorna l'indice                   }

           { Controllo per il rilascio }
            test    DelayActive,dh        { Controlla il bit X di DelayActive   }
            jnz     @In_Corso2            { Se z=0 allora il periodo Š in corso }
            mov	    WORD PTR ds:[di],0    { Se non in corso allora azzera ReleaseDelayX }

         @In_Corso2:
            sub     di,4                  { Aggiorna l'indice                   }
            shl     dx,1                  { Aggiorna le maschere DL e DH }
            loop    @loop
         end;
         exit;
       end;
       {
         Determinazione della pressione/rilascio dei tasti.
         1. Confronta precBtnStatus e BtnStatus
            - Se il bit Š prima 0 e poi 1 allora Š stato premuto
            - Se il bit Š prima 1 e poi 0 allora Š stato rilasciato
         2. Il risultato del confronto viene notificato nelle variabili
            btX.
            - btX = 0 => nessun evento
            - btX = 1 => premuto
            - btX = 2 => rilasciato
       }
     asm
    	mov 	ax,btnStatus
        xor 	ax,precBtnStatus   { i bits settati a 1 in AX indicano i bottoni
                                     che hanno cambiato stato }
        { A questo punto pu• succedere che pi— bottoni abbiano cambiato stato e
          quindi Š necessario determinare quale di essi deve essere considerato.
          A tal fine viene utilizzata la priorit… LEFT-RIGHT-CENTER.

          In AX quindi vengono azzerati tutti i bits a sinistra del primo bit
          settato. }
        xor     dx,dx              { Determina in numero del bottone in DX }
        cmp     ax,0
        je      @Fuori
        mov     bl,1
        mov     cx,2

     @Cerca:
        test    al,bl
        jnz     @Trovato
        shl     bl,1
        loop    @Cerca

     @Trovato:
        mov     dl,3
        sub     dl,cl              { Determina in numero del bottone in DX }
        jcxz    @Fuori
        not     bl

     @Azzera:
        rol     bl,1
        and     al,bl              { Azzera i bits a sinistra del primo settato }
        loop    @Azzera

     @Fuori:
        mov     LastEv.Button,dl   { Assegna il numero del bottone }
        cmp     dl,0               { Controlla se Š stato premuto un tasto        }
        je      @TastoPremuto
        mov     MBDelayC,0         { Azzera il Mouse Device Buttons Delay Counter }

     @TastoPremuto:

        mov 	bx,bp
        sub 	bx,4               { BX viene utilizzato come indice         }
        add     bx,dx              { In DX c'Š il numero del bottone         }

        mov     btL,0              { Default = Nessun evento                 }
        mov     btR,0              { Default = Nessun evento                 }
        mov     btC,0              { Default = Nessun evento                 }

        cmp     LastEv.Button,0
        je  	@btX_Fine          { Se _Button_=0 allora btX non ha cambiato stato }
        test 	btnStatus,ax       { Controlla il bit di btnStatus           }
        jnz 	@btX_1             { Se z=0 allora il tasto Š stato premuto  }
        mov 	BYTE PTR ss:[bx],2 { btX Š stato rilasciato                  }
        jmp 	@btX_Fine

     @btX_1:
        mov 	BYTE PTR ss:[bx],1 { btX Š stato premuto                     }
        or      LastEv.Button,80h  { Setta l'ultimo bit di _Button_ per indicare
                                     che Š stato premuto }
     @btX_Fine:

       { Determinato btX bisogna verificare che il periodo corrispondente
         sia attivo oppure no ed agire di conseguenza. }

        push    ss
        pop     es                    { Casica in ES il valore di SS        }
        lea     si,btnInfo            { Carica in SI l'offset di btnPressInfo }
        mov     dx,0801h              { DL e DH vengono usate come maschere
                                        rispettivamente per la pressione e per
                                        il rilascio }
        lea     di,PressDelayL        { DI viene utilizzato come indice per i
                                        contatori }
        mov 	bx,bp
        sub 	bx,3                  { BX viene utilizzato come indice per le
                                        variabili btX }
        mov     cx,3

     @loop2:
       { Controllo per la pressione }
        test	DelayActive,dl        { Controlla il bit X di DelayActive   }
        jnz     @In_Corso1	      { Se z=0 allora il periodo Š in corso }

     @Non_in_corso1:
        cmp     BYTE PTR es:[bx],1    { Verifica che il bottone X sia stato premuto }
        je      @Premuto
     @Non_Premuto:
        mov	WORD PTR ds:[di],0    { Se non in corso e btX non Š stato premuto
                                        allora azzera PressDelayX  }
        jmp     @001
     @Premuto:
        or      DelayActive,dl        { Attiva il periodo di multi-clicking }
        mov     BYTE PTR ds:[si],1    { Imposta a 1 il numero di pressioni nel
                                        periodo }
        jmp     @001

     @In_Corso1:
        cmp     BYTE PTR es:[bx],1    { Verifica che il bottone X sia stato premuto }
        jne     @001
        inc     BYTE PTR ds:[si]      { Incrementa il numero di pressioni nel
                                        periodo }
     @001:

        inc     si
        inc     si
        inc     si

        add     di,6

       { Controllo per il rilascio }
        test	DelayActive,dh        { Controlla il bit X di DelayActive   }
        jnz     @In_Corso2            { Se z=0 allora il periodo Š in corso }

     @Non_in_corso2:
        cmp     BYTE PTR es:[bx],2    { Verifica che il bottone X sia stato rilasciato }
        je      @Rilasciato
     @Non_Rilasciato:
        mov	WORD PTR ds:[di],0    { Se non in corso e btX non Š stato premuto
                                        allora azzera ReleaseDelayX  }
        jmp     @002
     @Rilasciato:
        or      DelayActive,dh        { Attiva il periodo di multi-clicking }
        mov     BYTE PTR ds:[si],1    { Imposta a 1 il numero di rilasci nel
                                        periodo }
        jmp     @002

     @In_Corso2:
        cmp     BYTE PTR es:[bx],2    { Verifica che il bottone X sia stato rilasciato }
        jne     @002
        inc     BYTE PTR ds:[si]      { Incrementa il numero dei rilasci nel
                                        periodo }
     @002:
        { Aggiornameto indici }
        dec     si
        dec     si
        sub     di,4
        inc     bx

        shl     dx,1                  { Aggiorna le maschere DL e DH }

        loop    @loop2

        mov     IDevDelayC,0          { Azzera il General Input Device Delay Counter }
        mov     ax,row
        cmp     ax,precMCY            { Confronta row con precMCY }
        mov     precMCY,ax
        mov     LastEv.mcy,ax
        je      @003
        mov     MMDelayC,0            { Azzera il Mouse Device Movement Delay Counter }
     @003:
        mov     ax,column
        cmp     ax,precMCX
        mov     precMCX,ax
        mov     LastEv.mcx,ax
        je      @004
        mov     MMDelayC,0            { Azzera il Mouse Device Movement Delay Counter }
     @004:
        mov     ax,btnStatus
        mov     precBtnStatus,ax

        { Determinazione dei clicks di pressione o di rilascio }
        xor     al,al                 { In AL verr… messo in numero di clicks }
        cmp     LastEv.Button,0
        je      @FuoriClicks

        xor     bh,bh
        mov     bl,LastEv.Button      { Carica in BX _Button_ per poi usare BX
                                        come indice }
        and     bx,0007h              { Prende in BX il numero del bottone  }
        dec     bx
        lea     si,btnInfo            { Carica l'offset di btnInfo in SI    }
        test    LastEv.Button,80h     { Controlla se il bottone Š stato rilasciato }
        jz      @Released             { Se z=1 allora il bottone Š stato rilasciato }

     @Pressed:
        mov     al,ds:[si+bx]
        jmp     @FuoriClicks

     @Released:
        mov     al,ds:[si+bx+3]

     @FuoriClicks:
        mov     LastEv.Clicks,al

        mov     LastEv.Event,EvMouse
        sti
        call    AllocEvent
        cli
     end;
   end;


var Executing:boolean;


                {********* Application Controller *********}
   procedure EventController; external;
   procedure EventCtrlSetup;  external;
   procedure StopEvScanning; far; external;
   procedure StartEvScanning; far; external;
   {$L appctrl.obj}



   procedure InitEventManager;
     begin
       { Inizializza le variabili per l'Event Buffer }
       EvBuffer:=nil;
       { Inizializza l'Event Buffer }
       CreateEvBuffer;
       precMCX:=0;
       precMCY:=0;
       precBtnStatus:=0;
       MultipleMClickDelay:=13;
       { Effettua il setup di AppController }
       EventCtrlSetup;
     end;




var i:longint;
    Ev__:TEventInBuf;

begin
  { Inizio programma principale }
  InizializzaGrafica(3,16);
  _serif8_.DrawText(0,riga*20,TextLeft,'Inizio scansione eventi.  Attendere...');
  {
  readkey;
  }
  wait(1);

  cleardevice;
  ResetMouse;
  showmousecursor;

  InitEventManager;

{$IFDEF interrupt}

  GetIntVec($1c,@Int1C);
  SetIntVec($1c,@EventController);
  with LastEv do repeat until(Event=EvKeyboard) and (KeyComb=27);
  SetIntVec($1c,@Int1C);
  while GetNextEvent(Ev__)<>EvNothing do begin
    VisEvent(Ev__);
    delay(100);
  end;
  readkey;

{$ELSE}

  GetIntVec($F3,@IntF3);
  SetIntVec($F3,@EventController);
  with LastEv do
    repeat
      asm
        int    0F3h
      end;
    StopEvScanning;
      if GetNextEvent(Ev__)<>EvNothing then VisEvent(Ev__);
    StartEvScanning;
    until (Event=EvKeyboard) and (KeyComb=27);
  SetIntVec($F3,@IntF3);

{$ENDIF}
end.