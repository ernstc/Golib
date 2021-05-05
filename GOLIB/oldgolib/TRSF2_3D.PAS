{ by ERNESTO CIANCIOTTA }

{*  Modulo per la trasformazioni Tridimensionali *}

unit Trsf2_3d;
{$X+}
interface

   const    AsseX : byte = 1;
            AsseY : byte = 2;
            AsseZ : byte = 3;

   type  Matr_4x4 = array[1..4,1..4] of real;
            Vet_4 = array[1..4] of real;
            Vet_3 = array[1..3] of real;
        PMatr_4x4 = ^Matr_4x4;
           PVet_4 = ^Vet_4;
           PVet_3 = ^Vet_3;

   procedure Moltiplica_4x4(var m1, m2, destinazione);
   procedure Addiziona_4x4(var m1, m2, destinazione);

   procedure Moltiplica_4_4x4(var vettore, matrice, destinazione);
   procedure Moltiplica_3_3x4(var vettore, matrice, destinazione);

   procedure Moltiplica_4x4_x_D(var m, d, destinazione);
   procedure Moltiplica_4x4_x_N(var m, n, destinazione);
   procedure Moltiplica_4x4_x_T(var m, t, destinazione);
   procedure Moltiplica_4x4_x_Rz(var m, rz, destinazione);
   procedure Moltiplica_4x4_x_Ry(var m, ry, destinazione);
   procedure Moltiplica_4x4_x_Rx(var m, rx, destinazione);
   procedure Moltiplica_4x4_x_S(var m, sc, destinazione);

   procedure Moltiplica_3x4(var m1, m2, destinazione);

   procedure Ribalta_(asse:byte; var m, destinazione);



implementation


   procedure Moltiplica_4x4(var m1, m2, destinazione);
     var mat1: Matr_4x4 absolute m1;
         mat2: Matr_4x4 absolute m2;
         buffer: Matr_4x4 absolute destinazione;
         i, j, k: byte;
         s: real;

     begin
       for i:=1 to 4 do
         for k:=1 to 4 do begin
           s:=0;
           for j:=1 to 4 do s:=mat2[j,i]*mat1[k,j]+s;
           buffer[k,i]:=s;
         end;
     end;

   procedure Addiziona_4x4(var m1, m2, destinazione);
     var mat1: Matr_4x4 absolute m1;
         mat2: Matr_4x4 absolute m2;
         buffer: Matr_4x4 absolute destinazione;
         i, j: byte;

     begin
       for i:=1 to 4 do
         for j:=1 to 4 do buffer[i,j]:=mat1[i,j]+mat2[i,j];
     end;

   { N.B. : Per questa funzione sono valide le costanti
            "UsaComeFunzione" e
            "NelPrimoVettore".                                     }

   procedure Moltiplica_4_4x4(var vettore, matrice, destinazione);
     var vet: Vet_4 absolute vettore;
         mat: Matr_4x4 absolute matrice;
         buffer: Vet_4 absolute destinazione;
         k, j: byte;
         s:real;

     begin
       for k:=1 to 4 do begin
         s:=0;
         for j:=1 to 4 do
           s:=vet[j]*mat[j,k]+s;
         buffer[k]:=s;
       end;
     end;

   procedure Moltiplica_3_3x4(var vettore, matrice, destinazione);
     var vet: Vet_3 absolute vettore;
         mat: Matr_4x4 absolute matrice;
         buffer: Vet_3 absolute destinazione;
         k, j: byte;
         s:real;

     begin
       for k:=1 to 3 do begin
         s:=0;
         for j:=1 to 3 do
           s:=vet[j]*mat[j,k]+s;
         buffer[k]:=s+mat[4,k];
       end;
     end;

   procedure Moltiplica_4x4_x_D(var m, d, destinazione);
     var mat1: Matr_4x4 absolute m;
         mat2: Matr_4x4 absolute d;
         buffer: Matr_4x4 absolute destinazione;
         i, j: byte;

     begin
       for i:=1 to 4 do
         for j:=1 to 4 do buffer[j,i]:=mat1[j,i]*mat2[i,i];
     end;

   procedure Moltiplica_4x4_x_N(var m, n, destinazione);
     var mat1: Matr_4x4 absolute m;
         mat2: Matr_4x4 absolute n;
         buffer: Matr_4x4 absolute destinazione;
         i, j: byte;

     begin
       for i:=1 to 2 do
         for j:=1 to 4 do buffer[j,i]:=mat1[j,i]*mat2[i,i];
     end;

   procedure Moltiplica_4x4_x_T(var m, t, destinazione);
     var mat1: Matr_4x4 absolute m;
         mat2: Matr_4x4 absolute t;
         buffer: Matr_4x4 absolute destinazione;
         i: byte;

     begin
       buffer:=mat1;
       for i:=1 to 3 do buffer[4,i]:=buffer[4,i]+mat2[4,i];
     end;

   procedure Moltiplica_4x4_x_Rz(var m, rz, destinazione);
     var mat1: Matr_4x4 absolute m;
         mat2: Matr_4x4 absolute rz;
         buffer: Matr_4x4 absolute destinazione;
         i, j, k: byte;
         s:real;

     begin
       buffer:=mat1;
       for i:=1 to 2 do
         for k:=1 to 4 do begin
           s:=0;
           for j:=1 to 2 do s:=mat2[j,i]*mat1[k,j]+s;
           buffer[k,i]:=s;
         end;
     end;

   procedure Moltiplica_4x4_x_Ry(var m, ry, destinazione);
     var mat1: Matr_4x4 absolute m;
         mat2: Matr_4x4 absolute ry;
         buffer: Matr_4x4 absolute destinazione;
         i, j, k: byte;
         s:real;

     begin
       buffer:=mat1;
       for i:=1 to 2 do
         for k:=1 to 4 do begin
           s:=0;
           for j:=1 to 2 do s:=mat2[j*2-1,i*2-1]*mat1[k,j*2-1]+s;
           buffer[k,i*2-1]:=s;
         end;
     end;

   procedure Moltiplica_4x4_x_Rx(var m, rx, destinazione);
     var mat1: Matr_4x4 absolute m;
         mat2: Matr_4x4 absolute rx;
         buffer: Matr_4x4 absolute destinazione;
         i, j, k: byte;
         s:real;

     begin
       buffer:=mat1;
       for i:=2 to 3 do
         for k:=1 to 4 do begin
           s:=0;
           for j:=2 to 3 do s:=mat2[j,i]*mat1[k,j]+s;
           buffer[k,i]:=s;
         end;
     end;

   procedure Moltiplica_4x4_x_S(var m, sc, destinazione);
     var mat1: Matr_4x4 absolute m;
         mat2: Matr_4x4 absolute sc;
         buffer: Matr_4x4 absolute destinazione;
         i, k: byte;

     begin
       buffer:=mat1;
       for i:=1 to 3 do
         for k:=1 to 4 do buffer[k,i]:=mat1[k,i]*mat2[i,i];
     end;

   procedure Moltiplica_3x4(var m1, m2, destinazione);
     var mat1: Matr_4x4 absolute m1;
         mat2: Matr_4x4 absolute m2;
         buffer: Matr_4x4 absolute destinazione;
         i, j, k: byte;
         s: real;

     begin
       for i:=1 to 3 do
         for k:=1 to 4 do begin
           s:=0;
           for j:=1 to 4 do s:=mat2[j,i]*mat1[k,j]+s;
           buffer[k,i]:=s;
         end;
     end;

   procedure Ribalta_(asse:byte; var m, destinazione);
     var mat:Matr_4x4 absolute m;
         buffer:Matr_4x4 absolute destinazione;
         i, j, k: byte;
         s: real;

     begin
       buffer:=mat;
       for i:=1 to 4 do buffer[i,asse]:=-buffer[i,asse];
     end;

end.