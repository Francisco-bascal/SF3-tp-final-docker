using MediClock.Web.Dtos;

namespace MediClock.Web.Servicios;

public interface IEventoService
{
    Task<List<EventoDto>> ObtenerUltimosAsync(CancellationToken cancellationToken = default);
}
