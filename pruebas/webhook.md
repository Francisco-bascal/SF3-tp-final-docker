# Prueba 2: Webhook HTTP

Endpoint: `POST http://n8n.lab.test:8080/webhook/eventos`

Si el archivo `hosts` ya tiene los nombres `lab.test`, se puede omitir `--resolve`.

## Solicitud válida (201)

Guardar el cuerpo en un archivo `evento.json`:

```json
{"dispositivo":"mediclock-01","tipo_evento":"dispensado","detalle":"Toma de las 08:00","cantidad":2}
```

```bash
curl --resolve n8n.lab.test:8080:127.0.0.1 -X POST "http://n8n.lab.test:8080/webhook/eventos" -H "Content-Type: application/json" -d @evento.json
```

Respuesta esperada (HTTP 201):

```json
{"ok":true,"result":{"id":2,"status":"created"}}
```

## Solicitud inválida (400)

```bash
curl --resolve n8n.lab.test:8080:127.0.0.1 -X POST "http://n8n.lab.test:8080/webhook/eventos" -H "Content-Type: application/json" -d "{}"
```

Respuesta esperada (HTTP 400):

```json
{"ok":false,"errors":["dispositivo es obligatorio (texto de hasta 50 caracteres)","tipo_evento debe ser uno de: dispensado, omitido, alarma, error"]}
```

## Verificar

- Aplicación web: `http://app.lab.test:8080/Eventos` muestra el registro nuevo.
- pgAdmin: `http://db.lab.test:8080`, tabla `eventos_dispensador`.
