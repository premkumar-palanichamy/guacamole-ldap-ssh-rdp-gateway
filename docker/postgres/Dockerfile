FROM postgres:15

# Runs all SQL files in lexical order on first database initialization.
COPY docker/postgres/init/ /docker-entrypoint-initdb.d/

# Keep data.sql unchanged and only force schema to run first.
RUN test -f /docker-entrypoint-initdb.d/schema_file.sql \
	|| (echo "ERROR: Missing docker/postgres/init/schema_file.sql. Run ./setup-postgres.sh before docker compose up --build." >&2; exit 1)
RUN mv /docker-entrypoint-initdb.d/schema_file.sql /docker-entrypoint-initdb.d/01_schema_file.sql
