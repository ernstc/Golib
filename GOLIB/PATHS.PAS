{ (c) Ernesto CIANCIOTTA Productions 1996 }

{$I DIRECTIV.INC     Direttive di compilazione}



{ Modulo in cui sono raccolti tutti i paths necessari per l'esecuzione }
{ di applicativi GOLIB.                                                }


UNIT Paths;

INTERFACE

const
      Main_Directory = 'c:\progetti\proget~1\';
      Work_Dir       = Main_Directory+'golib\';

      Work_Directory : string = Work_Dir;
      BGI_Directory  : string = Main_Directory+'bp\bgi\';

      GolibRESFile   : string = Work_Dir+'golib8.bmp\golib8.res';

const
      ToolBarRESFile = Work_Dir+'golib8.bmp\toolbar.res';



IMPLEMENTATION


END.
