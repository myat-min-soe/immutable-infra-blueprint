# Modern Infrastructure: Atmos, Packer, Terraform, နှင့် Ansible ကိုအသုံးပြု၍ "Immutable Infrastructure" တည်ဆောက်ခြင်း (Deep Dive)

လက်ရှိ ခေတ်သစ် Software Ecosystem တွေမှာ CI/CD pipeline ကနေတစ်ဆင့် Infrastructure ကို Code အနေနဲ့ (Infrastructure as Code - IaC) Manage လုပ်တာက Standard တစ်ခုဖြစ်လာပါပြီ။ ဒါပေမယ့် Technical အားဖြင့် ဒီလို Automation လုပ်တဲ့အခါ "**ဘယ် Tool ကို ဘယ်အချိန်မှာ သုံးမလဲ (Separation of Concerns)**" ဆိုတာက အလွန်အရေးကြီးပါတယ်။

ဒီ Article မှာတော့ **Live Server တွေပေါ်မှာ Script တွေ တိုက်ရိုက် run တဲ့ ရှေးရိုးရာ (Mutable) စနစ်ကနေ၊ "Build Once, Deploy Everywhere"** လို့ခေါ်တဲ့ **"Immutable Infrastructure"** ပုံစံကို Atmos, Packer, Terraform, Ansible နှင့် GitLab CI တို့ ပေါင်းစပ်ပြီး ဘယ်လို Low-Level အလုပ်လုပ်သွားလဲဆိုတာကို Architect တစ်ယောက်ရဲ့ အမြင်ကနေ Deep Dive ရှင်းပြပေးသွားမှာပါ။

---

## 🧐 ဘာကြောင့် ဒီ Architecture ကို ပြောင်းလဲအသုံးပြုသင့်တာလဲ? (Why Should We Use This?)

ရိုးရိုး Terraform နဲ့ Ansible သုံးနေတာပဲ၊ ဘာလို့ Packer တွေ၊ Atmos တွေ၊ Parent-Child CI တွေပါ ထပ်ပေါင်းထည့်ရတာလဲ? အကြောင်းရင်းကတော့ ရေရှည် (Scale) လုပ်တဲ့အခါ ကြုံရမယ့် ပြဿနာတွေကို ကြိုတင်ဖြေရှင်းထားလို့ပါပဲ။

1.  **Snowflake Servers ပြဿနာကို အမြစ်ပြတ်ရှင်းလင်းခြင်း**: Server တွေကို လူကိုယ်တိုင် ဝင်ပြင်ခြင်း၊ Runtime မှာ Script တွေ Error တက်ခြင်းကြောင့် ဖြစ်ပေါ်လာတဲ့ "ငါ့စက်မှာတော့ အလုပ်လုပ်တယ်" (Configuration Drift) ပြဿနာကို ရာခိုင်နှုန်းပြည့် ကာကွယ်ပေးပါတယ်။
2.  **Ultra-Fast Auto-Scaling**: Traffic တက်လာလို့ Server အသစ်တွေ အရေးပေါ်ပွားတဲ့အခါ (Auto-scaling) မှာ Software တွေလိုက်သွင်းနေရင် မိနစ်ချီ ကြာပါတယ်။ Golden Image (AMI) ကြိုထုတ်ထားတဲ့အတွက် စက္ကန့်ပိုင်းအတွင်း Server တက်လာပြီး ချက်ချင်း အလုပ်လုပ်နိုင်ပါတယ်။
3.  **DRY (Don't Repeat Yourself) Codebase**: Environment (Dev, UAT, Prod) တစ်ခုတိုးလာတိုင်း Terraform Code တွေ ခဏခဏ Copy-Paste လုပ်စရာမလိုတော့ဘဲ Atmos ရဲ့ Wrapper စနစ်ကြောင့် YAML ဖိုင်လေးတစ်ခုတိုးရုံနဲ့ ပြီးစီးပါတယ်။
4.  **Zero-Trust Security Model**: Bastion Hosts တွေ၊ SSH Public Key တွေ၊ Port 22 တွေကို လုံးဝမသုံးတော့ဘဲ AWS Systems Manager (SSM) ဖြင့် HTTPS API ကနေ ချိတ်ဆက်တဲ့အတွက် လုံခြုံရေးအမြင့်ဆုံး စနစ်ကို ရရှိပါတယ်။

---

## 📐 The Architecture Diagram

System ကြီးတစ်ခုလုံး ဘယ်လိုချိတ်ဆက်အလုပ်လုပ်လဲဆိုတာကို အောက်ပါ Hand-drawn Design Diagram မှာ ကြည့်ရှုနိုင်ပါတယ်:

```text
+-----------------------------------------------------------------------------------+
|                            GitLab CI/CD Orchestration                             |
|                                                                                   |
|  [ Parent Pipeline ] ---> (Trigger) ---> [ Packer Pipeline ] (Bake AMI)           |
|          |                                                                        |
|          +--------------> (Approve) ---> [ Terraform Pipeline ] (Build AWS)       |
|          |                                                                        |
|          +--------------> (Approve) ---> [ Ansible Pipeline ] (Config Server)     |
+-----------------------------------------------------------------------------------+
                                 | (Deploys & Configures)
                                 v
+-----------------------------------------------------------------------------------+
|                                 AWS Cloud Environment                             |
|                                                                                   |
|  +-------------------------------- AWS VPC Network ----------------------------+  |
|  |                                                                             |  |
|  |  (Internet) --> [ Internet Gateway ] -----> [ Application Load Balancer ]   |  |
|  |                                                           |                 |  |
|  |  +------------------ Private Subnets (Multi-AZ) ----------v--------------+  |  |
|  |  |                                                                       |  |  |
|  |  |   [ Auto Scaling Group ]               [ AWS Systems Manager (SSM) ]  |  |  |
|  |  |   +--------------------+               (Connection w/o Port 22)       |  |  |
|  |  |   |   EC2 Instances    |<--- HTTPS ---> Ansible Config Sync           |  |  |
|  |  |   | (Nginx + Apps in   |                                              |  |  |
|  |  |   |  Docker container) |                                              |  |  |
|  |  |   +---------+----------+                                              |  |  |
|  |  |             |                                                         |  |  |
|  |  |   +---------v----------+                                              |  |  |
|  |  |   |   RDS Database     | (MySQL / PostgreSQL)                         |  |  |
|  |  |   +--------------------+                                              |  |  |
|  |  +-----------------------------------------------------------------------+  |  |
|  +-----------------------------------------------------------------------------+  |
|                                                                                   |
|  [ S3 Bucket (Terraform State & Native Lock) ]                                    |
+-----------------------------------------------------------------------------------+
```

---

## 🗺️ The AWS Infrastructure Topology (Network & Compute)

Infrastructure တစ်ခုလုံးရဲ့ Network နဲ့ Architecture ကို AWS Best Practices (Well-Architected Framework) နှင့်အညီ အသေးစိတ် ခွဲခြားတည်ဆောက်ထားပါတယ်။ အဓိက ပါဝင်တဲ့ အစိတ်အပိုင်းတွေကတော့:

1.  **VPC & Network Isolation (သီးသန့် Network):** System အားလုံးကို Custom VPC တစ်ခုအတွင်းမှာ လုံခြုံစွာထားရှိပြီး Public နှင့် Private Subnet ဆိုပြီး Layer ခွဲခြားထားပါတယ်။
2.  **Public Layer (Internet Facing):** 
    *   **Internet Gateway (IGW)** မှတစ်ဆင့် အပြင်က Request တွေကို လက်ခံပါတယ်။
    *   **Application Load Balancer (ALB)** များကို Public Subnet မှာ ထားရှိပြီး၊ User တွေရဲ့ HTTP/HTTPS Traffic ကို အတွင်းပိုင်းက EC2 တွေဆီ လုံခြုံစွာ ဖြန့်ဝေပေးပါတယ်။
    *   **NAT Gateway** များကိုလည်း Public Layer မှာထားပြီး၊ Private Subnet ထဲက EC2 များ Internet ကို Outbound ထွက်ပြီး Update ယူနိုင်ရန် (ဥပမာ- Docker image pull လုပ်ရန်) စီစဉ်ထားပါတယ်။
3.  **Private Layer (Highly Secure & Auto-Scaled):** 
    *   **EC2 Auto Scaling Group (ASG):** Application နဲ့ Nginx ကို Run မယ့် Server များကို Private Subnet ထဲမှာပဲ သီးသန့်ထားပါတယ်။ အပြင်ကနေ တိုက်ရိုက်လှမ်းခေါ်လို့ (Direct Access) ပြုလုပ်၍ မရပါဘူး။ Traffic များလာပါက ASG မှ Server အသစ်များကို Auto Scale လုပ်ပေးပါတယ်။
    *   **RDS Database:** MySQL သို့မဟုတ် PostgreSQL Database ကိုလည်း Private Subnet ထဲမှာပဲ ထားရှိပြီး EC2 များကနေသာ ချိတ်ဆက်နိုင်ရန် Security Group (SG) တွေနဲ့ တင်းကျပ်စွာ ပိတ်ထားပါတယ်။
4.  **Zero-Trust Security (SSM):** 
    *   ပုံမှန် Architecture တွေလို Bastion Host (Jump Box) မလိုတော့ပါဘူး။
    *   SSH Port 22 လုံးဝ ဖွင့်စရာမလိုဘဲ **AWS Systems Manager (SSM)** မှတစ်ဆင့် HTTPS port 443 ကိုသုံးပြီး Agent-based လုံခြုံစွာ ချိတ်ဆက်စီမံပါတယ်။
5.  **High Availability (HA):** Subnet များကို Availability Zone (AZ) အနည်းဆုံး ၂ ခုခွဲပြီး ဖြန့်ကျက်ထားသောကြောင့် Data Center တစ်ခုခု Down သွားခဲ့လျှင်တောင် Application ဆက်လက်အလုပ်လုပ်နေမှာ ဖြစ်ပါတယ်။

---

## 🏗️ The Architecture: Separation of Concerns

System ကြီးတစ်ခုလုံးရဲ့ တည်ငြိမ်မှု (Stability) ရဖို့အတွက် နည်းပညာ ၄ ခုကို သူ့တာဝန်နဲ့သူ တိတိကျကျ ခွဲခြားပေးထားပါတယ်:

1.  **Atmos**: Multi-Environment အတွက် Configuration Wrapper (The Brain).
2.  **Packer**: Base Machine Image သီးသန့် ဖန်တီးပေးခြင်း (The Baker).
3.  **Terraform**: AWS Resource များ ဖန်တီးခြင်း (The Builder).
4.  **Ansible**: Agent-based Configuration Management (The Tuner).
5.  **GitLab CI**: Trigger အပိုင်းကို ထိန်းချုပ်သည့် Orchestrator (The Conductor).

---

## 📦 ၁. Packer: Building the "Golden Image" (AMI)

ပုံမှန်အားဖြင့် DevOps အများစုက EC2 အသစ်တက်လာရင် Nginx သွင်းမယ်၊ Docker သွင်းမယ်ဆိုပြီး **Terraform `user_data` script တွေ ဒါမှမဟုတ် `ansible-playbook` တွေကို Server တက်လာမှ Run ကြပါတယ်။** (Run-time Provisioning).

ဒါဟာ Production အတွက် **အန္တရာယ် အရမ်းများပါတယ်**။ Ubuntu Repository တွေ ယာယီ Down နေတာမျိုး၊ `apt-get` က Package Version အသစ်ကို ယူလိုက်တဲ့အတွက် Application နဲ့ မကိုက်တော့တာမျိုး တွေ ကြုံတွေ့ရနိုင်ပါတယ်။

ဒီပြဿနာကို ရှင်းဖို့ HashiCorp ရဲ့ **Packer** ကို သုံးပြီး **Base AMI (Amazon Machine Image)** ကို အရင်ဆုံး Build (Bake) လုပ်ပါတယ်။

### Low-Level Workflow:
-   **Builder**: AWS `ebs` builder ကိုသုံးကာ `ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*` (Canonical ၏ နောက်ဆုံးထွက် Image) ကို အခြေခံအဖြစ် ယူပါတယ်။
-   **Provisioner**: ယာယီ EC2 instance တစ်ခုထပြီး `install_packages.sh` ကို Run ပါတယ်။ အဲဒီအထဲမှာ Nginx, Docker (CE), Docker Compose (v2 plugin) နှင့် MySQL (`mysql-client`) တွကို Download ဆွဲပြီး Install အပြီးသတ်လုပ်ပါတယ်။
-   **Output**: ပြီးတာနဲ့ `Demo-base-image-<timestamp>` ဆိုပြီး AMI ကို Tag လေးတပ်ကာ AWS ထဲမှာ သိမ်းလိုက်ပါတယ်။

**Immuntability ၏ အားသာချက်**:  `develop` မှာ စမ်းသပ်ထားတဲ့ `Demo-base-image` ထဲက Docker version နဲ့ `production` ရောက်ရင် Boot တက်လာမယ့် Docker version က **၁၀၀% တူညီသွားပါတယ်။** Boot time ကလည်း Package တွေ သွင်းစရာမလိုတော့လို့ စက္ကန့်ပိုင်းအတွင်း ပြီးစီးပါတယ်။

---

## 🏗️ ၂. Terraform & Atmos: Provisioning & State Management

Golden Image ရပြီဆိုတော့ AWS Infrastructure ကို Terraform နဲ့ တည်ဆောက်ပါမယ်။ ဒါပေမယ့် Environment ၃၊ ၄ ခု (dev, uat, prod) ကို deploy လုပ်တဲ့အခါ, Terraform folder တွေအများကြီး copy-paste လုပ်ရတာ ရှုပ်ထွေးပါတယ်။ 

### Atmos: The Configuration Wrapper
ဒီအတွက် **Atmos (Cloud Posse)** ကို သုံးပါတယ်။ `stacks/deploy/` အောက်မှာ `dev.yaml`, `prod.yaml` စသည်ဖြင့် YAML file လေးတွေနဲ့ပဲ Configuration ကို ထိန်းချုပ်ပါတယ်။ Terraform Module (ဥပမာ EC2 ဆောက်တဲ့ Code) က ၁ ခုတည်းပါပဲ။ Atmos က လိုအပ်တဲ့ Environment Variables (Instance Type, VPC ID) တွေကို Inject လုပ်ပေးသွားပါတယ်။ ဒါဟာ **DRY (Don't Repeat Yourself)** အပြည့်အဝဖြစ်ပါတယ်။

### Terraform Native S3 Locking (Goodbye DynamoDB!)
Terraform State lock ချဖို့ အရင်က DynamoDB ကို သုံးရပါတယ်။ ဒါပေမယ့် ဒီ Architecture မှာ **Terraform 1.10+ ရဲ့ အမိုက်စား feature အသစ်ဖြစ်တဲ့ "Native S3 State Locking"** ကို ပြောင်းသုံးထားပါတယ်။ 

Backend config မှာ `use_lockfile: true` လို့ ထည့်လိုက်ရုံနဲ့, Terraform ဟာ S3 bucket ထဲက `<env>.tfstate` ဘေးလေးမှာပဲ `<env>.tfstate.lock.info` ဆိုတဲ့ ဖိုင်လေးကို တိုက်ရိုက်ထုတ်ပြီး Lock ချပေးသွားပါတယ်။ **Infrastructure Components တစ်ခု (DynamoDB) သက်သာသွားလို့ Architecture ပိုရှင်းသွားပါတယ်။**

### Dynamic AMI Data Source
Terraform Code ထဲမှာ `ami_id = "ami-0123...abc"` လို့ Hardcode လုံးဝ မရေးထားပါဘူး။
`aws_ami` Data Source ကိုသုံးပြီး၊ Packer က တပ်ပေးလိုက်တဲ့ `tag:Name = "Demo-base-image"` ကို လှမ်း Filter ခိုင်းပါတယ်။
ဒါကြောင့် Packer က Image အသစ် Bake ပြီးသွားတိုင်း၊ Terraform က Latest AMI အသစ်ကို အလိုအလျောက် ယူပြီး Instance တွေကို Rolling Update တိုက်ရိုက်လုပ်ပေးသွားပါတယ်။

---

## 🤖 ၃. Ansible: Zero-SSH Configuration Management

**"Packer က Software တွေ အကုန်သွင်းပြီးပြီဆိုတော့, Ansible က ဘာလုပ်ဖို့လိုသေးလို့လဲ?"** လို့ မေးစရာရှိပါတယ်။

Packer သွင်းပေးလိုက်တာက Package (Binary) တွေသက်သက်ပါ။ `develop` နဲ့ `prod` မှာ Nginx ရဲ့ Reverse Proxy IP တွေ မတူပါဘူး။ MySQL connection string တွေ၊ Log level တွေခွဲခြားပေးဖို့ **Configuration Management** လိုအပ်ပါတယ်။ ဒါကို Ansible က တာဝန်ယူပါတယ်။

### AWS Systems Manager (SSM) ဖြင့် လုံခြုံစွာဝင်ရောက်ခြင်း
Private Subnet ထဲက EC2 တွေကို Ansible ဝင်ချိတ်ဖို့ Bastion Host တွေ၊ Port 22 SSH Key တွေ **လုံးဝ (လုံးဝ)** မသုံးထားပါဘူး။ 

*   **SSM Connection Plugin**: `ansible_connection: "'aws_ssm'"` လို့ Define လုပ်ထားပါတယ်။ EC2 ထဲမှာ Run နေတဲ့ SSM Agent ကနေပြီး AWS API ကို အသုံးပြုကာ (HTTPS Over Port 443 ဖြင့် Outbound) ချိတ်ဆက်ပါတယ်။
*   **Dynamic Inventory**: Inventory ကို IP တွေ လိုက်မရေးဘဲ `amazon.aws.aws_ec2` plugin အသုံးပြုပြီး `tag:Name = "Demo-<env>-Instance"` ဆိုတဲ့ Tag ကတစ်ဆင့် AWS ထဲက Server တွေကို အလိုအလျောက် List ကောက်ပေးပါတယ်။
*   **Idempotency & Assertions**: Ansible Task တွေဟာ အရင်ဆုံး `dpkg-query` နဲ့ လိုအပ်တဲ့ Nginx/Docker ရှိ/မရှိ Check လုပ် (Assert) ပါတယ်။ ရှိလာပြီဆိုမှ Jinja2 Template လေးတွေနဲ့ Nginx Config ကို Overwrite သွားလုပ်ပါတယ်။ ဒါကြောင့် Playbook ကို ဘယ်နှခါ Run Run Configuration State ပြောင်းလဲမသွားပါဘူး (Idempotent)။

---

## 🔄 ၄. GitLab CI: Parent-Child Pipeline Orchestration

ဒီ အပိုင်းတွေအားလုံးကို GitLab CI ထဲမှာ လာပေါင်းပါတယ်။ ဒါပေမယ့် Monolithic `.gitlab-ci.yml` ကြီး မဟုတ်ဘဲ **Parent-Child Pipeline Architecture** ကို အသုံးပြုထားပါတယ်။

1.  **Parent Router (`.gitlab-ci.yml`)**: User တွေကို UI ခလုတ် (Trigger Button) တွေပဲ ပြပေးပါတယ်။
2.  **Child Pipelines**: `.gitlab/ci/` အောက်မှာ သီးသန့်ခွဲထားပါတယ်။
    *   **Packer (`packer.yml`)**: Branch restriction (`develop` branch ပေါ်မှာရပ်မှ) နှင့် Path change (`components/packer/**/*` အောက်က Code တွေပြင်မှ) သာလျှင် Packer Build Trigger ကို CI မှာ ပြပေးပါတယ်။
    *   **Terraform (`terraform.yml`)**: `tfsec` ဖြင့် Static Code Analysis လုံခြုံရေး အရင်စစ်ပါတယ်။ `terraform plan` ပြုလုပ်ပြီး ထွက်လာတဲ့ Binary `.tfplan` ဖိုင်ကို GitLab Artifact အနေနဲ့ သိမ်းပါတယ်။ အဲ့ဒီ **သိမ်းထားတဲ့ Artifact အတိအကျကိုပဲ `terraform apply` က ပြန်ခေါ်သုံးပါတယ်** (Race Condition ကာကွယ်ခြင်း)။
    *   **Ansible (`ansible.yml`)**: စမ်းသပ်အောင်မြင်စွာ Boot တက်လာတဲ့ Server တွေကို SSM ကနေ Config ပုံသွင်းပါတယ်။

### 🛡️ Shifting Security Left: tfsec ၏ လုံခြုံရေး ခံတပ် (Static Code Analysis)

Infrastructure ကို Code ရေးပြီး တည်ဆောက်တဲ့အခါ "လူအမှား (Human Error)" တွေကို တားဆီးဖို့ `tfsec` လို Static Analysis Tool ကို Terraform Pipeline ရဲ့ ရှေ့ဆုံး (First Line of Defense) အနေနဲ့ ဘာကြောင့် မဖြစ်မနေ ထည့်သွင်းအသုံးပြုသင့်တာလဲ?

**⚙️ ဘယ်လို အလုပ်လုပ်သလဲ? (How it works deeply)**
`tfsec` ဟာ AWS ဆီကို Network ကနေ တကယ် သွားမချိတ်ပါဘူး။ ခင်ဗျားရေးထားတဲ့ Terraform Code (HCL) တွေကို Abstract Syntax Tree (AST) ပုံစံပြောင်းပြီး လိုင်းတစ်လိုင်းချင်းစီကို Scan ဖတ်ပါတယ်။ ပြီးရင် AWS Well-Architected Framework နဲ့ CIS Benchmarks တွေထဲက Security Rules ရာပေါင်းများစွာနဲ့ အလိုအလျောက် သွားတိုက်စစ်ပါတယ်။ ဥပမာ - AWS Security Group မှာ Port `22` (SSH) ကို Public `0.0.0.0/0` ဖွင့်ထားမိတာမျိုး၊ RDS Database ကို Encrypt မလုပ်ထားတာမျိုး၊ S3 Bucket တွေကို Public Read ဖွင့်ထားမိတာမျိုး တွေ့တာနဲ့ `terraform plan` အဆင့်ကိုတောင် ပေးမသွားဘဲ CI Pipeline ကို ချက်ချင်း ရပ်ပစ် (Fail) လိုက်ပါတယ်။ ဒါကို "**Shift-Left Security**" (လုံခြုံရေးကို နောက်ဆုံးမှ မစစ်ဘဲ၊ အစောဆုံး Code ရေးတဲ့ CI အဆင့်မှာတင် ဖမ်းယူစစ်ဆေးခြင်း) လို့ ခေါ်ပါတယ်။

**✅ အားသာချက်များ (Pros of tfsec):**
1.  **Ultra-Fast & Proactive Detection:** Cloud ပေါ်ကို အမှား (Vulnerability) ရောက်သွားပြီးမှ Hacker ဝင်လို့ ပြာယာခတ်ရတာမျိုး မရှိတော့ပါဘူး။ ကိုယ်ရေးလိုက်တဲ့ လုံခြုံရေး အားနည်းချက်ကို စက္ကန့်ပိုင်းအတွင်း Code အဆင့်မှာ မြန်မြန်ဆန်ဆန် သိနိုင်ပါတယ်။
2.  **No AWS Credentials Required:** Cloud ထဲ ဝင်မစစ်တဲ့ Static Analysis ဖြစ်လို့ `tfsec` run တဲ့ GitLab Runner မှာ တန်ဖိုးကြီး AWS Access Keys တွေ လုံးဝ ပေးထားစရာ မလိုပါဘူး။
3.  **Built-in Educational Value:** Error တက်ရင် "ဘာကြောင့်မှားတာလဲ၊ Best Practice က ဘယ်လိုရေးသင့်လဲ၊ ဘယ်လို ပြင်ရမလဲ" ဆိုတဲ့ Link တွေကို CI Terminal မှာ တိုက်ရိုက်ဖော်ပြပေးလို့ DevOps/Developer တွေအတွက် Security Awareness ကိုပါ တဖြည်းဖြည်း မြှင့်တင်ပေးပါတယ်။

**❌ အားနည်းချက်များ နှင့် ဖြေရှင်းပုံ (Cons & Limitations):**
1.  **False Positives (အလွန်အကျွံ Sensitive ဖြစ်ခြင်း):** တစ်ခါတစ်ရံမှာ တကယ် Public ဖွင့်ဖို့လိုတဲ့ အရာတွေ (ဥပမာ- Application Load Balancer မှာ Port 80/443 ကို Internet ကနေ လာခွင့်ပေးတာမျိုး) ကိုပါ လုံခြုံရေးအရ စိုးရိမ်ပြီး Error ပြကာ Pipeline ကို ပိတ်ချတတ်ပါတယ်။ ဒီလိုအခြေအနေမျိုးမှာ တမင်ဖွင့်ထားတာဖြစ်ကြောင်း လုံခြုံတယ်ဆိုတာကို သေချာရင်၊ Terraform Code ရဲ့ အပေါ်မှာ `#tfsec:ignore:aws-vpc-no-public-ingress-sgr` လို့ Ignore Comment လေးတပ်ပြီး Bypass ပြုလုပ်ပေးရပါတယ်။
2.  **Static Only (Runtime Context ကို မသိနိုင်ခြင်း):** Code စာသားကိုသာ ဖတ်တာဖြစ်လို့၊ AWS ထဲရောက်သွားမှ ဖြစ်လာမယ့် IAM Policy Permission လွဲချော်တာတွေ၊ AWS Resource Limit ပြည့်နေတာတွေကိုတော့ လုံးဝ ကြိုတင်မသိနိုင်ပါဘူး။ ဒါကြောင့် `tfsec` အလွန်မှာ တကယ့် Cloud နဲ့ တိုက်စစ်တဲ့ `terraform plan` ကို နောက်ခံထပ်ထားပေးရခြင်း ဖြစ်ပါတယ်။

---

## 💡 The Verdict (နိဂုံးချုပ် သုံးသပ်ချက်)

ဒီ Architecture ဟာ ခေတ်သစ် Cloud-Native ကုမ္ပဏီကြီးတွေသုံးတဲ့ Cloud Architecture Design Pattern ကို တိုက်ရိုက်အသုံးချထားခြင်းဖြစ်ပါတယ်။ 

**State (Configuration) ကို Run-time ရောက်မှ မတွက်ခိုင်းဘဲ၊ Build-time (Packer) ကတည်းက အတိအကျ Freeze လုပ်လိုက်တဲ့စနစ်** ဟာ Infrastructure ကို "Predictable" အဖြစ်ဆုံး၊ မြန်ဆန်ဆုံးနဲ့ လုံခြုံမှုအရှိဆုံး ဖြစ်စေတဲ့ Best Practice တစ်ခုဖြစ်ကြောင်း မျှဝေလိုက်ရပါတယ်။ 🚀
