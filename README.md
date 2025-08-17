# Terraform AWS Modular Infrastructure

This repository contains reusable, scalable Terraform modules for setting up AWS infrastructure components using **DynamoDB**, **Lambda**, and **API Gateway**. Each module is designed with flexibility in mind, allowing you to create multiple resources using input variables and maps.

---

## 📦 Modules Overview

### 1. DynamoDB Module

This module allows creation of multiple DynamoDB tables using a map input.

- Each table definition supports:
  - **Partition Key** (Required)
  - **Sort Key** (Optional)
- If the sort key is not specified, it will not be created.
- Tables are defined using a map variable structure, enabling scalable multi-table deployment.

🔗 [DynamoDB Module Release v0.0.1](https://github.com/VishnuSharma11D00/infrastructure-modules/releases/tag/dynamodb-v0.0.1)

---

### 2. Lambda Module

This module allows creation of multiple AWS Lambda functions using a map.

- Each Lambda definition includes:
  - `lambda_name`
  - `zip_file`
  - `policy_document`
  - `environment_variables`
  - `lambda_layer_arn` (Optional: If not provided, no layer is attached)
- Automatically creates CloudWatch log permissions:
  - `logs:CreateLogStream`
  - `logs:PutLogEvents`
- These are added per Lambda to ensure logging works as expected in Terraform (since AWS console adds them automatically, but Terraform does not).

🔗 [Lambda Module Release v0.1.1](https://github.com/VishnuSharma11D00/infrastructure-modules/releases/tag/lambda-v0.1.1)

---

### 3. API Gateway Module

This module sets up a **single REST API** with multiple resources and methods.

- Each resource includes:
  - `path_part_name`
  - `api_method`
  - `lambda_function_name`
  - `lambda_function_arn`
  - `query_string_parameters` (Optional)
  - `mapping_template_body` (Optional — defaults to `"$input.json('$')"` if not provided)
- **CORS Support**: 
  - Use `cors_allowed_origin` variable to allow specific origins (e.g., `"*"` for all origins)

🔗 [API Gateway Module Release v0.1.0](https://github.com/VishnuSharma11D00/infrastructure-modules/releases/tag/api-gateway-v0.1.0)

---

## 🔖 Release Strategy
All modules are versioned independently for flexibility. You can reference the most recent stable version of each module from the release links above.

However, for deployments involving tightly coupled versions, you may choose to create a meta-release (e.g., v1.0.0) pointing to the latest stable commit/tag across all modules.

---

## 📂 Repository Structure
```
infrastructure-modules/
├── dynamodb/
├── lambda/
└── api-gateway/
```
---

## ✅ Recommendations
- Use separate releases for each module if you expect to iterate on them independently.
- Use a combined release (meta-release) if you're delivering a specific, tested stack version — useful for reproducible infrastructure deployment.

## 📬 Contributions
Feel free to open issues or submit PRs for improvements or new features. This repo is intended to be a base for modular, scalable infrastructure development on AWS using Terraform.


