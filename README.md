# DevOps Project - Strapi on AWS ECS with Terraform & GitHub Actions

This Project deploys a **Strapi CMS application** to **AWS ECS Fargate** using **Terraform** for infrastructure provisioning and **GitHub Actions** for CI/CD automation. It also integrates **CloudWatch** for monitoring and logging.

---
## Project Structure

```
.
├── my-strapi-project
    ├── Dockerfile
├──.github
      ├── workflows
            ├── strapi-deploy.yml
            ├── cd.yml
├── main.tf
├── variables.tf
├── terraform.tfvars
├── outputs.tf
```

---

## Infrastructure Overview (Terraform)

### Files

#### `main.tf`
Defines all core AWS resources:
- **VPC, Subnets, Internet Gateway**
- **Security Groups** for ALB and ECS
- **ALB, Target Group, Listener** (Port 80)
- **ECS Cluster, Task Definition, Service**
- **CloudWatch Log Group**: `/ecs/strapi`
- **CloudWatch Alarms** for:
  - CPU and Memory utilization
  - ECS Task Count
- **CloudWatch Dashboard** for visual monitoring

#### `variables.tf`
Holds configurable parameters such as:
- `container_name`
- `container_port` (defaults to 1337)
- `task_role_arn`, `execution_role_arn`
- `alb_name`, `cluster_name`, `task_name`, `service_name`
- (optional) `image` – but **now omitted in favor of dynamic image deployment**

#### `outputs.tf`
Prints:
- ECS Service Name
- Task Definition ARN
- ALB Public DNS (`strapi_url`)

---

## CI/CD Overview (GitHub Actions)

### CI Pipeline: `.github/workflows/strapi-deploy.yml`

Triggered on `push` to `main`. It:
1. **Builds** the Docker image from `./my-strapi-project`
2. **Tags** it as `latest`
3. **Pushes** it to ECR: `${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.us-east-2.amazonaws.com/rohana-strapi-repo:latest`

Uses:
- `aws-actions/configure-aws-credentials`
- `aws-actions/amazon-ecr-login`

### CD Pipeline: `.github/workflows/cd.yml`

Manually triggered workflow that:
1. **Runs `terraform apply`** to update the ECS Task Definition with the latest image
2. Uses:
   - `hashicorp/setup-terraform`
   - GitHub secrets for AWS credentials
3. Assumes `terraform.tfstate` is remotely stored (S3 + DynamoDB backend if configured)

---

## Monitoring (CloudWatch)

Provisioned via Terraform:
- **Log Group**: `/ecs/strapi`
- **Metrics**:
  - CPUUtilization
  - MemoryUtilization
  - NetworkIn / NetworkOut
- **Alarms**:
  - High CPU or Memory (e.g., >70%)
- **Dashboard**: Graphs for task-level performance

---

## Deployment Steps

1. Push code to `main` → triggers CI (build + push image)
2. Manually trigger `cd.yml` workflow → updates ECS to use latest image
3. Access Strapi Admin at: `http://<alb-dns>:1337`

---

## Notes

- The ECS Task uses `awslogs` driver
- ALB forwards port 80 to container port 1337
- All infrastructure is managed via Terraform — no manual AWS console setup
- Uses a **custom VPC** (defined in `vpc.tf`)

---
## Author

**Rohana Upadhyaya**    
Location: Bengaluru, Karnataka
