copy a:\command\t.bat c:\dos /Y                 >> c:\gstation.log

cls
echo Installazione di GOLIB STATION 1.0 (solo Disco #1).
echo\
echo\
pause
cls
echo Disco #1 . . .
echo\
echo Copia archivi
echo  STATION - Directory principale
copy a:\station.arj c:\tp7              >> c:\gstation.log
echo  GOLIB8  - Risorse
copy a:\golib8.arj c:\tp7               >> c:\gstation.log
echo  TPU     - Moduli compilati
copy a:\tpu.arj c:\tp7                  >> c:\gstation.log
echo  OBJ     - Moduli oggetto
copy a:\obj.arj c:\tp7                  >> c:\gstation.log
echo  ASM     - Sorgenti in assembler
copy a:\asm.arj c:\tp7                  >> c:\gstation.log

cls
echo Creazione directories . . .
md c:\tp7\golib8.bmp
md c:\tp7\units
md c:\tp7\obj
md c:\tp7\asm

echo Scompattazione archivi . . .

echo  STATION - c:\tp7
cd\tp7
c:\dos\arj e -e c:\tp7\station.arj      >> c:\gstation.log

echo  GOLIB8  - c:\tp7\golib8.bmp
cd\tp7\golib8.bmp
c:\dos\arj e -e c:\tp7\golib8.arj       >> c:\gstation.log

echo  TPU     - c:\tp7\units
cd\tp7\units
c:\dos\arj e -e c:\tp7\tpu.arj          >> c:\gstation.log

echo  OBJ     - c:\tp7\obj
cd\tp7\obj
c:\dos\arj e -e c:\tp7\obj.arj          >> c:\gstation.log

echo  ASM     - c:\tp7\asm
cd\tp7\asm
c:\dos\arj e -e c:\tp7\asm.arj          >> c:\gstation.log

echo Eliminazione archivi . . .
cd\tp7
rem --- Reset archivi ---
c:\tp7\reset c:\tp7\*.arj /Y no         >> c:\gstation.log
rem --- Cancellazione archivi ---
del c:\tp7\*.arj                        >> c:\gstation.log
del c:\gstation.log

cls
echo\
echo Installazione completata.
echo\
echo\
pause
cls
cd\tp7
