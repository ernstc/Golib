{ by ERNESTO CIANCIOTTA }

{$D-}
{$L-}

{ Modulo per la temporizzazione dei programmi }
unit Timer;

interface

   {procedure GetTime(var Hour, Minute, Second, Sec100: Word);}


   uses dos,crt,graph;

   procedure StartTimer;
   procedure BlockTimer;
   procedure ResetTimer;
   procedure GetTimerState(var sec,sec100:word);
   procedure WritelnTimerState;

   procedure GTimerStart;
   procedure GTimerStop;

implementation


   const   secondi : longint = 0;
         centesimi : word = 0;

   var h,m,s,s100:array[1..2] of word;


   procedure StartTimer;
     begin
       getTime(h[1],m[1],s[1],s100[1]);
     end;

   procedure BlockTimer;
     begin
       getTime(h[2],m[2],s[2],s100[2]);
       inc(secondi,(h[2]-h[1])*3600);
       inc(secondi,(m[2]-m[1])*60);
       if s[2]>s[1] then inc(secondi,s[2]-s[1])
                    else begin
                      dec(secondi,60);
                      inc(secondi,60-s[1]+s[2]);
                    end;
       if s100[2] < s100[1] then begin
         dec(secondi);
         centesimi:=1000-s100[1]+s100[2];
       end
       else centesimi:=s100[2]-s100[1];
     end;

   procedure ResetTimer;
     begin
       secondi:=0;
       centesimi:=0;
     end;

   procedure GetTimerState;
     begin
       sec:=secondi;
       sec100:=centesimi;
     end;

   procedure WritelnTimerState;
     var s,s100:word;
     begin
       GetTimerState(s,s100);
       writeln;
       writeln('Tempo trascorso:  ',s,' secondi e ',s100,' centesimi.');
     end;



   procedure GTimerStart;
     begin
       resettimer;
       starttimer;
     end;



   procedure GTimerStop;
     const
         GolibPalette:PaletteType=(
           size:16;
           colors:(0,4,2,6,1,5,3,56,7,36,50,54,9,45,27,63)
         );
     begin
       blocktimer;
       restorecrtmode;
       writelntimerstate;
       readkey;
       SetGraphMode(GetGraphMode);
       SetRGBPalette(56,27,27,27);
       SetRGBPalette(7,48,48,48);
       SetAllPalette(GolibPalette);
     end;


end.



