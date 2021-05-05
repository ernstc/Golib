{ (c) 1994,96 Ernesto CIANCIOTTA Productions }
{ Programma dimostravo con livello di difficolt… bassissimo. }
uses
     strings,   {- Primitive per la gestione delle stringhe ASCIIZ }
     graftool,  {- Primitive grafiche per il disegno degli oggetti }
     golib9,    {- Modulo principale della libreria }
     applic,    {- Gestore dell'applicazione }
     frame2,    {- Modulo contenente l'oggetto finestra }
     w_header,  {- Modulo di utilit… per la creazione delle intestazioni
                   per le finestre }
     golib_h,
     __menu;

var window1:OTFrame; {- oggetto finestra 1}
    window2:OTFrame; {- oggetto finestra 2}
    r:OTRect;        {- oggetto rettangolo; non Š un oggetto visualizzabile }

begin
  InizializzaGrafica(3,16);  {- Entra in modalit… grafica }

  r.SetRect(70,90,500,300);  {- Imposta l'angolo in alto a sinistra e la
                                dimensione orizzontale e verticale della
                                finestra }

  { Segue la inizializzazione della finestra 1 }
  window1.Init( r,
                { Intestazione della finestra 1 }
                new(OPFullHeader, Init( StrNewPas('Programma dimostrativo con livello di difficolta'' bassissimo.'),
                                       true,
                                       true,
                                       true)
                )
  );
  window1.AddMenu(GetDemoMenu,_nord_);

  r.moverel(40,40);
  { Segue la inizializzazione della finestra 2 }
  window2.Init( r,
                { Intestazione della finestra 2 }
                new(OPNormalHeader, Init( StrNewPas('Finestra 2'))
                )
  );

  window2.PutOnDeskTop;  {- Fa si che la finestra 2 venga posizionata sul Desktop }
  window1.PutOnDeskTop;  {- Fa si che la finestra 1 venga posizionata sul Desktop }

  StartApplication;      {- Fa partire l'applicazione }
end.