{by Ernesto CIANCIOTTA Productions}
program Editor_di_risorse_per_GOLIB;

uses
    crt,
    codici,
    utility,
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
    window,
    frame,
    w_intest
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

      bianco = 15;
      nero   = 0;
      _xor_    = 1;
      traspar = 6;

      dimCasella=13;

      {$I SysCur.pcr}

var
    ColoreSelezionato:word;
    ColoreMarcato:word;
    out:file;
    source:text;



type
     TCursore = record
       p1,
       p2: array [0..15] of word;
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
        for i:=0 to 15 do
          for j:=0 to 15 do tab[i,j]:=col;
      end;


    procedure OTTabella.Disegna;
      var i,j:word;
      begin
        with r do
          for i:=0 to 15 do
            for j:=0 to 15 do
              Incavo3D(x1+i*dimCasella,y1+j*dimCasella,x1+(i+1)*dimCasella-1,y1+(j+1)*dimCasella-1,tab[i,j]);
      end;



    procedure Inc3D(params:PDrawParameters; x,y:integer);
    far;
     begin
       with params^.rect do Incavo3D(x1+x,y1+y,x2+x,y2+y,longint(params^.params));
     end;



    procedure OTTabella.ExecMessage(var Message:TMessage);
      var i,j:word;
      begin
        if Message.Message<>EvMOUSE_L_PRESSED then exit;
        i:=(Message.mcx-r.x1) div dimCasella;
        j:=(Message.mcy-r.y1) div dimCasella;
        if tab[i,j]=ColoreSelezionato then tab[i,j]:=bianco
                                      else tab[i,j]:=ColoreSelezionato;
        ColoreMarcato:=tab[i,j];
        hidemousecursor;
        DrawInside(i*dimCasella,j*dimCasella,(i+1)*dimCasella-1,(j+1)*dimCasella-1,@Inc3D,pointer(tab[i,j]));
        showmousecursor;
        inherited ExecMessage(Message);
      end;


    procedure OTTabella.Setta(i,j,col:word);
      var msg:TMessage;
      begin
        tab[i,j]:=col;
        ColoreMarcato:=col;
        hidemousecursor;
        DrawInside(i*dimCasella,j*dimCasella,(i+1)*dimCasella-1,(j+1)*dimCasella-1,@Inc3D,pointer(tab[i,j]));
        showmousecursor;
        msg.Message:=ID;
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
      begin
        r.assign(50,50,520,350);
        inherited Init(r,'Editor di Risorse per GOLIB',FullIntestParam(true,false,true));
        nomeF:='';
        modificato:=false;
        salvato:=false;
        for i:=0 to 15 do begin
          cursore.p1[i]:=$FFFF;
          cursore.p2[i]:=$0000;
        end;

        AddMenu(ResEditMenu,_nord_);

        { creazione tabella }
        new(tab, Init(_tabella_,15,15,ColoreSelezionato));


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

        rect.SetRect(240,85,100,56);
        AddOther( new(OPRectangle, Init(rect,0,In3D)) ,nil);

        rect.SetRect(245,90,100,30);
        AddOther( new(OPText, Init(Null_ID,rect,@_serif8_,'Colore Selezionato',1,8,0)),nil);
        rect.SetRect(245,110,90,25);
        new(campoColore, Init(Null_ID,rect,1,ColoreSelezionato));
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
          ColoreSelezionato:=col;
          CampoColore^.SetStyle(1,col);
          CampoColore^.Refresh;
        end;

      procedure Tabella;
        var i,j,mask:word;
        begin
          i:=(Message.mcx-tab^.r.x1) div dimCasella;
          j:=(Message.mcy-tab^.r.y1) div dimCasella;
          mask:=$8000 shr i;
          with cursore do begin
            if ColoreMarcato in [_xor_,traspar]
              then p1[j]:=p1[j] or mask
              else p1[j]:=p1[j] and not mask;
            if ColoreMarcato in [_xor_,bianco]
              then p2[j]:=p2[j] or mask
              else p2[j]:=p2[j] and not mask;
          end;
          anteprima^.Refresh;
          modificato:=true;
        end;

      procedure Uscita;
        begin
        end;

      begin
        case Message.Message of
        _nuovo_    :nuovo;
        _apri_     :aprifile;
        _salva_c_  :SalvaConNome;
        _salva_    :Salva;
        _crea_pas_ :creasorgentePAS;
        _about_    :about;
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
	if modificato and not salvato then begin
          lookvideo:=false;
          new(c, Init);
          lookvideo:=true;
          case c^.Execute of
          _OK_: Salva;
          _ANNULLA_: exit;
          end
        end;        RestoreCRTMode;
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
          end
          else begin
            nomeF:=nf;
            blockread(out,cursore,1);
            close(out);
          end;
        end;
        CreaTab;
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
        writeln(_f,'const'#9,ncur,' : array [0..31] of word = (');
        for i:=0 to 15 do writeln(_f,#9#9'$',HexW(cursore.p1[i]),',');
        writeln(_f);
        for i:=0 to 14 do writeln(_f,#9#9'$',HexW(cursore.p2[i]),',');
        writeln(_f,#9#9'$',HexW(cursore.p2[15]));
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
        DefineGraphicCursor(cursore,1,1);
        WaitNextMouseMessage(Msg, btLPressMask or
                                  btRPressMask or
                                  btCPressMask );
        DefineGraphicCursor(syscur_Cursore,1,1);
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
                nil)),
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
        OTFrame.Init(r,'',IntestParam);
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




var app:OTApp;


begin
  coloreselezionato:=traspar;
  InizializzaGrafica(3,16);
  app.Init;
  app.PutOnDeskTop;
  StartApplication;
end.
