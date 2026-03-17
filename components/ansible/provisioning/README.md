# Ansible Configuration via AWS SSM

ဒီ component က EC2 instance ပေါ်မှာ **Nginx, Docker, Docker Compose, MySQL Client, MySQL Server** တွေ ရှိမရှိ စစ်ဆေးပြီး (Assert) လိုအပ်သော **Configuration အပိုင်း (e.g. Reverse Proxy settings)** များကို idempotent ဖြစ်အောင် ဆောင်ရွက်ပေးပါတယ်။ Software Installation များကို Packer ဖြင့် AMI အသစ်ထုတ်သည့်အခါ ကြိုတင်ထည့်သွင်း (Pre-bake) ထားပြီးဖြစ်ပါသည်။ Instance တွေက private subnet မှာ ရှိပြီး SSH key မသုံးဘဲ **AWS SSM (Systems Manager)** ကနေ connect လုပ်ပါတယ်။

---

## Architecture

```
Your Machine                         AWS (ap-southeast-1)
┌──────────────────┐                  ┌──────────────────────────┐
│  Atmos CLI       │                  │   Private Subnet         │
│  + Ansible       │──── SSM API ────▶│   EC2 Instance           │
│  + AWS CLI       │  (via internet)  │   (SSM Agent pre-built   │
│  + SSM Plugin    │                  │    on Ubuntu AMI)         │
└──────────────────┘                  └──────────────────────────┘
```

**SSH key မလို၊ Public IP မလို၊ Bastion မလို** — SSM Agent + IAM role ပဲ လိုပါတယ်။

---

## Directory Structure

```
components/ansible/provisioning/
├── site.yml                        # Main playbook (controls all roles)
├── inventory/
│   ├── dev.aws_ec2.yml             # Dynamic inventory – develop
│   ├── uat.aws_ec2.yml             # Dynamic inventory – UAT
│   ├── preprod.aws_ec2.yml         # Dynamic inventory – pre-production
│   └── prod.aws_ec2.yml            # Dynamic inventory – production
├── versions/                       # Fetched version reports (git-tracked)
│   ├── develop_versions.json
│   ├── uat_versions.json
│   ├── preprod_versions.json
│   └── prod_versions.json
└── roles/
    ├── nginx/                      # Nginx reverse proxy
    │   ├── tasks/main.yml
    │   └── handlers/main.yml
    ├── docker/                     # Docker Engine (CE)
    │   ├── tasks/main.yml
    │   └── handlers/main.yml
    ├── docker_compose/             # Docker Compose v2 plugin
    │   └── tasks/main.yml
    ├── mysql_client/               # MySQL client (for RDS connectivity)
    │   └── tasks/main.yml
    ├── mysql_server/               # MySQL Server (dev/uat only)
    │   ├── tasks/main.yml
    │   └── handlers/main.yml
    └── version_report/             # Package version collector
        └── tasks/main.yml
```

---

## How It Works

### Playbook (`site.yml`)

Playbook က stack YAML (e.g. `stacks/deploy/dev.yaml`) ထဲက boolean flags အပေါ်မူတည်ပြီး role တစ်ခုစီကို conditionally include လုပ်ပါတယ်:

```yaml
roles:
  - role: nginx
    tags: [nginx]
    when: install_nginx | default(false) | bool

  - role: docker
    tags: [docker]
    when: install_docker | default(false) | bool

  - role: docker_compose
    tags: [docker-compose]
    when: install_docker_compose | default(false) | bool

  - role: mysql_client
    tags: [mysql-client]
    when: install_mysql_client | default(false) | bool

  - role: mysql_server
    tags: [mysql-server]
    when: install_mysql_server | default(false) | bool

  - role: version_report        # Always runs — collects installed versions
    tags: [version-report]
```

### Dynamic Inventory

`amazon.aws.aws_ec2` plugin သုံးပြီး EC2 tag ပေါ် based ပြီး instance တွေကို auto-discover လုပ်ပါတယ်။ Hardcoded IP/Instance ID မလိုပါ:

```yaml
# inventory/dev.aws_ec2.yml
plugin: amazon.aws.aws_ec2
regions:
  - ap-southeast-1
filters:
  tag:Name: "Demo-develop-Instance"
  instance-state-name: running
hostnames:
  - instance-id
compose:
  ansible_connection: "'aws_ssm'"
  ansible_aws_ssm_region: "'ap-southeast-1'"
  ansible_aws_ssm_bucket_name: "'Demo-develop-storage-bucket'"
```

### Idempotent Roles

Role တိုင်းက **check → assert → configure** pattern ကို follow လုပ်ပါတယ်:

1. **Check** — software ရှိပြီးသား လား check လုပ်ပါတယ် (e.g. `dpkg-query`, `docker --version`)
2. **Assert** — မရှိပါက "Invalid AMI/Missing Package" အဖြစ် ယူဆပြီး ချက်ချင်း အလုပ်ရပ် (fail) ပါမည်။ အကြောင်းမှာ AMI ကို Packer ဖြင့် ကြိုတင် build ထားရမည်ဖြစ်သောကြောင့်ပါ။
3. **Configure** — စစ်ဆေးအောင်မြင်ပါက သက်ဆိုင်ရာ Environment အတွက် Nginx/MySQL config ဖိုင်များကို လာရောက် deploy/template လုပ်ပေးပါသည်။

ဒါကြောင့် playbook ကို ဘယ်နှစ်ကြိမ် run run ရလဒ်အတူတူပဲ ဖြစ်ပါတယ် (idempotent)။

---

## Roles Detail

### `nginx` — Nginx Reverse Proxy

| Item | Value |
|------|-------|
| **Tag** | `nginx` |
| **Package** | `nginx` |
| **Service** | `nginx` (systemd, enabled on boot) |
| **Handler** | `Restart Nginx` |

Tasks: `dpkg-query` ဖြင့် Nginx ရှိမရှိ check → မရှိပါက Ansible playbook fail → ရှိပါက default Nginx config ဖျက်ခြင်း → Environment-specific reverse proxy တည်ဆောက်ခြင်း (`/etc/nginx/conf.d/site1.conf`) → `systemctl is-active` verify

---

### `docker` — Docker Engine (CE)

| Item | Value |
|------|-------|
| **Tag** | `docker` |
| **Packages** | `docker-ce`, `docker-ce-cli`, `containerd.io` |
| **Service** | `docker` (systemd, enabled on boot) |
| **Handler** | `Restart Docker` |

Tasks:
1. `dpkg-query` ဖြင့် check နှင့် assert ပြုလုပ်ခြင်း
2. `ubuntu` user ကို `docker` group ထဲ add
3. systemd enable/start → `docker --version` verify

---

### `docker_compose` — Docker Compose v2 Plugin

| Item | Value |
|------|-------|
| **Tag** | `docker-compose` |
| **Package** | `docker-compose-plugin` |

Tasks: `docker compose version` နဲ့ check & assert လုပ်ခြင်း → verify

> **Note:** Docker Compose v2 ကို Docker CLI plugin အဖြစ် install လုပ်တာဖြစ်ပြီး `docker compose` command (space, not hyphen) နဲ့ run ပါတယ်။

---

### `mysql_client` — MySQL Client

| Item | Value |
|------|-------|
| **Tag** | `mysql-client` |
| **Package** | `mysql-client` |

Tasks: `dpkg-query` ဖြင့် check & assert ပြုလုပ်ခြင်း → verify

> EC2 instance ကနေ **AWS RDS** ကို connect လုပ်ဖို့ client ပဲ လိုပါတယ်။

---

### `mysql_server` — MySQL Server

| Item | Value |
|------|-------|
| **Tag** | `mysql-server` |
| **Package** | `mysql-server` |
| **Service** | `mysql` (systemd, enabled on boot) |
| **Handler** | `Restart MySQL` |

Tasks: `dpkg-query` ဖြင့် check & assert ပြုလုပ်ခြင်း → environment-specific my.cnf template လိုအပ်ပါက ဖြည့်တင်းခြင်း → systemd enable/start → verify

> ⚠️ **dev/uat environment မှာပဲ** install လုပ်ပါတယ်။ preprod/prod မှာ **AWS RDS** သုံးတဲ့အတွက် `install_mysql_server: false` ဖြစ်ပါတယ်။

---

## Package Flags per Environment

Stack YAML (`stacks/deploy/<env>.yaml`) ထဲမှာ ဒီ flags တွေကို set လုပ်ထားပါတယ်:

| Flag | dev | uat | preprod | prod |
|------|:---:|:---:|:-------:|:----:|
| `install_nginx` | ✅ | ✅ | ✅ | ✅ |
| `install_docker` | ✅ | ✅ | ✅ | ✅ |
| `install_docker_compose` | ✅ | ✅ | ✅ | ✅ |
| `install_mysql_client` | ✅ | ✅ | ✅ | ✅ |
| `install_mysql_server` | ✅ | ✅ | ❌ | ❌ |

Stack YAML example (`stacks/deploy/dev.yaml`):

```yaml
components:
  ansible:
    provisioning:
      vars:
        env_name: "develop"
        install_nginx: true
        install_docker: true
        install_docker_compose: true
        install_mysql_client: true
        install_mysql_server: true
      env:
        ANSIBLE_HOST_KEY_CHECKING: "false"
        ANSIBLE_FORCE_COLOR: "true"
        AWS_PROFILE: Demo
      settings:
        ansible:
          playbook: site.yml
          inventory: inventory/dev.aws_ec2.yml
```

---

## Prerequisites

### 1. AWS CLI (configured with `Demo` profile)

```bash
# Verify AWS CLI is configured
aws sts get-caller-identity --profile Demo
```

### 2. Install AWS Session Manager Plugin

SSM connection အတွက် Session Manager plugin ကို install လုပ်ပါ:

**Ubuntu/Debian:**
```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
rm session-manager-plugin.deb
```

**macOS:**
```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_arm64/session-manager-plugin.pkg" -o "session-manager-plugin.pkg"
sudo installer -pkg session-manager-plugin.pkg -target /
rm session-manager-plugin.pkg
```

**Windows:**
- Download: https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe
- Run the installer

**Verify:**
```bash
session-manager-plugin --version
```

### 3. Install Ansible + Required Collections

```bash
# Install Ansible (if not already installed)
pip install ansible boto3 botocore

# Install required Ansible collections
ansible-galaxy collection install community.aws
ansible-galaxy collection install amazon.aws
```

**Verify:**
```bash
ansible --version
ansible-galaxy collection list | grep -E "community.aws|amazon.aws"
```

### 4. Verify SSM Agent on EC2

SSM Agent သည် Ubuntu AMIs မှာ pre-installed ဖြစ်ပါတယ်။ Verify လုပ်ရန်:

```bash
aws ssm describe-instance-information \
  --profile Demo \
  --region ap-southeast-1 \
  --filters "Key=tag:Name,Values=Demo-develop-Instance" \
  --query "InstanceInformationList[*].[InstanceId,PingStatus,PlatformName]" \
  --output table
```

Expected: `PingStatus` = **Online**

> ⚠️ `PingStatus` က `ConnectionLost` ဖြစ်ရင် IAM instance profile မှာ SSM permissions ပါမပါ check လုပ်ပါ။

---

## Usage

### Via Atmos (Recommended)

```bash
# ── Full provisioning (per environment) ──
atmos ansible playbook provisioning -s develop
atmos ansible playbook provisioning -s uat
atmos ansible playbook provisioning -s preprod
atmos ansible playbook provisioning -s prod

# ── Dry-run (recommended for production) ──
atmos ansible playbook provisioning -s prod -- --check -vvv

# ── Run specific roles only (using tags) ──
atmos ansible playbook provisioning -s develop -- --tags docker
atmos ansible playbook provisioning -s develop -- --tags nginx
atmos ansible playbook provisioning -s develop -- --tags docker-compose
atmos ansible playbook provisioning -s develop -- --tags mysql-client
atmos ansible playbook provisioning -s develop -- --tags mysql-server

# ── Multiple tags ──
atmos ansible playbook provisioning -s develop -- --tags nginx,docker,mysql-client
```

### Direct Ansible (Without Atmos)

```bash
cd components/ansible/provisioning

# Full provisioning
AWS_PROFILE=Demo ansible-playbook site.yml -i inventory/dev.aws_ec2.yml

# Dry-run
AWS_PROFILE=Demo ansible-playbook site.yml -i inventory/dev.aws_ec2.yml --check -vvv

# Specific tags
AWS_PROFILE=Demo ansible-playbook site.yml -i inventory/dev.aws_ec2.yml --tags docker
```

### Testing & Debugging

```bash
cd components/ansible/provisioning

# 1. Test dynamic inventory discovers your instances
AWS_PROFILE=Demo ansible-inventory -i inventory/dev.aws_ec2.yml --list

# 2. Test SSM connectivity with ping
AWS_PROFILE=Demo ansible all -i inventory/dev.aws_ec2.yml -m ping

# 3. Run ad-hoc commands on remote instance
AWS_PROFILE=Demo ansible all -i inventory/dev.aws_ec2.yml -m shell -a "docker --version"
AWS_PROFILE=Demo ansible all -i inventory/dev.aws_ec2.yml -m shell -a "nginx -v"
AWS_PROFILE=Demo ansible all -i inventory/dev.aws_ec2.yml -m shell -a "mysql --version"
```

### SSM Login (SSH into EC2 Instance)

SSM ကနေ instance ထဲ login ဝင်ပြီး manually check လုပ်ချင်ရင်:

```bash
# Login to instance (replace <instance-id> with actual ID)
aws ssm start-session --target <instance-id> --profile Demo --region ap-southeast-1

# Example:
aws ssm start-session --target i-006d0bcf655eed890 --profile Demo --region ap-southeast-1
```

Instance ID ကို dynamic inventory ကနေ ရှာနိုင်ပါတယ်:

```bash
# List discovered instance IDs
AWS_PROFILE=Demo ansible-inventory -i inventory/dev.aws_ec2.yml --list | jq '._meta.hostvars | keys'
```

Login ဝင်ပြီးရင် package versions ကို verify လုပ်နိုင်ပါတယ်:

```bash
# Check installed versions on instance
cat /opt/Demo/versions.json
nginx -v
docker --version
docker compose version
mysql --version
systemctl status nginx docker mysql
```

---

## Version Report

Playbook run ပြီးတိုင်း `version_report` role က install ထားတဲ့ package version တွေကို collect လုပ်ပြီး:

1. **Remote server** မှာ `/opt/Demo/versions.json` အဖြစ် save လုပ်ပါတယ်
2. **Local** မှာ `versions/<env>_versions.json` အဖြစ် fetch လုပ်ပါတယ် (git-tracked)

### Example Output

```json
{
  "environment": "develop",
  "instance_id": "i-06d9749685ce780fe",
  "timestamp": "2026-03-11T14:00:00Z",
  "packages": {
    "nginx": "1.24.0-2ubuntu7.1",
    "docker-ce": "5:27.5.1-1~ubuntu.24.04~noble",
    "docker-ce-cli": "5:27.5.1-1~ubuntu.24.04~noble",
    "containerd.io": "1.7.27-1",
    "docker-compose-plugin": "2.32.4-1~ubuntu.24.04~noble",
    "mysql-client": "8.0.41-0ubuntu0.24.04.1",
    "mysql-server": "8.0.41-0ubuntu0.24.04.1"
  }
}
```

### Comparing Environments

```bash
# Compare dev vs uat versions
diff versions/develop_versions.json versions/uat_versions.json

# Compare all environments (packages only)
jq '.packages' versions/*_versions.json

# Check specific package across environments
for f in versions/*_versions.json; do
  echo "$(jq -r '.environment' $f): $(jq -r '.packages["docker-ce"]' $f)"
done
```

> **Tip:** Version files များကို git commit လုပ်ထားရင် `git diff` နဲ့ version changes history ကို track လုပ်နိုင်ပါတယ်။

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `session-manager-plugin: command not found` | Install SSM plugin (see Prerequisites Step 2) |
| Dynamic inventory returns empty `{}` | Check EC2 tag name matches exactly: `Demo-<stage>-Instance` |
| `PingStatus: ConnectionLost` | SSM Agent not running or IAM role missing SSM permissions |
| `An error occurred (TargetNotConnected)` | Instance is stopped or SSM Agent crashed — check instance state |
| `botocore.exceptions.NoCredentialsError` | Run with `AWS_PROFILE=Demo` or configure default AWS credentials |
| `ERROR! Unexpected Exception: No module named 'boto3'` | Run `pip install boto3 botocore` |
| `collection community.aws not found` | Run `ansible-galaxy collection install community.aws amazon.aws` |
| Task fails with `[Errno 2] No such file or directory` | Binary not on PATH — role uses `dpkg-query` or `command` check with `ignore_errors: true` |

---

## Prerequisites Checklist

```
[ ] AWS CLI installed and configured (profile: Demo)
[ ] AWS Session Manager Plugin installed
[ ] Python packages: ansible, boto3, botocore
[ ] Ansible collections: community.aws, amazon.aws
[ ] EC2 instance SSM Agent online (PingStatus: Online)
[ ] Stack YAML configured with correct install flags
```
