::保存编译及测试结果到WinMake.log，文件存放在桌面
@echo off
set mypath="C:\Documents and Settings\%username%\桌面"
echo 正在编译，请稍等...... 
echo %date% %time% >> %mypath%\WinMake.log
::删除存在的beam及dump文件，然后编译所有erl文件
del *.beam *.dump
erlc -W erlbattle.erl battlefield.erl tools.erl worldclock.erl englandArmy.erl feardFarmers.erl >> %mypath%\WinMake.log
erlc -W testAll.erl testWorldClockGetTime.erl testBattleFieldCreate.erl testErlBattleTakeAction.erl >> %mypath%\WinMake.log
erl -noshell -s testAll test -s init stop >> %mypath%\WinMake.log
echo 编译完成，请查看WinMake.log