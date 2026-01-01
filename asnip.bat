@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

REM ==========================================
REM 功能：双击运行，交互式获取 ASN 对应的 IPv4 段
REM 特色：包含主菜单、处理进度和专门的退出页面
REM ==========================================

:START
cls
echo ==========================================
echo       ASN 批量查询工具 (数据源: RIPE)
echo ==========================================
echo.
echo [主菜单]
echo 1. 请输入 AS 号 (例如: 13335)
echo 2. 查询多个请用空格隔开 (例如: 13335 16509)
echo 3. 输入 "q" 或 直接回车 退出程序
echo.

set "ASN_INPUT="
set /p "ASN_INPUT=请输入指令/AS号: "

rem 处理退出逻辑
if "%ASN_INPUT%"=="" goto EXIT_PAGE
if /i "%ASN_INPUT%"=="q" goto EXIT_PAGE
if /i "%ASN_INPUT%"=="exit" goto EXIT_PAGE

echo.
echo [正在处理] 请稍候，正在从远端抓取数据...
echo ------------------------------------------

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$asnInput = '%ASN_INPUT%';" ^
  "$asnList = $asnInput.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries);" ^
  "$all = New-Object System.Collections.Generic.List[string];" ^
  "foreach($a in $asnList) {" ^
  "  $a = $a.Trim();" ^
  "  if($a -notmatch '^AS\d+$') {" ^
  "    if($a -match '^\d+$') { $a = 'AS' + $a } else { Write-Host ('[跳过] 无效格式: {0}' -f $a) -ForegroundColor Yellow; continue }" ^
  "  }" ^
  "  Write-Host ('[查询] 正在获取: {0} ...' -f $a) -NoNewline;" ^
  "  $url = 'https://stat.ripe.net/data/announced-prefixes/data.json?resource=' + $a;" ^
  "  try {" ^
  "    $r = Invoke-RestMethod -Uri $url;" ^
  "    if($r.data.prefixes) {" ^
  "      $count = 0;" ^
  "      $r.data.prefixes | ForEach-Object { $_.prefix } |" ^
  "        Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}/\d{1,2}$' } |" ^
  "        ForEach-Object { $all.Add($_); $count++ };" ^
  "      Write-Host (' [完成: {0} 条]' -f $count) -ForegroundColor Green;" ^
  "    } else { Write-Host ' [提示: 无宣告前缀]' -ForegroundColor Gray }" ^
  "  } catch {" ^
  "    Write-Host ' [错误: API 访问失败]' -ForegroundColor Red;" ^
  "  }" ^
  "}" ^
  "if($all.Count -gt 0) {" ^
  "  $all | Sort-Object -Unique | Out-File -Encoding ascii 'ip.txt';" ^
  "  Write-Host '------------------------------------------' -ForegroundColor Cyan;" ^
  "  Write-Host '任务成功完成！' -ForegroundColor Green;" ^
  "  Write-Host ('结果已保存至: ip.txt (总计: {0} 条独立网段)' -f ($all | Sort-Object -Unique).Count);" ^
  "  Write-Host '您可以双击打开 ip.txt 查看结果。';" ^
  "} else {" ^
  "  Write-Host '------------------------------------------' -ForegroundColor Red;" ^
  "  Write-Host '查询结束，但未能提取到有效数据。' -ForegroundColor Red;" ^
  "}"

echo.
echo 按任意键返回主菜单继续查询...
pause >nul
goto START


:EXIT_PAGE
cls
echo ==========================================
echo.
echo          感谢使用 ASN 查询工具
echo.
echo    [已安全退出] 结果文件 ip.txt 已妥善保存。
echo.
echo ==========================================
echo.
echo 窗口将在 3 秒后自动关闭...
timeout /t 3
exit
