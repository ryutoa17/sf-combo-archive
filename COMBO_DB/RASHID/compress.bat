@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

rem ============================================================
rem  compress.bat  --  動画を軽量化して clips に出力する
rem
rem  使い方
rem    編集済みの動画をこのファイルにドラッグ＆ドロップするだけ
rem    複数まとめてドロップできます
rem
rem  出力設定（固定）
rem    解像度  そのまま      切り抜き  なし
rem    fps     20            CRF       30
rem    preset  slower        音声      なし
rem
rem  ※ fps は combo.html のコマ送り単位（FPS = 20）と揃えること
rem
rem  ffmpeg.exe の探索順
rem    1. このフォルダ
rem    2. ひとつ上のフォルダ（COMBO_DB/ または VS_DB/）
rem    3. ふたつ上のフォルダ（スト６/ffmpeg.exe に1つ置けば全ツールで共用できます）
rem    4. PATH
rem ============================================================

set "OUTDIR=clips"
set "CRF=30"
set "FPS=20"
set "PRESET=slower"

title 動画の軽量化

rem ffmpeg を探す
set "FF="
if exist "%~dp0ffmpeg.exe" set "FF=%~dp0ffmpeg.exe"
if not defined FF if exist "%~dp0..\ffmpeg.exe" set "FF=%~dp0..\ffmpeg.exe"
if not defined FF if exist "%~dp0..\..\ffmpeg.exe" set "FF=%~dp0..\..\ffmpeg.exe"
if not defined FF (
  where ffmpeg >nul 2>&1
  if not errorlevel 1 set "FF=ffmpeg"
)
if not defined FF (
  echo.
  echo   ffmpeg が見つかりません。
  echo   ffmpeg.exe を スト６ フォルダ（ふたつ上）に置いてください。
  echo.
  pause
  exit /b 1
)

if "%~1"=="" (
  echo.
  echo   軽量化したい動画を、このファイルにドラッグ＆ドロップしてください。
  echo   複数まとめてドロップできます。
  echo.
  pause
  exit /b 0
)

if not exist "%OUTDIR%" mkdir "%OUTDIR%"

set /a OK=0
set /a NG=0
set /a SUMIN=0
set /a SUMOUT=0

echo.

:LOOP
if "%~1"=="" goto FINISH

set "IN=%~1"
set "NAME=%~n1"
set "OUT=%OUTDIR%\%NAME%.mp4"
set /a INKB=%~z1/1024

echo   %NAME%
echo     元 !INKB! KB  ...  処理中

"%FF%" -hide_banner -loglevel error -y ^
  -i "%IN%" -an ^
  -vf "fps=%FPS%" ^
  -c:v libx264 -crf %CRF% -preset %PRESET% ^
  -g 600 -pix_fmt yuv420p -movflags +faststart ^
  "%OUT%"

if errorlevel 1 (
  echo     失敗しました
  set /a NG+=1
  echo.
  shift
  goto LOOP
)

for %%F in ("%OUT%") do set /a OUTKB=%%~zF/1024
set /a PCT=0
if !INKB! gtr 0 set /a PCT=!OUTKB!*100/!INKB!

echo     → !OUTKB! KB  ^(!PCT!%%^)
echo.

set /a OK+=1
set /a SUMIN+=!INKB!
set /a SUMOUT+=!OUTKB!

shift
goto LOOP

:FINISH
echo   ======================================================
if %OK% gtr 0 (
  set /a TOTPCT=0
  if %SUMIN% gtr 0 set /a TOTPCT=%SUMOUT%*100/%SUMIN%
  echo    %OK% 本を軽量化しました
  echo    合計 %SUMIN% KB  ...  %SUMOUT% KB  ^(!TOTPCT!%%^)
)
if %NG% gtr 0 echo    %NG% 本が失敗しました
echo    出力先 %~dp0%OUTDIR%
echo   ======================================================
echo.
echo   combo.html を開いて「編集」から clips フォルダを接続すると
echo   クリップ名で紐付けできます。
echo.
pause
endlocal
