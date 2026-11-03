# MediClock - Plataforma Docker integrada

Trabajo Práctico Integrador Final - Software Factory 3 (ITES 2026).

## Integrantes

Bascal Francisco Emanuel
Fuentes Facundo Demian
Alzuri Luciana Aymara
Díaz Ignacio

## Objetivo y caso de uso

MediClock es un dispensador automático de pastillas (motor stepper, RTC, sensor magnético, LED y pantalla LCD) que se configura desde un sistema web. Esta plataforma simula el registro de **eventos del dispensador** (pastilla dispensada, omitida, alarma, error) que llegan por **MQTT** o por **HTTP**, se procesan con n8n, se guardan en PostgreSQL y se visualizan en una aplicación web. No se usa hardware real: los mensajes se simulan con línea de comandos.

## Arquitectura

Diagrama completo (contenedores, redes, puertos): [docs/arquitectura.md](docs/arquitectura.md).

| Servicio | Imagen | Función |
|---|---|---|
| `proxy` | `nginx:alpine` | Único punto de entrada HTTP. Enruta por nombre de host. |
| `app` | Imagen propia (`app/Dockerfile`) | Aplicación web .NET que consulta y muestra los eventos. |
| `n8n` | `n8nio/n8n` | Workflows: MQTT request/reply y webhook HTTP. |
| `postgres` | `postgres:16-alpine` | Persistencia (tabla `eventos_dispensador`). |
| `pgadmin` | `dpage/pgadmin4` | Administración e inspección de PostgreSQL. |
| `mosquitto` | `eclipse-mosquitto:2` | Broker MQTT. |
| `portainer` | `portainer/portainer-ce` | Inspección del entorno Docker. |

Recorridos:

- **MQTT:** simulador → Mosquitto → n8n → PostgreSQL → n8n → Mosquitto → simulador.
- **HTTP:** cliente → proxy → webhook de n8n → PostgreSQL → respuesta JSON.
- **Visualización:** navegador → proxy → app → PostgreSQL → tabla HTML.

### Redes y volúmenes

- `red_frontend`: proxy, app, n8n y pgadmin. Es la red por la que el proxy llega a los servicios web.
- `red_backend`: postgres, mosquitto, portainer y los servicios que los usan. PostgreSQL y Mosquitto no son alcanzables desde el proxy: se separan para que el único camino HTTP hacia el exterior sea el proxy.
- Volúmenes: `postgres_datos`, `pgadmin_datos`, `n8n_datos`, `mosquitto_datos`, `portainer_datos`.

### Roles de base de datos y Permisos

| Rol | Permisos | Usado por |
|---|---|---|
| `admin` (superusuario) | Todos | Solo administración (pgAdmin, `psql`) |
| `n8n_user` | `SELECT`, `INSERT` | n8n |
| `app_user` | `SELECT` | Aplicación web |

La aplicación web no puede modificar datos: un `INSERT` con `app_user` falla con `permission denied`.

## Tecnologías elegidas y justificación

- **Aplicación web: C# con ASP.NET Core (.NET 8) y Entity Framework Core.** Es la tecnología que usa el sistema real de MediClock. La app sigue la estructura Controller → Service → DbContext y construye su imagen con un Dockerfile multi-stage (SDK para compilar, runtime liviano para ejecutar).
- **Proxy inverso: Nginx.** Configuración explícita en un archivo (`proxy/nginx.conf`), fácil de leer y de explicar, con un `server` (virtual host) por servicio. Se prefirió a Traefik porque no requiere montar el socket de Docker en el proxy y a Caddy por ser más habitual en la industria y en la documentación disponible.

**Proxy inverso:** es un servidor que recibe todas las solicitudes HTTP y las reenvía al servicio correcto. Identifica el destino por el encabezado `Host` de la solicitud y lo compara con los `server_name` de la configuración. Se usa para tener un solo puerto público, no exponer los servicios internos y poder centralizar aspectos como HTTPS.

## Requisitos previos

- Windows 10/11 con Docker Desktop (Docker Compose v2).
- Permisos de administrador para editar el archivo `hosts`.
- (Opcional) `curl`, incluido en Windows 10.

## Configuración

### 1. Variables de entorno

```bash
copy .env.example .env
```

Editar `.env` y cambiar todas las contraseñas (`cambiar_*`). El archivo `.env` no se sube al repositorio.

> Si se cambian `N8N_DB_USER` o `APP_DB_USER`, también hay que cambiarlos en `postgres/init.sql` (las líneas `GRANT`).

### 2. Resolución de nombres local

Agregar al final de `C:\Windows\System32\drivers\etc\hosts` (editor abierto como administrador):

```
127.0.0.1 app.lab.test n8n.lab.test db.lab.test
```

Alternativa desde una PowerShell como administrador:

```bash
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "127.0.0.1 app.lab.test n8n.lab.test db.lab.test"
```

Los comandos `curl` de este documento usan `--resolve`, por lo que funcionan aun sin este paso, pero el navegador sí lo necesita.

### 3. Construir e iniciar

```bash
docker compose up -d --build
```

Esperar entre 30 y 60 segundos: n8n y pgAdmin tardan en arrancar y el proxy responde 502 mientras tanto.

```bash
docker compose ps
```

### 4. Importar los workflows de n8n

Los workflows están en `n8n/workflows/mqtt.json` y `n8n/workflows/webhook.json`. El script crea las credenciales (PostgreSQL con `n8n_user` y Mosquitto) a partir del `.env`, importa los workflows, los publica y reinicia n8n:

```bash
powershell -ExecutionPolicy Bypass -File .\n8n\importar.ps1
```

Alternativa manual desde la interfaz (`http://n8n.lab.test:8080`): crear el usuario propietario, crear las credenciales *Postgres* (host `postgres`, puerto 5432, base `mediclock`, usuario `n8n_user`) y *MQTT* (host `mosquitto`, puerto 1883, sin usuario), importar ambos JSON (menú → *Import from file*), asignar las credenciales a los nodos y activar los workflows.

### 5. Detener

```bash
docker compose down
```

No usar `-v`: elimina los volúmenes y borra los datos.

## URLs y puertos

| Servicio | Acceso |
|---|---|
| Aplicación web | http://app.lab.test:8080 (eventos en `/Eventos`) |
| n8n | http://n8n.lab.test:8080 |
| pgAdmin | http://db.lab.test:8080 |
| Portainer | https://localhost:9443 (certificado autofirmado) |
| Mosquitto | `localhost:1883` |

Puertos publicados en el host: **8080** (proxy), **1883** (Mosquitto) y **127.0.0.1:9443** (Portainer). PostgreSQL, la app, n8n y pgAdmin no publican puertos.

### Reglas de enrutamiento del proxy

| `Host` de la solicitud | Destino |
|---|---|
| `app.lab.test` | `http://app:8080` |
| `n8n.lab.test` | `http://n8n:5678` (con WebSocket) |
| `db.lab.test` | `http://pgadmin:80` |
| cualquier otro | 404 |

Se resuelven con el DNS interno de Docker (`127.0.0.11`) usando los nombres de servicio, sin IP fijas.

### pgAdmin: registrar el servidor

Ingresar con `PGADMIN_DEFAULT_EMAIL` / `PGADMIN_DEFAULT_PASSWORD` del `.env`. *Add New Server*: host `postgres`, puerto `5432`, base `mediclock`, usuario `admin` y la contraseña `POSTGRES_PASSWORD`.

### Portainer

La primera vez pide crear el usuario administrador (hacerlo en los primeros minutos; si bloquea la pantalla, `docker compose restart portainer`). Elegir el entorno *local*. Los contenedores aparecen en *Containers*, con logs, redes y volúmenes.

## Pruebas

- MQTT request/reply: [pruebas/mqtt.md](pruebas/mqtt.md)
- Webhook HTTP: [pruebas/webhook.md](pruebas/webhook.md)

### Carga de datos de ejemplo

`pruebas/datos.json` contiene 8 eventos. Este script los envía uno por uno al webhook de n8n (cada uno debe responder `HTTP 201`):

```bash
powershell -ExecutionPolicy Bypass -File .\pruebas\cargar-datos.ps1
```

Luego se ven en `http://app.lab.test:8080/Eventos`. Si el proxy usa otro puerto: `-Puerto 8081`.

### Persistencia

1. Registrar un evento (webhook o MQTT).
2. `docker compose down` y luego `docker compose up -d` (sin `-v`).
3. Verificar que el registro sigue en `http://app.lab.test:8080/Eventos` o en pgAdmin, y que los workflows de n8n siguen activos.

### Diagnóstico

```bash
docker compose ps
docker compose logs n8n --tail 50
docker compose logs -f proxy
```

## Estructura del repositorio

```
docker-compose.yml     Definición de los 7 servicios, redes y volúmenes
.env.example           Variables de entorno (copiar a .env)
app/                   Aplicación web .NET + Dockerfile + .dockerignore
proxy/nginx.conf       Virtual hosts del proxy inverso
postgres/              00-roles.sh (roles) e init.sql (tabla y permisos)
mosquitto/             mosquitto.conf
n8n/workflows/         mqtt.json y webhook.json exportados
n8n/importar.ps1       Importa credenciales y workflows
pruebas/               Pruebas MQTT y webhook
docs/arquitectura.md   Diagrama de arquitectura
```

## Decisiones técnicas y problemas conocidos

- **Credenciales de base de datos:** `postgres/00-roles.sh` crea los roles con las contraseñas del `.env` durante la primera inicialización. `init.sql` otorga solo los permisos necesarios. Estos scripts solo se ejecutan cuando el volumen de PostgreSQL está vacío; para recrearlos hay que borrar `postgres_datos`.
- **Healthcheck:** PostgreSQL usa `pg_isready`; `app`, `n8n` y `pgadmin` esperan a que esté sano (`depends_on: service_healthy`).
- **Resolución DNS en Nginx:** se usa el resolver de Docker con variables en `proxy_pass`, de modo que el proxy arranca aunque algún servicio todavía no exista.
- **n8n tras el proxy:** `WEBHOOK_URL`, `N8N_PROXY_HOPS=1` y `N8N_SECURE_COOKIE=false` (HTTP local sin TLS).
- **pgAdmin:** rechaza correos con dominios reservados como `.test`; por eso el usuario por defecto es `admin@mediclock.com`.
- **Mosquitto sin autenticación:** es válido para el laboratorio local; en producción corresponde usar usuarios y ACL por tópico.
- **Seguridad de Portainer:** se publica solo en `127.0.0.1`, por lo que no es accesible desde la red.
- **Arranque inicial:** hasta que n8n y pgAdmin terminan de iniciar, el proxy responde 502.

## Preguntas de la defensa técnica (guía rápida)

- **Imagen vs contenedor:** la imagen es la plantilla inmutable; el contenedor es una instancia en ejecución de esa imagen.
- **Dockerfile vs Compose:** el Dockerfile define cómo construir *una* imagen; Compose define y orquesta *varios* servicios (redes, volúmenes, variables).
- **Resolución de nombres:** Docker incluye un DNS en las redes definidas por el usuario que resuelve el nombre de cada servicio a la IP de su contenedor.
- **PostgreSQL sin puerto publicado:** los demás contenedores lo alcanzan por la red Docker; publicar el puerto solo sirve para acceder desde el host, y aquí se evita para reducir la superficie de ataque.
- **HTTP vs MQTT request/reply:** en HTTP la respuesta viaja por la misma conexión; en MQTT es asincrónica, por tópicos, y se relaciona con la solicitud mediante el `correlation_id`.
- **Solo lectura de la app:** la app usa `app_user`, que solo tiene `SELECT`; la base rechaza cualquier escritura.
- **Datos al recrear contenedores:** persisten en los volúmenes nombrados; solo se pierden con `down -v`.
- **Error de conexión n8n ↔ PostgreSQL:** revisar `docker compose logs n8n`, el estado de la ejecución en n8n y que la credencial use host `postgres`, la base y el usuario correctos.
