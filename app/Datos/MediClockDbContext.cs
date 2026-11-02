using MediClock.Web.Modelos;
using Microsoft.EntityFrameworkCore;

namespace MediClock.Web.Datos;

public class MediClockDbContext : DbContext
{
    public MediClockDbContext(DbContextOptions<MediClockDbContext> options)
        : base(options)
    {
    }

    public DbSet<EventoDispensador> Eventos => Set<EventoDispensador>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<EventoDispensador>(entidad =>
        {
            entidad.ToTable("eventos_dispensador");
            entidad.HasKey(e => e.Id);
            entidad.Property(e => e.Id).HasColumnName("id");
            entidad.Property(e => e.Dispositivo).HasColumnName("dispositivo");
            entidad.Property(e => e.TipoEvento).HasColumnName("tipo_evento");
            entidad.Property(e => e.Detalle).HasColumnName("detalle");
            entidad.Property(e => e.Cantidad).HasColumnName("cantidad");
            entidad.Property(e => e.CreadoEn).HasColumnName("creado_en");
        });
    }
}
