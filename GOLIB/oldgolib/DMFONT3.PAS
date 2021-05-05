uses crt,graftool,fonts;

var f:OTFont;


begin
  InizializzaGrafica(3,16);

  f.LoadFontFrom('c:\tp7\vgasys.fnt');

  textcolor:=14;
  f.DrawText(8,10,TextLeft,'ABCDEFGHILMNOPQRSTUVZ');
  f.DrawText(10,25,TextLeft,'abcdefghilmnopqrstuvz');

  _serif8_.DrawText(10,60,TextLeft,'ABCDEFGHILMNOPQRSTUVZ');
  _serif8_.DrawText(10,75,TextLeft,'abcdefghilmnopqrstuvz');

  serife83.DrawText(10,110,TextLeft,'ABCDEFGHILMNOPQRSTUVZ');
  serife83.DrawText(10,125,TextLeft,'abcdefghilmnopqrstuvz');
  readkey;
end.