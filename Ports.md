


## البورتات المهمة للـ OSCP

---

### 🔹 Web

```
80   HTTP
443  HTTPS
8080 HTTP Alternate
8443 HTTPS Alternate
8888 HTTP Alternate
```

---

### 🔹 File Transfer / Shares

```
21   FTP
22   SSH / SFTP
69   TFTP (UDP)
139  SMB over NetBIOS
445  SMB Direct
2049 NFS
```

---

### 🔹 Remote Access

```
22   SSH
23   Telnet
3389 RDP (Windows)
5985 WinRM HTTP
5986 WinRM HTTPS
```

---

### 🔹 Database

```
1433 MSSQL
1521 Oracle
3306 MySQL / MariaDB
5432 PostgreSQL
6379 Redis
27017 MongoDB
```

---

### 🔹 Windows / Active Directory

```
53   DNS
88   Kerberos
135  RPC / MSRPC
139  NetBIOS
389  LDAP
445  SMB
464  Kerberos Password Change
593  RPC over HTTP
636  LDAPS (Secure)
3268 Global Catalog LDAP
3269 Global Catalog LDAPS
```

---

### 🔹 Email

```
25   SMTP
110  POP3
143  IMAP
465  SMTPS
587  SMTP Submission
993  IMAPS
995  POP3S
```

---

### 🔹 Other Services

```
111  RPCBind / Portmapper
161  SNMP (UDP)
162  SNMP Trap (UDP)
512  rexec (Linux)
513  rlogin (Linux)
514  rsh (Linux)
873  Rsync
1099 Java RMI
2121 FTP Alternate
3000 Grafana / Node.js
4369 RabbitMQ / Erlang
4848 GlassFish Admin
5000 Flask / Docker
5601 Kibana
8009 Apache AJP
8161 ActiveMQ
9000 PHP-FPM / SonarQube
9090 Prometheus / Cockpit
9200 Elasticsearch
11211 Memcached
```

---

### 🔹 Nmap Commands للـ OSCP

bash

```bash
# سريع كل البورتات
nmap -p- --min-rate 5000 192.168.1.1

# Top 1000 مع scripts
nmap -sV -sC -A 192.168.1.1

# UDP مهم
nmap -sU -p 53,69,111,161,162 192.168.1.1

# بعد ما تلاقي البورتات المفتوحة
nmap -sV -sC -A -p 80,443,445,22 192.168.1.1
```

---

### جدول الأولويات للـ OSCP

|البورت|الخدمة|الأهمية|أول شي تجرب|
|---|---|---|---|
|80/443|HTTP/S|⭐⭐⭐⭐⭐|Gobuster + SQLi + LFI|
|445|SMB|⭐⭐⭐⭐⭐|Null session + EternalBlue|
|22|SSH|⭐⭐⭐⭐|Weak creds + keys|
|3389|RDP|⭐⭐⭐⭐|BlueKeep + weak creds|
|21|FTP|⭐⭐⭐|Anonymous + backdoor|
|1433|MSSQL|⭐⭐⭐⭐|SA login + xp_cmdshell|
|3306|MySQL|⭐⭐⭐|Root no pass + UDF|
|5985|WinRM|⭐⭐⭐⭐|evil-winrm|
|161|SNMP|⭐⭐⭐|Community string|
|2049|NFS|⭐⭐⭐|No_root_squash|
|389|LDAP|⭐⭐⭐|Anonymous bind|
|88|Kerberos|⭐⭐⭐⭐|AS-REP Roasting|

### أول scan تسويه على أي target

bash

```bash
# خطوة 1 - كل البورتات
nmap -p- --min-rate 5000 -oN allports.txt 192.168.1.1

# خطوة 2 - البورتات المفتوحة بالتفصيل
nmap -sV -sC -A -p 22,80,445 -oN detailed.txt 192.168.1.1

# خطوة 3 - UDP
nmap -sU -p 53,69,111,161 -oN udp.txt 192.168.1.1
```


