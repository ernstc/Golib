{by Ernesto CIANCIOTTA Productions}

{$D+}
{$L+}

unit utility;

interface

uses  dos;

const
      __uno:char='1';
      __zero:char='0';


type
      Stringa8 = string[8];
      TExtention = string[3];
      THexB = string[2];
      THexW = string[4];



  procedure GetExtention(var FileName:string; var ext:TExtention; extPref:TExtention);
  procedure SetExtention(var FileName:string; ext:TExtention);
  function Byte_BinStr(num:byte):Stringa8;
  function NumStr(num:longint):string;
  function StrNum(s:string):integer;
  function StrUpperPas(s:string):string;
  function StrLowerPas(s:string):string;
  function HexB(num:byte):THexB;
  function HexW(num:word):THexW;
  function MillesFormat(num:longint):string;


implementation


  procedure GetExtention(var FileName:string; var ext:TExtention; extPref:TExtention);
    var point_pos:byte;
        ext_l:byte;
    begin
      point_pos:=length(FileName);
      while FileName[point_pos]<>'.' do dec(point_pos);
      if point_pos<>0
        then begin
          if Length(FileName)<>point_pos
            then begin
              ext_l:=Length(FileName)-point_pos;
              if ext_l>3 then begin
                delete(FileName,point_pos+1,ext_l-3);
                ext_l:=3;
              end;
              ext:=copy(FileName,point_pos+1,ext_l)
            end
            else begin
              ext:=extPref;
              FileName:=FileName+extPref;
            end;
        end
        else begin
          if extPref<>'' then begin
            ext:=extPref;
            FileName:=FileName+'.'+extPref;
          end;
        end;
      for ext_l:=1 to length(ext) do ext[ext_l]:=upcase(ext[ext_l]);
    end;


  procedure SetExtention(var FileName:string; ext:TExtention);
    var point_pos:byte;
        ext_l:byte;
    begin
      point_pos:=length(FileName);
      while FileName[point_pos]<>'.' do dec(point_pos);
      if point_pos<>0 then begin
        delete(FileName,point_pos+1,length(FileName)-point_pos);
        FileName:=FileName+ext;
      end
      else FileName:=FileName+'.'+ext;
    end;


  function Byte_BinStr(num:byte):Stringa8;
     var buffer:Stringa8;
         i,j:byte;
     begin
       j:=0;   buffer[0]:=#8;
       for i:=8 downto 1 do begin
         if odd(num shr j) then buffer[i]:=__uno
                           else buffer[i]:=__zero;
         inc(j);
       end;
       Byte_BinStr:=buffer;
     end;


  function NumStr(num:longint):string;
    var s:string;
    begin
      str(num,s);
      NumStr:=s;
    end;


  function StrNum(s:string):integer;
    var num,j:integer;
    begin
      val(s,num,j);
      StrNum:=num;
    end;


  function StrUpperPas(s:string):string;  assembler;
  asm
  	PUSH	DS
	CLD
	LDS	SI,s
        LES	DI,@Result
        MOV	CL,[SI]
        MOVSB
  @@1:	LODSB
	CMP	AL,'a'
	JB	@@2
	CMP	AL,'z'
	JA	@@2
	SUB	AL,20H
  @@2:	STOSB
	LOOP	@@1
	POP	DS
  end;


  function StrLowerPas(s:string):string;  assembler;
  asm
  	PUSH	DS
	CLD
	LDS	SI,s
        LES	DI,@Result
        MOV	CL,[SI]
        MOVSB
  @@1:	LODSB
	CMP	AL,'A'
	JB	@@2
	CMP	AL,'Z'
	JA	@@2
	ADD	AL,20H
  @@2:	STOSB
	LOOP	@@1
	POP	DS
  end;


  function HexB(num:byte):THexB;
    var h:THexB;
        i,r:byte;
    begin
      h:='00';
      for i:=2 downto 1 do begin
        r:=num mod 16;
        num:=num div 16;
        if r<=9 then h[i]:=chr(r+48)
                else h[i]:=chr(r+55);
      end;
      HexB:=h;
    end;


  function HexW(num:word):THexW;
    var h:THexW;
        i,r:byte;
    begin
      h:='0000';
      for i:=4 downto 1 do begin
        r:=num mod 16;
        num:=num div 16;
        if r<=9 then h[i]:=chr(r+48)
                else h[i]:=chr(r+55);
      end;
      HexW:=h;
    end;


  function MillesFormat(num:longint):string;
    var index:byte;
        s:string;
    const
        punto:string[1]='.';
    begin
      s:=NumStr(num);
      index:=length(s);
      if index>3 then begin
        inc(index);
        repeat
          dec(index,3);
          insert(punto,s,index);
        until index<=3;
      end;
      MillesFormat:=s;
    end;

end.