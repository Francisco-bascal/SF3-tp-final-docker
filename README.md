# MediClock - Plataforma Docker integrada

Trabajo Práctico Integrador Final - Software Factory 3 (ITES 2026).

## Integrantes

- Bascal Francisco Emanuel
- Fuentes Facundo Demian
- Alzuri Luciana Aymara
- Díaz Ignacio

## Qué es y qué se logra

MediClock es un dispensador automático de pastillas (motor stepper, RTC, sensor magnético, LED y pantalla LCD) que se configura desde un sistema web. Esta plataforma simula el registro de **eventos del dispensador** (pastilla dispensada, omitida, alarma, error). Los eventos llegan por **MQTT** o por **HTTP**, se procesan con n8n, se guardan en PostgreSQL y se ven en una página web. No se usa hardware real: los mensajes se simulan con comandos.

Siguiendo esta guía se levanta todo con Docker en unos 20 minutos (la primera vez la descarga puede tardar más).

**Índice:** [Requisitos](#1-requisitos) · [Cómo usar la terminal](#2-cómo-usar-la-terminal-powershell) · [Instalación paso a paso](#3-instalación-paso-a-paso) · [Pruebas](#4-pruebas) · [Detener, reiniciar, borrar](#5-detener-reiniciar-y-borrar-todo) · [Problemas frecuentes](#6-problemas-frecuentes) · [Información técnica](#7-información-técnica)

---

## 1. Requisitos

Una computadora con **Windows 10 u 11**, conexión a internet y estos dos programas instalados:

| Programa | Para qué sirve | Cómo comprobar que está instalado |
|---|---|---|
| **Docker Desktop** | Ejecuta los contenedores | Abrir PowerShell y escribir `docker --version` |
| **Git** | Descarga el proyecto | Abrir PowerShell y escribir `git --version` |

Si el comando muestra una versión (por ejemplo `Docker version 28.5.1`), está instalado. Si dice que no se reconoce, instalarlo desde [docker.com](https://www.docker.com/products/docker-desktop/) o [git-scm.com](https://git-scm.com/download/win).

**Antes de empezar, abrir Docker Desktop** (menú Inicio → Docker Desktop) y esperar a que abajo a la izquierda se vea **"Engine running"** en verde. Si no está en verde, los comandos de Docker fallan.

## 2. Cómo usar la terminal (PowerShell)

Todos los comandos de esta guía se escriben en **PowerShell**. Hay dos formas de abrirla:

| Tipo | Cómo abrirla | Cuándo se usa |
|---|---|---|
| **PowerShell normal** | Tecla Windows → escribir `PowerShell` → Enter | Casi todos los pasos |
| **PowerShell como administrador** | Tecla Windows → escribir `PowerShell` → clic derecho en el resultado → **Ejecutar como administrador** → **Sí** | Solo el paso 3.3 (archivo `hosts`) |

Para ejecutar un comando: copiarlo, pegarlo en la ventana (clic derecho pega) y apretar **Enter**.

**La carpeta raíz del proyecto** es la carpeta que contiene el archivo `docker-compose.yml`. Casi todos los comandos hay que ejecutarlos **dentro de esa carpeta**. Para comprobar que se está en ella, escribir `dir`: tiene que aparecer la lista de archivos con `docker-compose.yml`.

En PowerShell hay que escribir **`curl.exe`** (con `.exe`). Sin eso, PowerShell ejecuta otro comando distinto.

## 3. Instalación paso a paso

### 3.1. Descargar el proyecto

**Dónde:** PowerShell normal. **Carpeta:** cualquiera (se usa Documentos).

```bash
cd $HOME\Documents
git clone https://github.com/Francisco-bascal/SF3-tp-final-docker.git
cd SF3-tp-final-docker
dir
```

**Resultado esperado:** `dir` lista archivos, entre ellos `docker-compose.yml`, `README.md` y las carpetas `app`, `proxy`, `n8n`, `pruebas`. **A partir de acá, todos los comandos se ejecutan en esta carpeta** (`SF3-tp-final-docker`).

### 3.2. Crear el archivo de configuración `.env`

**Dónde:** PowerShell normal, en la carpeta raíz del proyecto.

```bash
copy .env.example .env
```

**Resultado esperado:** `1 archivo(s) copiado(s).` No hace falta editar nada para esta prueba. Los usuarios y contraseñas que se usan en el resto de la guía son los de ese archivo:

| Dato | Valor |
|---|---|
| Email de pgAdmin | `admin@mediclock.com` |
| Contraseña de pgAdmin | `cambiar_pgadmin` |
| Contraseña de la base de datos (usuario `admin`) | `cambiar_admin` |

> No cambiar usuarios ni contraseñas del `.env` después del primer arranque: la base de datos los guarda la primera vez. Si hace falta cambiarlos, hay que borrar todo (ver sección 5).

### 3.3. Configurar los nombres de las direcciones (archivo `hosts`)

La plataforma se abre con direcciones como `app.lab.test`. Este paso le indica a Windows que esas direcciones apuntan a tu propia computadora.

**Dónde:** **PowerShell como administrador** (ver sección 2). **Carpeta:** cualquiera.

```bash
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "127.0.0.1 app.lab.test n8n.lab.test db.lab.test"
```

Para comprobar (en cualquier PowerShell):

```bash
ping app.lab.test -n 1
```

**Resultado esperado:** una línea `Respuesta desde 127.0.0.1`. Hacerlo una sola vez por computadora. Si se ejecuta dos veces no pasa nada grave (queda la línea repetida).

### 3.4. Construir e iniciar la plataforma

**Dónde:** PowerShell normal, en la carpeta raíz del proyecto, con Docker Desktop abierto.

```bash
docker compose up -d --build
```

**Resultado esperado:** la primera vez descarga imágenes y compila la aplicación (puede tardar entre 5 y 15 minutos). Termina con líneas `Started` o `Healthy` y vuelve el cursor sin errores.

Esperar **1 minuto** y comprobar:

```bash
docker compose ps
```

**Resultado esperado:** 7 servicios con estado `Up`, y `postgres` con `(healthy)`:

```
SERVICE     STATUS
app         Up ...
mosquitto   Up ...
n8n         Up ...
pgadmin     Up ...
portainer   Up ...
postgres    Up ... (healthy)
proxy       Up ...
```

Si falta alguno, ver la sección 6.

### 3.5. Importar los workflows de n8n

Carga en n8n los dos procesos automáticos del proyecto (MQTT y webhook) y sus conexiones a la base de datos y al broker.

**Dónde:** PowerShell normal, en la carpeta raíz del proyecto.

```bash
powershell -ExecutionPolicy Bypass -File .\n8n\importar.ps1
```

**Resultado esperado:** aparecen estas líneas (entre otras): `Successfully imported 2 credentials.` y dos veces `Successfully imported 1 workflow.` Al final reinicia n8n. **Esperar 1 minuto** antes de seguir.

### 3.6. Crear los usuarios de cada programa

Cada programa pide crear un usuario la primera vez. Se hace desde el navegador (Chrome, Edge o Firefox).

#### n8n: `http://n8n.lab.test:8080`

1. Se muestra **Set up owner account**. Completar: **Email** (cualquiera, por ejemplo el propio), **First Name**, **Last Name** y **Password** (8 o más caracteres, con al menos 1 número y 1 mayúscula).
2. Dejar sin marcar la casilla de recibir novedades y apretar **Next**.
3. Si aparecen preguntas de personalización o una clave de licencia, apretar **Skip** o cerrar.
4. En el menú de la izquierda entrar a **Workflows**. **Resultado esperado:** dos workflows, *MQTT - Registrar evento (request/reply)* y *Webhook - Registrar evento (HTTP)*, publicados (activos). Si no aparecen, ver la sección 6.

Anotar el email y la contraseña elegidos.

#### pgAdmin: `http://db.lab.test:8080`

1. Iniciar sesión con **Email** `admin@mediclock.com` y **Password** `cambiar_pgadmin`.
2. En el panel izquierdo, clic derecho en **Servers** → **Register** → **Server...**
3. Pestaña **General**: en **Name** escribir `mediclock`.
4. Pestaña **Connection**, completar exactamente:

   | Campo | Valor |
   |---|---|
   | Host name/address | `postgres` |
   | Port | `5432` |
   | Maintenance database | `mediclock` |
   | Username | `admin` |
   | Password | `cambiar_admin` |
   | Save password | marcado |

   (El host es `postgres`, **no** `localhost`.)
5. Apretar **Save**. **Resultado esperado:** aparece `mediclock` bajo Servers sin errores.
6. Para ver la tabla: `mediclock` → **Databases** → **mediclock** → **Schemas** → **public** → **Tables** → clic derecho en `eventos_dispensador` → **View/Edit Data** → **All Rows**. Por ahora está vacía.

#### Portainer: `https://localhost:9443`

1. El navegador avisa que la conexión no es privada (el certificado es autofirmado). Apretar **Avanzado** → **Continuar a localhost**.
2. Si dice *"timed out for security purposes"*: en PowerShell ejecutar `docker compose restart portainer`, esperar 10 segundos y recargar la página.
3. La página pide un **setup token**. Obtenerlo en PowerShell (carpeta raíz del proyecto):

   ```bash
   docker compose logs portainer | findstr setup_token
   ```

   Copiar el valor largo que aparece después de `setup_token=` (si hay varios, el último) y pegarlo en la página.
4. Crear el usuario administrador: **Username** `admin` y una contraseña de **12 o más caracteres**. Apretar **Create user**.
5. Si aparece *Edge Compute*, **no** marcar la casilla y continuar.
6. Apretar **Get Started** (la ballena de Docker). Entrar al entorno **local**.
7. **Resultado esperado:** en **Containers** se ven los 7 contenedores del proyecto.

#### Aplicación web: `http://app.lab.test:8080`

No pide usuario. Entrar a `http://app.lab.test:8080/Eventos`: **Resultado esperado:** el mensaje *"No hay eventos registrados."* (todavía no hay datos).

## 4. Pruebas

Los archivos JSON necesarios ya están en la carpeta `pruebas` del proyecto; no hay que escribir ni editar nada. Todos los comandos: **PowerShell normal, en la carpeta raíz del proyecto**.

### Prueba 1: webhook HTTP

Enviar un evento válido:

```bash
curl.exe -X POST http://n8n.lab.test:8080/webhook/eventos -H "Content-Type: application/json" -d "@pruebas/webhook-evento.json" -w " HTTP %{http_code}"
```

**Resultado esperado:** `{"ok":true,"result":{"id":1,"status":"created"}} HTTP 201`

Enviar un evento inválido:

```bash
curl.exe -X POST http://n8n.lab.test:8080/webhook/eventos -H "Content-Type: application/json" -d "@pruebas/webhook-invalido.json" -w " HTTP %{http_code}"
```

**Resultado esperado:** `{"ok":false,"errors":[...]} HTTP 400` (no se crea ningún registro).

**Verificar:** recargar `http://app.lab.test:8080/Eventos` (aparece 1 fila) y en pgAdmin repetir *View/Edit Data → All Rows* sobre `eventos_dispensador`.

### Prueba 2: cargar 8 eventos de ejemplo

```bash
powershell -ExecutionPolicy Bypass -File .\pruebas\cargar-datos.ps1
```

**Resultado esperado:** ocho líneas terminadas en `HTTP 201` y al final `Se cargaron 8 eventos`. Recargar `http://app.lab.test:8080/Eventos`: se ven los eventos.

### Prueba 3: MQTT (solicitud y respuesta)

Hacen falta **dos ventanas** de PowerShell abiertas en la carpeta raíz del proyecto.

**Ventana 1** (escucha la respuesta; queda esperando y se cierra sola al recibirla, o a los 60 segundos):

```bash
docker compose exec mosquitto mosquitto_sub -t "lab/g1/res/#" -v -C 1 -W 60
```

**Ventana 2** (envía la solicitud; no imprime nada si salió bien):

```bash
docker compose exec mosquitto mosquitto_pub -t lab/g1/req/eventos.create -f /pruebas/mqtt-solicitud.json
```

**Resultado esperado en la Ventana 1** (el `id` es el del registro creado):

```
lab/g1/res/eventos/req-001 {"ok":true,"correlation_id":"req-001","result":{"id":9,"status":"created"}}
```

Comprobar que `correlation_id` es `req-001`, igual al enviado. Recargar `http://app.lab.test:8080/Eventos`: aparece el evento "Alarma de las 12:00".

Para probar un error, repetir los dos comandos usando `/pruebas/mqtt-solicitud-invalida.json` en la Ventana 2. La respuesta será `"ok":false` con `"correlation_id":"req-002"`. Más detalle en [pruebas/mqtt.md](pruebas/mqtt.md).

### Prueba 4: las tres aplicaciones por el mismo puerto (proxy inverso)

Abrir en el navegador estas tres direcciones. Todas usan el **puerto 8080**:

| Dirección | Debe mostrar |
|---|---|
| `http://app.lab.test:8080` | La aplicación MediClock |
| `http://n8n.lab.test:8080` | n8n |
| `http://db.lab.test:8080` | pgAdmin |

Comprobar que ninguna de las tres tiene su propio puerto publicado (solo se ve `0.0.0.0:8080` en el proxy):

```bash
docker compose ps
```

### Prueba 5: persistencia de datos

1. Anotar cuántos eventos se ven en `http://app.lab.test:8080/Eventos`.
2. Detener y volver a crear los contenedores (**sin** `-v`):

   ```bash
   docker compose down
   docker compose up -d
   ```

3. Esperar **1 minuto** y recargar `http://app.lab.test:8080/Eventos`. **Resultado esperado:** los mismos eventos siguen ahí, y n8n conserva el usuario y los workflows.

### Prueba 6: Portainer y diagnóstico

1. En `https://localhost:9443` → entorno **local** → **Containers**: se ven los contenedores y su estado.
2. Clic en un contenedor (por ejemplo `n8n`) → ícono **Logs** (documento) para ver sus registros.
3. En PowerShell:

   ```bash
   docker compose ps
   docker compose logs n8n --tail 20
   ```

## 5. Detener, reiniciar y borrar todo

**Dónde:** PowerShell normal, en la carpeta raíz del proyecto.

| Qué se quiere | Comando |
|---|---|
| Detener (se conservan los datos) | `docker compose down` |
| Volver a iniciar | `docker compose up -d` y esperar 1 minuto |
| **Borrar todo, incluidos los datos** y empezar de cero | `docker compose down -v` |

Si se borra todo, se repiten los pasos 3.4, 3.5 y 3.6 (los usuarios de n8n, pgAdmin y Portainer hay que crearlos de nuevo).

## 6. Problemas frecuentes

| Qué se ve | Causa probable | Qué hacer |
|---|---|---|
| `error during connect ... dockerDesktopLinuxEngine` | Docker Desktop no está abierto | Abrirlo y esperar "Engine running" en verde |
| `port is already allocated` / `address already in use` | Otro programa usa el puerto 8080, 1883 o 9443 | Cerrar ese programa. Para el 8080, cambiar `PROXY_PUERTO=8081` en `.env` y usar `:8081` en todas las direcciones |
| La página dice `502 Bad Gateway` | n8n o pgAdmin todavía están arrancando | Esperar 1 minuto y recargar |
| `app.lab.test` no abre ("no se puede acceder") | Falta el paso 3.3 | Repetir el paso 3.3 con PowerShell **como administrador** |
| *"No se pudo conectar con la base de datos"* | Se cambiaron las contraseñas del `.env` después del primer arranque | Borrar todo con `docker compose down -v` y repetir desde el paso 3.4 |
| No aparecen los workflows en n8n, o el webhook responde `404` | No se importaron o falta reiniciar n8n | Repetir el paso 3.5 y esperar 1 minuto |
| MQTT: la Ventana 1 dice `Timed out` sin respuesta | n8n recién iniciado o workflow no publicado | Esperar 1 minuto, repetir el paso 3.5 y volver a probar. Ver `docker compose logs n8n --tail 50` |
| Portainer dice *"timed out for security purposes"* | Pasaron unos minutos sin crear el usuario | `docker compose restart portainer` y recargar |
| En pgAdmin no conecta con el servidor | Se puso `localhost` como host | El host es `postgres` |
| Tengo PostgreSQL instalado en mi PC | No interfiere: el de este proyecto corre dentro de Docker y no usa el puerto 5432 de tu PC | Nada |

---

## 7. Información técnica

### Arquitectura

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

### Direcciones y puertos

| Servicio | Acceso |
|---|---|
| Aplicación web | http://app.lab.test:8080 (eventos en `/Eventos`) |
| n8n | http://n8n.lab.test:8080 |
| pgAdmin | http://db.lab.test:8080 |
| Portainer | https://localhost:9443 (certificado autofirmado) |
| Mosquitto | `localhost:1883` |

Puertos publicados en el host: **8080** (proxy), **1883** (Mosquitto) y **127.0.0.1:9443** (Portainer). PostgreSQL, la app, n8n y pgAdmin no publican puertos.

### Redes y volúmenes

- `red_frontend`: proxy, app, n8n y pgadmin. Es la red por la que el proxy llega a los servicios web.
- `red_backend`: postgres, mosquitto, portainer y los servicios que los usan. PostgreSQL y Mosquitto no son alcanzables desde el proxy: se separan para que el único camino HTTP hacia el exterior sea el proxy.
- Volúmenes: `postgres_datos`, `pgadmin_datos`, `n8n_datos`, `mosquitto_datos`, `portainer_datos`.

### Roles de base de datos y permisos

| Rol | Permisos | Usado por |
|---|---|---|
| `admin` (superusuario) | Todos | Solo administración (pgAdmin, `psql`) |
| `n8n_user` | `SELECT`, `INSERT` | n8n |
| `app_user` | `SELECT` | Aplicación web |

La aplicación web no puede modificar datos: un `INSERT` con `app_user` falla con `permission denied`.

### Reglas de enrutamiento del proxy

| `Host` de la solicitud | Destino |
|---|---|
| `app.lab.test` | `http://app:8080` |
| `n8n.lab.test` | `http://n8n:5678` (con WebSocket) |
| `db.lab.test` | `http://pgadmin:80` |
| cualquier otro | 404 |

Se resuelven con el DNS interno de Docker (`127.0.0.11`) usando los nombres de servicio, sin IP fijas.

### Tecnologías elegidas y justificación

- **Aplicación web: C# con ASP.NET Core (.NET 8) y Entity Framework Core.** Es la tecnología que usa el sistema real de MediClock. La app sigue la estructura Controller → Service → DbContext y construye su imagen con un Dockerfile multi-stage (SDK para compilar, runtime liviano para ejecutar).
- **Proxy inverso: Nginx.** Configuración explícita en un archivo (`proxy/nginx.conf`), fácil de leer y de explicar, con un `server` (virtual host) por servicio. Se prefirió a Traefik porque no requiere montar el socket de Docker en el proxy y a Caddy por ser más habitual en la industria y en la documentación disponible.

**Proxy inverso:** es un servidor que recibe todas las solicitudes HTTP y las reenvía al servicio correcto. Identifica el destino por el encabezado `Host` de la solicitud y lo compara con los `server_name` de la configuración. Se usa para tener un solo puerto público, no exponer los servicios internos y poder centralizar aspectos como HTTPS.

### Estructura del repositorio

```
docker-compose.yml     Definición de los 7 servicios, redes y volúmenes
.env.example           Variables de entorno (copiar a .env)
app/                   Aplicación web .NET + Dockerfile + .dockerignore
proxy/nginx.conf       Virtual hosts del proxy inverso
postgres/              00-roles.sh (roles) e init.sql (tabla y permisos)
mosquitto/             mosquitto.conf
n8n/workflows/         mqtt.json y webhook.json exportados
n8n/importar.ps1       Importa credenciales y workflows
pruebas/               JSON de ejemplo, cargar-datos.ps1, mqtt.md y webhook.md
docs/arquitectura.md   Diagrama de arquitectura
```

### Decisiones técnicas y problemas conocidos

- **Credenciales de base de datos:** `postgres/00-roles.sh` crea los roles con las contraseñas del `.env` durante la primera inicialización. `init.sql` otorga solo los permisos necesarios a `n8n_user` y `app_user` (nombres fijos: no cambiarlos en el `.env`). Estos scripts solo se ejecutan cuando el volumen de PostgreSQL está vacío.
- **Healthcheck:** PostgreSQL usa `pg_isready`; `app`, `n8n` y `pgadmin` esperan a que esté sano (`depends_on: service_healthy`).
- **Resolución DNS en Nginx:** se usa el resolver de Docker con variables en `proxy_pass`, de modo que el proxy arranca aunque algún servicio todavía no exista.
- **n8n tras el proxy:** `WEBHOOK_URL`, `N8N_PROXY_HOPS=1` y `N8N_SECURE_COOKIE=false` (HTTP local sin TLS).
- **pgAdmin:** rechaza correos con dominios reservados como `.test`; por eso el usuario por defecto es `admin@mediclock.com`.
- **Mosquitto sin autenticación:** es válido para el laboratorio local; en producción corresponde usar usuarios y ACL por tópico. La carpeta `pruebas` se monta en el contenedor (solo lectura) para publicar los mensajes de ejemplo.
- **Seguridad de Portainer:** se publica solo en `127.0.0.1`, por lo que no es accesible desde la red.
- **Arranque inicial:** hasta que n8n y pgAdmin terminan de iniciar, el proxy responde 502.
- **Importación de workflows:** el trigger MQTT de n8n se conecta al iniciar; por eso `importar.ps1` publica los workflows y reinicia n8n.

### Preguntas de la defensa técnica (guía rápida)

- **Imagen vs contenedor:** la imagen es la plantilla inmutable; el contenedor es una instancia en ejecución de esa imagen.
- **Dockerfile vs Compose:** el Dockerfile define cómo construir *una* imagen; Compose define y orquesta *varios* servicios (redes, volúmenes, variables).
- **Resolución de nombres:** Docker incluye un DNS en las redes definidas por el usuario que resuelve el nombre de cada servicio a la IP de su contenedor.
- **PostgreSQL sin puerto publicado:** los demás contenedores lo alcanzan por la red Docker; publicar el puerto solo sirve para acceder desde el host, y aquí se evita para reducir la superficie de ataque.
- **HTTP vs MQTT request/reply:** en HTTP la respuesta viaja por la misma conexión; en MQTT es asincrónica, por tópicos, y se relaciona con la solicitud mediante el `correlation_id`.
- **Solo lectura de la app:** la app usa `app_user`, que solo tiene `SELECT`; la base rechaza cualquier escritura.
- **Datos al recrear contenedores:** persisten en los volúmenes nombrados; solo se pierden con `down -v`.
- **Error de conexión n8n ↔ PostgreSQL:** revisar `docker compose logs n8n`, el estado de la ejecución en n8n y que la credencial use host `postgres`, la base y el usuario correctos.
