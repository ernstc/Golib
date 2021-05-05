{ Ernesto CIANCIOTTA Productions }

{*************************************************************************}
{*                                                                       *}
{*  Modulo contenente un modello di lista astratta utilizzato da alcuni  *}
{*  oggetti della libreria GOLIB 1.0.                                    *}
{*                                                                       *}
{*  L'utilit… di questi oggetti Š quella creare una lista di oggetti     *}
{*  visualizzabili, molto pi— semplificati rispetto agli oggetti         *}
{*  dal ramo OTView.                                                     *}
{*                                                                       *}
{*  La necessit… di questa semplificazione sta in una minore quantit… di *}
{*  memoria richiesta da ogni elemento della lista.                      *}
{*                                                                       *}
{*                                                                       *}
{*  Scritto con Turbo Pascal 7.0                                         *}
{*                                                                       *}
{*************************************************************************}

{$D+}
{$L+}

UNIT XList;

INTERFACE

uses
       fonts,
       strings,
       codici,
       golib_h;

type

       { Modello astratto di un elemento della lista. }
       OPXList = ^OTXList;
       OTXList = object (OTGolibObject)
          succ:OPXList;
          constructor MakeElement(next:OPXList);
          destructor DestroyElement; virtual;
          procedure DrawElement(x,y:integer; selected:boolean); virtual;
          procedure ExecMessage(var Message:TMessage); virtual;
          function GetHeight:word; virtual;
       end;


       { Capo astratto della lista che raccoglie le propriet… in comune ai
         vari elementi. }
       OPXXList = ^OTXXList;
       OTXXList = object
          _List_:OPXList;
          constructor MakeList(List:OPXList);
          destructor DestroyList; virtual;
          function GetNumElements:word;
          procedure InitProperties; virtual;
          procedure AppendElement(Element:OPXList);
          procedure DeleteAllElements;
          function DeleteElements(From,Count:word):word;
       private
       public
          numElements:word;
          _lastElement_:OPXList;
       end;


       { Esempio di lista, derivata da OTXXList, che serve per l'uso di una
         lista di linee di testo. }
       OPXXTextLine = ^OTXXTextLine;
       OTXXTextLine = object (OTXXList)
          constructor MakeList(Font:OPFont; List:OPXList);
          procedure InitProperties; virtual;
       private
          _Font_:OPFont;
       end;


       OPXTextLine = ^OTXTextLine;
       OTXTextLine = object (OTXList)
          constructor MakeElement(str:string; next:OPXList);
          destructor DestroyLine; virtual;
          procedure DrawElement(x,y:integer; selected:boolean); virtual;
          procedure ExecMessage(var Message:TMessage); virtual;
          function GetHeight:word; virtual;
       private
       public
          _string_:PChar;
       end;


var
   { Buffer di memoria utilizzato dalla lista OTXXTextLine per comunicare
     le proriet… alle prorie linee OTXTextLine. }
   OTXTextLine_Font:OPFont;


IMPLEMENTATION


                      {----- OTXXList -----}
   constructor OTXXList.MakeList(List:OPXList);
     begin
       numElements:=0;
       _List_:=nil;
       InitProperties;
       AppendElement(List);
     end;


   destructor OTXXList.DestroyList;
     begin
       DeleteAllElements;
     end;


   function OTXXList.GetNumElements:word;
     begin
       GetNumElements:=numElements;
     end;


   procedure OTXXList.InitProperties;
     begin
     end;


   procedure OTXXList.AppendElement(Element:OPXList);
     var point:OPXList;
         numL:word;
         LengthStr:word;
     begin
       if Element=nil then exit;
       if _List_=nil then _List_:=Element
                     else _lastElement_^.succ:=Element;
       numL:=0;
       point:=Element;
       while true do begin
         inc(numL);
         if point^.succ=nil then begin
           _lastElement_:=point;
           break;
         end;
         point:=point^.succ;
       end;
       inc(numElements,numL);
     end;


   procedure OTXXList.DeleteAllElements;
     var point,
         succ:OPXList;
     begin
       point:=_List_;
       while point<>nil do begin
         succ:=point^.succ;
         dispose(point,DestroyElement);
         point:=succ;
       end;
       _List_:=nil;
       numElements:=0;
     end;


   function OTXXList.DeleteElements(From,Count:word):word;
     var point,
         succ,
         DelList:OPXList;
         DelTheFirst:boolean;
         IndiceStr:word;
         Limite:word;
     begin
       if (From=0) or
          (From>numElements) or
          (Count=0) or
          (_List_=nil) then exit;
       Limite:=From+Count-1;
       if Limite>numElements then Count:=numElements-From+1;
       point:=_List_;
       { "point" si posiziona sull'elemento che precede il primo elemento
         che deve essere cancellato }
       if From>1
         then begin
           if From>2
              then for IndiceStr:=3 to From do
                     if point^.succ=nil then exit
                                        else point:=point^.succ;
           DelList:=point^.succ;
           if DelList=nil then exit;
           DelTheFirst:=false;
         end
         else begin
           point:=nil;
           DelList:=_List_;
           DelTheFirst:=true;
         end;
       { Cancellazione di "Count" elementi a partire da "DelList" }
       for IndiceStr:=1 to Count do begin
         if DelList=nil then break;
         succ:=DelList^.succ;
         dispose(DelList,DestroyElement);
         DelList:=succ;
       end;
       if DelTheFirst then _List_:=succ
                      else point^.succ:=succ;
       dec(numElements,Count);
       DeleteElements:=Count;
     end;


                        {----- OTXList -----}
   constructor OTXList.MakeElement(next:OPXList);
     begin
       succ:=next;
     end;


   destructor OTXList.DestroyElement;
     begin
     end;


   procedure OTXList.DrawElement(x,y:integer; selected:boolean);
     begin
     end;


   procedure OTXList.ExecMessage(var Message:TMessage);
     begin
       Message:=Null_Message;
       Message.HNDL:=_XLIST_;
     end;


   function OTXList.GetHeight:word;
     begin
       GetHeight:=1;
     end;


                       {----- OTXXTextLine -----}
   constructor OTXXTextLine.MakeList(Font:OPFont; List:OPXList);
     begin
       _Font_:=Font;
       inherited MakeList(List);
     end;


   procedure OTXXTextLine.InitProperties;
     begin
       OTXTextLine_Font:=_Font_;
     end;


                        {----- OTXTextLine -----}
   constructor OTXTextLine.MakeElement(str:string; next:OPXList);
     begin
       inherited MakeElement(next);
       GetMem(_string_,length(str)+1);
       StrPCopy(_string_,str);
     end;


   destructor OTXTextLine.DestroyLine;
     begin
       FreeMem(_string_,StrLen(_string_)+1);
     end;


   procedure OTXTextLine.DrawElement(x,y:integer; selected:boolean);
     begin
       if selected then TextColor:=15
                   else TextColor:=0;
       OTXTextLine_Font^.__DrawText(x,y,TextLeft,_string_);
     end;


   procedure OTXTextLine.ExecMessage(var Message:TMessage);
     begin
       Message.HNDL:=_X_TEXT_LINE_;
       Message.Message:=_TEXT_LINE_;
       Message.ParametersPtr1:=_string_;
     end;


   function OTXTextLine.GetHeight:word;
     begin
       GetHeight:=OTXTextLine_Font^.GetHeight;
     end;




BEGIN
  OTXTextLine_Font:=@_system_;
END.