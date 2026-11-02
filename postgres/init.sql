-- Estructura del caso de uso MediClock: eventos del dispensador de pastillas.
CREATE TABLE IF NOT EXISTS eventos_dispensador (
    id          SERIAL PRIMARY KEY,
    dispositivo VARCHAR(50)  NOT NULL,
    tipo_evento VARCHAR(30)  NOT NULL
                CHECK (tipo_evento IN ('dispensado', 'omitido', 'alarma', 'error')),
    detalle     VARCHAR(200),
    cantidad    INTEGER      NOT NULL DEFAULT 1 CHECK (cantidad > 0),
    creado_en   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- Los roles se crean con la contraseña del entorno (ver postgres/00-roles.sh).
-- Permisos: n8n lee e inserta; la aplicacion web solo lee.
GRANT SELECT, INSERT ON eventos_dispensador TO n8n_user;
GRANT USAGE, SELECT ON SEQUENCE eventos_dispensador_id_seq TO n8n_user;
GRANT SELECT ON eventos_dispensador TO app_user;
