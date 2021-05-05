{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



unit BIOS_Utt;

interface

   uses dos;

   type TAction_DFZ = procedure;

   procedure SetStandardDimCursor;
   procedure SetDimCursor(LineaIniziale,LineaFinale:byte);
   procedure EliminaCursore;
   procedure RipristinaCursore;
   procedure SetAction_For_DivForZero(action:TAction_DFZ);
   procedure Ripristina_DivForZero;
   procedure StampaSchermo;

implementation

  const
       LnSt:byte = 7;
       LnFn:byte = 8;


  var StatoCursore:boolean;
      Action_DFZ:procedure;
      DivForZero:pointer;

  {$F+}
  procedure NessunaAzione; begin end;
  {$F-}

  procedure DivisoZero(flags,cs,ip,ax,bx,cx,dx,si,di,ds,es,bp:word);
  interrupt;
    begin
      Action_DFZ;
    end;

  procedure SetStandardDimCursor; assembler;
  asm
        MOV     AH,1
        MOV     CX,0708h
        INT     10h
        MOV     LnSt,7
        MOV     LnFn,8
  end;

  procedure SetDimCursor; assembler;
  asm
        MOV     AH,1
        MOV     CH,LineaIniziale
        MOV     CL,LineaFinale
        MOV     LnSt,CH
        MOV     LnFn,CL
        INT     10h
  end;

  procedure EliminaCursore; assembler;
  asm
        MOV     AH,1
        MOV     CH,20h
        INT     10h
  end;

  procedure RipristinaCursore; assembler;
  asm
        MOV     AH,1
        MOV     CH,LnSt
        MOV     CL,LnFn
        INT     10h
  end;

  procedure SetAction_For_DivForZero;
    begin
      Action_DFZ:=action;
    end;

  procedure Ripristina_DivForZero;
    begin
      SetIntVec(0,DivForZero);
    end;

  procedure StampaSchermo; assembler;
  asm
        INT     5
  end;

begin
  Action_DFZ:=NessunaAzione;
  getIntVec(0,DivForZero);
  SetIntVec(0,@DivisoZero);
end.


