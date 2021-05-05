unit BIOS_Utt;

interface

   uses dos;

   type TAction_DFZ = procedure;

   procedure SetDimCursor(LineaIniziale,LineaFinale:byte);
   procedure EliminaCursore;
   procedure RipristinaCursore;
   procedure SetAction_For_DivForZero(action:TAction_DFZ);
   procedure Ripristina_DivForZero;
   procedure StampaSchermo;

implementation

  var StatoCursore:boolean;
      LnSt,LnFn:byte;
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

  procedure SetDimCursor;
    var Regs:Registers;
    begin
      with regs do begin
        ah:=1;
        ch:=lineaIniziale;
        cl:=lineaFinale;
        intr($10,regs);
      end;
      LnSt:=LineaIniziale;
      LnFn:=LineaFinale;
    end;

  procedure EliminaCursore;
    var regs:Registers;
    begin
      with regs do begin
        ah:=1;
        ch:=$20;
        intr($10,regs);
      end;
    end;

  procedure RipristinaCursore;
    var regs:Registers;
    begin
      with regs do begin
        ah:=1;
        ch:=LnSt;
        cl:=LnFn;
        intr($10,regs);
      end;
    end;

  procedure SetAction_For_DivForZero;
    begin
      Action_DFZ:=action;
    end;

  procedure Ripristina_DivForZero;
    begin
      SetIntVec(0,DivForZero);
    end;

  procedure StampaSchermo;
    var regs:Registers;
    begin
      intr(5,regs);
    end;

begin
  Action_DFZ:=NessunaAzione;
  getIntVec(0,DivForZero);
  SetIntVec(0,@DivisoZero);
end.


