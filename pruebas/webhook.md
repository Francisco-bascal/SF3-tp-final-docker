# Prueba del webhook HTTP

Todos los comandos se ejecutan en **PowerShell normal**, dentro de la carpeta raíz del proyecto (la que contiene `docker-compose.yml`). Requieren que el archivo `hosts` tenga los nombres `lab.test` (ver README).

Endpoint: `POST http://n8n.lab.test:8080/webhook/eventos`

Importante: en PowerShell hay que escribir `curl.exe` (con `.exe`). Sin eso, PowerShell usa otro comando distinto.

Los cuerpos de ejemplo ya están en el repositorio:

| Archivo | Contenido |
|---|---|
| `pruebas/webhook-evento.json` | Evento válido |
| `pruebas/webhook-invalido.json` | Evento inválido (`tipo_evento` inexistente y `cantidad` 0) |
| `pruebas/datos.json` | Lista de 8 eventos para cargar de una sola vez |

## Caso 1: evento válido (HTTP 201)

```bash
curl.exe -X POST http://n8n.lab.test:8080/webhook/eventos -H "Content-Type: application/json" -d "@pruebas/webhook-evento.json" -w " HTTP %{http_code}"
```

Resultado esperado:

```
{"ok":true,"result":{"id":1,"status":"created"}} HTTP 201
```

## Caso 2: evento inválido (HTTP 400)

```bash
curl.exe -X POST http://n8n.lab.test:8080/webhook/eventos -H "Content-Type: application/json" -d "@pruebas/webhook-invalido.json" -w " HTTP %{http_code}"
```

Resultado esperado:

```
{"ok":false,"errors":["tipo_evento debe ser uno de: dispensado, omitido, alarma, error","cantidad debe ser un entero mayor a 0"]} HTTP 400
```

## Caso 3: cargar los 8 eventos de ejemplo

```bash
powershell -ExecutionPolicy Bypass -File .\pruebas\cargar-datos.ps1
```

Resultado esperado: ocho líneas terminadas en `HTTP 201` y el mensaje final `Se cargaron 8 eventos`.

## Verificar

- Aplicación web: `http://app.lab.test:8080/Eventos`
- pgAdmin: `http://db.lab.test:8080`, tabla `eventos_dispensador`.
