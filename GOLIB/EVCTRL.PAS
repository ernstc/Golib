{ Ernesto CIANCIOTTA Productions }

{ ********************************************* }
{ *                                           * }
{ * Modulo contenente un rilevatore di eventi * }
{ * che si connette all'interrupt 1Ch         * }
{ *                                           * }
{ * Scritto con Turbo Pascal 7.0 e            * }
{ *         con Turbo Assembler 3.0           * }
{ *                                           * }
{ ********************************************* }

{$D+}
{$L+}

UNIT EvCTRL;

INTERFACE

uses
     keyboard,
     dos;

const
      btLPressMask = $0001;
      btRPressMask = $0002;
      btCPressMask = $0004;
      btLReleaseMask = $0008;
      btRReleaseMask = $0010;
      btCReleaseMask = $0020;

      DefaultMultipleMClickDelay = 10;


const
      { Tipi di Eventi }
      EvNothing  = $0000;
      EvKeyboard = $0001;
      EvMouse    = $0002;
      EvCommand  = $0003;

type
      PMessage = ^TMessage;
      TMessage = record
         Reserved: word;
         Message: word;
         case byte of
         0: ( b1Reg, b2Reg, b3Reg, b4Reg: byte;
              b5Reg, b6Reg, b7Reg, b8Reg: byte;
             );
         1: ( w1Reg, w2Reg: word;
              w3Reg, w4Reg: word;
             );
         2: ( longReg1: longint;
              longReg2: longint;
             );
         3: ( ParametersPtr: pointer;
             );
         4: ( Shifts: word;
              case byte of
              0: ( case byte of
                   0: ( KeyStroke:word;
                       );
                   1: ( Character: Char;
                        ScanCode: byte;
                       );
                  );
              1: ( Clicks: byte;
                   mcx, mcy: word;
                  );
             );
      end;





var
    { Contatori di informazioni sul ritardo di eventi da parte degli
      INPUT DEVICE }
    IDevDelayC,     { General Input Device Delay Counter }
    KBDelayC,       { Keyboard Device Delay Counter }
    MMDelayC,       { Mouse Device Movement Delay Counter }
    MBDelayC: word; { Mouse Device Buttons Delay Counter }

    IndexFirstMsg: word;
    IndexLastMsg : word;

   procedure SetMultipleMClickDelay(milliseconds:byte);
   { Alloca un messaggio nel buffer se questo non Š pieno }
   procedure AllocMessage(var Message:TMessage);
   { Cancella il primo messaggio della lista }
   procedure DeleteMessage;
   { Svuota il buffer degli Messagi }
   procedure DeleteAllMessages;
   { Verifica che sia presente un messaggio in lista e restiuisce il tipo del
     primo messaggio il lista }
   function MessagePresent:word;
   { Copia il primo messaggio in attesa di essere processato. }
   function VisNextMessage(var Message:TMessage):word;
   { Copia e cancellazione del primo messaggio in attesa di essere processato. }
   function GetNextMessage(var Message:TMessage):word;
   { TRUE se il buffer Š pieno }
   function MessageBufferFull:boolean;
   { Rispettivamente bloccano e riattivano la scansione dei Messagi }
   procedure StopEvScanning;
   procedure StartEvScanning;


   { Chiamare solo dopo che Š stato attivato il mouse }
   procedure InitMessageManager;

   procedure InitMessageManagerF3;


IMPLEMENTATION

type
      TPointer = record
         offset,
         segment:word;
      end;

      TProc = procedure;



     {*******************************************************************}
     {--------------------- Gestione interna modulo ---------------------}
     {*******************************************************************}

const
      MessageSize = sizeof(TMessage);
      CopySteps   = MessageSize div 2;
      OffSet_MessageField = 2;

      { Numero massimo di messaggi memorizzabili }
      MaxNumMessages = 100;
      { Dimensione del buffer }
      MsgBufferSize = MaxNumMessages * MessageSize;


var
    { Puntatore al buffer in cui verrano memorizzati i messaggi. }
    MsgBuffer:pointer;
    { Indici per l'Message Buffer }
    NumMessages   : word;

    {IndexFirstMsg: word;
    IndexLastMsg : word;}
    BufferOfsLimit: word;  { Limite dell'offset del buffer }
    BufferOrigin: word;    { Origine del buffer            }
    { Ultimo messaggio che Š stato creato }
    LastSysMessage: TMessage;
    { Quando si verifica un messaggio allora l'AppController non deve fare
      altro che compilare LastSysMessage e chiamare AllocMessage per memorizzare
      l'evento nel buffer.
    }

var
    MultipleMClickDelay: word;   { numero di ritardi del INT 1Ch }

    Int1C, IntF3: procedure;

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

   { *** Funzioni publiche *** }

   procedure SetMultipleMClickDelay(milliseconds:byte);
     begin
       MultipleMClickDelay:=round(milliseconds/18.2);
     end;


   procedure AllocMessage(var Message:TMessage); assembler;
   asm
       cmp         NumMessages,MaxNumMessages
       je          @Fine
       { Calcolo del nuovo valore di IndexLastMsg }
       mov         ax,IndexLastMsg
       add         ax,MessageSize
       cmp         ax,BufferOfsLimit
       jb          @Assegna
       mov         ax,BufferOrigin
   @Assegna:
       mov         IndexLastMsg,ax
       inc         NumMessages
       { Alloca }
       cld
       mov         bx,IndexLastMsg
       push        ds
       les         di,MsgBuffer
       lds         si,Message
       mov         di,bx
       mov         cx,CopySteps
       rep         movsw
       pop         ds
   @Fine:
   end;


   procedure DeleteMessage; assembler;
   asm
       cmp         NumMessages,0
       je          @Fine
       { Calcolo del nuovo valore di IndexFirstMsg }
       add         bx,MessageSize
       cmp         bx,BufferOfsLimit
       jne         @Assegna
       mov         bx,BufferOrigin
   @Assegna:
       mov         IndexFirstMsg,bx
       dec         NumMessages
   @Fine:
   end;


   procedure DeleteAllMessages;
     begin
       if MsgBuffer=nil then exit;
       IndexFirstMsg:=TPointer(MsgBuffer).Offset;
       IndexLastMsg:=BufferOfsLimit;
       NumMessages:=0;
       precMCX:=0;
       precMCY:=0;
       precBtnStatus:=0;
     end;


   function MessagePresent:word; assembler;
   asm
       xor         ax,ax
       cmp         NumMessages,0
       je          @Fine
       les         di,MsgBuffer
       mov         di,IndexFirstMsg
       mov         ax,es:[di+OffSet_MessageField]
   @Fine:
   end;


   { Copia in Message il primo messaggio in lista }
   function VisNextMessage(var Message:TMessage):word; assembler;
   asm
       xor         ax,ax
       cmp         NumMessages,0
       je          @Fine
       cld
       mov         bx,IndexFirstMsg
       push        ds
       les         di,Message
       lds         si,MsgBuffer
       mov         si,bx
       mov         ax,ds:[si+OffSet_MessageField]
       mov         cx,CopySteps
       rep         movsw
       pop         ds
   @Fine:
   end;


   { Copia in Message il primo messaggio in lista e lo cancella dal buffer }
   function GetNextMessage(var Message:TMessage):word; assembler;
   asm
       xor         ax,ax
       cmp         NumMessages,0
       je          @Fine
       cld
       mov         bx,IndexFirstMsg
       push        ds
       les         di,Message
       lds         si,MsgBuffer
       mov         si,bx
       mov         ax,ds:[si+OffSet_MessageField]
       mov         cx,CopySteps
       rep         movsw
       pop         ds
       { Calcolo del nuovo valore di IndexFirstMsg }
       add         bx,MessageSize
       cmp         bx,BufferOfsLimit
       jne         @Assegna
       mov         bx,BufferOrigin
   @Assegna:
       mov         IndexFirstMsg,bx
       dec         NumMessages
   @Fine:
   end;


   { Verifica che il buffer sia pieno }
   function MessageBufferFull:boolean;
     begin
       if NumMessages=MaxNumMessages then MessageBufferFull:=true
                                 else MessageBufferFull:=false;
     end;



   { *** Funzioni private *** }

   procedure CreateMsgBuffer;
     begin
       GetMem(MsgBuffer,MsgBufferSize);
       IndexFirstMsg:=TPointer(MsgBuffer).Offset;
       BufferOrigin:=IndexFirstMsg;
       BufferOfsLimit:=IndexFirstMsg+MsgBufferSize;
       IndexLastMsg:=BufferOfsLimit;
       NumMessages:=0;
       { Reset di LastEv }
       asm
         cld
         push     ds
         pop      es
         lea      di,LastSysMessage
         xor      ax,ax
         mov      cx,CopySteps
         rep      stosw
       end;
     end;


   procedure DestroyMsgBuffer;
     begin
       if MsgBuffer=nil then exit;
       FreeMem(MsgBuffer,MsgBufferSize);
       MsgBuffer:=nil;
       NumMessages:=0;
     end;


   { Momorizza il messaggio nel buffer se questo non Š pieno. }
   procedure PutMessageInBuffer; near; assembler;
   asm
       cmp         NumMessages,MaxNumMessages
       je          @Fine
       { Calcolo del nuovo valore di IndexLastMsg }
       mov         ax,IndexLastMsg
       add         ax,MessageSize
       cmp         ax,BufferOfsLimit
       jb          @Assegna
       mov         ax,BufferOrigin
   @Assegna:
       mov         IndexLastMsg,ax
       inc         NumMessages
       { Alloca }
       cld
       push        ds
       pop         es
       lea         si,LastSysMessage
       les         di,MsgBuffer
       mov         di,IndexLastMsg
       mov         cx,CopySteps
       rep         movsw
   @Fine:
   end;


var
    { Utilizzata come variabile di passaggio da MouseMessageController. }
    MButton:byte;

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
        call    FAR PTR GetShiftFlags   { Legge lo stato degli shifts della tastiera }
        cli
        mov     LastSysMessage.Shifts,ax
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
        mov     MButton,dl         { Assegna il numero del bottone }
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

        cmp     MButton,0
        je  	@btX_Fine          { Se _Button_=0 allora btX non ha cambiato stato }
        test 	btnStatus,ax       { Controlla il bit di btnStatus           }
        jnz 	@btX_1             { Se z=0 allora il tasto Š stato premuto  }
        mov 	BYTE PTR ss:[bx],2 { btX Š stato rilasciato                  }
        jmp 	@btX_Fine

     @btX_1:
        mov 	BYTE PTR ss:[bx],1 { btX Š stato premuto                     }
        or      MButton,80h        { Setta l'ultimo bit di _Button_ per indicare
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
        mov     LastSysMessage.Mcy,ax
        je      @003
        mov     MMDelayC,0            { Azzera il Mouse Device Movement Delay Counter }
     @003:
        mov     ax,column
        cmp     ax,precMCX
        mov     precMCX,ax
        mov     LastSysMessage.Mcx,ax
        je      @004
        mov     MMDelayC,0            { Azzera il Mouse Device Movement Delay Counter }
     @004:
        mov     ax,btnStatus
        mov     precBtnStatus,ax

        { Determinazione dei clicks di pressione o di rilascio }
        xor     al,al                 { In AL verr… messo in numero di clicks }
        cmp     MButton,0
        je      @FuoriClicks

        xor     bh,bh
        mov     bl,MButton            { Carica in BX _Button_ per poi usare BX
                                        come indice }
        and     bx,0003h              { Prende in BX il numero del bottone  }
        dec     bx
        lea     si,btnInfo            { Carica l'offset di btnInfo in SI    }
        test    MButton,80h           { Controlla se il bottone Š stato rilasciato }
        jz      @Released             { Se z=1 allora il bottone Š stato rilasciato }

     @Pressed:
        mov     al,ds:[si+bx]
        jmp     @FuoriClicks

     @Released:
        mov     al,ds:[si+bx+3]

     @FuoriClicks:
        mov     LastSysMessage.Clicks,al

     { Determinazione del messaggio generato dal mouse }

        mov     ah,80h
        cmp     al,1                  { Controlla il numero di clicks }
        jna     @NoMultiClick         { Se <= salta                   }
        or      ah,01h

     @NoMultiClick:

        mov     al,MButton
        mov     LastSysMessage.Message,ax
        mov     LastSysMessage.Reserved,0
        call    PutMessageInBuffer
     end;
   end;



var
    { Interrupts da usare per le operazioni con la tastiera di GetKeyStroke,
      CheckForKeyStroke e GetShiftFlags. }
    _Get_Int_   : byte;
    _Check_Int_ : byte;
    _Shifts_Int_: byte;


                {********* Event Controller *********}
   procedure EventController; external;
   procedure EventCtrlSetup;  external;
   procedure StopEvScanning; external;
   procedure StartEvScanning; external;
   {$L appctrl.obj}



   procedure InitMessageManager;
     begin
       { Inizializza l'Message Buffer }
       CreateMsgBuffer;
       precMCX:=0;
       precMCY:=0;
       precBtnStatus:=0;
       MultipleMClickDelay:=DefaultMultipleMClickDelay;
       { Effettua il setup di AppController }
       EventCtrlSetup;
       { Installa EventController all'interrupt 1Ch }
       SetIntVec($1C,@EventController);
     end;



   procedure InitMessageManagerF3;
     begin
       { Inizializza l'Event Buffer }
       CreateMsgBuffer;
       precMCX:=0;
       precMCY:=0;
       precBtnStatus:=0;
       MultipleMClickDelay:=DefaultMultipleMClickDelay;
       { Effettua il setup di AppController }
       EventCtrlSetup;
       { Installa EventController all'interrupt F3h }
       SetIntVec($F3,@EventController);
     end;




   {******************** Uscita dall'applicazione ************************}

var
   ExitProcedure: pointer;

   procedure ExitApplic; far;
     begin
       { Ripristino degli interrupts }
       SetIntVec($1C,@Int1C);

       SetIntVec($F3,@IntF3);

       DestroyMsgBuffer;
       if ExitProcedure<>nil then TProc(ExitProcedure);
     end;
{$F-}


BEGIN
  { Installazione della procedura di uscita }
  ExitProcedure:=exitProc;
  exitProc:=@ExitApplic;
  GetIntVec($1C,@Int1C);

  GetIntVec($F3,@IntF3);

  { Inizializza le variabili per l'Message Buffer }
  MsgBuffer:=nil;
  NumMessages:=0;
  GetKeyInterrupts(_Get_Int_,_Check_Int_,_Shifts_Int_);
END.
