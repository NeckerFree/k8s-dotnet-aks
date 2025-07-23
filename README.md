# k8s-dotnet-aks

Proyecto de ejemplo para aprender Kubernetes en Azure (AKS) con una API .NET 8 + SQLite, Docker, Terraform (backend remoto en Azure Storage), Azure Container Registry (ACR) y CI/CD con GitHub Actions. Incluye workflows para **crear** y **destruir** la infraestructura automáticamente.

---

## Contenido

```
k8s-dotnet-aks/
├── src/
│   ├── K8sDotnetApi/         # API .NET 8 Minimal + EF Core + SQLite CRUD
│   └── k8s/                  # Manifiestos Kubernetes (PVC, Deployment, Service)
├── infra/                    # Terraform: RG, ACR, AKS
├── .github/workflows/        # Workflows: terraform-create, terraform-destroy, ci, cd
└── K8sDotnetApi.sln          # Solución Visual Studio
```

---

## Requisitos

- Azure Subscription con Service Principal (usar secrets ARM_*).
- GitHub repo con estos **Secrets**:
  - `ARM_CLIENT_ID`
  - `ARM_CLIENT_SECRET`
  - `ARM_SUBSCRIPTION_ID`
  - `ARM_TENANT_ID`
  - `VM_SSH_PUB_KEY` (clave pública para nodos AKS)
  - (Opcional) `VM_SSH_KEY` si quieres conectarte a nodos; no requerido por los workflows.

---

## Flujo de Trabajo Automatizado

1. **Push a `main`** → corre *Terraform Create Infra* (crea RG, ACR, AKS).
2. Cuando finaliza, corre **CI Build & Push**:
   - Obtiene nombre del ACR desde Terraform outputs.
   - Construye imagen Docker de la API.
   - Publica imagen en ACR.
3. Cuando finaliza, corre **CD Deploy to AKS**:
   - Obtiene credenciales AKS desde Terraform outputs.
   - Aplica pvc.yaml, deployment.yaml (parcheando el nombre de imagen), service.yaml.
   - La app queda expuesta con un LoadBalancer público.
4. Cuando quieras limpiar costos, ejecuta manualmente **Terraform Destroy Infra** (workflow_dispatch).

---

## Inicialización del Backend de Terraform

Los workflows crean (idempotente) los recursos del backend remoto si no existen:
- Resource Group: `tfstate-rg`
- Storage Account: `tfstatek8sstore`
- Container: `tfstate`

Si prefieres hacerlo manualmente:

```bash
az group create -n tfstate-rg -l eastus
az storage account create -n tfstatek8sstore -g tfstate-rg -l eastus --sku Standard_LRS
az storage container create -n tfstate --account-name tfstatek8sstore
```

---

## Ejecutar Localmente (opcional)

```bash
cd src/K8sDotnetApi
dotnet restore
dotnet run
# http://localhost:5164/
```

### Probar CRUD

```bash
curl http://localhost:5164/movies
curl -X POST http://localhost:5164/movies -H "Content-Type: application/json" -d '{"title":"Matrix","year":1999}'
```

---

## Construir Imagen Docker Local

```bash
cd src/K8sDotnetApi
docker build -t holamundo-dotnet:local .
docker run -p 8080:8080 holamundo-dotnet:local
```

---

## Notas Importantes

- El nombre del ACR en Terraform está configurado como `k8sdotnetacr` (global único en Azure; cámbialo si ya existe).
- El `deployment.yaml` usa marcador `<ACR_LOGIN_SERVER>` que el workflow CD sustituye dinámicamente antes de aplicar.
- SQLite se almacena en `/app/data/movies.db`, montado desde un PVC (Azure Disk vía StorageClass default). No escalar a múltiples réplicas sin mover a una BD externa (Azure SQL, PostgreSQL, etc.).

---

## Limpieza

Para destruir la infra (y evitar costos): usa el workflow **Terraform Destroy Infra** desde la pestaña *Actions* en GitHub.

---

¡Disfruta aprendiendo AKS! 💪
