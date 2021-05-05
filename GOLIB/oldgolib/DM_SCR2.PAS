{ Ernesto CIANCIOTTA Productions }

{$D+}
{$L+}




uses
     dos,
     strings,
     utility,
     mouse,
     graph,
     fonts,
     graftool,
     codici,
     applic,
     golib_h,
     golib9,
       dispfile,
     buttons,
     w_intest,
     xscrolls,
     __xscr,
     window,
     frame;


var memAv,
    maxAv:Longint;




type
      OTMemSpy = object (OTView)
         constructor Init;
         procedure Disegna; virtual;
         procedure ExecMessage(var Message:TMessage); virtual;
      private
         txcol:word;
      end;


      OTFileSpy = object (OTFrame)
         constructor Init;
         destructor Done; virtual;
         procedure ExecMessage(var Message:TMessage); virtual;
      private
         pop1:{OPXListBox}OPXPopUpField;
         pop2:OPXListBox{OPXPopUpField};
         W1, W2: word;
         S1, S2: PChar;
         FileList1,
         FileList2:OPXXFileList;
         flRiduci:boolean;
         numFinestre:word;
      end;


                         {----- OTMemSpy -----}
      constructor OTMemSpy.Init;
        begin
          inherited Init(Null_ID,NullRect);
          R.SetRect(_MaxXResolution-350,_MaxYResolution-50,350,50);
          SysConfig:=SysConfig or cfAlwaysAsFirst;
          txCol:=0;
        end;

      procedure OTMemSpy.Disegna;
        begin
          with R do begin
            hidemousecursor;
            Window3D(x1,y1,x2,y2,8);
            Incavo3dSoft(x1+5,y1+5,x2-5,y2-5,-1);
            textcolor:=0;
            cour.DrawText(x1+10,y1+12,TextLeft,'                 Memoria libera:  '+NumStr(MemAv));
            cour.DrawText(x1+10,y1+29,TextLeft,'Memoria libera contigua massima:  '+NumStr(MaxAv));
            showmousecursor;
          end;
        end;


      procedure OTMemSpy.ExecMessage(var Message:TMessage);
        begin
          if Message.Message<>EvMOUSE_L_PRESSED then exit;
          if (SysConfig and cfAlwaysAsFirst)=0
            then begin
              SysConfig:=SysConfig or cfAlwaysAsFirst;
              txCol:=0;
            end
            else begin
              SysConfig:=SysConfig and __cfAlwaysAsFirst;
              txCol:=1;
            end;
          Disegna;
        end;


                         {----- OTFileSpy -----}
      constructor OTFileSpy.Init;
        var _r:OTRect;
            dir:string;
        begin
          chdir('c:\');
          _r.SetRect(96,40,500,350);
          inherited Init(_r,'*** Golib ''95 ***',FullIntestParam(true,true,true));
          s1:=nil;
          s2:=nil;
          w1:=1;
          w2:=1;
          GetDir(0,dir);
          new(FileList1, MakeList(@cour,dir,Directory));
          new(FileList2, MakeList(@cour,dir,AnyFile and not directory));
          _r.SetRect(2,2,100,300);
          new(pop1,Init(01010,Nullrect,@cour,@s1,w1,FileList1));
          new(pop2,Init(01111,NullRect,@cour,@s2,w2,FileList2));
          AddOther(pop1,  NewLayoutMetrics(
                                 NewLayout(LmLeft,InPixels,2),
                                 NewLayout(LmTop,InPixels,2),
                                 NewLayout(LmWidth,InPercent,49),
                                 NewLayout(LmBottom,InPixels,0),
                                 LmOther,nil
                               )
          );
          AddOther(pop2,  NewLayoutMetrics(
                                 NewLayout(LmWidth,InPercent,49),
                                 NewLayout(LmTop,InPixels,2),
                                 NewLayout(LmRight,InPixels,2),
                                 NewLayout(LmBottom,InPixels,0),
                                 LmOther,nil
                               )
          );

           _r.SetRect(20,50,110,30);
          AddOther(
            new(OPGroup, Init(Null_ID,'Nuova finestra',
              AddObject( new(OPTextButton, Init(21212,_r,'Nuova finestra',true,1,8,0)),
              AddObject( new(OPCheckButton,Init(Null_ID,20,90,'Riduci',true,@FlRiduci,0)),
              nil))
            )),nil
          );
          numFinestre:=0;
        end;

      destructor OTFileSpy.Done;
        begin
          dispose(FileList1,DestroyList);
          dispose(FileList2,DestroyList);
          inherited Done;
        end;

      procedure OTFileSpy.ExecMessage(var Message:TMessage);
        var dir:string;
            f:file;
            attr:word;
            win:OPFrame;
            _r:OTRect;
            Msg:TMessage;
        begin
          case Message.Message of
            01010: begin
                     assign(f,s1);
                     getFAttr(f,attr);
                     if (attr and directory)<>0
                     then begin
                       GetDir(0,dir);
                       if dir[length(dir)]='\' then delete(dir,length(dir),1);
                       dir:=dir+'\'+StrPas(s1);
                       FileList1^.ChangeDirectory(dir,Directory);
                       FileList2^.ChangeDirectory(dir,AnyFile and not dos.directory);
                       chdir(dir);
                       {pop1^.RefreshListBox(3);
                       }pop1^.RefreshPopUp(3);
                       pop2^.RefreshListBox(1);
                       {pop2^.RefreshPopUp(1);
                       }
                     end;
                   end;
            21212: begin
                     _r.SetRect(numFinestre*25,0,200,100);
                     inc(numFinestre);
                     new(win,Init(_r,'Primo Piano',FullIntestParam(true,true,true)));
                     win^.PutOnDeskTop;
                     if flRiduci then begin
                       Msg.HNDL:=ID;
                       Msg.Message:=_RIDUCI_FINESTRA_;
                       win^.ExecMessage(Msg);
                     end;
                   end;
          else inherited ExecMessage(Message);
          end;
        end;



var window2:OTFileSpy;
    r:OTRect;
    mSpy:OTMemSpy;
    directory:string;


begin
  getdir(0,directory);

  Work_Directory:=directory;
  BGI_Directory:=directory;

  WaitInRefreshDelay:=-1;

  MakeSpecialEffect:=true;
  GraphParamControl:=false;
  LookVideoOnShutDown:=false;
  spessore_bordo:=4;
  InizializzaGrafica(3,16);

  {mSpy.Init;
  mSpy.PutOnDesktop;}

  window2.Init;
  window2.PutOnDeskTop;

  if WaitInRefreshDelay<>-1 then asm
    MOV AH,12H
    MOV BL,36H
    MOV AL,0
    INT 10H      (* Attiva il refresh della memoria video *)
  end;
  EvMoveDirection:=All;

  StartApplication;
  chdir(directory);
end.