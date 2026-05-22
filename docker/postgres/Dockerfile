FROM postgres:15

# Runs all SQL files in lexical order on first database initialization.
COPY docker/postgres/init/ /docker-entrypoint-initdb.d/
