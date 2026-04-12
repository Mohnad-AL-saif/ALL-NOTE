
ذي مسار محتوى الملفات 
```
/srv/ftp/
```

- `passive` — تفعيل الـ Passive Mode (يساعد في تجاوز مشاكل الـ firewall)
- `binary` — تحويل وضع النقل إلى Binary (مهم لنقل الملفات بدون تلف)
- `ls` — عرض الملفات والمجلدات الموجودة
### 🔹 1. Nmap Discovery

bash

```bash
# أساسي
nmap -sV -p 21 -sC -A 192.168.1.1

# FTP scripts كلها
nmap -p 21 --script=ftp-anon,ftp-bounce,ftp-syst,ftp-features 192.168.1.1

# Vuln scan
nmap -p 21 --script=ftp-vsftpd-backdoor,ftp-proftpd-backdoor,ftp-vuln-cve2010-4221 192.168.1.1

# مع trace
nmap -sV -p 21 -sC -A 192.168.1.1 --script-trace

# كل السكريبتات
nmap -p 21 --script=ftp-anon,ftp-bounce,ftp-syst,ftp-brute,ftp-vsftpd-backdoor,ftp-proftpd-backdoor 192.168.1.1
```

**شرح الناتج:**
```
PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 3.0.3          ← نوع الـ FTP وإصداره
| ftp-anon: Anonymous FTP login allowed    ← Anonymous مفتوح ✅✅
| ftp-syst:
|   STAT:
| FTP server status:
|      Connected to 192.168.1.1
|      Logged in as ftp                    ← اسم اليوزر المستخدم
|      TYPE: ASCII
|_     vsFTPd 3.0.3 - secure, fast, stable
```

---

### 🔹 2. Banner Grabbing

bash

```bash
# Netcat
nc -nv 192.168.1.1 21

# Telnet
telnet 192.168.1.1 21

# OpenSSL (لو FTP over TLS)
openssl s_client -connect 192.168.1.1:21 -starttls ftp
```

**شرح الناتج:**
```
220 ProFTPD 1.3.5 Server (ProFTPD Default Installation)
↑   ↑نوع السيرفر  ↑الإصدار
220 = Service Ready (كود طبيعي)

# أنواع السيرفرات الشائعة
220 vsFTPd 3.0.3         ← Linux
220 ProFTPD 1.3.5        ← Linux (فيه backdoor في إصدارات قديمة)
220 FileZilla Server     ← Windows
220 Microsoft FTP Service ← Windows IIS
```

---

### 🔹 3. Anonymous Login

bash

```bash
# يدوي
ftp 192.168.1.1

# عند السؤال
Username: anonymous
Password: anonymous   (أو فاضي أو أي شي)

# مباشرة من الأمر
ftp -n 192.168.1.1 << EOT
user anonymous anonymous
ls
bye
EOT
```

**شرح الناتج:**
```
230 Login successful.   ← دخلت ✅
331 Password required   ← يحتاج باسوورد
530 Login incorrect     ← Anonymous مغلق ❌
```

---

### 🔹 4. الأوامر داخل FTP Session

bash

```bash
# معلومات
status              # حالة الاتصال
pwd                 # المجلد الحالي
syst                # نوع الـ OS

# استعراض الملفات
ls                  # قائمة الملفات
ls -la              # مع الملفات المخفية
ls -R               # recursive كل المجلدات
dir                 # بديل لـ ls

# التنقل
cd <folder>         # دخول مجلد
cd ..               # رجوع

# تنزيل
binary              # وضع binary (مهم قبل التنزيل)
get <file>          # تنزيل ملف واحد
mget *              # تنزيل كل الملفات
mget *.txt          # تنزيل نوع معين
prompt off          # إيقاف التأكيد

# رفع
put <file>          # رفع ملف
mput *              # رفع كل الملفات

# خروج
bye
quit
```

**شرح الناتج:**
```
# ls -la
drwxr-xr-x  2 ftp  ftp   4096 Jan 01 12:00 .           ← مجلد
drwxr-xr-x  3 ftp  ftp   4096 Jan 01 12:00 ..
-rw-r--r--  1 ftp  ftp    523 Jan 01 12:00 notes.txt    ← ملف عادي
-rwxr-xr-x  1 ftp  ftp   1024 Jan 01 12:00 script.sh   ← ملف executable
drwxrwxrwx  2 ftp  ftp   4096 Jan 01 12:00 uploads      ← مجلد writable ✅✅

d = مجلد
- = ملف
rwxrwxrwx = الصلاحيات (owner/group/others)
```

---

### 🔹 5. الأوامر الكودية (Response Codes)
```
220  Service ready          ← الاتصال ناجح
230  Login successful       ← دخلت ✅
331  Password required      ← يحتاج باسوورد
530  Login incorrect        ← باسوورد غلط ❌
226  Transfer complete      ← التنزيل اكتمل ✅
227  Entering Passive Mode  ← تحول لـ passive
150  Opening connection     ← بدأ النقل
550  Permission denied      ← ما عندك صلاحية ❌
553  File name not allowed  ← الاسم ممنوع
```

---

### 🔹 6. تنزيل كل الملفات (Non-Interactive)

bash

```bash
# wget mirror
wget -r ftp://anonymous:anonymous@192.168.1.1
wget -r ftp://anonymous:anonymous@192.168.1.1:2121

# wget بدون passive
wget -m --no-passive ftp://anonymous:anonymous@192.168.1.1

# wget مع تنظيف المسار
wget -r -nH --cut-dirs=1 ftp://anonymous:anonymous@192.168.1.1

# مجلد محدد
mkdir ftp_dump
cd ftp_dump
wget -r ftp://anonymous:anonymous@192.168.1.1
```

---

### 🔹 7. بيوزر وباسوورد

bash

```bash
# ftp مع credentials
ftp 192.168.1.1
Username: admin
Password: password123

# wget مع credentials
wget -r ftp://admin:password123@192.168.1.1

# curl
curl ftp://192.168.1.1/ -u admin:password123
curl ftp://192.168.1.1/ --user admin:password123
curl ftp://192.168.1.1/file.txt -u admin:password123 -o file.txt

# تنزيل كل شي بـ curl
curl -s ftp://admin:password123@192.168.1.1/ | while read line; do
  file=$(echo $line | awk '{print $NF}')
  curl -s ftp://admin:password123@192.168.1.1/$file -o $file
done
```

---

### 🔹 8. TFTP (UDP/69)

bash

```bash
# الاتصال
tftp 192.168.1.1

# الأوامر
connect 192.168.1.1
get <file>
put <file>
status
verbose
quit

# مباشرة
tftp -i 192.168.1.1 GET file.txt
tftp -i 192.168.1.1 PUT shell.php
```

---

### 🔹 9. FTP Exploitation

bash

```bash
# vsFTPd 2.3.4 Backdoor (CVE-2011-2523)
nmap -p 21 --script ftp-vsftpd-backdoor 192.168.1.1

# ProFTPD 1.3.3c Backdoor
nmap -p 21 --script ftp-proftpd-backdoor 192.168.1.1

# FTP Bounce Attack
nmap -p 21 --script ftp-bounce 192.168.1.1

# Brute Force (مو مسموح في OSCP إلا لو محدد)
nmap -p 21 --script ftp-brute 192.168.1.1
hydra -l admin -P /usr/share/wordlists/rockyou.txt ftp://192.168.1.1
```

---

### 🔹 10. فحص ملفات الـ Config (بعد الدخول للجهاز)

bash

```bash
# vsFTPd config
cat /etc/vsftpd.conf | grep -v "#"
cat /etc/ftpusers

# الإعدادات الخطيرة اللي تدور عليها
grep "anonymous_enable=YES" /etc/vsftpd.conf   ← Anonymous مفتوح
grep "anon_upload_enable=YES" /etc/vsftpd.conf ← رفع ملفات ممكن ✅
grep "write_enable=YES" /etc/vsftpd.conf        ← الكتابة مسموحة ✅
grep "anon_root=" /etc/vsftpd.conf              ← مسار الـ anonymous
```

---

### 🔹 11. شرح ناتج Nmap FTP كامل
```
PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 2.3.4
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
| -rw-r--r--    1 0        0             104 Jan 01 notes.txt
| ftp-syst:
|   STAT:
|     FTP server status:
|       Connected from 192.168.1.100
|       Logged in as ftp
|       TYPE: ASCII
|_     vsFTPd 2.3.4 - ⚠️ BACKDOOR إصدار خطير جداً

↑ vsftpd 2.3.4 = ثغرة backdoor معروفة (CVE-2011-2523)
↑ Anonymous allowed = تقدر تدخل بدون باسوورد
↑ ملفات ظاهرة = تقدر تشوف محتوى الـ FTP
```

---

### الخطوات بالترتيب
```
1️⃣  nmap -sV -p 21          → اكتشاف الإصدار والـ scripts
2️⃣  nc -nv IP 21             → Banner grabbing
3️⃣  ftp-anon script          → تأكيد Anonymous
4️⃣  ftp IP → anonymous       → دخول يدوي
5️⃣  ls -la                   → استعراض الملفات
6️⃣  wget -r ftp://...        → تنزيل كل شي
7️⃣  grep للملفات الحساسة    → passwords/config/keys
8️⃣  فحص الإصدار للـ exploits → vsftpd/ProFTPD backdoors
```

















