# Prueba MQTT request/reply

Todos los comandos se ejecutan en **PowerShell normal**, dentro de la carpeta raíz del proyecto (la que contiene `docker-compose.yml`). Hacen falta **dos ventanas** de PowerShell abiertas en esa carpeta.

Tópicos del grupo `g1`:

- Solicitud: `lab/g1/req/eventos.create`
- Respuesta: el tópico indicado en `reply_to` (siempre empieza con `lab/g1/res/`).

Los mensajes de ejemplo ya están en el repositorio, no hay que escribir ni editar JSON:

| Archivo | Contenido |
|---|---|
| `pruebas/mqtt-solicitud.json` | Solicitud válida (`correlation_id` = `req-001`) |
| `pruebas/mqtt-solicitud-invalida.json` | Solicitud con `tipo_evento` inexistente (`correlation_id` = `req-002`) |

## Caso 1: solicitud válida

**Ventana 1** (escucha; queda esperando hasta 60 segundos y se cierra sola al recibir la respuesta):

```bash
docker compose exec mosquitto mosquitto_sub -t "lab/g1/res/#" -v -C 1 -W 60
```

**Ventana 2** (envía la solicitud; no muestra nada si salió bien):

```bash
docker compose exec mosquitto mosquitto_pub -t lab/g1/req/eventos.create -f /pruebas/mqtt-solicitud.json
```

**Resultado esperado en la Ventana 1** (el `id` es el del registro creado):

```
lab/g1/res/eventos/req-001 {"ok":true,"correlation_id":"req-001","result":{"id":1,"status":"created"}}
```

Verificar que el `correlation_id` es el mismo que se envió (`req-001`). El registro aparece en `http://app.lab.test:8080/Eventos`.

## Caso 2: solicitud inválida

Repetir los dos comandos anteriores cambiando solamente el nombre del archivo en la Ventana 2 por `/pruebas/mqtt-solicitud-invalida.json`.

**Resultado esperado en la Ventana 1:**

```
lab/g1/res/eventos/req-002 {"ok":false,"correlation_id":"req-002","errors":["data.tipo_evento debe ser uno de: dispensado, omitido, alarma, error"]}
```

No se crea ningún registro.

## Si la Ventana 1 termina con `Timed out` y sin respuesta

1. Esperar 1 minuto después de levantar o reiniciar el sistema y repetir.
2. Comprobar que los workflows están importados y publicados (ver README, sección de problemas).
3. Ver los registros de n8n: `docker compose logs n8n --tail 50`
