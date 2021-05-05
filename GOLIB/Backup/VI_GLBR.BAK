{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



{ Utilit… per vedere il contenuto dei files in formato GLBr }

uses
    dos,
    openfile,
    utility,
    GLBr_sdk;

const
     Separatore = '________________________________________________________________________________';


var
   f:file;
   fName:string;
   ext:TExtention;

   header: TGLBrHeader;

   StartRes:longint;
   i,ris:word;

   Attributi,tipo,npack:word;

   ver:word;
   num_ris:longint;

   idx:PIDXTable;




procedure VisCursore;
  var c:TCursorRes;
      j:word;
  begin
    blockread(f,c,sizeof(TCursorRes));
    writeln('Cursore');
    writeln;
    with c do begin
      write('Traccia = ');
      for j:=1 to 8 do write(HexW(c.bin[j]),' ');
      writeln;
      write('          ');
      for j:=9 to 16 do write(HexW(c.bin[j]),' ');
      writeln;
      write('          ');
      for j:=17 to 24 do write(HexW(c.bin[j]),' ');
      writeln;
      write('          ');
      for j:=25 to 32 do write(HexW(c.bin[j]),' ');
      writeln;
      writeln('HotX = ',c.hotX);
      writeln('HotY = ',c.hotY);
    end;
  end;


procedure VisPackage;
  var j, npack:word;
      p:PPackage;
  begin
    blockread(f,npack,2);
    GetMem(p,sizeof(THotSpotRes)*npack+2);
    j:=filepos(f);
    blockread(f,p^.hot,sizeof(THotSpotRes)*npack);
    p^.n:=npack;
    writeln('Package');
    writeln;
    writeln('Numero di hot spots = ',npack);
    writeln;
    for j:=1 to npack do with p^.hot[j] do begin
      write('Numero Hot Spot = ',j:5,' ':10);
      writeln('x1 = ',x1:5,'   y1 = ',y1:5);
      writeln(' ':33,'x2 = ',x2:5,'   y2 = ',y2:5);
      writeln(' ':33,'IDCursor = ',IDCursor:5);
      writeln(' ':33,'Message  = ',Message:5);
      if j<npack then writeln;
    end;
    FreeMem(p,sizeof(THotSpotRes)*npack+2);
  end;


procedure VisAttributi;
  begin
    writeln;
    write('Attributi della risorsa: ');
    if Attributi<>0 then begin
      if (Attributi and ConfMOVABLE)<>0 then write('MOVABLE':10,#10#13,' ':26);
      if (Attributi and ConfPERSONAL)<>0 then write('PERSONAL':10,#10#13,' ':26);
      write(#10#13);
    end
    else writeln('nessun attributo');
  end;


begin
  writeln('Vi GLBr 1.0 (c) Ernesto Cianciotta 1996'#10#13);
  if paramcount=0 then begin
    writeln('Sintassi: vi_GLBr [path]<file name>[.GLB]');
    writeln;
    halt(1);
  end;
  fName:=paramstr(1);
  { Assegna l'estensione al nome del file qualora ne sia sprovvisto }
  GetExtention(fName,ext,'GLB');
  if ResetFile(f,fName,1)<>0 then HaltApplication(LastIOResult);
  { Verifica che il file sia del formato GLBr }
  blockread(f,header,sizeof(TGLBrHeader),ris);
  if (header<>GLBr_header) or (ris<>sizeof(TGLBrHeader)) then begin
    writeln('Il file specificato non Š nel formato GLBr 1.0 !'#10#13);
    close(f);
    halt(3);
  end;
  { Legge la versione ed il numero delle risorse }
  blockread(f,ver,2);
  blockread(f,num_ris,4);

  StartRes:=num_ris*8;

  { Alloca memoria in cui caricare la tabella d'accesso }
  GetMem(idx,StartRes);
  { Carica la tabella d'accesso }
  blockread(f,idx^,StartRes);

  StartRes:=FilePos(f);

  { Visualizza le risorse }
  writeln('Versione del file:          ',NumStr(ver)+'.0':10);
  writeln('Numero di risorse nel file: ',num_ris:10);
  for i:=1 to num_ris do begin
    seek(f,idx^[i].index);
    blockread(f,Attributi,2);
    blockread(f,tipo,2);
    writeln;
    write(Separatore);
    writeln('ID Risorsa = ',idx^[i].ID:5,'                            Indice = ',idx^[i].index:5);
    VisAttributi;
    write  ('Tipo risorsa ',HexW(tipo):5,':   ');
    case tipo of
    0001: VisPackage;
    0002: VisCursore;
    { seguiranno i visualizzatori per tutti gli altri tipi di risorsa
      supportati }
    end;
    write(Separatore);
  end;

  { Libera la memoria in cui c'Š la tabella d'accesso }
  FreeMem(idx,num_ris*8);

  close(f);
end.
