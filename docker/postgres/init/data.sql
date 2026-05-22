-- Guacamole groups, connections, and permissions for LDAP+PostgreSQL mode.
-- NOTE: Group names must match LDAP cn values exactly.

-- LDAP group mirror: SSH users
INSERT INTO guacamole_entity (name, type)
VALUES ('SSH users', 'USER_GROUP');

INSERT INTO guacamole_user_group (entity_id, disabled)
SELECT entity_id, FALSE
FROM guacamole_entity
WHERE name = 'SSH users' AND type = 'USER_GROUP';

-- LDAP group mirror: Desktop users
INSERT INTO guacamole_entity (name, type)
VALUES ('Desktop users', 'USER_GROUP');

INSERT INTO guacamole_user_group (entity_id, disabled)
SELECT entity_id, FALSE
FROM guacamole_entity
WHERE name = 'Desktop users' AND type = 'USER_GROUP';

-- SSH target 1
INSERT INTO guacamole_connection (connection_name, protocol)
VALUES ('linux-server-1-ssh', 'ssh');

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'hostname', 'linux-server-1'
FROM guacamole_connection WHERE connection_name = 'linux-server-1-ssh';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'port', '22'
FROM guacamole_connection WHERE connection_name = 'linux-server-1-ssh';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'username', 'target'
FROM guacamole_connection WHERE connection_name = 'linux-server-1-ssh';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'password', 'Target@123'
FROM guacamole_connection WHERE connection_name = 'linux-server-1-ssh';

-- SSH target 2
INSERT INTO guacamole_connection (connection_name, protocol)
VALUES ('linux-server-2-ssh', 'ssh');

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'hostname', 'linux-server-2'
FROM guacamole_connection WHERE connection_name = 'linux-server-2-ssh';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'port', '22'
FROM guacamole_connection WHERE connection_name = 'linux-server-2-ssh';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'username', 'target'
FROM guacamole_connection WHERE connection_name = 'linux-server-2-ssh';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'password', 'Target@123'
FROM guacamole_connection WHERE connection_name = 'linux-server-2-ssh';

-- RDP desktop target
INSERT INTO guacamole_connection (connection_name, protocol)
VALUES ('linux-desktop-rdp', 'rdp');

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'hostname', 'linux-desktop'
FROM guacamole_connection WHERE connection_name = 'linux-desktop-rdp';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'port', '3389'
FROM guacamole_connection WHERE connection_name = 'linux-desktop-rdp';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'username', 'desktop'
FROM guacamole_connection WHERE connection_name = 'linux-desktop-rdp';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'password', 'Desktop@123'
FROM guacamole_connection WHERE connection_name = 'linux-desktop-rdp';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'security', 'any'
FROM guacamole_connection WHERE connection_name = 'linux-desktop-rdp';

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT connection_id, 'ignore-cert', 'true'
FROM guacamole_connection WHERE connection_name = 'linux-desktop-rdp';

-- Group permissions
INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
SELECT e.entity_id,
       c.connection_id,
       'READ'::guacamole_object_permission_type
FROM guacamole_entity e
CROSS JOIN guacamole_connection c
WHERE e.name = 'SSH users'
  AND e.type = 'USER_GROUP'
  AND c.connection_name IN ('linux-server-1-ssh', 'linux-server-2-ssh');

INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
SELECT e.entity_id,
       c.connection_id,
       'READ'::guacamole_object_permission_type
FROM guacamole_entity e
CROSS JOIN guacamole_connection c
WHERE e.name = 'Desktop users'
  AND e.type = 'USER_GROUP'
  AND c.connection_name = 'linux-desktop-rdp';