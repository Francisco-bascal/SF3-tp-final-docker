namespace MediClock.Web.Dtos;

public class EventoDto
{
    public int Id { get; set; }

    public string Dispositivo { get; set; } = string.Empty;

    public string TipoEvento { get; set; } = string.Empty;

    public string? Detalle { get; set; }

    public int Cantidad { get; set; }

    public DateTime CreadoEn { get; set; }
}
