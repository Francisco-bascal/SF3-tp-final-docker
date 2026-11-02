# Importa las credenciales y los workflows en n8n, los publica y reinicia el servicio.
# Ejecutar desde la raiz del repositorio, con la plataforma levantada:
#   powershell -ExecutionPolicy Bypass -File .\n8n\importar.ps1

$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

if (-not (Test-Path .env)) {
    throw 'No existe el archivo .env. Copiar .env.example a .env y completar las contrasenas.'
}

$variables = @{}
Get-Content .env | Where-Object { $_ -match '^\w+=' } | ForEach-Object {
    $clave, $valor = $_ -split '=', 2
    $variables[$clave] = $valor
}

# Las credenciales se arman desde el .env y se borran al terminar: no se guardan en el repositorio.
$credenciales = @(
    @{
        id = 'cred-postgres-n8n'; name = 'Postgres MediClock (n8n_user)'; type = 'postgres'
        data = @{
            host = 'postgres'; port = 5432; database = $variables['POSTGRES_DB']
            user = $variables['N8N_DB_USER']; password = $variables['N8N_DB_PASSWORD']
            ssl = 'disable'; allowUnauthorizedCerts = $false; maxConnections = 10
        }
    },
    @{
        id = 'cred-mqtt-mosquitto'; name = 'Mosquitto'; type = 'mqtt'
        data = @{
            protocol = 'mqtt'; host = 'mosquitto'; port = 1883; username = ''; password = ''
            clean = $true; clientId = ''; ssl = $false; passwordless = $true
        }
    }
)

$archivoTemporal = Join-Path $env:TEMP 'credenciales-n8n.json'
$json = ConvertTo-Json -InputObject $credenciales -Depth 6
[IO.File]::WriteAllText($archivoTemporal, $json, (New-Object Text.UTF8Encoding $false))

try {
    docker compose cp $archivoTemporal n8n:/tmp/credenciales.json
    docker compose cp .\n8n\workflows\mqtt.json n8n:/tmp/mqtt.json
    docker compose cp .\n8n\workflows\webhook.json n8n:/tmp/webhook.json

    docker compose exec -T n8n n8n import:credentials --input=/tmp/credenciales.json
    docker compose exec -T n8n n8n import:workflow --input=/tmp/mqtt.json
    docker compose exec -T n8n n8n import:workflow --input=/tmp/webhook.json

    docker compose exec -T n8n n8n publish:workflow --id=wfMqttEventos001
    docker compose exec -T n8n n8n publish:workflow --id=wfWebhookEventos1
}
finally {
    docker compose exec -T -u root n8n rm -f /tmp/credenciales.json /tmp/mqtt.json /tmp/webhook.json
    Remove-Item $archivoTemporal -Force -ErrorAction SilentlyContinue
}

docker compose restart n8n
Write-Host 'Workflows importados y publicados. Esperar unos segundos a que n8n termine de iniciar.'
