# k8s-dotnet-aks

Proyecto de ejemplo para aprender Kubernetes en Azure (AKS) con una API .NET 8 + SQLite, Docker, Terraform (backend remoto en Azure Storage), Azure Container Registry (ACR) y CI/CD con GitHub Actions. Incluye workflows para **crear** y **destruir** la infraestructura automáticamente.

---

## 🧱 Estructura del Proyecto

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

## 🔐 Requisitos

- Azure Subscription con Service Principal
- GitHub repo con estos **Secrets** configurados:

| Secret              | Descripción                                                     |
|---------------------|------------------------------------------------------------------|
| `AZURE_CREDENTIALS` | Credenciales JSON generadas con `az ad sp create-for-rbac --sdk-auth` |
| `VM_SSH_PUB_KEY`    | Clave pública SSH para nodos AKS                                |
| `VM_SSH_KEY`        | (Opcional) Clave privada SSH para acceso manual a nodos         |

---

## 🚀 Workflows de GitHub Actions

| Archivo                   | Propósito                               | Cuándo se ejecuta                           |
|---------------------------|------------------------------------------|----------------------------------------------|
| `terraform-create.yml`    | Provisiona la infraestructura (AKS, ACR) | `push` a `main` o manual desde GitHub        |
| `terraform-destroy.yml`   | Elimina toda la infraestructura          | Manual desde la UI de GitHub Actions         |
| `ci.yml`                  | Compila y testea la API (.NET)           | `push` o `pull_request` hacia `main`         |
| `cd.yml`                  | Construye imagen Docker y despliega a AKS| `push` a `main`                              |

---

## 🌐 Flujo de Trabajo Automatizado

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

## ☁️ Backend Remoto de Terraform

Los workflows crean automáticamente (idempotente) estos recursos para almacenar el estado remoto:

- Resource Group: `tfstate-rg`
- Storage Account: `tfstatek8sstore`
- Container: `tfstate`

O puedes crearlos manualmente con:

```bash
az group create -n tfstate-rg -l eastus
az storage account create -n tfstatek8sstore -g tfstate-rg -l eastus --sku Standard_LRS
az storage container create -n tfstate --account-name tfstatek8sstore
```

---

## ▶️ Ejecutar API Localmente

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

## 🐳 Construir Imagen Docker Local

```bash
cd src/K8sDotnetApi
docker build -t holamundo-dotnet:local .
docker run -p 8080:8080 holamundo-dotnet:local
```

---

## ⚠️ Notas Importantes

- El nombre del ACR en Terraform está configurado como `k8sdotnetacr` (debe ser único globalmente).
- El `deployment.yaml` usa el marcador `<ACR_LOGIN_SERVER>` que es sustituido por el workflow `cd.yml` automáticamente.
- SQLite se monta en `/app/data/movies.db` mediante un PVC con Azure Disk. Para escalar horizontalmente, deberías usar una base de datos externa como Azure SQL.

---

## 🧹 Limpieza

Para evitar costos innecesarios, ejecuta el workflow manual:

```
Terraform Destroy Infra
```

Desde la pestaña **Actions** en GitHub.

---

¡Disfruta aprendiendo AKS! 💪