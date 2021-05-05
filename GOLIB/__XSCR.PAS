{ Ernesto CIANCIOTTA Productions }

{*************************************************************************}
{*                                                                       *}
{*  Modulo contenente gli oggetti demo derivati dagli scrollers estesi   *}
{*  della libreria GOLIB 1.0.                                            *}
{*                                                                       *}
{*  Scritto con Turbo Pascal 7.0                                         *}
{*                                                                       *}
{*************************************************************************}

{$D-}
{$L-}


UNIT __XSCR;


INTERFACE

  uses
        dos,
        codici,
        files,
        utility,
        mouse,
        graftool,
        fonts,
        bitmaps,
        resman,
        xlist;


type

       OPXXFileList = ^OTXXFileList;
       OTXXFileList = object (OTXXTextLine)
          constructor MakeList(Font:OPFont; dir:string; FAttr:word);
          procedure ChangeDirectory(dir:string; FAttr:word);
       private
          FAttributes:word;
          directory:string;
       end;


       OPXFileName = ^OTXFileName;
       OTXFileName = object (OTXTextLine)
          constructor MakeElement(FileName:string; next:OPXList);
          constructor MakeElement2(FileName:string; FAttr:word; next:OPXList);
          procedure DrawElement(x,y:integer; selected:boolean); virtual;
          function GetHeight:word; virtual;
       private
          icon:word;
       end;



IMPLEMENTATION



   procedure Files_RESOURCES; external; {$L files.obj}


   var
        Doc_HCA,
        Exe_File_HCA,
        Directory_HCA,
        Any_File_HCA:  HCA;




                       {---- OTXXFileList -----}
   constructor OTXXFileList.MakeList(Font:OPFont; dir:string; FAttr:word);
     var F: SearchRec;
         fine:string[4];
         ZeroAttr:boolean;
     begin
       if dir[byte(dir[0])]='\' then fine:='*.*'
                                else fine:='\*.*';
       directory:=dir;
       FAttributes:=FAttr;
       { Inizializzazione }
       inherited MakeList(Font,nil);
       { Creazione della lista }
       FindFirst(directory+fine,FAttributes,F);
       while DosError=0 do begin
         if (ZeroAttr and (F.Attr=0)) or
            ((F.Attr and FAttributes)<>0)
         then
           AppendElement(
             new( OPXFileName, MakeElement2(StrLowerPas(F.Name),F.Attr,nil))
           );
         FindNext(F);
       end;
     end;


   procedure OTXXFileList.ChangeDirectory(dir:string; FAttr:word);
     var F: SearchRec;
         fine:string[4];
         ZeroAttr:boolean;
     begin
       DeleteAllElements;
       ZeroAttr:=(FAttributes and dos.Directory)=0;
       if dir[byte(dir[0])]='\' then fine:='*.*'
                                else fine:='\*.*';
       directory:=dir;
       FAttributes:=FAttr;
       { Creazione della lista }
       FindFirst(directory+fine,FAttributes,F);
       while DosError=0 do begin
         if (ZeroAttr and (F.Attr=0)) or
            ((F.Attr and FAttributes)<>0)
         then
           AppendElement(
             new( OPXFileName, MakeElement2(StrLowerPas(F.Name),F.Attr,nil))
           );
         FindNext(F);
       end;
     end;


                    {----- OTXFileName -----}
   constructor OTXFileName.MakeElement(FileName:string; next:OPXList);
     var ext:TExtention;
         f:file;
         Attr:word;
     begin
       assign(f,FileName);
       GetFAttr(f,Attr);
       if (Attr and Directory)<>0
         then icon:=Directory_Icon
         else begin
           GetExtention(FileName,ext,'');
           if (ext='EXE') or (ext='COM') or (ext='BAT')
             then icon:=Exe_File_Icon
             else
               if ext='BMP'
                 then icon:=Doc_Icon
                 else icon:=Any_File_Icon;
         end;
       inherited MakeElement(FileName,next);
     end;


   constructor OTXFileName.MakeElement2(FileName:string; FAttr:word; next:OPXList);
     var ext:TExtention;
     begin
       if (FAttr and Directory)<>0
         then icon:=Directory_Icon
         else begin
           GetExtention(FileName,ext,'');
           if (ext='EXE') or (ext='COM') or (ext='BAT')
             then icon:=Exe_File_Icon
             else
               if ext='BMP'
                 then icon:=Doc_Icon
                 else icon:=Any_File_Icon;
         end;
       inherited MakeElement(FileName,next);
     end;


   procedure OTXFileName.DrawElement(x,y:integer; selected:boolean);
     var h:^HCA;
         _x:integer;
     begin
       case icon of
         Doc_Icon       : h:=@Doc_HCA;
         Exe_File_Icon  : h:=@Exe_File_HCA;
         Directory_Icon : h:=@Directory_HCA;
         Any_File_Icon  : h:=@Any_File_HCA;
       end;
       if Selected then _x:=16
                   else _x:=0;
       if icon<>0
         then begin
           BitBtl(h^,VideoDC,_x,0,x,y+1,16,h^.DimY);
           _x:=x+20;
         end
         else _x:=x;
       inherited DrawElement(_x,y+1,selected);
     end;


   function OTXFileName.GetHeight:word;
     var h:word;
     begin
       h:=inherited GetHeight;
       if h<17 then h:=17;
       GetHeight:=h;
     end;



var precExitProc:pointer;


{$F+}
   procedure FilesExitProc;
     begin
       DestroyDC(Doc_HCA);
       DestroyDC(Exe_File_HCA);
       DestroyDC(Directory_HCA);
       DestroyDC(Any_File_HCA);
       TProc(precExitProc);
     end;
{$F-}


   procedure GetBitmap(ID:word;var _HCA:HCA);
     var bmp:pointer;
         size:longint;
     begin
       size:=GetBMPResource_IDNum(@Files_RESOURCES,6,ID,bmp);
       CreateCompatibleArea(_HCA,bmp^);
       FreeMem(bmp,size);
     end;



begin
  GetBitmap(Doc_Icon,Doc_HCA);
  GetBitmap(Exe_File_Icon,Exe_File_HCA);
  GetBitmap(Directory_Icon,Directory_HCA);
  GetBitmap(Any_File_Icon,Any_File_HCA);
end.