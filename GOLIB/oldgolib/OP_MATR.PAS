{ by ERNESTO CIANCIOTTA }
unit Op_Matr;
interface
{$E+,N+}

   const
         shortintType:byte = 129;
             byteType:byte =   1;
          integerType:byte = 130;
             wordType:byte =   2;
          longintType:byte =   4;
             realType:byte =   6;
           singleType:byte = 132;
           doubleType:byte =   8;
         extendedType:byte =  10;
             compType:byte = 136;

   type
        AllNumericType = record
                           case byte of
                             1:  (t1:byte);
                           129:  (t_1:shortint);
                             2:  (t2:word);
                           130:  (t_2:integer);
                             4:  (t4:longint);
                           132:  (t_4:single);
                             6:  (t6:real);
                             8:  (t8:double);
                           136:  (t_8:comp);
                            10:  (t10:extended);
                         end;



   procedure WriteNum( var buffer:AllNumericType; Tipo:byte;
                       formattazione:byte );

   { Procedura per la viasualizzazzione di una qualsiasi matrice numerica }
   procedure VisMat(var m; DimX,DimY, dimU:word; formattazione:byte);

   procedure Moltiplica(var m1, m2, ris; DimX1,DimY1,DimX2,DimY2:word;
                            Tipo_m1, Tipo_m2, Tipo_ris:byte);
   procedure Addiziona(var m1, m2, ris; DimX,DimY:word;
                           Tipo_m1, Tipo_m2, Tipo_ris:byte);


implementation

   uses DinMatr;

   function RealConverted(buffer: AllNumericType; tipo:byte):Extended;
     begin
       case tipo of
        6: RealConverted:=buffer.t6;
        8: RealConverted:=buffer.t8;
       10: RealConverted:=buffer.t10;
       end;
     end;

   function OrdinalConverted(buffer: AllNumericType; tipo:byte):longint;
     begin
        case tipo of
        1: OrdinalConverted:=buffer.t1;
        2: OrdinalConverted:=buffer.t2;
        4: OrdinalConverted:=buffer.t4;
       end;
     end;




   procedure WriteNum( var buffer:AllNumericType; Tipo:byte;
                       formattazione:byte );
     begin
       case Tipo of
         1:  write(buffer.t1:formattazione);
       129:  write(buffer.t_1:formattazione);
         2:  write(buffer.t2:formattazione);
       130:  write(buffer.t_2:formattazione);
         4:  write(buffer.t4:formattazione);
       132:  write(buffer.t_4:formattazione:2);    {  I numeri reali        }
         6:  write(buffer.t6:formattazione:2);     {  vengono visualizzati  }
         8:  write(buffer.t8:formattazione:2);     {  con sole due cifre    }
       136:  write(buffer.t_8:formattazione:2);    {  decimali              }
        10:  write(buffer.t10:formattazione:2);
       end;
     end;

   procedure VisMat(var m; DimX,DimY, dimU:word; formattazione:byte);
     var buffer:AllNumericType;
         i,j:word;
         mat:OTDinamicMatrox;
     begin
       mat.init(1,1,DimX,DimY,dimU and $7F,@m);
       for j:=1 to DimY do begin
         for i:=1 to DimX do begin
           mat.FastOut(i,j,buffer);
           WriteNum(buffer,dimU,formattazione);
         end;
         writeln;
       end;
     end;

   procedure Moltiplica(var m1, m2, ris; DimX1,DimY1,DimX2,DimY2:word;
                            Tipo_m1, Tipo_m2, Tipo_ris:byte);
     var mat1, mat2, matR: OTDinamicMatrox;
         i,j, k:word;
         s:real;
         buf1, buf2, bufR: AllNumericType;
     begin
       if DimX1<>DimY2 then halt(10101);

       Tipo_m1:=Tipo_m1 and $7F;
       Tipo_m2:=Tipo_m2 and $7F;
       Tipo_ris:=Tipo_ris and $7F;

       if ((Tipo_ris<Tipo_m1) or (Tipo_ris<Tipo_m2)) or
          ((Tipo_ris<6) and ((Tipo_m1>=6) or (Tipo_m2>=6)))
       then halt(10102);
       mat1.Init(1,DimX1,1,DimY1,Tipo_m1,@m1);
       mat2.Init(1,DimX2,1,DimY2,Tipo_m2,@m2);
       matR.Init(1,DimX2,1,DimY1,Tipo_ris,@ris);
       for i:=1 to DimY1 do
         for k:=1 to DimX2 do begin
           bufR.t10:=0;
           for j:=1 to DimX1 do begin
             mat1.FastOut(j,i,buf1);
             mat2.Fastout(k,j,buf2);
             case Tipo_ris of
              1: bufR.t1:=OrdinalConverted(buf1,Tipo_m1)*
                          OrdinalConverted(buf2,Tipo_m2)+bufR.t1;
              2: bufR.t2:=OrdinalConverted(buf1,Tipo_m1)*
                          OrdinalConverted(buf2,Tipo_m2)+bufR.t2;
              4: bufR.t4:=OrdinalConverted(buf1,Tipo_m1)*
                          OrdinalConverted(buf2,Tipo_m2)+bufR.t4;
              6: bufR.t6:=RealConverted(buf1,Tipo_m1)*
                          RealConverted(buf2,Tipo_m2)+bufR.t6;
              8: bufR.t8:=RealConverted(buf1,Tipo_m1)*
                          RealConverted(buf2,Tipo_m2)+bufR.t8;
             10: bufR.t10:=RealConverted(buf1,Tipo_m1)*
                           RealConverted(buf2,Tipo_m2)+bufR.t10;
             end;
           end;
           case Tipo_ris of
            1: matR.FastIn(bufR.t1,k,i);
            2: matR.FastIn(bufR.t2,k,i);
            4: matR.FastIn(bufR.t4,k,i);
            6: matR.FastIn(bufR.t6,k,i);
            8: matR.FastIn(bufR.t8,k,i);
           10: matR.FastIn(bufR.t10,k,i);
           end;
         end;
     end;

   procedure Addiziona(var m1, m2, ris; DimX,DimY:word;
                           Tipo_m1, Tipo_m2, Tipo_ris:byte);
     var mat1, mat2, matR: OTDinamicMatrox;
         i,j:word;
         buf1, buf2, bufR: AllNumericType;

     begin
       if ((Tipo_ris<Tipo_m1) or (Tipo_ris<Tipo_m2)) or
          ((Tipo_ris<6) and ((Tipo_m1>=6) or (Tipo_m2>=6)))
       then halt(10102);
       mat1.Init(1,DimX,1,DimY,Tipo_m1 and $7F,@m1);
       mat2.Init(1,DimX,1,DimY,Tipo_m2 and $7F,@m2);
       matR.Init(1,DimX,1,DimY,Tipo_ris and $7F,@ris);
       for i:=1 to DimX do
         for j:=1 to DimY do begin
           mat1.FastOut(i,j,buf1);
           mat2.FastOut(i,j,buf2);
           case Tipo_ris of
            1: begin
                 bufR.t1:=OrdinalConverted(buf1,Tipo_m1)+
                          OrdinalConverted(buf2,Tipo_m2);
                 matR.FastIn(bufR.t1,i,j);
               end;
            2: begin
                 bufR.t2:=OrdinalConverted(buf1,Tipo_m1)+
                          OrdinalConverted(buf2,Tipo_m2);
                 matR.FastIn(bufR.t2,i,j);
               end;
            4: begin
                 bufR.t4:=OrdinalConverted(buf1,Tipo_m1)+
                          OrdinalConverted(buf2,Tipo_m2);
                 matR.FastIn(bufR.t4,i,j);
               end;
            6: begin
                 bufR.t6:=RealConverted(buf1,Tipo_m1)+
                          RealConverted(buf2,Tipo_m2);
                 matR.FastIn(bufR.t6,i,j);
               end;
            8: begin
                 bufR.t8:=RealConverted(buf1,Tipo_m1)+
                          RealConverted(buf2,Tipo_m2);
                 matR.FastIn(bufR.t8,i,j);
               end;
           10: begin
                 bufR.t10:=RealConverted(buf1,Tipo_m1)+
                           RealConverted(buf2,Tipo_m2);
                 matR.FastIn(bufR.t10,i,j);
               end;
           end;
         end;
     end;


end.