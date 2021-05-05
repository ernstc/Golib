{ by ERNESTO CIANCIOTTA }
{$D+}
{$L+}
program Verifica_Esempio_Libro;
uses crt,graph,graftool,Trasf_3D,Op_Matr;
const
      NumPunti=12;

      cubo3d: array[1..NumPunti,1..3] of real=
                ((-1, 1,-1),
                 ( 1, 1,-1),
                 ( 1,-1,-1),
                 (-1,-1,-1),
                 (-1, 1, 1),
                 ( 1, 1, 1),
                 ( 1,-1, 1),
                 (-1,-1, 1),
                 ( 0, 0, 0),
                 ( 3, 0, 0),
                 ( 0, 3, 0),
                 ( 0, 0, 3));

  tx : Matr_4x4=
           ((   1,   0,   0,   0),
            (   0,   1,   0,   0),
            (   0,   0,   1,   0),
            (   0,   0,   0,   1));

  t1 : Matr_4x4=
           ((   1,   0,   0,   0),
            (   0,   1,   0,   0),
            (   0,   0,   1,   0),
            (  -6,  -8,-7.5,   1));

  t2 : Matr_4x4=
           ((   1,   0,   0,   0),
            (   0,   0,  -1,   0),
            (   0,   1,   0,   0),
            (   0,   0,   0,   1));

  t3 : Matr_4x4=
           ((-0.8,   0, 0.6,   0),
            (   0,   1,   0,   0),
            (-0.6,   0,-0.8,   0),
            (   0,   0,   0,   1));


  t4 : Matr_4x4=
           ((   1,   0,   0,   0),
            (   0, 0.8, 0.6,   0),
            (   0,-0.6, 0.8,   0),
            (   0,   0,   0,   1));

  t5 : Matr_4x4=
           ((   1,   0,   0,   0),
            (   0,   1,   0,   0),
            (   0,   0,  -1,   0),
            (   0,   0,   0,   1));

   n : Matr_4x4=
           ((   4,   0,   0,   0),
            (   0,   4,   0,   0),
            (   0,   0,   1,   0),
            (   0,   0,   0,   1));


var Vsx,Vcx,Vsy,Vcy:word;
    cubo:array[1..NumPunti,1..3] of real;
    VN:Matr_4x4;
    ty: Matr_4x4;
    tz: Matr_4x4;



function Xs(indice:byte):integer;
  begin
    Xs:=round(Vsx*(cubo[indice,1]/cubo[indice,3])+Vcx);
  end;

function Ys(indice:byte):integer;
  begin
    Ys:=round(Vsx*(cubo[indice,2]/cubo[indice,3])+Vcx);
  end;

procedure Crea_VN;
  begin
    Moltiplica_4x4_x_Ry(tx,ty,VN);
    Moltiplica_4x4_x_Rz(VN,tz,NellaPrimaMatrice);
    Moltiplica_4x4_x_T(VN,t1,NellaPrimaMatrice);
    Moltiplica_4x4_x_Rx(VN,t2,NellaPrimaMatrice);
    Moltiplica_4x4_x_Ry(VN,t3,NellaPrimaMatrice);
    Moltiplica_4x4_x_Rx(VN,t4,NellaPrimaMatrice);
    Ribalta_(AsseZ,VN, NellaPrimaMatrice);
    Moltiplica_4x4_x_N(VN,n,NellaPrimaMatrice);
    Ribalta_(AsseY,VN, NellaPrimaMatrice);
  end;

procedure Trasforma_Cubo;
  var i:word;
  begin
    Crea_VN;
    for i:=1 to 12 do Moltiplica_3_3x4(cubo3d[i],VN,cubo[i]);
  end;

procedure DisegnaCubo;
  var i:byte;
  begin
    SetColor(white);
    line(Xs(8),Ys(8),Xs(7),Ys(7));
    line(Xs(7),Ys(7),Xs(6),Ys(6));

    line(Xs(6),Ys(6),Xs(5),Ys(5));
    line(Xs(5),Ys(5),Xs(8),Ys(8));

    line(Xs(4),Ys(4),Xs(3),Ys(3));
    line(Xs(3),Ys(3),Xs(2),Ys(2));

    line(Xs(2),Ys(2),Xs(1),Ys(1));
    line(Xs(1),Ys(1),Xs(4),Ys(4));

    line(Xs(8),Ys(8),Xs(4),Ys(4));
    line(Xs(7),Ys(7),Xs(3),Ys(3));

    line(Xs(6),Ys(6),Xs(2),Ys(2));
    line(Xs(5),Ys(5),Xs(1),Ys(1));

    SetColor(red+8);
    line(Xs(9),Ys(9),Xs(10),Ys(10));
    setcolor(blue+8);
    line(Xs(9),Ys(9),Xs(11),Ys(11));
    setColor(yellow);
    line(Xs(9),Ys(9),Xs(12),Ys(12));
  end;

procedure Set_tx(gradi:real);
  begin
    tx[2,2]:=cos(gradi);
    tx[2,3]:=-sin(gradi);
    tx[3,2]:=sin(gradi);
    tx[3,3]:=cos(gradi);
  end;

procedure Set_ty(gradi:real);
  begin
    ty[1,1]:=cos(gradi);
    ty[1,3]:=sin(gradi);
    ty[3,1]:=-sin(gradi);
    ty[3,3]:=cos(gradi);
  end;

procedure Set_tz(gradi:real);
  begin
    tz[1,1]:=cos(gradi);
    tz[1,2]:=-sin(gradi);
    tz[2,1]:=sin(gradi);
    tz[2,2]:=cos(gradi);
  end;

const p:array[false..true] of byte=(1,0);
var cambiato,tt,gg:boolean;
    p_ch, ch:char;
    g1,g2,g3:real;
    piu:real;

begin
  ty:=tx;
  tz:=tx;
  clrscr;
  Trasforma_Cubo;
  visMat(VN,4,4,realType,8);
  writeln;
  VisMat(cubo,3,8,realType,8);
  writeln;
  writeln('Demo 3D');
  writeln;
  writeln('Premi un tasto per continuare e poi usa il tastirino numerico e il tasto ESC peruscire. Usa anche i tasti + e -.');
  ch:=readkey;

  InizializzaGrafica(2,16);
  tt:=false;
  SetVisualPage(p[not tt]);
  vsx:=399;    vsx:=160;
  vcx:=399;    vcx:=100;
  vsy:=299;    vsy:=99;
  vcy:=299;    vcy:=99;
  g1:=0; g2:=0; g3:=0; piu:=0.05;
  ch:='5';
  cambiato:=false;
  disegnaCubo;
  repeat
    SetActivePage(p[tt]);
    cleardevice;               {
    if cambiato then begin     }
      DisegnaCubo;             {
      ch:=readkey;
      cambiato:=false;
    end;                       }
    SetVisualPage(p[tt]);
    tt:=not tt;
    if keypressed then begin
      p_ch:=ch;
      ch:=readkey;
    end;
    case ch of
    '8': inc(Vsx);
    '2': dec(Vsx);
    '4': dec(Vcx);
    '6': inc(Vcx);
    '5': ;      {
    's': cubo[1,1]:=cubo[1,1]+1;
    'a': cubo[1,1]:=cubo[1,1]-1;
    'w': cubo[1,2]:=cubo[1,2]+1;
    'z': cubo[1,2]:=cubo[1,2]-1;
    'f': cubo[2,1]:=cubo[2,1]+1;
    'd': cubo[2,1]:=cubo[2,1]-1;
    'r': cubo[2,2]:=cubo[2,2]+1;
    'c': cubo[2,2]:=cubo[2,2]-1;
    'h': cubo[3,1]:=cubo[3,1]+1;
    'g': cubo[3,1]:=cubo[3,1]-1;
    'y': cubo[3,2]:=cubo[3,2]+1;
    'b': cubo[3,2]:=cubo[3,2]-1;
    'k': cubo[4,1]:=cubo[4,1]+1;
    'j': cubo[4,1]:=cubo[4,1]-1;
    'i': cubo[4,2]:=cubo[4,2]+1;
    'm': cubo[4,2]:=cubo[4,2]-1;
    '•': cubo[8,1]:=cubo[8,1]+1;
    'l': cubo[8,1]:=cubo[8,1]-1;
    'p': cubo[8,3]:=cubo[8,3]+1;
    '.': cubo[8,3]:=cubo[8,3]-1;
    }
    '7': begin
           piu:=-piu;
           ch:=p_ch;
         end;
    '+': begin
           piu:=piu+0.01;
           ch:=p_ch;
         end;
    '-': begin
           piu:=piu-0.01;
           ch:=p_ch;
         end;
    '1': begin
           g1:=g1+piu;
           cambiato:=true;
         end;
    '3': begin
           g3:=g3+piu;
           cambiato:=true;
         end;
    '9': begin
           g2:=g2+piu;
           cambiato:=true;
         end;
    end;
    if cambiato then begin
      set_tx(g1);
      set_ty(g2);
      set_tz(g3);
      trasforma_cubo;        {
      disegnacubo;           }
    end;
    if Vsx=0 then Vsx:=1;
    if Vcx=0 then Vcx:=1;
  until ch=#27;
  InizializzaGrafica(3,16);
  Vsx:=399;  Vcx:=359;
  DisegnaCubo;
  ch:=readkey;
  closeGraph;
  textmode(3)
end.