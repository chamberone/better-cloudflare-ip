chcp 936
cls
@echo off
cd "%~dp0"
color A
setlocal enabledelayedexpansion
rem 请设置期望到 CloudFlare 服务器的带宽大小(单位 Mbps):
set Bandwidth=5
set /a Speed=%Bandwidth%*128
set /a startH=%time:~0,2%
if %time:~3,1% EQU 0 (set /a startM=%time:~4,1%) else (set /a startM=%time:~3,2%)
if %time:~6,1% EQU 0 (set /a startS=%time:~7,1%) else (set /a startS=%time:~6,2%)
goto start
:start
title 获取CF节点IP
del data.txt ip.txt CR.txt CRLF.txt cut.txt speed.txt
RD /S /Q temp
cls
rem curl https://www.cloudflare.com/ips-v4 -o ip.txt -#
curl https://service.freecdn.workers.dev -o data.txt
set /a column=0
for /f %%i in (data.txt) do (
	set /a column=column+1
	if !column! GEQ 8 echo %%i >> ip.txt
)

for /f "tokens=2 delims=:" %%i in ('find /c /v "" ip.txt') do (
set /a count=%%i
set /a count=count/50+1
)
title 测试 ICMP 丢包率
fping -f ip.txt -c %count% --interval=0 -s > ping.csv
findstr "%%" ping.csv > temp.csv
del ping.csv
del ip.txt
sort /+17 temp.csv /o ping.csv
del temp.csv
del sort.txt
cls
set /a a=0
for /f "delims=" %%i in (ping.csv) do (
set s=%%i
set s=!s:~0,15!
set /a a=a+1
title 提取测试后的IP地址----正在处理第 !a! 行
echo !s%!>>sort.txt
)
rem del ping.csv
cls
set count=0
for /f "tokens=1,2" %%a in ('type "sort.txt"') do (
echo %%a >> ip.txt
title 选取50个丢包率最少的IP地址下载测速
set /a count+=1
if !count! equ 50 goto speedtest
)
:speedtest
del sort.txt
mkdir temp
cls
echo WScript.sleep 500 > sleep.vbs
for /f "tokens=1,2" %%a in ('type "ip.txt"') do (
sleep.vbs
start /b curl --resolve speed.cloudflare.com:443:%%a https://speed.cloudflare.com/__down?bytes=1000000000 -o temp/%%a -s --connect-timeout 2 --max-time 10
echo %%a 启动测速
)
del sleep.vbs
del ip.txt
chcp 936
cls
echo 等待测速进程结束,筛选出三个优选的IP
choice /t 15 /d y /n >nul
cd temp
dir /o:-s /b > ../ip.txt
cd ..
set n=0
for /f "delims=" %%i in (ip.txt) do (
set /a n+=1 & if !n!==1 set "a=%%i")
set n=0
for /f "delims=" %%i in (ip.txt) do (
set /a n+=1 & if !n!==2 set "b=%%i")
set n=0
for /f "delims=" %%i in (ip.txt) do (
set /a n+=1 & if !n!==3 set "c=%%i")
for /f "delims=" %%i in ('dir temp /b /a-d^| find /v /c "&#@"') do (
		if %%i GEQ 3 (
		chcp 936
		) else (
		goto start
		)
	)
title 优选的IP地址为 (!a!)-(!b!)-(!c!)
rem del best3ip.txt
echo (!a!)-(!b!)-(!c!) >> best3ip.txt
goto one
:one
chcp 936
del CRLF.txt cut.txt speed.txt
cls
echo 第一次测试 !a!
curl --resolve speed.cloudflare.com:443:!a! https://speed.cloudflare.com/__down?bytes=1000000000 -o nul --connect-timeout 5 --max-time 15 > CR.txt 2>&1
findstr "0:" CR.txt >> CRLF.txt
CR2CRLF CRLF.txt
for /f "delims=" %%i in (CRLF.txt) do (
set s=%%i
set s=!s:~73,5!
echo !s%!>>cut.txt
)
for /f "delims=" %%i in ('findstr /v "k M" cut.txt') do (
set x=%%i
set x=!x:~0,5!
set /a x=!x%!/1024
echo !x! >> speed.txt
)
for /f "delims=" %%i in ('findstr "k" cut.txt') do (
set x=%%i
set x=!x:~0,4!
set /a x=!x%!
echo !x! >> speed.txt
)
for /f "delims=" %%i in ('findstr "M" cut.txt') do (
set x=%%i
set x=!x:~0,2!
set y=%%i
set y=!y:~3,1!
set /a x=!x%!*1024
set /a x=!y%!*1024/10
set /a z=x+y
echo !z! >> speed.txt
)
set /a Max=0
for /f "tokens=1,2" %%a in ('type "speed.txt"') do (
if %%a GEQ !Max! set /a Max=%%a
)
if !Max! GEQ !Speed! (cls &&echo !a! 满足 %Bandwidth% Mbps带宽需求 && echo 峰值速度 !Max! kB/s && goto end) else (goto two)
:two
chcp 936
del CRLF.txt cut.txt speed.txt
cls
echo 第一次测试 !a! 不满足带宽需求,峰值速度 !Max! kB/s
echo 第二次测试 !a!
curl --resolve speed.cloudflare.com:443:!a! https://speed.cloudflare.com/__down?bytes=1000000000 -o nul --connect-timeout 5 --max-time 15 > CR.txt 2>&1
findstr "0:" CR.txt >> CRLF.txt
CR2CRLF CRLF.txt
for /f "delims=" %%i in (CRLF.txt) do (
set s=%%i
set s=!s:~73,5!
echo !s%!>>cut.txt
)
for /f "delims=" %%i in ('findstr /v "k M" cut.txt') do (
set x=%%i
set x=!x:~0,5!
set /a x=!x%!/1024
echo !x! >> speed.txt
)
for /f "delims=" %%i in ('findstr "k" cut.txt') do (
set x=%%i
set x=!x:~0,4!
set /a x=!x%!
echo !x! >> speed.txt
)
for /f "delims=" %%i in ('findstr "M" cut.txt') do (
set x=%%i
set x=!x:~0,2!
set y=%%i
set y=!y:~3,1!
set /a x=!x%!*1024
set /a y=!y%!*1024/10
set /a z=x+y
echo !z! >> speed.txt
)
set /a Max=0
for /f "tokens=1,2" %%a in ('type "speed.txt"') do (
if %%a GEQ !Max! set /a Max=%%a
)
if !Max! GEQ !Speed! (cls &&echo !a! 满足 %Bandwidth% Mbps带宽需求 && echo 峰值速度 !Max! kB/s && goto end) else (goto three)
:three
chcp 936
del CRLF.txt cut.txt speed.txt
cls
echo 第二次测试 !a! 不满足带宽需求,峰值速度 !Max! kB/s
echo 第一次测试 !b!
curl --resolve speed.cloudflare.com:443:!b! https://speed.cloudflare.com/__down?bytes=1000000000 -o nul --connect-timeout 5 --max-time 15 > CR.txt 2>&1
findstr "0:" CR.txt >> CRLF.txt
CR2CRLF CRLF.txt
for /f "delims=" %%i in (CRLF.txt) do (
set s=%%i
set s=!s:~73,5!
echo !s%!>>cut.txt
)
for /f "delims=" %%i in ('findstr /v "k M" cut.txt') do (
set x=%%i
set x=!x:~0,5!
set /a x=!x%!/1024
echo !x! >> speed.txt
)
for /f "delims=" %%i in ('findstr "k" cut.txt') do (
set x=%%i
set x=!x:~0,4!
set /a x=!x%!
echo !x! >> speed.txt
)
for /f "delims=" %%i in ('findstr "M" cut.txt') do (
set x=%%i
set x=!x:~0,2!
set y=%%i
set y=!y:~3,1!
set /a x=!x%!*1024
set /a y=!y%!*1024/10
set /a z=x+y
echo !z! >> speed.txt
)
set /a Max=0
for /f "tokens=1,2" %%a in ('type "speed.txt"') do (
if %%a GEQ !Max! set /a Max=%%a
)
if !Max! GEQ !Speed! (cls &&echo !b! 满足 %Bandwidth% Mbps带宽需求 && echo 峰值速度 !Max! kB/s && goto end) else (goto four)
:four
chcp 936
del CRLF.txt cut.txt speed.txt
cls
echo 第一次测试 !b! 不满足带宽需求,峰值速度 !Max! kB/s
echo 第二次测试 !b!
curl --resolve speed.cloudflare.com:443:!b! https://speed.cloudflare.com/__down?bytes=1000000000 -o nul --connect-timeout 5 --max-time 15 > CR.txt 2>&1
findstr "0:" CR.txt >> CRLF.txt
CR2CRLF CRLF.txt
for /f "delims=" %%i in (CRLF.txt) do (
set s=%%i
set s=!s:~73,5!
echo !s%!>>cut.txt
)
for /f "delims=" %%i in ('findstr /v "k M" cut.txt') do (
set x=%%i
set x=!x:~0,5!
set /a x=!x%!/1024
echo !x! >> speed.txt
)
for /f "delims=" %%i in ('findstr "k" cut.txt') do (
set x=%%i
set x=!x:~0,4!
set /a x=!x%!
echo !x! >> speed.txt
)
for /f "delims=" %%i in ('findstr "M" cut.txt') do (
set x=%%i
set x=!x:~0,2!
set y=%%i
set y=!y:~3,1!
set /a x=!x%!*1024
set /a y=!y%!*1024/10
set /a z=x+y
echo !z! >> speed.txt
)
set /a Max=0
for /f "tokens=1,2" %%a in ('type "speed.txt"') do (
if %%a GEQ !Max! set /a Max=%%a
)
if !Max! GEQ !Speed! (cls &&echo !b! 满足 %Bandwidth% Mbps带宽需求 && echo 峰值速度 !Max! kB/s && goto end) else (goto five)
:five
chcp 936
del CRLF.txt cut.txt speed.txt
cls
echo 第二次测试 !b! 不满足带宽需求,峰值速度 !Max! kB/s
echo 第一次测试 !c!
curl --resolve speed.cloudflare.com:443:!c! https://speed.cloudflare.com/__down?bytes=1000000000 -o nul --connect-timeout 5 --max-time 15 > CR.txt 2>&1
findstr "0:" CR.txt >> CRLF.txt
CR2CRLF CRLF.txt
for /f "delims=" %%i in (CRLF.txt) do (
set s=%%i
set s=!s:~73,5!
echo !s%!>>cut.txt
)
for /f "delims=" %%i in ('findstr /v "k M" cut.txt') do (
set x=%%i
set x=!x:~0,5!
set /a x=!x%!/1024
echo !x! >> speed.txt
)
for /f "delims=" %%i in ('findstr "k" cut.txt') do (
set x=%%i
set x=!x:~0,4!
set /a x=!x%!
echo !x! >> speed.txt
)
for /f "delims=" %%i in ('findstr "M" cut.txt') do (
set x=%%i
set x=!x:~0,2!
set y=%%i
set y=!y:~3,1!
set /a x=!x%!*1024
set /a y=!y%!*1024/10
set /a z=x+y
echo !z! >> speed.txt
)
set /a Max=0
for /f "tokens=1,2" %%a in ('type "speed.txt"') do (
if %%a GEQ !Max! set /a Max=%%a
)
if !Max! GEQ !Speed! (cls &&echo !c! 满足 %Bandwidth% Mbps带宽需求 && echo 峰值速度 !Max! kB/s && goto end) else (goto six)
:six
chcp 936
del CRLF.txt cut.txt speed.txt
cls
echo 第一次测试 !c! 不满足带宽需求,峰值速度 !Max! kB/s
echo 第二次测试 !c!
curl --resolve speed.cloudflare.com:443:!c! https://speed.cloudflare.com/__down?bytes=1000000000 -o nul --connect-timeout 5 --max-time 15 > CR.txt 2>&1
findstr "0:" CR.txt >> CRLF.txt
CR2CRLF CRLF.txt
for /f "delims=" %%i in (CRLF.txt) do (
set s=%%i
set s=!s:~73,5!
echo !s%!>>cut.txt
)
for /f "delims=" %%i in ('findstr /v "k M" cut.txt') do (
set x=%%i
set x=!x:~0,5!
set /a x=!x%!/1024
echo !x! >> speed.txt
)
for /f "delims=" %%i in ('findstr "k" cut.txt') do (
set x=%%i
set x=!x:~0,4!
set /a x=!x%!
echo !x! >> speed.txt
)
for /f "delims=" %%i in ('findstr "M" cut.txt') do (
set x=%%i
set x=!x:~0,2!
set y=%%i
set y=!y:~3,1!
set /a x=!x%!*1024
set /a y=!y%!*1024/10
set /a z=x+y
echo !z! >> speed.txt
)
set /a Max=0
for /f "tokens=1,2" %%a in ('type "speed.txt"') do (
if %%a GEQ !Max! set /a Max=%%a
)
if !Max! GEQ !Speed! (cls &&echo !c! 满足 %Bandwidth% Mbps带宽需求 && echo 峰值速度 !Max! kB/s && goto end) else (goto start)
:end
set /a stopH=%time:~0,2%
if %time:~3,1% EQU 0 (set /a stopM=%time:~4,1%) else (set /a stopM=%time:~3,2%)
if %time:~6,1% EQU 0 (set /a stopS=%time:~7,1%) else (set /a stopS=%time:~6,2%)
set /a starttime=%startH%*3600+%startM%*60+%startS%
set /a stoptime=%stopH%*3600+%stopM%*60+%stopS%
if %starttime% GTR %stoptime% (set /a alltime=86400-%starttime%+%stoptime%) else (set /a alltime=%stoptime%-%starttime%)
echo 总计用时 %alltime% 秒
del ip.txt CR.txt CRLF.txt cut.txt speed.txt
RD /S /Q temp
echo 按任意键关闭窗口
pause>nul