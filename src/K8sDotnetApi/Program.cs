using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Configuración de EF Core + SQLite en ruta persistente montada por PVC
builder.Services.AddDbContext<AppDbContext>(options =>
 options.UseSqlite("Data Source=/app/data/movies.db")); //Linux

// var dbPath = Path.Combine("app", "data", "movies.db");
// Directory.CreateDirectory(Path.GetDirectoryName(dbPath));
// builder.Services.AddDbContext<AppDbContext>(options =>
//  options.UseSqlite($"Data Source={dbPath}")); //Windows
var app = builder.Build();

// Ejecutar migraciones en arranque (solo DEMO; no recomendado prod)
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
}

app.MapGet("/", () => "¡Hola Mundo desde .NET 8 en Kubernetes con SQLite!");

app.MapGet("/movies", async (AppDbContext db) => await db.Movies.ToListAsync());

app.MapGet("/movies/{id}", async (int id, AppDbContext db) =>
    await db.Movies.FindAsync(id) is Movie m ? Results.Ok(m) : Results.NotFound());

app.MapPost("/movies", async (Movie movie, AppDbContext db) =>
{
    db.Movies.Add(movie);
    await db.SaveChangesAsync();
    return Results.Created($"/movies/{movie.Id}", movie);
});

app.MapPut("/movies/{id}", async (int id, Movie movie, AppDbContext db) =>
{
    var m = await db.Movies.FindAsync(id);
    if (m == null) return Results.NotFound();
    m.Title = movie.Title;
    m.Year = movie.Year;
    await db.SaveChangesAsync();
    return Results.Ok(m);
});

app.MapDelete("/movies/{id}", async (int id, AppDbContext db) =>
{
    var m = await db.Movies.FindAsync(id);
    if (m == null) return Results.NotFound();
    db.Movies.Remove(m);
    await db.SaveChangesAsync();
    return Results.NoContent();
});

app.Run();

public class Movie
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public int Year { get; set; }
}

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
    public DbSet<Movie> Movies => Set<Movie>();
}
