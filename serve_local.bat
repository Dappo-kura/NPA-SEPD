@echo off
cd /d "%~dp0"
py -m http.server 8765 --bind 127.0.0.1
pause
