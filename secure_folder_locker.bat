@echo off
title Secure Folder Locker
color 0A
:: Encrypted Password (Hex Encoded)
set "pass=YOUR_HEX_ENCODED_PASSWORD"  :: 🔹 Replace with your hex password

:: Security Question (Predefined)
set "securityQuestion=YOUR_SECURITY_QUESTION"  :: 🔹 Replace with your question (e.g., "What is your pet's name?")
set "securityAnswer=YOUR_SECURITY_ANSWER"  :: 🔹 Replace with your answer (e.g., "Buddy")

:: Email Settings (For OTP Recovery)
set "email=YOUR_EMAIL@gmail.com"  :: 🔹 Replace with your email
set "emailPassword=YOUR_APP_PASSWORD"  :: 🔹 Replace with your **Google App Password**
set "otpFile=%temp%\otp.txt"

:: Check if Folder is Locked
if EXIST "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}" goto UNLOCK
if NOT EXIST Private goto MDPrivate

:CONFIRM
echo Are you sure you want to lock the folder? (Y/N)
set /p "cho=> "
if /I "%cho%"=="Y" goto LOCK
if /I "%cho%"=="N" goto END
echo Invalid choice, try again.
goto CONFIRM

:LOCK
attrib +h +s Private
ren Private "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
attrib +h +s "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
echo Folder Locked Successfully!
goto End

:UNLOCK
echo Enter password to unlock the folder:
set /p "passInput="
for /f %%a in ('echo %passInput% ^| certutil -encodehex -f -') do set "passHex=%%a"
if "%passHex%"=="%pass%" goto SUCCESS

:: Password Failed
echo Incorrect password! Do you want to recover your password? (Y/N)
set /p "recoverChoice=> "
if /I "%recoverChoice%"=="Y" goto FORGOT_PASSWORD
goto FAIL

:FORGOT_PASSWORD
echo Choose Recovery Option:
echo 1. Answer Security Question
echo 2. Receive OTP via Email
set /p "option=> "
if "%option%"=="1" goto SECURITY_QUESTION
if "%option%"=="2" goto EMAIL_OTP
echo Invalid choice, try again.
goto FORGOT_PASSWORD

:SECURITY_QUESTION
echo %securityQuestion%
set /p "answer=> "
if /I "%answer%"=="%securityAnswer%" (
    echo Correct! Your password is: YOUR_ACTUAL_PASSWORD
    pause
    goto UNLOCK
)
echo Incorrect answer!
goto FAIL

:EMAIL_OTP
:: Generate Random OTP
set /a otp=%random%%%9000+1000
echo %otp% > %otpFile%

:: Send OTP via PowerShell
powershell -Command "& {
    Send-MailMessage -To '%email%' -From '%email%' -Subject 'Your OTP' -Body 'Your OTP is %otp%' 
    -SmtpServer 'smtp.gmail.com' -Port 587 -UseSsl 
    -Credential (New-Object System.Management.Automation.PSCredential ('%email%', (ConvertTo-SecureString '%emailPassword%' -AsPlainText -Force)))
}"

echo OTP sent to your email. Enter the OTP:
set /p "otpInput=> "
set /p otpFileContent=<%otpFile%
if "%otpInput%"=="%otpFileContent%" (
    echo Correct! Your password is: YOUR_ACTUAL_PASSWORD
    pause
    goto UNLOCK
)
echo Incorrect OTP!
goto FAIL

:SUCCESS
attrib -h -s "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
ren "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}" Private
attrib -h -s Private
echo Folder Unlocked Successfully!
goto End

:FAIL
echo Access Denied. Try again.
timeout /t 3 >nul
goto End

:MDPrivate
md Private
echo Private folder created successfully!
goto End

:End
exit
