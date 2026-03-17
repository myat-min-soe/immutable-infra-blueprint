# Demo Infrastructure as Code (Terraform + Atmos)

Pun Hlaing Hospitals (Demo) ရဲ့ AWS infrastructure ကို **Terraform** နဲ့ **[Atmos](https://atmos.tools/)** သုံးပြီး manage လုပ်ထားတဲ့ repository ဖြစ်ပါတယ်။

![Demo Infrastructure Diagram](Demo-infra.png)

---

## � Table of Contents

- [Project Structure](#-project-structure)
- [Architecture Overview](#️-architecture-overview)
- [CI/CD Pipeline (GitLab CI)](#-cicd-pipeline-gitlab-ci)
- [Environments](#-environments)
- [Prerequisites](#️-prerequisites)
- [Usage](#-usage)
- [Backend Configuration](#-backend-configuration)
- [Notes](#-notes)

---

## �📁 Project Structure

```
Demo-iac-terraform/
├── atmos.yaml                      # Atmos configuration
├── components/
│   ├── terraform/
│   │   ├── compute/                # Compute component
│   │   │   ├── main.tf             #   Module wiring (IAM, SG, EC2, ALB, S3, CodeDeploy, ECR)
│   │   │   ├── variables.tf        #   Input variables
│   │   │   └── outputs.tf          #   Outputs (IPs, bucket names, ECR URLs)
│   │   └── database/               # Database component
│   │       ├── main.tf             #   RDS MySQL module wiring
│   │       └── variables.tf        #   DB-specific variables
│   ├── packer/
│   │   └── Demo-ami/                # Packer AMI build component
│   │       ├── build.pkr.hcl       #   Packer build configurations
│   │       ├── install_packages.sh #   Pre-bake installation script
│   │       └── variables.pkr.hcl   #   Packer variables
│   └── ansible/
│       └── provisioning/           # Server configuration component
│           ├── site.yml            #   Main playbook
│           ├── inventory/          #   Per-environment dynamic inventories
│           │   ├── dev.aws_ec2.yml
│           │   ├── uat.aws_ec2.yml
│           │   ├── preprod.aws_ec2.yml
│           │   └── prod.aws_ec2.yml
│           ├── versions/           #   Fetched version reports (git-tracked)
│           └── roles/
│               ├── nginx/          #   Nginx reverse proxy
│               ├── docker/         #   Docker Engine (CE)
│               ├── docker_compose/ #   Docker Compose v2 plugin
│               ├── mysql_client/   #   MySQL client for RDS
│               ├── mysql_server/   #   MySQL Server (dev/uat only)
│               └── version_report/ #   Package version collector
├── modules/
│   ├── cloudwatch/                 # CloudWatch alarms & SNS alerts
│   ├── codedeploy/                 # CodeDeploy app, deployment group, deploy S3 bucket
│   ├── database/                   # RDS MySQL instance, parameter group, subnet group
│   ├── ecr/                        # ECR repositories (frontend & backend)
│   ├── iam/                        # IAM roles, policies, instance profiles, CI/CD user
│   │   └── iam-policies/           #   JSON policy documents
│   ├── instances/                  # EC2 instance
│   ├── loadbalancer/               # ALB listener rules & target groups
│   │   ├── listener_rule/
│   │   └── target_group/
│   ├── security/                   # Application security groups
│   └── storage/                    # S3 storage buckets
├── stacks/
│   └── deploy/
│       ├── packer.yaml             # Standalone Packer stack for base AMI
│       ├── dev.yaml                # Develop environment stack
│       ├── uat.yaml                # UAT environment stack
│       ├── preprod.yaml            # Pre-production environment stack
│       ├── prod.yaml               # Production environment stack
│       ├── db_preprod.yaml         # Pre-production database stack
│       └── db_prod.yaml            # Production database stack
└── README.md
```


---

## 🏗️ Architecture Overview

### Components

| Component  | Type | Description | Modules/Roles Used |
|------------|------|-------------|--------------|
| `Demo-ami`  | Packer | Base Machine Image (AMI) pre-baked with software | `amazon-ebs`, `shell` provisioner |
| `compute`  | Terraform | Application infrastructure (per environment) | `iam`, `security`, `instances`, `loadbalancer`, `storage`, `codedeploy`, `ecr` |
| `database` | Terraform | Database infrastructure (preprod & prod only) | `database` |
| `provisioning` | Ansible | Server configuration & proxy setup (idempotent configuration) | `nginx`, `docker`, `docker_compose`, `mysql_client`, `mysql_server` |

### Modules

| Module | Description | Key Resources |
|--------|-------------|---------------|
| `iam` | Identity & access management | EC2 role, instance profile, CodeDeploy service role, CI/CD user, ECR PowerUser policy |
| `security` | Network security | App security group (allows traffic from ALB) |
| `instances` | Compute | EC2 instance (t3a.small) with Docker |
| `loadbalancer` | Traffic routing | ALB target group, HTTPS listener rules (frontend & backend domains) |
| `storage` | Object storage | S3 bucket for application storage |
| `codedeploy` | Deployment | CodeDeploy app, deployment group, deploy S3 bucket |
| `ecr` | Container registry | ECR repos (`Demo-cms-frontend`, `Demo-cms-backend`), lifecycle policy (30 images) |
| `cloudwatch` | Monitoring | CloudWatch alarms, SNS alert notifications |
| `database` | Database | RDS MySQL instance, parameter group, DB subnet group |

---

## 🔄 CI/CD Pipeline (GitLab CI)

Infrastructure pipeline ကို **Parent-Child Architecture** ဖြင့် တည်ဆောက်ထားပါသည်။ Main `.gitlab-ci.yml` (Parent) ကနေပြီး သက်ဆိုင်ရာ Infrastructure Component (Packer, Terraform, Ansible) များဆီသို့ (Child Pipelines) trigger လုပ်ပေးပါသည်။

### Pipeline Architecture

```
                 [ Parent Pipeline ]
                 .gitlab-ci.yml (Router)
                          │
         ┌────────────────┼────────────────┐
         ▼                ▼                ▼
  [ Child 1 ]      [ Child 2 ]       [ Child 3 ]
 .gitlab/ci/       .gitlab/ci/       .gitlab/ci/
  packer.yml      terraform.yml      ansible.yml
         │                │                │
    Build AMI     Provision Infra   Configure System
    (Packer)       (Terraform)        (Ansible)
```

### Child Pipelines Overview

| Pipeline | Configuration File | Key Stages | Description |
|----------|--------------------|------------|-------------|
| **Router** | `.gitlab-ci.yml` | `trigger-*` | Parent UI မှတဆင့် မည်သည့် component run မည်ကို ရွေးချယ်နိုင်သည် |
| **Packer** | `.gitlab/ci/packer.yml` | `validate`, `build` | Unified Base Image (`Demo-base-image`) အသစ်ထုတ်ပေးသည် |
| **Terraform**| `.gitlab/ci/terraform.yml` | `security`, `plan`, `apply` | `tfsec` ဖြင့် security scan ဖတ်ပြီး Compute/Database ကို deploy လုပ်သည် |
| **Ansible** | `.gitlab/ci/ansible.yml` | `provision`, `verify` | Pre-baked AMI ပေါ်တွင် environment-specific configurations များကို လာရောက်ပုံသွင်းသည် |

### Branch Strategy & Trigger Flow

> **အားလုံး manual:** Pipeline သည် branch ပေါ်တွင် push လုပ်တိုင်း trigger jobs များ ပေါ်လာမည်ဖြစ်ပြီး၊ GitLab UI မှတဆင့် ▶️ button ကိုနှိပ်မှ သက်ဆိုင်ရာ child pipeline များ စတင် run ပါမည်။

```
any branch push → Parent Router ပေါ်လာမည်
                            │
  ┌─────────────────────────┼─────────────────────────┐
  ▼                         ▼                         ▼
▶️ packer-pipeline     ▶️ terraform-pipeline     ▶️ ansible-pipeline
  │                         │                         │
  └─ ▶️ validate:packer     └─ ▶️ tfsec:scan          ├─ ▶️ provision:develop
  └─ ▶️ build:packer        ├─ ▶️ validate:compute    ├─ ▶️ provision:uat
                            ├─ ▶️ plan:<env>:compute  ├─ ▶️ provision:preprod
                            ├─ ▶️ apply:<env>:compute ├─ ▶️ provision:prod
                            │                         │
                            └─ (db_preprod/prod jobs) └─ ▶️ verify:versions
```

> **Plan file safety:** Terraform Apply stage သည် Plan stage ကနေ save ထားသော artifact file ကိုသာ apply လုပ်ပါသည်။ Plan ပြီးနောက် code ပြောင်းသွားပါက apply fail ဖြစ်ပြီး re-plan ထပ်လုပ်ရပါမည်။


### Required GitLab CI/CD Variables

GitLab → **Settings → CI/CD → Variables** မှာ set လုပ်ပါ:

| Variable | Type | Description |
|----------|------|-------------|
| `AWS_ACCESS_KEY_ID` | Variable (masked) | AWS IAM access key |
| `AWS_SECRET_ACCESS_KEY` | Variable (masked) | AWS IAM secret key |

> ⚠️ Production environment အတွက် GitLab **Protected variables** + **Protected branches** သုံးပါ။

### Version Report Artifacts

Provision job တိုင်းက `versions/<env>_versions.json` ကို **CI artifact** (30 days) အဖြစ် save ပါတယ်။ GitLab UI (**Jobs → Artifacts**) ကနေ download လုပ်နိုင်ပါတယ်။

### Tools Auto-installed in Pipeline

| Tool | Version |
|------|---------|
| tfsec | latest |
| Terraform | 1.12 (Docker image) |
| Atmos | 1.209.0 |
| Ansible | 11.5.0 |
| AWS SSM Plugin | latest |
| Collections | `community.aws`, `amazon.aws` |

---

### Application CI/CD Flow (Separate)

Application deployment (Docker build + ECR push + CodeDeploy) သည် infrastructure pipeline နဲ့ သီးသန့် ဖြစ်ပါတယ်:

```
Code Repo
  │
  ▼
Docker Build
  │
  ▼
Push to ECR ──────────────────────┐
  • develop-Demo-cms-frontend      │
  • develop-Demo-cms-backend       │
                                  ▼
                           CodeDeploy triggers
                                  │
                                  ▼
                           EC2 Instance
                             pulls from ECR
                                  │
                                  ▼
                           Docker Compose Run
                             • Frontend Container
                             • Backend Container
```

### ECR Repositories (per environment)

| Environment | Frontend ECR | Backend ECR |
|-------------|-------------|-------------|
| develop | `develop-Demo-cms-frontend` | `develop-Demo-cms-backend` |
| uat | `uat-Demo-cms-frontend` | `uat-Demo-cms-backend` |
| preprod | `preprod-Demo-cms-frontend` | `preprod-Demo-cms-backend` |
| prod | `prod-Demo-cms-frontend` | `prod-Demo-cms-backend` |

### IAM Permissions

| Principal | ECR Permission | Other Permissions |
|-----------|---------------|-------------------|
| EC2 Instance Role | `AmazonEC2ContainerRegistryPowerUser` (pull) | SSM, CloudWatch, S3, CodeDeploy, Parameter Store |
| CI/CD User | `AmazonEC2ContainerRegistryPowerUser` (push/pull) | CodeDeploy, S3 deploy bucket |

---

## 🌐 Environments

| Stack | Stage | Frontend Domain | Backend Domain | Instance Type |
|-------|-------|-----------------|----------------|---------------|
| `dev` | develop | `develop.myatminsoe.com` | `develop-cms.myatminsoe.com` | t3a.small |
| `uat` | uat | `uat.myatminsoe.com` | `uat-cms.myatminsoe.com` | t3a.small |
| `preprod` | preprod | `preprod.myatminsoe.com` | `preprod-cms.myatminsoe.com` | t3a.small |
| `prod` | prod | `www.myatminsoe.com` | `cms.myatminsoe.com` | t3a.small |
| `db_preprod` | preprod | — | — | db.t4g.micro |
| `db_prod` | prod | — | — | db.t4g.micro |

---

## ⚙️ Prerequisites

- [Terraform](https://www.terraform.io/) >= 1.0
- [Atmos](https://atmos.tools/) CLI
- AWS CLI configured with profile: `Demo`
- S3 backend bucket: `Demo-terraform-backend-storage`

---

## 🚀 Usage

### Deployment Order

**"Build Once, Deploy Everywhere"** (Immutable Infrastructure) pattern ကို သုံးထားပါတယ်:

1. **Packer (Demo-ami)**: Software Package များ (Nginx, Docker, MySQL) ပါဝင်သော Base AMI ကို အရင်ဆုံး Build လုပ်ပါ။
2. **Compute**: Environment အလိုက် Terraform plan/apply လုပ်ပါ။ (ECR, EC2, ALB, IAM, SG, S3, CodeDeploy) (မှတ်ချက်: Terraform သည် Packer မှ နောက်ဆုံးထုတ်ထားသော AMI ကို auto-detect လုပ်ပါမည်)
3. **Database**: လိုအပ်ပါက Database stack ကို plan/apply လုပ်ပါ။ (RDS MySQL)
4. **Ansible**: ထို EC2 အပေါ်သို့ environment-specific custom configurations များ (ဥပမာ Nginx site.conf) ကို deploy လုပ်ပါ။

### Packer AMI Build

```bash
# Unified Base Image အသစ်ထုတ်ရန် (Software updates/changes ရှိမှသာ)
atmos packer build Demo-ami -s packer
```

### Compute Stack

```bash
# ── Develop ──
atmos terraform plan compute -s dev
atmos terraform apply compute -s dev

# ── UAT ──
atmos terraform plan compute -s uat
atmos terraform apply compute -s uat

# ── Pre-production ──
atmos terraform plan compute -s preprod
atmos terraform apply compute -s preprod

# ── Production ──
atmos terraform plan compute -s prod
atmos terraform apply compute -s prod
```

### Database Stack

```bash
# ── Pre-production Database ──
atmos terraform plan database -s db_preprod
atmos terraform apply database -s db_preprod

# ── Production Database ──
atmos terraform plan database -s db_prod
atmos terraform apply database -s db_prod
```

### Ansible Configuration

Ansible component သည် EC2 instance ပေါ်တွင် Software install လုပ်ခြင်း မဟုတ်တော့ဘဲ (Packer တွင် ပါဝင်ပြီးဖြစ်သည်) **idempotent** ဖြစ်သော **configuration (e.g. Nginx proxy settings)** များကိုသာ လာရောက် ပုံသွင်းပေးပါသည်။ SSH key မသုံးဘဲ **AWS SSM** မှတဆင့် connect လုပ်ပါသည်။

> 📖 **အပြည့်အစုံ setup guide** အတွက် [`components/ansible/provisioning/README.md`](components/ansible/provisioning/README.md) ကို ကြည့်ပါ။

#### Architecture

```
Local Machine                         AWS (ap-southeast-1)
┌──────────────────┐                  ┌──────────────────────────┐
│  Atmos CLI       │                  │   Private Subnet         │
│  + Ansible       │──── SSM API ────▶│   EC2 Instance           │
│  + AWS CLI       │  (via internet)  │   (SSM Agent pre-built)  │
│  + SSM Plugin    │                  │                          │
└──────────────────┘                  └──────────────────────────┘
```

**SSH key မလို၊ Public IP မလို၊ Bastion host မလို** — SSM Agent + IAM role ပဲ လိုပါတယ်။

#### How It Works

1. **Dynamic Inventory** (`inventory/<env>.aws_ec2.yml`) — `amazon.aws.aws_ec2` plugin သုံးပြီး EC2 tag name (`Demo-<stage>-Instance`) ကနေ auto-discover လုပ်ပါတယ်
2. **SSM Connection** — `ansible_connection: aws_ssm` ဖြင့် SSH အစား SSM ကနေ connect လုပ်ပါတယ်
3. **Playbook** (`site.yml`) — Stack YAML ထဲက flags အပေါ်မူတည်ပြီး roles တွေကို include လုပ်ပါတယ်
4. **Verification & Config** — Role တိုင်းက **"Package ရှိ/မရှိ စစ်ဆေးခြင်း"** (Assert) နှင့် **"Configuration apply လုပ်ခြင်း"** (e.g. `site1.conf`) ကိုသာ ဆောင်ရွက်ပါသည်။ Install မလုပ်ပါ။

#### Roles

| Role | Tag | Description | Key Packages |
|------|-----|-------------|---------------|
| `nginx` | `nginx` | Nginx reverse proxy install + enable | `nginx` |
| `docker` | `docker` | Docker Engine (CE) from official repo | `docker-ce`, `docker-ce-cli`, `containerd.io` |
| `docker_compose` | `docker-compose` | Docker Compose v2 plugin | `docker-compose-plugin` |
| `mysql_client` | `mysql-client` | MySQL client for connecting to RDS | `mysql-client` |
| `mysql_server` | `mysql-server` | MySQL Server (dev/uat only, preprod/prod uses RDS) | `mysql-server` |

Role တိုင်းက handler ပါဝင်ပါတယ် (`Restart Nginx`, `Restart Docker`, `Restart MySQL`) — config change ဖြစ်ရင် auto-restart လုပ်ပေးပါတယ်။

#### Package Flags per Environment

| Flag | dev | uat | preprod | prod |
|------|:---:|:---:|:-------:|:----:|
| `install_nginx` | ✅ | ✅ | ✅ | ✅ |
| `install_docker` | ✅ | ✅ | ✅ | ✅ |
| `install_docker_compose` | ✅ | ✅ | ✅ | ✅ |
| `install_mysql_client` | ✅ | ✅ | ✅ | ✅ |
| `install_mysql_server` | ✅ | ✅ | ❌ | ❌ |

> **Note:** `mysql_server` ကို dev/uat environment မှာပဲ install လုပ်ပါတယ်။ preprod/prod မှာ **AWS RDS** သုံးတဲ့အတွက် client ပဲ လိုပါတယ်။

#### Commands

```bash
# ── Full provisioning (per environment) ──
atmos ansible playbook provisioning -s dev
atmos ansible playbook provisioning -s uat
atmos ansible playbook provisioning -s preprod
atmos ansible playbook provisioning -s prod

# ── Dry-run (production - recommended first) ──
atmos ansible playbook provisioning -s prod -- --check -vvv

# ── Run specific roles only (using tags) ──
atmos ansible playbook provisioning -s dev -- --tags docker
atmos ansible playbook provisioning -s dev -- --tags nginx,mysql-client
atmos ansible playbook provisioning -s dev -- --tags mysql-server

# ── Direct ansible (without Atmos) ──
cd components/ansible/provisioning
AWS_PROFILE=Demo ansible-playbook site.yml -i inventory/dev.aws_ec2.yml

# ── Test inventory discovery ──
AWS_PROFILE=Demo ansible-inventory -i inventory/dev.aws_ec2.yml --list

# ── Test SSM connectivity ──
AWS_PROFILE=Demo ansible all -i inventory/dev.aws_ec2.yml -m ping
```

### Useful Commands

```bash
# Describe a stack to see all resolved variables
atmos describe stacks -s dev

# Validate all stacks
atmos validate stacks
```

### SSM Login (SSH into EC2 Instance)

```bash
# Login to develop instance
aws ssm start-session --target <instance-id> --profile Demo --region ap-southeast-1

# Example:
aws ssm start-session --target i-006d0bcf655eed890 --profile Demo --region ap-southeast-1
```

> **Tip:** Instance ID ကို `atmos ansible playbook provisioning -s develop` run တဲ့အခါ output ထဲမှာ ကြည့်နိုင်ပါတယ်။ သို့မဟုတ် dynamic inventory နဲ့ ရှာနိုင်ပါတယ်:
> ```bash
> cd components/ansible/provisioning
> AWS_PROFILE=Demo ansible-inventory -i inventory/dev.aws_ec2.yml --list | jq '._meta.hostvars | keys'
> ```

---

## 🔧 Backend Configuration

Terraform state ကို S3 မှာ store လုပ်ပြီး **Terraform 1.10+ Native S3 State Locking** စနစ်ဖြင့် S3 ပေါ်တွင် တိုက်ရိုက် state locking ပြုလုပ်ထားပါတယ်။ (DynamoDB အသုံးမပြုတော့ပါ)

| Setting        | Value                           |
|----------------|---------------------------------|
| **S3 Bucket**  | `Demo-terraform-backend-storage` |
| **Region**     | `ap-southeast-1` (Singapore)    |
| **Encryption** | Enabled (AES256)                |
| **Locking**    | Native S3 (`use_lockfile: true`) |

### State File Keys

| Stack | State Key |
|-------|-----------|
| `dev` | `develop.tfstate` |
| `uat` | `uat.tfstate` |
| `preprod` | `preprod.tfstate` |
| `prod` | `prod.tfstate` |
| `db_preprod` | `db_preprod.tfstate` |
| `db_prod` | `db_prod.tfstate` |

---
