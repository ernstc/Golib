{ Ernesto CIANCIOTTA Productions }
{ Programma dimostravo con livello di difficoltÖ bassissimo. }
uses
     graftool,  {- Primitive grafiche per il disegno degli oggetti }
     golib9,    {- Modulo principale della libreria }
     applic,    {- Gestore dell'applicazione }
     frame,     {- Modulo contenente l'oggetto finestra }
     w_intest;  {- Modulo di utilitÖ per la creazione delle intestazioni
                   per le finestre }

var window:OTFrame; {- oggetto finestra }
    r:OTRect;       {- oggetto rettangolo; non ä un oggetto visualizzabile }

begin
  InizializzaGrafica(3,16);  {- Entra in modalitÖ grafica }

  r.SetRect(70,90,500,300);  {- Imposta l'angolo in alto a sinistra e la
                                dimensione orizzontale e verticale della
                                finestra }

  { Segue la inizializzazione della finestra }
  window.Init(r,'Programma dimostravo con livello di difficoltÖ bassissimo.',FullIntestParam(true,true,true));

  window.PutOnDeskTop;  {- FÖ sç che la finestra venga posizionata sul Desktop }

  StartApplication;     {- FÖ partire l'applicazione }
end.