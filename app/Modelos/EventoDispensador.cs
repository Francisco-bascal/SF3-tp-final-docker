namespace MediClock.Web.Modelos;

public class EventoDispensador
{
    public int Id { get; set; }

    public string Dispositivo { get; set; } = string.Empty;

    public string TipoEvento { get; set; } = string.Empty;

    public string? Detalle { get; set; }

    public int Cantidad { get; set; }

    public DateTime CreadoEn { get; set; }
}
