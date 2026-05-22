#!/bin/bash
set -e

# Initialize LDAP database if not already done
if [ ! -f /var/lib/ldap/data.mdb ]; then
    echo "Initializing LDAP database..."
    
    # Start slapd briefly to initialize
    /usr/sbin/slapd -d 0 -u openldap -g openldap &
    SLAPD_PID=$!
    
    # Wait for slapd to start
    sleep 3
    
    # Create temporary LDIF file with base DN and user entries
    cat > /tmp/init.ldif <<'LDIF'
dn: dc=ladvik,dc=local
objectClass: top
objectClass: dcObject
objectClass: organization
o: Ladvik
dc: ladvik

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
LDIF

    # Add entries from LDIF file (ignore already exists errors)
    echo "Adding LDAP entries..."
    ldapadd -x -D "cn=admin,dc=ladvik,dc=local" -w admin123 -f /tmp/init.ldif 2>&1 | grep -v "already exists" || true
    
    # Load additional groups from LDIF file if it exists
    if [ -f /ldifs/groups.ldif ]; then
        echo "Adding groups from /ldifs/groups.ldif..."
        ldapadd -x -D "cn=admin,dc=ladvik,dc=local" -w admin123 -f /ldifs/groups.ldif 2>&1 | grep -v "already exists" || true
    fi
    
    # Clean up temp file
    rm -f /tmp/init.ldif
    
    # Stop slapd
    echo "Stopping temporary slapd instance..."
    kill $SLAPD_PID
    wait $SLAPD_PID || true
    
    echo "LDAP database initialization complete"
fi

# Start slapd in foreground
exec /usr/sbin/slapd -d 0 -u openldap -g openldap
