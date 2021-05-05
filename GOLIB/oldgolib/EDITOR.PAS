{ by Ernesto CIANCIOTTA Productions }

{***************************************************}
{*                                                 *}
{* Modulo della libreria GOLIB contenete un Editor *}
{*                                                 *}
{***************************************************}

unit EDITOR;

INTERFACE

uses
     g_utile,
     memman,

     dos,
     crt,
     strings,
     mouse,
     graph,
     graftool,
     applic,
     golib8,
     fonts,
     bitmaps,
     scrolls
    ;

const
      Default_EditFGColor: word= 0;  { Nero }
      Default_EditBGColor: word= 15; { Bianco }

type
      PLine = ^TLine;
      TLine = object private
         TextLine:PChar;
         prec,
         succ:PLine;
      end;

      TCharPos = object private
         index:word;
         line:longint;
      end;


      OPEdit = ^OTEdit;
      OTEdit = object (OTView)
      private
        {-Variabili-}

          {*** Generali ***}
         InsMode:boolean;

          {*** Cursore ***}
         CurX,CurY:integer;
         VMovX:integer;     { Serve per lo spostamento verticale del cursore con tastiera }
         CurHeight:word;
         Interlinea:word;
         __ChIndex:word;
         __NumActiveLine:longint;

          {*** Testo ***}
         Text:PLine;
         LastLine,
         CurrentLine:PLine;
         ActiveFont:OPFont;
         NumLines:longint;
         FGColor,
         BGColor:word;

          {*** Testo selezionato ***}
         StartBlock,
         EndBlock: TCharPos;
         TextSelected:boolean;

        {-Metodi-}
         constructor Init(_ID:word; var coord:OTRect; font:OPFont);
         destructor Done; virtual;
         procedure Reaction; virtual;
         function ReactionEvent(Event:word):word; virtual;
         procedure KeyEvent(Event:word); virtual;
         procedure Disegna; virtual;
          {
           Quando l'editor viene selezionato allora:
           1) "__ChIndex" e "__NumActiveLine" devono essere copia rispettivamente nelle varibili
              "ChIndex" e "NumActiveLine"
           2) deve essere impostato XString
           3) Settare FirstCH e LastCH
           4) Settare il colore del testo
          }
         procedure Select; virtual;
          {
           Quando l'editor viene deselezionato allora:
           1) "ChIndex" e "NumActiveLine" devono essere copia rispettivamente nelle varibili
              "__ChIndex" e "__NumActiveLine"
           2) Deve essere rilasciato XString
          }
         procedure Deselect; virtual;
         procedure Edit;

      private
         procedure ASCIIZ_XString;
         procedure XString_ASCIIZ;
      end;


      OPEditBox = ^OTEditBox;
      OTEditBox = object (OTScrollBox)
         constructor Init(_ID:word; var coord:OTRect; font:OPFont);
         destructor Done; virtual;
         procedure Disegna; virtual;
         procedure Reaction; virtual;
         procedure SetColors(FG,BG:word);
      private
         __edit__:OTEdit;
      end;


      OPEditField = ^OTEditField;
      OTEditField = object (OTView)
      private
         __edit__:OTEdit;
      end;


      PCursorMap = ^TCursorMap;
      TCursorMap = array[1..32] of word;


const
      EditCursor: PCursorMap=nil;


IMPLEMENTATION


const
      maxTextLineBuffer=65535;

      RapportoMemAvail=2;

      maxTextLenght=32760;  { Effettivamente la lunghezza massima reale durante
                              l'esecuzione Š uguale a MaxAvail/2 .}
      LineEditing:Char=#0;  { Variabile d'appoggio il cui puntatore viene assegnato
                              varibile PChar che si riferisce alla linea che Š in fase
                              di editing. }
      WaitTime:real=0.3;


type
     PExtendedString = ^TExtendedString;
     TExtendedString = array[1..maxTextLenght] of char;

     PSave = ^TSave;
     TSave = array[1..8] of char;

     TEvent = (EvNothing,EvKeyBoard,EvMouse);

     TCompRisults = (CmpUguale,CmpMaggiore,CmpMinore);


var
 { Globale }
    RzSave:TSave;
    FirstCH, LastCH: char;   { Identificano il codice del primo e }
                             { dell'ultimo carattere.             }
    EditInProgress:boolean;

 { Cursore }
    PersistentCursor:boolean;
    Event:TEvent;

  {**************************************}
    ChIndex:word;
    NumActiveLine:longint;                 {- Pacchetto immodificabile}
    CursorPos:TCharPos absolute ChIndex;
  {**************************************}

 { Buffer XString }
    XString: PExtendedString;
    MemXString:Longint;
    DimXString: word;
    XStringPresent:boolean;  { Indica se Š stato creato o no il buffer XString }



                      {***** Timer *****}
var
    Int1CSave : Pointer;
    TimerCounter:word;

{$F+,S-,W-}
   procedure TimerHandler; interrupt;
     begin
       inc(TimerCounter);
     end;
{$F-,S+}


   procedure Bip;
     begin
       sound(750);
       delay(30);
       nosound;
     end;



                       {***** OTEdit *****}
   constructor OTEdit.Init(_ID:word; var coord:OTRect; font:OPFont);
     begin
       inherited Init(_ID,coord);
       InsMode:=true;
       CurX:=0; CurY:=0;
       VMovX:=0;
       with font^ do begin
         CurHeight:=GetHeight;
         Interlinea:=CurHeight+Font^.Header.Ext_Leading;
       end;
       __ChIndex:=1;
       __NumActiveLine:=1;
       { Crea il testo }
       new(Text);
       with Text^ do begin
         prec:=nil;
         succ:=nil;
         TextLine:=nil;
       end;
       LastLine:=Text;
       CurrentLine:=Text;
       ActiveFont:=font;
       NumLines:=1;
       FGColor:=Default_EditFGColor;
       BGColor:=Default_EditBGColor;
       TextSelected:=false;
     end;


   destructor OTEdit.Done;
     var l:PLine;
     begin
       { Distruzione del testo }
       l:=Text;
       while l<>nil do begin
         Text:=l^.succ;
         if l^.TextLine=@LineEditing then begin
           if XStringPresent then begin
             FreeMem(XString,MemXString);
             XString:=nil;
             XStringPresent:=false;
           end
           else begin
             RestoreCRTMode;
             writeln('Errore EDITOR.TPU: Conflitto nella distruzione di XString.');
             halt;
           end;
         end
         else StrDispose(l^.TextLine);
         dispose(l);
         l:=Text;
       end;
       DeselectEditor(@Self);
       inherited Done;
     end;


   procedure OTEdit.Reaction;
     begin

     end;


   function OTEdit.ReactionEvent(Event:word):word;
     begin

     end;


   procedure OTEdit.KeyEvent(Event:word);
     begin

     end;


   procedure OTEdit.Disegna;
     begin

     end;


   procedure OTEdit.Select;
     begin
       ChIndex:=__ChIndex;
       NumActiveline:=__NumActiveLine;
       with ActiveFont^ do begin
         FirstCH:=chr(Font^.Header.First);
         LastCH:=chr(Font^.Header.Last);
       end;
       textcolor:=FGColor;
       setFillStyle(1,BGColor);
       ASCIIZ_XString;
       SelectEditor(@Self);
     end;


   procedure OTEdit.Deselect;
     begin
       __ChIndex:=ChIndex;
       __NumActiveLine:=NumActiveLine;
       XString_ASCIIZ;
       DeselectEditor(@Self);
     end;


   procedure OTEdit.Edit;
     var bufW:word;
     begin
       while EditInProgress do begin
         Cursor;
         { Crea il buffer XString }
         if not XStringPresent then ASCIIZ_XString;
         case Event of
           EvKeyBoard:
               begin
                hidemousecursor;
                {**************}
                 KeyController;
                {**************}
                showmousecursor;
               end;
           EvMouse:
               begin
                {****************}
                 MouseController;
                {****************}
               end;
         end;
       end; {while}
     end;


   procedure OTEdit.ASCIIZ_XString;
     var txLen:word;
     begin
       { Migrazione ASCIIZ -> XString}
       with CurrentLine^ do begin
         if TextLine<>nil then txLen:=StrLen(TextLine)
                          else txLen:=0;
         if XStringPresent then begin
           if txLen=0 then begin
             DimXString:=0;
             ChIndex:=1;
             TextLine:=@LineEditing;
             exit;
           end
           else FreeMem(XString,MemXString);
         end;
         XString:=pointer(TextLine);
         TextLine:=@LineEditing;
       end;
       { Calcolo della dimensione del buffer }
       MemXString:=MaxAvail;
       if MemXString>65520 then MemXString:=65520;
       MemXString:=MemXString div RapportoMemAvail;
       { Creazione del buffer }
       ResizeMemBlock(pointer(XString),txLen+1,MemXString);
       XStringPresent:=true;
       DimXString:=txLen;
     end;


   procedure OTEdit.XString_ASCIIZ;
     var txLen:word;
     begin
       { Migrazione XString -> ASCIIZ }
       if DimXString=0 then begin
         CurrentLine^.TextLine:=nil;
         exit;
       end;
       txLen:=DimXString+1;
       ResizeMemBlock(pointer(XString),MemXString,txLen);
       XString^[txLen]:=#0;
       CurrentLine^.TextLine:=pointer(XString);
       XString:=nil;
       XStringPresent:=false;
     end;





                   {***** OTEditBox *****}
   constructor OTEditBox.Init(_ID:word; var coord:OTRect; font:OPFont);
     begin

     end;


   destructor OTEditBox.Done;
     begin
       inherited Done;
     end;


   procedure OTEditBox.Disegna;
     begin
     end;


   procedure OTEditBox.Reaction;
     begin
     end;


   procedure OTEditBox.SetColors(FG,BG:word);
     begin
     end;




begin
  XStringPresent:=false;
  EditInProgress:=false;
end.