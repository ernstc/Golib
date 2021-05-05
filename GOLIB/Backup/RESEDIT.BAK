{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



program Editor_di_risorse_per_GOLIB;

uses
    crt,
    codici,
    utility,
    strings,
    graph,
    graftool,
    mouse,
    fonts,
    golib_h,
    applic,
    golib9,
      dispfile,
    menu,
    buttons,
    window2,
    frame2,
    w_header
    ;


const
      _nuovo_ = 1000;
      _apri_  = 1001;
      _salva_c_ = 1002;
      _salva_   = 1003;
      _crea_pas_ = 1004;
      _about_ = 1005;

      _c_tutto_ = 1006;
      _t_nero_   = 1007;
      _t_traspar_ = 1008;
      _t_xor_    = 1009;
      _t_bianco_ = 1010;

      _test_ = 1011;
      _tabella_ = 1012;

      _OK_ = 1013;
      _NO_ = 1014;
      _ANNULLA_= 1015;

      __bianco = 1101;
      __nero   = 1102;
      __xor    = 1103;
      __traspar = 1104;
      __DefHot = 1105;

      _nuovo_editor_ = 1106;

      bianco = 15;
      nero   = 0;
      _xor_    = 1;
      traspar = 6;

      dimCasella=13;


var
   NumeroEditors:word;


type
     TCursore = record
       p1,
       p2: array [0..15] of word;
       HotX,
       HotY:integer;
     end;

     OPTabella = ^OTTabella;
     OTTabella = object (OTView)
        constructor Init(_ID,x,y:integer; col:word);
        procedure Disegna; virtual;
        procedure ExecMessage(var Message:TMessage); virtual;
        procedure Setta(i,j,col:word);
        function GetColor(i,j:word):word;
     private
        tab:array[0..15,0..15] of word;
        hotX,
        hotY:integer;
        Drawing:boolean;
     public
        ColoreSelezionato:word;
        ColoreMarcato:word;
        DefMode:boolean;
     end;

     OPAnteprima = ^OTAnteprima;
     OTAnteprima = object (OTView)
        constructor Init(x,y:integer; tabella:OPTabella);
        procedure Disegna; virtual;
        procedure Aggiorna(i,j,col:word);
     private
        tab:OPTabella;
     end;

     OPApp = ^OTApp;
     OTApp = object (OTFrame)
        constructor Init;
        destructor Done; virtual;
        procedure ExecMessage(var Message:TMessage); virtual;
     private
        procedure Nuovo;
        procedure ApriFile;
        procedure SalvaConNome;
        procedure Salva;
        procedure CreaSorgentePAS;
        procedure About;
        procedure Test;
        procedure tutto(col:word);
     private
        tab:OPTabella;
        CampoColore:OPIncavo3d;
        Anteprima:OPAnteprima;
        cursore: TCursore;
        nomeF:string;
        modificato,
        salvato:boolean;
        out:file;
        function chiudi:boolean;
     end;

     OPAbout = ^OTAbout;
     OTAbout = object (OTDialogBox)
        constructor Init;
        procedure ExecMessage(var Message:TMessage); virtual;
     end;

     OPChiudi = ^OTChiudi;
     OTChiudi = object (OTDialogBox)
        constructor Init;
        procedure ExecMessage(var Message:TMessage); virtual;
     end;



                      {***** OTTabella *****}
    constructor OTTabella.Init(_ID,x,y:integer; col:word);
      var i,j:word;
      begin
        r.SetRect(x,y,dimCasella*16-1,dimCasella*16-1);
        inherited Init(_ID,r);
        coloreselezionato:=traspar;
        for i:=0 to 15 do
          for j:=0 to 15 do tab[i,j]:=col;
        hotX:=0;
        hotY:=0;
        Drawing:=false;
        MouseReactionMask:=rcLPressed or rcLReleased or rcMove ;
      end;


    procedure OTTabella.Disegna;
      var i,j:word;
      begin
        with r do
          for i:=0 to 15 do
            for j:=0 to 15 do begin
              Incavo3D(x1+i*dimCasella,y1+j*dimCasella,x1+(i+1)*dimCasella-1,y1+(j+1)*dimCasella-1,tab[i,j]);
              if (i=hotX) and (j=hotY) then begin
                SetColor(15); SetWriteMode(XorPut);
                SetLineStyle(0,0,3);
                line(2+x1+i*dimCasella,2+y1+j*dimCasella,x1+(i+1)*dimCasella-1-2,y1+(j+1)*dimCasella-1-2);
                line(2+x1+i*dimCasella,y1+(j+1)*dimCasella-1-2,x1+(i+1)*dimCasella-1-2,y1+j*dimCasella+2);
                SetWriteMode(NormalPut);
                SetLineStyle(0,0,1);
              end;
            end;
      end;

type
    PParamInc3D = ^TParamInc3D;
    TParamInc3D = record
      col:word;
      croce:boolean;
    end;


    procedure Inc3D(params:PDrawParameters; x,y:integer);
    far;
     begin
       with params^.rect do begin
         Incavo3D(x1+x,y1+y,x2+x,y2+y,PParamInc3D(params^.params)^.col);
         if PParamInc3D(params^.params)^.croce then begin
           SetColor(15); SetWriteMode(XorPut);
           SetLineStyle(0,0,3);
           line(x1+x+2,y1+y+2,x2+x-2,y2+y-2);
           line(x1+x+2,y2+y-2,x2+x-2,y1+y+2);
           SetWriteMode(NormalPut);
           SetLineStyle(0,0,1);
         end;
       end;
     end;



    procedure OTTabella.ExecMessage(var Message:TMessage);
      var i,j:word;
          p:TParamInc3D;
      begin
        if (Message.Message=EvMOUSE_L_PRESSED) then begin
          repeat
            i:=(Message.mcx-r.x1) div dimCasella;
            j:=(Message.mcy-r.y1) div dimCasella;
            if DefMode then begin
              { Inquesta modalit… imposta l'hot spot del cursore }
              p.col:=tab[hotX,hotY];
              p.croce:=false;
              hidemousecursor;
              DrawInside(hotX*dimCasella,hotY*dimCasella,(hotX+1)*dimCasella-1,(hotY+1)*dimCasella-1,@Inc3D,@p);
              showmousecursor;
              hotX:=i;
              hotY:=j;
              p.croce:=true;
            end
            else begin
              { In questa modalit… imposta il pixel del cursore }
              tab[i,j]:=ColoreSelezionato;
              ColoreMarcato:=tab[i,j];
              p.croce:=(i=hotX) and (j=hotY);
            end;
            hidemousecursor;
            p.col:=tab[i,j];
            DrawInside(i*dimCasella,j*dimCasella,(i+1)*dimCasella-1,(j+1)*dimCasella-1,@Inc3D,@p);
            showmousecursor;
            Message.Message:=ID;
            SendMessage(Message);
            { aspetta il prossimo messaggio }
            repeat
              WaitNextMouseMessage(Message,rcLReleased or rcMove);
            until (Message.mcx >= R.x1) and (Message.mcx <= R.x2) and
                  (Message.mcy >= R.y1) and (Message.mcy <= R.y2) or
                  ((PositionAndButtonStatus and 1)=0);
          until Message.Message=EvMOUSE_L_RELEASED;
        end;
      end;


    procedure OTTabella.Setta(i,j,col:word);
      var msg:TMessage;
          p:TParamInc3D;
      begin
        tab[i,j]:=col;
        ColoreMarcato:=col;
        hidemousecursor;
        p.col:=tab[i,j];
        p.croce:=(i=hotX) and (j=hotY);
        DrawInside(i*dimCasella,j*dimCasella,(i+1)*dimCasella-1,(j+1)*dimCasella-1,@Inc3D,@p);
        showmousecursor;
        msg.Message:=ID;
        Msg.mcx:=i*DimCasella+r.x1;
        Msg.mcx:=j*DimCasella+r.y1;
        SendMessage(Msg);
      end;


    function OTTabella.GetColor(i,j:word):word;
      begin
        GetColor:=tab[i,j];
      end;


                          {***** OTAnteprima *****}
    constructor OTAnteprima.Init(x,y:integer; tabella:OPTabella);
      begin
        r.SetRect(x,y,19,19);
        inherited Init(Null_ID,r);
        tab:=tabella;
      end;


    procedure OTAnteprima.Disegna;
      var i,j:word;
      begin
        with r do Incavo3D(x1,y1,x2,y2,-1);
        for i:=0 to 15 do
          for j:=0 to 15 do
            PutPixel(r.x1+2+i,r.y1+2+j,tab^.GetColor(i,j));
      end;


    procedure OTAnteprima.Aggiorna(i,j,col:word);
      begin
        setfullport;
        PutPixel(r.x1+2+i,r.y1+2+j,col);
      end;





                          {***** OTApp *****}
    function ResEditMenu:OPMenuLine; forward;


    constructor OTApp.Init;
      var rect:OTRect;
          i:word;
          lk:boolean;
          xxx:integer;
      begin
        lk:=lookvideo;
        lookvideo:=false;

        inc(NumeroEditors);
        xxx:=(NumeroEditors mod 7)*30;
        r.SetRect(xxx,xxx,470,307);
        inherited Init(r,
                       new(OPFullHeader, Init( StrNewPas('Editor di Risorse per GOLIB [Finestra '+NumStr(NumeroEditors)+']'),
                                       true,
                                       true,
                                       true)
                       )
        );
        nomeF:='';
        modificato:=false;
        salvato:=false;
        for i:=0 to 15 do begin
          cursore.p1[i]:=$FFFF;
          cursore.p2[i]:=$0000;
        end;
        AddMenu(ResEditMenu,_nord_);

        { creazione tabella }
        new(tab, Init(_tabella_,15,15,traspar));

        tab^.DefMode:=false;

        rect.SetRect(240,15,100,30);
        AddOther( new(OPTextButton, Init(__bianco,rect,'Bianco',true,1,8,0))
        , nil);
        rect.SetRect(345,15,100,30);
        AddOther( new(OPTextButton, Init(__nero,rect,'Nero',true,1,8,0))
        , nil);
        rect.SetRect(240,50,100,30);
        AddOther( new(OPTextButton, Init(__traspar,rect,'Trasparente',true,1,8,0))
        , nil);
        rect.SetRect(345,50,100,30);
        AddOther( new(OPTextButton, Init(__xor,rect,'XOR',true,1,8,0))
        , nil);
        rect.SetRect(345,85,100,56);
        AddOther( new(OPTextButton, Init(__DefHot,rect,'Definisci'#13#10'HotSpot',true,1,8,0))
        , nil);
        rect.SetRect(15,230,430,18);
        AddOther( new(OPTextButton, Init(_nuovo_editor_,rect,'Apri un nuovo editor',true,1,8,0))
        , nil);

        rect.SetRect(240,85,100,56);
        AddOther( new(OPRectangle, Init(rect,0,In3D)) ,nil);

        rect.SetRect(245,90,100,30);
        AddOther( new(OPText, Init(Null_ID,rect,@_serif8_,'Colore Selezionato',1,8,0)),nil);
        rect.SetRect(245,110,90,25);
        new(campoColore, Init(Null_ID,rect,1,traspar));
        AddOther(campoColore,nil);

        rect.SetRect(240,160,205,60);
        AddOther( new(OPRectangle, Init(rect,0,In3D)) ,nil);

        rect.SetRect(245,165,100,30);
        AddOther( new(OPText, Init(Null_ID,rect,@_serif8_,'Anteprima',1,8,0)),nil);
        new(Anteprima, Init(255,185,tab));
        AddOther(Anteprima,nil);
        rect.SetRect(330,175,100,30);
        AddOther( new(OPTextButton, Init(_test_,rect,'Test',true,1,8,0))
        , nil);

        AddOther(tab,nil);

        lookvideo:=lk;
      end;


    destructor OTApp.Done;
      begin
        inherited Done;
      end;


    procedure OTApp.ExecMessage(var Message:TMessage);
      var i,j:word;
          c:OPChiudi;

      procedure SelezionaColore(col:word);
        begin
          tab^.ColoreSelezionato:=col;
          CampoColore^.SetStyle(1,col);
          CampoColore^.Refresh;
        end;

      procedure Tabella;
        var i,j,mask:word;
        begin
          i:=(Message.mcx-tab^.r.x1) div dimCasella;
          j:=(Message.mcy-tab^.r.y1) div dimCasella;
          if tab^.DefMode then begin
            tab^.DefMode:=false;
            cursore.HotX:=i;
            cursore.HotY:=j;
          end
          else begin
            mask:=$8000 shr i;
            with cursore do begin
              if tab^.ColoreMarcato in [_xor_,traspar]
                then p1[j]:=p1[j] or mask
                else p1[j]:=p1[j] and not mask;
              if tab^.ColoreMarcato in [_xor_,bianco]
                then p2[j]:=p2[j] or mask
                else p2[j]:=p2[j] and not mask;
            end;
            anteprima^.Refresh;
          end;
          modificato:=true;
        end;

      procedure Uscita;
        begin
        end;

      procedure Nuovo_Edior;
        var e:OPApp;
        begin
          new(e,Init);
          e^.PutOnDeskTop;
        end;

      begin
        case Message.Message of
        {_nuovo_    :nuovo;}
        _apri_     :aprifile;
        _salva_c_  :SalvaConNome;
        _salva_    :Salva;
        _crea_pas_ :creasorgentePAS;
        {_about_    :about;}
        _c_tutto_  :tutto(traspar);
        _t_bianco_ :tutto(bianco);
        _t_nero_   :tutto(nero);
        _t_traspar_:tutto(traspar);
        _t_xor_    :tutto(_xor_);
        __bianco   :SelezionaColore(bianco);
        __nero     :SelezionaColore(nero);
        __traspar  :SelezionaColore(traspar);
        __xor      :SelezionaColore(_xor_);
        _test_     :Test;
        _tabella_  :Tabella;
        __DefHot   :tab^.DefMode:=true;
        _nuovo_editor_: Nuovo_Edior;
        {_esci_     : begin
                       if modificato and not salvato then begin
                         lookvideo:=false;
                         new(c, Init);
                         lookvideo:=true;
                         case c^.Execute of
                         _OK_: Salva;
                         _ANNULLA_: exit;
                         end
                       end;
                     end;}
        end;
        inherited ExecMessage(Message);
      end;


    procedure OTApp.Nuovo;
      var c:OPChiudi;

      procedure procedi;
        begin
          tutto(traspar);
          modificato:=false;
          salvato:=false;
          nomeF:='';
        end;

      begin
        if modificato and not salvato then begin
          lookvideo:=false;
          new(c, Init);
          lookvideo:=true;
          case c^.Execute of
          _OK_: Salva;
          _ANNULLA_: exit;
          end
        end;
        procedi;
      end;


    procedure OTApp.ApriFile;
      var nf:string;
          c:OPChiudi;

      procedure CreaTab;
        var i,j:byte;
            mask,c1,c2:word;
        begin
          for i:=0 to 15 do
            for j:=0 to 15 do begin
              mask:=$8000 shr j;
              c1:=cursore.p1[i] and mask;
              c2:=cursore.p2[i] and mask;
              if (c1<>0) and (c2<>0) then tab^.tab[j,i]:=_xor_;
              if (c1=0) and (c2<>0) then tab^.tab[j,i]:=bianco;
              if (c1<>0) and (c2=0) then tab^.tab[j,i]:=traspar;
              if (c1=0) and (c2=0) then tab^.tab[j,i]:=nero;
            end;
        end;

      begin
	{if modificato and not salvato then begin
          lookvideo:=false;
          new(c, Init);
          lookvideo:=true;
          case c^.Execute of
          _OK_: Salva;
          _ANNULLA_: exit;
          end
        end;}        RestoreCRTMode;
        writeln('''\'' = Annulla');
        writeln;
        writeln('Inserisci il nome del file da aprire:');
        readln(nf);
        if nf<>'\' then begin
          assign(out,nf);
          restoreGraphMode;
          {$I-}
          reset(out,sizeof(cursore));
          {$I+}
          if ioresult<>0 then begin
            RestoreCRTMode;
            writeln('Problemi col nome del file!');
            readkey;
            if nomeF<>'' then assign(out,nomeF);
            tab^.hotX:=0;
            tab^.hotY:=0;
          end
          else begin
            nomeF:=nf;
            blockread(out,cursore,1);
            close(out);
            tab^.hotX:=cursore.HotX;
            tab^.hotY:=cursore.HotY;
          end;
          CreaTab;
        end;
        RestoreGolibGraphMode;
        modificato:=false;
      end;


    procedure OTApp.SalvaConNome;
      var nf:string;
      begin
        RestoreCRTMode;
        writeln('''\'' = Annulla');
        writeln;
        writeln('Inserisci il nome del file su cui salvare:');
        readln(nf);
        if nf<>'\' then begin
          assign(out,nf);
          restoreGraphMode;
          {$I-}
          rewrite(out,sizeof(cursore));
          {$I+}
          if ioresult<>0 then begin
            RestoreCRTMode;
            writeln('Problemi col nome del file!');
            readkey;
            if nomeF<>'' then assign(out,nomeF);
          end
          else begin
            nomeF:=nf;
            blockwrite(out,cursore,1);
            close(out);
          end;
        end;
        RestoreGolibGraphMode;
        salvato:=true;
      end;


    procedure OTApp.Salva;
      begin
        if nomeF=''
          then SalvaConNome
          else begin
            rewrite(out,1);
            blockwrite(out,cursore,sizeof(cursore));
            close(out);
            salvato:=true;
          end;
      end;


    procedure OTApp.CreaSorgentePAS;
      var ncur,nfPas:string;
          i:byte;
          _f:text;
      begin
        nfPas:=nomeF;
        if nfpas='' then nfpas:='nuovo.pcr';
        i:=length(nfPas);
        while true do begin
          if nfPas[i]='\'
            then break
            else if nfPas[i]='.' then begin
              delete(nfPas,i,length(nfPas)-i+1);
              break;
            end;
          dec(i);
        end;
        ncur:=nfpas+'_cursore';
        nfPas:=nfPas+'.PCR';
        assign(_f,nfPas);
        rewrite(_f);
        writeln(_f,'const'#9,ncur,' : array [0..33] of word = (');
        for i:=0 to 15 do writeln(_f,#9#9'$',HexW(cursore.p1[i]),',');
        writeln(_f);
        for i:=0 to 15 do writeln(_f,#9#9'$',HexW(cursore.p2[i]),',');
        writeln(_f);
        writeln(_f,#9#9,cursore.HotX,',');
        writeln(_f,#9#9,cursore.HotY);
        writeln(_f,#9');');
        close(_f);
      end;


    procedure OTApp.About;
      var ab:OPAbout;
      begin
        lookvideo:=false;
        new(ab, Init);
        lookvideo:=true;
        ab^.execute;
      end;


    procedure OTApp.Test;
      var Msg:TMessage;
      begin
        DefineGraphicCursor(cursore,cursore.HotX,cursore.HotY);
        hidemousecursor;
        showmousecursor;
        WaitNextMouseMessage(Msg, btLPressMask or
                                  btRPressMask or
                                  btCPressMask );
        with SystemCursor^ do
          DefineGraphicCursor(bin,HotX,HotY);
        hidemousecursor;
        showmousecursor;
      end;


    procedure OTApp.tutto(col:word);
      var i,j,c1,c2:word;
      begin
        for i:=0 to 15 do
          for j:=0 to 15 do
            tab^.tab[i,j]:=col;
        if col in [_xor_,traspar] then c1:=$FFFF
                                  else c1:=$0000;
        if col in [_xor_,bianco] then c2:=$FFFF
                                 else c2:=$0000;
        for i:=0 to 15 do begin
          cursore.p1[i]:=c1;
          cursore.p2[i]:=c2;
        end;
        tab^.refresh;
        anteprima^.refresh;
        modificato:=true;
      end;


    function OTApp.chiudi:boolean;
      var ch:char;
      begin
        chiudi:=true;
        if modificato and not salvato then begin
          RestoreCRTMode;
          writeln('Il file non Š stato salvato!');
          writeln('1. Salvare');
          writeln('2. Non salvare');
          writeln('3. Annulla');
          ch:=#0;
          while not (ch in['1'..'3']) do ch:=readkey;
          if ch='1' then Salva;
          if ch='3' then chiudi:=false;
          RestoreGolibGraphMode;
        end;
      end;


    function ResEditMenu:OPMenuLine;
      begin
        ResEditMenu:=new(OPMenuLine,
          Init(
             NewItem('@File',Null_ID,_Attivo_,
                NewItemPP('@Nuovo',_nuovo_,0,itEnable,_No_SubMenu_,
                NewItemPP('@Apri',_Apri_,0,itEnable,_No_SubMenu_,
                NewItemPP('@Salva',_salva_,0,itEnable,_No_SubMenu_,
                NewItemPP('Salva @con nome...',_salva_c_,0,itEnable,_No_SubMenu_,
                NewSEPARATOR_PP(
                NewItemPP('Crea sogente @PAS',_crea_pas_,0,itEnable,_No_SubMenu_,
                NewSEPARATOR_PP(
                NewItemPP('@Esci',_ESCI_,0,itEnable,_No_SubMenu_,
                nil)))))))),
             NewItem('@Edit',Null_ID,_Attivo_,
                NewItemPP('@Cancella tutto',_c_tutto_,0,itEnable,_No_SubMenu_,
                NewItemPP('@Tutto...',Null_ID,0,itEnable,
                   NewItemPP('@Bianco',_t_bianco_,0,itEnable,_No_SubMenu_,
                   NewItemPP('@Nero',_t_nero_,0,itEnable,_No_SubMenu_,
                   NewItemPP('@Trasparente',_t_traspar_,0,itEnable,_No_SubMenu_,
                   NewItemPP('@XOR',_t_xor_,0,itEnable,_No_SubMenu_,
                   nil)))),
                NewSEPARATOR_PP(
                NewItemPP('@Nuovo editor',_nuovo_editor_,0,itEnable,_No_SubMenu_,
                nil)))),
             NewItem('@About',_about_,_Attivo_,_No_SubMenu_,
                {NewItemPP('@About',_about_,0,itEnable,_No_SubMenu_,
                nil),}
             nil)))
          )
        );
      end;


                      {***** OTAbout *****}
    constructor OTAbout.Init;
      var rect:OTRect;
      begin
        r.SetRect(0,0,350,150);
        inherited Init(r,true,'About...',false);

        rect.SetRect(10,10,200,30);
        AddOther( new(OPText, Init(Null_ID,rect,@_serif8_,'Editor di risorse per applicazioni GOLIB',1,8,0)),nil);
        rect.SetRect(10,40,300,30);
        AddOther( new(OPText, Init(Null_ID,rect,@_serif8_,'(c) 1994,1996  by  Ernesto CIANCIOTTA Productions',1,8,0)),nil);

        rect.SetRect((350-100) div 2,70,100,30);
        AddOther( new(OPTextButton, Init(_OK_,rect,'OK',true,1,8,0))
        , nil);
      end;


    procedure OTAbout.ExecMessage(var Message:TMessage);
      begin
        {inherited ReactionEvent(Event);}
        if Message.Message = _OK_ then CloseWin;
      end;

                      {***** OTChiudi *****}
    constructor OTChiudi.Init;
      var rect:OTRect;
      begin
        r.SetRect((MaxXResolution-350) div 2,(MaxYResolution-150) div 2,350,150);
        OTFrame.Init(r,new(OPNormalHeader, Init( StrNewPas(''))));
        SysConfig:=SysConfig or cfModal;

        rect.SetRect(10,10,200,30);
        AddOther( new(OPText, Init(Null_ID,rect,@_serif8_,'Il cursore non Š stato salvato !',1,8,0)),nil);
        rect.SetRect(10,40,300,30);
        AddOther( new(OPText, Init(Null_ID,rect,@_serif8_,'Vuoi salvarlo ?',1,8,0)),nil);

        rect.SetRect(10,70,70,25);
        AddOther( new(OPTextButton, Init(_OK_,rect,'Si',true,1,8,0))
        , nil);

        rect.SetRect(85,70,70,25);
        AddOther( new(OPTextButton, Init(_NO_,rect,'No',true,1,8,0))
        , nil);

        rect.SetRect(160,70,70,25);
        AddOther( new(OPTextButton, Init(_ANNULLA_,rect,'Annulla',true,1,8,0))
        , nil);
      end;


    procedure OTChiudi.ExecMessage(var Message:TMessage);
      begin
        {inherited ExecMessage(Message);}
        with Message do
        if (Message=_OK_) or
           (Message=_NO_) or
           (Message=_ANNULLA_) then CloseWin;
      end;




var
    app:OTApp;


begin
  InizializzaGrafica(3,16);
  NumeroEditors:=0;
  app.Init;
  app.PutOnDeskTop;
  StartApplication;
end.
