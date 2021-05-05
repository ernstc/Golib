{ (c) Ernesto CIANCIOTTA Productions 1996 }


{$DEFINE debug}
{UNDEF   debug}


{$A+                            Allineamento a Word }
{$B-                            Boolean shortcut }
{$N+,E+                         Gira con e senza il coprocessore }
{$G+                            Gira su sistemi 80286 e superiori }
{$X+                            Sintassi estesa }

{$IFNDEF debug}

  {$I-,P-,Q-,R-,S-,T-,V-        Nessun controllo sul codice }
  {$D-,L-,Y-                    Nessuna informazione di debug }

{$ENDIF}
