unit inter_fc;

interface
  uses crt;
  const ColorVDU=$B800;
        attivo:boolean = true;
        disattivo:boolean = false;
        return:boolean = true;
        noreturn:boolean = false;

  type  bufferVideo=array[0..1999] of word;
        TCarattere=record
                     case byte of
                     0: (ch:word);
                     1: (car:char;attr:byte);
                   end;
        PVideo=^TVideo;
        TVideo=record
                 case byte of
                 0: (scr:array[0..1999] of TCarattere);
                 1: (ch:array[1..25,1..80] of TCarattere);
               end;
        PEvento=^TEvento;
        TEvento=record
                  x1,y1,
                  x2,y2:integer;
                  azione:procedure;
                  succ:PEvento;
                end;
        PReazione=^TReazione;
        TReazione=procedure;

        OPScrollBar=^OTScrollBar;
        OTScrollBar=object
        private
           attributo:byte;
           sb:^string;
           posT:shortint;
           precNtot,precVis,ntot,dimE,visibili,GVS,maxT,pos:word;
           x,y:integer;
           intervallo:real;
           ch1,ch2,ch3,chN:char;
        public
           constructor Init(cx,cy:integer;dim:word;attr:byte);
           destructor Done;
           procedure ScrollBar(p,tot:word); virtual;
           procedure SetControlCharts(c1,c2,c3,neutro:char);
           procedure DefaultControlCharts; virtual;
        private
           procedure Visualizza; virtual;
           procedure CalcolaStringa;
        end;

        OPScrollBarHoriz=^OTScrollBarHoriz;
        OTScrollBarHoriz=object ( OTScrollBar )
           procedure ScrollBar(p,tot:word); virtual;
           procedure DefaultControlCharts; virtual;
        private
           procedure Visualizza; virtual;
        end;

        OPScrollBarVert=^OTScrollBarVert;
        OTScrollBarVert=object ( OTScrollBar )
           procedure ScrollBar(p,tot:word); virtual;
           procedure DefaultControlCharts; virtual;
        private
           procedure Visualizza; virtual;
        end;


  var     precVideo:bufferVideo;
        visualVideo:^bufferVideo;
              video:TVideo absolute $B800:0;


  function VideoSegment:word;
  function MaxX:integer;
  function MaxY:integer;
  procedure go(stringa:string);
  procedure tasto(col,riga:integer;intestazione:string;larghezza,fase:byte);
  procedure tastoOmbra(stato:boolean;col,riga:integer;intestazione:string);
  procedure evidenzia(x1,y1,x2,y2:integer; attributo:byte);
  procedure bordo(stato:boolean; x1,y1,x2,y2:integer; sfondo,carattere:byte;
                  primo:boolean);
  procedure OpenWin(x1,y1,x2,y2:integer;int,crn,intr:byte;intest:string;max:boolean);
  procedure AggiungiEvento(Ev:PEvento);
  function NuovoEvento(prima:PEvento;m1,n1,m2,n2:integer;az:TReazione):PEvento;
  function Reazione(m,n:integer):PReazione;

implementation

  var indice:byte;
      ch:char;
      ListaEventi,evento,CodaEventi:PEvento;

  procedure NessunaReazione;  begin end;

  function VideoSegment:word;
    begin
      if lastMode=7 then VideoSegment:=$B000
                    else VideoSegment:=$B800;
    end;

  function MaxX:integer;
  begin
    MaxX:=Lo(WindMax)-Lo(WindMin)+1;
  end;

  function MaxY:integer;
  begin
    MaxY:=Hi(WindMax)-Hi(WindMin)+1;
  end;

  procedure go(stringa:string);
      var i,j,c,y:integer;
          lrg,lrg2:byte;
          cr,cr2:char;
      begin
        y:=whereY;
        lrg:=lo(windMax)-lo(windMin)+1;
        lrg2:=lrg div 2;
        c:=length(stringa);
        if not(odd(c)) then c:=c div 2
                  else begin
                         c:=c div 2+1;
                         stringa:=stringa+' ';
                       end;
        for i:=1 to c do
          begin
            cr:=stringa[c-i+1];
            cr2:=stringa[c+i];
            for j:=1 to lrg2-i do begin
              gotoxy(j,y);         writeln(' ',cr);
              delay(1);
              gotoxy(lrg-j,y); write(cr2,' ');
              delay(1);
            end;
          end;
      end;


  procedure tasto(col,riga:integer;intestazione:string;larghezza,fase:byte);
    const cl:array[0..2,0..1] of byte=((15,8),(8,8),(8,15));
    var i:integer;
    begin
      textcolor(cl[fase,0]);    textbackground(7);
      gotoxy(col,riga);  write('Á');
      for i:=1 to larghezza-2 do write('Ä');
      gotoxy(col,riga+1);  write('³');
      gotoxy(col,riga+2);  write('À');
      textcolor(cl[fase,1]);
      for i:=1 to larghezza-2 do write('Ä');
      write('¾');
      gotoxy(col+larghezza-1,riga+1); write('³');
      gotoxy(col+larghezza-1,riga);   write('¿');
      if intestazione<>'' then begin
        textcolor(14);
        gotoxy(col+((larghezza-length(intestazione)) div 2),riga+1);
        write(intestazione);
      end;
    end;


  procedure tastoOmbra(stato:boolean;col,riga:integer;intestazione:string);
    const carattere:array[false..true] of byte = (0,9);
          speciale:boolean = false;
    var i:integer;
    begin
      textcolor(carattere[stato]);
      textbackground(2);
      gotoxy(col,riga);
      for i:=col to length(intestazione)-1+col do
        if intestazione[i-col+1]='~' then begin
          speciale:=not(speciale);
          if speciale then textcolor(6)
                      else textcolor(carattere[stato]);
        end
        else write(intestazione[i-col+1]);
      textcolor(0);  textbackground(7);
      write('Ü');
      gotoxy(col+1,riga+1);
      for i:=1 to length(intestazione)-2 do write('ß');
    end;

  procedure evidenzia(x1,y1,x2,y2:integer; attributo:byte);
    var cella,x,y:integer;

    begin
      for y:=y1 to y2 do
        for x:=x1 to x2 do
          begin
            cella:=80*y+x-81;
            visualVideo^[cella]:=(visualVideo^[cella] AND $00FF)+(attributo SHL 8);
          end;
    end;

  procedure bordo(stato:boolean; x1,y1,x2,y2:integer; sfondo,carattere:byte;
                  primo:boolean);
    const risorse:array[false..true,1..10] of char =
                               (('Ì','½','Î','¹','º','¸','Ö','Ó','Ð','¶'),
                                ('É','»','È','¼','º','¸','Ö','Ó','Ð','¶'));
    var i:integer;
        at:byte;
    begin
      at:=textattr shr 4;
      window(x1,y1,x2,y2+1);
      textcolor(carattere); textbackground(sfondo);
      write(risorse[stato,1]);
      for i:=2 to maxx-1 do write(risorse[stato,7]);
      write(risorse[stato,2]);
      gotoxy(1,2); write(risorse[stato,5]);
      gotoxy(maxx,2); write(risorse[stato,6]);
      gotoxy(1,3); write(risorse[stato,5]);
      gotoxy(maxx,3); write(risorse[stato,6]);
      textbackground(at);
      for i:=4 to maxy-2 do
        begin
          gotoxy(1,i); write(risorse[stato,5]);
          gotoxy(maxx,i); write(risorse[stato,6]);
        end;
      write(risorse[stato,3]);
      for i:=2 to maxx-1 do write(risorse[stato,8]);
      write(risorse[stato,4]);
      textbackground(sfondo);
      gotoxy(1,3); write(risorse[stato,9]);
      gotoxy(maxx,3); write(risorse[stato,10]);
      gotoxy(2,3); for i:=2 to maxx-1 do write('Ä');
      if not(primo) then
        evidenzia(2+x1-1,2+y1-1,maxx+x1-1,2+y1-1,sfondo shl 4 + carattere)
      else begin
        gotoxy(2,2); for i:= 2 to maxx-1 do write(' ');
      end;
    end;

  procedure OpenWin(x1,y1,x2,y2:integer;int,crn,intr:byte;intest:string;max:boolean);
    var l,i:integer;
        ang:byte;
    begin
      textattr:=intr;
      window(x1,y1,x2,y2);
      clrscr;
      if length(intest)>MaxX-5 then intest[0]:=chr(MaxX-5);
      textattr:=int;
      write('ÓÔÕ');
      l:=x2-x1-4-length(intest);
      for i:=1 to l div 2 do write('Ç');
      write(intest);
      for i:=1 to l div 2 + l mod 2 do write('Ç');
      if max then write('×½') else write('Ö¼');
      for i:=y1+1 to y2-1 do begin
        with video.ch[i,x1] do begin
          attr:=crn;
          car:='·';
        end;
        with video.ch[i,x2] do begin
          attr:=crn;
          car:='¶';
        end;
      end;
      ang:=(crn and $f0)+(int and $0f);
      textattr:=ang;
      gotoxy(1,maxY);
      write('Ê');
      for i:=x1+1 to x2-1 do
        with video.ch[y2,i] do begin
            attr:=crn;
            car:='Ñ';
          end;
      with video.ch[y2,x2] do begin
          attr:=ang;
          car:='º';
        end;
      evidenzia(x2+1,y1+1,x2+2,y2+1,$08);
      evidenzia(x1+2,y2+1,x2,y2+1,$08);
    end;

  procedure AggiungiEvento(Ev:PEvento);
    begin
      if ListaEventi=nil then CodaEventi:=Ev
                         else Ev^.succ:=ListaEventi;

    end;

  function NuovoEvento(prima:PEvento;m1,n1,m2,n2:integer;az:TReazione):PEvento;
    var e:PEvento;
    begin
      new(e);
      if prima<>nil then begin
        prima^.succ:=e;
        ListaEventi:=Prima;
      end;
      with e^ do begin
        x1:=m1;  y1:=n1;
        x2:=m2;  y2:=n2;
        azione:=az;
        succ:=nil;
      end;
      NuovoEvento:=e;
    end;
  {** X- **}

  function Reazione(m,n:integer):PReazione;
    var e:PEvento;
    begin
      e:=ListaEventi;
      while not (m in [e^.x1..e^.x2]) or not(n in [e^.y1..e^.y2]) and (e<>nil) do
        e:=e^.succ;
      if e<>nil then reazione:=@e^.azione
                else reazione:=@NessunaReazione;
    end;

   {****************** Oggetto - OTScrollBar - *******************}

  constructor OTScrollBar.Init;
    begin
      attributo:=attr and $7F;
      visibili:=dim;
      precVis:=visibili;
      GVS:=(dim-2)*2;
      x:=cx;  y:=cy;
      getMem(sb,visibili-2);
      pos:=0;
      ntot:=0;
      precNtot:=0;
      Visualizza;
      DefaultControlCharts;
    end;

  destructor OTScrollBar.Done;
    begin
      freemem(sb,visibili-2);
    end;

  procedure OTScrollBar.SetControlCharts;
    begin
      ch1:=c1;
      ch2:=c2;
      ch3:=c3;
      chN:=neutro;
    end;

  procedure OTScrollBar.DefaultControlCharts;  begin end;

  procedure OTScrollBar.Visualizza;  begin end;

  procedure OTScrollBar.ScrollBar;  begin end;

  procedure OTScrollBar.CalcolaStringa;
    const limite:real = 2.499999999;
    var i:word;
    begin
      if visibili>=ntot then for i:=0 to visibili-3 do sb^[i]:=ch2
      else begin
        if (precNtot<>ntot) or (visibili<>precVis) then begin
          intervallo:=ntot/(gvs);
          dimE:=round(gvs*visibili/ntot);
          if dimE<1 then dimE:=1;
          maxT:=gvs-dimE+1;
          precNtot:=ntot;
          precVis:=visibili;
        end;
        posT:=round((0.5+pos)/intervallo);
        if posT=0 then posT:=1;
        if posT>maxT then posT:=maxT;
        for i:=0 to visibili-3 do sb^[i]:=chN;
        if intervallo>limite then i:=(posT-1) div 2
                             else i:=posT div 2;
        case dimE of
        1:if odd(posT) then sb^[i]:=ch3
                       else sb^[i]:=ch1;
        2:if odd(posT) then sb^[i]:=ch2
                       else begin
                              sb^[i]:=ch1;  sb^[i+1]:=ch3;
                            end;
        else if odd(dimE) then
               if odd(posT) then begin
                 for i:=i to dimE div 2+i-1 do sb^[i]:=ch2;
                 sb^[i+1]:=ch3;
               end
               else begin
                 if intervallo>limite then inc(i);
                 sb^[i-1]:=ch1;
                 for i :=i+1 to dimE div 2 +i do sb^[i-1]:=ch2;
               end
             else
               if odd(posT) then for i:=i to dimE div 2 +i-1 do sb^[i]:=ch2
               else begin
                 if intervallo>limite then inc(i);
                 sb^[i-1]:=ch1;
                 for i:=i to dimE div 2 +i-2 do sb^[i]:=ch2;
                 sb^[i+1]:=ch3;
               end;
        end;
      end;
    end;

  procedure OTScrollBarHoriz.ScrollBar;
    var i:word;
        cx,cy:integer;
    begin
      if (p<>pos) or (tot<>ntot) then begin
        pos:=p;  ntot:=tot;
        CalcolaStringa;
        cx:=x+lo(windMin)+1;
        cy:=y+hi(windMin);
        for i:=1 to visibili-2 do begin
          with video.ch[cy,cx] do begin
            car:=sb^[i-1];
            attr:=attributo;
          end;
          inc(cx);
        end;
      end;
    end;

  procedure OTScrollBarHoriz.DefaultControlCharts;
    begin
      SetControlCharts('É','Ü','­','±');
    end;

  procedure OTScrollBarHoriz.Visualizza;
    var i:word;    attr:byte;
    begin
      attr:=textattr;
      textattr:=attributo;
      gotoxy(x,y);
      write(#17);
      for i:=2 to visibili-1 do write('±');
      write(#16);
      textattr:=attr;
    end;

  procedure OTScrollBarVert.ScrollBar;
    var i:word;
        cx,cy:integer;
    begin
      if (p<>pos) or (tot<>ntot) then begin
        pos:=p; ntot:=tot;
        CalcolaStringa;
        cx:=x+lo(windMin);
        cy:=y+hi(windMin)+1;
        for i:=1 to visibili-2 do begin
          with video.ch[cy,cx] do begin
            car:=sb^[i-1];
            attr:=attributo;
          end;
          inc(cy);
        end;
      end;
    end;

  procedure OTScrollBarVert.DefaultControlCharts;
    begin
      SetControlCharts('ç','¨','ï','±');
    end;

  procedure OTScrollBarVert.Visualizza;
    var i:word;    attr:byte;
    begin
      attr:=textattr;
      textattr:=attributo;
      gotoxy(x,y);
      write(#30);
      for i:=2 to visibili-1 do begin
        gotoxy(x,y+i-1);
        write('±');
      end;
      gotoxy(x,y+i);
      write(#31);
      textattr:=attr;
    end;


  {*************************************}

begin
  if lastmode=7 then visualVideo:=Ptr($B000,0) else VisualVideo:=ptr($B800,0);
  ListaEventi:=nil;
  CodaEventi:=nil;
end.



