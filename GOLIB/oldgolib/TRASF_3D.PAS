{ by ERNESTO CIANCIOTTA }

{*  Modulo per la trasformazioni Tridimensionali *}

unit Trasf_3d;
{$X+}
interface

   const     UsaComeFunzione: string[10] = '$Funzione$';
           NellaPrimaMatrice: string[10] = '$InMatr_1$';
         NellaSecondaMatrice: string[10] = '$InMatr_2$';
             NelPrimoVettore: string[10] = '$InVet_1_$';

            AsseX : byte = 1;
            AsseY : byte = 2;
            AsseZ : byte = 3;


   type  Matr_4x4 = array[1..4,1..4] of real;
            Vet_4 = array[1..4] of real;
            Vet_3 = array[1..3] of real;
        PMatr_4x4 = ^Matr_4x4;
           PVet_4 = ^Vet_4;
           PVet_3 = ^Vet_3;

   function Moltiplica_4x4(var m1, m2, destinazione):PMatr_4x4;
   function Addiziona_4x4(var m1, m2, destinazione):PMatr_4x4;

   function Moltiplica_4_4x4(var vettore, matrice, destinazione):PVet_4;
   function Moltiplica_3_3x4(var vettore, matrice, destinazione):PVet_3;

   function Moltiplica_4x4_x_D(var m, d, destinazione):PMatr_4x4;
   function Moltiplica_4x4_x_N(var m, n, destinazione):PMatr_4x4;
   function Moltiplica_4x4_x_T(var m, t, destinazione):PMatr_4x4;
   function Moltiplica_4x4_x_Rz(var m, rz, destinazione):PMatr_4x4;
   function Moltiplica_4x4_x_Ry(var m, ry, destinazione):PMatr_4x4;
   function Moltiplica_4x4_x_Rx(var m, rx, destinazione):PMatr_4x4;
   function Moltiplica_4x4_x_S(var m, sc, destinazione):PMatr_4x4;

   function Moltiplica_3x4(var m1, m2, destinazione):PMatr_4x4;

   function Ribalta_(asse:byte; var m, destinazione):PMatr_4x4;



implementation

   procedure PuntaDati(var m1, m2, m3:Matr_4x4; buffer:PMatr_4x4);
     var stringa:string[10] absolute m3;
     begin
       if stringa=NellaPrimaMatrice then
         begin
           m1:=buffer^;
           dispose(buffer);
         end
       else if stringa=NellaSecondaMatrice then
         begin
           m2:=buffer^;
           dispose(buffer);
         end
       else begin
              m3:=buffer^;
              dispose(buffer);
       end;
     end;

   function Moltiplica_4x4(var m1, m2, destinazione):PMatr_4x4;
     var mat1: Matr_4x4 absolute m1;
         mat2: Matr_4x4 absolute m2;
         matR: Matr_4x4 absolute destinazione;
         buffer: PMatr_4x4;
         i, j, k: byte;
         s: real;
         stringa: string[10] absolute destinazione;

     begin
       new(buffer);
       for i:=1 to 4 do
         for k:=1 to 4 do begin
           s:=0;
           for j:=1 to 4 do s:=mat2[j,i]*mat1[k,j]+s;
           buffer^[k,i]:=s;
         end;
       if stringa=UsaComeFunzione then Moltiplica_4x4:=buffer
       else begin
         Moltiplica_4x4:=nil;
         PuntaDati(mat1,mat2,matR,buffer);
       end;
     end;

   function Addiziona_4x4(var m1, m2, destinazione):PMatr_4x4;
     var mat1: Matr_4x4 absolute m1;
         mat2: Matr_4x4 absolute m2;
         matR: Matr_4x4 absolute destinazione;
         buffer: PMatr_4x4;
         i, j: byte;
         stringa: string[10] absolute destinazione;
     begin
       new(buffer);
       for i:=1 to 4 do
         for j:=1 to 4 do buffer^[i,j]:=mat1[i,j]+mat2[i,j];
       if stringa=UsaComeFunzione then Addiziona_4x4:=buffer
       else begin
         Addiziona_4x4:=nil;
         PuntaDati(mat1,mat2,matR,buffer);
       end;
     end;

   { N.B. : Per questa funzione sono valide le costanti
            "UsaComeFunzione" e
            "NelPrimoVettore".                                     }

   function Moltiplica_4_4x4(var vettore, matrice, destinazione):PVet_4;
     var vet: Vet_4 absolute vettore;
         mat: Matr_4x4 absolute matrice;
         vetR: Vet_4 absolute destinazione;
         buffer: PVet_4;
         k, j: byte;
         s:real;
         stringa: string[10] absolute destinazione;

     begin
       new(buffer);
       for k:=1 to 4 do begin
         s:=0;
         for j:=1 to 4 do
           s:=vet[j]*mat[j,k]+s;
         buffer^[k]:=s;
       end;
       Moltiplica_4_4x4:=nil;
       if stringa=UsaComeFunzione then Moltiplica_4_4x4:=buffer
       else if stringa=NelPrimoVettore then
         begin
           vet:=buffer^;
           dispose(buffer);
         end
       else begin
         vetR:=buffer^;
         dispose(buffer);
       end;
     end;

   function Moltiplica_3_3x4(var vettore, matrice, destinazione):PVet_3;
     var vet: Vet_3 absolute vettore;
         mat: Matr_4x4 absolute matrice;
         vetR: Vet_3 absolute destinazione;
         buffer: PVet_3;
         k, j: byte;
         s:real;
         stringa: string[10] absolute destinazione;

     begin
       new(buffer);
       for k:=1 to 3 do begin
         s:=0;
         for j:=1 to 3 do
           s:=vet[j]*mat[j,k]+s;
         buffer^[k]:=s+mat[4,k];
       end;
       Moltiplica_3_3x4:=nil;
       if stringa=UsaComeFunzione then Moltiplica_3_3x4:=buffer
       else if stringa=NelPrimoVettore then
         begin
           vet:=buffer^;
           dispose(buffer);
         end
       else begin
         vetR:=buffer^;
         dispose(buffer);
       end;
     end;

   function Moltiplica_4x4_x_D(var m, d, destinazione):PMatr_4x4;
     var mat1: Matr_4x4 absolute m;
         mat2: Matr_4x4 absolute d;
         matR: Matr_4x4 absolute destinazione;
         buffer: PMatr_4x4;
         i, j: byte;
         stringa: string[10] absolute destinazione;

     begin
       new(buffer);
       for i:=1 to 4 do
         for j:=1 to 4 do buffer^[j,i]:=mat1[j,i]*mat2[i,i];
       if stringa=UsaComeFunzione then Moltiplica_4x4_x_D:=buffer
       else begin
         Moltiplica_4x4_x_D:=nil;
         PuntaDati(mat1,mat2,matR,buffer);
       end;
     end;

   function Moltiplica_4x4_x_N(var m, n, destinazione):PMatr_4x4;
     var mat1: Matr_4x4 absolute m;
         mat2: Matr_4x4 absolute n;
         matR: Matr_4x4 absolute destinazione;
         buffer: PMatr_4x4;
         i, j: byte;
         stringa: string[10] absolute destinazione;

     begin
       new(buffer);
       for i:=1 to 2 do
         for j:=1 to 4 do buffer^[j,i]:=mat1[j,i]*mat2[i,i];
       if stringa=UsaComeFunzione then Moltiplica_4x4_x_N:=buffer
       else begin
         Moltiplica_4x4_x_N:=nil;
         PuntaDati(mat1,mat2,matR,buffer);
       end;
     end;

   function Moltiplica_4x4_x_T(var m, t, destinazione):PMatr_4x4;
     var mat1: Matr_4x4 absolute m;
         mat2: Matr_4x4 absolute t;
         matR: Matr_4x4 absolute destinazione;
         buffer: PMatr_4x4;
         i: byte;
         stringa: string[10] absolute destinazione;

     begin
       new(buffer);
       buffer^:=mat1;
       for i:=1 to 3 do buffer^[4,i]:=buffer^[4,i]+mat2[4,i];
       if stringa=UsaComeFunzione then Moltiplica_4x4_x_T:=buffer
       else begin
         Moltiplica_4x4_x_T:=nil;
         PuntaDati(mat1,mat2,matR,buffer);
       end;
     end;

   function Moltiplica_4x4_x_Rz(var m, rz, destinazione):PMatr_4x4;
     var mat1: Matr_4x4 absolute m;
         mat2: Matr_4x4 absolute rz;
         matR: Matr_4x4 absolute destinazione;
         buffer: PMatr_4x4;
         i, j, k: byte;
         s:real;
         stringa: string[10] absolute destinazione;

     begin
       new(buffer);
       buffer^:=mat1;
       for i:=1 to 2 do
         for k:=1 to 4 do begin
           s:=0;
           for j:=1 to 2 do s:=mat2[j,i]*mat1[k,j]+s;
           buffer^[k,i]:=s;
         end;
       if stringa=UsaComeFunzione then Moltiplica_4x4_x_Rz:=buffer
       else begin
         Moltiplica_4x4_x_Rz:=nil;
         PuntaDati(mat1,mat2,matR,buffer);
       end;
     end;

   function Moltiplica_4x4_x_Ry(var m, ry, destinazione):PMatr_4x4;
     var mat1: Matr_4x4 absolute m;
         mat2: Matr_4x4 absolute ry;
         matR: Matr_4x4 absolute destinazione;
         buffer: PMatr_4x4;
         i, j, k: byte;
         s:real;
         stringa: string[10] absolute destinazione;

     begin
       new(buffer);
       buffer^:=mat1;
       for i:=1 to 2 do
         for k:=1 to 4 do begin
           s:=0;
           for j:=1 to 2 do s:=mat2[j*2-1,i*2-1]*mat1[k,j*2-1]+s;
           buffer^[k,i*2-1]:=s;
         end;
       if stringa=UsaComeFunzione then Moltiplica_4x4_x_Ry:=buffer
       else begin
         Moltiplica_4x4_x_Ry:=nil;
         PuntaDati(mat1,mat2,matR,buffer);
       end;
     end;

   function Moltiplica_4x4_x_Rx(var m, rx, destinazione):PMatr_4x4;
     var mat1: Matr_4x4 absolute m;
         mat2: Matr_4x4 absolute rx;
         matR: Matr_4x4 absolute destinazione;
         buffer: PMatr_4x4;
         i, j, k: byte;
         s:real;
         stringa: string[10] absolute destinazione;

     begin
       new(buffer);
       buffer^:=mat1;
       for i:=2 to 3 do
         for k:=1 to 4 do begin
           s:=0;
           for j:=2 to 3 do s:=mat2[j,i]*mat1[k,j]+s;
           buffer^[k,i]:=s;
         end;
       if stringa=UsaComeFunzione then Moltiplica_4x4_x_Rx:=buffer
       else begin
         Moltiplica_4x4_x_Rx:=nil;
         PuntaDati(mat1,mat2,matR,buffer);
       end;
     end;

   function Moltiplica_4x4_x_S(var m, sc, destinazione):PMatr_4x4;
     var mat1: Matr_4x4 absolute m;
         mat2: Matr_4x4 absolute sc;
         matR: Matr_4x4 absolute destinazione;
         buffer: PMatr_4x4;
         i, k: byte;
         stringa: string[10] absolute destinazione;

     begin
       new(buffer);
       buffer^:=mat1;
       for i:=1 to 3 do
         for k:=1 to 4 do buffer^[k,i]:=mat1[k,i]*mat2[i,i];
       if stringa=UsaComeFunzione then Moltiplica_4x4_x_S:=buffer
       else begin
         Moltiplica_4x4_x_S:=nil;
         PuntaDati(mat1,mat2,matR,buffer);
       end;
     end;

   function Moltiplica_3x4(var m1, m2, destinazione):PMatr_4x4;
     var mat1: Matr_4x4 absolute m1;
         mat2: Matr_4x4 absolute m2;
         matR: Matr_4x4 absolute destinazione;
         buffer: PMatr_4x4;
         i, j, k: byte;
         s: real;
         stringa: string[10] absolute destinazione;

     begin
       new(buffer);
       for i:=1 to 3 do
         for k:=1 to 4 do begin
           s:=0;
           for j:=1 to 4 do s:=mat2[j,i]*mat1[k,j]+s;
           buffer^[k,i]:=s;
         end;
       if stringa=UsaComeFunzione then Moltiplica_3x4:=buffer
       else begin
         Moltiplica_3x4:=nil;
         PuntaDati(mat1,mat2,matR,buffer);
       end;
     end;

   function Ribalta_(asse:byte; var m, destinazione):PMatr_4x4;
     var mat:Matr_4x4 absolute m;
         matR:Matr_4x4 absolute destinazione;
         buffer: PMatr_4x4;
         i, j, k: byte;
         s: real;
         stringa: string[10] absolute destinazione;
     begin
       new(buffer);
       buffer^:=mat;
       for i:=1 to 4 do buffer^[i,asse]:=-buffer^[i,asse];
       Ribalta_:=nil;
       if stringa=UsaComeFunzione then Ribalta_:=buffer
       else if stringa=NellaPrimaMatrice then
         begin
           mat:=buffer^;
           dispose(buffer);
         end
       else begin
         matR:=buffer^;
         dispose(buffer);
       end;
     end;

end.