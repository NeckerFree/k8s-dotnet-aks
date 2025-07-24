# k8s-dotnet-aks

Sample project to learn how to deploy a .NET 8 + SQLite API to **Azure Kubernetes Service (AKS)** using Docker, Terraform (with Azure remote backend), Azure Container Registry (ACR), and CI/CD pipelines with GitHub Actions. Includes automated workflows to **create** and **destroy** the infrastructure.

<div align="center">
<img width="512" height="768" alt="Azure K8S Architecture Diagram" src="https://github.com/user-attachments/assets/7ddcd16b-88bf-449d-9fe9-e0463e477283" />
<p align="center">Architecture Diagram</p>
</div>
---

## 📚 Table of Contents

- [📁 Project Structure](#-project-structure)
- [🔐 Requirements](#-requirements)
- [🚀 GitHub Actions Workflows](#-github-actions-workflows)
- [🌐 Automated Deployment Flow](#-automated-deployment-flow)
- [☁️ Terraform Remote Backend](#-terraform-remote-backend)
- [▶️ Run API Locally](#-run-api-locally)
- [🐳 Build Local Docker Image](#-build-local-docker-image)
- [☸️ Useful Kubernetes Commands](#-useful-kubernetes-commands)
- [⚠️ Important Notes](#-important-notes)
- [🧹 Cleanup](#-cleanup)

---

## 📁 Project Structure

```
k8s-dotnet-aks/
├── src/
│   ├── K8sDotnetApi/         # .NET 8 Minimal API + EF Core + SQLite CRUD
│   └── k8s/                  # Kubernetes manifests (PVC, Deployment, Service)
├── infra/                    # Terraform: RG, ACR, AKS
├── .github/workflows/        # Workflows: terraform-create, terraform-destroy, ci, cd
└── K8sDotnetApi.sln          # Visual Studio solution
```

---

## 🔐 Requirements

- Azure subscription with a Service Principal
- GitHub repo with the following **Secrets**:

| Secret              | Description                                                         |
| ------------------- | ------------------------------------------------------------------- |
| `AZURE_CREDENTIALS` | JSON credentials created with `az ad sp create-for-rbac --sdk-auth` |
| `VM_SSH_PUB_KEY`    | Public SSH key for AKS node authentication                          |
| `VM_SSH_KEY`        | (Optional) Private SSH key for manual access to AKS nodes           |

---

## 🚀 GitHub Actions Workflows

| File                    | Purpose                                    | Trigger                                |
| ----------------------- | ------------------------------------------ | -------------------------------------- |
| `terraform-create.yml`  | Provisions infrastructure (AKS, ACR, etc.) | On `push` to `main` or manual dispatch |
| `terraform-destroy.yml` | Destroys all infrastructure                | Manual dispatch from GitHub UI         |
| `ci.yml`                | Builds and tests the .NET API              | On `push` or `pull_request` to `main`  |
| `cd.yml`                | Builds Docker image and deploys to AKS     | On `push` to `main`                    |

---

## 🌐 Automated Deployment Flow

1. **Push to** `main` → triggers *Terraform Create Infra*.
2. When finished, **CI Build & Push** runs:
   - Fetches ACR login server from Terraform output.
   - Builds Docker image of the API.
   - Pushes image to ACR.
3. Then, **CD Deploy to AKS** runs:
   - Gets AKS credentials from Terraform output.
   - Applies PVC, Deployment (with ACR image), and Service manifests.
   - Exposes the app via a public LoadBalancer.
4. To clean up, manually run **Terraform Destroy Infra** to avoid cost.

---

## ☁️ Terraform Remote Backend

Terraform stores state remotely in an Azure Storage Account. The following resources are created:

- Resource Group: `tfstate-rg`
- Storage Account: `tfstatek8sstore`
- Container: `tfstate`

You can also create them manually:

```bash
az group create -n tfstate-rg -l eastus
az storage account create -n tfstatek8sstore -g tfstate-rg -l eastus --sku Standard_LRS
az storage container create -n tfstate --account-name tfstatek8sstore
```

---

## ▶️ Run API Locally

```bash
cd src/K8sDotnetApi
dotnet restore
dotnet run
# Access via: http://localhost:5164/
```

### Test CRUD

```bash
curl http://localhost:5164/movies
curl -X POST http://localhost:5164/movies -H "Content-Type: application/json" -d '{"title":"Matrix","year":1999}'
```
<div align="center">
<img width="1178" height="786" alt="K8S API Get Movies" src="https://github.com/user-attachments/assets/e01df3f4-f642-4856-811a-b88825a68a4f" />
<p align="center">K8S API Get Movies</p>
</div>
---

## 🐳 Build Local Docker Image

```bash
cd src/K8sDotnetApi
docker build -t holamundo-dotnet:local .
docker run -p 8080:8080 holamundo-dotnet:local
```

---

## ☸️ Useful Kubernetes Commands

```bash
# Get AKS credentials locally
az aks get-credentials --name <aks-name> --resource-group <rg-name>

# View Pods
kubectl get pods

# View Services (check External IP)
kubectl get svc

# Apply manifests
kubectl apply -f src/k8s/deployment.yaml
kubectl apply -f src/k8s/service.yaml

# Get logs
kubectl logs <pod-name>

# Test container port is open (inside pod)
kubectl exec -it <pod-name> -- curl localhost:8080/movies

# Delete everything
kubectl delete -f src/k8s/
```

---

## ⚠️ Important Notes

- The ACR name in Terraform is `k8sdotnetacr` (must be globally unique).
- The `deployment.yaml` uses `containerPort: 8080`, so service must map `targetPort: 8080`.
- `cd.yml` replaces the image reference dynamically with the one from ACR.
- SQLite is persisted in `/app/data/movies.db` using a PVC backed by Azure Disk.
- For production or horizontal scaling, switch to an external database like Azure SQL.

---

## 🧹 Cleanup

To avoid unwanted Azure costs, go to GitHub → **Actions** tab → manually trigger:

```
Terraform Destroy Infra
```

---

Enjoy learning AKS and GitHub Actions! 🚀

## 📦 Sample Data

Once deployed, you can test the API with some sample movie records:

```bash
curl -X POST http://<EXTERNAL-IP>/movies -H "Content-Type: application/json" -d '{"title":"Matrix","year":1999}'
curl -X POST http://<EXTERNAL-IP>/movies -H "Content-Type: application/json" -d '{"title":"Inception","year":2010}'
curl -X POST http://<EXTERNAL-IP>/movies -H "Content-Type: application/json" -d '{"title":"Interstellar","year":2014}'
curl -X POST http://<EXTERNAL-IP>/movies -H "Content-Type: application/json" -d '{"title":"The Dark Knight","year":2008}'
curl -X POST http://<EXTERNAL-IP>/movies -H "Content-Type: application/json" -d '{"title":"The Matrix Reloaded","year":2003}'
```

Replace `<EXTERNAL-IP>` with the public IP of your `hola-mundo-dotnet-svc` LoadBalancer.

---
