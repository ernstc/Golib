{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



uses
    crt,
    paths,
    graftool,
    fonts;

const
      NPicth = 4;


type
      TPicth  = record
         picth: word;
         cod_SubPP,
         cod_Mark: char;
      end;

      TPicths = array[1..NPicth] of TPicth;


const
      Picths: TPicths =
         ((picth: 7 ; cod_SubPP:#7  ; cod_Mark:#1 ),
          (picth:10 ; cod_SubPP:#8  ; cod_Mark:#2 ),
          (picth:14 ; cod_SubPP:#9  ; cod_Mark:#3 ),
          (picth:24 ; cod_SubPP:#10 ; cod_Mark:#4 ));
var
   M_Symboles:OTFont;
   i:byte;


begin
  InizializzaGrafica(3,16);
  M_Symboles.Init;
  M_Symboles.LoadFontFrom(Work_Dir+'\golib8.bmp\golib_f.fnt');
  for i:=1 to NPicth do begin
    M_Symboles.DrawText(10,10+(30*i),TextLeft,Picths[i].cod_subPP);
    M_Symboles.DrawText(50,10+(30*i),TextLeft,Picths[i].cod_Mark);
  end;
  readkey;
end.