# Prueba 1: MQTT request/reply

Tópicos del grupo `g1`:

- Solicitud: `lab/g1/req/eventos.create`
- Respuesta: la indicada en `reply_to` (debe empezar con `lab/g1/res/`).

Se usan los clientes que trae el contenedor de Mosquitto, por lo que no hace falta instalar nada en el host.

## 1. Escuchar la respuesta

Terminal 1:

```bash
docker compose exec mosquitto mosquitto_sub -t "lab/g1/res/#" -v
```

## 2. Publicar una solicitud

Guardar el mensaje en un archivo dentro del contenedor y publicarlo (evita problemas de comillas en PowerShell).

Terminal 2:

```bash
docker compose exec mosquitto sh -c "echo '{\"correlation_id\":\"req-001\",\"reply_to\":\"lab/g1/res/eventos/req-001\",\"data\":{\"dispositivo\":\"mediclock-01\",\"tipo_evento\":\"alarma\",\"detalle\":\"Alarma de las 12:00\",\"cantidad\":1}}' > /tmp/req.json && mosquitto_pub -t lab/g1/req/eventos.create -f /tmp/req.json"
```

Respuesta esperada en la Terminal 1 (el `id` es el del registro creado en la base):

```
lab/g1/res/eventos/req-001 {"ok":true,"correlation_id":"req-001","result":{"id":3,"status":"created"}}
```

## 3. Solicitud inválida

Con `tipo_evento` fuera de `dispensado`, `omitido`, `alarma`, `error` (o sin `correlation_id`, `dispositivo`, o con `cantidad` menor o igual a 0) la respuesta es:

```
{"ok":false,"correlation_id":"req-002","errors":["data.tipo_evento debe ser uno de: dispensado, omitido, alarma, error"]}
```

No se inserta ningún registro.

## 4. Verificar en la base

```bash
docker compose exec postgres psql -U admin -d mediclock -c "SELECT * FROM eventos_dispensador ORDER BY id DESC LIMIT 5"
```

También se puede ver desde pgAdmin (`http://db.lab.test:8080`).
