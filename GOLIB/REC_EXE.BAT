@echo off
cls
set copycmd=
echo Batch Program by Ernesto CIANCIOTTA
echo\
echo\
echo Recupero dei file eseguibili dalla directory C:\TP7\UNITS
echo\
copy c:\tp7\units\*.exe c:\tp7
del c:\tp7\units\*.exe
set copycmd=/-Y
echo\
