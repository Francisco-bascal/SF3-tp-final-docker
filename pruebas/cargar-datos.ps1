# Carga los eventos de pruebas/datos.json enviandolos uno por uno al webhook de n8n.
# Ejecutar desde la raiz del repositorio, con la plataforma levantada y los workflows importados:
#   powershell -ExecutionPolicy Bypass -File .\pruebas\cargar-datos.ps1
# Si el proxy usa otro puerto: ... -Puerto 8081

param(
    [int]$Puerto = 8080
)

$archivoDatos = Join-Path $PSScriptRoot 'datos.json'
$archivoTemporal = Join-Path $env:TEMP 'evento-webhook.json'
$url = "http://n8n.lab.test:$Puerto/webhook/eventos"
$sinCodificacionBom = New-Object Text.UTF8Encoding $false

$eventos = Get-Content $archivoDatos -Raw -Encoding UTF8 | ConvertFrom-Json
$fallidos = 0

foreach ($evento in $eventos) {
    [IO.File]::WriteAllText($archivoTemporal, ($evento | ConvertTo-Json -Compress), $sinCodificacionBom)

    # --resolve evita depender del archivo hosts para esta prueba.
    $respuesta = curl.exe -s --resolve "n8n.lab.test:${Puerto}:127.0.0.1" `
        -X POST $url -H 'Content-Type: application/json' -d "@$archivoTemporal" `
        -w ' HTTP %{http_code}'

    Write-Host "$($evento.dispositivo) / $($evento.tipo_evento): $respuesta"
    if ($respuesta -notmatch 'HTTP 201$') { $fallidos++ }
}

Remove-Item $archivoTemporal -Force -ErrorAction SilentlyContinue

if ($fallidos -gt 0) {
    Write-Host "$fallidos evento(s) no se cargaron. Revisar que n8n este iniciado y los workflows publicados."
    exit 1
}
Write-Host "Se cargaron $($eventos.Count) eventos. Verlos en http://app.lab.test:$Puerto/Eventos"
