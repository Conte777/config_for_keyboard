@echo off
chcp 65001 >nul
:: 65001 - UTF-8

:: Получение пути к исполняемому файлу
set exePath="%~dp0keybinding.exe" 
:: Получение пути к шаблону xml
set tempPath="%~dp0template.xml"
:: Создание пути к файлу задачи
set targetPath="%~dp0task.xml"
:: Получение userSID
for /f "tokens=2 delims== " %%i in ('wmic useraccount where name^="%username%" get sid /value') do set "usersid=%%i"
:: Получение названия учетной записи
set "fullusername=%COMPUTERNAME%\%USERNAME%"
:: Получение текущего времени
for /f %%i in ('powershell -command "Get-Date -Format \"yyyy-MM-ddTHH:mm:ss\" "') do set datetime=%%i

:: Замена переменных в файле
powershell -Command "(Get-Content %tempPath%).replace('{time}', '%datetime%').replace('{fullusername}', '%fullusername%').replace('{userSID}', '%userSID%').replace('{exePath}', '%exePath%') | Set-Content %targetPath%"

:: Созадание задачи
schtasks /create /tn AutoRunKeyboardScript /XML %targetPath%
:: Запуск задачи
schtasks /run /tn AutoRunKeyboardScript

:: Удаление файла задачи
del %targetPath%

pause