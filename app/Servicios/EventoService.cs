using MediClock.Web.Datos;
using MediClock.Web.Dtos;
using Microsoft.EntityFrameworkCore;

namespace MediClock.Web.Servicios;

public class EventoService : IEventoService
{
    private const int CantidadMaximaEventos = 100;

    private readonly MediClockDbContext _context;

    public EventoService(MediClockDbContext context)
    {
        _context = context;
    }

    public async Task<List<EventoDto>> ObtenerUltimosAsync(CancellationToken cancellationToken = default)
    {
        return await _context.Eventos
            .AsNoTracking()
            .OrderByDescending(e => e.CreadoEn)
            .Take(CantidadMaximaEventos)
            .Select(e => new EventoDto
            {
                Id = e.Id,
                Dispositivo = e.Dispositivo,
                TipoEvento = e.TipoEvento,
                Detalle = e.Detalle,
                Cantidad = e.Cantidad,
                CreadoEn = e.CreadoEn
            })
            .ToListAsync(cancellationToken);
    }
}
