#!/bin/bash
set -e

# Start slapd temporarily in background for initialization
/usr/sbin/slapd -d 0 -u openldap -g openldap &
SLAPD_PID=$!

# Wait for slapd to be ready
sleep 3

# Check if LDAP tree already has users — if not, initialize
if ! ldapsearch -x -H ldap://localhost:389 \
    -D "cn=admin,dc=ladvik,dc=local" -w admin123 \
    -b "ou=users,dc=ladvik,dc=local" 2>/dev/null | grep -q "dn:"; then

    echo "Initializing LDAP database..."

    ldapadd -x -D "cn=admin,dc=ladvik,dc=local" -w admin123 <<'LDIF' 2>&1 || true
dn: ou=users,dc=ladvik,dc=local
objectClass: organizationalUnit
ou: users

dn: ou=groups,dc=ladvik,dc=local
objectClass: organizationalUnit
ou: groups

dn: uid=bob,ou=users,dc=ladvik,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
uid: bob
cn: Bob
sn: Bob
userPassword: Bob@123
loginShell: /bin/bash
uidNumber: 1001
gidNumber: 501
homeDirectory: /home/bob
mail: bob@ladvik.local

dn: uid=alice,ou=users,dc=ladvik,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
uid: alice
cn: Alice
sn: Alice
userPassword: Alice@123
loginShell: /bin/bash
uidNumber: 1002
gidNumber: 501
homeDirectory: /home/alice
mail: alice@ladvik.local

dn: uid=prem,ou=users,dc=ladvik,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
uid: prem
cn: Prem
sn: Prem
userPassword: Prem@123
loginShell: /bin/bash
uidNumber: 1003
gidNumber: 601
homeDirectory: /home/prem
mail: prem@ladvik.local

LDIF

    if [ -f /ldifs/groups.ldif ]; then
        echo "Adding groups..."
        ldapadd -x -D "cn=admin,dc=ladvik,dc=local" -w admin123 \
            -f /ldifs/groups.ldif || true
    fi

    echo "LDAP initialization complete"
else
    echo "LDAP already initialized, skipping"
fi

# ── Stop the temporary slapd ──────────────────────────────
kill $SLAPD_PID
wait $SLAPD_PID 2>/dev/null || true

# ── Start slapd in the foreground (PID 1) ────────────────
exec /usr/sbin/slapd -d 0 -u openldap -g openldap
