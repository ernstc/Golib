{ Ernesto CIANCIOTTA Productions }

{ *************************************** }
{ *                                     * }
{ * Modulo della libreria GOLIB per la  * }
{ * gestione dei men—.                  * }
{ *                                     * }
{ * Scritto con Turbo Pascal 7.0        * }
{ *                                     * }
{ *************************************** }

{$D+}
{$L+}


{$DEFINE bitbtl_esteso }

{ La definizione, indicata sopra, implementa un uso esteso delle procedure
  di BITBTL nella gestione dei delle viste dei men—.
  L'implementazione genera un notevole INCREMENTO di PRESTAZIONI, ma al
  tempo stesso un una maggiore richiesta di memoria libera nello HEAP.
  Questa definizione pu• quindi essere attivata solo nelle versioni
  definitive e nei programmi demo che non girano all'interno dell'IDE.
}

UNIT Menu;

INTERFACE

  uses
         codici,
         {$IFDEF debugging}
         crt,
         {$ENDIF}
         strings,
         mouse,
         graph,
         graftool,
         fonts,
         resman,
         bitmaps,
         golib_h,
         applic,
         golib9,
           dispfile,
         statusln;

const
         SelectedItemColor:word=7;
         SelectedTextColor:word=0;
         DeselectedTextColor:word=0;
         Time_for_Remark:word=200;

type
        PMenuPP   = ^TMenuPP;
        PMenuLine = ^TMenuLine;


        TMenuLine = record
          HotKey:char;
          Event:word;
          descr:PChar;
          attivo:boolean;
          selezionato:boolean;
          SubMenu:PMenuPP;
          succ:PMenuLine;
        end;


        TMenuPP   = record
          HotKey:char;
          Event:word;
          HelpContext:word; { Codice per l'help e i messaggi della statusline }
          SubMenu:PMenuPP;
          attributes: byte; {* vedi schema per chiarimenti *}
          succ:PMenuPP;
          case boolean of
            false: (descr:PChar);
            true : (bmp_Rlsd,
                    bmp_Prsd:^HCA);
        end;


        OPMenuPopUp = ^OTMenuPopUp;


        PSelectItemPar = ^TSelectItemPar;
        TSelectItemPar = record
          _r:OTRect;
          posiz:byte;
          stringa:string;
          ch:char;
        end;


        OPMenuLine = ^OTMenuLine;
        OTMenuLine = object (OTView)
          constructor Init(_menu_:PMenuLine);
          destructor Done; virtual;
          procedure Disegna; virtual;
          procedure Adjust; virtual;
          procedure ExecMessage(var Message:TMessage); virtual;
          procedure LinkToStatusLine(statusLn:pointer);
        public
          { Le variabili che seguono servono per passare i parametri al metodo
            SelectItem che viene chiamato tramite la procedura DrawRefreshListProc. }
          SIPar:PSelectItemPar;
          procedure SelectItem; virtual;   {** indicizzato VMI ** vedi GOLIB_H **}
        private
          menu:PMenuLine;
          menuPP:OPMenuPopUp;
          items:OTRects;
          statusLine:OPStatusLine;
        end;


        OTMenuPopUp = object (OTView)
          constructor Init(x,y:integer;var no_r,in_r:OTRects; _menu_:PMenuPP);
          destructor Done; virtual;
          procedure Disegna; virtual;
          function GetReaction:word;
          procedure LinkToStatusLine(statusLn:pointer);
        private
          menu:PMenuPP;
          menuPP:OPMenuPopUp;
          out_rect:OPRects;
          in_rect:OPRects;
          PrecImage:HCA;
          statusLine:OPStatusLine;
        end;


{ Funzione che, dato un codice di tasto esteso, restituisce una stringa che descrive la combianzione
  di tasti. }
  function GetKeyString(KeyCode:word):string;



{ Funzioni di utilit… per la creazione dei men—. }

  function NewItem(d:string; _ID:word; _Attivo:boolean; _SubMenu:PMenuPP; next:PMenuLine):PMenuLine;
  function NewItemPP(d:string; _ID:word; HelpCtx:word; ItemAttributes:byte; _SubMenu, next:PMenuPP):PMenuPP;
  function NewBitmapPP(_ID:word; HelpCtx:word; BitmapRlsd,BitmapPrsd:word; ItemAttributes:byte;
                       _SubMenu, next:PMenuPP):PMenuPP;
  function NewBitmapPP_GetRES(_ID:word; HelpCtx:word; BitmapID:word; RES:pointer; NRes:word; ItemAttributes:byte;
                              _SubMenu, next:PMenuPP):PMenuPP;
  function NewBitmapPP_GetRES_Str(_ID:word; HelpCtx:word; BitmapID:string; RES:pointer; NRes:word;ItemAttributes:byte;
                                  _SubMenu, next:PMenuPP):PMenuPP;
  function NewBitmapPP_LoadRES_Str(_ID:word; HelpCtx:word; BitmapID, FileRES:string; ItemAttributes:byte;
                                   _SubMenu, next:PMenuPP):PMenuPP;
  function NewBitmapPP_LoadRES(_ID:word; HelpCtx:word; BitmapID:word; FileRES:string; ItemAttributes:byte;
                               _SubMenu, next:PMenuPP):PMenuPP;
  function NewBitmapPP_Load(_ID:word; HelpCtx:word; FileName:string; ItemAttributes:byte;
                            _SubMenu, next:PMenuPP):PMenuPP;
  function NewSEPARATOR_PP(next:PMenuPP):PMenuPP;


{N.B.: Se una voce Š disattivata e alla stessa voce Š associato un submen—,
       allora quest'ultimo deve avere tutte le voci disattivate. }


IMPLEMENTATION


   const
         _spazio_verticale_=2;
         line_space=5;

         { Se TRUE allora il OTMenuPopUp.Done provveder… a distruggere la
           lista dei suoi items degli items dei submen— collegati. }
         CompletePopUpDestruction: boolean = true;

         { Se TRUE allora tutte le voci dei submen— che verranno creati
           saranno disattivati qualunque sia l'impostazione originaria delle
           voci. }
         AllItemsDisabled        : boolean = false;


         _k=5;
         _spazio=18;
         _spazio_div_2=_spazio div 2;
         _spazio_a_sinistra_=28;
         _spazio_in_PopUp_=_spazio_a_sinistra_*2;
         _spazio_in_alto_=7;

         NPicth = 4;

   type
         TPicth  = record
            picth: word;
            cod_SubPP,
            cod_Mark: char;
         end;

         TPicths = array[1..NPicth] of TPicth;

   const
         Picths: TPicths =
            ((picth: 7 ; cod_SubPP:#7  ; cod_Mark:#1 ),
             (picth:10 ; cod_SubPP:#8  ; cod_Mark:#2 ),
             (picth:14 ; cod_SubPP:#9  ; cod_Mark:#3 ),
             (picth:24 ; cod_SubPP:#10 ; cod_Mark:#4 ));

   var
         M_Symboles:OTFont;

         SubPP_Symbole,
         Maked_Symbole:Char;

         ItemAttiva:OPRect;
         dir_sin_:boolean;



   function GetKeyString(KeyCode:word):string;
     type TKeyCode = record
             case word of
             0: (KeyCode:word);
             1: (CharCode: Char;
                 ScanCode: Byte);
          end;
     var  kb:TKeyCode absolute KeyCode;
     begin

     end;




   procedure Menu_Symboles; external; {$L golib_f.obj}


   procedure SetMenuSymboles(_picth_:word);
     var i:byte;
     begin
       for i:=1 to NPicth do if Picths[i].picth >= _picth_ then break;
       SubPP_Symbole:=Picths[i].cod_SubPP;
       Maked_Symbole:=Picths[i].cod_Mark;
     end;


   procedure DisposeMenuPP(_m_:PMenuPP);
     var buf:PMenuPP;
     begin
       buf:=_m_;
       while _m_<>nil do begin
         _m_:=buf^.succ;
         if buf^.SubMenu<>nil then DisposeMenuPP(buf^.subMenu);
         if buf^.descr<>nil then begin
           if (buf^.attributes and itBitmap)=itBitmap then begin
             if buf^.bmp_Rlsd<>nil then begin
               DestroyDC(buf^.bmp_Rlsd^);
               dispose(buf^.bmp_Rlsd);
             end;
             if buf^.bmp_Prsd<>nil then begin
               DestroyDC(buf^.bmp_Prsd^);
               dispose(buf^.bmp_Prsd);
             end;
           end
           else freemem(buf^.descr,StrLen(buf^.descr)+1);
         end;
         dispose(buf);
         buf:=_m_;
       end;
     end;


   { ------------------- Descrizione degli oggetti ------------------------}


                      { ----- OTMenuLine ----- }
   constructor OTMenuLine.Init(_menu_:PMenuLine);
     var rect:OTRect;
         ccLen, txtLen:word;
     begin
       inherited Init(Null_ID,r);
       menu:=_menu_;
       items.ResetList;
       ccLen:=MenuLFont^.TextLength('@',0,0);
       while _menu_<>nil do begin
         items.newRect(rect);
         txtLen:=MenuLFont^.TextLength(StrPas(_menu_^.descr),0,0)+ccLen;
         if txtLen>MinDimX then MinDimX:=txtLen;
         _menu_:=_menu_^.succ;
       end;
       statusLine:=nil;
       SysConfig:=SysConfig or cfPostDraw
                            or cfLPriority;
       MouseReactionMask:=MouseReactionMask and not rcMultiClick;
     end;


   destructor OTMenuLine.Done;
     var buf:PMenuLine;
     begin
       buf:=menu;
       while menu<>nil do begin
         menu:=buf^.succ;
         if buf^.SubMenu<>nil then DisposeMenuPP(buf^.subMenu);
         freemem(buf^.descr,StrLen(buf^.descr)+1);
         dispose(buf);
         buf:=menu;
       end;
       OTView.Done;
     end;



   const meno=3;
         menotxt=2;
         interlinea=6;
         interlinea_4=interlinea-4;
         spazio_sopra_txt=interlinea_4 div 2;



   procedure OTMenuLine.Disegna;
     var buf:PMenuLine;
         item:OPRects;
         stringa:string;
         k:word;
         ch:char;
         posiz:byte;
         item_rect:OTRect;
     begin
       {setfillstyle(1,8);
       with r do bar(x1,y1,x2,y2);}
       setfillstyle(1,SelectedItemColor);
       textcolor:=0;
       buf:=menu;
       item:=@items;
       k:=_k;
       if not item^.rect.Zero then
         while item<>nil do begin
           item_rect:=item^.rect;
           item_rect.MoveRel(r.x1,r.y1);
           if buf^.selezionato then with Item_rect do
             bar(x1,y1,x2,y2);
           stringa:=StrPas(buf^.descr);
           posiz:=pos('@',stringa);
           if posiz<>0 then begin
             ch:=stringa[posiz+1];
             delete(stringa,posiz,1);
           end;
           if buf^.attivo then begin
             if posiz<>0 then begin
               setcolor(textcolor);
               MoveTo(_spazio_div_2+1+item_rect.x1+MenuLFont^.TextLength(copy(stringa,1,pos(ch,stringa)-1),0,0),
                      item_rect.y2-menotxt-interlinea_4+spazio_sopra_txt);
               LineRel(MenuLFont^.TextLength(ch,0,0)-1,0);
             end;
             MenuLFont^.drawtext(_spazio_div_2+1+item_rect.x1,item_rect.y1+1+meno-menotxt+spazio_sopra_txt,TextLeft,stringa);
           end
           else begin
             if posiz<>0 then
               Line_In_3d(_spazio_div_2+2+item_rect.x1-1+MenuLFont^.TextLength(copy(stringa,1,pos(ch,stringa)-1),0,0),
                          item_rect.y2-menotxt-interlinea_4+spazio_sopra_txt,
                          _spazio_div_2+2+item_rect.x1-1+MenuLFont^.TextLength(copy(stringa,1,pos(ch,stringa)-1),0,0)+
                          MenuLFont^.TextLength(ch,0,0)-1,
                          item_rect.y2-menotxt-interlinea_4+spazio_sopra_txt);
             MenuLFont^.drawtextIn(_spazio_div_2+2+item_rect.x1,item_rect.y1+1+meno-menotxt+spazio_sopra_txt,TextLeft,stringa);
           end;
           buf:=buf^.succ;
           item:=item^.succ;
         end;
     end;


   procedure OTMenuLine.Adjust;
     var rect:OTRect;
         len:word;
         h:word;
         x,y:word;
         str:string;
         c:byte;
         buf:OPRects;
         _menu_:PMenuLine;
     begin
       buf:=@items;
       _menu_:=menu;
       x:=0;
       y:=9-meno;
       h:=menuLFont^.GetHeight;
       while _menu_<>nil do begin
         _menu_^.selezionato:=false;
         str:=StrPas(_menu_^.descr);
         c:=pos('@',str);
         if c<>0 then delete(str,c,1);
         len:=menuLFont^.TextLength(str,0,0);
         rect.Assign(x,y-meno,x+len+_spazio,y+h+interlinea_4);
         inc(x,len+_spazio);
         if rect.x2+r.x1>r.x2 then begin
           inc(r.y2,h+interlinea);
           inc(y,h+interlinea);
           rect.Assign(0,y-meno,len+_spazio,y+h+interlinea_4);
           x:=len+_spazio;
         end;
         buf^.rect:=rect;
         buf:=buf^.succ;
         _menu_:=_menu_^.succ;
       end;
       with R do begin
         DimX:=x2-x1;
         DimY:=y2-y1;
       end;
     end;


   procedure OTMenuLine.SelectItem;
     begin
       textcolor:=SelectedTextColor;
       setfillstyle(1,SelectedItemColor);
       with SIPar^ do begin
         with R do begin
           bar(0,0,dimx,dimy);
           if posiz<>0 then begin
             setcolor(textcolor);
             MoveTo(x1+_spazio_div_2+MenuLFont^.TextLength(copy(stringa,1,pos(ch,stringa)-1),0,0)+1,
                    y1+DimY-menotxt-interlinea_4+spazio_sopra_txt);
             LineRel(MenuLFont^.TextLength(ch,0,0)-1,0);
           end;
           MenuLFont^.drawtext(x1+_spazio_div_2+1,y1+meno-menotxt+spazio_sopra_txt+1,TextLeft,stringa);
         end;
       end;
     end;


   procedure OTMenuLine.ExecMessage(var Message:TMessage);
     label  EndWhile;
     var buf: PMenuLine;
         vis, __r: OTRect;
         clip, precFlag, primo, _ok_: boolean;
         len, dim_image: word;
         item: OPRects;
         rect,in_r: OTRects;
         PrecImage: HCA;
         VisibleZone: PRefreshRectList;
         _x1_, _x2_, _dx_,
         dx, dy: integer;
         PtrSelectItem: pointer;
         msg:TMessage;
         answer:word;

     procedure DeSelectItem;
       begin
         clip:=ClippingForBITBTL;
         ClippingForBITBTL:=false;
         if __r.intersect(FullRect,__r) then
           with __r do BitBtl(PrecImage,VideoDC,0,0,x1,y1,DimX+1,DimY+1);
         DestroyDC(PrecImage);
         ClippingForBITBTL:=clip;
       end;

     begin
       case Message.Message of
         EvKEYDOWN: begin
           end;
         EvMOUSE_L_PRESSED: begin
             msg:=Message;
             new(SIPar);
             PtrSelectItem:=GetVMP(typeOf(Self),VMI_OTMenuLine_SelectItem);
             answer:=Null_ID;
             dir_sin_:=true;
             setwritemode(0);
             primo:=true;
             __r.assign(0,0,0,0);
             _ok_:=true;
             buf:=nil;
             while msg.Message<>EvMOUSE_L_RELEASED do begin
               ItemAttiva:=nil;
               buf:=menu;
               item:=@items;
               while buf<>nil do  with SIPar^ do begin
                 stringa:=StrPas(buf^.descr);
                 posiz:=pos('@',stringa);
                 if posiz<>0 then begin
                   ch:=stringa[posiz+1];
                   delete(stringa,posiz,1);
                 end;
                 if not buf^.attivo then begin
                   buf:=buf^.succ;
                   item:=item^.succ;
                   continue;
                 end;
                 _r:=item^.rect;
                 _r.MoveRel(r.x1,r.y1);
                 if _Father_<>nil then begin
                   if _r.x2>_Father_^.r.x2 then _r.x2:=_Father_^.r.x2;
                   if _r.y2>_Father_^.r.y2 then _r.y2:=_Father_^.r.y2;
                 end;
                 if _r.XYIn(msg.Mcx,msg.Mcy) then begin
                   buf^.selezionato:=true;
                   if not primo and _ok_ then DeSelectItem
                                         else primo:=false;
                   __r:=_r;
                   { Inizio selezione voce }
                   vis:=_r;
                   if _r.Intersect(FullRect,_r) then begin
                     clip:=ClippingForBITBTL;
                     ClippingForBITBTL:=false;
                     CreateCompatibleDC(PrecImage,_r.DimX+1,_r.DimY+1);
                     BitBtl(VideoDC,PrecImage,_r.x1,_r.y1,0,0,_r.DimX+1,_r.DimY+1);
                     ClippingForBITBTL:=clip;
                     VisibleZone:=GetVisibleZone(@Self,@_r,NullObj);
                     _r:=vis;
                     vis:=R;
                     R:=_r;
                     hidemousecursor;
                     DrawRefreshListProc(VisibleZone,@Self,PtrSelectItem,nil,ObjectNoParam);
                     showmousecursor;
                     R:=vis;
                     DisposeRefreshList(VisibleZone);
                   end;
                   { Fine selezione voce }
                   _ok_:=true;
                   if buf^.subMenu=nil then begin
                     while (msg.Message<>EvMOUSE_L_RELEASED ) and
                           _r.XYIn(msg.Mcx,msg.Mcy) do begin
                       WaitNextMouseMessage(msg, rcMove or
                                                 rcLPressed or
                                                 rcLReleased);
                     end;
                     buf^.selezionato:=false;
                     goto EndWhile;
                   end
                   else begin
                     in_r.ResetList;
                     in_r.newRect(_r);
                     rect.resetList;
                     rect.newRect(r);
                     { Creazione del menu Pop-Up }
                     New(MenuPP, Init(_r.x1,_r.y2,rect,in_r,buf^.submenu));
                     MenuPP^.LinkToStatusLine(StatusLine);
                     MenuPP^.PutOnDeskTop;
                     ShowMouseCursor;
                     mcx:=Msg.mcx;
                     mcy:=Msg.mcy;
                     answer:=MenuPP^.GetReaction;
                     precFlag:=CompletePopUpDestruction;
                     CompletePopUpDestruction:=false;
                     Dispose(MenuPP, Done);
                     CompletePopUpDestruction:=precFlag;
                     dir_sin_:=true;
                   end;
                   buf^.selezionato:=false;
                   break;
                 end
                 else begin
                   item:=item^.succ;
                   buf:=buf^.succ;
                 end;
               end; { while }
               if (buf=nil) and _ok_ and not __r.Zero then begin
                 DeSelectItem;
                 _ok_:=false;
               end;
               WaitNextMouseMessage(msg, rcMove or
                                         rcLPressed or
                                         rcLReleased);
       EndWhile:
             end; { while }
             if buf<>nil then begin
               DeSelectItem;
               if buf^.subMenu=nil then answer:=buf^.Event;
             end;
             dispose(SIPar);
             {Messaggio alla linea di stato}
             if StatusLine<>nil then StatusLine^.SetMessage(MAIN_MESSAGE_FIELD,'Wait...');
             msg.HNDL:=_LINE_MENU_;
             msg.Message:=answer;
             SendMessage(msg);
             {Messaggio alla linea di stato}
             if StatusLine<>nil then StatusLine^.SetMessage(MAIN_MESSAGE_FIELD,'Ready');
           end;
       end;
     end;


   procedure OTMenuLine.LinkToStatusLine(statusLn:pointer);
     begin
       StatusLine:=statusLn;
     end;


                  { ----- OTMenuPopUp ----- }
   constructor OTMenuPopUp.Init(x,y:integer;var no_r,in_r:OTRects; _menu_:PMenuPP);
     var buf:PMenuPP;
         len, dimFont:word;
         stringa:string;
         ch:char;
         posiz:integer;
         dy:word;
         _x1_, _x2_, _dx_: integer;

     begin
       dy:=_spazio_in_alto_;
       menu:=_menu_;
       DimFont:=MenuPPFont^.GetHeight+1;
       if x<0 then x:=0;
       if y<0 then y:=0;
       r.assign(x,y,x+_spazio_in_PopUp_,y+dy);
       buf:=menu;
       while buf<>nil do begin
         buf^.attributes:=buf^.attributes and __itSelected;
         if buf^.SubMenu<>nil then buf^.attributes:=buf^.attributes and __itMarked;
         if (buf^.attributes and itSeparator)=itSeparator then inc(r.y2,line_space+_spazio_verticale_)
         else with r do begin
           if (buf^.attributes and itBitmap)=itBitmap then begin
             { Regola l'altezza del pop-up }
             inc(y2,buf^.bmp_Rlsd^.DimY+_spazio_verticale_);
             len:=buf^.bmp_Rlsd^.DimX;
           end
           else begin
             { Regola l'altezza del pop-up }
             inc(y2,DimFont+_spazio_verticale_);
             stringa:=StrPas(buf^.descr);
             posiz:=pos('@',stringa);
             if posiz<>0 then begin
               ch:=stringa[posiz+1];
               delete(stringa,posiz,1);
             end;
             len:=MenuPPFont^.TextLength(stringa,0,0);
           end;
           { Regola la larghezza del pop-up }
           if DimX < (len+_spazio_in_PopUp_) then begin
             x2:=x1+len+_spazio_in_PopUp_;
             DimX:=x2-x1;
           end;
         end;
         buf:=buf^.succ;
       end;
       { In questa fase si posiziona il rettangolo del pop-up affinchŠ non
         esca dal bordo dello schermo. }
       inc(r.y2,1);
       r.DimY:=r.y2-r.y1;
       if not dir_sin_ then begin
         r.x2:=ItemAttiva^.x1+2;
         r.x1:=r.x2-r.DimX;
       end;
       if r.x1<0 then begin
         dir_sin_:=true;
         r.x1:=ItemAttiva^.x2-3;
         r.x2:=r.x1+r.DimX;
       end;
       out_rect:=@no_r;
       in_rect:=@in_r;
       if (r.x2>_MaxXResolution) then begin
         if ItemAttiva=nil then
           if (in_rect<>nil) and (in_rect^.rect.x2<MaxXResolution) then
             r.x2:=in_rect^.rect.x2
           else
             r.x2:=_MaxXResolution
         else begin
           dir_Sin_:=false;
           r.x2:=ItemAttiva^.x1+2;
         end;
         r.x1:=r.x2-r.DimX;
       end;
       if (r.y2>_MaxYResolution) then begin
         if ItemAttiva=nil then
           r.y2:=r.y1-in_rect^.rect.dimY
         else
           r.y2:=ItemAttiva^.y2;
         r.y1:=r.y2-r.DimY;
       end;
     {$IFDEF bitbtl_esteso}
       with r do begin
         _x1_:=x1-(x1 mod 8);
         _x2_:=_x1_+DimX+16;
         _x2_:=_x2_-(_x2_ mod 8);
         _dx_:=_x2_-_x1_;
         CreateCompatibleDC(PrecImage,_dx_,r.DimY+1);
         BitBtl(VideoDC,PrecImage,_x1_,y1,0,0,_dx_,r.DimY+1);
       end;
     {$ENDIF}
       statusLine:=nil;
       inherited Init(Null_ID,r);
       SysConfig:=SysConfig and not cfSelectable
                            or cfAlwaysAsFirst;
     end;


   destructor OTMenuPopUp.Done;
     var _x1_, _x2_, _dx_: integer;
       {$IFDEF bitbtl_esteso}
         lk:boolean;
       {$ELSE}
         _SM:TSortMethod;
       {$ENDIF}
     begin
     {$IFDEF bitbtl_esteso}
       with r do begin
         ClippingForBITBTL:=false;
         _x1_:=x1-(x1 mod 8);
         _x2_:=_x1_+DimX+16;
         _x2_:=_x2_-(_x2_ mod 8);
         _dx_:=_x2_-_x1_;
         BitBtl(PrecImage,VideoDC,0,0,_x1_,y1,_dx_,DimY+1);
         ClippingForBITBTL:=true;
         DestroyDC(PrecImage);
       end;
       lk:=lookvideo;
       lookvideo:=false;
     {$ELSE}
       _SM:=RectSortMethod;
       RectSortMethod:=TLBR;
     {$ENDIF}
       in_rect^.DisposeList;
       out_rect^.DisposeList;
       if CompletePopUpDestruction then DisposeMenuPP(menu);
       inherited Done;
     {$IFDEF bitbtl_esteso}
       lookvideo:=lk;
     {$ELSE}
       RectSortMethod:=_SM;
     {$ENDIF}
     end;


   procedure OTMenuPopUp.Disegna;
     const itMark = itMarcable or itMarked;
     var buf:PMenuPP;
         stringa:string;
         dy,DimFont:word;
         posiz:integer;
         ch:char;

     begin
       { Sistema le variabili che contengono il codice ascii dei simboli da usare
         per i subMenu e le voci marcabili.
         Questo per selezionare dei simboli che abbiano una grandezza adatta alla
         dimensione del font utilizzato per scrivere le voci del menu.}
       SetMenuSymboles(MenuPPFont^.GetPicth);
       with r do Window3D(x1,y1,x2,y2,8);
       buf:=menu;
       dy:=_spazio_in_alto_;
       DimFont:=MenuPPFont^.GetHeight+1;
       setfillstyle(1,SelectedItemColor);
       while buf<>nil do begin
         if (buf^.attributes and itSeparator)=itSeparator then begin
           with r do line_In_3d(x1+3,y1+dy,x2-5,y1+dy);
           inc(dy,line_space+_spazio_verticale_);
           buf:=buf^.succ;
           continue;
         end;
         if (buf^.attributes and itSelected)=itSelected then begin
           if AllItemsDisabled
           then begin
             setColor(SelectedItemColor);
             with r do rectangle(x1+3,y1+dy-2,x2-3-M_Symboles.TextLength(Maked_Symbole,0,0)-2,y1+dy+MenuPPFont^.GetHeight-1)
           end
           else begin
             setcolor(SelectedTextColor);
             textcolor:=SelectedTextColor;
             with r do bar(x1+3,y1+dy-2,x2-3,y1+dy+MenuPPFont^.GetHeight-1);
           end;
         end
         else begin
           setcolor(DeselectedTextColor);
           textcolor:=DeselectedTextColor;
         end;
         if (buf^.attributes and itMark)=itMark then begin
           if ((buf^.attributes and itEnable)=0) or
              AllItemsDisabled
           then
             M_Symboles.DrawTextIn(r.x1+4,r.y1+dy-1,TextLeft,Maked_Symbole)
           else
             M_Symboles.DrawText(r.x1+4,r.y1+dy-1,TextLeft,Maked_Symbole);
         end;
         if buf^.subMenu<>nil then
           M_Symboles.DrawText(r.x2-1,r.y1+dy-1,TextRight,SubPP_Symbole);
         if (buf^.attributes and itBitmap)=itBitmap then begin
           BitBtl(buf^.bmp_Rlsd^,VideoDC,0,0,r.x1+_spazio_a_sinistra_,r.y1+dy-1,buf^.bmp_Rlsd^.DimX,buf^.bmp_Rlsd^.DimY);
           if ((buf^.attributes and itEnable)=0) or AllItemsDisabled
           then begin
             SetWriteMode(5);
             SetColor(15);
             GLBPattern:=GranaPattern;
             BarPat(r.x1+_spazio_a_sinistra_,r.y1+dy-1,
                    buf^.bmp_Rlsd^.DimX+r.x1+_spazio_a_sinistra_,buf^.bmp_Rlsd^.DimY+r.y1+dy-1);
             GLBPattern:=FullPattern;
             SetWriteMode(0);
           end;
           inc(dy,buf^.bmp_Rlsd^.DimY+_spazio_verticale_);
         end
         else begin
           stringa:=StrPas(buf^.descr);
           posiz:=pos('@',stringa);
           if posiz<>0 then begin
             ch:=stringa[posiz+1];
             delete(stringa,posiz,1);
           end;
           if ((buf^.attributes and itEnable)=0) or
              AllItemsDisabled
           then begin
             if posiz<>0 then Line_In_3d(r.x1+_spazio_a_sinistra_-1+
                                         +MenuPPFont^.TextLength(copy(stringa,1,pos(ch,stringa)-1),0,0),
                                         r.y1+dy+DimFont-3,
                                         MenuPPFont^.TextLength(ch,0,0)+r.x1+_spazio_a_sinistra_-2+
                                         +MenuPPFont^.TextLength(copy(stringa,1,pos(ch,stringa)-1),0,0),
                                         r.y1+dy+DimFont-3);
             MenuPPFont^.DrawTextIn(r.x1+_spazio_a_sinistra_,r.y1+dy-1,TextLeft,stringa)
           end
           else begin
             if posiz<>0 then begin
               setcolor(textcolor);
               MoveTo(r.x1+_spazio_a_sinistra_+MenuPPFont^.TextLength(copy(stringa,1,pos(ch,stringa)-1),0,0),
                      r.y1+dy+DimFont-3);
               LineRel(MenuPPFont^.TextLength(ch,0,0),0);
             end;
             MenuPPFont^.DrawText(r.x1+_spazio_a_sinistra_,r.y1+dy-1,TextLeft,stringa);
           end;
           inc(dy,DimFont+_spazio_verticale_);
         end;
         buf:=buf^.succ;
       end;
     end;



   function OTMenuPopUp.GetReaction:word;
     var item:PMenuPP;
         __r,_r:OTRect;
         stringa:string;
         posiz:byte;
         ch:char;
         dy,height:word;
         in_r,out_r:OTRects;
         bitmap,
         itemEnable,
         primo,
         _ok_,
         precAllItemsDisabled,
         precFlag,
         direzione:boolean;
         PrecItemImage:HCA;
         MouseOnPD:boolean; { Questo flag serve per stabilire se il mouse
                              Š entrato almeno per una volta nell'area
                              del menu PD. Se il bottone viene rilasciato
                              e MouseOnPD Š false allora la procedura non
                              termina. }
         msg:TMessage;

     function OutRects:boolean;
       var buf:OPRects;
           b1,b2:boolean;
       begin
         b1:=false;
         buf:=out_rect;
         while (buf<>nil) and not b1 do begin
           b1:=buf^.rect.XYIn(mcx,mcy);
           buf:=buf^.succ;
         end;
         b2:=false;
         buf:=in_rect;
         while (buf<>nil) and not b2 do begin
           b2:=buf^.rect.XYIn(mcx,mcy);
           buf:=buf^.succ;
         end;
         if not b1 and b2 then OutRects:=true
                          else OutRects:=not(b1 xor b2);
       end;

     procedure SelectItem;
       var vis:OTRect;
           _x1_, _x2_, _dx_,
           dx,dy:integer;
           clip:boolean;
           bmp_HCA:^HCA;
       begin
         clip:=ClippingForBITBTL;
         ClippingForBITBTL:=false;
         dx:=0;
         dy:=0;
         vis:=_r;
         with vis do begin
           if x2>r.x2 then x2:=r.x2;
           if x2>_MaxXResolution then x2:=_MaxXResolution;
           if x1<r.x1 then x1:=r.x1;
           if x1<0 then begin
             dx:=x1;
             x1:=0;
           end;
           if y2>r.y2 then y2:=r.y2;
           if y2>_MaxYResolution then y2:=_MaxYResolution;
           if y1<r.y1 then y1:=r.y1;
           if y1<0 then begin
             dy:=y1;
             y1:=0;
           end;
           DimX:=x2-x1;
           DimY:=y2-y1;
           setviewPort(x1,y1+1,x2,y2,true);
           _x1_:=x1-(x1 mod 8);
           _x2_:=_x1_+DimX+16;
           _x2_:=_x2_-(_x2_ mod 8);
           _dx_:=_x2_-_x1_;
           CreateCompatibleDC(PrecItemImage,_dx_,DimY+1);
           BitBtl(VideoDC,PrecItemImage,_x1_,y1,0,0,_dx_,DimY+1);
         end;
         textcolor:=SelectedTextColor;
         setfillstyle(1,SelectedItemColor);
         HideMouseCursor;
         if itemEnable and not AllItemsDisabled then begin
           with _r do bar(3,0,dimx-3,dimy);
           if ((item^.attributes and itMarcable)=itMarcable) and
               ((item^.attributes and itMarked)=itMarked) then
             M_Symboles.DrawText(4,1,TextLeft,Maked_Symbole);
           if item^.subMenu<>nil then
             M_Symboles.DrawText(dx+_r.DimX-1,dy+1,TextRight,SubPP_Symbole);
           if bitmap then begin
             if item^.bmp_Prsd=nil
               then bmp_HCA:=pointer(item^.bmp_Rlsd)
               else bmp_HCA:=pointer(item^.bmp_Prsd);
             BitBtl(bmp_HCA^,VideoDC,0,0,_r.x1+_spazio_a_sinistra_,_r.y1+dy+2,bmp_HCA^.DimX,height)
           end
           else begin
             stringa:=StrPas(item^.descr);
             posiz:=pos('@',stringa);
             if posiz<>0 then begin
               ch:=stringa[posiz+1];
               delete(stringa,posiz,1);
             end;
             if posiz<>0 then begin
               setcolor(textcolor);
               MoveTo(dx+_spazio_a_sinistra_+MenuPPFont^.TextLength(copy(stringa,1,pos(ch,stringa)-1),0,0),
                      dy+_r.DimY-2);
               LineRel(MenuPPFont^.TextLength(ch,0,0),0);
             end;
             MenuPPFont^.drawtext(dx+_spazio_a_sinistra_,dy+1,TextLeft,stringa);
           end;
         end
         else begin
           setcolor(SelectedItemColor);
           with _r do rectangle(3,0,dimx-3-M_Symboles.TextLength(Maked_Symbole,0,0)-2,dimy-1);
         end;
         ShowMouseCursor;
         setViewPort(0,0,_MaxXResolution,_MaxYResolution,true);
         ClippingForBITBTL:=clip;
         {Messaggio alla linea di stato}
         if StatusLine<>nil then StatusLine^.Hints(item^.HelpContext);
       end;

     procedure DeSelectItem;
       var vis:OTRect;
           _x1_, _x2_, _dx_:integer;
           clip:boolean;
       begin
         clip:=ClippingForBITBTL;
         ClippingForBITBTL:=false;
         vis:=__r;
         with vis do begin
           if x2>r.x2 then x2:=r.x2;
           if x2>_MaxXResolution then x2:=_MaxXResolution;
           if x1<r.x1 then x1:=r.x1;
           if x1<0 then x1:=0;
           if y2>r.y2 then y2:=r.y2;
           if y2>_MaxYResolution then y2:=_MaxYResolution;
           if y1<r.y1 then y1:=r.y1;
           if y1<0 then y1:=0;
           DimX:=x2-x1;
           DimY:=y2-y1;
           _x1_:=x1-(x1 mod 8);
           _x2_:=_x1_+DimX+16;
           _x2_:=_x2_-(_x2_ mod 8);
           _dx_:=_x2_-_x1_;
           BitBtl(PrecItemImage,VideoDC,0,0,_x1_,y1,_dx_,DimY+1);
           DestroyDC(PrecItemImage);
         end;
         ClippingForBITBTL:=clip;
         {Messaggio alla linea di stato}
         if StatusLine<>nil then StatusLine^.Hints(0);
       end;


     begin
       { Sistema le variabili che contengono il codice ascii dei simboli da usare
         per i subMenu e le voci marcabili.
         Questo per selezionare dei simboli che abbiano una grandezza adatta alla
         dimensione del font utilizzato per scrivere le voci del menu.}
       SetMenuSymboles(MenuPPFont^.GetPicth);
       setwritemode(0);
       primo:=true;
       __r.assign(0,0,0,0);
       _ok_:=true;
       item:=nil;
       direzione:=dir_sin_;
       while  (PositionAndButtonStatus<>0) and
             (OutRects
             or
             r.XYIn(mcx,mcy)) do begin
       {MouseOnPD:=false;
       while  ((PositionAndButtonStatus<>0) and
             (OutRects
             or
             r.XYIn(mcx,mcy))) or
             not MouseOnPD do begin
         if (PositionAndButtonStatus<>0) and
            r.XYIn(mcx,mcy)
         then MouseOnPD:=true
         else if not OutRects and not r.XYIn(mcx,mcy) then exit;}
         item:=menu;
         dy:=r.y1+_spazio_in_alto_-2;
         while item<>nil do begin
           if (item^.attributes and itSeparator)=itSeparator then begin
             item:=item^.succ;
             inc(dy,7);
             continue;
           end;
           bitmap:=(item^.attributes and itBitmap)=itBitmap;
           if bitmap then height:=item^.bmp_Rlsd^.DimY
                     else height:=MenuPPFont^.GetHeight;
           itemEnable:=(item^.attributes and itEnable)=itEnable;
           if (not itemEnable or AllItemsDisabled) and
              (item^.subMenu=nil)
           then begin
             item:=item^.succ;
             inc(dy,height+3);
             if bitmap then dec(dy);
             continue;
           end;
           _r.assign(r.x1,dy-1,r.x2,dy+height+1);
           if _r.XYIn(mcx,mcy) then begin
             item^.attributes:=item^.attributes or itSelected;
             ItemAttiva:=@_r;
             if not primo and _ok_ then DeSelectItem
                                   else primo:=false;
             __r:=_r;
             SelectItem;
             _ok_:=true;
             if item^.subMenu=nil then
               while (PositionAndButtonStatus<>0) and _r.XYIn(mcx,mcy) do
             else begin
               in_r.ResetList;
               in_r.newRect(_r);
               out_r.CopyListFrom(out_rect);
               out_r.newRect(r);
               if not itemEnable then begin
                 precAllItemsDisabled:=AllItemsDisabled;
                 AllItemsDisabled:=true;
               end;
               { Creazione del sub men— }
               New(MenuPP, Init(r.x2-2,dy+1,out_r,in_r,item^.submenu));
               MenuPP^.LinkToStatusLine(StatusLine);
               MenuPP^.PutOnDeskTop;
               ShowMouseCursor;
               ID:=MenuPP^.GetReaction;
               { Distruzione del Pop-up }
               precFlag:=CompletePopUpDestruction;
               CompletePopUpDestruction:=false;
               Dispose(MenuPP,done);
               CompletePopUpDestruction:=precFlag;
               if not itemEnable then AllItemsDisabled:=precAllItemsDisabled;
             end;
             item^.attributes:=item^.attributes and __itSelected;
             break;
           end
           else begin
             item:=item^.succ;
             inc(dy,height+3);
             if bitmap then dec(dy);
           end;
         end;
         if (item=nil) and _ok_ and not __r.Zero then begin
           DeSelectItem;
           _ok_:=false;
         end;
       end;
       if (item<>nil) and
          (r.XYIn(mcx,mcy) or (item^.subMenu<>nil)) then with item^ do begin
         if (attributes and itMarcable)=itMarcable then begin
           { Passa da stato di marked a stato di non marked o vicevrsa. }
           if (attributes and itMarked)=0
             then attributes:=attributes or itMarked
             else attributes:=attributes and __itMarked;
           with __r do
             if (x2>_MaxXResolution) or (y2>_MaxYResolution) then
               setviewPort(x1,y1+1,_MaxXResolution,_MaxYResolution,true)
             else
               if x2>r.x2 then
                 setviewPort(x1,y1+1,r.x2,y2,true)
               else
                 setviewPort(x1,y1+1,x2,y2,true);
           setfillstyle(1,SelectedItemColor);
           HideMouseCursor;
           if (attributes and itMarked=itMarked)
             then M_Symboles.DrawText(4,1,TextLeft,Maked_Symbole)
             else with __r do bar(4,0,15,dimY);
           ShowMouseCursor;
           {$IFDEF debugging}
             { provvisorio }
             delay(Time_for_Remark);
           {$ENDIF}
         end;
         DestroyDC(PrecItemImage);
         if item^.subMenu<>nil then GetReaction:=ID
                               else GetReaction:=Event;
       end
       else GetReaction:=Null_ID;
       dir_sin_:=direzione;
       {Messaggio alla linea di stato}
       if StatusLine<>nil then StatusLine^.Hints(0);
     end;


   procedure OTMenuPopUp.LinkToStatusLine(statusLn:pointer);
     begin
       StatusLine:=statusLn;
     end;



   { ---------------------------------------------------------------------- }


   function NewItem(d:string; _ID:word; _Attivo:boolean; _SubMenu:PMenuPP; next:PMenuLine):PMenuLine;
     var buf:PMenuLine;
     begin
       New(buf);
       with buf^ do begin
         getmem(descr,length(d)+1);
         StrPCopy(descr,d);
         {descr:=d;}
         Event:=_ID;
         attivo:=_attivo;
         subMenu:=_SubMenu;
         succ:=next;
       end;
       NewItem:=buf;
     end;


   function NewItemPP(d:string; _ID:word; HelpCtx:word; ItemAttributes:byte; _SubMenu, next:PMenuPP):PMenuPP;
     var buf:PMenuPP;
     begin
       New(buf);
       with buf^ do begin
         getmem(descr,length(d)+1);
         StrPCopy(descr,d);
         Event:=_ID;
         HelpContext:=HelpCtx;
         Attributes:=ItemAttributes and __itBitmap and __itSelected;
         subMenu:=_SubMenu;
         {
         if subMenu<>nil then attributes:=attributes and __itMarcable;
         }
         succ:=next;
       end;
       NewItemPP:=buf;
     end;


var
   buf:PMenuPP;
   CAbmp_Rlsd,
   CAbmp_Prsd:^HCA;
   bmp:pointer;


   procedure NewBitmap(_ID:word; HelpCtx:word; ItemAttributes:byte; _SubMenu, next:pointer);
   near;
     begin
       new(buf);
       with buf^ do begin
         bmp_Rlsd:=pointer(CAbmp_Rlsd);
         bmp_Prsd:=pointer(CAbmp_Prsd);
         Event:=_ID;
         HelpContext:=HelpCtx;
         Attributes:=ItemAttributes or itBitmap;
         subMenu:=_SubMenu;
         succ:=next;
       end;
     end;


   function NewBitmapPP(_ID:word; HelpCtx:word; BitmapRlsd,BitmapPrsd:word; ItemAttributes:byte;
                        _SubMenu, next:PMenuPP):PMenuPP;
     begin
       new(CAbmp_Rlsd);
       CAbmp_Prsd:=nil;
       if (GetResource_IDNum(BitmapRlsd,bmp)=0) or
          (CreateCompatibleArea(CAbmp_Rlsd^,bmp^)=nil)
         then begin
         { Se il bitmap non viene trovato, allora viene messo al suo posto una
           voce che indica l'errore. }
         dispose(CAbmp_Rlsd);
         if bmp<>nil then FreeMem(bmp,longint(PVetByte(bmp)^[3]));
         NewBitmapPP:=NewItemPP('* Bitmap not found! *',Null_ID,0,itDisable,_SubMenu,next);
         exit;
       end;
       FreeMem(bmp,longint(PVetByte(bmp)^[3]));
       new(CAbmp_Prsd);
       if (GetResource_IDNum(BitmapPrsd,bmp)=0) or
          (CreateCompatibleArea(CAbmp_Prsd^,bmp^)=nil)
         then begin
         { Se il bitmap non viene trovato, viene disabilitato il cambio
           del bitmap della selezione. }
         dispose(CAbmp_Prsd);
         CAbmp_Prsd:=nil;
       end;
       FreeMem(bmp,longint(PVetByte(bmp)^[3]));
       NewBitmap(_ID,HelpCtx,ItemAttributes,_SubMenu,next);
       NewBitmapPP:=buf;
     end;


   function NewBitmapPP_GetRES(_ID:word; HelpCtx:word; BitmapID:word; RES:pointer; NRes:word; ItemAttributes:byte;
                               _SubMenu, next:PMenuPP):PMenuPP;
     begin
       new(CAbmp_Rlsd);
       CAbmp_Prsd:=nil;
       if (GetBMPResource_IDNum(RES,NRes,BitmapID,bmp)=0) or
          (CreateCompatibleArea(CAbmp_Rlsd^,bmp^)=nil)
         then begin
         { Se il bitmap non viene trovato, allora viene messo al suo posto una
           voce che indica l'errore. }
         dispose(CAbmp_Rlsd);
         if bmp<>nil then FreeMem(bmp,longint(PVetByte(bmp)^[3]));
         NewBitmapPP_GetRES:=NewItemPP('* Bitmap not found! *',Null_ID,0,itDisable,_SubMenu,next);
         exit;
       end;
       FreeMem(bmp,longint(PVetByte(bmp)^[3]));
       NewBitmap(_ID,HelpCtx,ItemAttributes,_SubMenu,next);
       NewBitmapPP_GetRES:=buf;
     end;


   function NewBitmapPP_GetRES_Str(_ID:word; HelpCtx:word; BitmapID:string; RES:pointer; NRes:word; ItemAttributes:byte;
                                   _SubMenu, next:PMenuPP):PMenuPP;
     begin
       new(CAbmp_Rlsd);
       CAbmp_Prsd:=nil;
       if (GetBMPResource_IDStr(RES,NRes,BitmapID,bmp)=0) or
          (CreateCompatibleArea(CAbmp_Rlsd^,bmp^)=nil)
         then begin
         { Se il bitmap non viene trovato, allora viene messo al suo posto una
           voce che indica l'errore. }
         dispose(CAbmp_Rlsd);
         if bmp<>nil then FreeMem(bmp,longint(PVetByte(bmp)^[3]));
         NewBitmapPP_GetRES_Str:=NewItemPP('* Bitmap not found! *',Null_ID,0,itDisable,_SubMenu,next);
         exit;
       end;
       FreeMem(bmp,longint(PVetByte(bmp)^[3]));
       NewBitmap(_ID,HelpCtx,ItemAttributes,_SubMenu,next);
       NewBitmapPP_GetRES_Str:=buf;
     end;


   function NewBitmapPP_LoadRES_Str(_ID:word; HelpCtx:word; BitmapID, FileRES:string; ItemAttributes:byte;
                                    _SubMenu, next:PMenuPP):PMenuPP;
     begin
       new(CAbmp_Rlsd);
       CAbmp_Prsd:=nil;
       if (LoadBMPResource_IDStr(FileRES,BitmapID,bmp)=0) or
          (CreateCompatibleArea(CAbmp_Rlsd^,bmp^)=nil)
         then begin
         { Se il bitmap non viene trovato, allora viene messo al suo posto una
           voce che indica l'errore. }
         dispose(CAbmp_Rlsd);
         if bmp<>nil then FreeMem(bmp,longint(PVetByte(bmp)^[3]));
         NewBitmapPP_LoadRES_Str:=NewItemPP('* Bitmap not found! *',Null_ID,0,itDisable,_SubMenu,next);
         exit;
       end;
       FreeMem(bmp,longint(PVetByte(bmp)^[3]));
       NewBitmap(_ID,HelpCtx,ItemAttributes,_SubMenu,next);
       NewBitmapPP_LoadRES_Str:=buf;
     end;


   function NewBitmapPP_LoadRES(_ID:word; HelpCtx:word; BitmapID:word; FileRES:string; ItemAttributes:byte;
                                _SubMenu, next:PMenuPP):PMenuPP;
     begin
       new(CAbmp_Rlsd);
       CAbmp_Prsd:=nil;
       if (LoadBMPResource_IDNum(FileRES,BitmapID,bmp)=0) or
          (CreateCompatibleArea(CAbmp_Rlsd^,bmp^)=nil)
         then begin
         { Se il bitmap non viene trovato, allora viene messo al suo posto una
           voce che indica l'errore. }
         dispose(CAbmp_Rlsd);
         if bmp<>nil then FreeMem(bmp,longint(PVetByte(bmp)^[3]));
         NewBitmapPP_LoadRES:=NewItemPP('* Bitmap not found! *',Null_ID,0,itDisable,_SubMenu,next);
         exit;
       end;
       FreeMem(bmp,longint(PVetByte(bmp)^[3]));
       NewBitmap(_ID,HelpCtx,ItemAttributes,_SubMenu,next);
       NewBitmapPP_LoadRES:=buf;
     end;


   function NewBitmapPP_Load(_ID:word; HelpCtx:word; FileName:string; ItemAttributes:byte;
                             _SubMenu, next:PMenuPP):PMenuPP;
     begin
       new(CAbmp_Rlsd);
       CAbmp_Prsd:=nil;
       if (LoadBitmap(FileName,bmp)=0) or
          (CreateCompatibleArea(CAbmp_Rlsd^,bmp^)=nil)
         then begin
         { Se il bitmap non viene trovato, allora viene messo al suo posto una
           voce che indica l'errore. }
         dispose(CAbmp_Rlsd);
         if bmp<>nil then FreeMem(bmp,longint(PVetByte(bmp)^[3]));
         NewBitmapPP_Load:=NewItemPP('* Bitmap not found! *',Null_ID,0,itDisable,_SubMenu,next);
         exit;
       end;
       FreeMem(bmp,longint(PVetByte(bmp)^[3]));
       NewBitmap(_ID,HelpCtx,ItemAttributes,_SubMenu,next);
       NewBitmapPP_Load:=buf;
     end;


   function NewSEPARATOR_PP(next:PMenuPP):PMenuPP;
     var buf:PMenuPP;
     begin
       New(buf);
       with buf^ do begin
         descr:=nil;
         Event:=Null_ID;
         Attributes:=itSeparator;
         subMenu:=nil;
         succ:=next;
       end;
       NewSEPARATOR_PP:=buf;
     end;


var p:word;


begin
  M_Symboles.Init;
  M_Symboles.RegisterFont(@Menu_Symboles);

  MenuLFont:=@_serif8_;
  MenuPPFont:=@_serif8_;
end.