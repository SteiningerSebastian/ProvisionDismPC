call powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

dism /Apply-Image /ImageFile:%1 /Index:1 /ApplyDir:C:\

C:\Windows\System32\bcdboot C:\Windows /s S:

md R:\Recovery\WindowsRE
xcopy /h C:\Windows\System32\Recovery\Winre.wim R:\Recovery\WindowsRE\

C:\Windows\System32\Reagentc /Setreimage /Path R:\Recovery\WindowsRE /Target C:\Windows

C:\Windows\System32\Reagentc /Info /Target C:\Windows