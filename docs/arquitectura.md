# Diagrama de arquitectura

```mermaid
flowchart LR
    subgraph Host["Máquina anfitriona (Windows + Docker Desktop)"]
        Navegador["Navegador / curl"]
        Simulador["Simulador MQTT<br/>mosquitto_pub / sub"]
        Admin["Navegador (admin)"]
    end

    subgraph Frontend["red_frontend"]
        Proxy["proxy (Nginx)<br/>:8080 → 80"]
        App["app (.NET)<br/>:8080 interno"]
        N8N_F["n8n<br/>:5678 interno"]
        PgAdmin_F["pgadmin<br/>:80 interno"]
    end

    subgraph Backend["red_backend"]
        N8N["n8n"]
        PgAdmin["pgadmin"]
        AppB["app (.NET)"]
        Postgres[("postgres<br/>:5432 interno")]
        Mosquitto["mosquitto<br/>:1883"]
        Portainer["portainer<br/>:9443"]
    end

    Navegador -- "app/n8n/db.lab.test:8080" --> Proxy
    Proxy -- "Host: app.lab.test" --> App
    Proxy -- "Host: n8n.lab.test" --> N8N_F
    Proxy -- "Host: db.lab.test" --> PgAdmin_F

    Simulador -- "1883" --> Mosquitto
    Mosquitto <-- "MQTT" --> N8N
    N8N -- "n8n_user: SELECT, INSERT" --> Postgres
    AppB -- "app_user: SELECT" --> Postgres
    PgAdmin -- "admin" --> Postgres

    Admin -- "https://localhost:9443" --> Portainer
    Portainer -. "/var/run/docker.sock" .-> Docker[("Docker Engine")]
```

`app`, `n8n` y `pgadmin` están conectados a ambas redes (el recuadro los dibuja en cada una según el rol que cumplen en ella). `postgres`, `mosquitto` y `portainer` solo están en `red_backend`.

## Puertos publicados en el host

| Servicio | Puerto host | Observación |
|---|---|---|
| proxy (Nginx) | 8080 | Único punto de entrada HTTP |
| mosquitto | 1883 | Pruebas MQTT desde el host |
| portainer | 127.0.0.1:9443 | Solo accesible desde la propia máquina |

PostgreSQL, la aplicación web, n8n y pgAdmin no publican puertos.

## Redes

- `red_frontend`: proxy, app, n8n, pgadmin. Es la red por la que el proxy alcanza a los servicios web.
- `red_backend`: postgres, mosquitto, portainer y los servicios que los consumen (app, n8n, pgadmin). La base de datos y el broker no son alcanzables desde el proxy.

## Volúmenes

`postgres_datos`, `pgadmin_datos`, `n8n_datos`, `mosquitto_datos`, `portainer_datos`.
