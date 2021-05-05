{ Die Maus soll ja auch als EingabegerÑt zugelassen werden.

  Bei einer Neukompilation die Konstanten NICHT Ñndern !!

  Die Benutzer-Routinen sind als Pointer typisiert, damit auch mit Ñlteren
   TP's als 5.0 gearbeitet werden kann.

  Fragen, VerbesserungsvorschlÑge und sonstige konstruktive Kritik an

		Roland Kîsling
		Corray 22
		D-56856 Zell
		06542-5162

}
{$A-				no word align}
{$B-				boolean shortcut}
{$N+,E+			run on no-copro-systems}
{$G-				run on 8086-systems}
{$I-,P-,Q-,R-,S-,T-,V-	no superfluous checks}

UNIT MOUSE2;

INTERFACE

CONST  M_GCZeiger     = 0;  {die vordefinierten GrafikCursoren}
	 M_GCPfHoch     = 1;    {Pfeil hoch}
	 M_GCPfLinks    = 2;    {Pfeil links}
	 M_GCHaken      = 3;
	 M_GCHand       = 4;
	 M_GCKreuz      = 5;
	 M_GCSandUhr    = 6;
	 M_GCUser       = 7;

	 M_TCBlockH     = 0;  {die TextCursoren H=Halbhell}
	 M_TCGrinsH     = 1;    {das Grinsegesicht}
	 M_TCGrins      = 2;
	 M_TCDachH      = 3;
	 M_TCDach       = 4;
	 M_TCPfeil      = 5;
	 M_TCganz       = 6;    {ganz gro·er Block}
	 M_TCunten      = 7;    {halber Block unten}
	 M_TCnormal     = 8;    {der Unterstrich}
	 M_TCoben       = 9;    {halber Block unten}
	 M_TCUser       =10;

    {Bits per le  CallMask ( ->*Subroutine* )}
	 M_CMmoves      = $01; {quando il mouse si muove}
	 M_CMleftP      = $02; {pressione del tasto sinistro}
	 M_CMleftR      = $04; {rilascio del tasto sinistro}
	 M_CMrigthP     = $08; {pressione del tasto destro}
	 M_CMrightR     = $10; {rilascio del tasto destro}

    {die Bits des Tastenzustandes (->M_GetPos) }
	 M_TGkeine      = $00; {Maus_TasteGedrÅckt: keine}
	 M_TGleft       = $01; {sinistro}
	 M_TGright      = $02; {destro}
	 M_TGbeide      = $03; {links/rechts}

	 M_links        = 1; {fÅr 'status' bei M_*button* }
	 M_rechts       = 2;

TYPE   M_GCursor      = M_GCZeiger..M_GCUser;
	 M_TCursor      = M_TCBlockH..M_TCUser;
	 M_TCTyp        = record case typ:word of
				 0: (Screen,Cursor:word);
				 1: (ScanStart,ScanStop:word)
				 end;
	 M_GCTyp        = record
				 mask,pattern: array[0..15] of word;
				 xspot,yspot : word;
				 end;


VAR    M_Ok           : boolean;

procedure M_Reset;
procedure M_Show;
procedure M_Hide;
procedure M_GetPos (VAR button,x,y:word);
procedure M_PutAt (x,y:word);
procedure M_ButtonPressed (VAR Status,No,x,y:word);
procedure M_ButtonReleased (VAR Status,No,x,y:word);
procedure M_SetXRange (Min,Max:word);
procedure M_SetYRange (Min,Max:word);
procedure M_SetGCursor (Cursor:M_GCursor);
procedure M_SetTCursor (Cursor:M_TCursor);
procedure M_SetUserGCursor (VAR Cursor:M_GCTyp);
procedure M_SetUserTCursor (VAR Cursor:M_TCTyp);
procedure M_ReadMotion (VAR xcounter,ycounter:integer);
procedure M_SetSubroutine (CallMask:word; UserRtn:pointer);
procedure M_ResetSubRoutine;
procedure M_SetMickeys (hor,ver:word);
procedure M_SetCondOff (xro,yro,xlu,ylu:word);
procedure M_SetDoubleSpeed (mickeys:word);
procedure M_SwapSubroutine (VAR CallMask:word; VAR UserRtn:pointer);
procedure M_AllocBuffer (VAR buffer:pointer);
procedure M_SaveDriverState (Buffer:pointer);
procedure M_RestoreDriverState (Buffer:pointer);
procedure M_SetCrtPage (Nr:word);
procedure M_GetCrtPage (VAR nr:word);

procedure g2t(VAR x,y:word);
procedure t2g(VAR s,z:word);

IMPLEMENTATION

VAR M_UserSet   : boolean;
    M_ExitSave  : pointer;
    M_BufferPtr : pointer;
    M_SaveUser  : pointer;

{das GetMem von SYSTEM ist leider nicht îffentlich}
procedure AsmGet (VAR p:pointer; b:word); begin GetMem(p,b) end;

{$L MOUSE.OBJ}
procedure M_Reset;                                          EXTERNAL;
procedure M_Show;                                           EXTERNAL;
procedure M_Hide;                                           EXTERNAL;
procedure M_GetPos;                                         EXTERNAL;
procedure M_PutAt;                                          EXTERNAL;
procedure M_ButtonPressed;                                  EXTERNAL;
procedure M_ButtonReleased;                                 EXTERNAL;
procedure M_SetXRange;                                      EXTERNAL;
procedure M_SetYRange;                                      EXTERNAL;
procedure M_SetGCursor;                                     EXTERNAL;
procedure M_SetTCursor;                                     EXTERNAL;
procedure M_SetUserGCursor;                                 EXTERNAL;
procedure M_SetUserTCursor;                                 EXTERNAL;
procedure M_ReadMotion;                                     EXTERNAL;
procedure M_SetSubroutine;                                  EXTERNAL;
procedure M_ResetSubRoutine;                                EXTERNAL;
procedure M_SetMickeys;                                     EXTERNAL;
procedure M_SetCondOff;                                     EXTERNAL;
procedure M_SetDoubleSpeed;                                 EXTERNAL;
procedure M_SwapSubroutine;                                 EXTERNAL;
procedure M_AllocBuffer;                                    EXTERNAL;
procedure M_SaveDriverState;                                EXTERNAL;
procedure M_RestoreDriverState;                             EXTERNAL;

{vom Maustreiber bisher nicht unterstÅtzt:}
procedure M_SetCrtPage;                                     EXTERNAL;
procedure M_GetCrtPage;                                     EXTERNAL;

procedure g2t;                                              EXTERNAL;
procedure t2g;                                              EXTERNAL;

procedure InitMouse;                                        EXTERNAL;

BEGIN
InitMouse
END.
