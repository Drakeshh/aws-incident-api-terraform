# 🚨 Incident Log API — Serverless REST API on AWS

![Terraform](https://img.shields.io/badge/Terraform-1.x-7B42BC?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Lambda%20%7C%20API%20Gateway%20%7C%20DynamoDB-FF9900?logo=amazonaws)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=githubactions)
![License](https://img.shields.io/badge/License-MIT-green)

A fully serverless REST API for managing IT incidents — provisioned entirely with Terraform and deployed via GitHub Actions. Built as a real-world portfolio project demonstrating modern cloud architecture patterns.

**Live API:** `https://api.project2.sergipratmerin.com/incidents`

---

## 📐 Architecture

```
Client
  │
  ▼
API Gateway  (REST API + routing)
  │
  ▼
Lambda  (Python 3.12 — business logic)
  │
  ▼
DynamoDB  (NoSQL — incident storage)
  │
IAM Role  (least-privilege execution permissions)
```

### Services used

| Service | Purpose |
|---|---|
| **API Gateway** | Exposes REST endpoints, routes requests to Lambda |
| **Lambda** | Serverless function handling all API logic in Python |
| **DynamoDB** | NoSQL database storing incident records |
| **IAM** | Least-privilege role allowing Lambda to access DynamoDB and CloudWatch |
| **CloudWatch** | Automatic Lambda execution logging |
| **GitHub Actions** | CI/CD pipeline — auto-deploys on every push to `main` |
| **Terraform** | Infrastructure as Code — provisions all AWS resources |

---

## 📁 Project structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml           # GitHub Actions CI/CD pipeline
├── terraform/
│   ├── main.tf                  # All AWS resources
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values (API endpoint, table name)
│   └── providers.tf             # AWS provider + S3 backend
├── src/
│   └── lambda_function.py       # Python Lambda handler
└── README.md
```

---

## 🔌 API endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/incidents` | Create a new incident |
| `GET` | `/incidents` | List all incidents |
| `GET` | `/incidents/{id}` | Get a specific incident |
| `PUT` | `/incidents/{id}` | Update an incident |
| `DELETE` | `/incidents/{id}` | Delete an incident |

### Incident schema

```json
{
    "id":          "uuid (auto-generated)",
    "title":       "Database server down",
    "severity":    "critical | high | medium | low",
    "status":      "open | in-progress | resolved",
    "description": "Primary DB unreachable since 10:00 UTC",
    "created_at":  "2026-03-22T10:00:00Z",
    "updated_at":  "2026-03-22T10:00:00Z"
}
```

### Example requests

**Create an incident:**
```bash
curl -X POST https://api.project2.sergipratmerin.com/incidents \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Database server down",
    "severity": "critical",
    "description": "Primary DB unreachable since 10:00 UTC"
  }'
```

**List all incidents:**
```bash
curl https://api.project2.sergipratmerin.com/incidents
```

**Update an incident:**
```bash
curl -X PUT https://api.project2.sergipratmerin.com/incidents/{id} \
  -H "Content-Type: application/json" \
  -d '{"status": "resolved"}'
```

**Delete an incident:**
```bash
curl -X DELETE https://api.project2.sergipratmerin.com/incidents/{id}
```

---

## 🚀 Getting started

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) v1.0+
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured
- An AWS account with appropriate permissions
- Python 3.12+

### 1. Clone the repository

```bash
git clone https://github.com/Drakeshh/aws-incident-api-terraform.git
cd aws-incident-api-terraform
```

### 2. Deploy infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. Set up GitHub Actions secrets

In your GitHub repository go to **Settings → Secrets and variables → Actions** and add:

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |

### 4. Push to deploy

```bash
git add .
git commit -m "feat: update lambda function"
git push origin main
# GitHub Actions automatically packages and deploys your Lambda
```

---

## ⚙️ CI/CD pipeline

The pipeline runs automatically on every push to `main`:

```
push to main
     │
     ├── 1. Checkout code
     ├── 2. Configure AWS credentials
     ├── 3. Setup Terraform
     ├── 4. terraform init
     ├── 5. terraform plan
     └── 6. terraform apply (packages + deploys Lambda automatically)
```

---

## 🔒 Security highlights

- **Least-privilege IAM** — Lambda execution role only has permissions for DynamoDB read/write and CloudWatch logging
- **No hardcoded credentials** — all secrets stored in GitHub Secrets
- **Private DynamoDB** — table is not publicly accessible, only reachable via Lambda
- **Input validation** — API returns proper 400 errors for missing required fields

### Potential improvements
- Add API Gateway authorizer (API key or Cognito) to restrict access
- Replace `IAMFullAccess` on the deployer user with a custom scoped policy
- Enable DynamoDB point-in-time recovery for data protection
- Add request throttling on API Gateway to prevent abuse

---

## 💡 Key concepts demonstrated

- **Serverless architecture** — no servers to manage, Lambda scales automatically
- **Infrastructure as Code** — every resource defined in Terraform, nothing created manually
- **REST API design** — proper HTTP methods, status codes and error handling
- **NoSQL data modeling** — DynamoDB single-table design with UUID partition key
- **IAM least privilege** — Lambda only has the exact permissions it needs

---

## 📚 Resources

- [AWS Lambda documentation](https://docs.aws.amazon.com/lambda/)
- [API Gateway documentation](https://docs.aws.amazon.com/apigateway/)
- [DynamoDB documentation](https://docs.aws.amazon.com/dynamodb/)
- [Terraform AWS Provider docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 📄 License

MIT — feel free to use this as a starting point for your own projects.

---

