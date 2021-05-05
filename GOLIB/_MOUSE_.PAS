{	a very simple program to demonstrate

		- the usage of the mouse-unit

		- the functionality of the mouse

		- an easy calculation of text-screen-positions
}
{$A-				no word align}
{$B-				boolean shortcut}
{$N+,E+			run on no-copro-systems}
{$G-				run on 8086-systems}
{$I-,P-,Q-,R-,S-,T-,V-	no superfluous checks}

program MouseDemo;

USES	CRT,DOS,
        BIOS_UTT,
	mouse2
	;

CONST	posw		= 3;				{#digits for position-writes}
	xstep		= 8;				{usual in text-modes}
	ystep		= 8;				{usual in text-modes}

VAR	OldExit	: pointer;
	ExitMsg	: string;
	UnderLogo	: integer;

	mxcol,					{max column for mouse-pic}
	mxrow,					{max row for mouse-pic}

	gxpos,					{column for graphics-x-pos}
	gypos,					{column for graphics-y-pos}
	txpos,					{column for text-x-pos}
	typos,					{column for text-y-pos}
	posline	: integer;			{row for all the positions}

							{the timer hack used here does
							 not work over midnight...
							}
	systime	: LongInt absolute $40:$6C;
	lasttime	: LongInt;


CONST	DispMouse	: boolean = FALSE;	{now displaying mouse-picture}
	DispRText	: boolean = FALSE;	{displaying running text}

	topLogo	= '  ษอออออออออออออออออออออป  ';
	midLogo	= '  บ MOUSE-DEMONSTRATION บ  ';
	botLogo	= '  ศอออออออออออออออออออออผ  ';

	LogoLine	= 1;


							{the running text:}
CONST	numLines	= 8;
	msgs		: array[0..numlines-1]of string[80] = (
	'As you can see, ',
	'the progress of the main program is (mostly) independent ',
	'from any mouse-action, even if the handler is written in ',
	'plain PASCAL. So why bother and hack around in assembler ',
	'when all the things ar as easy. After having read this message ',
	'you can go on and start programming your own mouse ',
	'applications.                                        ',
	'                                      '
	);
	actLine	: word = 1;			{actual line}
	actChar	: word = 0;			{actual char}
VAR	actMsg	: string;			{actual displayed line}

procedure DisableInts; inline($FA);		{as shown in manual}
procedure EnableInts;  inline($FB);

procedure InitWait;
 begin
 lasttime:=systime;
 actMsg:=msgs[0];
 while length(actMsg)<mxcol do actMsg:=' '+actMsg;
 end;{InitWait}

function RunPossible:boolean;
 VAR goodtime:boolean;
 begin
 repeat
   DisableInts;
   goodTime:=not(DispMouse);
   if goodTime then DispRText:=TRUE;
   EnableInts;
  until goodTime or KeyPressed;
 if KeyPressed
  then begin
   DispRText:=FALSE;
   RunPossible:=FALSE;
   end
  else RunPossible:=goodTime;
 end;{RunPossible}

function WaitForText:boolean;			{wait some time}
 CONST RTdelay = 1*18;				{2 secs}
	 fullLine= 'ออออออออออออออออออออออออออออออออออออออออ'+
		     'ออออออออออออออออออออออออออออออออออออออออ';
 begin
 if systime>(lasttime+RTdelay)		{if time gone, start the run}
  then begin
   if RunPossible then begin
    (*SetSchrift(invers);				{ by displaying a frame}
    *)GotoXY(1,LogoLine  ); writeln(fullLine);
    GotoXY(1,LogoLine+2); writeln(fullLine);
    (*SetSchrift(normal);
    *)DispRText:=FALSE;
    WaitForText:=TRUE;
    end;
   end
  else WaitForText:=FALSE;
 end;{WaitForText}

procedure RunningText;				{}
 CONST RTdelay=2;					{~.25 sec}
 VAR nextTime:longint;
 begin{RunningText}
 if RunPossible then begin
  nextTime:=systime+RTdelay;			{start timing}
  GotoXY(1,LogoLine+1); write(actMsg);	{display the message}
  DispRText:=FALSE;				{writing is done}
  inc(actChar);					{roll in next char}
  if actChar>length(msgs[actLine]) then begin
   actChar:=1;
   inc(actLine);
   if actLine>=numLines then actLine:=0;
   end;
  Delete(actMsg,1,1);
  actMsg:=actMsg+msgs[actLine][actChar];
  repeat
   until (systime>nextTime) or KeyPressed;
  end;
 end;{RunningText}



function imax(i1,i2:integer):integer;
  begin
    if i1>i2 then imax:=i1
             else imax:=i2;
  end;


function imin(i1,i2:integer):integer;
  begin
    if i1<i2 then imin:=i1
             else imin:=i2;
  end;



procedure DisplayAll;
 CONST						{and some static variables...}
	oldx		: integer = -0815;	{impossible position}
	oldy		: integer = -0815;
	mwide		= 5;				{width of mouse-picture}
	mhigh		= 6;				{heigth of mouse-picture}
	empty		= '     ';			{an empty line}
	topMouse	= 'ฺฤฤฤฟ';			{top of mouse}
	midMouse	= 'ณ   ณ';			{middle of mouse}
	botMouse	= 'ภฤฤยู';			{bottom of mouse}
	tailMouse	= '   ณ ';			{tail of mouse}
	buttons	: string[mwide]		{for the buttons}
			  =midMouse;
	butpic	: array[boolean]of char	{the buttons:}
			  = '_Û';

 VAR mbut:string[mwide];			{strg with 'buttons' inside}
     x,y,b:word;					{result from the mouse}
     tx,ty:word;					{text-position}
     px,py:word;					{upper left corner of picture}
     pchgd:boolean;				{pic-position changed?}
     badtime:boolean;				{two tasks writing}

 begin{DisplayAll}
 DisableInts;
 badTime:=DispRText;
 if not(badTime) then DispMouse:=TRUE;
 Enableints;
 if badTime then exit;
 M_GetPos(b,x,y);					{get actual state from driver}
 tx:=(x div xstep)+1;				{calc text-position}
 ty:=(y div ystep)+1;
 px:=imax(1,imin(mxcol-mwide+1,tx));	{calc picture position}
 py:=imax(UnderLogo,imin(mxrow-mhigh+1,ty));

 pchgd:=(px<>oldx) or (py<>oldy);		{moved?}

 if (oldx>0)					{painted at all?}
    and pchgd					{and moved?}
  then begin					{=> erase old picture}
   GotoXY(oldx,oldy);   write(empty);
   GotoXY(oldx,oldy+1); write(empty);
   GotoXY(oldx,oldy+2); write(empty);
   GotoXY(oldx,oldy+3); write(empty);
   GotoXY(oldx,oldy+4); write(empty);
   GotoXY(oldx,oldy+5); write(empty);
   end;

 GotoXY(gxpos,posline); write(x:posw);	{display new position}
 GotoXY(gypos,posline); write(y:posw);
 GotoXY(txpos,posline); write(tx:posw);
 GotoXY(typos,posline); write(ty:posw);

 buttons[2]:=butpic[(b and M_TGli)<>0];	{'insert' the buttons}
 buttons[4]:=butpic[(b and M_TGre)<>0];

 if pchgd then begin				{display whole the picture}
  GotoXY(px,py  ); write(topMouse);
  GotoXY(px,py+2); write(midMouse);
  GotoXY(px,py+3); write(midMouse);
  GotoXY(px,py+4); write(botMouse);
  GotoXY(px,py+5); write(tailMouse);
  end;
 GotoXY(px,py+1); write(buttons);		{and anytimes the buttons}

 DispMouse:=FALSE;				{just going out}
 oldx:=px;						{mark position for intelligent}
 oldy:=py;						{ redisplay}
 end;{DisplayAll}

procedure MouseProc; INTERRUPT;		{the server for mouse-actions}
 begin
 DisplayAll;					{displays a mouse}
 end;{MouseProc}

procedure ShowDemo;
							{we want to get the news at any
							 change of mouse's state
							}
 CONST callmask = M_CMchpos+M_CMliged+M_CMlilos+M_CMreged+M_CMrelos;

 VAR   xmax,					{virtual maximal x-coordinate}
       ymax     : word;				{virtual maximal y-coordinate}
 begin
 M_reset;						{reset the mouse}
 posline:=25{MaxZeile};				{eval display-positions}
 mxcol:=80{MaxSpalte};
 mxrow:=posline-1;
 GotoXY(1,PosLine);
 write('mouse-pos=['); gxpos:=WhereX;
 write(0:posw,'|'); gypos:=WhereX;
 write(0:posw,']          text-pos=['); txpos:=WhereX;
 write(0:posw,'|'); typos:=WhereX;
 write(0:posw,']    press any key to terminate');

 xmax:=(80{MaxSpalte}-1)*xstep;			{set up a virtual move area}
 ymax:=(25{MaxZeile} -1)*ystep;

 {SetSchrift(normal);}
 DisplayAll;					{display at actual position}
 M_SetSubroutine(callmask,@MouseProc);	{and at any new one}
 InitWait;

 repeat						{wait some time}
  until WaitForText or KeyPressed;

 while not(KeyPressed) do RunningText;	{then run the text}

 while KeyPressed do Readkey;		{afterwards consume keys}

 M_reset;						{then reset the mouse again
							 this also cancels the subroutine
							}
 end;{ShowDemo}

{$F+}
procedure OwnExit;
 begin
 ExitProc:=OldExit;
 {SetSchrift(half); Loesche(Bild);} GotoXY(1,1);
 if ExitMsg<>'' then begin
  {SetSchrift(normal);}
  write(ExitMsg);
  {SetSchrift(half);}
  writeln;
  end;
 RipristinaCursore;
 end;{OwnExit}
{$F-}

begin{MouseDemo}
clrscr;
OldExit:=ExitProc; ExitProc:=@OwnExit;
{Wrap(FALSE);}
{SetSchrift(half); Loesche(Bild);}

writeln(topLogo);
writeln(midLogo);
writeln(botLogo);

UnderLogo:=4; ExitMsg:=''; EliminaCursore;

if not(M_OK) then begin
 ExitMsg:='no mouse-driver installed';
 halt(1);
 end;

ShowDemo;

ExitMsg:='good bye ...'; halt(0);
end.

