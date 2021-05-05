{ by ERNESTO CIANCIOTTA (c) 1995 }

uses timer,
     inter_fc,
     bios_utt,
     graph,
     mouse,
     crt,
     graftool,
     dispfl_8,
     golib8,
     bitmaps,
     buttons,
     codici,
     w_intest;

const _delay:boolean=false;
      _f2:boolean=false;

type OTNewWin =object(OTWindow)
       function reactionevent(event:word):word; virtual;
       procedure disegna; virtual;
     end;

     OPcolori=^otcolori;
     OTColori = object(OTView)
       procedure Disegna; virtual;
     end;


procedure OTColori.Disegna;
var i,l:word;
begin
  l:=r.DimX div 8;
  for i:=0 to 7 do begin
    setfillstyle(1,i);
    with r do bar(x1+l*i,y1,x1+l*i+l,y2-dimY div 2-2);
  end;
  for i:=8 to 15 do begin
    setfillstyle(1,i);
    with r do bar(x1+l*(i-8),y2-dimY div 2-1,x1+l*(i-8)+l,y2);
  end;
end;


type TSegmentWord = array [0..19199] of word;
     vet25 = array[1..25] of byte;
     vet9  = array[1..9] of byte;
     vet5  = array[1..5] of byte;
     vet20 = array[1..20] of byte;


var
    k,win2:OTNewWin;
    r:OTRect;
    l:OPLayoutMetrics;
    attivo:boolean;
    num1,num2: byte;
    Seg1W:^TSegmentWord;
    Seg2W:^TSegmentWord;
    transito:^TSegmentWord;
    copia:boolean;


var
    CRTCRegs     :vet25;
    SequencerRegs:vet5;
    GraphicsRegs :vet9;
    AttributeRegs:vet20;
    MOutPut:byte;
    FeatureC:byte;
    graphic1:byte;
    graphic2:byte;
    PELmask:byte;
    PELaddread:byte;
    PELaddwrite:byte;
    PELdata:byte;

var
    _CRTCRegs     :vet25;
    _SequencerRegs:vet5;
    _GraphicsRegs :vet9;
    _AttributeRegs:vet20;
    _MOutPut:byte;
    _FeatureC:byte;
    _graphic1:byte;
    _graphic2:byte;



procedure ScriviRegistro(chip:word;numRegistro,valore:byte);
begin
  if chip in [0,8,$10,$18] then asm
    mov ah,$f1
    mov dx,chip
    mov bl,numRegistro
    mov bh,valore
    int 10h
  end
  else asm
    mov ah,$f1
    mov dx,chip
    mov bl,valore
    int 10h
  end;
end;


procedure LeggiRegistri; assembler;
asm
    mov ch,1
    mov cl,25
    mov dx,0
    mov ax,ds
    mov es,ax
    mov bx,offset CRTCRegs
    mov ah,$f2
    xor al,al
    int 10h

    mov ch,1
    mov cl,5
    mov dx,8
    mov ax,ds
    mov es,ax
    mov bx,offset SequencerRegs
    mov ah,$f2
    xor al,al
    int 10h

    mov ch,1
    mov cl,9
    mov dx,10h
    mov ax,ds
    mov es,ax
    mov bx,offset GraphicsRegs
    mov ah,$f2
    xor al,al
    int 10h

    mov ah,$f2
    mov ch,1
    mov cl,20
    mov dx,18h
    mov ax,ds
    mov es,ax
    mov bx,offset AttributeRegs
    mov ah,$f2
    xor al,al
    int 10h

    mov ah,$f0
    mov bl,1
    mov bh,00
    mov dx,20h
    int 10h
    mov MOutPut,bl

    mov ah,$f0
    mov bl,1
    mov bh,00
    mov dx,28h
    int 10h
    mov FeatureC,bl

    mov ah,$f0
    mov bl,1
    mov bh,00
    mov dx,30h
    int 10h
    mov Graphic1,bl

    mov ah,$f0
    mov bl,1
    mov bh,00
    mov dx,38h
    int 10h
    mov Graphic2,bl

    mov dx,3c6h
    in al,dx
    mov PELmask,al
    mov dx,3c7h
    in al,dx
    mov PELaddread,al
    mov dx,3c8h
    in al,dx
    mov PELaddwrite,al
    mov dx,3c9h
    in al,dx
    mov PELdata,al
end;


procedure ScriviRegistri;
var i:byte;
    buf:byte;
begin
  asm

    mov ch,1
    mov cl,25
    mov dx,0
    mov ax,ds
    mov es,ax
    mov bx,offset CRTCRegs
    mov ah,$f3
    xor al,al
    int 10h

    mov ah,$f2
    mov ch,1
    mov cl,20
    mov dx,18h
    mov ax,ds
    mov es,ax
    mov bx,offset AttributeRegs
    mov ah,$f3
    xor al,al
    int 10h

    mov ah,$f1
    mov bl,1
    mov dx,20h
    mov bl,MOutPut
    int 10h
    mov MOutPut,bl

    mov ah,$f1
    mov bl,1
    mov dx,28h
    mov bl,FeatureC
    int 10h
    mov FeatureC,bl

    mov ah,$f1
    mov bl,1
    mov dx,30h
    mov bl,Graphic1
    int 10h
    mov Graphic1,bl

    mov ah,$f1
    mov bl,1
    mov dx,38h
    mov bl,Graphic2
    int 10h
    mov Graphic2,bl

    mov dx,3c6h
    mov al,PELmask
    out dx,al
    mov dx,3c7h
    mov al,PELaddread
    out dx,al
    mov dx,3c8h
    mov al,PELaddwrite
    out dx,al
    mov dx,3c9h
    mov al,PELdata
    out dx,al
  end;
  for i:=1 to 7 do begin
    buf:=GraphicsRegs[i];
    asm
      mov dx,10h
      mov bl,i
      mov bh,buf
      mov ah,$f1
      int 10h
      mov buf,bl
    end;
  end;
  asm
    mov ch,1
    mov cl,5
    mov dx,8
    mov ax,ds
    mov es,ax
    mov bx,offset SequencerRegs
    mov ah,$f3
    xor al,al
    int 10h
  end;
  LeggiRegistri;
end;



procedure daSeg1aSeg2;
begin
  hidemousecursor;
  seg1w:=ptr($A000,0);
  seg2w:=ptr($A000,19200);
  ScriviRegistri;
{seg2w^:=seg1w^;}
  asm
    push   ds
    les    di,dword ptr seg2w
    lds    si,dword ptr seg1w
    mov	   cx,19199
    cld
    rep    movsb
    pop    ds
  end;
  { Ripristina il secondo registro del sequencer accedendo direttamente alle
    porte hardware}
  asm
    mov dx,$3c4
    mov al,2
    out dx,al
    mov dx,$3c5
    mov al,15
    out dx,al
  end;
  showmousecursor;
end;



procedure SettaRegistri;
var ch:char;

  procedure Schermo;
  begin
    gotoxy(1,1);
    write  ('Modifica dei registri dei chips video.                                          ');
    write  ('--------------------------------------------------------------------------------');
    writeln('ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿');
    writeln('³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³');
    writeln('ÃÄÄÄÅÄÄÄÅÄÄÄÅÄÄÄÅÄÄÄÅÄÄÄÅÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ');
    writeln('³   ³   ³   ³   ³   ³   ³ CRT Controller (25 regs) 3B4h mono , 3D4h color');
    writeln('ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ');
    writeln('ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿');
    writeln('³   ³   ³   ³   ³   ³ Sequencer (5 registri) 3C4h');
    writeln('ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ');
    writeln('ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿');
    writeln('³   ³   ³   ³   ³   ³   ³   ³   ³   ³ Graphic Controller (9 registri) 3CEh');
    writeln('ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ');
    writeln('ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿');
    writeln('³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³');
    writeln('ÃÄÄÄÅÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ');
    writeln('³   ³ Attribute Controller (20 registri) 3C0h');
    writeln('ÀÄÄÄÙ');                                           {53}
    writeln('ÚÄÄÄ¿                                              ÚÄÄÄ¿');
    writeln('³   ³ Miscellaneous OutPut register 3C2h           ³   ³ PEL mask register');
    writeln('³   ³ Feature Control reg. (3BAh mono, 3DAh color) ³   ³ PEL address read mode');
    writeln('³   ³ Graphic 1 Position register 3CCh             ³   ³ PEL address write mode');
    writeln('³   ³ Graphic 2 Position register 3CAh             ³   ³ PEL data register');
    writeln('ÀÄÄÄÙ                                              ÀÄÄÄÙ');
  end;


  procedure VisualizzaValori;
  var col,i:byte;
  begin
    col:=0;
    for i:=1 to 19 do begin
      inc(col);
      gotoxy(2+4*(col-1),4);
      write(CrtCRegs[i]:3);
    end;
    col:=0;
    for i:=i+1 to 25 do begin
      inc(col);
      gotoxy(2+4*(col-1),6);
      write(CrtCRegs[i]:3);
    end;
    col:=0;
    for i:=1 to 5 do begin
      inc(col);
      gotoxy(2+4*(col-1),9);
      write(SequencerRegs[i]:3);
    end;
    col:=0;
    for i:=1 to 9 do begin
      inc(col);
      gotoxy(2+4*(col-1),12);
      write(GraphicsRegs[i]:3);
    end;
    col:=0;
    for i:=1 to 19 do begin
      inc(col);
      gotoxy(2+4*(col-1),15);
      write(AttributeRegs[i]:3);
    end;
    col:=0;
    for i:=i+1 to 20 do begin
      inc(col);
      gotoxy(2+4*(col-1),17);
      write(AttributeRegs[i]:3);
    end;
    gotoxy(2,20);  write(MOutPut:3);
    gotoxy(2,21);  write(FeatureC:3);
    gotoxy(2,22);  write(Graphic1:3);
    gotoxy(2,23);  write(Graphic2:3);
    gotoxy(53,20);  write(PELmask:3);
    gotoxy(53,21);  write(PELaddread:3);
    gotoxy(53,22);  write(PELaddwrite:3);
    gotoxy(53,23);  write(PELdata:3);
  end;

  procedure ModificaValori;
  var col,riga,i,chip:byte;

  begin
    ch:=#0;
    chip:=1;
    i:=1;
    col:=2;
    riga:=4;
    evidenzia(col,riga,col+2,riga,$70);
    while true do begin
      ch:=readkey;
      case ch of
      #0 : case readkey of
             #71 : asm
                     mov ah,$f6
                     int 10h
                   end;
             #79 : break;
             #75 : begin
                     evidenzia(col,riga,col+2,riga,$07);
                     dec(i);
                     if i=19 then begin
                       dec(riga,2);
                       col:=2+4*18;
                     end
                     else dec(col,4);
                     if i=0 then begin
                       dec(chip);
                       i:=1;
                       col:=2;
                       if chip=0 then chip:=12;
                       case chip of
                       1: begin
                            riga:=6;
                            i:=25;
                            col:=2+4*5;
                          end;
                       2: begin
                            i:=5;
                            col:=2+4*4;
                            riga:=9;
                          end;
                       3: begin
                            i:=9;
                            col:=2+4*8;
                            riga:=12;
                          end;
                       4: begin
                            i:=20;
                            riga:=17;
                            col:=2;
                          end;
                       5..8: begin
                               i:=1;
                               col:=2;
                               riga:=15+chip;
                             end;
                       9..12: begin
                                i:=1;
                                col:=53;
                                riga:=11+chip;
                              end;
                       end;
                     end;
                   evidenzia(col,riga,col+2,riga,$70);
                   end;
             #77 : begin
                     evidenzia(col,riga,col+2,riga,$07);
                     inc(i);
                     if i=20 then begin
                       inc(riga,2);
                       col:=2;
                     end
                     else inc(col,4);
                     case chip of
                     1: if i>25 then begin
                          inc(chip);
                          col:=2;
                          riga:=9;
                          i:=1;
                        end;
                     2: if i>5 then begin
                          inc(chip);
                          col:=2;
                          riga:=12;
                          i:=1;
                        end;
                     3: if i>9 then begin
                          inc(chip);
                          col:=2;
                          riga:=15;
                          i:=1;
                        end;
                     4: if i>20 then begin
                          inc(chip);
                          col:=2;
                          riga:=20;
                          i:=1;
                        end;
                     5..7: begin
                          inc(chip);
                          inc(riga);
                          i:=1;
                        end;
                     8: begin
                          inc(chip);
                          riga:=20;
                          i:=1;
                        end;
                     9..11: begin
                          inc(chip);
                          inc(riga);
                          i:=1;
                        end;
                     12: begin
                          chip:=1;
                          riga:=4;
                          col:=2;
                          i:=1;
                        end;
                     end;
                     case chip of
                     9..12: col:=53;
                     5..8 : col:=2;
                     end;
                     evidenzia(col,riga,col+2,riga,$70);
                   end;
             #72,#73: begin
                        evidenzia(col,riga,col+2,riga,$07);
                        dec(chip);
                        i:=1;
                        case chip of
                        0: begin
                             riga:=23;
                             chip:=12;
                           end;
                        1: riga:=4;
                        2: riga:=9;
                        3: riga:=12;
                        4: riga:=15;
                        5,9 : riga:=20;
                        6,10: riga:=21;
                        7,11: riga:=22;
                        8: riga:=23;
                        end;
                        if chip in [9..12] then col:=53
                                           else col:=2;
                        evidenzia(col,riga,col+2,riga,$70);
                      end;
             #80,#81: begin
                        evidenzia(col,riga,col+2,riga,$07);
                        inc(chip);
                        i:=1;
                        case chip of
                        13: begin
                             riga:=4;
                             chip:=1;
                           end;
                        2: riga:=9;
                        3: riga:=12;
                        4: riga:=15;
                        5,9 : riga:=20;
                        6,10: riga:=21;
                        7,11: riga:=22;
                        8,12: riga:=23;
                        end;
                        if chip in [9..12] then col:=53
                                           else col:=2;
                        evidenzia(col,riga,col+2,riga,$70);
                      end;
           end;
      #13: begin
             gotoxy(col,riga);
             write('   ');
             gotoxy(col,riga);
             RipristinaCursore;
             case chip of
             1: read(CrtCRegs[i]);
             2: read(SequencerRegs[i]);
             3: read(GraphicsRegs[i]);
             4: read(AttributeRegs[i]);
             5: read(MOutPut);
             6: read(FeatureC);
             7: read(Graphic1);
             8: read(Graphic2);
             9: read(PELmask);
             10: read(PELaddread);
             11: read(PELaddwrite);
             12: read(PELdata);
             end;
             gotoxy(col,riga);
             case chip of
             1: write(CrtCRegs[i]:3);
             2: write(SequencerRegs[i]:3);
             3: write(GraphicsRegs[i]:3);
             4: write(AttributeRegs[i]:3);
             5: write(MOutPut:3);
             6: write(FeatureC:3);
             7: write(Graphic1:3);
             8: write(Graphic2:3);
             9: write(PELmask:3);
             10: write(PELaddread:3);
             11: write(PELaddwrite:3);
             12: write(PELdata:3);
             end;
             EliminaCursore;
             evidenzia(col,riga,col+2,riga,$70);
           end;
      '0': begin
             Schermo;
             VisualizzaValori;
             evidenzia(col,riga,col+2,riga,$70);
           end;
      end;
    end;
  end;

begin
  LeggiRegistri;
  RestoreCRTMode;
  EliminaCursore;
  clrscr;
  Schermo;
  VisualizzaValori;
  ModificaValori;
  RestoreGraphMode;
  RefreshDisplay;
  showmouseCursor;
end;



procedure OTNewWin.disegna;
begin
  inherited disegna;
end;




function OTNewWin.reactionevent(event:word):word;
const numprove=500;
      discost=8;

var count:word;
    colonne:integer;
    count2:word;
begin
  inherited reactionevent(event);
  if LastButtonPressed then
  case event of
  _MUOVI_OGGETTO_: begin
                     if not _delay then exit;
                     hidemousecursor;
                     with r do BitBtlVideoDC(abs(x1),abs(y1),abs(x1)+300,abs(y1)-00,dimX,dimY);
                     showmousecursor;
                   end;
  $9900: begin
           if not copia then exit;
           daSeg1aSeg2;
         end;
{  $9901: begin
           SettaRegistri;
           copia:=true;
         end;
}  $9941: begin
           hidemousecursor;
           for count:=8 to 400 do begin
               BarGoLIBW(count,10,10,200,8,1);
           end;
           showmousecursor;
         end;
  $9902: begin
           hidemousecursor;      {
           for count:=8 to 100 do }
           setwritemode($F1);
           setfillstyle(1,5);
                                  BarPat(13,10,615,409);
           setwritemode(0);
           showmousecursor;  end;
  $9940: begin  setfillstyle(1,10);
           hidemousecursor;
           setcolor(5);
           setwritemode(xorPut);
           setlinestyle(UserBitLn,$5555,1);
           for count:=1 to 400 do begin
             line(1,2,3,4);
             line(13,10+count-1,13+603-1,10+count-1);
             if count mod 2=0 then setlinestyle(UserBitLn,$5555,1)
                              else setlinestyle(UserBitLn,$aaaa,1);
           end;
           setwritemode(0);
           setlinestyle(UserBitLn,$FFFF,1);
           showmousecursor;
           (*
           Bar(11,11,410,210);

           {setviewport(10,10,40,40,true);
           }
           colonne:=600;
       { for count2:=1 to 9 do begin
       }    hidemousecursor;
           ResetTimer;
           StartTimer;
           for count:=0 to numprove div 2 do Bar_W(10,10,400,200,15,0);
           BlockTimer;
           RestoreCRTMode;
           WritelnTimerState;
           readkey;
           RestoreGraphMode;
           RefreshDisplay;
           showmousecursor;
           (*
           ResetTimer;
           StartTimer;
           for count:=0 to numprove div 2 do graph.Bar(0,25,colonne,125);
           BlockTimer;
           RestoreCRTMode;
           WritelnTimerState;
           readkey;
           RestoreGraphMode;
           RefreshDisplay;  {
           dec(colonne,60);
        end;                 }
           showmousecursor;
           *)
         end;
  $9903: begin
  (*
           ResetTimer;
           StartTimer;
           for count:=0 to numprove div 3 do begin
             {with r do barGolib(
               abs(x1)+count*discost,
               abs(y1)+count*discost,
               abs(x1)+count*discost+r.DimX+1,
               abs(y1)+count*discost+r.DimY+1,
               9,1);}

             with r do BitBtlMove(
               abs(x1)+count*discost,
               abs(y1)+count*discost,
               abs(x1)+discost+count*discost,
               abs(y1)+discost+count*discost,
               r.DimX+1,r.DimY+1);
           end;
           BlockTimer;
           RestoreCRTMode;
           WritelnTimerState;
           readkey;
           RestoreGraphMode;
           RefreshDisplay;
           showmousecursor;
  *)
         end;
  $9910: begin
           hidemousecursor;                           {
           for count:=0 to 20 do  begin
           for count2:=634 downto 639-439 do             begin}
           BitBtlVideoDC(633,190,625,0,1,200);    {      readkey;}
                           {barGoLIB(count,190,1,190,3,1);     end;}
        {   sound(70);
           delay(20);
           nosound;}
           showmousecursor;
         end;
  $9911: begin
           _f2:=not _f2;
           hidemousecursor;
           for count:=0 to 440 do
             BitBtlVideoDC(count,0,count,count+10,1,21);
           showmousecursor;
         end;
  $9921: begin
           _f2:=not _f2;
           hidemousecursor;
           for count:=0 to 440 do BitBtlVideoDC(count,0,170,190,100,21);
           showmousecursor;
         end;
  $9912: begin
           hidemousecursor;
           {for count:=r.y1 downto 0 do
           with r do BitBtlMove(abs(x1),count,abs(x1),count-1,r.DimX+1,r.DimY+1);
           }
           with r do BitBtlVideoDC(abs(x1),abs(y1),abs(x1)+8,abs(y1),r.DimX+1,r.DimY+1);
           showmousecursor;
         end;
  $9922: begin
           hidemousecursor;

           BitBtl(VideoDC,VideoDC,0,0,  0,0,160,160);
           BitBtl(VideoDC,VideoDC,0,0,160,0,160,160);
           BitBtl(VideoDC,VideoDC,0,0,320,0,160,160);
           BitBtl(VideoDC,VideoDC,0,0,480,0,160,160);

           BitBtl(VideoDC,VideoDC,0,0,  0,160,160,160);
           BitBtl(VideoDC,VideoDC,0,0,160,160,160,160);
           BitBtl(VideoDC,VideoDC,0,0,320,160,160,160);
           BitBtl(VideoDC,VideoDC,0,0,480,160,160,160);

           BitBtl(VideoDC,VideoDC,0,0,  0,320,160,160);
           BitBtl(VideoDC,VideoDC,0,0,160,320,160,160);
           BitBtl(VideoDC,VideoDC,0,0,320,320,160,160);
           BitBtl(VideoDC,VideoDC,0,0,480,320,160,160);

           showmousecursor;
         end;
  $9930: disegna;
  $9923: begin
           hidemousecursor;

           BitBtl(VideoDC,VideoDC,0,0,  0,0,216,240);
           BitBtl(VideoDC,VideoDC,0,0,216,0,216,240);
           BitBtl(VideoDC,VideoDC,0,0,432,0,208,240);

           BitBtl(VideoDC,VideoDC,0,0,  0,240,216,240);
           BitBtl(VideoDC,VideoDC,0,0,216,240,216,240);
           BitBtl(VideoDC,VideoDC,0,0,432,240,208,240);

           showmousecursor;
         end;
  end;
end;


{$define pattern1}

begin
  num1:=0;
  InizializzaGrafica(3,16);
{$ifdef pattern1}
  GLBPattern[1]:=$aa;
  GLBPattern[2]:=$55;
  GLBPattern[3]:=$aa;
  GLBPattern[4]:=$55;
  GLBPattern[5]:=$aa;
  GLBPattern[6]:=$55;
  GLBPattern[7]:=$aa;
  GLBPattern[8]:=$55;
{$else}

  GLBPattern[1]:=$ff;
  GLBPattern[2]:=$ff;
  GLBPattern[3]:=$ff;
  GLBPattern[4]:=$ff;
  GLBPattern[5]:=$ff;
  GLBPattern[6]:=$ff;
  GLBPattern[7]:=$ff;
  GLBPattern[8]:=$ff;
{$endif}

  hidemousecursor;
  FullBar(3);
  BackGroundColor:=3;
  showmousecursor;
  r.assign(639-439,479-238,639,479);
  win2.init(r,'Golib''95 (c) 1995 Ernesto CIANCIOTTA',FullIntestParam(true,true,true));
  win2.AddTitleObject( new(OPIncavo3dSoft, Init(Null_ID,NullRect,1,8)),_sud_,
                                        NewLayoutMetrics(
                                            NewLayout(LmLeft,InPixels,3)^,
                                            NewLayout(LmHeight,InPixels,4+IntestFont^.GetMaxDim)^,
                                            NewLayout(LmRight,InPixels,4)^,
                                            NewLayout(LmBottom,InPixels,4)^,
                                            LmParent,nil)
  );
  win2.PutOnDeskTop;

{  EvMoveRange.assign(0,0,639,479);
{  EvMoveDirection:=Vert;
}  r.assign(0,0,439,238);
  k.init(r,'Prove sulla manipolazione del Frame Buffer',FullIntestParam(true,true,true));
  k.AddTitleObject( new(OPIncavo3dSoft, Init(Null_ID,NullRect,1,8)),_sud_,
                                        NewLayoutMetrics(
                                            NewLayout(LmLeft,InPixels,3)^,
                                            NewLayout(LmHeight,InPixels,4+IntestFont^.GetMaxDim)^,
                                            NewLayout(LmRight,InPixels,4)^,
                                            NewLayout(LmBottom,InPixels,4)^,
                                            LmParent,nil)
  );
  {k.SetLimitSize(439,200);
  }
  k.PutOnDeskTop;
  l:=
  NewLayoutMetrics(
           NewLayout(LmLeft,InPixels,15)^,
           NewLayout(LmTop,InPixels,50)^,
           NewLayout(LmRight,InPixels,0)^,
           NewLayout(LmBottom,InPixels,0)^,
           LmOther,nil
         );
  k.AddOther(New(OPColori,Init(Null_ID,r)),nil);
  l:=
  NewLayoutMetrics(
           NewLayout(LmLeft,InPixels,50)^,
           NewLayout(LmTop,InPixels,30)^,
           NewLayout(LmWidth,InPixels,150)^,
           NewLayout(LmHeight,InPixels,24)^,
           LmOther,nil
         );
  k.AddOther(new(OPTextButton, Init($9900,r,'Copia normale (R)',true,1,8,0)),l);
  l:=
  NewLayoutMetrics(
           NewLayout(LmLeft,InPixels,50)^,
           NewLayout(LmTop,InPixels,55)^,
           NewLayout(LmWidth,InPixels,150)^,
           NewLayout(LmHeight,InPixels,24)^,
           LmOther,nil
         );
  k.AddOther(new(OPTextButton, Init($9930,r,'Refresh window',true,1,8,0)),l);
  l:=
  NewLayoutMetrics(
           NewLayout(LmLeft,InPixels,201)^,
           NewLayout(LmTop,InPixels,30)^,
           NewLayout(LmWidth,InPixels,29)^,
           NewLayout(LmHeight,InPixels,49)^,
           LmOther,nil
         );
  k.AddOther(new(OPTextButton, Init($9940,r,'BarG',true,1,8,0)),l);
  l:=
  NewLayoutMetrics(
           NewLayout(LmWidth,InPixels,150)^,
           NewLayout(LmTop,InPixels,30)^,
           NewLayout(LmRight,InPixels,50)^,
           NewLayout(LmHeight,InPixels,24)^,
           LmOther,nil
         );
  k.AddOther(new(OPTextButton, Init($9922,r,'Tappezza(1)',true,1,8,0)),l);
  l:=
  NewLayoutMetrics(
           NewLayout(LmWidth,InPixels,150)^,
           NewLayout(LmTop,InPixels,55)^,
           NewLayout(LmRight,InPixels,50)^,
           NewLayout(LmHeight,InPixels,24)^,
           LmOther,nil
         );
  k.AddOther(new(OPTextButton, Init($9923,r,'Tappezza(2)',true,1,8,0)),l);
  l:=
  NewLayoutMetrics(
           NewLayout(LmLeft,InPixels,50)^,
           NewLayout(LmTop,InPixels,100)^,
           NewLayout(LmWidth,InPixels,100)^,
           NewLayout(LmHeight,InPixels,15)^,
           LmOther,nil
         );
  k.AddOther(new(OPTextButton, Init($9902,r,'Barra con Pattern',true,1,8,0)),l);
  l:=
  NewLayoutMetrics(
           NewLayout(LmLeft,InPixels,50)^,
           NewLayout(LmTop,InPixels,120)^,
           NewLayout(LmWidth,InPixels,100)^,
           NewLayout(LmHeight,InPixels,15)^,
           LmOther,nil
         );
  k.AddOther(new(OPTextButton, Init($9910,r,'Trasferimento',true,1,8,0)),l);
  l:=
  NewLayoutMetrics(
           NewLayout(LmLeft,InPixels,50)^,
           NewLayout(LmTop,InPixels,140)^,
           NewLayout(LmWidth,InPixels,180)^,
           NewLayout(LmHeight,InPixels,15)^,
           LmOther,nil
         );
  k.AddOther(new(OPTextButton, Init($9912,r,'Con SHIFTR8D.ASM',true,1,8,0)),l);
  l:=
  NewLayoutMetrics(
           NewLayout(LmLeft,InPixels,160)^,
           NewLayout(LmTop,InPixels,120)^,
           NewLayout(LmWidth,InPixels,70)^,
           NewLayout(LmHeight,InPixels,15)^,
           LmOther,nil
         );
  k.AddOther(new(OPTextButton, Init($9911,r,'Specchio-1',true,1,8,0)),l);
  l:=
  NewLayoutMetrics(
           NewLayout(LmLeft,InPixels,240)^,
           NewLayout(LmTop,InPixels,120)^,
           NewLayout(LmWidth,InPixels,70)^,
           NewLayout(LmHeight,InPixels,15)^,
           LmOther,nil
         );
  k.AddOther(new(OPTextButton, Init($9921,r,'Specchio-2',true,1,8,0)),l);
  l:=
  NewLayoutMetrics(
           NewLayout(LmLeft,InPixels,240)^,
           NewLayout(LmTop,InPixels,140)^,
           NewLayout(LmWidth,InPixels,90)^,
           NewLayout(LmHeight,InPixels,15)^,
           LmOther,nil
         );
  k.AddOther(new(OPTextButton, Init($9941,r,'Scorrimento XOR',true,1,8,0)),l);
  l:=
  NewLayoutMetrics(
           NewLayout(LmLeft,InPixels,160)^,
           NewLayout(Lmtop,InPixels,100)^,
           NewLayout(LmWidth,InPixels,100)^,
           NewLayout(LmHeight,InPixels,15)^,
           LmOther,nil
         );
  k.AddOther(new(OPTextButton, Init($9903,r,'Test di velocit…',true,1,8,0)),l);
  l:=
  NewLayoutMetrics(
           NewLayout(LmLeft,InPixels,7)^,
           NewLayout(LmHeight,InPixels,15)^,
           NewLayout(LmWidth,InPixels,15)^,
           NewLayout(LmBottom,InPixels,5)^,
           LmOther,nil
         );
  k.AddOther(new(OPTextButton, Init($9901,r,'R',true,1,8,0)),l);

  LeggiRegistri;
  _CRTCRegs     :=CRTCRegs;
  _SequencerRegs:=SequencerRegs;
  _GraphicsRegs :=GraphicsRegs;
  _AttributeRegs:=AttributeRegs;
  _MOutPut:=MOutPut;
  _FeatureC:=FeatureC;
  _graphic1:=graphic1;
  _graphic2:=graphic2;

  copia:=false;
  new(transito);
  StartApplication;

  asm
    mov ah,$f6
    int 10h
  end;
end.