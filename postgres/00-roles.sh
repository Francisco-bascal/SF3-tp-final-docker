#!/bin/sh
# Crea los roles con las contraseñas del .env (se ejecuta antes de init.sql).
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<EOSQL
CREATE ROLE ${N8N_DB_USER} LOGIN PASSWORD '${N8N_DB_PASSWORD}';
CREATE ROLE ${APP_DB_USER} LOGIN PASSWORD '${APP_DB_PASSWORD}';
EOSQL
