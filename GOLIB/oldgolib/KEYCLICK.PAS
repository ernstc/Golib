
 {Keep.PAS}

{ Example for Keep }

{$M $800,0,0 }   { 2K stack, no heap }
{ This program causes a click each time
 a key is pressed.}
uses Crt, Dos;
var
  KbdIntVec : Procedure;
  shift:byte;
  KeyComb:word;

{$F+}
procedure Keyclick; interrupt;
assembler;
asm
   pushf
   call    KbdIntVec
   push    es
   mov     dx,0040h
   mov     es,dx
   xor     bx,bx
   { Controlla se Š presente un carattere nel buffer }
   mov     ax,es:[001Ah]
   cmp     ax,es:[001Ch]
   je      @001
   call    readkey
   mov     bl,al
   cmp     al,0
   jne     @001
   call    readkey
   mov     bh,al
@001:
   mov     KeyComb,bx
   mov     al,es:[0017h]
   mov     shift,al
   pop     es
end;
{$F-}

begin
  { Insert ISR into keyboard chain }
  GetIntVec($9,@KbdIntVec);
  SetIntVec($9,Addr(Keyclick));
  while true do;
  SetIntVec($9,@KbdIntVec);
end.


