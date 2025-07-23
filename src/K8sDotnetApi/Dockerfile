# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
# Crear carpeta para datos SQLite (montada luego via PVC en K8s)
RUN mkdir -p /app/data
EXPOSE 8080
# ASPNETCORE_URLS permite que Kestrel escuche en el puerto 8080 dentro del contenedor
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "K8sDotnetApi.dll"]
