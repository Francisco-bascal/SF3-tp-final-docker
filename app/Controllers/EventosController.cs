using MediClock.Web.Dtos;
using MediClock.Web.Servicios;
using Microsoft.AspNetCore.Mvc;

namespace MediClock.Web.Controllers;

public class EventosController : Controller
{
    private readonly IEventoService _eventoService;
    private readonly ILogger<EventosController> _logger;

    public EventosController(IEventoService eventoService, ILogger<EventosController> logger)
    {
        _eventoService = eventoService;
        _logger = logger;
    }

    public async Task<IActionResult> Index(CancellationToken cancellationToken)
    {
        try
        {
            var eventos = await _eventoService.ObtenerUltimosAsync(cancellationToken);
            return View(eventos);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogError(ex, "No se pudieron consultar los eventos.");
            ViewBag.MensajeError = "No se pudo conectar con la base de datos. Intente nuevamente más tarde.";
            return View(new List<EventoDto>());
        }
    }
}
