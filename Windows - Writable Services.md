

## نفس الفكرة على Windows - Writable Services

---

## اكتشاف الـ Services

powershell

```powershell
# كل الـ services
Get-Service

# تفاصيل أكثر
sc query type= all

# شوف مين يشغّل كل service
Get-WmiObject Win32_Service | Select-Object Name, StartName, PathName
```

---

## تحقق من الـ Permissions

powershell

````powershell
# الأداة الأشهر - accesschk من Sysinternals
accesschk.exe -uwcqv "Everyone" * /accepteula
accesschk.exe -uwcqv "Users" * /accepteula

# أو PowerShell
Get-ACL "C:\path\to\service.exe" | Format-List
```

---

## الـ Vectors الرئيسية
```
1. Writable Service Binary     ← تستبدل الـ .exe نفسه
2. Writable Service Path       ← تحط exe قبله في الـ PATH
3. Unquoted Service Path       ← مسار فيه spaces بدون quotes
4. Writable Registry Key       ← تغير مسار الـ service
````

---

## Unquoted Service Path - الأشهر

powershell

````powershell
# تكتشفها
wmic service get name,pathname | findstr /i /v "C:\Windows\\" | findstr /i /v """
```

لو الـ path مثلاً:
```
C:\Program Files\My App\service.exe
```
بدون quotes، Windows يجرب:
```
C:\Program.exe          ← لو كتبت هنا تنتهي ✓
C:\Program Files\My.exe
````

---

## أدوات تعمل كل هذا تلقائياً

|التول|مثل|
|---|---|
|**WinPEAS**|LinPEAS بس للويندوز|
|**PowerUp**|متخصص في service misconfigs|
|**SharpUp**|نفس PowerUp بس C#|

powershell

```powershell
# PowerUp
Import-Module .\PowerUp.ps1
Invoke-AllChecks
```
 











