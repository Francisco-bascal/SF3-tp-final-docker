using MediClock.Web.Datos;
using MediClock.Web.Servicios;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews();
builder.Services.AddDbContext<MediClockDbContext>(opciones =>
    opciones.UseNpgsql(builder.Configuration.GetConnectionString("MediClock")));
builder.Services.AddScoped<IEventoService, EventoService>();

var app = builder.Build();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
